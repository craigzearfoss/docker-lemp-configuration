#!/bin/bash

docker_version="3.7"
script_completed=false

working_dir="$(pwd)"

service_server=""   # NGINX
service_db=""       # MySQL / MariaDB / Postgres
service_db_admin="" # phpMyAdmin or pgAdmin
service_email=""    # MailHog"
server_version=""   # name of the docker file in the configurations/Dockerfiles directory
containers_created=()

create_app_service=true

project_name=$1
php_framework=""
git_repo=""
container_base_dir=$(echo $working_dir | sed "s|\(.*\)/.*|\1|")
container_dir="${container_base_dir}/${project_name}"
site_dir="${container_dir}/site"
web_root="${container_dir}/site/public"
local_web_root="/var/www/site/public"
local_container_dir="/var/www/${project_name}"
create_project_script="${container_dir}/create_project.sh"
port=
default_port=8000
dockerfiles=("${working_dir}"/configurations/Dockerfiles/*)
db_name=${project_name//[\-]/_}
db_root_password=
db_username=
db_password=
db_port=3306
db_exposed_port=6603
dd_admin_port=$((${dd_admin_port} + 1))

# Get a list of available databases
db_services=("MySQL" "MariaDB" "Postgres")

# Get a list of available PHP frameworks
# @TODO: Need to add Phalcon  WordPress Drupal
php_frameworks=()
search_dir="/home/craig/Documents/temp/docker-auto-compose/configurations/php-framework-installs"
for entry in "${working_dir}"/configurations/php-framework-installs/*; do
  filename="${entry##*/}"
  php_frameworks+=("${filename%.*}")
done

frameworks_with_partial_installs=("Symfony")
frameworks_with_db_migrations=("CodeIgniter" "Laravel")
frameworks_with_db_seeds=("CodeIgniter" "Laravel")

full_install=true
run_db_migrations=false
run_db_seeds="Y"

# Set the project URLs
site_url="http://localhost:${port}"
db_admin_url="http://localhost:${db_admin_port}"

create_phpinfo_file="N"
create_project_script="create_project_script"


join_by() {
  local IFS="$1";
  shift;
  echo "$*";
}

define_docker_files() {
  # ##########################################################################################
  # Define docker files.
  # ##########################################################################################

  docker_file="${container_dir}/Dockerfile"
  docker_compose_file="${container_dir}/docker-compose.yml"
  server_conf_file="${container_dir}/conf-files/${service_server,,}.conf"
  if [[ "${service_db^^}" == "MARIADB" ]] || [[ "${service_db^^}" == "MYSQL" ]]; then
    init_db_file="${container_dir}/init-files/${service_db,,}/initdb.sql"
  elif [[ "${service_db^^}" == "POSTGRES" ]]; then
    init_db_file="${container_dir}/init-files/${service_db,,}/initdb.sh"
  else
    init_db_file=""
  fi
}

create_docker_files() {
  # ##########################################################################################
  # Create the docker containers.
  # ##########################################################################################

  printf "\n\nCopying configuration files ...\n"
  mkdir -p "${container_dir}"
  cp "${working_dir}/configurations/Dockerfiles/${server_version}" "${docker_file}"
  cp -pr "${working_dir}/configurations/" "${container_dir}/configurations"

  # Create docker-compose.yml file.
  printf "Creating docker-compose.yml ...\n"
  echo "version: \"${docker_version}\"" > "${docker_compose_file}"
  echo "services:" >> "${docker_compose_file}"

  if [[ "${create_app_service}" == true ]]; then
    cat "${working_dir}/configurations/docker-compose-sections/service-app" >> "${docker_compose_file}"
  fi

  if [[ ! -z "${service_db}" ]]; then
    cat "${working_dir}/configurations/docker-compose-sections/service-${service_db,,}" >> "${docker_compose_file}"
  fi

  if [[ ! -z "${service_db_admin}" ]]; then
    cat "${working_dir}/configurations/docker-compose-sections/service-${service_db_admin,,}" >> "${docker_compose_file}"
  fi

  if [[ ! -z ${db_email} ]]; then
    cat "${working_dir}/configurations/docker-compose-sections/service-${db_email},," >> "${docker_compose_file}"
  fi;

  if [[ ! -z "${service_server}" ]]; then
    cat "${working_dir}/configurations/docker-compose-sections/service-${service_server,,}" >> "${docker_compose_file}"
  fi

  cat "${working_dir}/configurations/docker-compose-sections/networks" >> "${docker_compose_file}"
  cat "${working_dir}/configurations/docker-compose-sections/volumes" >> "${docker_compose_file}"

  # Make modifications to docker-compose.yml file.
  printf "Updating docker-compose.yml file ...\n"
  sed -i "s/{{project_name}}/${project_name}/g" ${docker_compose_file}
  sed -i "s/{{port}}/${port}/g" ${docker_compose_file}
  sed -i "s/{{service_db}}/${service_db,,}/g" ${docker_compose_file}
  sed -i "s/{{db_exposed_port}}/${db_exposed_port}/g" ${docker_compose_file}
  sed -i "s/{{db_admin_port}}/${db_admin_port}/g" ${docker_compose_file}
}

