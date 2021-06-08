#!/bin/bash

docker_version="3.7"
docker_compose_yml_version="nginx-mysql"
dockerfile_filename="php-7-4-fpm"
create_mailhog_container="Y"

service_app="app"
service_db="mysql"
service_phpmyadmin="phpmyadmin"
service_pgadmin="pgadmin"
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
db_name=${project_name//[\-]/_}
db_root_password=
db_username=
db_password=
db_port=3306
db_exposed_port=6603
db_admin_app="phpMyAdmin"
db_admin_port=8001
full_install="Y"
frameworks_with_db_migrations=("CodeIgniter" "Laravel")
run_db_migrations="Y"
frameworks_with_db_seeds=("CodeIgniter" "Laravel")
run_db_seeds="Y"

create_phpinfo_file="N"

create_docker_containers() {

  # ##########################################################################################
  # Create the docker containers.
  # ##########################################################################################

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
  if [[ "${service_db}" == "mariadb" ]]; then
    cp "${working_dir}/docker-compose/mysql/init.sql" "${init_db_file}"
  else
    cp "${working_dir}/docker-compose/${service_db}/init.sql" "${init_db_file}"
  fi

  # Create docker-compose.yml file.
  printf "Creating docker-compose.yml file ...\n"
  echo "version: \"${docker_version}\"" > "${docker_compose_file}"
  echo "services:" >> "${docker_compose_file}"
  cat "${working_dir}/configurations/docker-compose-sections/service-${service_app}" >> "${docker_compose_file}"
  cat "${working_dir}/configurations/docker-compose-sections/service-${service_db}" >> "${docker_compose_file}"
  if [[ "${service_db}" == "mysql" ]] || [[ "${service_db}" == "mariadb" ]]; then
    cat "${working_dir}/configurations/docker-compose-sections/service-${service_phpmyadmin}" >> "${docker_compose_file}"
  elif [[ "${service_db}" == "postgre" ]]; then
    cat "${working_dir}/configurations/docker-compose-sections/service-${service_pgadmin}" >> "${docker_compose_file}"
  fi
  if [[ $create_mailhog_container == "Y" ]]; then
    cat "${working_dir}/configurations/docker-compose-sections/service-mailhog" >> "${docker_compose_file}"
  fi;
  cat "${working_dir}/configurations/docker-compose-sections/service-${service_server}" >> "${docker_compose_file}"
  cat "${working_dir}/configurations/docker-compose-sections/networks" >> "${docker_compose_file}"
  cat "${working_dir}/configurations/docker-compose-sections/volumes" >> "${docker_compose_file}"

  # Make changes to docker-compose.yml file.
  printf "Updating docker-compose.yml file ...\n"
  sed -i "s/{{project_name}}/${project_name}/g" ${docker_compose_file}
  sed -i "s/{{port}}/${port}/g" ${docker_compose_file}
  sed -i "s/{{service_db}}/${service_db}/g" ${docker_compose_file}
  sed -i "s/{{db_exposed_port}}/${db_exposed_port}/g" ${docker_compose_file}
  sed -i "s/{{db_admin_port}}/${db_admin_port}/g" ${docker_compose_file}

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

  # Add superuser create to init.sql file
  if [[ "${service_db}" == "mysql" ]] || [[ "${service_db}" == "mariadb" ]]; then
    echo "CREATE DATABASE FLUSH ${db_name};" >> ${init_db_file}
    echo "CREATE USER \"${db_username}'@'localhost' IDENTIFIED BY \"${db_password}\";" >> ${init_db_file}
    echo "GRANT ALL PRIVILEGES ON *.* TO '${db_username}'@'localhost' WITH GRANT OPTION;" >> ${init_db_file}
    echo "CREATE USER '${db_username}'@'%' IDENTIFIED BY \"${db_password}\";" >> ${init_db_file}
    echo "GRANT ALL PRIVILEGES ON *.* TO '${db_username}'@'%' WITH GRANT OPTION;" >> ${init_db_file}
    echo "FLUSH PRIVILEGES;" >> ${init_db_file}
  elif [[ "${service_db}" == "postgres" ]]; then
    echo "create database ${db_name};" >> ${init_db_file}
    echo "create user ${db_username} with encrypted password '${db_password}';" >> ${init_db_file}
    echo "grant all privileges on database ${db_name} to ${db_username};" >> ${init_db_file}
  fi

  # Copy bash scripts (and set variable values).
  printf "\nCopying bash script files ...\n"
  mkdir "${project_dir}/scripts/"
  cp -r "${working_dir}/scripts/" "${project_dir}"
  for bash_script in "${project_dir}"/scripts/*.sh; do
    sed -i "s/{{project_name}}/${project_name}/g" "${bash_script}"
    sed -i "s#{{local_project_dir}}#${local_project_dir}#g" "${bash_script}"
  done

  printf "Building Docker containers ...\n"
  docker-compose build
  docker-compose up -d
  docker-compose ps

  # Remove init.sql setup file.
  ###rm "${init_db_file}"
}


# ##########################################################################################
# Prompt user for all settings.
# ##########################################################################################

# Prompt for the type of project. (Are we including MailHog?)
printf "\nSelect the type of project: [1]"
printf "\n\t1 - Web Server"
printf "\n\t2 - Web Server and Fake SMTP (MailHog)"
printf "\n\t3 - Fake SMTP (MailHog) only"
printf "\n"
selected_option=0
while [[ selected_option -lt 1 || selected_option -gt 3 ]]; do
  read selected_option
  if [ -z "$selected_option" ]; then
    selected_option=1
  fi
  selected_option="$((selected_option))"
done
if [[ "$selected_option" -eq 2 ]] || [[ "$selected_option" -eq 3 ]]; then
  selected_option="$((selected_option))"
  create_mailhog_container="Y"
  if [[ "$selected_option" -eq 3 ]] ; then
  printf "\nCreating up fake-smtp-mailhog container ...\n"
    cd configurations/docker-compose-files/mailhog
    docker-compose up -d mailhog
    printf "\nMailHog container has been created as fake-smtp-mailhog:\n"
    exit
  fi
else
  create_mailhog_container="N"
fi

# Prompt for which Dockerfile to use.
printf "\nSelect Docker file: [1]"
declare -a dockerfiles
files=("${working_dir}"/configurations/Dockerfiles/*)
cnt=1
for ((i=${#files[@]}-1; i>=0; i--)); do
  dockerfiles[$cnt]="${files[$i]##*/}"
  printf "\n\t${cnt} - ${dockerfiles[$cnt]}"
  cnt=$((${cnt} + 1))
done
printf "\n"
selected_option=0
while [[ selected_option -lt 1 || selected_option -gt "${cnt}" ]]; do
  read selected_option
  if [ -z "$selected_option" ]; then
    selected_option=1
  fi
done
dockerfile_filename="${dockerfiles[selected_option]}"

# Get the project name.
if [ -z "$project_name" ]; then
  printf "\nProject name (Can only contain letters, numbers, underscores and dashes.): "
  valid_project_name=false
  while [ "$valid_project_name" != true ]; do
    read  project_name
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
repo_okay=false
printf "\nGit repository (Leave blank for none.): \n"
while [ "$repo_okay" != true ]; do
  read git_repo
  if [ -z "$git_repo" ]; then
    repo_okay=true
  else
    if (git ls-remote "${git_repo}" -q 2>&1); then
      repo_okay=true
    else
      printf "\nEnter a different git repository or leave blank to create a new project.\n"
      git_repo=
    fi
  fi
done

# Get the project framework.
printf "\nSelect the project framework."
#printf "\n\t1 - CakePHP"
printf "\n\t2 - CodeIgniter"
printf "\n\t3 - Laravel"
printf "\n\t4 - Lumen"
printf "\n\t5 - Symfony"
#printf "\n\t6 - WordPress"
#printf "\n\t7 - Yii"
#printf "\n\t8 - Zend"
printf "\n"
selected_option=-1
while [[ selected_option -lt 1 || selected_option -gt 8 ]]; do
  read selected_option
  selected_option="$((selected_option))"
done

if [[ "$selected_option" -eq 1 ]]; then
  project_framework="CakePHP"
elif [[ "$selected_option" -eq 2 ]]; then
  project_framework="CodeIgniter"
elif [[ "$selected_option" -eq 3 ]]; then
  project_framework="Laravel"
elif [[ "$selected_option" -eq 4 ]]; then
  project_framework="Lumen"
elif [[ "$selected_option" -eq 5 ]]; then
  project_framework="Symfony"
elif [[ "$selected_option" -eq 6 ]]; then
  project_framework="WordPress"
elif [[ "$selected_option" -eq 7 ]]; then
  project_framework="Yii"
elif [[ "$selected_option" -eq 8 ]]; then
  project_framework="Zend"
fi
unimplemented_frameworks=("CakePHP Symfony WordPress Yii Zend")
if [[ " ${unimplemented_frameworks[@]} " =~ " ${project_framework} " ]]; then
    printf "Sorry, ${project_framework} has not been implemented yet.\n"
    exit
fi
printf "\n"

# Is this a full install?
frameworks_with_partial_installs=("Symfony")
if [[ " ${frameworks_with_partial_installs[@]} " =~ " ${project_framework} " ]]; then
  printf "\nIs this a full install [Y/n]?"
  valid_replies=("Y N")
  good_reply=false
  while [ "$good_reply" != true ]; do
    read full_install
    if [ -z "$full_install" ]; then
      full_install="Y"
    fi
    full_install=${full_install^^}
    if [[ " ${valid_replies[@]} " =~ " ${full_install} " ]]; then
      good_reply=true
    fi
  done
fi

# Get the project directory.
printf "Project directory [${project_base_dir}]: \n"
read custom_base_dir
custom_base_dir=${custom_base_dir:-${project_base_dir}}
project_base_dir=$custom_base_dir
project_dir="${project_base_dir}/${project_name}"

# Verify that directories do not already exist.
if [ -d $project_dir ]; then
  printf "\nThe directory ${project_dir} already exists.\n"
  exit
fi
if [ ! -d $project_base_dir ]; then
  printf "\nThe project base directory ${project_base_dir} does not exist.  Please create it and rerun this script.\n"
  exit
fi

# Get the port.
port_is_in_use="Y"
select_a_port_prompt="Select a port [${default_port}]: "
while [[ "${port_is_in_use}" == "Y" ]]; do
  printf "${select_a_port_prompt}\n"
  read port
  port=${port:-${default_port}}
  if [[ "$port" -lt 1024 ||"$port" -gt 65535 ]]; then
    select_a_port_prompt="A port must be in the range 1024 to 65535. Select a different port [${default_port}]: "
  elif [[ $(nc -w5 -z -v localhost "${port}" 2>&1) == *"succeeded"* ]]; then
    select_a_port_prompt="Port ${port} is in use. Select a different port [${default_port}]: "
    port_is_in_use="Y"
  else
    port_is_in_use="N"
  fi
done

# Get database type
printf "\nSelect the type of database:"
printf "\n\t1 - MySQL"
printf "\n\t2 - MariaDB"
printf "\n\t3 - Postgres"
printf "\n"
selected_option=-1
while [[ selected_option -lt 1 || selected_option -gt 3 ]]; do
  read selected_option
  selected_option="$((selected_option))"
done
if [[ "$selected_option" -eq 1 ]]; then
  service_db="mysql"
  db_port=3306
  db_admin_app="phpMyAdmin"
  db_exposed_port=6603
elif [[ "$selected_option" -eq 2 ]]; then
  service_db="mariadb"
  db_port=3306
  db_admin_app="phpMyAdmin"
  db_exposed_port=6603
elif [[ "$selected_option" -eq 3 ]]; then
  service_db="postgres"
  db_port=5432
  db_admin_app="pgAdmin"
  db_exposed_port=5432
fi
# Set the port for the database admin program (phpMyAdmin, pgAdmin, etc.).  (Make sure the port is available.)
db_admin_port=$(($port + 1))
while [[ $(nc -w5 -z -v localhost "${db_admin_port}" 2>&1) == *"succeeded"* ]]; do
  db_admin_port=$((db_admin_port + 1))
done

# If the exposed port for the database is in use then keep incrementing it until we find an open port.
while [[ $(nc -w5 -z -v localhost "${db_exposed_port}" 2>&1) == *"succeeded"* ]]; do
  db_exposed_port=$((${db_exposed_port} + 1))
done

# Get database root password.
printf "\nEnter database root password: \n"
db_root_password=
while [ -z "$db_root_password" ]; do
  read db_root_password
done

# Get database username.
db_username=
valid_username=false
while [ "$valid_username" = false ]; do
  printf "\nEnter database username: \n"
  read db_username
  if [ -z "$db_username" ]; then
    valid_username=false
  elif [[ !($db_username =~ ^[A-Za-z0-9_-]+$) ]]; then
    printf "\nUser name an only contain alphanumeric characters, underscores and dashes.)"
    valid_username=false
  elif [[ $(expr length "$db_username") -gt 20 ]]; then
    printf "\nUser name can be no longer than 20 characters."
    valid_username=false
  else
    valid_username=true
  fi
done

# Get database user password.
printf "\nEnter database user password: \n"
db_password=
while [ -z "$db_password" ]; do
  read db_password
done

# Should we run database migrations?
if [[ " ${frameworks_with_db_migrations[@]} " =~ " ${project_framework} " ]]; then
  printf "\nRun database migrations [Y/n]?"
  valid_replies=("Y N")
  good_reply=false
  while [ "$good_reply" != true ]; do
    read run_db_migrations
    if [ -z "$run_db_migrations" ]; then
      run_db_migrations="Y"
    fi
    run_db_migrations=${run_db_migrations^^}
    if [[ " ${valid_replies[@]} " =~ " ${run_db_migrations} " ]]; then
      good_reply=true
    fi
  done
fi

# Should we run database seeders?
if [[ " ${frameworks_with_db_seeds[@]} " =~ " ${project_framework} " ]]; then
  printf "\nRun database seeders [Y/n]?"
  valid_replies=("Y N")
  good_reply=false
  while [ "$good_reply" != true ]; do
    read run_db_seeds
    if [ -z "$run_db_seeds" ]; then
      run_db_seeds="Y"
    fi
    run_db_seeds=${run_db_seeds^^}
    if [[ " ${valid_replies[@]} " =~ " ${run_db_seeds} " ]]; then
      good_reply=true
    fi
  done
fi

# Should we create a phpinfo.php file
valid_replies=("Y N")
printf "\nShould we create a http://localhost:${port}/phpinfo.php file: [Y/n]"
good_reply=false
while [ "$good_reply" != true ]; do
  read create_phpinfo_file
  if [ -z "$create_phpinfo_file" ]; then
    create_phpinfo_file="Y"
  fi
  create_phpinfo_file=${create_phpinfo_file^^}
  if [[ " ${valid_replies[@]} " =~ " ${create_phpinfo_file} " ]]; then
    good_reply=true
  fi
done


# ##########################################################################################
# Confirm settings before continuing.
# ##########################################################################################

printf "\n-----------------------------------------------------------"
printf "\nProject name:        ${project_name}"
printf "\nProject framework:   ${project_framework}"
if [[ $project_framework == "Symfony" ]]; then
  printf "\nFull install:        ${project_framework}"
fi
printf "\nProject directory:   ${project_dir}"
printf "\nGit repository:      ${git_repo}"
#printf "\nWorking directory:   ${working_dir}"
#printf "\nBase directory:      ${base_dir}"
printf "\nPort:                ${port}"
if [[ "${service_db}" == "mysql" ]] || [[ "${service_db}" == "mariadb" ]]; then
  printf "\nphpMyAdmin port:     ${db_admin_port}"
elif [[ "${service_db}" == "postgres" ]]; then
  printf "\npgAdmin port:        ${db_admin_port}"
fi
printf "n/phpinfo.php file"    "${create_phpinfo_file}"
printf "\nDatabase:"
printf "\n    Type:            ${service_db}"
printf "\n    Name:            ${db_name}"
printf "\n    Root password:   ***${db_root_password: -3}"
printf "\n    Username:        ${db_username}"
printf "\n    Password:        ***${db_password: -3}"
if [[ " ${frameworks_with_db_migrations[@]} " =~ " ${project_framework} " ]]; then
  printf "\n    Run migrations:  ${run_db_migrations}"
fi
if [[ " ${frameworks_with_db_seeds[@]} " =~ " ${project_framework} " ]]; then
  printf "\n    Run db seeds:    ${run_db_seeds}"
fi
printf "\n-----------------------------------------------------------\n\n"

read -p "Hit [Enter] to continue or Ctrl-C to quit." reply

# Define Docker files.
nginx_conf_file="${project_dir}/docker-compose/${service_server}/${project_name}.conf"
if [[ "${service_db}" == "postgres" ]]; then
  init_db_file="${project_dir}/docker-compose/${service_db}/init.sh"
else
  init_db_file="${project_dir}/docker-compose/${service_db}/init.sql"
fi
docker_compose_file="${project_dir}/docker-compose.yml"
docker_file="${project_dir}/Dockerfile"

cd "${project_base_dir}"

# Copy configuration files to the project directory.
mkdir "${project_dir}"
create_docker_containers


# ##########################################################################################
# Install php framework (or repository).
# ##########################################################################################

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
    docker exec -w "${local_project_dir}" "${project_name}-app" bash "/var/www/scripts/codeigniter-initialize_env_file.sh"
    cat "${working_dir}/configurations/env-sections/CodeIgniter" >>  "${project_dir}/${project_name}/.env"

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

  # Clone git repository.
  docker exec -w /var/www/scripts "${project_name}-app" bash "git_clone.sh ${git_repo} ${project_name}"
  #docker exec -it "${project_name}-app" bash - c bash /var/www/scripts/git_clone.sh "${git_repo}" "${project_name}"
  docker exec -w /var/www/scripts "${project_name}-app" bash composer_update.sh

fi


# ##########################################################################################
# Update configuration files.
# ##########################################################################################

if [[ $project_framework == "CakePHP" ]]; then

  # CakePHP
  printf "\nUpdating .env file and configuration settings ...\n"
  docker-compose exec app sed -i "s/export APP_NAME=.*/export APP_NAME=\"${project_name}\"/g" "${local_project_dir}/config/.env"
  docker-compose exec app sed -i "s/export SECURITY_SALT=.*/export SECURITY_SALT=\"$(openssl rand -base64 6)\"/g" "${local_project_dir}/config/.env"

elif [[ $project_framework == "CodeIgniter" ]]; then

  # CodeIgniter
  printf "\nUpdating .env file and configuration settings ...\n"
  docker exec -w "${local_project_dir}" "${project_name}-app" sed -i "s/# CI_ENVIRONMENT =.*/CI_ENVIRONMENT = development/g" .env
  docker exec -w "${local_project_dir}" "${project_name}-app" sed -i "s/# database.default.hostname =.*/database.default.hostname = db-${service_db}/g" .env
  docker exec -w "${local_project_dir}" "${project_name}-app" sed -i "s/# database.default.database =.*/database.default.database = ${db_name}/g" .env
  docker exec -w "${local_project_dir}" "${project_name}-app" sed -i "s/# database.default.username =.*/database.default.username = ${db_username}/g" .env
  docker exec -w "${local_project_dir}" "${project_name}-app" sed -i "s/# database.default.password =.*/database.default.password = '${db_password}'/g" .env
  hash=$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev 2>&1)
  hash=$(echo -n $hash | md5sum | cut -c 1-32)
  docker exec -w "${local_project_dir}" "${project_name}-app" sed -i "s/HASH_SECRET_KEY =.*/HASH_SECRET_KEY = \'${hash}\'/" .env
  if [ -z "$git_repo" ]; then
    docker exec -w "${local_project_dir}/app/Config" "${project_name}-app" sed -i "s/public \$baseURL =.*/        public \$baseURL = 'http:\/\/localhost:${port}\/';/" App.php
    docker exec -w "${local_project_dir}/app/Config" "${project_name}-app" sed -i "s/public \$indexPage =.*/        public \$indexPage = '';/g" App.php
  fi

