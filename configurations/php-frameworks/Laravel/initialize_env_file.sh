#!/bin/bash

echo  "Initializing CodeIgniter .env file ..."
cd "/var/www/site"

# Set variables
env_file="/var/www/site/.env"
db_admin_port="{{db_admin_port}}"
db_exposed_port="{{db_exposed_port}}"
db_name="{{db_name}}"
db_password="{{db_password}}"
db_username="{{db_username}}"
full_install={{full_install}}
git_repo="{{git_repo}}"
local_web_root="{{local_web_root}}"
port="{{port}}"
project_name="{{project_name}}"
service_db="{{service_db}}"
web_root="{{web_root}}"

#FILE="{{local_project_dir}}/.env.example"
#if [[ -f "$FILE" ]] && [[ !-f "/{{local_project_dir}}/.env" ]]; then
#  cp "$FILE" /{{local_project_dir}}/.env
#fi
