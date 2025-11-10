#!/bin/bash
# docker_status.sh

@echo " ### Docker Containers ### "
docker ps -a
@echo "\n ### Docker Images ### "
docker images
@echo "\n ### Docker Volumes ### "
docker volume ls
@echo "\n ### Docker Networks ### "
docker network ls
