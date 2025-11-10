FROM debian:12

# Install PHP-FPM and required PHP extensions
RUN apt-get update && \
    apt-get install -y \
    php8.2-fpm \
    php8.2-mysqli \
    php8.2-mbstring \
    php8.2-gd \
    php8.2-curl \
    php8.2-zip \
    php8.2-xml \
    mariadb-client \
    curl && \
    rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp-cli

# Copy PHP-FPM config. and WordPress script
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/install-wp.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install-wp.sh

# Create directory for PHP-FPM socket
RUN mkdir -p /run/php && \
    chown -R www-data:www-data /run/php

# Create WordPress directory and set permissions
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html

# Create PHP session directories
# RUN mkdir -p /var/lib/php/sessions && \
#     mkdir -p /var/lib/php/wsdlcache && \
#     chown -R www-data:www-data /var/lib/php && \
#     chmod -R 755 /var/lib/php

WORKDIR /var/www/html
EXPOSE  9000
ENTRYPOINT ["/usr/local/bin/install-wp.sh"]
