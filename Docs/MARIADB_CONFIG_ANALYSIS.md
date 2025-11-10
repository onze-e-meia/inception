# MariaDB Configuration Deep Dive - Inception Project

## Overview

You have **THREE** MariaDB configuration files:

1. **`Dockerfile`** - Builds the MariaDB container image
2. **`50-server.cnf`** - MariaDB server configuration
3. **`init-db.sh`** - Database initialization script

---

## File 1: Dockerfile (Container Build)

### Purpose
Defines how to build the MariaDB Docker image.

### Line-by-Line Analysis

```dockerfile
FROM debian:12
```
- **What it does:** Base image - Debian 12 (Bookworm)
- **Why:** Subject requires Alpine or Debian, you chose Debian 12
- **For Inception:** ✅ **CORRECT** - Meets requirements
- **Note:** You're using Debian 12, but your other containers use Debian 11 - consider consistency

```dockerfile
RUN apt-get update && \
    apt-get install -y \
    mariadb-server \
    mariadb-client && \
    rm -rf /var/lib/apt/lists/*
```
- **What it does:**
  - Update package list
  - Install MariaDB server and client
  - Clean up package cache
- **Why:**
  - `mariadb-server`: The actual database
  - `mariadb-client`: Tools like `mysql`, `mysqladmin` (needed for healthcheck!)
  - `rm -rf /var/lib/apt/lists/*`: Reduces image size
- **For Inception:** ✅ **ESSENTIAL** - You need both server and client

```dockerfile
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
```
- **What it does:** Copy your custom MariaDB configuration
- **Why:** Override defaults (bind-address, character sets, etc.)
- **For Inception:** ✅ **ESSENTIAL** - Need to bind to 0.0.0.0 for Docker networking

```dockerfile
COPY tools/init-db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-db.sh
```
- **What it does:** Copy and make executable the initialization script
- **Why:** Creates database, users, sets passwords on first run
- **For Inception:** ✅ **ESSENTIAL** - Must initialize database

```dockerfile
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld
```
- **What it does:**
  - Create directory for MySQL socket file
  - Change ownership to mysql user
  - Set permissions to 777 (read/write/execute for everyone)
- **Why:** MariaDB writes socket file here, needs permissions
- **For Inception:** ⚠️ **PERMISSIONS TOO OPEN**
  - `chmod 777` is security issue (everyone can access)
  - Should be `chmod 755` or `chmod 775`
- **Fix:** Change to `chmod 755`

```dockerfile
RUN chown -R mysql:mysql /var/lib/mysql
```
- **What it does:** Set ownership of data directory
- **Why:** MariaDB needs to write database files here
- **For Inception:** ✅ **ESSENTIAL** - MariaDB won't work without proper ownership

```dockerfile
EXPOSE 3306
```
- **What it does:** Document that container uses port 3306
- **Why:** Informational - tells Docker/users which port MariaDB uses
- **For Inception:** ⚠️ **DOCUMENTATION ONLY**
  - Doesn't actually open port (docker-compose.yml does that)
  - Good practice to document
  - Keep for clarity

```dockerfile
ENTRYPOINT ["/usr/local/bin/init-db.sh"]
```
- **What it does:** Run init script when container starts
- **Why:** Initialize DB on first run, then start MariaDB
- **For Inception:** ✅ **ESSENTIAL** - This is how everything starts

---

## File 2: 50-server.cnf (Server Configuration)

### Purpose
Configure MariaDB server behavior, performance, and networking.

### Line-by-Line Analysis

```ini
[mysqld]
```
- **What it does:** Start of mysqld (server) configuration section
- **For Inception:** ✅ **ESSENTIAL** - All settings go under this

```ini
user = mysql
```
- **What it does:** Run MariaDB as 'mysql' user
- **Why:** Security - don't run as root
- **For Inception:** ✅ **ESSENTIAL** - Matches Dockerfile ownership

```ini
pid-file = /var/run/mysqld/mysqld.pid
```
- **What it does:** Location of process ID file
- **Why:** Used for process management, healthchecks
- **For Inception:** ✅ **USEFUL** - Default location, keep it

