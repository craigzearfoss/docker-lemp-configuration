#!/bin/bash

cd {{local_project_dir}}

for seed_file in "${local_project_dir}/${project_name}/app/Database/Seeds/*.php"; do
  echo "php artisan db:seed --class${seed_file%.*}"
  php artisan db:seed "--class${seed_file%.*}"
done
