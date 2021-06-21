#!/bin/bash

docker_version="3.7"
script_completed=false

working_dir="$(pwd)"
user="devuser"

service_app="app"
service_server="NGINX" # NGINX
service_db="MySQL"     # MySQL / MariaDB / Postgres
service_db_admin=""    # phpMyAdmin or pgAdmin
service_email=""       # MailHog"
php_version=""         # name of the docker file in the configurations/Dockerfiles directory
containers_created=()

create_app_service=true

node_install_required=false # some applications require that we install node
nodejs_version=""
nodejs_versions=("16.3.0" "14.17.1" "12.22.1")
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
servers=("${working_dir}"/configurations/Dockerfiles/*)
dockerfiles=("${working_dir}"/configurations/Dockerfiles/${service_server}/*)
db_name=${project_name//[\-]/_}
db_root_password=
db_username=
db_password=
db_port=3306
db_exposed_port=6603
dd_admin_port=$((${dd_admin_port} + 1))
db_host_data_dir=""
pgadmin_default_email="admin@admin.com"
pgadmin_default_password="root"

# Get a list of available databases
db_services=("MySQL" "MariaDB" "Postgres")

# Get a list of available PHP frameworks
php_frameworks=()
for entry in configurations/php-frameworks/*; do
  php_frameworks+=("${entry##*/}")
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

laravel_jetstream_install_cmd=""

empty_option_choice_is_valid=false

is_email_valid() {
  regex="^([A-Za-z]+[A-Za-z0-9]*((\.|\-|\_)?[A-Za-z]+[A-Za-z0-9]*){1,})@(([A-Za-z]+[A-Za-z0-9]*)+((\.|\-|\_)?([A-Za-z]+[A-Za-z0-9]*)+){1,})+\.([A-Za-z]{2,})+"
  [[ "${1}" =~ $regex ]]
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
    if [ -z "${response}" ]; then
      break
    fi
  done
  response=$((${response} - 1))
  empty_option_choice_is_valid=false;
}

get_yes_or_no_response() {
  local __default=$1
  valid_yes_no_responses=("Y N")
  good_reply=false
  while [ "${good_reply}" != true ]; do
    read response
    if [[ -z "${response}" ]] && [[ ! -z "${__default}" ]]; then
      response="${__default}"
    fi
    response="${response^^}"
    if [[ " ${valid_yes_no_responses[@]} " =~ " ${response} " ]]; then
      good_reply=true
    fi
  done
}

continue_confirmation() {
  printf "\nEnter [C] to continue or [Q] to quit.\n"
  response=""
  while [[ "${response^^}" != "C" ]] && [[ "${response^^}" != "Q" ]]; do
    read response
  done
  if [[ "${response^^}" == "Q" ]]; then
    printf "\n"
    exit
  fi
}

join_by() {
  local IFS="$1";
  shift;
  echo "$*";
}

replace_variables_in_file() {
  local __file_to_process=$1
  sed -i "s/{{db_admin_port}}/${db_admin_port}/g" "${__file_to_process}"
  sed -i "s/{{db_exposed_port}}/${db_exposed_port}/g" "${__file_to_process}"
  sed -i "s/{{db_name}}/${db_name}/g" "${__file_to_process}"
  sed -i "s/{{db_password}}/${db_password}/g" "${__file_to_process}"
  sed -i "s/{{db_port}}/${db_port}/g" "${__file_to_process}"
  sed -i "s/{{db_root_password}}/${db_root_password}/g" "${__file_to_process}"
  sed -i "s/{{db_username}}/${db_username}/g" "${__file_to_process}"
  sed -i "s/{{full_install}}/true/g" "${__file_to_process}"
  sed -i "s/{{git_repo}}/${git_repo//\//\\/}/g" "${__file_to_process}"
  sed -i "s/{{local_web_root}}/${local_web_root//\//\\/}/g" "${__file_to_process}"
  sed -i "s/{{nodejs_version}}/${nodejs_version}/g" "${__file_to_process}"
  sed -i "s/{{pgadmin_default_email}}/${pgadmin_default_email}/g" "${__file_to_process}"
  sed -i "s/{{pgadmin_default_password}}/${pgadmin_default_password}/g" "${__file_to_process}"
  sed -i "s/{{port}}/${port}/g" "${__file_to_process}"
  sed -i "s/{{project_name}}/${project_name}/g" "${__file_to_process}"
  sed -i "s/{{service_db}}/${service_db,,}/g" "${__file_to_process}"
  sed -i "s/{{service_db_admin}}/${service_db_admin,,}/g" "${__file_to_process}"
  sed -i "s/{{service_server}}/${service_server,,}/g" "${__file_to_process}"
  sed -i "s/{{user}}/${user}/g" "${__file_to_process}"
  sed -i "s/{{web_root}}/${web_root//\//\\/}/g" "${__file_to_process}"
}

