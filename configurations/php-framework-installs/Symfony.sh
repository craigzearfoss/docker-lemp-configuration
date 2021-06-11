#!/bin/bash

printf "\nCreating Symfony project ...\n"
if [[ "${full_install}" == true ]]; then
  docker exec -w /var/www "${project_name}-app" composer create-project symfony/website-skeleton site
else
  docker exec -w /var/www "${project_name}-app" composer create-project symfony/skeleton site
fi

#  printf "\nUpdating .env file and configuration settings ...\n"
#  docker-compose exec app echo "DB_USER=${db_username}" >> "${local_container_dir}/.local.env"
#  docker-compose exec app echo "DB_PASS=${db_password}" >> "${local_container_dir}/.local.env"
