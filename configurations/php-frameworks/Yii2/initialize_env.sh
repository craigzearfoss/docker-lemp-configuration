#!/bin/bash

echo "Initializing Yii2 configuration ..."
cd /var/www/site

# Set variables
db_config_file="/var/www/site/config/db.php"
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

# Update database config/db.php
echo "Updating config/db.php ..."
sed -i "s/.*'dsn' =>.*/    'dsn' => 'mysql:host=db-${service_db,,};dbname=${db_name};port=${db_port}',/g" "${db_config_file}"
sed -i "s/.*'username' =>.*/    'username' => '${db_username}',/g" "${db_config_file}"
sed -i "s/.*'password' =>.*/    'password' => '${db_password}',/g" "${db_config_file}"
