#!/bin/bash
## @TODO: This isn't working yet
# Create Laminas project
echo  "Creating Laminas project ..."
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

composer require --dev laminas/laminas-component-installer --no-interaction

# Install vendor files
cd /var/www/site
composer update
