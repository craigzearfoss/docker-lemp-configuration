#!/bin/bash

echo  "Initializing Laravel .env file ..."
cd /var/www/site

# Set variables
env_file="/var/www/site/.env"
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
  if [[ -f "/var/www/site/.env.example" ]]; then
    cp /var/www/site/.env.example "${env_file}"
  elif [[ -f "/var/www/site/env" ]]; then
    cp /var/www/site/env "${env_file}"
  else
    cp /var/www/configurations/php-frameworks/Laravel/.env "${env_file}"
  fi
fi

# Make modifications to .env file
echo "Modifying .env file ..."
sed -i "s/APP_NAME=.*/APP_NAME=${project_name}/g" "${env_file}"
sed -i "s/APP_ENV=.*/APP_ENV=local/g" "${env_file}"
sed -i "s/DEBUG=.*/DEBUG=true/g" "${env_file}"
sed -i "s/APP_URL=.*/APP_URL=http:\/\/localhost:${port}/g" "${env_file}"

sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/g" "${env_file}"
sed -i "s/DB_HOST=.*/DB_HOST=db-${service_db,,}/g" "${env_file}"
sed -i "s/DB_PORT=.*/DB_PORT=${db_port}/g" "${env_file}"
sed -i "s/DB_DATABASE=.*/DB_DATABASE=${project_name}/g" "${env_file}"
sed -i "s/DB_USERNAME=.*/DB_USERNAME=${db_username}/g" "${env_file}"
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${db_password}/g" "${env_file}"

# Generate app encryption key
echo  "Generating app encryption key ..."
cd /var/www/site
php artisan key:generate

# Clear Laravel cache
echo  "Clearing Laravel cache ..."
cd /var/www/site
php artisan optimize:clear
