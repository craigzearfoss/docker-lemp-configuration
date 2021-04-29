#!/bin/bash
printf "\nSetting up Laravel Docker Project Environment\n"

docker_compose_yml_version="nginx-mysql"
dockerfile_filename="php-7-4-fpm"

working_dir="$(pwd)"
base_dir=$(echo $working_dir | sed "s|\(.*\)/.*|\1|")
working_dir="$working_dir"

# Get the project name.
printf "\nEnter project name: "
read project_name
if [ -z "$project_name" ]; then
  printf "\nYou need to enter a project name."
  printf "\nA directory will be created with that name.\n"
  exit
fi

# Get the git repo.
printf "\nEnter the git repo or hit [Enter] to create a new Laravel project. "
read git_repo

# Get the project directory.
printf "\nEnter the directory where the project will be created."
printf "\nHit [Enter] to use the directory ${base_dir}/${project_name}.\n"
read custom_base_dir
if [ -z "$custom_base_dir" ]; then
  project_dir="${base_dir}/${project_name}"
else
  if [ "${custom_base_dir: -1}" != "/" ]; then
    custom_base_dir="${custom_base_dir}"
  fi
  project_dir="${custom_base_dir}/${project_name}"
fi

# Get database user credentials.
while [ -z "$port" ]; do
  printf "\nHit [Enter] to use port 8000 or enter the port that you want to use: "
  read port
  if [ -z "$port" ]; then
    port=8000
  fi
done

# Get database user credentials.
mysql_root_password=
while [ -z "$mysql_root_password" ]; do
  printf "\nEnter MYSQL_ROOT_PASSWORD: "
  read mysql_root_password
done
mysql_user_name=
while [ -z "$mysql_user_name" ]; do
  printf "\nEnter MYSQL_USER: "
  read mysql_user_name
done
mysql_user_password=
while [ -z "$mysql_user_password" ]; do
  printf "\nEnter MYSQL_PASSWORD: "
  read mysql_user_password
done

printf "\nproject_name: $project_name"
printf "\ngit_repo:     $git_repo"
printf "\nbase_dir:     $base_dir"
printf "\nworking_dir:  $working_dir"
printf "\nproject_dir:  $project_dir"
printf "\nport:         $port"
printf "\nMYSQL_ROOT_PASSWORD: $mysql_root_password"
printf "\nMYSQL_USER:          $mysql_user_name"
printf "\nMYSQL_USER_PASSWORD: $mysql_user_password"
printf "\n"

if [ -d $project_dir ]; then
  printf "The directory $project_name already exists.\n"
  exit
fi

# Make sure the base directory exists.
if [ -z "$base_dir" ]; then
  printf "Base directory $base_dir does not exist.  Please create it and rerun this script."
  exit
fi

printf "\nHit [Enter] to continue or Ctrl-C to quit."
read reply

# Create the Laravel project.
cd "${base_dir}"
if [ -z "$git_repo" ]; then
  printf "\nCreating the Laravel project ...\n"
  curl -s "https://laravel.build/${project_name}" | bash

  # Set database settings in .env file
  printf "\nAdding database user credentials to .env file ..."
  db_name=$project_name
  sed -i "s/DB_USERNAME=sail/DB_USERNAME=${mysql_user_name}/g" ${project_dir}/.env
  sed -i "s/DB_PASSWORD=password/DB_PASSWORD==${mysql_user_password}/g" ${project_dir}/.env
else
  printf "\nDownloading git repo ${git_repo} ...\n"
  git clone $git_repo $project_name
  cp "${project_dir}/.env.example" "${project_dir}/.env"

  # Set database settings in .env file
  printf "\nAdding database user credentials to .env file ..."
  db_name=$(grep DB_DATABASE ${project_dir}/.env | cut -d '=' -f2)
  if [ -z "${db_name}"]; then
    db_name=$project_name
    sed -i "/^\DB_DATABASE=.*/ s//DB_D
    ATABASE=${db_name}/" ${project_dir}/.env
  fi
  sed -i "/^\DB_HOST=.*/ s//DB_HOST=mysql/" ${project_dir}/.env
  sed -i "/^\DB_USERNAME=.*/ s//DB_USERNAME=${mysql_user_name}/" ${project_dir}/.env
  sed -i "/^\DB_PASSWORD=.*/ s//DB_PASSWORD=${mysql_user_password}/" ${project_dir}/.env
fi


# Copy configuration files.
nginx_conf_file="${project_dir}/docker-compose/nginx/${project_name}.conf"
mysql_init_file="${project_dir}/docker-compose/mysql/init_db.sql"
docker_compose_file="${project_dir}/docker-compose.yml"
docker_file="${project_dir}/Dockerfile"

cd "${project_dir}"
mkdir "${project_dir}/docker-compose/"
mkdir "${project_dir}/docker-compose/mysql/"
mkdir "${project_dir}/docker-compose/nginx/"

cp "${working_dir}/docker-compose/nginx/project_name.conf" "${nginx_conf_file}"
cp "${working_dir}/docker-compose/mysql/init_db.sql" "${mysql_init_file}"
cp "${working_dir}/configurations/docker-compose-files/${docker_compose_yml_version}/docker-compose.yml" "${docker_compose_file}"
cp "${working_dir}/configurations/Dockerfiles/${dockerfile_filename}" "${docker_file}"

# Making changes to docker-compose.yml file
printf "\nMaking changes to docker-compose.yml file ..."
sed -i "s/{{project_name}}/${project_name}/g" ${docker_compose_file}
sed -i "s/{{port}}/${port}/g" ${docker_compose_file}

# Add superuser create to init_db.sql file
echo "CREATE USER '${mysql_user_name}'@'localhost' IDENTIFIED BY \"${mysql_user_password}\";" >> ${mysql_init_file}
echo "GRANT ALL PRIVILEGES ON *.* TO '${mysql_user_name}'@'localhost' WITH GRANT OPTION;" >> ${mysql_init_file}
echo "CREATE USER '${mysql_user_name}'@'%' IDENTIFIED BY \"${mysql_user_password}\";" >> ${mysql_init_file}
echo "GRANT ALL PRIVILEGES ON *.* TO '${mysql_user_name}'@'%' WITH GRANT OPTION;" >> ${mysql_init_file}
echo "FLUSH PRIVILEGES;" >> ${mysql_init_file}

docker-compose build
docker-compose up -d
docker-compose ps
docker-compose exec app composer install

printf "\nIf you see any errors with the 'composer install' command then run a composer update with the command:"
printf "\n\tdocker-compose exec app composer update"
printf "\n\nYou should now be able to the to http://localhost:${port} in your browser."
echo "SUCCESS"
exit
