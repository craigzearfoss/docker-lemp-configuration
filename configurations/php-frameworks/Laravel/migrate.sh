#!/bin/bash

echo  "Running Laravel database migrations ..."
cd /var/www/site
DB_HOST=127.0.0.1 php artisan migrate
