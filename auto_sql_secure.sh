#!/usr/bin/expect

#Set password from parameter
set SQLROOTPASS [lindex $argv 0]

#Start of script mysql_secure_installation automation
spawn sudo mysql_secure_installation
expect "Press y|Y for Yes, any other key for No: "
send -- "Y\r"

expect "Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG: "
send -- "2\r"

expect "password: "
send -- "$SQLROOTPASS\r"

expect "password"
send -- "$SQLROOTPASS\r"

expect "Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :"
send -- "Y\r"

expect "Remove anonymous users? (Press y|Y for Yes, any other key for No) :"
send -- "Y\r"

expect "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :"
send -- "Y\r"

expect "Remove test database and access to it? (Press y|Y for Yes, any other key for No) :"
send -- "Y\r"

expect "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :"
send -- "Y\r"

expect "All done!"
send -- "\r"
