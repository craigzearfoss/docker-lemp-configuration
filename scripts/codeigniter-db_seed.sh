#!/bin/bash

cd {{local_project_dir}}

for seed_file in "${local_project_dir}/${project_name}/app/Database/Seeds/*.php"; do
  echo "php spark db:seed ${seed_file%.*}"
  php spark db:seed "${seed_file%.*}"
done
