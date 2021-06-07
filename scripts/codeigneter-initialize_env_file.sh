#!/bin/bash

FILE="{{local_project_dir}}/env"
if [[ -f "$FILE" ]] && [[ !-f "/{{local_project_dir}}/.env" ]]; then
  cp "$FILE" /{{local_project_dir}}/.env
fi

cat /var/www/configurations/env-sections/CodeIgniter" >>  {{local_project_dir}}/.env