#!/bin/bash
if [ "$EUID" -ne 0 ]
    then echo "Suorita tiedosto roottina"
    exit
fi

shopt -s nocasematch
ask_and_run() {
    read -p "$1 (yes/no): " answer
    if [[ "$answer" = "yes" ]] || [[ "$answer" = "y" ]]; then
        shift
        "${@}"
    else
        echo "Skipataan $1"
    fi
}

ask_and_run "Haluatko disable password authentication ja root login?" disable_ssh_password_auth
ask_and_run "Haluatko update ja upgrade järjestelmä tiedostot?" update_system_packages
ask_and_run "Haluatko asentaa nginx, php 8.1, certbot?" install_nginx_php_certbot
ask_and_run "Haluatko asentaa docker ja docker compose?" install_docker
ask_and_run "Haluatko päivittää php limittejä?" update_php_limits
ask_and_run "Haluatko lisätä käyttäjän www data ryhmään?" add_user_to_wwwdata
ask_and_run "Haluatko aktivoida palomuurin" update_firewall
ask_and_run "Haluatko asentaa MariaDB?" install_mariadb
ask_and_run "Haluatko asentaa pikku ohjelmistoja mm speedtest, htop?" instalL_small_packages
ask_and_run "Haluatko automatically clean files and config swappiness?" auto_clean_swappiness
ask_and_run "Haluatko vaihtaa aikavyöhykkeen Helsinkiin?" change_timezone
ask_and_run "Haluatko vaihtaa palvelimen nimen?" change_hostname
ask_and_run "Haluatko käynnistää palvelimen uudelleen?" reboot


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

install_nginx_php_certbot() {
    yes |  apt-get install -y nginx software-properties-common
    yes |  add-apt-repository ppa:ondrej/php
    yes |  apt-get update
    yes | apt-get install -y php8.1-fpm php8.1-mysql php8.1-curl php8.1-gd php8.1-mbstring \
            php8.1-xml php8.1-xmlrpc php8.1-zip php8.1-soap php8.1-intl \
            php8.1-bcmath php8.1-cli php8.1-dev php8.1-common php8.1-json \
            php8.1-opcache php8.1-readline php8.1-imap php8.1-imagick \
            php8.1-redis php8.1-sqlite3 php8.1-xdebug php8.1-xmlreader \
            php8.1-xmlwriter php8.1-zmq php8.1-ldap php8.1-pgsql php8.1-pdo \
            php8.1-pdo-mysql php8.1-pdo-pgsql php8.1-pdo-sqlite
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
shopt -u nocasematch
