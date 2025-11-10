FROM debian:12

# Install NGINX
RUN apt-get update && \
    apt-get install -y \
    nginx \
    openssl && \
    rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /var/www/html && \
    mkdir -p /etc/nginx/ssl && \
    chown -R www-data:www-data /var/www/html

# Copy NGINX config.
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/default.conf /etc/nginx/conf.d/default.conf

# Copy SSL certificates
COPY conf/nginx.crt /etc/nginx/ssl/nginx.crt
COPY conf/nginx.key /etc/nginx/ssl/nginx.key

# Set proper permissions for SSL certificates
RUN chmod 644 /etc/nginx/ssl/nginx.crt && \
    chmod 600 /etc/nginx/ssl/nginx.key

EXPOSE 443
CMD ["nginx", "-g", "daemon off;"]