set_project_name() {
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
}

set_container_directory() {
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
}

set_server_service() {
  service_server="NGINX"
  printf "\nSelect ${service_server} version: [2]"
  empty_option_choice_is_valid=true
  get_choice_response "${servers[@]}"
  if [ "${response}" -eq -1 ]; then
    service_server="NGINX"
  else
    service_server="${servers[$response]##*/}"
  fi
  dockerfiles=("${working_dir}"/configurations/Dockerfiles/${service_server}/*)
}

set_php_version() {
  # @TODO: let's reverse the order so newest versions are at the top
  printf "\nSelect PHP version: [3]"
  empty_option_choice_is_valid=true
  get_choice_response "${dockerfiles[@]}"
  if [ "${response}" -eq -1 ]; then
    src_dockerfile="${dockerfiles[2]}"
    php_version="${src_dockerfile##*/}"
  else
    src_dockerfile="${dockerfiles[$response]}"
    php_version="${src_dockerfile##*/}"
  fi
}

set_port() {
  port_is_in_use=true
  select_a_port_prompt="\nSelect a port [${default_port}]: "
  while [[ "${port_is_in_use}" == true ]]; do
    printf "${select_a_port_prompt}\n"
    read port
    port="${port:-${default_port}}"
    if [[ "${port}" -lt 1024 || "${port}" -gt 65535 ]]; then
      select_a_port_prompt="\nA port must be in the range 1024 to 65535. Select a different port. [${default_port}] "
    elif [[ $(nc -w5 -z -v localhost "${port}" 2>&1) == *"succeeded"* ]]; then
      select_a_port_prompt="\nPort ${port} is in use. Select a different port. [${default_port}] "
      port_is_in_use=true
    else
      port_is_in_use=false
    fi
  done
  site_url="http://localhost:${port}"
}

set_git_repo() {
  printf "\nEnter the git repository or leave blank if"
  printf "\nyou are going to create a new project.\n"
  valid_response=false
  while [[ "${valid_response}" == false ]]; do
    read response

    if [ -z "${response}" ]; then
      valid_response=true
      git_repo=""
    elif (git ls-remote "${response}" -q 2>&1); then
      valid_response=true
      git_repo="${response}"
    else
      printf "\nGit repository does not exist or it is not accessible.\n"
      valid_response=false
      git_repo=""
    fi
  done
}

set_php_framework() {
  if [[ -z "${git_repo}" ]]; then
    printf "\nSelect the PHP framework to install."
  else
    printf "\nSelect the PHP framework of the repository."
    printf "\nThis used to automatically configure the project environment settings."
    printf "\nIf you do not know the framework or do not want it configured then select '(none)'."
  fi
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
    if [[ -z "${response}" ]]; then
      valid_response=false
      selected_index=""
      php_framework=""
    elif [[ "$response" -eq 1 ]]; then
      valid_response=true
      selected_index=$((${response}))
      php_framework=""
    elif [[ "$response" -gt 1 && "${response}" -le "${#options[@]}" ]]; then
      valid_response=true
      selected_index=$((${response} - 2))
      php_framework="${php_frameworks[$selected_index]}"
    else
      printf "\nSelect a valid number.\n"
      valid_response=false
      selected_index=""
      php_framework=""
    fi
  done
  if [[ "${php_framework^^}" == "CAKEPHP" ]]; then
    local_web_root="/var/www/site/webroot"
    web_root="${site_dir}/webroot"
  elif [[ "${php_framework^^}" == "WORDPRESS" ]]; then
    site_dir="${container_dir}/wordpress"
    local_web_root="/var/www/wordpress"
    web_root="${site_dir}"
  elif [[ "${php_framework^^}" == "YII2" ]]; then
    local_web_root="/var/www/site/web"
    web_root="${site_dir}/web"
  fi
}

