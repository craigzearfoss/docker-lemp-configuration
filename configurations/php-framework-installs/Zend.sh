#!/bin/bash

printf "\nCreating Zend project ...\n"
docker exec -w /var/www "${project_name}-app" composer require zendframework/zendframework site

