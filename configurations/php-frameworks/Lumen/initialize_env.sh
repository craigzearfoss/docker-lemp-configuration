#!/bin/bash

echo  "Initializing Lumen .env file ..."
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
    cp /var/www/configurations/php-frameworks/Lumen/.env "${env_file}"
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
hash=$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev 2>&1)
hash=$(echo -n $hash | md5sum | cut -c 1-32)
sed -i "s/APP_KEY=.*/APP_KEY=${hash}/g" "${env_file}"

php artisan key:generate

# Clear Lumen cache
cd /var/www/site
php artisan optimize:clear
