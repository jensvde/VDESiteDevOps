#!/bin/bash

#Variables:
SQL_ROOT_PASS=Test@1234
SQL_USER=winkel
SQL_USER_PASS=Winkeltje@1234
DOMAINNAME=vandeneynde.eu
USERNAME="jens"
WEBMIN_USERNAME=peggy
WEBMIN_PASSWORD=password
SSL_CERT_NAME="/home/$USERNAME/vandeneynde_eu.zip"
APPNAME=VandenEynde
APPLOWERNAME=vandeneynde
GITPREFIX=VDESite
GITLINK="https://github.com/jensvde/$GITPREFIX.git"
CERT_LOCATION="/home/$USERNAME/vandeneynde_eu.crt"
KEY_LOCATION="/home/$USERNAME/vandeneynde.key"

#Begin of program
#Check if root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

#Update and upgrade
sudo apt-get update && sudo apt-get upgrade -y

#Add webmin source if not exist
if grep -Fxq "deb http://download.webmin.com/download/repository sarge contrib" /etc/apt/sources.list 
then
        echo "Exists"
else
        echo "Add"
        echo "deb http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
        wget -q -O- http://www.webmin.com/jcameron-key.asc | sudo apt-key add
	sudo apt update
fi

#Installing nano, git, wget, nginx, mysql-server, expect, unzip, webmin, php, php-json, composer
sudo apt-get install -y nano git wget nginx mysql-server expect unzip webmin 

#Configure default user
echo "$WEBMIN_USERNAME:$WEBMIN_PASSWORD" >> /etc/webmin/miniserv.users
echo  "$WEBMIN_USERNAME: acl adsl-client ajaxterm apache at backup-config bacula-backup bandwidth bind8 burner change-user cluster-copy cluster-cron cluster-passwd cluster-shell cluster-software cluster-useradmin cluster-usermin cluster-webmin cpan cron custom dfsadmin dhcpd dovecot exim exports fail2ban fdisk fetchmail filemin file filter firewall6 firewalld firewall fsdump grub heartbeat htaccess-htpasswd idmapd inetd init inittab ipfilter ipfw ipsec iscsi-client iscsi-server iscsi-target iscsi-tgtd jabber krb5 ldap-client ldap-server ldap-useradmin logrotate lpadmin lvm mailboxes mailcap man mon mount mysql net nis openslp package-updates pam pap passwd phpini postfix postgresql ppp-client pptp-client pptp-server procmail proc proftpd qmailadmin quota raid samba sarg sendmail servers shell shorewall6 shorewall smart-status smf software spam squid sshd status stunnel syslog syslog-ng system-status tcpwrappers telnet time tunnel updown useradmin usermin vgetty webalizer webmincron webminlog webmin wuftpd xinetd virtual-server virtualmin-awstats jailkit virtualmin-htpasswd virtualmin-sqlite virtualmin-dav ruby-gems virtualmin-git php-pear virtualmin-init virtualmin-slavedns virtualmin-registrar" >> /etc/webmin/webmin.acl
/usr/share/webmin/changepass.pl /etc/webmin $WEBMIN_USERNAME $WEBMIN_PASSWORD

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
sudo mysql -e "CREATE DATABASE db;"
sudo mysql -e "CREATE DATABASE db_users;"
sudo mysql --user=winkel --password=Winkeltje@1234 db < db_OK.db
sudo mysql --user=winkel --password=Winkeltje@1234 db_users < db_users_OK.db

#Unzip SSL certificate
unzip -u $SSL_CERT_NAME -d /home/$USERNAME/

#Getting website from Github
sudo killall dotnet
rm -r /home/$USERNAME/$APPNAME
rm -r /home/$USERNAME/publish
git clone $GITLINK /home/$USERNAME/$GITPREFIX
cp -avrfn /home/$USERNAME/$GITPREFIX/$APPNAME/bin/Release/netcoreapp3.1/publish /home/$USERNAME/publish

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
sudo service nginx stop

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

echo "
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
        worker_connections 768;
        # multi_accept on;
}

http {

        ##
        # Basic Settings
        ##

        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;
        keepalive_timeout 65;
        types_hash_max_size 2048;
        # server_tokens off;

        # server_names_hash_bucket_size 64;
        # server_name_in_redirect off;

        include /etc/nginx/mime.types;
        default_type application/octet-stream;
		client_max_body_size 4096M;

        ##
        # SSL Settings
        ##

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
        ssl_prefer_server_ciphers on;

        ##
        # Logging Settings
        ##

        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        ##
        # Gzip Settings
        ##

        gzip on;

        # gzip_vary on;
        # gzip_proxied any;
        # gzip_comp_level 6;
        # gzip_buffers 16 8k;
        # gzip_http_version 1.1;
        # gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
		
        ##
        # Virtual Host Configs
        ##

        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites-enabled/*;
}
#mail {
#       # See sample authentication script at:
#       # http://wiki.nginx.org/ImapAuthenticateWithApachePhpScript
#
#       # auth_http localhost/auth.php;
#       # pop3_capabilities "TOP" "USER";
#       # imap_capabilities "IMAP4rev1" "UIDPLUS";
#
#       server {
#               listen     localhost:110;
#               protocol   pop3;
#               proxy      on;
#       }
#
#       server {
#               listen     localhost:143;
#               protocol   imap;
#               proxy      on;
#       }
#}" > /etc/nginx/nginx.conf
sudo service nginx start
service nginx restart  

#Fixing webmin SSL
cat /home/$USERNAME/$KEY_LOCATION /home/$USERNAME/$CERT_LOCATION > miniserv.pem
echo "extracas=/etc/webmin/cabundle.crt" >> /etc/webmin/miniserv.conf
cp /home/$USERNAME/miniserv.pem /etc/webmin
cp /home/$USERNAME/cabundle.crt /etc/webmin
service webmin restart

#Giving user permission to use shutdown
echo "$USERNAME ALL = NOPASSWD: /sbin/halt, /sbin/reboot, /sbin/poweroff" >> /etc/shutdown.allow
