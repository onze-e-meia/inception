FROM debian:11

# Install MariaDB server
RUN apt-get update && \
    apt-get install -y \
    mariadb-server \
    mariadb-client && \
    rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copy initialization script
COPY tools/init-db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-db.sh

# Create directory for socket and set permissions
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

# Set proper permissions for data directory
RUN chown -R mysql:mysql /var/lib/mysql

# Expose MariaDB port
EXPOSE 3306

# Run initialization script and start MariaDB
ENTRYPOINT ["/usr/local/bin/init-db.sh"]
