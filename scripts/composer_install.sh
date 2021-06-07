#!/bin/bash

printf "\nRunning composer install ...\n"

cd {{local_project_dir}}

printf "\n\tcomposer install\n"
composer install
