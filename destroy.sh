#!/bin/bash

docker_env=$1

if [ -z "$docker_env" ]; then
  printf "\nYou must specify the Docker environment to destroy.\n"
  exit
fi

printf "\nAre you sure that your want to destroy Docker environment for $docker_env?"
printf "\nThis will destroy all associated Docker containers and cannot be undone."
read -p "Do you want to continue? [y/N]" reply
if [[ "${reply^^}" != "Y" ]]; then
  exit
fi

container_suffixes=("app" "nginx" "mysql" "phpmyadmin")
for suffix in "${container_suffixes[@]}";
do
  printf "\nKilling container ${docker_env}-${suffix} ...\n\t"
  docker kill "${docker_env}-${suffix}"
done

printf "\nPruning Docker images ...\n\t"
docker system prune -f

printf "\nRemoving image ${docker_env} ...\n\t"
docker image rm "${docker_env}"

printf "\nDONE"
