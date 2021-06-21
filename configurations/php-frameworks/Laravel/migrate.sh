#!/bin/bash

echo  "Running Laravel database migrations ..."
cd /var/www/site
php artisan migrate --force