set_laravel_jetstream() {
  # Note: Only install Laravel Jetstream on new projects
  if [[ -z "${git_repo}" ]]; then
    printf "\nLaravel Jetstream provides login, registration, email verification, two-factor authentication,"
    printf "\nsession management, API via Laravel Sanctum, and optional team management features."
    printf "\nInstall Laravel Jetstream? [N]\n"
    get_yes_or_no_response "N"
    if [[ "${response}" == "Y" ]]; then
      options=("php artisan jetstream:install livewire" "php artisan jetstream:install livewire --teams" "php artisan jetstream:install inertia" "php artisan jetstream:install inertia --teams" "Cancel (Don't install Jetstream.)")
      printf "\nSelect which flavor of Jetstream to install: "
      printf "\nNote that Livewire uses Blade templating and Inertia uses Vue.js."
      empty_option_choice_is_valid=false
      get_choice_response "${options[@]}"
      if [ "${response}" -ne 5 ]; then
        laravel_jetstream_install_cmd="${options[$response]}"
        node_install_required=true
      fi
    fi
  fi
}

is_this_a_full_install() {
  if [[ ! -z "${php_framework}" ]] && [[ "${frameworks_with_partial_installs[@]}" =~ "${php_framework}" ]]; then
    printf "\nIs this a full install? [Y]"
    get_yes_or_no_response "Y"
    if [[ "${response}" == "Y" ]]; then
      full_install=true
    else
      full_response=false
    fi
  fi
}

set_mailhog_service() {
  printf "\nCreate a MailHog container? [N]\n"
  get_yes_or_no_response "N"
  if [[ "${response}" == "Y" ]]; then
    service_email="MailHog"
  else
    service_email=""
  fi
}

set_database_name() {
  printf "\nEnter the database name: [${db_name}]\n"
  valid_response=false
  while [[ "${valid_response}" == false ]]; do
    read response
    if [ -z "${response}" ]; then
      valid_response=true
    elif [[ "${response}" =~ ^[A-Za-z0-9_-]+$ ]]; then
      valid_response=true
      db_name="${response}"
    else
      valid_response=false
      printf "\nDatabase name can only contain letters, numbers and underscores.\n"
    fi
  done
}

set_database_service() {
  printf "\nSelect the database: [1]"
  empty_option_choice_is_valid=true
  get_choice_response "${db_services[@]}"
  if [ "${response}" -eq -1 ]; then
    service_db="MySQL"
  else
    service_db="${db_services[$response]}"
  fi

  set_database_name

  # Get database ports
  if [[ "${service_db^^}" == "MYSQL" ]] || [[ "${service_db^^}" == "MARIADB" ]]; then
    db_port=3306
    db_exposed_port=6603
  elif [[ "${service_db^^}" == "POSTGRES" ]]; then
    db_port=5432
    db_exposed_port=5432
  fi
  while [[ $(nc -w5 -z -v localhost "${db_exposed_port}" 2>&1) == *"succeeded"* ]]; do
    db_exposed_port=$((${db_exposed_port} + 1))
  done
}

set_database_admin_service() {
  if [[ "${service_db^^}" == "MYSQL" ]] || [[ "${service_db^^}" == "MARIADB" ]]; then
    service_db_admin="phpMyAdmin"
  elif [[ "${service_db^^}" == "POSTGRES" ]]; then
    service_db_admin="pgAdmin"
  else
    service_db_admin=""
  fi
  if [[ ! -z "${service_db_admin}" ]]; then
    printf "\nCreate a ${service_db_admin} container? [Y]\n"
    get_yes_or_no_response "Y"
    if [[ "${response}" == "N" ]]; then
      service_db_admin=""
    elif [[ "${service_db_admin^^}" == "PGADMIN" ]]; then

      # Get pgAdmin default email
      printf "\nEnter the email address used to log into pgAdmin: [${pgadmin_default_email}]\n"
      valid_email=false
      while [[ "${valid_email}" == false ]]; do
        read entered_email
        if [[ -z "${entered_email}" ]]; then
          valid_email=true
        else
          if is_email_valid "${entered_email}"; then
            pgadmin_default_email="${entered_email}"
            valid_email=true
          else
            printf "\nInvalid email address.\n"
            valid_email=false
          fi
        fi
      done

      # Get pgAdmin default password
      printf "\nEnter database root password: [${pgadmin_default_password}]\n"
      pgadmin_default_password=
      while [ -z "${valid_password}" ]; do
        read entered_password
        if [[ -z "${entered_password}" ]]; then
          valid_password=true
        else
          valid_password=true
          pgadmin_default_password="${entered_password}"
        fi
      done

    fi
  fi
  if [[ ! -z "${service_db_admin}" ]]; then
    db_admin_port=$(($port + 1))
    while [[ $(nc -w5 -z -v localhost "${db_admin_port}" 2>&1) == *"succeeded"* ]]; do
      db_admin_port=$((db_admin_port + 1))
    done
  fi
  db_admin_url="http://localhost:${db_admin_port}"
}

