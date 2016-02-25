#!/bin/bash
#
# StackScript Bash Library
#
# Copyright (c) 2010 Linode LLC / Christopher S. Aker <caker@linode.com>
# All rights reserved.

###########################################################
# mysql-server
###########################################################

function mysql_install {
    # $1 - the mysql root password

    if [ ! -n "$1" ]; then
        echo "mysql_install() requires the root pass as its first argument"
        return 1;
    fi

    echo -e "\n--- Installing MySQL ---"
    
    echo "mysql-server mysql-server/root_password password $1" | sudo debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password $1" | sudo debconf-set-selections
    sudo apt-get -y install mysql-server mysql-client

    echo "Sleeping while MySQL starts up for the first time..."
    sleep 5
}

function mysql_tune {
    # Tunes MySQL's memory usage to utilize the percentage of memory you specify, defaulting to 40%

    # $1 - the percent of system memory to allocate towards MySQL

    if [ ! -n "$1" ];
        then PERCENT=40
        else PERCENT="$1"
    fi

    sed -i -e 's/^#skip-innodb/skip-innodb/' /etc/mysql/my.cnf # disable innodb - saves about 100M

    MEM=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo) # how much memory in MB this system has
    MYMEM=$((MEM*PERCENT/100)) # how much memory we'd like to tune mysql with
    MYMEMCHUNKS=$((MYMEM/4)) # how many 4MB chunks we have to play with

    # mysql config options we want to set to the percentages in the second list, respectively
    OPTLIST=(key_buffer sort_buffer_size read_buffer_size read_rnd_buffer_size myisam_sort_buffer_size query_cache_size)
    DISTLIST=(75 1 1 1 5 15)

    for opt in ${OPTLIST[@]}; do
        sed -i -e "/\[mysqld\]/,/\[.*\]/s/^$opt/#$opt/" /etc/mysql/my.cnf
    done

    for i in ${!OPTLIST[*]}; do
        val=$(echo | awk "{print int((${DISTLIST[$i]} * $MYMEMCHUNKS/100))*4}")
        if [ $val -lt 4 ]
            then val=4
        fi
        config="${config}\n${OPTLIST[$i]} = ${val}M"
    done

    sed -i -e "s/\(\[mysqld\]\)/\1\n$config\n/" /etc/mysql/my.cnf

    touch /tmp/restart-mysql
}

function mysql_create_database {
    # $1 - the mysql root password
    # $2 - the db name to create

    if [ ! -n "$1" ]; then
        echo "mysql_create_database() requires the root pass as its first argument"
        return 1;
    fi
    if [ ! -n "$2" ]; then
        echo "mysql_create_database() requires the name of the database as the second argument"
        return 1;
    fi

    echo -e "\n--- Creating DB '$2' ---"
    echo "CREATE DATABASE $2;" | mysql -u root -p$1
}

function mysql_create_user {
    # $1 - the mysql root password
    # $2 - the user to create
    # $3 - their password

    if [ ! -n "$1" ]; then
        echo "mysql_create_user() requires the root pass as its first argument"
        return 1;
    fi
    if [ ! -n "$2" ]; then
        echo "mysql_create_user() requires username as the second argument"
        return 1;
    fi
    if [ ! -n "$3" ]; then
        echo "mysql_create_user() requires a password as the third argument"
        return 1;
    fi

    echo -e "\n--- Creating DB User '$2'---"
    echo "CREATE USER '$2'@'localhost' IDENTIFIED BY '$3';" | mysql -u root -p$1
}

function mysql_grant_user {
    # $1 - the mysql root password
    # $2 - the user to bestow privileges 
    # $3 - the database

    if [ ! -n "$1" ]; then
        echo "mysql_create_user() requires the root pass as its first argument"
        return 1;
    fi
    if [ ! -n "$2" ]; then
        echo "mysql_create_user() requires username as the second argument"
        return 1;
    fi
    if [ ! -n "$3" ]; then
        echo "mysql_create_user() requires a database as the third argument"
        return 1;
    fi

    echo -e "\n--- Grant privs for User: $2 on DB: $3 ---"
    echo "GRANT ALL PRIVILEGES ON $3.* TO '$2'@'localhost';" | mysql -u root -p$1
    echo "FLUSH PRIVILEGES;" | mysql -u root -p$1

}

###########################################################
# Elliot Lewis
###########################################################

function mysql_update {

    # Update MySQL
    mysqldump --lock-all-tables -u root -p --all-databases > dump.sql # Backup
    
    sudo apt-get remove mysql-server # Remove old
    sudo apt-get autoremove
    sudo apt-get install mysql-client-5.6 mysql-client-core-5.6 # Install new
    sudo apt-get install mysql-server-5.6
    
    mysql -u root -p < dump.sql # Restore data
    
    echo -e "\n--- MySQL updated to 5.6 ---"
}

function mysql_run_sql_from_file {
    # $1 - the mysql root password
    # $2 - db name
    # $3 - path to file

    if [ ! -n "$1" ]; then
        echo "Error: mysql_run_sql_from_file() requires the root pass as its first argument"
        return 1;
    fi
    
    if [ ! -n "$2" ]; then
        echo "Error: mysql_run_sql_from_file() requires db name as second argument"
        return 1;
    fi
    
    if [ ! -n "$3" ]; then
        echo "Error: mysql_run_sql_from_file() requires path to file as third argument"
        return 1;
    fi

    echo -e "\n--- Running SQL from $3 ---"
    echo "USE $2;source $3;" | mysql -u root -p$1
}

function mysql_ext_php_install {
    echo -e "\n--- Installing PHP MySQL extension ---"
    sudo apt-get install php5-mysql
    sudo service apache2 restart
}

echo -e "\n--- mysql.sh imported ---"