#!/bin/bash

# Create CakePHP project
echo  "Creating CakePHP project ..."
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

composer create-project --prefer-dist cakephp/app:~4.0 site

# Install vendor files
cd /var/www/site
composer update

