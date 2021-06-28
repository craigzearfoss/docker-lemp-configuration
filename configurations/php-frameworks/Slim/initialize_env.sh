#!/bin/bash

echo  "Initializing app/settings.php ..."
cd /var/www/site

# Set variables
settings_file="/var/www/site/app/settings.php"
original_settings_file="/var/www/site/app/settings_original.php"
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

if grep -Fxq "'db'" "${settings_file}"; then

  # db property is already in the settings.php file
  sed -i "s/.*'driver' =>.*/                    'driver' => '${service_db,,}',/g" "${settings_file}"
  sed -i "s/.*'host' =>.*/                    'host' => 'db-${service_db,,}',/g" "${settings_file}"
  sed -i "s/.*'username' =>.*/                    'username' => '${db_username}',/g" "${settings_file}"
  sed -i "s/.*'database' =>.*/                    'database' => '${db_name}',/g" "${settings_file}"
  sed -i "s/.*'password' =>.*/                    'password' => '${db_password}',/g" "${settings_file}"

else

  # add db property to settings.php file
  mv "${settings_file}" "${original_settings_file}"
  touch "${settings_file}"

  SUB="return new Settings"
  while IFS= read -r line; do
    echo "$line" >> "${settings_file}"
    if [[ "$line" == *"$SUB"* ]]; then
      echo "                'db' => [" >> "${settings_file}"
      echo "                    'driver' => '${service_db,,}'," >> "${settings_file}"
      echo "                    'host' => 'db-${service_db,,}'," >> "${settings_file}"
      echo "                    'username' => '${db_username}'," >> "${settings_file}"
      echo "                    'database' => '${db_name}'," >> "${settings_file}"
      echo "                    'password' => '${db_password}'," >> "${settings_file}"
      echo "                    'charset' => 'utf8mb4'," >> "${settings_file}"
      echo "                    'collation' => 'utf8mb4_unicode_ci'," >> "${settings_file}"
      echo "                    'flags' => [" >> "${settings_file}"
      echo "                        // Turn off persistent connections" >> "${settings_file}"
      echo "                        PDO::ATTR_PERSISTENT => false," >> "${settings_file}"
      echo "                        // Enable exceptions" >> "${settings_file}"
      echo "                        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION," >> "${settings_file}"
      echo "                        // Emulate prepared statements" >> "${settings_file}"
      echo "                        PDO::ATTR_EMULATE_PREPARES => true," >> "${settings_file}"
      echo "                        // Set default fetch mode to array" >> "${settings_file}"
      echo "                        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC" >> "${settings_file}"
      echo "                    ]," >> "${settings_file}"
      echo "                ]," >> "${settings_file}"
    fi
  done < "${original_settings_file}"
fi
