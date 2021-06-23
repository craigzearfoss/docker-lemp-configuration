#!/bin/bash

# Create Slim project
echo  "Creating Slim project ..."
if [ -d "/var/www/site" ]; then
echo "Directory /var/www/site already exists."
echo "Delete it and rerun this script."
exit
fi

if [ ! -d "/var/www" ]; then
mkdir -p "/var/www"
fi

# Create project
if [ -d "/var/www/site" ]; then
rm -Rf /var/www/site
fi

cd /var/www

composer create-project slim/slim-skeleton:dev-master site --no-interaction

# Install vendor files
cd /var/www/site
composer update --no-interaction
