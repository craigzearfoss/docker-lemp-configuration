#!/bin/bash

printf "\nCreating FuelPHP project ...\n"
docker exec -w /var/www "${project_name}-app" composer create-project fuel/fuel --prefer-dist site
