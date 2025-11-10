#!/bin/bash

set -e

MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mysql_root_pass)
MYSQL_PASSWORD=$(cat /run/secrets/mysql_pass)

# Create log directory if it doesn't exist
mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo " # Initializing MariaDB data directory."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

echo " ## Starting MariaDB in bootstrap mode."
mysqld --user=mysql --bootstrap << EOF
USE mysql;
FLUSH PRIVILEGES;

-- Root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create WordPress database
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Create WordPress user with access from any host
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

-- Ensure root can connect from any host for administration
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;
EOF

echo " ### MariaDB initialization complete!"
echo " #### Starting MariaDB server."

# Start MariaDB in foreground as PID 1
exec mysqld --user=mysql
