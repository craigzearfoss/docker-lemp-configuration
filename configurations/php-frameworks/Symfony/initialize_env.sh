#!/bin/bash

echo  "Initializing Symfony .env file ..."
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
    cp /var/www/configurations/php-frameworks/Symfony/.env "${env_file}"
  fi
fi

# Make modifications to .env file
echo "Modifying .env file ..."

# First, make sure database settings are in the .env file
sed -i "s/.*APP_ENV=.*/APP_ENV=de/g" "${env_file}"
if ! grep -Fxq "DATABASE_URL=\"mysql" "${env_file}"; then
  echo "# DATABASE_URL=\"mysql://${db_username}:${db_password}@db-${service_db,,}:${db_port}/${db_name}?serverVersion=5.7\"" >> "${env_file}"
fi
if ! grep -Fxq "DATABASE_URL=\"postgres" "${env_file}"; then
  echo "# DATABASE_URL=\"postgresql://${db_username}:${db_password}@db-${service_db,,}:${db_port}/${db_name}?serverVersion=13&charset=utf8\"" >> "${env_file}"
fi

if [[ "${service_db^^}" == "MYSQL" ]] || [[ "${service_db^^}" == "MARIADB" ]]; then
  sed -i "s/.*DATABASE_URL=\"mysql.*/DATABASE_URL=\"mysql:\/\/${db_username}:${db_password}@db-${service_db,,}:${db_port}\/${db_name}?serverVersion=5.7\"/g" "${env_file}"
  sed -i "s/.*DATABASE_URL=\"postgres.*/# DATABASE_URL=\"postgresql:\/\/${db_username}:${db_password}@db-${service_db,,}:${db_port}\/${db_name}?serverVersion=13&charset=utf8\"/g" "${env_file}"
elif [[ "${service_db^^}" == "POSTGRES" ]]; then
  sed -i "s/.*DATABASE_URL=\"mysql.*/# DATABASE_URL=\"mysql:\/\/${db_username}:${db_password}@db-${service_db,,}:${db_port}\/${db_name}?serverVersion=5.7\"/g" "${env_file}"
  sed -i "s/.*DATABASE_URL=\"postgres.*/DATABASE_URL=\"postgresql:\/\/${db_username}:${db_password}@db-${service_db,,}:${db_port}\/${db_name}?serverVersion=13&charset=utf8\"/g" "${env_file}"
fi
