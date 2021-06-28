#!/bin/bash

echo  "Initializing CodeIgniter .env file ..."
cd /var/www/site

# Set variables
env_file="/var/www/site/.env"
db_admin_port="{{db_admin_port}}"
db_exposed_port="{{db_exposed_port}}"
db_name="{{db_name}}"
db_password="{{db_password}}"
db_port="{{db_port}}"
db_username="{{db_username}}"
full_install={{full_install}}
git_repo="{{git_repo}}"
port="{{port}}"
project_name="{{project_name}}"
service_db="{{service_db}}"

# Make sure .env file exists
if [[ ! -f "$env_file" ]]; then
  if [[ -f "/var/www/site/.env.example" ]]; then
    cp /var/www/site/.env.exampple "${env_file}"
  elif [[ -f "/var/www/site/env" ]]; then
    cp /var/www/site/env "${env_file}"
  else
    cp /var/www/configurations/php-frameworks/CodeIgniter/.env "$env_file"
  fi
fi

# Make modifications to .env file
echo "Modifying .env file ..."
sed -i "s/.*CI_ENVIRONMENT =.*/CI_ENVIRONMENT = development/g" "${env_file}"
sed -i "s/.*app.baseURL =.*/app.baseURL = 'http:\/\/localhost:${port}\/';/" "${env_file}"
sed -i "s/.*database.default.hostname =.*/database.default.hostname = 'db-${service_db,,}'/g" "${env_file}"
sed -i "s/.*database.default.database =.*/database.default.database = '${db_name}'/g" "${env_file}"
sed -i "s/.*database.default.username =.*/database.default.username = '${db_username}'/g" "${env_file}"
sed -i "s/.*database.default.password =.*/database.default.password = '${db_password}'/g" "${env_file}"
if [[ "${service_db^^}" == "MYSQL" ]] || [[ "${service_db^^}" == "MARIADB" ]]; then
  sed -i "s/.*database.default.DBDriver =.*/database.default.DBDriver = 'MySQLi'/g" "${env_file}"
fi

# Add EMAIL section (if it doesn't already exist)
if ! grep -Fxq "email.SMTPUser" "${env_file}"; then
  echo "" >> "${env_file}"
  echo "#--------------------------------------------------------------------" >> "${env_file}"
  echo "# EMAIL" >> "${env_file}"
  echo "#--------------------------------------------------------------------" >> "${env_file}"
  echo "# email.fromEmail = 'noreply@example.com'" >> "${env_file}"
  echo "#email.fromName = '${project_name}'" >> "${env_file}"
  echo "# email.protocol = 'smtp'" >> "${env_file}"
  echo "# email.SMTPHost = 'smtp.mailtrap.io'" >> "${env_file}"
  echo "# email.SMTPUser = 'youruser'" >> "${env_file}"
  echo "# email.SMTPPass = 'yourpassword'" >> "${env_file}"
  echo "# email.SMTPPort = '587'" >> "${env_file}"
  echo "# email.SMTPCrypto = 'tls'" >> "${env_file}"
  echo "# email.mailType = 'html'" >> "${env_file}"
fi

# Add HASH_SECRET_KEY and other variables
hash=$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev 2>&1)
hash=$(echo -n $hash | md5sum | cut -c 1-32)
if grep -Fxq "HASH_SECRET_KEY.SMTPUser" "${env_file}"; then
  sed -i "s/HASH_SECRET_KEY =.*/HASH_SECRET_KEY = \'${hash}\'/" "${env_file}"
else
  echo "" >> "${env_file}"
  echo "#********************************************************************" >> "${env_file}"
  echo "# The following were added by the create_project.sh bash script." >> "${env_file}"
  echo "#********************************************************************" >> "${env_file}"
  echo "" >> "${env_file}"
  echo "HASH_SECRET_KEY = '${hash}'" >> "${env_file}"
fi

# Clear CodeIgniter cache
echo  "Clearing CodeIgniter cache ..."
cd /var/www/site
php spark cache:clear
