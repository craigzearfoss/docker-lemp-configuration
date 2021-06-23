#!/bin/bash

# Create Symfony project
echo  "Creating Symfony project ..."
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

full_install= {{full_install}}
if [[ "${full_install}" == true ]]; then
  composer create-project symfony/website-skeleton site --no-interaction
else
  composer create-project symfony/skeleton site --no-interaction
fi

# Install vendor files
cd /var/www/site
composer update --no-interaction
