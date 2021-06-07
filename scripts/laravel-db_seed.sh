#!/bin/bash

printf "\nRunning database seeds ..."

cd {{local_project_dir}}

for seed_file in "${local_project_dir}/app/Database/Seeds/*.php"; do
  printf "\n\tphp artisan db:seed --class${seed_file%.*}"
  cd /var/www/{{project_name}}; DB_HOST=127.0.0.1 php artisan db:seed "--class${seed_file%.*}"
done
