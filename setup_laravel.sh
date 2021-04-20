#!/bin/bash
printf "\nSetting up Laravel Docker Project Environment\n"

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
db_username=
while [ -z "$db_username" ]; do
  printf "\nEnter DB_USERNAME: "
  read db_username
done
db_password=
while [ -z "$db_password" ]; do
  printf "\nEnter DB_PASSWORD: "
  read db_password
done

printf "\nproject_name: $project_name"
printf "\nbase_dir:     $base_dir"
printf "\nworking_dir:  $working_dir"
printf "\nproject_dir:  $project_dir"
printf "\nport:         $port"
printf "\nDB_USERNAME:  $db_username"
printf "\nDB_PASSWORD:  $db_password"
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

# Create the Laravel project.
cd "${base_dir}"
printf "\nCreating the Laravel project ...\n"
curl -s "https://laravel.build/${project_name}" | bash

# Set database settings in .env file
printf "\nAdd database user credentials to .env file."
sed -i "s/DB_USERNAME=sail/DB_USERNAME=${db_username}/g" ${project_dir}/.env
sed -i "s/DB_PASSWORD=password/DB_PASSWORD==${db_password}/g" ${project_dir}/.env

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
cp "${working_dir}/docker-compose.yml" "${docker_compose_file}"
cp "${working_dir}/Dockerfile" "${docker_file}"

# Make changes for configuration files.
sed -i "s/{{project_name}}/${project_name}/g" ${docker_compose_file}
sed -i "s/{{port}}/${port}/g" ${docker_compose_file}

docker-compose build
docker-compose up -d
docker-compose ps
docker-compose exec app composer install

printf "\nIf you see any errors with the 'composer install' command then run a composer update with the command:"
printf "\n\tdocker-compose exec app composer update"
printf "\n\nYou should now be able to the to http://localhost:{$port} in your browser."
echo "SUCCESS"
exit
