#!/bin/bash
# docker_down.sh - stop and remove Docker containers and networks

docker compose -f srcs/docker-compose.yml down
