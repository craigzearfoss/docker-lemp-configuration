#!/bin/bash

printf "\nCreating Phalcon project ...\n"
docker exec -w /var/www "${project_name}-app" apt-get install php7.2-phalcon