```ini
socket = /var/run/mysqld/mysqld.sock
```
- **What it does:** Unix socket file location for local connections
- **Why:** Faster than TCP for same-machine connections
- **For Inception:** ⚠️ **OPTIONAL**
  - Your setup uses TCP (wordpress:3306), not socket
  - Doesn't hurt to define though
- **Verdict:** Can keep or remove

```ini
port = 3306
```
- **What it does:** TCP port MariaDB listens on
- **Why:** Standard MySQL/MariaDB port
- **For Inception:** ✅ **ESSENTIAL** - WordPress connects here

```ini
basedir = /usr
datadir = /var/lib/mysql
tmpdir = /tmp
```
- **What it does:**
  - `basedir`: Where MariaDB binaries are installed
  - `datadir`: Where database files are stored
  - `tmpdir`: Temporary files location
- **Why:** Tell MariaDB where everything is
- **For Inception:** ✅ **ESSENTIAL**
  - `datadir` especially - this is your volume mount point!

```ini
lc-messages-dir = /usr/share/mysql
```
- **What it does:** Location of error message translations
- **Why:** Localization
- **For Inception:** ❌ **UNNECESSARY**
  - Default works fine
  - You don't need translations
- **Simplify:** Remove

```ini
bind-address = 0.0.0.0
```
- **What it does:** Listen on all network interfaces
- **Why:** Allows WordPress container to connect
- **For Inception:** ✅ **ESSENTIAL**
  - Default is 127.0.0.1 (localhost only)
  - **MUST be 0.0.0.0 for Docker networking!**
- **This is critical!**

```ini
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
```
- **What it does:**
  - Default character encoding: UTF-8 with 4 bytes (emojis!)
  - Default collation: Unicode sorting rules
- **Why:** Proper international character support
- **For Inception:** ✅ **ESSENTIAL**
  - WordPress needs utf8mb4 for proper emoji/international support
  - Best practice

```ini
default-storage-engine = InnoDB
```
- **What it does:** Use InnoDB as default table type
- **Why:** InnoDB supports transactions, foreign keys, crash recovery
- **For Inception:** ✅ **GOOD PRACTICE**
  - WordPress uses InnoDB
  - Default in modern MariaDB anyway
- **Verdict:** Keep it

```ini
innodb_buffer_pool_size = 256M
```
- **What it does:** Memory for caching table data and indexes
- **Why:** Performance - more cache = less disk I/O
- **For Inception:** ⚠️ **OVERKILL**
  - 256MB is for production servers
  - WordPress on local VM needs maybe 64MB
  - Your container only has a few MB of WordPress data
- **Simplify:** Change to `64M` or `128M` or remove (default is 128M)

```ini
innodb_log_file_size = 64M
```
- **What it does:** Size of transaction log files
- **Why:** Larger = better performance for write-heavy workloads
- **For Inception:** ❌ **OVERKILL**
  - 64MB is for busy production databases
  - You'll have maybe 10 blog posts
  - Default (48M) is plenty
- **Simplify:** Remove (use default)

```ini
innodb_flush_method = O_DIRECT
```
- **What it does:** How to write data to disk (bypass OS cache)
- **Why:** Performance tuning on physical servers
- **For Inception:** ❌ **UNNECESSARY**
  - This is for bare metal servers with specific I/O patterns
  - In Docker on VM, no benefit
  - Can cause issues with certain storage drivers
- **Simplify:** Remove

```ini
# Query Cache (disabled in MariaDB 10.5+)
# query_cache_type = 0
# query_cache_size = 0
```
- **What it does:** Query cache (now deprecated)
- **Why:** These are commented out - query cache removed in modern MariaDB
- **For Inception:** ℹ️ **ALREADY DISABLED**
  - Good that they're commented
- **Simplify:** Remove entire comment block (not needed)

```ini
log_error = /var/log/mysql/error.log
```
- **What it does:** Where to write error messages
- **Why:** Debugging, monitoring
- **For Inception:** ✅ **ESSENTIAL**
  - You'll need this for debugging
  - Used in init script too

