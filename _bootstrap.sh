#!/usr/bin/env bash

# import
<%= import 'system.sh' %>
<%= import 'apache.sh' %>
<%= import 'php.sh' %>
<%= import 'mysql.sh' %>

# Variables
SYSUSER="vagrant"
SUDOPASS="vagrant"

AUTHUSER="fish"
AUTHPASS="fish"

DBROOTPASSWD="root"
DBNAME="lexicon_db"
DBUSER="lexicon_user"
DBPASS="2SVueUlZYOwV"

# Bash profile
inc_custom_bash

# Configure distro
system_update

# Prob need curl, but prob alrady installed
sudo apt-get install -q -y curl

# Install Apache
apache_install
sudo a2enmod rewrite
sudo a2enmod expires
sudo service apache2 restart

# Install PHP
php_install_with_apache
php_tune

# By default Apache user only in it's own group
# groups www-data
# $ www-data : www-data
# Add www-data user to vagrant group so Apache can access symbolic link of /var/www -> /vagrant
echo -e "\n--- Adding Apache user to vagrant group ---"
sudo usermod -a -G vagrant www-data
echo -e "\n--- Adding vagrant user to Apache group ---"
sudo usermod -a -G www-data vagrant

# Change Apache Working Directory, set local vagrant as symbolic link for editing files locally
if [[ -L "/var/www" && -d "/var/www" ]]
then
    echo -e "\n--- /var/www/ already sym-linked to vagrant ---"
else
    echo -e "\n--- Setting Apache root /var/www/ to synced_folder ---"
    sudo rm -rf /var/www
    sudo ln -fs /vagrant /var/www
fi

# Disable default apache site
echo -e "\n--- Disable default site ---"
sudo a2dissite 00*
sudo service apache2 restart

# Setup each vhost
apache_virtualhost lexiconcms dev
apache_virtualhost lexiconfe dev /var/www/lexiconfe/dev_build/dist

# As Craft site
apache_virtualhost_change_for_craft lexiconcms

#
# MySQL
#

# Install MySQL
mysql_install $DBROOTPASSWD
mysql_ext_php_install

# Create DB & user
mysql_create_database $DBROOTPASSWD $DBNAME
mysql_create_user $DBROOTPASSWD $DBUSER $DBPASS
mysql_grant_user $DBROOTPASSWD $DBUSER $DBNAME

# Run SQL from named file
mysql_run_sql_from_file $DBROOTPASSWD $DBNAME /home/vagrant/lexicon_db.sql

# Install PHP
install_phpmyadmin $SUDOPASS $AUTHUSER $AUTHPASS
