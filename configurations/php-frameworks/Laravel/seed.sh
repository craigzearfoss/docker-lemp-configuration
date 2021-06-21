#!/bin/bash

# Run Laravel database seeds
echo  "Running Laravel database seeds ..."
cd /var/www/site
for seed_file in "/var/www/site/database/seeders/*.php"; do
  echo  "    ${seed_file%.*}"
  php artisan db:seed "--class=${seed_file%.*}" --force
done
