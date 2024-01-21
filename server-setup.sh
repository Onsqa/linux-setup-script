#!/bin/bash

# Ask user to enter their public key
read -p "Please enter your public key: " pub_key

# Ask user if they want to disable password authentication and root login
read -p "Do you want to disable password authentication and root login? (yes/no): " answer
if [ "$answer" = "yes" ]; then
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
    sudo apt-get install nginx -y
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
    # Install MariaDB
    sudo apt-get install mariadb-server -y
    sudo systemctl enable mariadb
    sudo mysql_secure_installation
    else
        echo "Skipping mariadb install"
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

read -p "Do you want to optimize system packages? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    sudo apt-get autoremove -y
    sudo apt-get autoclean -y
    else
    echo "Skipping optimization"
fi
#wget -O setup.sh https://raw.githubusercontent.com/Onsqa/linux-setup-script/main/server-setup.sh && chmod +x server-setup.sh && ./server-setup.sh
