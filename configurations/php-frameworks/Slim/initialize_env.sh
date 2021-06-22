#!/bin/bash

echo  "Initializing Symfony .env file ..."
cd /var/www/site

# Set variables
env="dev"
env_file="/var/www/site/.env"
env_env_file="/var/www/site/.env.${env}"
db_port="{{db_port}}"
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

# Make sure .env file exists
if [[ ! -f "$env_file" ]] && [[ -f "/var/www/site/.env.example" ]]; then
  cp /var/www/site/.env.example "${env_file}"
fi

if [[ -f "$env_file" ]]; then
  # Make modifications to .env.dev file
  echo "Modifying ${env_file} ..."
  sed -i "s/APP_ENV=.*/APP_ENV=${env}XXXX/g" "${env_file}"

  echo "Modifying ${env_env_file} ..."
  touch "${env_env_file}"
  sed -i "s/APP_ENV=.*/APP_ENV=local/g" "${env_env_file}"
  echo "" >> "${env_env_file}"
  echo "# database credentials" >> "${env_env_file}"
  echo "DB_USER=${db_username}" >> "${env_env_file}"
  echo "DB_PASS=${db_password}" >> "${env_env_file}"
fi

# Generate app encryption key
echo  "Generating app encryption key ..."
cd /var/www/site
php artisan key:generate

# Clear Symfony cache
echo  "Clearing Symfony cache ..."
cd /var/www/site
php bin/console cache:pool:clear cache.global_clearer
