#!/bin/bash

echo  "Running Lumen database migrations ..."
cd /var/www/site
php artisan migrate --force
