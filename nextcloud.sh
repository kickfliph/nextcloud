#!/bin/bash

nc_ver=nextcloud-19.0.3.zip
echo "$nc_ver"

sudo apt install nginx -y
sudo systemctl stop nginx.service
sudo systemctl enable nginx.service
sudo systemctl start nginx.service

sudo apt-get install mariadb-server mariadb-client -y
sudo systemctl stop mariadb.service
sudo systemctl enable mariadb.service
sudo systemctl start mariadb.service
sudo mysql_secure_installation
sudo systemctl restart mariadb.service

sudo apt install php-fpm php-mbstring php-xmlrpc php-soap php-apcu php-smbclient php-ldap php-redis php-gd php-xml php-intl php-json php-imagick php-mysql php-cli php-ldap php-zip php-curl php-dev libmcrypt-dev php-pear -y

echo "======================================================================================================================================"
echo " "
read -p 'Please enter Data Base Name: ' dbname
echo " "
read -p 'Please enter Data Base user name: ' users
echo " "
read -p -s 'Please enter password Data Base user: ' shadows
if [ -z "$dbname" ] || [ -z "$shadows" ] || [ -z "$users" ]
then
    echo 'Inputs cannot be blank please try again!'
    exit 0
fi

mysql -e "CREATE DATABASE ${dbname};"
mysql -e "CREATE USER '${users}'@'localhost' IDENTIFIED BY '${shadows}';"
mysql -e "GRANT ALL ON ${dbname}.* TO '${users}'@'localhost' IDENTIFIED BY '${shadows}' WITH GRANT OPTION;"
mysql -e "FLUSH PRIVILEGES;"

echo " "
read -p 'Please enter your Domain Name: ' domainame
echo " "
read -p 'Please enter your email: ' my_email
if [ -z "$domainame" ] || [ -z "$my_email" ]
then
    echo 'Inputs cannot be blank please try again!'
    exit 0
fi
echo " "

sudo apt install certbot python-certbot-nginx python3-certbot-nginx -y
sudo systemctl stop nginx

wget -c https://download.nextcloud.com/server/releases/$nc_ver -P /tmp
sudo apt install zip unzip nginx -y
unzip /tmp/$nc_ver -d /var/www/
sudo chown -R www-data:www-data /var/www/nextcloud

php_ver=`php -v | grep PHP | head -1 | cut -d ' ' -f2 | cut -c 1-3`

sudo cp ./nextcloud /etc/nginx/sites-available/

sudo sed -i "s/php7.4/$php_ver/g" /etc/nginx/sites-available/nextcloud
sudo sed -i "s/my_domain_name/$domainame/g" /etc/nginx/sites-available/nextcloud

sudo certbot --nginx --agree-tos --redirect --staple-ocsp --email $my_email -d $domainame

sudo ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
systemctl restart php$php_ver-fpm
 
