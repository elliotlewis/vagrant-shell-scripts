#!/bin/bash
#
# Copyright (c) 2016 Fishawack / Elliot Lewis <elliot.lewis@f-grp.com>

###########################################################
# wordpress
###########################################################

function mysql_fix_wp_links {
    # $1 - mysql root password
    # $2 - db name
    # $3 - find url
    # $4 - replace url
    
    echo -e "\n--- Fix WP abs links ---"
    echo "USE $2;UPDATE npc_options SET option_value = replace( option_value, '$3', '$4' );UPDATE npc_postmeta SET meta_value = replace( meta_value, '$3', '$4' );UPDATE npc_posts SET guid = replace( guid, '$3', '$4' );UPDATE npc_posts SET post_content = replace( post_content, '$3', '$4' );" | mysql -u root -p$1
}