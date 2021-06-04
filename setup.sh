#!/bin/bash
printf "\nCreate a PHP Development Environment\n"

selected_option=-1
while [[ selected_option -lt 1 || selected_option -gt 3 ]]; do
  printf "\nSelect the type of project."
  printf "\n\t1 - Web Server"
  printf "\n\t2 - Web Server and Fake SMTP (MailHog)"
  printf "\n\t3 - Fake SMTP (MailHog) only"
  printf "\n"
  read selected_option
  selected_option="$((selected_option))"
done
if [[ "$selected_option" -eq 2 ]] || [[ "$selected_option" -eq 3 ]]; then
  printf "\nSetting up fake-smtp-mailhog container ...\n"
  cd configurations/docker-compose-files/mailhog
  docker-compose up -d mailhog
  printf "\nMailHog container has been created as fake-smtp-mailhog:\n"
  if [[ "$selected_option" -eq 3 ]] ; then
    exit
  fi
fi

docker_version="3.7"
docker_compose_yml_version="nginx-mysql"
dockerfile_filename="php-7-4-fpm"

service_app="app"
service_db="mysql"
service_phpmyadmin="phpmyadmin"
service_server="nginx"

project_name=$1
project_framework=""
git_repo=""
working_dir="$(pwd)"
base_dir=$(echo $working_dir | sed "s|\(.*\)/.*|\1|")
project_base_dir="$base_dir"
project_dir="${project_base_dir}/${project_name}"
local_project_dir="/var/www/${project_name}"
port=
default_port=8000
phpmyadmin_port=$(($default_port + 1))
db_name=${project_name//[\-]/_}
db_root_password=
db_username=
db_password=
db_exposed_port=6603
default_full_install="Y"
full_install=${default_full_install}
run_migrations="Y"

# Create an array of available Docker files.
declare -a docker_files
basename "${working_dir}/configurations/Dockerfiles"
selected_docker_file_index=
cnt=1
for filepath in "${working_dir}/configurations/Dockerfiles/"*
do
  filename="$(basename $filepath)"
  docker_files[$cnt]="${filename}"
  if [[ $filename == $dockerfile_filename ]]; then
    selected_docker_file_index=$cnt
  fi
  cnt=$((${cnt} + 1))
done

# Set which Docker file to use.
printf "\nAvailable Docker files:\n"
for k in "${!docker_files[@]}"; do
  printf "\t"
  echo $k - "${docker_files[$k]}"
done
valid_docker_file=false
echo "selected_docker_file_index:$selected_docker_file_index"
while [ "$valid_docker_file" != true ]; do
  read -p "Docker file [${selected_docker_file_index}]: " response
  if [ -z "$response" ]; then
    response=$selected_docker_file_index
  else
    response="$((response))"
  fi
  if [[ "$response" -gt 0 ]] && [[ "$response" -le ${#docker_files[@]} ]]; then
    selected_docker_file_index=$response
    dockerfile_filename="${docker_files[selected_docker_file_index]}"
    valid_docker_file=true
  fi
done

create_docker_containers() {
  printf "\nCopying configuration files ...\n"
  cd "${project_dir}"
  mkdir "${project_dir}/docker-compose/"
  mkdir "${project_dir}/docker-compose/${service_db}/"
  mkdir "${project_dir}/docker-compose/${service_server}/"

  # Copy nginx configuration file. (First look for framework-specific configuration file.)
  if [ -f "${working_dir}/docker-compose/${service_server}/${project_framework}/project_name.conf" ]; then
    cp "${working_dir}/docker-compose/${service_server}/${project_framework}/project_name.conf" "${nginx_conf_file}"
  else
    cp "${working_dir}/docker-compose/${service_server}/project_name.conf" "${nginx_conf_file}"
  fi

  # Copy initial db commands file.
  cp "${working_dir}/docker-compose/${service_db}/init_db.sql" "${mysql_init_file}"

  # Create docker-compose.yml file.
  printf "Creating docker-compose.yml file ...\n"
  echo "version: \"${docker_version}\"" > "${docker_compose_file}"
  echo "services:" >> "${docker_compose_file}"
  cat "${working_dir}/configurations/docker-compose-sections/service-${service_app}" >> "${docker_compose_file}"
  cat "${working_dir}/configurations/docker-compose-sections/service-${service_db}" >> "${docker_compose_file}"
  cat "${working_dir}/configurations/docker-compose-sections/service-${service_phpmyadmin}" >> "${docker_compose_file}"
  cat "${working_dir}/configurations/docker-compose-sections/service-${service_server}" >> "${docker_compose_file}"
  cat "${working_dir}/configurations/docker-compose-sections/networks" >> "${docker_compose_file}"
  cat "${working_dir}/configurations/docker-compose-sections/volumes" >> "${docker_compose_file}"

  # Make changes to docker-compose.yml file.
  printf "Updating docker-compose.yml file ...\n"
  sed -i "s/{{project_name}}/${project_name}/g" ${docker_compose_file}
  sed -i "s/{{port}}/${port}/g" ${docker_compose_file}
  sed -i "s/{{phpmyadmin_port}}/${phpmyadmin_port}/g" ${docker_compose_file}
  sed -i "s/{{db_exposed_port}}/${db_exposed_port}/g" ${docker_compose_file}

  # Copy Dockerfile.
  printf "Copying Dockerfile file ...\n"
  cp "${working_dir}/configurations/Dockerfiles/${dockerfile_filename}" "${docker_file}"

  # Make changes to the nginx configuration file.
  printf "Updating Nginx configuration file ...\n"
  if [[ $project_framework == "CakePHP" ]]; then
    sed -i "s/server_name .*/server_name localhost;/g" ${nginx_conf_file}
    sed -i "s/[::]:80 /[::]:${port}/g" ${nginx_conf_file}
    sed -i "s/root .*/root   \/var\/www\/${project_name}\/public\/webroot;/g" ${nginx_conf_file}
    sed -i "s/error_log .*/error_log  \/var\/www\/${project_name}\/log\/error.log;/g" ${nginx_conf_file}
    sed -i "s/access_log .*/access_log \/var\/www\/${project_name}\/log\/access.log;/g" ${nginx_conf_file}
  elif [[ $project_framework == "CodeIgniter" ]]; then
    sed -i "s/root .*/root \/var\/www\/${project_name}\/public;/g" ${nginx_conf_file}
    sed -i "s/error_log .*/error_log  \/var\/log\/nginx\/${project_name}_error.log;/g" ${nginx_conf_file}
    sed -i "s/access_log .*/access_log \/var\/log\/nginx\/${project_name}_access.log;/g" ${nginx_conf_file}
  elif [[ $project_framework == "Yii" ]]; then
    sed -i "s/root .*/root \/var\/www\/${project_name}\/web;/g" ${nginx_conf_file}
    sed -i "s/error_log .*/error_log  \/var\/log\/nginx\/${project_name}_error.log;/g" ${nginx_conf_file}
    sed -i "s/access_log .*/access_log \/var\/log\/nginx\/${project_name}_access.log;/g" ${nginx_conf_file}
  else
    sed -i "s/root .*/root \/var\/www\/${project_name}\/public;/g" ${nginx_conf_file}
    sed -i "s/error_log .*/error_log  \/var\/log\/nginx\/${project_name}_error.log;/g" ${nginx_conf_file}
    sed -i "s/access_log .*/access_log \/var\/log\/nginx\/${project_name}_access.log;/g" ${nginx_conf_file}
  fi

  printf "Adding database credentials ...\n"
  export DB_DATABASE="${db_name}"
  export DB_ROOT_PASSWORD="${db_root_password}"
  export DB_USERNAME="${db_username}"
  export DB_PASSWORD="${db_password}"

  # Add superuser create to init_db.sql file
  echo "CREATE DATABASE FLUSH ${db_name};" >> ${mysql_init_file}
  echo "CREATE USER '${db_username}'@'localhost' IDENTIFIED BY \"${db_password}\";" >> ${mysql_init_file}
  echo "GRANT ALL PRIVILEGES ON *.* TO '${db_username}'@'localhost' WITH GRANT OPTION;" >> ${mysql_init_file}
  echo "CREATE USER '${db_username}'@'%' IDENTIFIED BY \"${db_password}\";" >> ${mysql_init_file}
  echo "GRANT ALL PRIVILEGES ON *.* TO '${db_username}'@'%' WITH GRANT OPTION;" >> ${mysql_init_file}
  echo "FLUSH PRIVILEGES;" >> ${mysql_init_file}

  printf "Building Docker containers ...\n"
  docker-compose build
  docker-compose up -d
  docker-compose ps

  printf "Installing composer ...\n"
  docker-compose exec app composer install

  # Remove init_db.sql setup file.
  rm "${project_dir}/docker-compose/${service_db}/init_db.sql"
}

# Get the project name.
if [ -z "$project_name" ]; then
  valid_project_name=false
  while [ "$valid_project_name" != true ]; do
    read -p "Project name (Can only contain letters, numbers, underscores and dashes.): " project_name
    if [[ $project_name =~ ^[A-Za-z0-9_-]+$ ]]; then
      valid_project_name=true
    else
      valid_project_name=false
    fi
  done
fi
project_dir="${project_base_dir}/${project_name}"
local_project_dir="/var/www/${project_name}"
db_name=${project_name//[\-]/_}

# Get the git repo. (If there is one.)
read -p "Git repository (Leave blank for none.): " git_repo

# Get the type of project
selected_option=-1
while [[ selected_option -lt 1 || selected_option -gt 8 ]]; do
  printf "\nSelect the type of project."
  printf "\n\t1 - CakePHP"
  printf "\n\t2 - CodeIgniter"
  printf "\n\t3 - Laravel"
  printf "\n\t4 - Lumen"
  printf "\n\t5 - Symfony"
  printf "\n\t6 - WordPress"
  printf "\n\t7 - Yii"
  printf "\n\t8 - Zend"
  printf "\n"
  read selected_option
  selected_option="$((selected_option))"
done

if [[ "$selected_option" -eq 1 ]]; then
  project_framework="CakePHP"
fi
if [[ "$selected_option" -eq 2 ]]; then
  project_framework="CodeIgniter"
fi
if [[ "$selected_option" -eq 3 ]]; then
  project_framework="Laravel"
fi
if [[ "$selected_option" -eq 4 ]]; then
  project_framework="Lumen"
fi
if [[ "$selected_option" -eq 5 ]]; then
  project_framework="Symfony"
fi
if [[ "$selected_option" -eq 6 ]]; then
  project_framework="WordPress"
fi
if [[ "$selected_option" -eq 7 ]]; then
  project_framework="Yii"
fi
if [[ "$selected_option" -eq 8 ]]; then
  project_framework="Zend"
fi

unimplemented_frameworks=("WordPress Zend")
if [[ " ${unimplemented_frameworks[@]} " =~ " ${project_framework} " ]]; then
    printf "Sorry, ${project_framework} has not been implemented yet.\n"
    exit
fi

# Is this a full install?
frameworks_with_partial_installs=("Symfony")
if [[ " ${frameworks_with_partial_installs[@]} " =~ " ${project_framework} " ]]; then
  valid_replies=("Y N")
  good_reply=false
  while [ "$good_reply" != true ]; do
    read -p "Full install [${default_full_install}]: " full_install
    full_install=${full_install:-${default_full_install}}
    full_install=${full_install^^}
    if [[ " ${valid_replies[@]} " =~ " ${full_install} " ]]; then
      good_reply=true
    fi
  done
fi

# Get the project directory.
read -p "Project directory [${project_base_dir}]: " custom_base_dir
custom_base_dir=${custom_base_dir:-${project_base_dir}}
project_base_dir=$custom_base_dir
project_dir="${project_base_dir}/${project_name}"

# Make sure the project directory does not already exist.
if [ -d $project_dir ]; then
  printf "\nThe directory ${project_dir} already exists.\n"
  exit
fi
# Make sure the project base directory exists.
if [ -d "project_base_dir" ]; then
  printf "\nThe project base directory ${project_base_dir} does not exist.  Please create it and rerun this script.\n"
  exit
fi

# Get the port.
port_is_in_use="Y"
select_a_port_prompt="Select a port [${default_port}]: "
while [[ "${port_is_in_use}" == "Y" ]]; do
  read -p "${select_a_port_prompt}" port
  port=${port:-${default_port}}
  if [[ $(nc -w5 -z -v localhost "${port}" 2>&1) == *"succeeded"* ]]; then
    select_a_port_prompt="Port ${port} is in use. Select a different port [${default_port}]: "
    port_is_in_use="Y"
  else
    port_is_in_use="N"
  fi
done
phpmyadmin_port=$(($port + 1))
while [[ $(nc -w5 -z -v localhost "${phpmyadmin_port}" 2>&1) == *"succeeded"* ]]; do
  phpmyadmin_port=$(($phpmyadmin_port + 1))
done

# Get database type
selected_option=-1
while [[ selected_option -lt 1 || selected_option -gt 2 ]]; do
  printf "\nSelect the type of database:"
  printf "\n\t1 - MySQL"
  printf "\n\t2 - Postgres"
  printf "\n"
  read selected_option
  selected_option="$((selected_option))"
done
if [[ "$selected_option" -eq 1 ]]; then
  service_db="mysql"
  db_exposed_port=6603
fi
if [[ "$selected_option" -eq 2 ]]; then
  service_db="postgres"
  db_exposed_port=6603
fi

# If the exposed port for the db is in use than keep incrementing it until we find an open port.
while [[ $(nc -w5 -z -v localhost "${db_exposed_port}" 2>&1) == *"succeeded"* ]]; do
  db_exposed_port=$((${db_exposed_port} + 1))
done

# Get database user credentials.
db_root_password=
while [ -z "$db_root_password" ]; do
  read -p "Enter database root password: " db_root_password
done

db_username=
while [ -z "$db_username" ]; do
  read -p "Enter database username: " db_username
done

db_password=
while [ -z "$db_password" ]; do
  read -p "Enter database user password: " db_password
done

printf "\n---------------------------------------------------"
printf "\nProject name:        ${project_name}"
printf "\nProject framework:   ${project_framework}"
if [[ $project_framework == "Symfony" ]]; then
  printf "\nFull install:        ${project_framework}"
fi
printf "\nProject directory:   ${project_base_dir}"
printf "\nGit repository:      ${git_repo}"
#printf "\nWorking directory:   ${working_dir}"
#printf "\nBase directory:      ${base_dir}"
printf "\nPort:                ${port}"
printf "\nphpMyAdmin port:     ${phpmyadmin_port}"
printf "\nDatabase:"
printf "\n    Type:            ${service_db}"
printf "\n    Name:            ${db_name}"
printf "\n    Root password:   ***${db_root_password: -3}"
printf "\n    Username:        ${db_username}"
printf "\n    Password:        ***${db_password: -3}"
printf "\n---------------------------------------------------\n\n"

read -p "Hit [Enter] to continue or Ctrl-C to quit." reply

# Define Docker files.
nginx_conf_file="${project_dir}/docker-compose/${service_server}/${project_name}.conf"
mysql_init_file="${project_dir}/docker-compose/${service_db}/init_db.sql"
docker_compose_file="${project_dir}/docker-compose.yml"
docker_file="${project_dir}/Dockerfile"

cd "${project_base_dir}"

# Copy configuration files to the project directory.
mkdir "${project_dir}"
create_docker_containers

if [ -z "$git_repo" ]; then

  if [[ $project_framework == "CakePHP" ]]; then
    # CakePHP
    printf "\nCreating CakePHP project ...\n"
    docker-compose exec app composer create-project --prefer-dist cakephp/app:~4.0 "${project_name}"
    docker-compose exec app cp "${local_project_dir}/config/.env.example" "${local_project_dir}/config/.env"

  elif [[ $project_framework == "CodeIgniter" ]]; then
    # CodeIgniter
    printf "\nCreating CodeIgniter project ...\n"
    docker-compose exec app composer create-project codeigniter4/appstarter "${project_name}"
    docker-compose exec app cp "${local_project_dir}/env" "${local_project_dir}/.env"
    docker-compose exec app cat "${working_dir}/configurations/env-sections/CodeIgniter" >>  "${local_project_dir}/.env"
  elif [[ $project_framework == "Laravel" ]]; then
    # Laravel
    printf "\nCreating Laravel project ...\n"
    docker-compose exec app composer create-project laravel/laravel "${project_name}"

  elif [[ $project_framework == "Lumen" ]]; then
    # Lumen
    printf "\nCreating Lumen project ...\n"
    docker-compose exec app composer create-project --prefer-dist laravel/lumen "${project_name}"

  elif [[ $project_framework == "Symfony" ]]; then
    # Symfony
    printf "\nCreating Symfony project ...\n"
    if [ "$full_install" == "Y"]; then
      docker-compose exec app composer create-project symfony/website-skeleton "${project_name}"
    else
      docker-compose exec app composer create-project symfony/skeleton "${project_name}"
    fi

  elif [[ $project_framework == "Yii" ]]; then
    # Yii
    docker-compose exec app composer create-project --prefer-dist yiisoft/yii2-app-basic "$project_name"

  else
    printf "\nInvalid framework specified."

  fi

else

  printf "\nDownloading git repo ${git_repo} ...\n"
  docker-compose exec app git clone $git_repo $project_name
  docker-compose exec app cd "${local_project_dir}" | composer update
  docker-compose exec app cp "${local_project_dir}/.env.example" "${local_project_dir}/.env"

fi

# Update configuration files.
printf "\nUpdating configuration files ...\n"
if [[ $project_framework == "CakePHP" ]]; then
  # CakePHP
  printf "\nUpdating .env file ...\n"
  docker-compose exec app sed -i "s/export APP_NAME=.*/export APP_NAME=\"${project_name}\"/g" "${local_project_dir}/config/.env"
  docker-compose exec app sed -i "s/export SECURITY_SALT=.*/export SECURITY_SALT=\"$(openssl rand -base64 6)\"/g" "${local_project_dir}/config/.env"
elif [[ $project_framework == "CodeIgniter" ]]; then
  # CodeIgniter
  printf "\nUpdating .env file ...\n"
  docker-compose exec app sed -i "s/# CI_ENVIRONMENT =.*/CI_ENVIRONMENT = development/g" "${local_project_dir}/.env"
  docker-compose exec app sed -i "s/# database.default.hostname =.*/database.default.hostname = db-${service_db}/g" "${local_project_dir}/.env"
  docker-compose exec app sed -i "s/# database.default.database =.*/database.default.database = ${db_name}/g" "${local_project_dir}/.env"
  docker-compose exec app sed -i "s/# database.default.username =.*/database.default.username = ${db_username}/g" "${local_project_dir}/.env"
  docker-compose exec app sed -i "s/# database.default.password =.*/database.default.password = ${db_password}/g" "${local_project_dir}/.env"
  docker-compose exec app sed -i "s/HASH_SECRET_KEY =.*/HASH_SECRET_KEY = dasgfasgdfsgdfshdh/g" "${local_project_dir}/.env"
  #tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo ''
elif [[ $project_framework == "Laravel" ]] || [[ $project_framework == "Lumen" ]]; then
  # Laravel/Lumen
  printf "\nUpdating .env file ...\n"
  docker-compose exec app sed -i "s/APP_NAME=.*/APP_NAME=${project_name}/" "${local_project_dir}/.env"
  docker-compose exec app sed -i "s/APP_KEY=.*/APP_KEY=$(openssl rand -base64 64)/" "${local_project_dir}/.env"
  docker-compose exec app sed -i "s/DB_HOST=.*/DB_HOST=db-${service_db}/" "${local_project_dir}/.env"
  docker-compose exec app sed -i "s/DB_DATABASE=.*/DB_DATABASE=${db_name}/" "${local_project_dir}/.env"
  docker-compose exec app sed -i "s/DB_USERNAME=.*/DB_USERNAME=${db_username}/" "${local_project_dir}/.env"
  docker-compose exec app sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${db_password}/" "${local_project_dir}/.env"
elif [[ $project_framework == "Symfony" ]]; then
  # Symfony
  printf "\nUpdating .env file ...\n"
  docker-compose exec app echo "DB_USER=${db_username}" >> "${local_project_dir}/.local.env"
  docker-compose exec app echo "DB_PASS=${db_password}" >> "${local_project_dir}/.local.env"
elif [[ $project_framework == "Yii" ]]; then
  # Yii
  docker-compose exec app sed -i "s/    'dsn' => '${service_db}:host=,.*/    'dsn' => '${service_db}:host=localhost;dbname=${db_name}',/g" "${local_project_dir}/config/web.php"
  docker-compose exec app sed -i "s/    'username' => 'root'.*/    'username' => '${db_username}',/g" "${local_project_dir}/config/web.php"
  docker-compose exec app sed -i "s/    'password' => ''.*/    'password' => '${db_username}',/g" "${local_project_dir}/config/web.php"
fi


# Run post install processes.
#docker restart "${project_name}-app"

if [[ $project_framework == "Laravel" ]]; then
  docker-compose exec app php "${local_project_dir}/artisan" optimize:clear
  if [[ $run_migrations == "Y" ]]; then
    docker-compose exec app php "${local_project_dir}/artisan" migrate
  fi
elif [[ $project_framework == "Lumen" ]]; then
  docker-compose exec app php "${local_project_dir}/artisan" cache:clear
  if [[ $run_migrations == "Y" ]]; then
    docker-compose exec app php "${local_project_dir}/artisan" migrate
  fi
fi

printf "\nIf you see any errors with the 'composer install' command then run a composer update with the command:\n"
printf "\tdocker-compose exec app composer update\n"
printf "\tYou can now go to http://localhost:${port} in your browser.\n"
printf "\tYou can access phpMyAdmin at http://localhost:${phpmyadmin_port} where the server is \"db-${service_db}\".\n"
exit
