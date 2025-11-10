#!/bin/bash
# docker-nuke.sh - remove all Docker containers, images, volumes, caches end data dir

run() {
    echo -e "> $*"
    eval "$@"
    echo -e
}

echo "Stopping all running containers..."
run "docker stop \$(docker ps -aq) 2>/dev/null"

echo "Removing all containers..."
run "docker rm -f \$(docker ps -aq) 2>/dev/null"

echo "Removing all images..."
run "docker rmi -f \$(docker images -aq) 2>/dev/null"

echo "Removing all volumes..."
run "docker volume rm -f \$(docker volume ls -q) 2>/dev/null"

echo "Pruning networks..."
run "docker network prune -f"

echo "Cleaning build cache..."
run "docker builder prune -af"

echo "Running nuclear cleanup (system prune)..."
run "docker system prune -af --volumes"

echo "Docker cleanup complete!"
