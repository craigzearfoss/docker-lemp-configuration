#!/bin/bash

# Create WordPress project
echo  "Creating WordPress project ..."
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

wget https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz