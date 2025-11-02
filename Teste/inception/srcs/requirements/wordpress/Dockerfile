FROM debian:11

# Install PHP-FPM and required PHP extensions
RUN apt-get update && \
    apt-get install -y \
    php7.4-fpm \
    php7.4-mysqli \
    php7.4-mbstring \
    php7.4-gd \
    php7.4-curl \
    php7.4-zip \
    php7.4-xml \
    php7.4-intl \
    php7.4-soap \
    php7.4-bcmath \
    mariadb-client \
    curl \
    wget && \
    rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Copy PHP-FPM configuration
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Copy WordPress installation script
COPY tools/install-wp.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install-wp.sh

# Create directory for PHP-FPM socket
RUN mkdir -p /run/php && \
    chown -R www-data:www-data /run/php

# Create WordPress directory and set permissions
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html

# Set working directory
WORKDIR /var/www/html

# Expose PHP-FPM port
EXPOSE 9000

# Run installation script and start PHP-FPM
ENTRYPOINT ["/usr/local/bin/install-wp.sh"]
