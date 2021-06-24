#!/bin/bash

echo  "Initializing FuelPHP configuration ..."
cd /var/www/site

# Set variables
db_config_file="/var/www/site/fuel/app/config/db.php"
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

if [[ -f "${db_config_file}" ]]; then

  # Update database configuration
  read -r -d '' dbconn_array << EOF
return array(
  'development' => array(),
EOF

  sed -i "s/return array.*/${dbconn_array}/g" "${db_config_file}"

  # @TODO: Need to add updates for email configuration
fi
