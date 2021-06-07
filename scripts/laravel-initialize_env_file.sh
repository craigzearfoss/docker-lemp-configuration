#!/bin/bash

FILE="{{local_project_dir}}/.env.example"
if [[ -f "$FILE" ]] && [[ !-f "/{{local_project_dir}}/.env" ]]; then
  cp "$FILE" /{{local_project_dir}}/.env
fi
