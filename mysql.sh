#!/bin/bash
SQL_USER="winkel"
SQL_PASS="Winkeltje@1234"

if [[ $1 == "--restart" ]]; then
	reboot
fi

if [ $# -lt 3 ]; then
    echo "No arguments supplied. Use mysql.sh --import/export [database name] [database file location]"
else
	if [[ $1 == "--import" ]]; then
		if [[ $2 == "db" ]]; then
			echo "Using application database (db)...";	
			if [ -f "$3" ]; then
				echo "Dropping, creating and importing application database (db)...";
				/usr/bin/mysql --user=$SQL_USER --password=$SQL_PASS -e "DROP DATABASE db;"
				/usr/bin/mysql --user=$SQL_USER --password=$SQL_PASS -e "CREATE DATABASE db;"
				/usr/bin/mysql --user=$SQL_USER --password=$SQL_PASS db < $3
			else
				echo "File $3 not found"
			fi
		fi

		if [[ $2 == "db_users" ]]; then
			echo "Using user database (db_users)...";	
			if [ -f "$3" ]; then
				echo "Dropping, creating and importing user database (db_users)...";
				/usr/bin/mysql --user=$SQL_USER --password=$SQL_PASS -e "DROP DATABASE db_users;"
				/usr/bin/mysql --user=$SQL_USER --password=$SQL_PASS -e "CREATE DATABASE db_users;"
				/usr/bin/mysql --user=$SQL_USER --password=$SQL_PASS db_users < $3
			else
				echo "File $3 not found"
			fi
		fi
	fi
	
	if [[ $1 == "--export" ]]; then
		if [[ $2 == "db" ]]; then
			echo "Exporting application database (db) to $3"
			/usr/bin/mysqldump --user=$SQL_USER --password=$SQL_PASS db > $3
		fi
		
		if [[ $2 == "db_users" ]]; then
			echo "Exporting user database (db_users) to $3"
			/usr/bin/mysqldump --user=$SQL_USER --password=$SQL_PASS db_users > $3
		fi
	fi
fi

