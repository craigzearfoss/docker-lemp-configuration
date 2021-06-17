#!/bin/bash

# Run CodeIgniter database seeds
echo  "Running CodeIgniter database seeds ..."
cd /var/www/site
for seed_file in "/var/www/site/app/Database/Seeds/*.php"; do
  echo  "php spark db:seed ${seed_file%.*}"
  php spark db:seed "${seed_file%.*}"
done