elif [[ $project_framework == "Laravel" ]] || [[ $project_framework == "Lumen" ]]; then

  # Laravel/Lumen
  printf "\nUpdating .env file and configuration settings ...\n"
  docker exec -w "${local_project_dir}" "${project_name}-app" sed -i "s/APP_NAME=.*/APP_NAME=${project_name}/" .env
  docker exec -w "${local_project_dir}" "${project_name}-app" sed -i "s/APP_ENV=.*/APP_ENV=local/" .env
  docker exec -w "${local_project_dir}" "${project_name}-app" php artisan key:generate
  docker exec -w "${local_project_dir}" "${project_name}-app" sed -i "s/APP_URL=.*/APP_URL=http:\/\/localhost:${port}/" .env
  docker exec -w "${local_project_dir}" "${project_name}-app" sed -i "s/DB_HOST=.*/DB_HOST=db-${service_db}/" .env
  docker exec -w "${local_project_dir}" "${project_name}-app" sed -i "s/DB_PORT=.*/DB_PORT=${db_port}/" .env
  docker exec -w "${local_project_dir}" "${project_name}-app" sed -i "s/DB_DATABASE=.*/DB_DATABASE=${db_name}/" .env
  docker exec -w "${local_project_dir}" "${project_name}-app" sed -i "s/DB_USERNAME=.*/DB_USERNAME=${db_username}/" .env
  docker exec -w "${local_project_dir}" "${project_name}-app" sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${db_password}/" .env

