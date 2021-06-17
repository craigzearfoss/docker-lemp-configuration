#!/bin/bash

# Clone a git repository
echo  "Cloning git repository ..."
if [ -d "/var/www/site" ]; then
  echo "Directory /var/www/site already exists."
  echo "Delete it and rerun this script."
  exit
fi

if [ ! -d "/var/www" ]; then
  mkdir -p "/var/www"
fi

# Clone repository
cd /var/www
git clone {{git_repo}} site

# Install vendor files
cd /var/www/site
composer update
