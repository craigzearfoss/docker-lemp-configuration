#!/bin/bash

# Run Laravel database seeds
echo  "Running Laravel database seeds ..."
cd /var/www/site
for seed_file in "/var/www/site/app/Database/Seeds/*.php"; do
  echo  "DB_HOST=127.0.0.1 php artisan db:seed --class${seed_file%.*}"
  DB_HOST=127.0.0.1 php artisan db:seed "--class${seed_file%.*}"
done
