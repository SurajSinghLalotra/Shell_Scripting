#!/bin/bash

#------------------------------------------------------------NGINX-INSTALLATION------------------------------------------------------
set -e
# Updating Index
echo "🆕 Updating Index..."
sudo dnf update -y

# Installing nginx
echo "⬇️  Installing nginx..."
sudo dnf install nginx -y

# Starting and Enabling nginx
echo "🚀 Starting and ennabling nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx

# Check status
echo "🔍 Checking Status..."
sudo systemctl status nginx

echo "Nginx Installed and started sucessfully"

#------------------------------------------------------------PHP & PHP-FPM INSTALLATION--------------------------------------------

# Installing php-fpm
echo "⬇️  Installing php-fpm..."
sudo dnf install php-fpm php-mysqlnd -y

# Enable and start php-fpm service
echo "🚀 Starting and ennabling php-fpm..."
sudo systemctl start php-fpm
sudo systemctl enable php-fpm

# Check status
echo "🔍 Checking Status..."
sudo systemctl status php-fpm


#-------------------------------------------------------------SQL-INSTALLATION-----------------------------------------------------

# Installing MariaDB Server
echo "⬇️  Installing MariaDB..."
sudo dnf install mariadb105-server -y

# Enable and start MariaDB service
echo "🚀 Starting and ennabling MariaDB..."
sudo systemctl enable mariadb
sudo systemctl start mariadb

echo "✅ MariaDB installed and started successfully."

#----------------------------------------------------------Database-creating---------------------------------------------------------
# Prompt user input for database info
read -p "Enter the database name to create: " dbname
read -p "Enter the username to create: " dbuser
#read -s -p "Enter the password for user '$dbuser': " dbpass

#dbname="wordpress"
#dbuser="wordpressuser"
dbpass="123"
echo

# Confirm and display
echo "🔨 Creating database '$dbname' and user '$dbuser...'"

# Execute SQL commands
sudo mysql -u root -e "CREATE DATABASE ${dbname} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
sudo mysql -u root -e "CREATE USER '${dbuser}'@'localhost' IDENTIFIED BY '${dbpass}';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${dbuser}'@'localhost';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"

echo "✅ Your Database named ${dbname} is created"
echo "✅ Your Username named ${dbuser} is created and have been GRANTED ALL PRIVILEGES"

#-------------------------------------------------------Downloading & Configuring Wordpress--------------------------------------------
# Navigating to /var/www/html
echo "📁 Navigating to /var/www/html..."
cd /var/www/html

# Downloading Wordpress
echo "⬇️  Downloading latest WordPress..."
sudo wget https://wordpress.org/latest.tar.gz

# Extracting Wordpresks
echo "📦 Extracting WordPress..."
sudo tar -xzf latest.tar.gz

# Removing the unecessary wordpress zip file
echo "🧹 Removing unecessary wordpress zip file..."
sudo rm -f latest.tar.gz

# Listing
echo "📂 Listing contents..."

echo "✅ WordPress downloaded and extracted to /var/www/html/wordpress"

#-------------------------------------------------------Wordpress Configuration-----------------------------------------------------------
# Emptying out the nginx html page
echo "🧹 Removing default Nginx HTML page..."
sudo rm -rf /usr/share/nginx/html/*

# Copying wordpress files to nginx 
echo "📁 Copying WordPress files to Nginx HTML directory..."
sudo cp -rv wordpress/* /usr/share/nginx/html

# Navigating to nginx document root
echo "📂 Navigating to Nginx document root..."
cd /usr/share/nginx/html

# Creating wp-config.php
echo "⚙️  Creating wp-config.php..."
sudo cp wp-config-sample.php wp-config.php


echo "📄 Opening wp-config.php for editing..."
echo "👉 Please update DB_NAME, DB_USER, and DB_PASSWORD in the file manually."

# Open file in Vim (user must manually edit values
#sudo vim +'%s/database_name_here/'${dbname}'/g' +wq  wp-config.php
#sudo vim +'%s/username_here/'${dbuser}'/g' +wq  wp-config.php
#sudo vim +'%s/password_here/'${dbpass}'/g' +wq  wp-config.php

#+'%s/username_here/'${dbuser}'/g'+'%s/password_here/'${dbpass}'/g' 

sudo vim +'%s/database_name_here/'"${dbname}"'/g' \
         +'%s/username_here/'"${dbuser}"'/g' \
         +'%s/password_here/'"${dbpass}"'/g' \
         +wq wp-config.php

echo "Wordpress Configuration completed"


#------------------------------------------------------Configure PHP configuration----------------------------------------------------------------
# Replacing php configuration from apache to nginx
echo "🔁 Replacing php configuration from apache to nginx"
sudo vim +'%s/apache/nginx/g' +wq /etc/php-fpm.d/www.conf

# Configure nginx for wordpress
echo "⚙️  Configure nginx for wordpress"
sudo chown -R nginx:nginx /usr/share/nginx/html

read -p "Enter the domain name you want to run your website at: " domain_name

cat <<EOF > sudo /etc/nginx/conf.d/wordpress.conf 

server {
    listen 80;
    server_name ${domain_name};

    root /usr/share/nginx/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}

EOF

#------------------------------------------------------Checking Configurations----------------------------------------------------------------------
# Check configuration of nginx for syntax errors
echo "📝 Check configuration of nginx for syntax errors"
sudo nginx -t

# Restart nginx
echo "↻ Restarting nginx"
sudo systemctl restart nginx

# Domain address
echo "This is your domain address:" 
echo "${domain_name}"

# IP address
echo "This is yout IP address"
curl ifconfig.me && echo ''

