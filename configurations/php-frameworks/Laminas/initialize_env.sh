#!/bin/bash

echo  "Initializing config/autoload/global.php ..."
cd /var/www/site

# Set variables
global_file="/var/www/site/config/autoload/global.php"
original_global_file="/var/www/site/config/autoload/global_original.php"
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

if grep -Fxq "'db'" "${global_file}"; then

  # db property is already in the global.php file
  sed -i "s/.*mysql:dbname=.*/                'dsn'    => 'mysql:dbname=${db_name};host=db-${service_db,,}:${db_port};charset=utf8',/g" "${global_file}"

else

  # add db property to global.php file
  mv "${global_file}" "${original_global_file}"
  touch "${global_file}"

  SUB="return ["
  while IFS= read -r line; do
    echo "$line" >> "${global_file}"
    if [[ "$line" == *"$SUB"* ]]; then
      echo "    'db' => [" >> "${global_file}"
      echo "        'adapters' => [" >> "${global_file}"
      echo "            'Application\Db\WriteAdapter' => [" >> "${global_file}"
      echo "                'driver' => 'Pdo'," >> "${global_file}"
      echo "                'dsn'    => 'mysql:dbname=${db_name};host=db-${service_db,,}:${db_port};charset=utf8'," >> "${global_file}"
      echo "            ]," >> "${global_file}"
      echo "            'Application\Db\ReadOnlyAdapter' => [" >> "${global_file}"
      echo "                'driver' => 'Pdo'," >> "${global_file}"
      echo "                'dsn'    => 'mysql:dbname=${db_name};host=db-${service_db,,}:${db_port};charset=utf8'," >> "${global_file}"
      echo "            ]," >> "${global_file}"
      echo "        ]," >> "${global_file}"
      echo "    ]," >> "${global_file}"
    fi
  done < "${original_global_file}"

fi