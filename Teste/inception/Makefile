# Inception - Docker Infrastructure Project
# Author: cfelipe-

.PHONY: all up build down clean fclean re logs ps status help

# Default target
all: up

# Create data directories and start containers
up: build
	@echo "Creating data directories..."
	@mkdir -p $(HOME)/data/mariadb
	@mkdir -p $(HOME)/data/wordpress
	@echo "Starting containers..."
	@docker compose -f srcs/docker-compose.yml up -d
	@echo "Inception infrastructure is up!"
	@echo "Access WordPress at: https://cfelipe-.42.fr"

# Build Docker images
build:
	@echo "Building Docker images..."
	@docker compose -f srcs/docker-compose.yml build

# Stop containers
down:
	@echo "Stopping containers..."
	@docker compose -f srcs/docker-compose.yml down
	@echo "Containers stopped."

# Stop containers and remove images
clean: down
	@echo "Removing Docker images..."
	@docker compose -f srcs/docker-compose.yml down --rmi all
	@echo "Cleaning Docker system..."
	@docker system prune -af
	@echo "Cleanup complete."

# Full clean including volumes and data directories
fclean: clean
	@echo "Removing volumes..."
	@docker compose -f srcs/docker-compose.yml down -v
	@echo "Removing data directories..."
	@sudo rm -rf $(HOME)/data/mariadb
	@sudo rm -rf $(HOME)/data/wordpress
	@echo "Full cleanup complete."

# Rebuild everything from scratch
re: fclean all

# Show container logs
logs:
	@docker compose -f srcs/docker-compose.yml logs -f

# Show container status
ps:
	@docker compose -f srcs/docker-compose.yml ps

# Show detailed status
status:
	@echo "=== Docker Containers ==="
	@docker ps -a
	@echo "\n=== Docker Images ==="
	@docker images
	@echo "\n=== Docker Volumes ==="
	@docker volume ls
	@echo "\n=== Docker Networks ==="
	@docker network ls

# Help
help:
	@echo "Inception - Docker Infrastructure Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make         - Build and start all containers (default)"
	@echo "  make up      - Create directories and start containers"
	@echo "  make build   - Build Docker images"
	@echo "  make down    - Stop containers"
	@echo "  make clean   - Stop containers and remove images"
	@echo "  make fclean  - Full cleanup (containers, images, volumes, data)"
	@echo "  make re      - Rebuild everything from scratch"
	@echo "  make logs    - Show container logs (follow mode)"
	@echo "  make ps      - Show container status"
	@echo "  make status  - Show detailed Docker status"
	@echo "  make help    - Show this help message"
