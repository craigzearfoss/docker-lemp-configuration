#!/bin/bash

# Create Yii2 project
echo  "Creating Yii2 project ..."
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
  composer create-project --prefer-dist yiisoft/yii2-app-basic site --no-interaction
else
  composer create-project --prefer-dist yiisoft/yii2-app-basic site --no-interaction
fi

# Install vendor files
cd /var/www/site
composer update --no-interaction