set_nodejs_version() {
  if [[ "${node_install_required}" == true ]]; then
    nodejs_version=${nodejs_versions[0]}
  else
    printf "\nInstall Node.js? [Y]\n"
    get_yes_or_no_response "Y"
    if [[ "${response}" == "Y" ]]; then
      printf "\nSelect the Node.js version. [1]"
      i=1
      for version in "${nodejs_versions[@]}"; do
        printf "\n\t${i} - ${version##*/}"
        i=$((${i} + 1))
      done
      printf "\n"
      valid_response=false
      while [[ "${valid_response}" == false ]]; do
        read response
        re='^[0-9]+$'
        if [[ -z "${response}" ]]; then
          valid_response=true
          nodejs_version="${nodejs_versions[0]}"
        else
          res="${response//[^\.]}"
          dot_count="${#res}"
          if [[ "$dot_count" -eq 0 ]]; then
            if [[ "${response}" -gt 0 && "${response}" -le "${#nodejs_versions[@]}" ]]; then
              valid_response=true
              selected_index=$((${response} - 1))
              nodejs_version="${nodejs_versions[$selected_index]}"
            else
              valid_response=false
              printf "\nInvalid selection or Node.js version.\n"
            fi
          else
            if [ "${#res}" -eq 2 ]; then
              valid_response=true
              nodejs_version="${response}"
            else
              valid_response=false
              printf "\nInvalid Node.js version.\n"
            fi
          fi
        fi
      done
    else
      nodejs_version=""
    fi
  fi
}

configure_database() {
  # Get database root password
  printf "\nEnter database root password.\n"
  db_root_password=
  while [ -z "${db_root_password}" ]; do
    read db_root_password
  done

  # Get database username
  db_username=
  valid_username=false
  printf "\nEnter database username.\n"
  while [ "${valid_username}" = false ]; do
    read db_username
    if [ -z "${db_username}" ]; then
      valid_username=false
    elif [[ ! ("${db_username}" =~ ^[A-Za-z0-9_-]+$) ]]; then
    printf "User name can only contain alphanumeric characters, underscores and dashes.\n"
      valid_username=false
    elif [[ $(expr length "${db_username}") -gt 20 ]]; then
      printf "User name can be no longer than 20 characters.\n"
      valid_username=false
    else
      valid_username=true
    fi
  done

  # Get database user password
  printf "\nEnter database user password.\n"
  db_password=
  while [ -z "${db_password}" ]; do
    read db_password
  done

  printf "\nDo you want to use a directory on the host machine to store"
  printf "\ndata so it will be persisted if the container is destroyed? [N]\n"
  get_yes_or_no_response "N"
  if [[ "${response}" == "Y" ]]; then
    printf "\nEnter the full path the the storage directory:\n"
    while [[ -z "${db_host_data_dir}" ]]; do
      read db_host_data_dir
      if [ ! -d "${db_host_data_dir}" ]; then
        printf "\nThe directory ${db_host_data_dir} does not exist so it will be created.\n"
      fi
    done
  fi
}

run_database_migrations() {
  if [[ "${frameworks_with_db_migrations[@]}" =~ "${php_framework}" ]]; then
    printf "\nRun database migrations? [N]\n"
    get_yes_or_no_response "N"
    if [[ "${response}" == "Y" ]]; then
      run_db_migrations=true
    else
      run_db_migrations=false
    fi
  fi
}

run_database_seeds() {
  if [[ "${frameworks_with_db_seeds[@]}" =~ "${php_framework}" ]]; then
    printf "\nRun database seeds? [N]\n"
    get_yes_or_no_response "N"
    if [[ "${response}" == "Y" ]]; then
      run_db_seeds=true
    else
      run_db_seeds=false
    fi
  fi
}

set_phpinfo_file() {
  printf "\nCreate a http://localhost:${port}/phpinfo.php file? [Y]\n"
  get_yes_or_no_response "Y"
  if [[ "${response}" == "Y" ]]; then
    create_phpinfo_file=true
  else
    create_phpinfo_file=false
  fi
}

