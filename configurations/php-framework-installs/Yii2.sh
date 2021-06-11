#!/bin/bash

printf "\nCreating Yii2 project ...\n"
docker exec -w /var/www "${project_name}-app" composer create-project --prefer-dist yiisoft/yii2-app-basic site

#  printf "\nUpdating configuration settings ...\n"
#  docker-compose exec app sed -i "s/    'dsn' => '${service_db}:host=,.*/    'dsn' => '${service_db}:host=localhost;dbname=${db_name}',/g" "${local_container_dir}/config/web.php"
#  docker-compose exec app sed -i "s/    'username' => 'root'.*/    'username' => '${db_username}',/g" "${local_container_dir}/config/web.php"
#  docker-compose exec app sed -i "s/    'password' => ''.*/    'password' => '${db_username}',/g" "${local_container_dir}/config/web.php"
