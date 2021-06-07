#!/bin/bash

printf "\nClearing cache ..."

cd {{local_project_dir}}

printf "\n\tartisan optimize:clear\n"
php artisan optimize:clear