define_docker_files() {
  # ##########################################################################################
  # Define docker files.
  # ##########################################################################################

  dockerfile="${container_dir}/Dockerfile"
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

add_nodejs_to_dockerfile() {
  if [[ ! -z "${nodejs_version}" ]]; then
    nodejs_run_code_file="${container_dir}/configurations/Dockerfile-sections/nodejs"
    sed -i -e "/# SECTION:nodejs/{r ${nodejs_run_code_file}" -e 'd}' ${dockerfile}
  fi
}

create_docker_files() {
  # ##########################################################################################
  # Create the docker containers.
  # ##########################################################################################

  # Copy Dockerfile
  printf "\nCopying configurations ..."
  mkdir -p "${container_dir}"
  cp -pr "${working_dir}/configurations/" "${container_dir}/configurations"

  printf "\nCopying Dockerfile ..."
  cp "${src_dockerfile}" "${dockerfile}"
  printf "\nUpdating Dockerfile ..."
  add_nodejs_to_dockerfile
  replace_variables_in_file "${dockerfile}"

  # Create docker-compose.yml file
  printf "\nCreating docker-compose.yml ..."
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
    cat "${working_dir}/configurations/docker-compose-sections/service-${db_email,,}" >> "${docker_compose_file}"
  fi;

  if [[ ! -z "${service_server}" ]]; then
    cat "${working_dir}/configurations/docker-compose-sections/service-${service_server,,}" >> "${docker_compose_file}"
  fi

  cat "${working_dir}/configurations/docker-compose-sections/networks" >> "${docker_compose_file}"
  cat "${working_dir}/configurations/docker-compose-sections/volumes" >> "${docker_compose_file}"

  # Make modifications to docker-compose.yml file.
  printf "\nUpdating docker-compose.yml ..."
  replace_variables_in_file "${docker_compose_file}"

  # Are we storing database data in a directory on the host machine?
  if [[ ! -z "${db_host_data_dir}" ]]; then
    echo "\nSetting ${service_db,,} data directory to ${db_host_data_dir} on host machine ..."
    if [[ "${service_db^^}" == "MYSQL" ]] || [[ "${service_db^^}" == "MARIADB" ]]; then
      sed -i "s/# - \.\/data\/db:.*/- ${db_host_data_dir//\//\\/}:\/var\/lib\/${service_db,,}/" "${docker_compose_file}"
    elif [[ "${service_db^^}" == "POSTGRES" ]]; then
      sed -i "s/# - \.\/data\/db:.*/- ${db_host_data_dir//\//\\/}:\/var\/lib\/postgresql/data/" "${docker_compose_file}"
    fi
  fi
}

create_server_conf_file() {
  #server configuration
  printf "\nCopying conf-files/${server_conf_file##*/} ..."

  # copy server configuration file
  export DIR=${server_conf_file%/*}
  mkdir -p "${DIR}"
  if [ -f "${container_dir}/configurations/server-files/${service_server,,}/${php_framework,,}.conf" ]; then
    cp -p "${container_dir}/configurations/server-files/${service_server,,}/${php_framework,,}.conf" "${server_conf_file}"
  else
    cp -p "${container_dir}/configurations/server-files/${service_server,,}/default.conf" "${server_conf_file}"
  fi

  # Make modifications to the server configuration file.
  printf "\nUpdating conf-files/${server_conf_file##*/} ..."
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
  # For MySQL and MariaDB
  printf "\nAdding database credentials ..."
  export DB_DATABASE="${db_name}"
  export DB_ROOT_PASSWORD="${db_root_password}"
  export DB_USERNAME="${db_username}"
  export DB_PASSWORD="${db_password}"

  # For Postgres
  export POSTGRES_DB="${db_name}"
  export POSTGRES_USER="admin"
  export POSTGRES_PASSWORD="${db_root_password}"
  export APP_DB_NAME="${db_name}"
  export APP_DB_USER="${db_username}"
  export APP_DB_PASS="${db_username}"

  # copy db entrypoint file
  printf "\nCopying init-files/${init_db_file##*/} ..."
  export DIR=${init_db_file%/*}
  mkdir -p "${DIR}"
  cp "${container_dir}/configurations/db-files/${service_db,,}/${init_db_file##*/}" "${init_db_file}"

  # Add superuser create to init.sql file
  ## @TODO: Need to implement for Postgres
  printf "\nUpdating init-files/${init_db_file##*/} ..."
  if [[ "${service_db^^}" == "MYSQL" ]] || [[ "${service_db^^}" == "MARIADB" ]]; then
    echo "" >> ${init_db_file}
    echo "/*" >> ${init_db_file}
    echo " Create administrator user" >> "${init_db_file}"
    echo "*/" >> "${init_db_file}"
    echo "CREATE DATABASE FLUSH ${db_name};" >> "${init_db_file}"
    echo "CREATE USER \"${db_username}'@'localhost' IDENTIFIED BY \"${db_password}\";" >> "${init_db_file}"
    echo "GRANT ALL PRIVILEGES ON *.* TO '${db_username}'@'localhost' WITH GRANT OPTION;" >> "${init_db_file}"
    echo "CREATE USER '${db_username}'@'%' IDENTIFIED BY \"${db_password}\";" >> "${init_db_file}"
    echo "GRANT ALL PRIVILEGES ON *.* TO '${db_username}'@'%' WITH GRANT OPTION;" >> "${init_db_file}"
    echo "FLUSH PRIVILEGES;" >> "${init_db_file}"
  elif [[ "${service_db^^}" == "POSTGRES" ]]; then
    echo "create database ${db_name};" >> ${init_db_file}
    echo "create user ${db_username} with encrypted password '${db_password}';" >> "${init_db_file}"
    echo "grant all privileges on database ${db_name} to ${db_username};" >> "${init_db_file}"
  fi
}

initialize_cakephp_project() {
  printf ""
}

initialize_codeigniter_project() {
  cat "${working_dir}/configurations/php-frameworks/CodeIgniter/initialize_env.sh" >> "${create_project_script}"
  #if [[ $run_db_migrations == true ]]; then
  #  cat "${working_dir}/configurations/php-frameworks/CodeIgniter/migrate.sh" >> "${create_project_script}"
  #fi
  #if [[ $run_db_seeds == true ]]; then
  #  cat "${working_dir}/configurations/php-frameworks/CodeIgniter/seed.sh" >> "${create_project_script}"
  #fi
}

initialize_fuelphp_project() {
  printf ""
}

initialize_laminas_project() {
  printf ""
}

initialize_laravel_project() {
  cat "${working_dir}/configurations/php-frameworks/Laravel/initialize_env.sh" >> "${create_project_script}"

  if [[ ! -z "${laravel_jetstream_install_cmd}" ]]; then
    printf "\n# Install Laravel Jetstream\n" >> "${create_project_script}"
    echo "cd /var/www/site" >> "${create_project_script}"
    echo "composer require laravel/jetstream" >> "${create_project_script}"
    echo "${laravel_jetstream_install_cmd}" >> "${create_project_script}"
    echo "npm install" >> "${create_project_script}"
    echo "npm run dev" >> "${create_project_script}"
    run_db_migrations=true  # Always run database migrations when installing Jetstream
  fi

  if [[ $run_db_migrations == true ]]; then
    cat "${working_dir}/configurations/php-frameworks/Laravel/migrate.sh" >> "${create_project_script}"
  fi
  if [[ $run_db_seeds == true ]]; then
    cat "${working_dir}/configurations/php-frameworks/Laravel/seed.sh" >> "${create_project_script}"
  fi

  substring="livewire"
  if grep -q "livewire" <<< "laravel_jetstream_install_cmd"; then
    echo "" >> "${create_project_script}"
    echo "# Publish the Livewire stack's Blade components" >>  "${create_project_script}"
    echo "cd /var/www/site" >> "${create_project_script}"
    echo "php artisan vendor:publish --tag=jetstream-views" >> "${create_project_script}"
    echo "npm run dev" >> "${create_project_script}"
  fi
}

initialize_lumen_project() {
  printf ""
}

initialize_phalcon_project() {
  printf ""
}

initialize_slim_project() {
  printf ""
}

initialize_symfony_project() {
  printf ""
}

initialize_wordpress_project() {
  printf ""
}

initialize_yii2_project() {
  printf ""
}

build_create_project_script() {

  # ##########################################################################################
  # Create an entrypoint bash script to create a new PHP project, get a project from a git
  # repository or make an empty project.
  # ##########################################################################################
  create_project_script="${container_dir}/create_project.sh"

  printf "\nCreating create_project.sh ...\n"
  export DIR=${create_project_script%/*}
  if [ ! -d "${DIR}" ] ; then
    mkdir -p "${DIR}"
  fi

  echo '#!/bin/bash' > "${create_project_script}"
  #echo 'set -o errexit' > "${create_project_script}"

  if [[ -z "${git_repo}" ]] && [[ -z "{$php_framework}" ]]; then
    # No PHP framework or git repository specified so just create a <webroot>/index.php file
    cat "${working_dir}/configurations/scripts/create_web_root_index_file.sh" >> "${create_project_script}"
  else
    if [[ ! -z "${git_repo}" ]]; then
      # Install project from a git repository
      cat "${working_dir}/configurations/scripts/git-clone_repo.sh" >> "${create_project_script}"
    else
      framework_install_script="${working_dir}/configurations/php-frameworks/${php_framework}/install.sh"
      if [[ ! -f "${framework_install_script}" ]]; then
        printf "\n-------------------------------------------------------------------"
        printf "\nPHP frame install file  ${framework_install_script} does not exist."
        printf "\n-------------------------------------------------------------------"
      else
        # Install a new PHP project for the specified framework
        cat "${framework_install_script}" >> "${create_project_script}"
      fi
    fi
  fi

  # Add project initialization code to the script
  if [[ "${php_framework^^}" == "CAKEPHP" ]]; then
    initialize_cakephp_project
  elif [[ "${php_framework^^}" == "CODEIGNITER" ]]; then
    initialize_codeigniter_project
  elif [[ "${php_framework^^}" == "FUELPHP" ]]; then
    initialize_fuelphp_project
  elif [[ "${php_framework^^}" == "LAMINAS" ]]; then
    initialize_laminas_project
  elif [[ "${php_framework^^}" == "LARAVEL" ]]; then
    initialize_laravel_project
  elif [[ "${php_framework^^}" == "LUMEN" ]]; then
    initialize_lumen_project
  elif [[ "${php_framework^^}" == "PHALCON" ]]; then
    initialize_phalcon_project
  elif [[ "${php_framework^^}" == "SLIM" ]]; then
    initialize_slim_project
  elif [[ "${php_framework^^}" == "SYMFONY" ]]; then
    initialize_symfony_project
  elif [[ "${php_framework^^}" == "WORDPRESS" ]]; then
    initialize_wordpress_project
  elif [[ "${php_framework^^}" == "YII2" ]]; then
    initialize_yii2_project
  fi

  if [[ "${create_phpinfo_file}" == true ]]; then
    # Create phpinfo.php file
    cat "${working_dir}/configurations/scripts/create_phpinfo_file.sh" >> "${create_project_script}"
  fi

  # Add development-only files to .gitignore file
  cat "${working_dir}/configurations/scripts/git-add_dev_only_files_to_gitignore.sh" >> "${create_project_script}"

  # Make modifications to create_project.sh bash script.
  chmod +x "${create_project_script}"
  sed -i "s/#!\/bin\/bash.*//g" "${create_project_script}"
  sed -i '1s/^/#!\/bin\/bash\n/' "${create_project_script}"
  replace_variables_in_file "${create_project_script}"
}

prompt_to_build_images() {
  printf "\nThe Docker configuration files have been built."
  printf "\nEnter [Q] to quit or [C] to build and launch the Docker images.\n"
  response=""
  while [[ "${response^^}" != "C" ]] && [[ "${response^^}" != "Q" ]]; do
    read response
  done
  if [[ "${response^^}" == "Q" ]]; then
    printf "\n\nTo create the Docker images manually:"
    printf "\n\tcd ${container_dir}"
    printf "\n\tdocker-compose build"
    printf "\n\tdocker-compose up -d"
    printf "\n\tdocker-compose ps"
    printf "\n\nThen to create the project run the create_project script: "
    printf "\n\tdocker exec -t ${project_name}-app bash create_project.sh --user=www-data\n"
    exit
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

run_post_install_processes(){
  # ##########################################################################################
  # Run post install processes.
  # ##########################################################################################
  printf "\n\nRunning post-install process ... "
}

run_create_project_script() {
  printf "\n\nBuilding project ...."
  printf "\n\tdocker exec -t ${project_name}-app bash create_project.sh --user=${user}\n"
  docker exec -t "${project_name}-app" bash create_project.sh "--user=${user}"
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
  elif [[ "${service_db_admin^^}" == "PGMYADMIN4" ]]; then
    printf "\npgAdmin URL :             ${db_admin_url}"
  fi
  if [[ "${create_phpinfo_file}" == true ]]; then
    printf "\nPHP Information:          ${site_url}/phpinfo.php"
  fi
  printf "\nDocker version:           ${docker_version}"
  printf "\nWorking directory:        ${working_dir}"
  printf "\nContainer base dir:       ${container_base_dir}"
  printf "\nContainer directory:      ${container_dir}"
  printf "\nSite directory:           ${site_dir}"
  printf "\nWeb root:                 ${web_root}"
  printf "\nGit repository:           ${git_repo}"
  printf "\nPort:                     ${port}"
  printf "\nServer:                   ${service_server}"
  printf "\nPHP version:              ${php_version}"
  printf "\nPHP framework:            ${php_framework}"
  if [[ "${php_framework^^}" == "SYMFONY" ]] && [[ "${full_install}" == false ]]; then
    printf " (Partial install)"
  fi
  if [ ! -z "${nodejs_version}" ]; then
    printf "\nNode.js version:          ${nodejs_version}"
  else
    printf "\nNode.js version:          [not installed]"
  fi
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
      printf "\n    Run db seeds:         N"
    fi
  fi
  if [[ "${service_db_admin^^}" == "PGADMIN" ]]; then
    printf "\npgAdmin:"
    printf "\n    Default email:       ${pgadmin_default_email}"
    printf "\n    Default password     ***${pgadmin_default_password: -3}"
  fi
  printf "\n-----------------------------------------------------------\n"
}

# ##########################################################################################
# Prompt user for all settings.
# ##########################################################################################

printf "\nCreating a Docker PHP development environment\n"

# Set the project name
set_project_name

# Set the container directory
set_container_directory

# Set the server (NGINX / Apache)
set_server_service

# Set the PHP version
set_php_version

# Set the port
set_port

# Set the git repository or to empty
set_git_repo

# Set PHP framework or empty
set_php_framework

if [[ "${php_framework^^}" == "LARAVEL" ]]; then
  set_laravel_jetstream
fi

# Is this a full install?
is_this_a_full_install

# Should we install node.js?
set_nodejs_version

# Should we create a MailHog service?
set_mailhog_service

# Get the database service
set_database_service

# Configure database
configure_database

# Should we run database migrations and seeds?
run_database_migrations
run_database_seeds

# Should we create a database admin service?
set_database_admin_service

# Should we create a phpinfo.php file?
set_phpinfo_file

# Confirm settings before continuing
display_configuration
continue_confirmation

# Define the docker files
define_docker_files

# Create the docker files
create_docker_files
create_server_conf_file
create_db_init_file
build_create_project_script

# Allow the user to exit before building the images
prompt_to_build_images

# Build the docker images
build_docker_images

# Run post-install process
run_post_install_processes

# Create an array of all of the containers that have been created
populate_containers_created_array

# Build the PHP project
run_create_project_script

script_completed=true

# Display the project configuration
display_configuration

printf "\nYou can now access the following in your browser:\n"
printf "\n\tWebsite:           ${site_url}\n"
if [[ "${php_framework^^}" == "WORDPRESS" ]]; then
  printf "\n\t    Database name: ${project_name}"
  printf "\n\t    Username:      ${db_username}"
  printf "\n\t    Password:      ***${db_password: -3}"
  printf "\n\t    Database host: db-${service_db,,}\n"
fi
if [[ "${service_db_admin^^}" == "PHPMYADMIN" ]]; then
  printf "\n\tphpMyAdmin:        ${db_admin_url}"
  printf "\n\t    Server:        db-${service_db,,}"
  printf "\n\t    Root password: ${db_root_password: -3}"
  printf "\n\t    Username:      ${db_username}"
  printf "\n\t    Password:      ***${db_password: -3}\n"
elif [[ "${service_db_admin^^}" == "PGADMIN" ]]; then
  printf "\n\tpgAdmin:           http://localhost:${db_admin_port}"
  printf "\n\t    Default email: ${pgadmin_default_email}"
  printf "\n\t    Default pw:    ***${pgadmin_default_password: -3}\n"
fi
if [[ "${create_phpinfo_file}" == true ]]; then
  printf "\n\tPHP Information:   ${site_url}/phpinfo.php\n"
fi

printf "\nTo access the Docker container:"
printf "\n\tdocker exec -it ${project_name}-app bash\n"

printf "\nTo destroy all Docker containers that were created:"
printf "\n\tbash destroy.sh ${project_name}\n"

if [[ -z "${php_framework}" ]] && [[ -z "${git_rep}" ]]; then
  printf "\nCreate your project in the ${project_name}-app container in the directory /www/var/${project_name}.\n\n"
fi

exit