create_server_conf_file() {
  #server configuration

  # copy server configuration file
  export DIR=${server_conf_file%/*}
  mkdir -p "${DIR}"
  if [ -f "${container_dir}/configurations/server-files/${service_server,,}/${php_framework,,}.conf" ]; then
    cp -p "${container_dir}/configurations/server-files/${service_server,,}/${php_framework,,}.conf" "${server_conf_file}"
  else
    cp -p "${container_dir}/configurations/server-files/${service_server,,}/default.conf" "${server_conf_file}"
  fi

  # Make modifications to the server configuration file.
  if [[ "${php_framework^^}" == "CAKEPHP" ]]; then
    sed -i "s/server_name .*/server_name localhost;/g" ${server_conf_file}
    sed -i "s/[::]:80 /[::]:${port}/g" ${server_conf_file}
    sed -i "s/error_log .*/error_log  \/var\/www\/${project_name}\/log\/error.log;/g" ${server_conf_file}
    sed -i "s/access_log .*/access_log \/var\/www\/${project_name}\/log\/access.log;/g" ${server_conf_file}
  elif [[ "${php_framework^^}" == "CODEIGNITER" ]]; then
    sed -i "s/error_log .*/error_log  \/var\/log\/nginx\/${project_name}_error.log;/g" ${server_conf_file}
    sed -i "s/access_log .*/access_log \/var\/log\/nginx\/${project_name}_access.log;/g" ${server_conf_file}
  elif [[ "${php_framework^^}" == "YII2" ]]; then
    sed -i "s/error_log .*/error_log  \/var\/log\/nginx\/${project_name}_error.log;/g" ${server_conf_file}
    sed -i "s/access_log .*/access_log \/var\/log\/nginx\/${project_name}_access.log;/g" ${server_conf_file}
  else
    sed -i "s/error_log .*/error_log  \/var\/log\/nginx\/${project_name}_error.log;/g" ${server_conf_file}
    sed -i "s/access_log .*/access_log \/var\/log\/nginx\/${project_name}_access.log;/g" ${server_conf_file}
  fi
}

create_db_init_file() {
  # entrypoint file(s)

  # copy db entrypoint file
  export DIR=${init_db_file%/*}
  mkdir -p "${DIR}"
  cp "${container_dir}/configurations/db-files/${service_db,,}/${init_db_file##*/}" "${init_db_file}"

  printf "Adding database credentials ...\n"
  export DB_DATABASE="${db_name}"
  export DB_ROOT_PASSWORD="${db_root_password}"
  export DB_USERNAME="${db_username}"
  export DB_PASSWORD="${db_password}"

  # Add superuser create to init.sql file
  ## @TODO: Need to implement for Postgres
  if [[ "${service_db^^}" == "MYSQL" ]] || [[ "${service_db^^}" == "MARIADB" ]]; then
    echo "" >> ${init_db_file}
    echo "/*" >> ${init_db_file}
    echo " Create administrator user" >> ${init_db_file}
    echo "*/" >> ${init_db_file}
    echo "CREATE DATABASE FLUSH ${db_name};" >> ${init_db_file}
    echo "CREATE USER \"${db_username}'@'localhost' IDENTIFIED BY \"${db_password}\";" >> ${init_db_file}
    echo "GRANT ALL PRIVILEGES ON *.* TO '${db_username}'@'localhost' WITH GRANT OPTION;" >> ${init_db_file}
    echo "CREATE USER '${db_username}'@'%' IDENTIFIED BY \"${db_password}\";" >> ${init_db_file}
    echo "GRANT ALL PRIVILEGES ON *.* TO '${db_username}'@'%' WITH GRANT OPTION;" >> ${init_db_file}
    echo "FLUSH PRIVILEGES;" >> ${init_db_file}
  elif [[ "${service_db^^}" == "POSTGRES" ]]; then
    echo "create database ${db_name};" >> ${init_db_file}
    echo "create user ${db_username} with encrypted password '${db_password}';" >> ${init_db_file}
    echo "grant all privileges on database ${db_name} to ${db_username};" >> ${init_db_file}
  fi
}

build_docker_images() {
  printf "Building Docker images ...\n"
  cd "${container_dir}"
  docker-compose build
  docker-compose up -d
  docker-compose ps

  # Remove init.sql setup file (Delete this file because it contains database user credentials)
  ###rm "${init_db_file}"
}

build_create_project_script() {

  # ##########################################################################################
  # Create an entrypoint bash script to create a new PHP project, get a project from a git
  # repository or make an empty project.
  # ##########################################################################################
  create_project_script="${container_dir}/create_project.sh"

  printf "\nCreating build project script ${create_project_script} ...\n\n"
  export DIR=${create_project_script%/*}
  if [ ! -d "${DIR}" ] ; then
    mkdir -p "${DIR}"
  fi

  echo '#!/bin/bash' > "${create_project_script}"
  echo 'set -o errexit' > "${create_project_script}"

  if [[ -z "$git_repo" ]] && [[ -z "$php_framework" ]]; then
    # No PHP framework or git repository specified so just create a <webroot>/index.php file
    cat "${working_dir}/scripts/create_web_root_index_file.sh" >> "${create_project_script}"
  else
    if [[ ! -z "$git_repo" ]]; then
      # Install project from a git repository
      cat "${working_dir}/scripts/git_clone_repo.sh" >> "${create_project_script}"
    else
      framework_install_script="${working_dir}/configurations/php-framework-installs/${php_framework}.sh"
      if [[ ! -f "$framework_install_script" ]]; then
        printf "\n-------------------------------------------------------------------"
        printf "\nPHP frame install file  ${framework_install_script} does not exist."
        printf "\n-------------------------------------------------------------------"
      else
        # Install a new PHP project for the specified framework
        cat "${framework_install_script}" >> "${create_project_script}"
      fi
    fi
  fi

  if [[ "${create_phpinfo_file}" == true ]]; then
    # Create phpinfo.php file
    cat "${working_dir}/scripts/create_phpinfo_file.sh" >> "${create_project_script}"
  fi

  # Make modifications to create_project.sh bash script.
  chmod +x "${create_project_script}"
  sed -i "s/#!\/bin\/bash.*//g" "${create_project_script}"
  sed -i '1s/^/#!\/bin\/bash\n/' "${create_project_script}"
  sed -i "s/{{container_dir}}/${container_dir//\//\\/}/g" "${create_project_script}"
  sed -i "s/{{db_admin_port}}/${db_admin_port}/g" "${create_project_script}"
  sed -i "s/{{db_exposed_port}}/${db_exposed_port}/g" "${create_project_script}"
  sed -i "s/{{git_repo}}/${git_repo//\//\\/}/g" "${create_project_script}"
  sed -i "s/{{project_name}}/${project_name}/g" "${create_project_script}"
  sed -i "s/{{port}}/${port}/g" "${create_project_script}"
  sed -i "s/{{service_db}}/${service_db,,}/g" "${boocreate_project_scripttstrap_file}"
  sed -i "s/{{web_root}}/${web_root//\//\\/}/g" "${create_project_script}"
  sed -i "s/{{local_web_root}}/${local_web_root//\//\\/}/g" "${create_project_script}"

  #printf "\n\nRunning ${create_project_script} bash script ...\n\n"
  ##bash "${create_project_script}"

  #echo "" >> "${create_project_script}"
  #echo "# Run composer" >> "${create_project_script}"
  #echo "cd /var/www/site" >> "${create_project_script}"
  #echo "composer update" >> "${create_project_script}"
  #echo "exit" >> "${create_project_script}"
  #exit
}

run_post_install_processes_OLD(){
  #docker restart "${project_name}-app"

  if [[ $project_framework == "CodeIgniter" ]]; then

    # CodeIgniter
    if [[ $run_db_migrations == "Y" ]]; then
      printf "\nRunning database migrations ..."
      docker exec -w "${local_container_dir}" "${project_name}-app" bash "/var/www/scripts/codeigniter-migrate.sh"

  #    docker exec -w "${local_container_dir}" "${project_name}-app" bash "/var/www/scripts/codeigniter-migrate.sh"
    fi
    if [[ $run_db_seeds == "Y" ]]; then
      printf "\nRunning database seeds ..."
      docker exec -w "${local_container_dir}" "${project_name}-app" bash "/var/www/scripts/codeigniter-db-seed.sh"
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

    docker-compose exec app php "${local_container_dir}/artisan" cache:clear
    if [[ $run_db_migrations == "Y" ]]; then
      docker-compose exec app php "${local_container_dir}/artisan" migrate
    fi

  fi


  # Add any development environment files to .gitignore
  docker exec -w /var/www/scripts "${project_name}-app" bash add_dev_only_files_to_gitignore.sh
  add_dev_only_files_to_gitignore.sh
}

run_post_install_processes(){
  # ##########################################################################################
  # Run post install processes.
  # ##########################################################################################
  printf "\n\nRunning post-install process ... "
}

build_project() {
  printf "\n\nBuilding project ....\n"
  docker exec -t "${project_name}-app" bash create_project.sh
}

get_choice_response() {
  local __options=("$@")

  i=1
  for name in "${__options[@]}"; do
    printf "\n\t${i} - ${name##*/}"
    i=$((${i} + 1))
  done
  printf "\n"

  response=0
  while [[ response -lt 1 || response -gt "${#__options[@]}" ]]; do
    read response
  done
  response=$((${response} - 1))
}

get_yes_or_no_response() {
  local __default=$1
  valid_yes_no_responses=("Y N")
  good_reply=false
  while [ "$good_reply" != true ]; do
    read response
    if [[ -z "${response}" ]] && [[ ! -z "${__default}" ]]; then
      response="${__default}"
    fi
    response=${response^^}
    if [[ " ${valid_yes_no_responses[@]} " =~ " ${response} " ]]; then
      good_reply=true
    fi
  done
}

set_php_framework_or_git_repo() {
  printf "\nEnter the git repository or select a PHP framework from the following list."
  options=("(none)")
  for framework in "${php_frameworks[@]}"; do
    options+=("${framework}")
  done

  i=1
  for name in "${options[@]}"; do
    printf "\n\t${i} - ${name##*/}"
    i=$((${i} + 1))
  done
  printf "\n"
  valid_response=false
  while [[ "${valid_response}" == false ]]; do
    read response
    re='^[0-9]+$'
    if [[ -z "${response}" ]]; then
      valid_response=false
      selected_index=""
      php_framework=""
      git_repo=""
    elif ! [[ "${response/-/}" =~ $re ]]; then
      # Not a number (Assume a git repository)
      if (git ls-remote "${response}" -q 2>&1); then
        valid_response=true
        selected_index=""
        php_framework=""
        git_repo="${response}"
      else
        printf "\nGit repository does not exist or it is not accessible.\n"
        printf "\nSelect a number or enter a valid git repository.\n"
        valid_response=false
        selected_index=""
        php_framework=""
        git_repo=""
      fi
    elif [[ "$response" -eq 1 ]]; then
      valid_response=true
      selected_index=$((${response}))
      php_framework=""
      git_repo=""
    elif [[ "$response" -gt 1 && "$response" -le "${#options[@]}" ]]; then
      valid_response=true
      selected_index=$((${response} - 2))
      php_framework="${php_frameworks[$selected_index]}"
      git_repo=""
    else
      printf "\nSelect a valid number or enter a git repository.\n"
      valid_response=false
      selected_index=""
      php_framework=""
      git_repo=""
    fi
  done
  if [[ "${php_framework^^}" == "CAKEPHP" ]]; then
    local_web_root="/var/www/site/webroot"
    web_root="${site_dir}/webroot"
  elif [[ "${php_framework^^}" == "YII2" ]]; then
    local_web_root="/var/www/site/web"
    web_root="${site_dir}/web"
  fi
}

populate_containers_created_array() {
  containers_created=()
  if [[ ! -z "${service_server}" || ! -z "${service_db}" || ! -z "${service_db_admin}" ]]; then
    containers_created+=("${project_name}-app")
  fi
  if [[ ! -z "${service_server}" ]]; then
    containers_created+=("${project_name}-${service_server,,}")
  fi
  if [[ ! -z "${service_db}" ]]; then
    containers_created+=("${project_name}-${service_db,,}")
  fi
  if [[ ! -z "${service_db_admin}" ]]; then
    containers_created+=("${project_name}-${service_db_admin,,}")
  fi
  if [[ ! -z "${service_email}" ]]; then
    containers_created+=("${project_name}-${service_email,,}")
  fi
}

display_configuration() {
  populate_containers_created_array
  printf "\n-----------------------------------------------------------"
  containers_created_str=$(join_by "," ${containers_created[@]})
  if [[ "${script_completed}" == true ]]; then
    printf "\nContainers created:       ${containers_created_str}"
  else
    printf "\nContainers to be created: ${containers_created_str}"
  fi
  printf "\nProject name:             ${project_name}"
  printf "\nWebsite URL:              ${site_url}"
  if [[ "${service_db_admin^^}" == "PHPMYADMIN" ]]; then
    printf "\nphpMyAdmin URL:           ${db_admin_url}"
  elif [[ "${service_db_admin^^}" == "PGMYADMIN" ]]; then
    printf "\npgAdmin URL :             ${db_admin_url}"
  fi
  if [[ "${create_phpinfo_file}" == true ]]; then
    printf "\nPHP Information:          ${site_url}/phpinfo.php"
  fi
  printf "\nDocker version:           ${docker_version}"
  printf "\nPHP framework:            ${php_framework}"
  if [[ "${php_framework}" == "Symfony" ]] && [[ "${full_install}" == false ]]; then
    printf " (Partial install)"
  fi
  printf "\nWorking directory:        ${working_dir}"
  printf "\nContainer base dir:       ${container_base_dir}"
  printf "\nContainer directory:      ${container_dir}"
  printf "\nSite directory:           ${site_dir}"
  printf "\nWeb root:                 ${web_root}"
  printf "\nGit repository:           ${git_repo}"
  printf "\nPort:                     ${port}"
  printf "\nDatabase:"
  printf "\n    Type:                 ${service_db}"
  printf "\n    Host/Server:          db-${service_db,,}"
  printf "\n    Name:                 ${db_name}"
  printf "\n    Root password:        ***${db_root_password: -3}"
  printf "\n    Username:             ${db_username}"
  printf "\n    Password:             ***${db_password: -3}"
  printf "\n    Port:                 ${db_port}"
  printf "\n    Exposed Port:         ${db_exposed_port}"
  if [[ " ${frameworks_with_db_migrations[@]} " =~ " ${php_framework} " ]]; then
    if [[ "${run_db_migrations}" == true ]]; then
      printf "\n    Run migrations:       Y"
    else
      printf "\n    Run migrations:       N"
    fi
    if [[ "${run_db_seeds}" == true ]]; then
      printf "\n    Run db seeds:         Y"
    else
      printf "\n    Run db seeds:        N"
    fi
  fi
  printf "\n-----------------------------------------------------------\n"
}


# ##########################################################################################
# Prompt user for all settings.
# ##########################################################################################

printf "\nCreating a Docker PHP development environment\n"

# Get the project name
if [ -z "${project_name}" ]; then
  printf "\nEnter the project name. (Can only contain letters, numbers, underscores and dashes.)"
  valid_project_name=false
  while [ "${valid_project_name}" != true ]; do
    read  project_name
    if [[ "${project_name}" =~ ^[A-Za-z0-9_-]+$ ]]; then
      valid_project_name=true
    else
      valid_project_name=false
    fi
  done
fi
container_dir="${container_base_dir}/${project_name}"
local_container_dir="/var/www/${project_name}"
db_name="${project_name//[\-]/_}"
create_project_script="${container_dir}/create_project.sh"

# Get the container directory
printf "\nEnter the directory for the container or just hit [Enter]\n"
printf "to use the directory ${container_base_dir}.\n"
read custom_base_dir
custom_base_dir="${custom_base_dir:-${container_base_dir}}"
container_base_dir="${custom_base_dir}"
if [ ! -d "${container_base_dir}" ]; then
  printf "\nThe directory ${container_base_dir} does not exist. Please create it and then rerun this script.\n"
  exit
fi
container_dir="${container_base_dir}/${project_name}"
if [ -d "${container_dir}" ]; then
  printf "\nThe directory ${container_dir} already exists. Delete or rename it and then rerun this script.\n"
  exit
fi

# Get the server service and server version (from the files in the configurations/Dockerfiles directory)
service_server="NGINX"
printf "\nSelect ${service_server} version:"
get_choice_response "${dockerfiles[@]}"
dockerfile="${dockerfiles[$response]}"
server_version="${dockerfile##*/}"

# Get the port
port_is_in_use=true
select_a_port_prompt="\nSelect a port [${default_port}]: "
while [[ "${port_is_in_use}" == true ]]; do
  printf "${select_a_port_prompt}\n"
  read port
  port="${port:-${default_port}}"
  if [[ "$port" -lt 1024 ||"$port" -gt 65535 ]]; then
    select_a_port_prompt="\nA port must be in the range 1024 to 65535. Select a different port. [${default_port}] "
  elif [[ $(nc -w5 -z -v localhost "${port}" 2>&1) == *"succeeded"* ]]; then
    select_a_port_prompt="\nPort ${port} is in use. Select a different port. [${default_port}] "
    port_is_in_use=true
  else
    port_is_in_use=false
  fi
done
site_url="http://localhost:${port}"

# Set PHP framework (or git repository)
set_php_framework_or_git_repo

# Is this a full install?
if [[ ! -z "${php_framework}" ]] && [[ "${frameworks_with_partial_installs[@]}" =~ "${php_framework}" ]]; then
  printf "\nIs this a full install? [Y]"
  get_yes_or_no_response "Y"
  if [[ "${response}" == "Y" ]]; then
    full_install=true
  else
    full_response=false
  fi
fi

# Should we create a MailHog container?
printf "\nCreate a MailHog container? [N]\n"
get_yes_or_no_response "N"
if [[ "${response}" == "Y" ]]; then
  service_email="MailHog"
else
  service_email=""
fi

# Get the database service
printf "\nSelect the database:"
get_choice_response "${db_services[@]}"
service_db="${db_services[$response]}"

#@TODO: Allow the user to specify the database name

# Get database ports
if [[ "${service_db}^^" == "MYSQL" ]] || [[ "${service_db}^^" == "MARIADB" ]]; then
  db_port=3306
  db_exposed_port=6603
elif [[ "${service_db}^^" == "POSTGRES" ]]; then
  db_port=5432
  db_exposed_port=5432
fi
while [[ $(nc -w5 -z -v localhost "${db_exposed_port}" 2>&1) == *"succeeded"* ]]; do
  db_exposed_port=$((${db_exposed_port} + 1))
done

# Should we include a database admin service
if [[ "${service_db^^}" == "MYSQL" ]] || [[ "${service_db^^}" == "MARIADB" ]]; then
  service_db_admin="phpMyAdmin"
elif [[ "${service_db^^}" == "POSTGRES" ]]; then
  service_db_admin="pgAdmin"
else
  service_db_admin=""
fi
if [[ ! -z "${service_db_admin}" ]]; then
  printf "\nCreate a container for ${service_db_admin}? [Y]\n"
  get_yes_or_no_response "Y"
  if [[ "${response}" == "N" ]]; then
    service_db_admin=""
  fi
fi
if [[ ! -z "${service_db_admin}" ]]; then
  db_admin_port=$(($port + 1))
  while [[ $(nc -w5 -z -v localhost "${db_admin_port}" 2>&1) == *"succeeded"* ]]; do
    db_admin_port=$((db_admin_port + 1))
  done
fi
db_admin_url="http://localhost:${db_admin_port}"

# Get database root password
printf "\nEnter database root password.\n"
db_root_password=
while [ -z "$db_root_password" ]; do
  read db_root_password
done

# Get database username
db_username=
valid_username=false
printf "\nEnter database username.\n"
while [ "$valid_username" = false ]; do
  read db_username
  if [ -z "$db_username" ]; then
    valid_username=false
  elif [[ ! ($db_username =~ ^[A-Za-z0-9_-]+$) ]]; then
  printf "User name can only contain alphanumeric characters, underscores and dashes.\n"
    valid_username=false
  elif [[ $(expr length "$db_username") -gt 20 ]]; then
    printf "User name can be no longer than 20 characters.\n"
    valid_username=false
  else
    valid_username=true
  fi
done

# Get database user password
printf "\nEnter database user password.\n"
db_password=
while [ -z "$db_password" ]; do
  read db_password
done

# Should we run database migrations?
if [[ "${frameworks_with_db_migrations[@]}" =~ "${php_framework}" ]]; then
  printf "\nRun database migrations? [Y]\n"
  get_yes_or_no_response "Y"
  if [[ "${response}" == "Y" ]]; then
    run_db_migrations=true
  else
    run_db_migrations=false
  fi
fi

# Should we run database seeders?
if [[ "${frameworks_with_db_seeds[@]}" =~ "${php_framework}" ]]; then
  printf "\nRun database seeds? [Y]\n"
  get_yes_or_no_response "Y"
  if [[ "${response}" == "Y" ]]; then
    run_db_seeds=true
  else
    run_db_seeds=false
  fi
fi

# Should we create a phpinfo.php file
printf "\nCreate a http://localhost:${port}/phpinfo.php file? [Y]\n"
get_yes_or_no_response "Y"
if [[ "${response}" == "Y" ]]; then
  create_phpinfo_file=true
else
  create_phpinfo_file=false
fi


# ##########################################################################################
# Confirm settings before continuing.
# ##########################################################################################

display_configuration
printf "\nEnter [C] to continue or [Q] to quit.\n"
response=""
while [[ "${response^^}" != "C" ]] && [[ "${response^^}" != "Q" ]]; do
  read response
done
if [[ "${response^^}" == "Q" ]]; then
  printf "\n"
  exit
fi

# Create the project code
#create_project_code
# Create the bootstrap.sh file

# Define the docker files
define_docker_files

# Create the docker files
create_docker_files
create_server_conf_file
create_db_init_file
build_create_project_script

# Build the docker images
build_docker_images

# Run post-install process
run_post_install_processes

populate_containers_created_array

printf "\n\nBuilding project ....\n"
docker exec -t "${project_name}-app" bash create_project.sh

script_completed=true

# Display the project configuration
display_configuration

printf "\nYou can now access the following in your browser:"
printf "\n\n\tWebsite:         ${site_url}\n"
if [[ "${service_db_admin^^}" == "PHPMYADMIN" ]]; then
  printf "\tphpMyAdmin:      ${db_admin_url}"
  printf "\n\t    Server:   db-${service_db}"
  printf "\n\t    Username: ${db_username}"
  printf "\n\t    Password: ***${db_password: -3}"
elif [[ "${service_db_admin^^}" == "PGADMIN" ]]; then
  printf "\tpgAdmin:           http://localhost:${db_admin_port}"
fi
if [[ "${create_phpinfo_file}" == true ]]; then
  printf "\n\tPHP Information: ${site_url}/phpinfo.php"
fi
printf "\n"

if [[ -z "${php_framework}" ]] && [[ -z "${git_rep}" ]]; then
  printf "\nCreate your project in the ${project_name}-app container in the directory /www/var/${project_name}.\n\n"
fi

exit
