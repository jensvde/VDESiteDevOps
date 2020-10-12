#!/bin/bash

#Variables:
SQL_ROOT_PASS=Test@1234
SQL_USER=winkel
SQL_USER_PASS=Winkeltje@1234
DOMAINNAME=vandeneynde.twinkeltjenijlen.be
USERNAME="twinkeltje_peggy"
CERT_LOCATION="/home/$USERNAME/certificate.crt"
KEY_LOCATION="/home/$USERNAME/certificate.key"
SSL_CERT_NAME="transip-ssl-twinkeltjenijlen.be-decrypted-certificate.zip"
APPNAME=VandenEynde
APPLOWERNAME=vandeneynde
GITLINK="https://github.com/jensvde/VDESite.git"
GITPREFIX=VDESite

#Begin of program
#Check if root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

#Update and upgrade
sudo apt-get update && sudo apt-get upgrade -y

#Installing nano, git, wget, nginx, mysql-server, expect, unzip
sudo apt-get install -y nano git wget nginx mysql-server expect unzip

#Installing dotnet core 3.1
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update; \
  sudo apt-get install -y apt-transport-https && \
  sudo apt-get update && \
  sudo apt-get install -y dotnet-sdk-3.1

#Automated mysql-secure-installation
./auto_sql_secure.sh $SQL_ROOT_PASS

#Create MySQL users and import databases
sudo mysql -e "CREATE USER '$SQL_USER'@'localhost' IDENTIFIED WITH mysql_native_password BY '$SQL_USER_PASS';"
sudo mysql -e "GRANT ALL ON *.* TO '$SQL_USER'@'localhost';"
sudo mysql --user=$SQL_USER --password=$SQL_USER_PASS < db.sql

#Unzip SSL certificate
unzip -u $SSL_CERT_NAME -d /home/$USERNAME

#Getting website from Github
sudo killall dotnet
rm -r /home/$USERNAME/$GITPREFIX
rm -r /home/$USERNAME/publish
cd /home/$USERNAME
git clone $GITLINK
cp -avrfn /home/$USERNAME/$GITPREFIX/$APPNAME/$APPNAME/bin/Release/netcoreapp3.1/publish /home/$USERNAME/publish
mv /home/$USERNAME/publish/$APPNAME.dll /home/$USERNAME/publish/$APPNAME.dll

#Installing service 
echo "[Unit]
Description=$APPNAME .NET Web API App running on Ubuntu

[Service]
WorkingDirectory=/home/$USERNAME/publish
ExecStart=/usr/bin/dotnet /home/$USERNAME/publish/$APPNAME.dll
Restart=always
# Restart service after 10 seconds if the dotnet service crashes:
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=dotnet-$APPLOWERNAME
User=$USERNAME
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target
"> /etc/systemd/system/kestrel-$APPLOWERNAME.service
sudo systemctl enable kestrel-$APPLOWERNAME.service
sudo systemctl start kestrel-$APPLOWERNAME.service
sudo systemctl status kestrel-$APPLOWERNAME.service

#Install nginx config files
echo   "##
# You should look at the following URL's in order to grasp a solid understanding
# of Nginx configuration files in order to fully unleash the power of Nginx.
# https://www.nginx.com/resources/wiki/start/
# https://www.nginx.com/resources/wiki/start/topics/tutorials/config_pitfalls/
# https://wiki.debian.org/Nginx/DirectoryStructure
#
# In most cases, administrators will remove this file from sites-enabled/ and
# leave it as reference inside of sites-available where it will continue to be
# updated by the nginx packaging team.
#
# This file will automatically load configuration files provided by other
# applications, such as Drupal or Wordpress. These applications will be made
# available underneath a path with that package name, such as /drupal8.
#
# Please see /usr/share/doc/nginx-doc/examples/ for more detailed examples.
##

# Default server configuration
#
server {
#       listen 80 default_server;
#       listen [::]:80 default_server;

        # SSL configuration
        #
        listen 443 ssl default_server;
        listen [::]:443 ssl default_server;

        ssl on;
        ssl_certificate $CERT_LOCATION;
        ssl_certificate_key $KEY_LOCATION;
#
        # Note: You should disable gzip for SSL traffic.
        # See: https://bugs.debian.org/773332
        #
        # Read up on ssl_ciphers to ensure a secure configuration.
        # See: https://bugs.debian.org/765782
        #
        # Self signed certs generated by the ssl-cert package
        # Don't use them in a production server!
        #
        # include snippets/snakeoil.conf;

        root /var/www/html;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name $DOMAINNAME *.$DOMAINNAME;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                #try_files $uri $uri/ =404;
                proxy_pass         http://localhost:5000;
                proxy_http_version 1.1;
                proxy_set_header   Upgrade \$http_upgrade;
                proxy_set_header   Connection keep-alive;
                proxy_set_header   Host \$host;
                proxy_cache_bypass \$http_upgrade;
                proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_set_header   X-Forwarded-Proto \$scheme;
        }

        # pass PHP scripts to FastCGI server
        #
        #location ~ \.php$ {
        #       include snippets/fastcgi-php.conf;
        #
        #       # With php-fpm (or other unix sockets):
        #       fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        #       # With php-cgi (or other tcp sockets):
		        #       fastcgi_pass 127.0.0.1:9000;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #       deny all;
        #}
}


# Virtual Host configuration for example.com
#
# You can move that to a different file under sites-available/ and symlink that
# to sites-enabled/ to enable it.
#
#server {
#       listen 80;
#       listen [::]:80;
#
#       server_name example.com;
#

#       root /var/www/example.com;
#       index index.html;
#
#       location / {
#               try_files $uri $uri/ =404;
#       }
#}
server{
        listen 80;
        server_name $DOMAINNAME *.$DOMAINNAME;
        return 301 https://$DOMAINNAME\$request_uri;
}
" > /etc/nginx/sites-enabled/default
sudo service nginx restart
