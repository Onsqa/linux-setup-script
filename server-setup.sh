#!/bin/bash
if [ "$EUID" -ne 0 ]
    then echo "Suorita tiedosto roottina"
    exit
fi

shopt -s nocasematch

disable_ssh_password_auth() {
    # Disable password authentication
    read -p "Syötä Public key " pub_key
    awk '/PasswordAuthentication yes/ {$0="PasswordAuthentication no"} 1' /etc/ssh/sshd_config > temp && mv temp /etc/ssh/sshd_config
    # Disable root login
    awk '/PermitRootLogin yes/ {$0="PermitRootLogin no"} 1' /etc/ssh/sshd_config > temp && mv temp /etc/ssh/sshd_config
    # Restart ssh service
    service ssh restart
    # Append public key to the authorized_keys file
    echo "$pub_key" >> ~/.ssh/authorized_keys
}
update_system_packages() {
    yes |  apt-get update
    yes |  apt-get upgrade 
}

all_nginx_php_certbot() {
    read -p "Enter the PHP version you want to install (e.g., 8.1): " php_version
    yes |  apt-get install -y nginx software-properties-common
    yes | sudo apt install python3 python3-venv libaugeas0
    yes |  sudo python3 -m venv /opt/certbot/
    yes | sudo /opt/certbot/bin/pip install --upgrade pip
    yes | sudo /opt/certbot/bin/pip install certbot certbot-nginx
    yes | sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot
    yes |  add-apt-repository ppa:ondrej/php
    yes |  apt-get update
    yes | apt-get install -y php${php_version}-fpm php${php_version}-mysql php${php_version}-curl php${php_version}-gd php${php_version}-mbstring \
            php${php_version}-xml php${php_version}-xmlrpc php${php_version}-zip php${php_version}-soap php${php_version}-intl \
            php${php_version}-bcmath php${php_version}-cli php${php_version}-dev php${php_version}-common php${php_version}-json \
            php${php_version}-opcache php${php_version}-readline php${php_version}-imap php${php_version}-imagick \
            php${php_version}-redis php${php_version}-sqlite3 php${php_version}-xdebug php${php_version}-xmlreader \
            php${php_version}-xmlwriter php${php_version}-zmq php${php_version}-ldap php${php_version}-pgsql php${php_version}-pdo \
            php${php_version}-pdo-mysql php${php_version}-pdo-pgsql php${php_version}-pdo-sqlite
}

install_docker() {
    # Install Docker
    yes | apt-get update
    yes |  apt-get install \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" |  tee /etc/apt/sources.list.d/docker.list > /dev/null
    yes |  apt-get install docker-ce docker-ce-cli containerd.io
    # Install Docker-Compose
    yes |  curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    yes |  chmod +x /usr/local/bin/docker-compose
    # User to docker group
    yes |  usermod -aG docker $USER
}

update_php_limits() {
    yes |  sed -i 's/upload_max_filesize = .*/upload_max_filesize = 2096M/' /etc/php/8.1/fpm/php.ini
    yes |  sed -i 's/post_max_size = .*/post_max_size = 100M/' /etc/php/8.1/fpm/php.ini
    yes |  sed -i 's/memory_limit = .*/memory_limit = 1024M/' /etc/php/8.1/fpm/php.ini
    # Restart PHP-FPM service
    yes |  service php8.1-fpm restart
    echo "PHP limits edited and PHP restarated."
}

add_user_to_wwwdata() {
    # Add current user to www-data group
    yes |  usermod -aG www-data $USER
    # Change ownership of /var/www to www-data group
    yes |   chown -R :www-data /var/www
    # Set the setgid bit on /var/www so all new files are created with the www-data group
    yes |  chmod -R g+s /var/www

}

update_firewall() {
    yes |  ufw enable
    yes |  ufw allow OpenSSH
    echo "Firewall enabled and SSH allowed."

}

install_mariadb(){
    echo "Enter the root password for MariaDB: "
    read -s root_password
    yes |  apt-get install mariadb-server -y
    yes |  systemctl enable mariadb
    yes |  systemctl start mariadb
    yes |  ufw allow 3306/tcp

    yes |  mysql -e "UPDATE mysql.user SET Password = PASSWORD('$root_password') WHERE User = 'root'"
    yes |  mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
    yes |  mysql -e "DELETE FROM mysql.user WHERE User=''"
    yes |  mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
    yes |  mysql -e "FLUSH PRIVILEGES"

}
install_small_packages(){
    yes |  apt-get install -y zip unzip htop curl speedtest-cli

}

auto_clean_swappiness() {
    yes |  apt-get autoremove -y
    yes |  apt-get autoclean -y
    echo "vm.swappiness=10" |  tee -a /etc/sysctl.conf
}
change_timezone() {
    timedatectl set-timezone Europe/Helsinki
    echo "Timezone changed to Europe/Helsinki"
}

change_hostname() {
    read -p "Enter the new server name: " new_hostname
    yes |  hostnamectl set-hostname $new_hostname
    echo "Server name changed to $new_hostname."
}

reboot() {
    shutdown -r now
    echo "Server rebooted."
}

read -p "Haluatko disabloida password authentication ja root kirjautumisen? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    disable_ssh_password_auth
    else
    echo "Skipataan password authentication ja root kirjautumisen."
fi

read -p "Haluatko päivittää järjestelmä ja sen paketit (yes/no): " answer
if [ "$answer" = "yes" ]; then
    update_system_packages
    else
    echo "Skipataan paketit päivittäminen."
fi

read -p "Haluatko asentaa nginx, php 8.1, certbot? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    all_nginx_php_certbot
    else
    echo "Skipataan nginx, php 8.1, certbot."
fi

read -p "Haluatko asentaa docker ja docker compose? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    install_docker
    else
    echo "Docker not installed."
fi

read -p "Haluatko päivittää php limittejä? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    update_php_limits
    else
    echo "Skipataan php limitit"
fi

read -p "Haluatko lisätä käyttäjän www data ryhmään? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    add_user_to_wwwdata
    else
    echo "Ei lisätä käyttäjää"
fi

read -p "Haluatko aktivoida palomuurin (yes/no): " answer
if [ "$answer" = "yes" ]; then
    update_firewall
    else
    echo "Skipataan palomuuri"
fi

read -p "Do you want to install MariaDB? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    install_mariadb
    else
    echo "Skipataan mariadb"
fi

read -p "Haluatko asentaa pikku ohjelmistoja mm speedtest, htop? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    instalL_small_packages
    else 
    echo "Skipping pikku softat"
fi

read -p "Haluatko automatically clean files and config swappiness? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    auto_clean_swappiness
    else
    echo "Swappiness not changed."
fi

read -p "Haluatko vaihtaa aikavyöhykkeen Helsinkiin? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    change_timezone
    else 
    echo "Skipping timezone change"
fi

read -p "Haluatko vaihtaa palvelimen nimen? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    change_hostname
    else
    echo "Skipping hostname change"
fi

read -p "Haluatko käynnistää palvleimen uudelleen? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    reboot
    else
    echo "Skipping reboot"
fi

shopt -u nocasematch
#wget -O setup.sh https://raw.githubusercontent.com/Onsqa/linux-setup-script/main/server-setup.sh && chmod +x setup.sh && sudo ./setup.sh
