#!/bin/bash

echo  "Initializing FuelPHP configuration ..."
cd /var/www/site

# Set variables

config_file="/var/www/site/fuel/app/config/config.php"
db_dev_config_file="/var/www/site/fuel/app/config/development/db.php"
db_admin_port="{{db_admin_port}}"
db_exposed_port="{{db_exposed_port}}"
db_name="{{db_name}}"
db_password="{{db_password}}"
db_port="{{db_port}}"
db_username="{{db_username}}"
full_install={{full_install}}
git_repo="{{git_repo}}"
port="{{port}}"
project_name="{{project_name}}"
service_db="{{service_db}}"

# Make modifications to config/config.php file
echo "Modifying config/config.php ..."
sed -i "s/.*'base_url'.*/    'base_url' => 'http:\/\/localhost:${port}\/',/g" "${config_file}"

# Make modifications to config/development/db.php file
echo "Modifying config/development/db.php ..."
sed -i "s/.*'dsn'.*/			'dsn'      => 'mysql:host=db-${service_db};port=${db_port};dbname=${db_name,,}',/g" "${db_dev_config_file}"
sed -i "s/.*'username'.*/			'username' => '${db_username}',/g" "${db_dev_config_file}"
sed -i "s/.*'password'.*/			'password' => '${db_password}',/g" "${db_dev_config_file}"

# @TODO: Need to add updates for email configuration
