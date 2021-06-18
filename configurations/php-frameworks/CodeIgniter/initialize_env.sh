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

# Make sure .env file exists
if [[ ! -f "$env_file" ]] && [[ -f "/var/www/site/.env.example" ]]; then

  cp /var/www/site/env "${env_file}"

  # Add additional lines to .env file
  echo "" >> "${env_file}"
  echo "#********************************************************************" >> "${env_file}"
  echo "# The following were added by the create_project.sh bash script." >> "${env_file}"
  echo "#********************************************************************" >> "${env_file}"
  echo "" >> "${env_file}"
  echo "HASH_SECRET_KEY = 'OAQoT1wiiwm8eHJEkQ4hIOR94SAcCEma'" >> "${env_file}"
  echo "" >> "${env_file}"
  echo "#--------------------------------------------------------------------" >> "${env_file}"
  echo "# EMAIL" >> "${env_file}"
  echo "#--------------------------------------------------------------------" >> "${env_file}"
  echo "email.fromEmail = 'noreply@example.com'" >> "${env_file}"
  echo "email.fromName = 'Task application'" >> "${env_file}"
  echo "email.protocol = 'smtp'" >> "${env_file}"
  echo "email.SMTPHost = 'smtp.mailgun.org'" >> "${env_file}"
  echo "email.SMTPUser = 'youruser@example.com'" >> "${env_file}"
  echo "email.SMTPPass = 'yourpassword'" >> "${env_file}"
  echo "email.SMTPPort = '587'" >> "${env_file}"
  echo "email.SMTPCrypto = 'tls'" >> "${env_file}"
  echo "email.mailType = 'html'" >> "${env_file}"
fi

if [[ -f "$env_file" ]]; then
  # Make modifications to .env file
  echo "Modifying .env file ..."
  sed -i "s/.*CI_ENVIRONMENT =.*/CI_ENVIRONMENT = development/g" "${env_file}"
  sed -i "s/.*database.default.hostname =.*/database.default.hostname = db-${service_db,,}/g" "${env_file}"
  sed -i "s/.*database.default.database =.*/database.default.database = ${db_name}/g" "${env_file}"
  sed -i "s/.*database.default.username =.*/database.default.username = ${db_username}/g" "${env_file}"
  sed -i "s/.*database.default.password =.*/database.default.password = '${db_password}'/g" "${env_file}"
  if [[ "${service_db^^}" == "MYSQL" ]] || [[ "${service_db^^}" == "MARIADB" ]]; then
    sed -i "s/.*database.default.DBDriver =.*/database.default.DBDriver = MySQLi/g" "${env_file}"
  fi

  hash=$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev 2>&1)
  hash=$(echo -n $hash | md5sum | cut -c 1-32)
  sed -i "s/HASH_SECRET_KEY =.*/HASH_SECRET_KEY = \'${hash}\'/" "${env_file}"

  # Only make the following changes for a new project, that is not from a git repo
  if [ "${git_repo}" == "" ]; then
     sed -i "s/public \$baseURL =.*/        public \$baseURL = 'http:\/\/localhost:${port}\/';/" /var/www/site/app/Config/App.php
     sed -i "s/public \$indexPage =.*/        public \$indexPage = '';/g"  /var/www/site/app/Config/App.php
  fi
fi

# Clear CodeIgniter cache
echo  "Clearing CodeIgniter cache ..."
cd /var/www/site
php spark cache:clear
