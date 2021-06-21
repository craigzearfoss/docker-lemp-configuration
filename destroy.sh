#!/bin/bash

docker_env=$1

if [ -z "$docker_env" ]; then
  printf "\nYou must specify the Docker environment to destroy.\n"
  exit
fi

printf "\nAre you sure that your want to destroy Docker environments for $docker_env?"
printf "\nThis will destroy all associated Docker containers and cannot be undone.\n"
read -p "Do you want to continue? [N]" reply
if [[ "${reply^^}" != "Y" ]]; then
  exit
fi


if [[ "$docker_env}" == "mailhog" ]]; then

  container_name="$docker_env"
  printf "\nKilling container ${container_name} ...\n\t"
  docker kill "${container_name}"

  printf "\nPruning Docker images ...\n\t"
  docker system prune -f

  printf "\nRemoving image ${container_name} ...\n\t"
  docker image rm "${container_name}"

  printf "\nThe MailHog container mailhog has been destroyed.\n\t"

else

  # No container name parameter passed
  container_suffixes=("app" "nginx" "mysql" "mariadb" "postgres" "phpmyadmin" "pgadmin4")
  for suffix in "${container_suffixes[@]}";
  do
    printf "\nKilling container ${docker_env}-${suffix} ...\n\t"
    docker kill "${docker_env}-${suffix}"
  done

  printf "\nPruning Docker images ...\n\t"
  docker system prune -f

  printf "\nRemoving image ${docker_env} ...\n\t"
  docker image rm "${docker_env}"

  printf "\nAll containers for '${docker_env}' have been destroyed.\n\t"
  printf "\nIf you want to destroy the mailhog container run the following command:"
  printf "\n\tbash destroy.sh mailhog"
  printf "\n\nThe directory '${docker_env}' has NOT been deleted."
fi

printf "\n\n"
