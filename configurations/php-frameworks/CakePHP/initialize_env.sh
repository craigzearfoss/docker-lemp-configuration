#!/bin/bash

echo  "Initializing CakePHP configuration ..."
cd /var/www/site

# Set variables
env_file="/var/www/site/config/.env"
app_local_file="/var/www/site/config/app_local.php"
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

# Make sure .env file exists
if [[ ! -f "$env_file" ]]; then
  if [[ -f "/var/www/site/config/.env.example" ]]; then
    cp /var/www/site/config/.env.example "${env_file}"
  elif [[ -f "/var/www/site/config/env" ]]; then
    cp /var/www/site/config/env "${env_file}"
  else
    cp /var/www/configurations/php-frameworks/CakePHP/.env "${env_file}"
  fi
fi

# Make sure app_local.php file exists
if [[ ! -f "$app_local_file" ]]; then
  if [[ -f "/var/www/site/config/app_local.example.php" ]]; then
    cp /var/www/site/config/app_local.example.php "${app_local_file}"
    cp /var/www/configurations/php-frameworks/CakePHP/app_local.php "${app_local_file}"
  fi
fi

# Update app_local.php file
echo "Updating app_local.php ..."
sed -i "0,/.*'port' => 'non_standard_port_number',.*/{s/.*'port' => 'non_standard_port_number',.*/            'port' => '${db_port}',/g}" "${app_local_file}"
sed -i "0,/.*'host' => 'localhost',.*/{s/.*'host' => 'localhost',.*/            'host' => 'db-${service_db,,}',/g}" "${app_local_file}"
sed -i "0,/.*'username' => 'my_app',.*/{s/.*'username' => 'my_app',.*/            'username' => '${db_username}',/g}" "${app_local_file}"
sed -i "0,/.*'password' => 'secret',.*/{s/.*'password' => 'secret',.*/            'password' => '${db_password}',/g}" "${app_local_file}"
sed -i "0,/.*'database' => 'my_app',.*/{s/.*'database' => 'my_app',.*/            'database' => '${db_name}',/g}" "${app_local_file}"

# Make modifications to .env file
echo "Modifying .env file ..."
sed -i "s/export APP_NAME=.*/export APP_NAME=\"${project_name}\"/g" "${env_file}"
sed -i "s/export DEBUG=.*/export DEBUG=\"true\"/g" "${env_file}"

hash=$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev 2>&1)
hash=$(echo -n $hash | md5sum | cut -c 1-32)
sed -i "s/export SECURITY_SALT=.*/export SECURITY_SALT=\"${hash}\"/g" "${env_file}"

# @TODO: Need to add updates for email configuration
