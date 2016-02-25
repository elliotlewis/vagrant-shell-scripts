#!/usr/bin/env bash

###########################################################
# Linode
###########################################################

function php_install_with_apache {
    #apt-get install -q -y php5 libapache2-mod-php5 php5-curl php5-cli php5-gd

    #aptitude -y install php5 php5-mysql libapache2-mod-php5
    sudo aptitude -y install php5 php5-mysql libapache2-mod-php5 php5-curl php5-cli php5-gd
    touch /tmp/restart-apache2
}

function php_tune {
    # Tunes PHP to utilize up to 32M per process

    sed -i'-orig' 's/memory_limit = [0-9]\+M/memory_limit = 32M/' /etc/php5/apache2/php.ini
    touch /tmp/restart-apache2
}

###########################################################
# Elliot Lewis
###########################################################

function install_phpmyadmin {
    
    if [ ! -n "$1" ]; then
         echo "install_phpmyadmin() requires the MySQL root password as the first argument"
         return 1;
    fi
    
    if [ ! -n "$2" ] || [ ! -n "$3" ]; then
         echo "install_phpmyadmin() requires the 'user' as the second argument and 'password' as the third for basic authentication"
         return 1;
    fi

    #
    # $1 - Required - root DB password
    # $2 - Required - username
    # $3 - Required - password
    DBPASSWD="$1"
    USERNAME="$2"
    USERPASS="$3"

    # check if phpMyAdmin already installed
    if [ ! -e "/etc/phpmyadmin" ]; then
        # sudo apt-get install phpmyadmin apache2-utils # cli version to ans questions
    
        echo -e "\n--- Install phpmyadmin ---"
        sudo echo "mysql-server mysql-server/root_password password $DBPASSWD" | debconf-set-selections
        sudo echo "mysql-server mysql-server/root_password_again password $DBPASSWD" | debconf-set-selections
        sudo echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
        sudo echo "phpmyadmin phpmyadmin/app-password-confirm password $DBPASSWD" | debconf-set-selections
        sudo echo "phpmyadmin phpmyadmin/mysql/admin-pass password $DBPASSWD" | debconf-set-selections
        sudo echo "phpmyadmin phpmyadmin/mysql/app-pass password $DBPASSWD" | debconf-set-selections
        sudo echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | debconf-set-selections
        sudo apt-get -y install phpmyadmin
    fi

    # Include phpMyAdmin in Apach confs
    # *Only required using apache2-utils install, debconf version installs vhost and enables
    #echo "" > /etc/apache2/apache2.conf
    #echo "# Include /etc/phpmyadmin/apache.conf" > /etc/apache2/apache2.conf
    #echo "<VirtualHost *:80>" > /etc/apache2/apache2.conf

    # phpMyAdmin requires mcrypt, install if required and enable
    if [ ! -e "/etc/php5/mods-available/mcrypt.ini" ]; then
        echo "\n--- Installing mcrypt ---"
        sudo apt-get install mcrypt php5-mcrypt
    fi

    echo -e "\n--- Endabling mcrypt ---"
    sudo php5enmod mcrypt
    
    # Password protect phpMyAdmin using basic authentication
    if [ ! -e "/usr/share/phpmyadmin/.htaccess" ]; then
    
        # http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script
        # command -v htpasswd >/dev/null 2>&1 || { echo "I require foo but it's not installed.  Aborting." >&2; }
        if [ command -v htpasswd != ""]; then
        #if [ hash htpasswd 2>/dev/null != ""]; then
            echo -e "\n--- Installing apache2-utils for htpasswd ---"
            sudo apt-get --assume-yes --quiet install apache2-utils
        fi
    
        echo -e "\n--- Setting-up basic authentication ---"
        
        # Add 'AllowOverride All' to conf file
        allowoverrideinfile=$( grep -c 'AllowOverride All' /etc/phpmyadmin/apache.conf )
        if [ $allowoverrideinfile -eq 0 ]; then
            sudo sed -i 's/DirectoryIndex index.php/DirectoryIndex index.php\n\tAllowOverride All/' '/etc/phpmyadmin/apache.conf'
        fi

        # Create .htaccess file
        sudo touch /usr/share/phpmyadmin/.htaccess
        
        # Installed phpmyadmin has owner root, as sudo .htaccess also root, so need to act as root to write
        echo "AuthType Basic" | sudo tee --append /usr/share/phpmyadmin/.htaccess > /dev/null
        echo "AuthName \"Restricted Files\"" | sudo tee --append /usr/share/phpmyadmin/.htaccess > /dev/null
        echo "AuthUserFile /etc/apache2/.phpmyadmin.htpasswd" | sudo tee --append /usr/share/phpmyadmin/.htaccess > /dev/null
        echo "Require valid-user" | sudo tee --append /usr/share/phpmyadmin/.htaccess > /dev/null

        sudo htpasswd -b -c /etc/apache2/.phpmyadmin.htpasswd $USERNAME $USERPASS
    fi

    # restart apache
    sudo service apache2 restart
}

echo -e "\n--- php.sh imported ---"