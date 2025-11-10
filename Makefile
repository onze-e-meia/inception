# Inception

# Config.
COMPOSE_FILE	= srcs/docker-compose.yml
DATA_DIR		= $(HOME)/data
SECRETS_DIR		= srcs/secrets
NGINX_CONF		= srcs/services/nginx/conf
DOMAIN_NAME		= tforster.42.fr

# Secret files
SECRET_FILES	= $(SECRETS_DIR)/mysql_pass.txt \
				  $(SECRETS_DIR)/mysql_root_pass.txt \
				  $(SECRETS_DIR)/wp_admin_pass.txt \
				  $(SECRETS_DIR)/wp_user_pass.txt

# SSL certificate
SSL_CERT		= $(NGINX_CONF)/nginx.crt
SSL_KEY			= $(NGINX_CONF)/nginx.key

# Colors for output
RED				= \033[0;31m
YELLOW			= \033[0;33m
GREEN			= \033[0;32m
BLUE			= \033[0;34m
NC				= \033[0m # No Color

all: up

# Check DATA_PATH directories
check:
	@echo "$(BLUE)Checking environment:$(NC)"
	@test -n "$(HOME)" || (echo "$(RED)ERROR: HOME is not set$(NC)" && exit 1)
	@echo "$(GREEN)HOME is set to: $(HOME)$(NC)"

# Check and create secrets
check-secrets:
	@echo "$(BLUE)Checking secret files:$(NC)"
	@mkdir -p $(SECRETS_DIR)
	@for secret in $(SECRET_FILES); do \
		if [ ! -f $$secret ]; then \
			echo "$(YELLOW)Creating missing secret file: $$secret$(NC)"; \
			openssl rand -base64 16 > $$secret; \
			chmod 600 $$secret; \
			echo "$(RED)WARNING: Generated random password in $$secret$(NC)"; \
			echo "$(RED)         Please review and update if needed!$(NC)"; \
		else \
			echo "$(GREEN)Found: $$secret$(NC)"; \
		fi \
	done

# Check SSL certificates
check-ssl:
	@echo "$(BLUE)Checking SSL certificates:$(NC)"
	@mkdir -p $(NGINX_CONF)
	@if [ ! -f $(SSL_CERT) ] || [ ! -f $(SSL_KEY) ]; then \
		echo "$(YELLOW)SSL certificates not found, generating:$(NC)"; \
		openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
			-keyout $(SSL_KEY) \
			-out $(SSL_CERT) \
			-subj "/C=BR/ST=Sao-Paulo/L=Sao-Paulo/O=42SP/OU=Student/CN=$(DOMAIN_NAME)"; \
		chmod 644 $(SSL_CERT); \
		chmod 600 $(SSL_KEY); \
		echo "$(GREEN)Generated self-signed SSL certificate for $(DOMAIN_NAME)$(NC)"; \
		echo "$(YELLOW)    Note: Browsers will show security warning!$(NC)"; \
	else \
		echo "$(GREEN)SSL certificate exists: $(SSL_CERT)$(NC)"; \
		echo "$(GREEN)SSL key exists: $(SSL_KEY)$(NC)"; \
	fi

# Create data directories
setup: check check-secrets check-ssl
	@echo "$(BLUE)Creating data directories:$(NC)"
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	@echo "$(GREEN)Data directories ready at: $(DATA_DIR)$(NC)"

# Build Docker images
build: setup
	@echo "$(BLUE)Building Docker images:$(NC)"
	@docker compose -f $(COMPOSE_FILE) build

# Start containers
up: build
	@echo "$(BLUE)Starting Docker containers:$(NC)"
	@docker compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)    Inception is up and running!$(NC)"
	@echo "Access WordPress at: https://$(DOMAIN_NAME)"

.PHONY: all check check-secrets check-ssl setup up build logs ps status