```ini
general_log_file = /var/log/mysql/mysql.log
general_log = 0
```
- **What it does:**
  - Location of general query log
  - `general_log = 0` means it's disabled
- **Why:** General log records every query (huge file, slow)
- **For Inception:** ✅ **CORRECT**
  - Good to define location
  - Good that it's disabled (0)
- **Verdict:** Keep or remove (doesn't matter if disabled)

```ini
slow_query_log = 0
```
- **What it does:** Log queries that take too long (disabled)
- **Why:** Performance monitoring for production
- **For Inception:** ❌ **UNNECESSARY**
  - You won't have slow queries
  - It's disabled anyway
- **Simplify:** Remove

```ini
skip-name-resolve
```
- **What it does:** Don't do DNS lookups for connecting hosts
- **Why:** Performance - faster connections
- **For Inception:** ✅ **GOOD PRACTICE**
  - Avoids DNS lookup delays
  - Harmless
- **Keep this**

```ini
max_connections = 100
```
- **What it does:** Maximum simultaneous connections
- **Why:** Prevent resource exhaustion
- **For Inception:** ⚠️ **OVERKILL**
  - You have 1 WordPress instance connecting
  - Default (151) is already way more than needed
  - Could be 10 or even 5
- **Simplify:** Change to `20` or remove (default is fine)

```ini
connect_timeout = 10
wait_timeout = 600
```
- **What it does:**
  - `connect_timeout`: How long to wait for connection to establish
  - `wait_timeout`: How long to keep idle connection open (10 minutes)
- **Why:** Prevent hanging connections
- **For Inception:** ⚠️ **OPTIONAL**
  - Defaults work fine
  - These are reasonable values though
- **Verdict:** Keep or remove (not critical)

```ini
max_allowed_packet = 64M
```
- **What it does:** Maximum size of a single query/packet
- **Why:** WordPress sometimes imports large SQL dumps
- **For Inception:** ✅ **USEFUL**
  - Matches your NGINX `client_max_body_size`
  - Good for importing themes/plugins
- **Keep this**

```ini
thread_cache_size = 128
```
- **What it does:** Cache database connection threads
- **Why:** Performance - reuse threads instead of creating new ones
- **For Inception:** ❌ **OVERKILL**
  - 128 threads for 1 WordPress connection?
  - Default (9) is plenty
- **Simplify:** Remove (use default)

```ini
sort_buffer_size = 4M
bulk_insert_buffer_size = 16M
tmp_table_size = 32M
max_heap_table_size = 32M
```
- **What it does:** Memory buffers for various operations:
  - `sort_buffer_size`: Memory for ORDER BY
  - `bulk_insert_buffer_size`: Memory for bulk inserts
  - `tmp_table_size`: Max size for in-memory temp tables
  - `max_heap_table_size`: Max size for MEMORY tables
- **Why:** Performance tuning for specific workloads
- **For Inception:** ❌ **OVERKILL**
  - These are for high-performance production servers
  - WordPress doesn't need this fine-tuning
  - Defaults work perfectly
- **Simplify:** Remove all four

---

## File 3: init-db.sh (Initialization Script)

### Purpose
One-time database setup: create database, users, set passwords.

### Line-by-Line Analysis

```bash
#!/bin/bash
```
- **What it does:** Shebang - run with bash interpreter
- **For Inception:** ✅ **ESSENTIAL**

```bash
set -e
```
- **What it does:** Exit immediately if any command fails
- **Why:** Safety - don't continue if something goes wrong
- **For Inception:** ✅ **GOOD PRACTICE**

```bash
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mysql_root_pass)
MYSQL_PASSWORD=$(cat /run/secrets/mysql_pass)
```
- **What it does:** Read passwords from Docker secrets files
- **Why:** Security - passwords not in code or environment
- **For Inception:** ✅ **EXCELLENT SECURITY**
  - This is Docker secrets best practice!
  - Better than environment variables
- **BUT:** Check if you're actually using Docker secrets in docker-compose.yml
  - If not using secrets, change to environment variables:
  ```bash
  MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
  MYSQL_PASSWORD=${MYSQL_PASSWORD}
  ```

```bash
mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql
```
- **What it does:** Create log directory and set ownership
- **Why:** MariaDB needs to write error logs
- **For Inception:** ✅ **ESSENTIAL**
  - Matches `log_error` setting in config

```bash
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi
```
- **What it does:**
  - Check if database already initialized
  - If not, create system tables
- **Why:** Only initialize once (important for persistent volumes!)
- **For Inception:** ✅ **ESSENTIAL**
  - Prevents re-initialization on restart
  - Critical for data persistence

```bash
echo "Starting MariaDB temporarily for initial setup..."
mysqld --user=mysql --bootstrap << EOF
```
- **What it does:** Start MariaDB in bootstrap mode (single-user, no network)
- **Why:** Safe way to initialize database before starting server
- **For Inception:** ✅ **EXCELLENT PRACTICE**
  - Better than starting server then connecting
  - More secure

```sql
USE mysql;
FLUSH PRIVILEGES;
```
- **What it does:**
  - Switch to mysql system database
  - Reload privilege tables
- **Why:** Ensure changes take effect
- **For Inception:** ✅ **NECESSARY**

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
```
- **What it does:** Set root password for localhost connections
- **Why:** Security - default root has no password
- **For Inception:** ✅ **ESSENTIAL**
  - Needed for healthcheck (`mysqladmin ping`)

```sql
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
```
- **What it does:** Create WordPress database if doesn't exist
- **Why:** WordPress needs a database
- **For Inception:** ✅ **ESSENTIAL**
  - Backticks handle database names with special chars

```sql
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
```
- **What it does:**
  - Create WordPress user (can connect from any host: `%`)
  - Grant all permissions on WordPress database
- **Why:** WordPress needs credentials to access its database
- **For Inception:** ✅ **ESSENTIAL**
  - `@'%'` is critical - WordPress container is remote host!

```sql
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
```
- **What it does:**
  - Allow root to connect from any host
  - Grant all privileges on all databases
- **Why:** Administration, debugging
- **For Inception:** ⚠️ **SECURITY RISK**
  - Allows root access from anywhere
  - Fine for development/local, but not production
  - For 42 project, it's acceptable
- **Verdict:** Keep for Inception, but know it's insecure

```sql
FLUSH PRIVILEGES;
```
- **What it does:** Reload privilege tables after changes
- **Why:** Make new users/permissions active
- **For Inception:** ✅ **ESSENTIAL**

```bash
echo "MariaDB initialization complete."
echo "Starting MariaDB server..."

exec mysqld --user=mysql
```
- **What it does:**
  - Print status message
  - Start MariaDB in foreground (PID 1)
- **Why:** `exec` replaces shell with mysqld (proper PID 1)
- **For Inception:** ✅ **PERFECT**
  - Correct Docker best practice
  - Server runs in foreground
  - Proper signal handling

---

## Summary: What's Essential vs Optional

### MUST KEEP (Core Functionality)

#### Dockerfile:
```dockerfile
FROM debian:11  # Match other containers

RUN apt-get update && \
    apt-get install -y mariadb-server mariadb-client && \
    rm -rf /var/lib/apt/lists/*

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/init-db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-db.sh

RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 755 /var/run/mysqld  # Fixed: was 777

RUN chown -R mysql:mysql /var/lib/mysql

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init-db.sh"]
```

#### 50-server.cnf (Minimal):
```ini
[mysqld]
# Basic Settings
user = mysql
pid-file = /var/run/mysqld/mysqld.pid
port = 3306
datadir = /var/lib/mysql

# CRITICAL: Allow Docker connections
bind-address = 0.0.0.0

# Character Set (WordPress requirement)
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# Logging
log_error = /var/log/mysql/error.log

# Performance
skip-name-resolve
max_allowed_packet = 64M
```

#### init-db.sh:
**Keep entire script** - all parts are necessary.

**Fix only:** If NOT using Docker secrets, change:
```bash
# From:
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mysql_root_pass)
MYSQL_PASSWORD=$(cat /run/secrets/mysql_pass)

# To:
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
```

---

## Minimal Configuration (Absolute Bare Bones)

### Dockerfile (Minimal):
```dockerfile
FROM debian:11

RUN apt-get update && \
    apt-get install -y mariadb-server mariadb-client && \
    rm -rf /var/lib/apt/lists/*

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/
COPY tools/init-db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-db.sh

RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init-db.sh"]
```
**Changes:** Combined chown commands, removed 777 permission

### 50-server.cnf (Minimal):
```ini
[mysqld]
user = mysql
datadir = /var/lib/mysql
bind-address = 0.0.0.0

character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

log_error = /var/log/mysql/error.log
skip-name-resolve
```
**Result:** 9 lines instead of 49!

### init-db.sh (Keep as-is):
Only change if NOT using Docker secrets - otherwise perfect!

---

## Recommended Configuration (Balanced)

### Dockerfile (Recommended):
```dockerfile
FROM debian:11

# Install MariaDB
RUN apt-get update && \
    apt-get install -y mariadb-server mariadb-client && \
    rm -rf /var/lib/apt/lists/*

# Copy configuration
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copy and setup initialization script
COPY tools/init-db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-db.sh

# Create runtime directory and set permissions
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 755 /var/run/mysqld

# Set data directory permissions
RUN chown -R mysql:mysql /var/lib/mysql

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init-db.sh"]
```

### 50-server.cnf (Recommended):
```ini
[mysqld]
# Basic Settings
user = mysql
pid-file = /var/run/mysqld/mysqld.pid
port = 3306
datadir = /var/lib/mysql

# Network - ESSENTIAL for Docker
bind-address = 0.0.0.0

# Character Set - WordPress Standard
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# Storage Engine
default-storage-engine = InnoDB

# Logging
log_error = /var/log/mysql/error.log

# Performance
skip-name-resolve
max_connections = 20
max_allowed_packet = 64M

# Memory Settings (Light)
innodb_buffer_pool_size = 128M
```

### init-db.sh (Recommended):
```bash
#!/bin/bash
set -e

# Get passwords (adjust based on your setup)
# If using Docker secrets:
# MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mysql_root_pass)
# MYSQL_PASSWORD=$(cat /run/secrets/mysql_pass)

# If using environment variables:
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_PASSWORD=${MYSQL_PASSWORD}

# Create log directory
mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql

# Initialize database if needed
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

# Configure database
echo "Starting MariaDB temporarily for initial setup..."
mysqld --user=mysql --bootstrap << EOF
USE mysql;
FLUSH PRIVILEGES;

ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF

echo "MariaDB initialization complete."
echo "Starting MariaDB server..."

# Start MariaDB in foreground
exec mysqld --user=mysql
```
**Changes from your version:**
- Removed remote root access (more secure)
- Adjusted for environment variables (most common setup)

---

## Key Issues in Your Current Files

### 🔴 CRITICAL Issues:

1. **Dockerfile line 20:** `chmod 777` is security risk
   - **Fix:** Change to `chmod 755`

2. **init-db.sh Docker secrets:** Script reads from `/run/secrets/` but docker-compose.yml probably doesn't use secrets
   - **Check:** Do you have `secrets:` in docker-compose.yml?
   - **Fix:** Either add secrets properly OR change script to use env vars

3. **Debian version mismatch:** Dockerfile uses `debian:12`, others use `debian:11`
   - **Fix:** Use `debian:11` for consistency

### ⚠️ OVERKILL Issues:

4. **50-server.cnf:** Too many performance tuning parameters
   - 256M buffer pool for tiny WordPress database
   - 128 thread cache for 1 connection
   - Production-level memory settings

5. **50-server.cnf:** Unnecessary settings:
   - `lc-messages-dir`
   - `slow_query_log`
   - `general_log` (already disabled)
   - `innodb_flush_method`
   - Query cache comments (already removed from MariaDB)

### ℹ️ MINOR Issues:

6. **init-db.sh:** Remote root access (`root@'%'`)
   - Fine for Inception, but note it's insecure

---

## Critical Configuration Check

### Is Your docker-compose.yml Using Secrets?

**If you have this in docker-compose.yml:**
```yaml
services:
  mariadb:
    secrets:
      - mysql_root_pass
      - mysql_pass
    
secrets:
  mysql_root_pass:
    file: ./secrets/db_root_password.txt
  mysql_pass:
    file: ./secrets/db_password.txt
```
**Then:** Keep your current init-db.sh ✅

**If you DON'T have secrets block:**
```yaml
services:
  mariadb:
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
```
**Then:** Change init-db.sh to use env vars ⚠️

---

## What to Remove from Your Files

### From Dockerfile:
❌ Line 20: Change `chmod 777` → `chmod 755`  
✅ Everything else is fine (maybe combine chown commands)

### From 50-server.cnf - Remove:
```ini
lc-messages-dir = /usr/share/mysql          # Not needed
socket = /var/run/mysqld/mysqld.sock        # Optional (not using)
tmpdir = /tmp                                # Default
basedir = /usr                               # Default

innodb_log_file_size = 64M                   # Overkill
innodb_flush_method = O_DIRECT               # Unnecessary in Docker

# query_cache comments                       # Already removed from MariaDB
general_log_file = /var/log/mysql/mysql.log # Not using
general_log = 0                              # Already disabled
slow_query_log = 0                           # Not needed

thread_cache_size = 128                      # Way too high
sort_buffer_size = 4M                        # Not needed
bulk_insert_buffer_size = 16M                # Not needed
tmp_table_size = 32M                         # Not needed
max_heap_table_size = 32M                    # Not needed

max_connections = 100                        # Too high (use 20)
connect_timeout = 10                         # Optional
wait_timeout = 600                           # Optional
```

### From 50-server.cnf - Simplify:
```ini
innodb_buffer_pool_size = 256M  # Change to 128M or 64M
```

### From init-db.sh - Fix:
```bash
# If NOT using Docker secrets, change:
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mysql_root_pass)
MYSQL_PASSWORD=$(cat /run/secrets/mysql_pass)

# To:
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
```

```sql
-- Optional: Remove for better security
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
```

---

## TL;DR - Recommendations

### Your Current Config:
**Verdict:** Mostly good, but has some issues and overkill.

### Critical Fixes Needed:
1. ✅ Change `chmod 777` to `chmod 755` in Dockerfile
2. ✅ Fix Debian version (use `debian:11` consistently)
3. ✅ Check Docker secrets vs environment variables in init-db.sh

### Recommended Changes:
1. Simplify 50-server.cnf (remove ~60% of settings)
2. Reduce `innodb_buffer_pool_size` to 64M or 128M
3. Remove performance tuning that doesn't apply to Docker

### Optional Improvements:
1. Remove remote root access from init-db.sh (better security)
2. Combine some RUN commands in Dockerfile (fewer layers)

---

## Final Recommendation

**Use the "Recommended" configuration** shown above.

**Why:**
1. ✅ Fixes security issue (chmod 777)
2. ✅ Removes unnecessary complexity
3. ✅ Still shows you understand MariaDB
4. ✅ Easier to explain during evaluation
5. ✅ Actually matches your workload

**What this achieves:**
- Reduces config file from 49 lines to ~20 lines
- Removes production-level tuning
- Keeps all essential features
- More appropriate for Inception scope

**Before making changes:** Check your docker-compose.yml to see if you're using Docker secrets or environment variables, then adjust init-db.sh accordingly!

---

## Files Comparison

### Current vs Recommended Line Count:

| File | Current | Minimal | Recommended |
|------|---------|---------|-------------|
| Dockerfile | 30 lines | 16 lines | 23 lines |
| 50-server.cnf | 49 lines | 9 lines | 21 lines |
| init-db.sh | 45 lines | 45 lines | 40 lines |
| **Total** | **124 lines** | **70 lines** | **84 lines** |

**Reduction:** From 124 to 84 lines (32% less code, same functionality!)

🎯
