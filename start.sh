#!/bin/bash

docker_env=$1

if [ -z "$docker_env" ]; then
  printf "\nYou must specify the Docker environment to start.\n"
  exit
fi

container_suffixes=("app" "nginx" "mysql" "mariadb" "postgres" "phpmyadmin" "pgadmin")
for suffix in "${container_suffixes[@]}";
do
  printf "\nStarting container ${docker_env}-${suffix} ...\n\t"
  docker start "${docker_env}-${suffix}"
done

printf "\nAll containers for '${docker_env}' have been started.\n\t"
printf "\nIf you want to start the mailhog container run the following command:"
printf "\n\tbash docker start mailhog"

printf "\n\n"
