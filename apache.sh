#!/usr/bin/env bash

###########################################################
# Linode
###########################################################

function apache_install {
    # installs the system default apache2 MPM
    sudo aptitude -y install apache2

    #a2dissite default # disable the interfering default virtualhost

    # clean up, or add the NameVirtualHost line to ports.conf
    #sed -i -e 's/^NameVirtualHost \*$/NameVirtualHost *:80/' /etc/apache2/ports.conf
    #if ! grep -q NameVirtualHost /etc/apache2/ports.conf; then
    #    echo 'NameVirtualHost *:80' > /etc/apache2/ports.conf.tmp
    #    cat /etc/apache2/ports.conf >> /etc/apache2/ports.conf.tmp
    #    mv -f /etc/apache2/ports.conf.tmp /etc/apache2/ports.conf
    #fi
}

###########################################################
# Elliot Lewis
###########################################################

function apache_virtualhost {
    # Configures a VirtualHost

    # $1 - required - directory to create
    # $2 - required - hostname of the virtualhost to create
    # $3 - optional - alternative path to public root

    if [ ! -n "$1" ]; then
        echo "Error: apache_virtualhost() requires the directory as the first argument, eg localhost"
        return 1;
    fi
    
    if [ ! -n "$2" ]; then
        echo "Error: apache_virtualhost() requires virtualhost as the second argument, eg localhost.dev"
        return 1;
    fi

    if [ -e "/etc/apache2/sites-available/$1.conf" ]; then
        echo /etc/apache2/sites-available/$1.conf already exists
        return;
    fi

    echo -e "\n--- Configuring vhost: '$1' ---"
    
    # path to root
    if [ ! -n "$3" ]; then
        PUBLICROOT=/var/www/$1/public_html
    else
        PUBLICROOT=$3
    fi
    
    # Create public_html and logs
    if [ ! -d "/var/www/$1/public_html" ]; then
        echo -e "\n--- Creating public_html for '$1' ---"
        sudo mkdir -p $PUBLICROOT /var/www/$1/logs
    fi
    
    # Incase exists, set correct perms
    sudo chmod -R 755 $PUBLICROOT

    # script can't write to conf file unless sudo, so set owner (headbang)
    sudo touch /etc/apache2/sites-available/$1.conf
    sudo chown vagrant:vagrant /etc/apache2/sites-available/$1.conf
    
    echo "<VirtualHost *:80>" > /etc/apache2/sites-available/$1.conf
    echo "    ServerName $2" >> /etc/apache2/sites-available/$1.conf
    echo "    DocumentRoot $PUBLICROOT" >> /etc/apache2/sites-available/$1.conf
    echo "    ErrorLog /var/www/$1/logs/error.log" >> /etc/apache2/sites-available/$1.conf
    echo "    CustomLog /var/www/$1/logs/access.log combined" >> /etc/apache2/sites-available/$1.conf
    echo "" >> /etc/apache2/sites-available/$1.conf
    echo "    <Directory \"$PUBLICROOT\">" >> /etc/apache2/sites-available/$1.conf
    echo "        Options FollowSymLinks" >> /etc/apache2/sites-available/$1.conf
    echo "        AllowOverride All" >> /etc/apache2/sites-available/$1.conf
    echo "        <RequireAll>" >> /etc/apache2/sites-available/$1.conf
    echo "        Require all granted" >> /etc/apache2/sites-available/$1.conf
    echo "        </RequireAll>" >> /etc/apache2/sites-available/$1.conf
    echo "    </Directory>" >> /etc/apache2/sites-available/$1.conf
    echo "</VirtualHost>" >> /etc/apache2/sites-available/$1.conf

    # Apache < 2.4 htaccess directives
    #echo "        Order Allow,Deny" >> /etc/apache2/sites-available/$1.conf
    #echo "        Allow From All" >> /etc/apache2/sites-available/$1.conf
    
    sudo a2ensite $1

    #sudo chmod -R 755 /var/www/npc-spanish/public_html
    # 775?
    #sudo chmod 644 /var/www/npc-spanish/public_html/.htaccess
    #find . -type f -print0 | xargs -0 chmod 644
    #find . -type f -print0 | xargs -0 chmod 644
    #find /opt/lampp/htdocs -type d -exec chmod 755 {} \;
    
    sudo service apache2 restart
}

function apache_virtualhost_change_for_craft {
    # VirtualHost must already exist

    # $1 - required - the hostname of the virtualhost to create 

    if [ ! -n "$1" ]; then
        echo -e "\n--- Error: apache_virtualhost_change_for_craft() requires the hostname as the first argument"
        return 1;
    fi
    
    if [ ! -e "/etc/apache2/sites-available/$1.conf" ]; then
        echo -e "\n--- Error: virtual host '$1' should already exist before amending! --"
        return;
    fi
    
    # Create public if not intalled Craft yet
    if [ ! -d "/var/www/$1/public_html/public" ]; then
        sudo mkdir -p /var/www/$1/public_html/public
    fi

    # Craft serves site from public
    sudo sed -i 's/\/var\/www\/$1\/public_html/\/var\/www\/$1\/public_html\/public/g' '/etc/apache2/sites-available/$1.conf'
}

#sudo chmod -R 774 /var/www/lexicon/public_html/craft/storage/

echo -e "\n--- apache.sh imported ---"