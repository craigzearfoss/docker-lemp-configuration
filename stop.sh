#!/bin/bash

docker_env=$1

if [ -z "$docker_env" ]; then
  printf "\nYou must specify the Docker environment to stop.\n"
  exit
fi

container_suffixes=("app" "nginx" "mysql" "mariadb" "postgres" "phpmyadmin" "pgadmin")
for suffix in "${container_suffixes[@]}";
do
  printf "\nStopping container ${docker_env}-${suffix} ...\n\t"
  docker stop "${docker_env}-${suffix}"
done

printf "\nAll containers for '${docker_env}' have been stopped.\n\t"
printf "\nIf you want to stop the mailhog container run the following command:"
printf "\n\tbash docker stop mailhog"

printf "\n\n"
