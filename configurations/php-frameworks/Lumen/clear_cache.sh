#!/bin/bash

echo  "Clearing Lumen cache ..."

cd /var/www/site

php artisan optimize:clear
