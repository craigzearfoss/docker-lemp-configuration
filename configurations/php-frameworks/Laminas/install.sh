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

composer create-project -s dev laminas/laminas-mvc-skeleton site --no-interaction

composer require --dev laminas/laminas-developer-tools --no-interaction
# NOTE: laminas-cache doesn't support php8
#composer require laminas/laminas-cache --no-interaction

# database support
composer require laminas/laminas-db --no-interaction

# forms support
composer require laminas/laminas-form --no-interaction

# JSON de/serialization support
composer require laminas/laminas-json --no-interaction

# logging support
composer require laminas/laminas-log --no-interaction

# MVC-based console support (symfony/console, or Aura.CLI is recommended)
# NOTE: laminas-mvc-console doesn't support php8
#composer require laminas/laminas-mvc-console --no-interaction
#composer require eth8505/laminas-symfony-console --no-interaction

# i18n support
composer require laminas/laminas-i18n --no-interaction

# official MVC plugins
# causes conflicts
#composer require laminas/laminas-mvc-plugins --with-all-dependencies --no-interaction

# sessions support
composer require laminas/laminas-session --no-interaction

# MVC testing support
# ERROR: unsatisified requirements
#composer require laminas/laminas-test --no-interaction

# laminas-di integration for laminas-servicemanager
# ERROR: incompatible requirement
#composer require laminas/laminas-servicemanager-di --no-interaction

# Install vendor files
cd /var/www/site
composer update --no-interaction
