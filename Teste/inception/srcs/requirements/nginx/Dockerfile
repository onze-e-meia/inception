FROM debian:11

# Install NGINX
RUN apt-get update && \
    apt-get install -y \
    nginx \
    openssl && \
    rm -rf /var/lib/apt/lists/*

# Copy NGINX configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/default.conf /etc/nginx/conf.d/default.conf

# Copy SSL certificates
COPY conf/nginx.crt /etc/nginx/ssl/nginx.crt
COPY conf/nginx.key /etc/nginx/ssl/nginx.key

# Create necessary directories
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html && \
    mkdir -p /etc/nginx/ssl

# Set proper permissions for SSL certificates
RUN chmod 644 /etc/nginx/ssl/nginx.crt && \
    chmod 600 /etc/nginx/ssl/nginx.key

# Expose HTTPS port only
EXPOSE 443

# Start NGINX in foreground
CMD ["nginx", "-g", "daemon off;"]
