#!/bin/bash

echo "Initializing Yii2 configuration ..."
cd /var/www/site

# Set variables
config_file="/var/www/site/config/db.php"
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

if [[ -f "${config_file}" ]]; then

  # Update database configuration
  echo "Updating database configurations ..."
  sed -i "0,/.*'dsn' =>.*/{s/.*'dsn' =>.*/    'dsn' => 'mysql:host=db-${service_db,,};dbname=${db_name}',/g}" "${config_file}"
  sed -i "0,/.*'username' =>.*/{s/.*'username' =>.*/    'username' => '${db_username}',/g}" "${config_file}"
  sed -i "0,/.*'password' =>.*/{s/.*'password' =>.*/    'password' => '${db_password}',/g}" "${config_file}"

  # @TODO: Need to add updates for email configuration
fi
