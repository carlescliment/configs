#!/bin/bash

external_files_folder='/var/local/poker-red'
vendors_folder="$external_files_folder/vendor"
site_folder='/var/www/gyron/portal/trunk'
console="$site_folder/src/console.php"

mkdir $external_files_folder
mkdir $vendors_folder
chown vagrant.www-data $vendors_folder

su -c "ln -s $vendors_folder $site_folder/src/vendor" vagrant
su -c "composer update --working-dir=$site_folder/src --no-interaction" vagrant
su -c "php $console database:update" vagrant

