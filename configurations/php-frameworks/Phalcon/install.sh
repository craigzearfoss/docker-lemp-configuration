#!/bin/bash
## @TODO: This isn't working yet
# Create Phalcon project
echo  "Creating Phalcon project ..."
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

apt-get install php7.2-phalcon

# Install vendor files
cd /var/www/site
composer update
