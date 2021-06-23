#!/bin/bash

echo "Initializing Yii2 configuration ..."
cd /var/www/site

# Set variables
config_file="/var/www/site/config/db.php"
db_admin_port="{{db_admin_port}}"
db_exposed_port="{{db_exposed_port}}"
db_name="{{db_name}}"
db_password="{{db_password}}"
db_username="{{db_username}}"
full_install={{full_install}}
git_repo="{{git_repo}}"
local_web_root="{{local_web_root}}"
port="{{port}}"
project_name="{{project_name}}"
service_db="{{service_db}}"
web_root="{{web_root}}"

if [[ -f "${config_file}" ]]; then

  # Update database configuration
  echo "Updating database configurations ..."
  sed -i "0,/.*'dsn' => 'mysql:host=localhost;dbname=yii2basic',.*/{s/.*'dsn' => 'mysql:host=localhost;dbname=yii2basic',,.*/    'dsn' => 'mysql:host=db-${service_db,,};dbname=${db_name}',,/g}" "${config_file}"
  sed -i "0,/.*'username' => 'root',.*/{s/.*'username' => 'root',.*/    'username' => '{$db_username}',/g}" "${config_file}"
  sed -i "0,/.*'password' => '',.*/{s/.*'password' => '',.*/    '${db_password}' => '',,/g}" "${config_file}"

  # @TODO: Need to add updates for email configuration
fi
