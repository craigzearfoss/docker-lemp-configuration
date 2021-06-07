#!/bin/bash

printf "\nRunning database migrations ..."
printf "\n\tcd {{local_project_dir}}"
cd {{local_project_dir}}

printf "\n\tphp artisan migrate\n"
cd /var/www/{{project_name}}; DB_HOST=127.0.0.1 php artisan migrate
