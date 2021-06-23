#!/bin/bash

echo  "Initializing CakePHP configuration ..."
cd /var/www/site

# Set variables
config_file="/var/www/site/config/app_local.php"
example_config_file="/var/www/site/config/app_local.example.php"
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

# Make sure configuration file exists
if [[ ! -f "${config_file}" ]] && [[ -f "${example_config_file}" ]]; then
  cp "${example_config_file}" "${config_file}"
fi

if [[ -f "${config_file}" ]]; then

  # Update database configuration
  echo "Updating database configurations ..."
  sed -i "0,/.*'host' => 'localhost',.*/{s/.*'host' => 'localhost',.*/            'host' => 'db-${service_db,,}',/g}" "${config_file}"
  sed -i "0,/.*'username' => 'my_app',.*/{s/.*'username' => 'my_app',.*/            'username' => '${db_username}',/g}" "${config_file}"
  sed -i "0,/.*'password' => 'secret',.*/{s/.*'password' => 'secret',.*/            'password' => '${db_password}',/g}" "${config_file}"
  sed -i "0,/.*'database' => 'my_app',.*/{s/.*'database' => 'my_app',.*/            'database' => '${db_name}',/g}" "${config_file}"

  # @TODO: Need to add updates for email configuration
fi

# Clear CakePHP cache
