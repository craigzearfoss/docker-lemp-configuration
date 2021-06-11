#!/bin/bash

printf "\nCreating Lumen project ...\n"
 docker exec -w /var/www "${project_name}-app" composer create-project --prefer-dist laravel/lumen site

#  printf "\nUpdating .env file and configuration settings ...\n"
#  docker exec -w "${local_container_dir}" "${project_name}-app" sed -i "s/APP_NAME=.*/APP_NAME=${project_name}/" .env
#  docker exec -w "${local_container_dir}" "${project_name}-app" sed -i "s/APP_ENV=.*/APP_ENV=local/" .env
#  docker exec -w "${local_container_dir}" "${project_name}-app" php artisan key:generate
#  docker exec -w "${local_container_dir}" "${project_name}-app" sed -i "s/APP_URL=.*/APP_URL=http:\/\/localhost:${port}/" .env
#  docker exec -w "${local_container_dir}" "${project_name}-app" sed -i "s/DB_HOST=.*/DB_HOST=db-${service_db}/" .env
#  docker exec -w "${local_container_dir}" "${project_name}-app" sed -i "s/DB_PORT=.*/DB_PORT=${db_port}/" .env
#  docker exec -w "${local_container_dir}" "${project_name}-app" sed -i "s/DB_DATABASE=.*/DB_DATABASE=${db_name}/" .env
#  docker exec -w "${local_container_dir}" "${project_name}-app" sed -i "s/DB_USERNAME=.*/DB_USERNAME=${db_username}/" .env
#  docker exec -w "${local_container_dir}" "${project_name}-app" sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${db_password}/" .env