elif [[ $project_framework == "Symfony" ]]; then

  # Symfony
  printf "\nUpdating .env file and configuration settings ...\n"
  docker-compose exec app echo "DB_USER=${db_username}" >> "${local_project_dir}/.local.env"
  docker-compose exec app echo "DB_PASS=${db_password}" >> "${local_project_dir}/.local.env"

elif [[ $project_framework == "Yii" ]]; then

  # Yii
  printf "\nUpdating configuration settings ...\n"
  docker-compose exec app sed -i "s/    'dsn' => '${service_db}:host=,.*/    'dsn' => '${service_db}:host=localhost;dbname=${db_name}',/g" "${local_project_dir}/config/web.php"
  docker-compose exec app sed -i "s/    'username' => 'root'.*/    'username' => '${db_username}',/g" "${local_project_dir}/config/web.php"
  docker-compose exec app sed -i "s/    'password' => ''.*/    'password' => '${db_username}',/g" "${local_project_dir}/config/web.php"

fi


# ##########################################################################################
# Run post install processes.
# ##########################################################################################

#docker restart "${project_name}-app"

if [[ $project_framework == "CodeIgniter" ]]; then

  # CodeIgniter
  if [[ $run_db_migrations == "Y" ]]; then
    printf "\nRunning database migrations ..."
    docker exec -w "${local_project_dir}" "${project_name}-app" bash "/var/www/scripts/codeigniter-migrate.sh"

