#!/bin/bash

set -e

MYSQL_PASSWORD=$(cat /run/secrets/mysql_pass)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_pass)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_pass)

echo " # Waiting for MariaDB..."
# Wait for MariaDB to be ready
until mariadb -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
    echo " # MariaDB is unavailable (sleeping)"
    sleep 3
done

echo " ## MariaDB is up and running!"

# Change to WordPress directory
cd /var/www/html

# Download WordPress if not already present
if [ ! -f "wp-config.php" ]; then
    echo " # Downloading WordPress via client."

    # Remove existing files
    rm -rf /var/www/html/*

    # Download WordPress core
    wp-cli core download --allow-root

    echo " ## Configuring WordPress."

    # Create wp-config.php
    wp-cli config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost=mariadb:3306 \
        --dbcharset="utf8mb4" \
        --dbcollate="utf8mb4_unicode_ci" \
        --allow-root

    # Install WordPress
    wp-cli core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    # Create additional user
    wp-cli user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=editor \
        --allow-root

    echo " ### WordPress installation complete!"
else
    echo " # WordPress already installed, skipping installation..."
fi

# Set permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo " #### Starting PHP-FPM."

# Start PHP-FPM in foreground as PID 1
exec php-fpm8.2 -F
