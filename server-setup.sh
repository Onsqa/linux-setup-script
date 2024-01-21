#!/bin/bash


# Ask user if they want to disable password authentication and root login
read -p "Do you want to disable password authentication and root login? (yes/no): " answer
if [ "$answer" = "yes" ]; then
read -p "Please enter your public key: " pub_key
    sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
    sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
    echo "$pub_key" >> ~/.ssh/authorized_keys
    sudo service ssh restart
    else
        echo "Skipping SSH configs"
fi

read -p "Do you want to update and upgrade system packages? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    sudo apt-get update -y 
    sudo apt-get upgrade -y
    echo "System packages updated and upgraded."
    else
        echo "System packages not updated or upgraded."
fi

read -p "Do you want to install nginx, php 8.1, certbot?" answer
if [ "$answer" = "yes" ]; then
    # Install Nginx and optimize it
    # Install Nginx
    sudo apt-get install nginx -y

    # Optimize Nginx
    sudo bash -c "cat >> /etc/nginx/nginx.conf" <<'EOF'
worker_processes auto;
events {
    worker_connections 1024;
}
http {
    keepalive_timeout 15;
}
EOF

    # Test and reload Nginx
    sudo nginx -t && sudo systemctl reload nginx
    # Install PHP with addons
    sudo apt-get install software-properties-common -y
    sudo add-apt-repository ppa:ondrej/php
    sudo apt-get update
    sudo apt-get install -y php8.1-fpm
    sudo apt-get install -y php8.1-mysql
    sudo apt-get install -y php8.1-curl
    sudo apt-get install -y php8.1-gd
    sudo apt-get install -y php8.1-mbstring
    sudo apt-get install -y php8.1-xml
    sudo apt-get install -y php8.1-xmlrpc
    sudo apt-get install -y php8.1-zip
    sudo apt-get install -y php8.1-soap
    sudo apt-get install -y php8.1-intl
    sudo apt-get install -y php8.1-bcmath
    sudo apt-get install -y php8.1-cli
    sudo apt-get install -y php8.1-dev
    sudo apt-get install -y php8.1-common
    sudo apt-get install -y php8.1-json
    sudo apt-get install -y php8.1-opcache
    sudo apt-get install -y php8.1-readline
    sudo apt-get install -y php8.1-imap
    sudo apt-get install -y php8.1-imagick
    sudo apt-get install -y php8.1-redis
    sudo apt-get install -y php8.1-sqlite3
    sudo apt-get install -y php8.1-xdebug
    sudo apt-get install -y php8.1-xmlreader
    sudo apt-get install -y php8.1-xmlwriter
    sudo apt-get install -y php8.1-zmq
    sudo apt-get install -y php8.1-ldap
    sudo apt-get install -y php8.1-pgsql
    sudo apt-get install -y php8.1-pdo
    sudo apt-get install -y php8.1-pdo-mysql
    sudo apt-get install -y php8.1-pdo-pgsql
    sudo apt-get install -y php8.1-pdo-sqlite
    
    # Install Certbot for nginx
    sudo apt-get install -y certbot
    sudo apt-get install -y python3-certbot-nginx
    sudo apt-get install -y python3-certbot-apache

    # Nginx to systemctl
    sudo systemctl enable nginx
    else
        echo "Skipping installing nginx, php 8.1, certbot"
fi

read -p "Do you want to install docker, docker-compose and add current user to docker group? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    # Install Docker
    sudo apt-get update
    sudo apt-get install \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
    echo "Packages installed successfully."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "Docker GPG key added."
    echo \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    echo "Docker repository added."
    sudo apt-get update
    echo "Package list updated."
    sudo apt-get install docker-ce docker-ce-cli containerd.io
    echo "Docker installed."
    # Install Docker-Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed."
    # User to docker group
    sudo usermod -aG docker $USER
    echo "User added to Docker group."
    else
        echo "Skipping installing Docker and Docker-Compose"
fi

read -p "Do you want to edit php limits? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    # Edit PHP limits
    sudo sed -i 's/upload_max_filesize = .*/upload_max_filesize = 2096M/' /etc/php/8.1/fpm/php.ini
    sudo sed -i 's/post_max_size = .*/post_max_size = 100M/' /etc/php/8.1/fpm/php.ini
    sudo sed -i 's/memory_limit = .*/memory_limit = 1024M/' /etc/php/8.1/fpm/php.ini
    # Restart PHP-FPM service
    sudo service php8.1-fpm restart
    echo "PHP limits edited and PHP restarated."
    else
        echo "PHP limits not edited."
fi

read -p "Do you want to add current user to www-data group? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    # Add current user to www-data group
    sudo usermod -aG www-data $USER
    echo "User added to www-data group."
    # Change ownership of /var/www to www-data group
    sudo chown -R :www-data /var/www
    echo "Ownership of /var/www changed to www-data group."
    # Set the setgid bit on /var/www so all new files are created with the www-data group
    sudo chmod -R g+s /var/www
    echo "Setgid bit set on /var/www."
    else
        echo "Skipping www-data group config"
fi



read -p "Do you want to configure firewall rules? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    # Configure Firewall
    sudo ufw allow 3306/tcp
    sudo ufw allow 'Nginx Full'
    sudo ufw allow OpenSSH
    echo "Firewall configured successfully"
    else
        echo "Skipping firewall configuration"
fi

read -p "Do you want to install mariadb? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    read -sp "Enter the root password for MariaDB: " root_password
    # Install MariaDB
    sudo apt-get install mariadb-server -y
    sudo systemctl enable mariadb

    sudo mysql -e "UPDATE mysql.user SET Password = PASSWORD('$root_password') WHERE User = 'root'"
    sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
    sudo mysql -e "DELETE FROM mysql.user WHERE User=''"
    sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
    sudo mysql -e "FLUSH PRIVILEGES"
else
    echo "Skipping mariadb install"
fi

read -p "Do you want to optimize MariaDB? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    sudo bash -c "cat >> /etc/mysql/mariadb.conf.d/50-server.cnf" <<'EOF'
[mysqld]
# Set buffer pool size to 50-80% of your computer's memory
innodb_buffer_pool_size=2048M
# Set the log file size to about 25% of the buffer pool size
innodb_log_file_size=512M
# Other settings
innodb_flush_log_at_trx_commit=1
innodb_flush_method=O_DIRECT
innodb_log_buffer_size=64M
query_cache_size=64M
query_cache_type=1
EOF
    sudo systemctl restart mariadb
else
    echo "Skipping MariaDB optimization"
fi

read -p "Do you want to install small utility packages? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    # Install small utility packages
    sudo apt-get install -y zip unzip
    sudo apt-get install -y htop
    sudo apt-get install -y curl
    sudo apt-get install -y speedtest-cli
    else 
    echo "Skipping small utility packages"
fi

read -p "Do you want to optimize system? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    sudo apt-get autoremove -y
    sudo apt-get autoclean -y
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
    else
    echo "Skipping optimization"
fi
read -p "Do you want to change server name? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    read -p "Enter the new server name: " new_hostname
    sudo hostnamectl set-hostname $new_hostname
    echo "Server name changed to $new_hostname."
else
    echo "Skipping server name change."
fi

read -p "Do you want to change server timezone? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    read -p "Enter the new timezone (e.g., 'America/Los_Angeles'): " new_timezone
    sudo timedatectl set-timezone $new_timezone
    echo "Server timezone changed to $new_timezone."
else
    echo "Skipping server timezone change."
fi
#wget -O setup.sh https://raw.githubusercontent.com/Onsqa/linux-setup-script/main/server-setup.sh && chmod +x server-setup.sh && ./server-setup.sh
