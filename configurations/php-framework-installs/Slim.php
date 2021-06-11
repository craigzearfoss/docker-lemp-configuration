#!/bin/bash

printf "\nCreating Slim project ...\n"
docker exec -w /var/www "${project_name}-app" composer create-project slim/slim-skeleton:dev-master site
