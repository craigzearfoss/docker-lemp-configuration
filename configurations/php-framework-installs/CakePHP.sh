#!/bin/bash

printf "\nCreating CakePHP project ...\n"
docker exec -w /var/www "${project_name}-app" composer create-project --prefer-dist cakephp/app:~4.0 site
#composer create-project --prefer-dist cakephp/app:~4.0 --working-dir="${container_dir}" "${project_name}"

#  cp "${container_dir}/config/.env.example" "${container_dir}/config/.env"

#  printf "\nUpdating .env file and configuration settings ...\n"
#  docker-compose exec app sed -i "s/export APP_NAME=.*/export APP_NAME=\"${project_name}\"/g" "${local_container_dir}/config/.env"
#  docker-compose exec app sed -i "s/export SECURITY_SALT=.*/export SECURITY_SALT=\"$(openssl rand -base64 6)\"/g" "${local_container_dir}/config/.env"
