#!/bin/bash

echo  "Clearing Laravel cache ..."

cd /var/www/site

php artisan optimize:clear
