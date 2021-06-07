#!/bin/bash

printf "\nRunning composer update ...\n"

cd {{local_project_dir}}

printf "\n\tcomposer update\n"
composer update
