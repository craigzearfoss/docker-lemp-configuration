#!/bin/bash

printf "\nCreating CodeIgniter project ...\n"
docker exec -w /var/www "${project_name}-app" composer create-project codeigniter4/appstarter site

  #docker exec -w "${local_container_dir}" "${project_name}-app" composer create-project codeigniter4/appstarter "${project_name}"

#      cp "${container_dir}/env" "${container_dir}/.env"
#      docker exec -w "${working_dir}" "${project_name}-app" bash "/var/www/scripts/codeigniter-initialize_env_file.sh"
#      cat "${working_dir}/configurations/env-sections/CodeIgniter" >>  "${container_dir}/${project_name}/.env"
#  printf "\nUpdating .env file and configuration settings ...\n"
#  docker exec -w "${local_container_dir}" "${project_name}-app" sed -i "s/# CI_ENVIRONMENT =.*/CI_ENVIRONMENT = development/g" .env
#  docker exec -w "${local_container_dir}" "${project_name}-app" sed -i "s/# database.default.hostname =.*/database.default.hostname = db-${service_db}/g" .env
#  docker exec -w "${local_container_dir}" "${project_name}-app" sed -i "s/# database.default.database =.*/database.default.database = ${db_name}/g" .env
#  docker exec -w "${local_container_dir}" "${project_name}-app" sed -i "s/# database.default.username =.*/database.default.username = ${db_username}/g" .env
#  docker exec -w "${local_container_dir}" "${project_name}-app" sed -i "s/# database.default.password =.*/database.default.password = '${db_password}'/g" .env
#  hash=$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev 2>&1)
#  hash=$(echo -n $hash | md5sum | cut -c 1-32)
#  docker exec -w "${local_container_dir}" "${project_name}-app" sed -i "s/HASH_SECRET_KEY =.*/HASH_SECRET_KEY = \'${hash}\'/" .env
#  if [ -z "$git_repo" ]; then
#    docker exec -w "${local_container_dir}/app/Config" "${project_name}-app" sed -i "s/public \$baseURL =.*/        public \$baseURL = 'http:\/\/localhost:${port}\/';/" App.php
#    docker exec -w "${local_container_dir}/app/Config" "${project_name}-app" sed -i "s/public \$indexPage =.*/        public \$indexPage = '';/g" App.php
#  fi