#    docker exec -w "${local_project_dir}" "${project_name}-app" bash "/var/www/scripts/codeigniter-migrate.sh"
  fi
  if [[ $run_db_seeds == "Y" ]]; then
    printf "\nRunning database seeds ..."
    docker exec -w "${local_project_dir}" "${project_name}-app" bash "/var/www/scripts/codeigniter-db-seed.sh"
  fi

elif [[ $project_framework == "Laravel" ]]; then

  # Laravel
  docker exec -w /var/www/scripts "${project_name}-app" bash laravel-clear_cache.sh
  docker restart "${project_name}-app"
  if [[ $run_db_migrations == "Y" ]]; then
    docker exec -w /var/www/scripts "${project_name}-app" bash laravel-migrate.sh
  fi
  if [[ $run_db_seeds == "Y" ]]; then
    docker exec -w /var/www/scripts "${project_name}-app" bash laravel-db_seed.sh
  fi

elif [[ $project_framework == "Lumen" ]]; then

  docker-compose exec app php "${local_project_dir}/artisan" cache:clear
  if [[ $run_db_migrations == "Y" ]]; then
    docker-compose exec app php "${local_project_dir}/artisan" migrate
  fi

fi

# Should we create a phpinfo.php file?
if [[ $create_phpinfo_file == "Y" ]]; then
  docker exec -w /var/www/scripts "${project_name}-app" bash create_phpinfo.sh
fi

# Add any development environment files to .gitignore
docker exec -w /var/www/scripts "${project_name}-app" bash add_dev_only_files_to_gitignore.sh
add_dev_only_files_to_gitignore.sh

printf "\n-----------------------------------------------------------\n\n"
printf "\nYou can now access the following in you browser:"
printf "\n\n\tWebsite: http://localhost:${port}\n"
if [[ "${service_db}" == "mysql" ]] || [[ "${service_db}" == "mariadb" ]]; then
  printf "\n\t${db_admin_app}: http://localhost:${db_admin_port}"
  printf "\n\t\tServer:   db-${service_db}"
  printf "\n\t\tUsername: ${db_username}"
  printf "\n\t\tPassword: ***${db_password}"
elif [[ "${service_db}" == "postgres" ]]; then
  printf "\n\t${db_admin_app}: http://localhost:${db_admin_port}"
  printf "\n\t\tEmail Address / Username: admin@admin.com"
  printf "\n\t\tPassword:                 root"
fi
printf "\n"
exit
