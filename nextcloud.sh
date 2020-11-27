#!/bin/bash

nc_ver=latest.zip
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

sudo apt install dnsutils php-fpm php-mbstring php-xmlrpc php-soap php-apcu php-smbclient php-ldap php-redis php-gd php-xml php-intl php-json php-imagick php-mysql php-cli php-ldap php-zip php-curl php-dev libmcrypt-dev php-pear -y

echo "======================================================================================================================================"
echo ""
while [[ $valve != 1 ]]
do

  echo ""
     read -p 'Please enter Data Base Name: ' dbname
  echo ""
     read -p 'Please enter Data Base user name: ' users
  echo ""
     read -s -p 'Please enter password Data Base user: ' shadows
  echo ""

  if [ ! -z "$dbname" ] || [ ! -z "$shadows" ] || [ ! -z "$users" ] ; then
     valve=1
   else
     echo 'Inputs cannot be blank please try again!'
  fi
done
valve=0

mysql -e "CREATE DATABASE ${dbname};"
mysql -e "CREATE USER '${users}'@'localhost' IDENTIFIED BY '${shadows}';"
mysql -e "GRANT ALL ON ${dbname}.* TO '${users}'@'localhost' IDENTIFIED BY '${shadows}' WITH GRANT OPTION;"
mysql -e "FLUSH PRIVILEGES;"

echo "================================================================================================================================"
echo " "

while [[ $valve != 1 ]]
do

read -p  "Please enter a valid hostname: " my_hostname

if [[ ! -z $my_hostname ]] && [[ ! -z `dig +short "$my_hostname"` ]] ; then
       valve=1
fi
done
valve=0

while [[ `. eml_verf $my_email` != OK ]]
do

  read -p  "Please enter a valid email address: " my_email

done
echo ""

sudo apt install certbot python-certbot-nginx python3-certbot-nginx -y
sudo systemctl stop nginx

wget -c https://download.nextcloud.com/server/releases/$nc_ver -P /tmp
sudo apt install zip unzip nginx -y
unzip /tmp/$nc_ver -d /var/www/
sudo chown -R www-data:www-data /var/www/nextcloud

php_ver=`php -v | grep PHP | head -1 | cut -d ' ' -f2 | cut -c 1-3`

sudo cp ./nextcloud /etc/nginx/sites-available/

sudo sed -i "s/php7.4/$php_ver/g" /etc/nginx/sites-available/nextcloud
sudo sed -i "s/my_domain_name/$my_hostname/g" /etc/nginx/sites-available/nextcloud

sudo certbot --nginx --agree-tos --redirect --staple-ocsp --email $my_email -d $my_hostname

sudo ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
systemctl restart php$php_ver-fpm
 
