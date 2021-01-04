#!/bin/bash

echo "uncomment bind address"
read -p "Press any key to resume ..."

sudo sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
sudo service mysql restart
echo "creating user winkeltemp identified by Winkeltje@1234"
sudo mysql -e "CREATE USER 'winkeltemp'@'%' IDENTIFIED WITH mysql_native_password BY 'Winkeltje@1234';"
sudo mysql -e "GRANT ALL ON *.* TO 'winkeltemp'@'%';"
sudo mysql -e "FLUSH PRIVILEGES;"
echo "press enter to delete user"
read -p "Press any key to resume ..."

sudo mysql -e "DROP USER 'winkeltemp'@'%'";
sudo mysql -e "FLUSH PRIVILEGES;"
sudo mysql -e "select host, user from mysql.user;"

echo "comment bind address"
read -p "Press any key to resume ..."

sudo sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
sudo service mysql restart

sudo mysql -e "SHOW DATABASES;"
