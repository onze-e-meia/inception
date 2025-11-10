# WordPress Configuration Deep Dive - Inception Project

## Overview

You have **THREE** WordPress configuration files:

1. **`Dockerfile`** - Builds the WordPress/PHP-FPM container
2. **`www.conf`** - PHP-FPM pool configuration
3. **`install-wp.sh`** - WordPress download and installation script

---

## File 1: Dockerfile (Container Build)

### Purpose
Creates a container with PHP-FPM and WordPress CLI, ready to run WordPress.

### Line-by-Line Analysis

```dockerfile
FROM debian:12
```
- **What it does:** Base image - Debian 12 (Bookworm)
- **Why:** Modern PHP 8.2 packages available
- **For Inception:** ⚠️ **INCONSISTENCY**
  - Your NGINX and MariaDB use Debian 11
  - Should match for consistency
- **Fix:** Change to `FROM debian:11` and use PHP 7.4 (or keep all on Debian 12)

```dockerfile
RUN apt-get update && \
    apt-get install -y \
    php8.2-fpm \
```
- **What it does:** Install PHP 8.2 FastCGI Process Manager
- **Why:** PHP-FPM handles PHP requests from NGINX
- **For Inception:** ✅ **ESSENTIAL**
- **Note:** Version mismatch with subject examples (they show PHP 7.4)
  - PHP 8.2 is fine, just be consistent

```dockerfile
    php8.2-mysqli \
```
- **What it does:** MySQL/MariaDB database extension
- **Why:** WordPress NEEDS this to connect to database
- **For Inception:** ✅ **ESSENTIAL** - WordPress won't work without it

```dockerfile
    php8.2-mbstring \
```
- **What it does:** Multibyte string handling (international characters)
- **Why:** WordPress uses this for UTF-8 text processing
- **For Inception:** ✅ **ESSENTIAL** - WordPress requires this

```dockerfile
    php8.2-gd \
```
- **What it does:** Image processing library (GD Graphics)
- **Why:** WordPress uses it for thumbnails, image resizing
- **For Inception:** ✅ **ESSENTIAL** - Media library won't work without it

```dockerfile
    php8.2-curl \
```
- **What it does:** HTTP client library
- **Why:** WordPress uses it for API calls, HTTP requests, plugin updates
- **For Inception:** ✅ **ESSENTIAL** - WordPress core functionality

```dockerfile
    php8.2-zip \
```
- **What it does:** ZIP archive handling
- **Why:** WordPress uses it for plugin/theme installation
- **For Inception:** ✅ **USEFUL** - Plugin/theme uploads need this
- **Verdict:** Keep it

```dockerfile
    php8.2-xml \
```
- **What it does:** XML parsing and generation
- **Why:** WordPress uses XML for:
  - RSS feeds
  - XML-RPC (remote publishing)
  - Import/export features
- **For Inception:** ✅ **ESSENTIAL** - WordPress requires this

```dockerfile
    php8.2-intl \
```
- **What it does:** Internationalization extension
- **Why:** Date/time formatting, translations
- **For Inception:** ⚠️ **OPTIONAL**
  - Nice to have for multilingual sites
  - Not critical for basic WordPress
  - Default locale works without it
- **Simplify:** Can remove, but harmless

```dockerfile
    php8.2-soap \
```
- **What it does:** SOAP web services protocol
- **Why:** Some plugins use SOAP for external APIs
- **For Inception:** ❌ **UNNECESSARY**
  - Rarely used in modern WordPress
  - You won't use SOAP in this project
  - Legacy API protocol
- **Simplify:** Remove

```dockerfile
    php8.2-bcmath \
```
- **What it does:** Arbitrary precision math
- **Why:** Some e-commerce plugins need it
- **For Inception:** ❌ **UNNECESSARY**
  - Not needed for basic WordPress
  - Only used by specific plugins
- **Simplify:** Remove

```dockerfile
    mariadb-client \
```
- **What it does:** MariaDB command-line tools (mysql, mysqladmin)
- **Why:** 
  - Script uses `mariadb` command to test connection
  - Useful for debugging
- **For Inception:** ✅ **ESSENTIAL**
  - Your install-wp.sh uses `mariadb -h mariadb` to test connection
  - Keep this!

```dockerfile
    curl \
    wget && \
```
- **What it does:** Download tools
- **Why:** 
  - `curl`: Used to download WP-CLI
  - `wget`: Alternative download tool
- **For Inception:** ⚠️ **REDUNDANT**
  - You only need ONE of these
  - Script uses WP-CLI which was downloaded with curl
  - `wget` is not used anywhere
- **Simplify:** Remove `wget`, keep `curl`

```dockerfile
    rm -rf /var/lib/apt/lists/*
```
- **What it does:** Delete package cache
- **Why:** Reduce image size
- **For Inception:** ✅ **BEST PRACTICE** - Always do this

```dockerfile
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp
```
- **What it does:** Install WP-CLI (WordPress command-line tool)
- **Why:** Automate WordPress installation (download, config, install)
- **For Inception:** ✅ **ESSENTIAL**
  - This is how you automate WordPress setup
  - Much better than manual installation

```dockerfile
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
```
- **What it does:** Copy custom PHP-FPM pool configuration
- **Why:** Configure how PHP-FPM runs (port, workers, limits)
- **For Inception:** ✅ **ESSENTIAL**
  - Default config uses Unix socket, you need TCP (0.0.0.0:9000)

```dockerfile
COPY tools/install-wp.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install-wp.sh
```
- **What it does:** Copy and make executable the WordPress installation script
- **Why:** Automate WordPress download and configuration
- **For Inception:** ✅ **ESSENTIAL** - This is your automation

```dockerfile
RUN mkdir -p /run/php && \
    chown -R www-data:www-data /run/php
```
- **What it does:** Create directory for PHP-FPM PID/socket files
- **Why:** PHP-FPM needs this to run
- **For Inception:** ✅ **ESSENTIAL**
  - PHP-FPM won't start without it

```dockerfile
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html
```
- **What it does:** Create WordPress directory with proper ownership
- **Why:** WordPress files go here, PHP needs write access
- **For Inception:** ✅ **ESSENTIAL**
  - This is your document root
  - Ownership must be www-data for uploads to work

```dockerfile
RUN mkdir -p /var/lib/php/sessions && \
    mkdir -p /var/lib/php/wsdlcache && \
    chown -R www-data:www-data /var/lib/php && \
    chmod -R 755 /var/lib/php
```
- **What it does:** Create PHP session and SOAP cache directories
- **Why:** www.conf references these paths
- **For Inception:** ✅ **CRITICAL FIX**
  - You added this after our debugging - good!
  - Without this, PHP-FPM crashes
  - Matches www.conf settings

```dockerfile
WORKDIR /var/www/html
```
- **What it does:** Set default directory for commands
- **Why:** Scripts run from WordPress directory
- **For Inception:** ✅ **USEFUL** - Clean practice

```dockerfile
EXPOSE 9000
```
- **What it does:** Document that container uses port 9000
- **Why:** Informational - PHP-FPM listens here
- **For Inception:** ⚠️ **DOCUMENTATION ONLY**
  - Doesn't actually open port (www.conf does)
  - Good for clarity
- **Verdict:** Keep for documentation

```dockerfile
ENTRYPOINT ["/usr/local/bin/install-wp.sh"]
```
- **What it does:** Run installation script on container start
- **Why:** Install WordPress, then start PHP-FPM
- **For Inception:** ✅ **ESSENTIAL** - This starts everything

---

## File 2: www.conf (PHP-FPM Pool Configuration)

### Purpose
Configure how PHP-FPM process pool runs - networking, workers, memory, security.

### Line-by-Line Analysis

```ini
[www]
```
- **What it does:** Name of the pool
- **Why:** Can have multiple pools with different settings
- **For Inception:** ✅ **ESSENTIAL** - Standard pool name

```ini
user = www-data
group = www-data
```
- **What it does:** Run PHP-FPM workers as www-data user/group
- **Why:** Security - match file ownership, don't run as root
- **For Inception:** ✅ **ESSENTIAL** - Matches ownership in Dockerfile

```ini
listen = 0.0.0.0:9000
```
- **What it does:** Listen on all interfaces, TCP port 9000
- **Why:** NGINX container needs to connect over network
- **For Inception:** ✅ **CRITICAL**
  - Default is Unix socket (/run/php/php-fpm.sock)
  - Docker networking requires TCP
  - **This is mandatory for Inception!**

```ini
pm = dynamic
```
- **What it does:** Process manager type
  - `static`: Fixed number of workers
  - `dynamic`: Spawn/kill workers as needed
  - `ondemand`: Start workers only when requests come
- **Why:** Balance between responsiveness and resource usage
- **For Inception:** ✅ **GOOD CHOICE**
  - `dynamic` is WordPress standard
  - Better than `static` for variable load
  - Better than `ondemand` for responsiveness

```ini
pm.max_children = 10
```
- **What it does:** Maximum worker processes
- **Why:** Limit resource usage
- **For Inception:** ⚠️ **SLIGHTLY HIGH**
  - 10 workers for 1-2 users (evaluator)
  - Each worker uses ~20-50MB RAM
  - Formula: max_children × memory_limit = total RAM
  - 10 × 256MB = 2.5GB potential usage
- **Simplify:** Change to `5` or even `3`

```ini
pm.start_servers = 2
```
- **What it does:** Workers to start on boot
- **Why:** Have some ready immediately
- **For Inception:** ✅ **REASONABLE**
  - Start with 2, scale up if needed
  - Good balance

```ini
pm.min_spare_servers = 1
pm.max_spare_servers = 3
```
- **What it does:**
  - `min_spare`: Keep at least 1 idle worker ready
  - `max_spare`: Kill idle workers above 3
- **Why:** Maintain pool of ready workers
- **For Inception:** ✅ **REASONABLE**
  - Ensures at least 1 worker always ready
  - Prevents too many idle workers

```ini
pm.max_requests = 500
```
- **What it does:** Restart worker after 500 requests
- **Why:** Prevent memory leaks from accumulating
- **For Inception:** ⚠️ **OPTIONAL**
  - PHP 8.2 has good memory management
  - 500 is conservative (could be 1000)
  - Not critical for short-lived project
- **Verdict:** Keep or remove, doesn't matter much

```ini
pm.status_path = /status
ping.path = /ping
ping.response = pong
```
- **What it does:**
  - `/status`: Show PHP-FPM status (JSON)
  - `/ping`: Health check endpoint
- **Why:** Monitoring, debugging
- **For Inception:** ⚠️ **OPTIONAL**
  - Nice for debugging
  - Not used in your healthcheck (uses `pidof`)
  - Could be useful during defense
- **Verdict:** Keep for debugging, but not essential

```ini
php_admin_value[error_log] = /var/log/php8.2-fpm.log
php_admin_flag[log_errors] = on
```
- **What it does:** Enable PHP error logging
- **Why:** Debugging - see PHP errors/warnings
- **For Inception:** ✅ **VERY USEFUL**
  - Essential for debugging during development
  - Helps during evaluation if something breaks

```ini
php_value[session.save_handler] = files
php_value[session.save_path] = /var/lib/php/sessions
```
- **What it does:** Store sessions in files at specific path
- **Why:** Sessions needed for WordPress login
- **For Inception:** ✅ **ESSENTIAL**
  - WordPress users need sessions to stay logged in
  - Path must exist (you created it in Dockerfile)

```ini
php_value[soap.wsdl_cache_dir] = /var/lib/php/wsdlcache
```
- **What it does:** Cache for SOAP WSDL files
- **Why:** Performance for SOAP services
- **For Inception:** ❌ **UNNECESSARY**
  - You installed php-soap (also unnecessary)
  - WordPress doesn't use SOAP
  - Directory created but not needed
- **Simplify:** Remove this line (remove php-soap from Dockerfile too)

```ini
php_admin_value[disable_functions] = exec,passthru,shell_exec,system
```
- **What it does:** Disable dangerous PHP functions
- **Why:** Security - prevent command execution exploits
- **For Inception:** ✅ **EXCELLENT SECURITY**
  - Prevents shell injection attacks
  - WordPress doesn't need these functions
  - **This is a great security practice!**

```ini
php_admin_flag[allow_url_fopen] = off
```
- **What it does:** Disable opening remote files with fopen()
- **Why:** Security - prevent SSRF attacks
- **For Inception:** ⚠️ **TOO RESTRICTIVE**
  - WordPress NEEDS this for HTTP requests
  - WordPress uses `wp_remote_get()` which uses URL fopen
  - Plugin updates won't work without this
  - Theme installation will break
- **Fix:** Change to `php_admin_flag[allow_url_fopen] = on`
- **Security note:** WordPress has its own safeguards for HTTP requests

```ini
php_value[upload_max_filesize] = 64M
php_value[post_max_size] = 64M
```
- **What it does:** 
  - `upload_max_filesize`: Max file upload size
  - `post_max_size`: Max POST request size (should be ≥ upload size)
- **Why:** Allow media uploads (images, videos)
- **For Inception:** ✅ **ESSENTIAL**
  - Default is 2M (too small)
  - 64M allows large images and plugin zips
  - Matches NGINX `client_max_body_size`

```ini
php_value[max_execution_time] = 300
php_value[max_input_time] = 300
```
- **What it does:**
  - `max_execution_time`: Max script runtime (5 minutes)
  - `max_input_time`: Max time parsing input data (5 minutes)
- **Why:** Prevent scripts from running forever
- **For Inception:** ⚠️ **OVERKILL**
  - 300 seconds (5 minutes) is very generous
  - Default (30s) is usually enough
  - WordPress admin operations rarely take >1 minute
- **Simplify:** Change to `60` or `120`, or remove (use default 30s)

```ini
php_value[memory_limit] = 256M
```
- **What it does:** Max memory per PHP script
- **Why:** Prevent single script from using all RAM
- **For Inception:** ⚠️ **SLIGHTLY HIGH**
  - 256M is generous (WordPress default is 128M)
  - Most operations use 30-80MB
  - Image processing might use 100-150MB
- **Simplify:** Change to `128M` (WordPress standard)

```ini
catch_workers_output = yes
```
- **What it does:** Capture stdout/stderr from workers
- **Why:** See PHP echo/print statements in logs
- **For Inception:** ✅ **USEFUL** - Helps with debugging

```ini
clear_env = no
```
- **What it does:** Pass environment variables to PHP
- **Why:** WordPress needs environment variables (DB credentials, etc.)
- **For Inception:** ✅ **ESSENTIAL**
  - Default is `yes` (clears env vars)
  - WordPress won't see DB credentials without this
  - **Must be `no`!**

---

## File 3: install-wp.sh (Installation Script)

### Purpose
Automate WordPress download, configuration, installation, and start PHP-FPM.

### Line-by-Line Analysis

```bash
#!/bin/bash
```
- **What it does:** Shebang - run with bash
- **For Inception:** ✅ **ESSENTIAL**

```bash
set -e
```
- **What it does:** Exit on any error
- **Why:** Safety - don't continue if something fails
- **For Inception:** ✅ **GOOD PRACTICE**

```bash
MYSQL_PASSWORD=$(cat /run/secrets/mysql_pass)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_pass)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_pass)
```
- **What it does:** Read passwords from Docker secrets
- **Why:** Security - passwords not in environment or code
- **For Inception:** ✅ **EXCELLENT SECURITY** if using Docker secrets
- **BUT:** Check if docker-compose.yml actually uses secrets
  - If using env vars instead, change to:
  ```bash
  MYSQL_PASSWORD=${MYSQL_PASSWORD}
  WP_ADMIN_PASSWORD=${WP_ADMIN_PASSWORD}
  WP_USER_PASSWORD=${WP_USER_PASSWORD}
  ```

```bash
echo "Waiting for MariaDB to be ready..."
until mariadb -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
    echo "MariaDB is unavailable - sleeping"
    sleep 3
done
```
- **What it does:** Wait for MariaDB to be ready before proceeding
- **Why:** WordPress needs database, MariaDB takes time to start
- **For Inception:** ✅ **ESSENTIAL**
  - Without this, WordPress install fails
  - docker-compose `depends_on` only waits for container start, not readiness
  - This is proper dependency handling

```bash
cd /var/www/html
```
- **What it does:** Change to WordPress directory
- **Why:** WP-CLI commands need to run from WordPress root
- **For Inception:** ✅ **ESSENTIAL**

```bash
if [ ! -f "wp-config.php" ]; then
```
- **What it does:** Check if WordPress already installed
- **Why:** Only install once (important for persistent volumes!)
- **For Inception:** ✅ **CRITICAL**
  - Prevents re-installation on container restart
  - Preserves your data
  - Uses wp-config.php as marker (good choice)

```bash
    rm -rf /var/www/html/*
```
- **What it does:** Delete any existing files
- **Why:** Clean slate before WordPress download
- **For Inception:** ✅ **GOOD PRACTICE**
  - Ensures clean installation
  - Prevents file conflicts

```bash
    wp core download --allow-root
```
- **What it does:** Download latest WordPress files
- **Why:** Get WordPress core
- **For Inception:** ✅ **ESSENTIAL**
  - `--allow-root`: WP-CLI normally refuses root (we run as root in script)
  - Downloads latest stable version

```bash
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost=mariadb:3306 \
        --dbcharset="utf8mb4" \
        --dbcollate="utf8mb4_unicode_ci" \
        --allow-root
```
- **What it does:** Create wp-config.php with database credentials
- **Why:** WordPress needs this to connect to database
- **For Inception:** ✅ **ESSENTIAL**
  - `--dbhost=mariadb:3306`: Docker service name + port
  - `utf8mb4`: Proper emoji/international support
  - Creates the config file WordPress needs

```bash
    wp core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root
```
- **What it does:** Run WordPress installation (create tables, admin user)
- **Why:** Initialize WordPress database
- **For Inception:** ✅ **ESSENTIAL**
  - `--url`: Your domain (tforster.42.fr)
  - `--skip-email`: Don't try to send email (no mail server)
  - Creates wp_posts, wp_users tables, etc.

```bash
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=editor \
        --allow-root
```
- **What it does:** Create second WordPress user
- **Why:** Subject requires two users (admin + regular)
- **For Inception:** ✅ **SUBJECT REQUIREMENT**
  - Role: editor (can write posts, can't change settings)
  - Admin username NOT "admin" (subject forbids this)

```bash
else
    echo "WordPress already installed, skipping installation..."
fi
```
- **What it does:** Skip if already installed
- **Why:** Preserve existing installation
- **For Inception:** ✅ **ESSENTIAL**
  - Allows container restart without losing data
  - Shows understanding of persistent storage

```bash
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
```
- **What it does:** Set proper ownership and permissions
- **Why:** 
  - PHP-FPM runs as www-data
  - Needs write access for uploads, plugins, etc.
- **For Inception:** ✅ **ESSENTIAL**
  - Without this, WordPress can't upload files
  - `755`: owner can write, others can read

```bash
echo "Starting PHP-FPM..."
exec php-fpm8.2 -F
```
- **What it does:** Start PHP-FPM in foreground mode
- **Why:** Container must run foreground process
- **For Inception:** ✅ **ESSENTIAL**
  - `-F`: Foreground mode (not daemon)
  - `exec`: Replace shell with PHP-FPM (proper PID 1)
  - **Make sure version matches Dockerfile (8.2)**

---

## Summary: What's Essential vs Optional

### MUST KEEP

#### Dockerfile (Essential):
```dockerfile
FROM debian:11  # Match other containers

RUN apt-get update && \
    apt-get install -y \
    php7.4-fpm \
    php7.4-mysqli \
    php7.4-mbstring \
    php7.4-gd \
    php7.4-curl \
    php7.4-zip \
    php7.4-xml \
    mariadb-client \
    curl && \
    rm -rf /var/lib/apt/lists/*

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY tools/install-wp.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install-wp.sh

RUN mkdir -p /run/php && \
    mkdir -p /var/www/html && \
    mkdir -p /var/lib/php/sessions && \
    chown -R www-data:www-data /run/php /var/www/html /var/lib/php

WORKDIR /var/www/html
EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/install-wp.sh"]
```

#### www.conf (Essential):
```ini
[www]
user = www-data
group = www-data

listen = 0.0.0.0:9000

pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3

php_admin_flag[log_errors] = on

php_value[session.save_handler] = files
php_value[session.save_path] = /var/lib/php/sessions

php_admin_value[disable_functions] = exec,passthru,shell_exec,system

php_value[upload_max_filesize] = 64M
php_value[post_max_size] = 64M
php_value[memory_limit] = 128M

catch_workers_output = yes
clear_env = no
```

#### install-wp.sh:
**Keep entire script** - all parts are necessary.

**Fix:** Adjust for Docker secrets vs environment variables.

---

## Critical Issues to Fix

### 🔴 CRITICAL:

1. **www.conf line 33:** `allow_url_fopen = off` breaks WordPress
   - **Fix:** Change to `php_admin_flag[allow_url_fopen] = on`
   - WordPress NEEDS this for HTTP requests

2. **Version inconsistency:** PHP 8.2 (Debian 12) vs PHP 7.4 (Debian 11)
   - **Fix:** Either use Debian 11 + PHP 7.4 everywhere, OR Debian 12 + PHP 8.2 everywhere
   - Update all paths: `/etc/php/7.4/` or `/etc/php/8.2/`
   - Update script: `php-fpm7.4` or `php-fpm8.2`

3. **install-wp.sh Docker secrets:** Check if docker-compose.yml uses secrets
   - **If NO:** Change to environment variables
   - **If YES:** Make sure secrets are properly defined

### ⚠️ UNNECESSARY:

4. **Dockerfile:** Remove unused PHP extensions:
   - `php8.2-intl` (optional)
   - `php8.2-soap` (unnecessary)
   - `php8.2-bcmath` (unnecessary)
   - `wget` (redundant with curl)

5. **www.conf:** Oversized resource limits:
   - `pm.max_children = 10` → change to `5`
   - `memory_limit = 256M` → change to `128M`
   - `max_execution_time = 300` → change to `60`

6. **www.conf:** Optional features:
   - `pm.status_path` and `ping.path` (not used)
   - `soap.wsdl_cache_dir` (SOAP not needed)

---

## Minimal Configuration (Bare Bones)

### Dockerfile (Minimal):
```dockerfile
FROM debian:11

RUN apt-get update && \
    apt-get install -y \
    php7.4-fpm \
    php7.4-mysqli \
    php7.4-mbstring \
    php7.4-gd \
    php7.4-curl \
    php7.4-xml \
    mariadb-client \
    curl && \
    rm -rf /var/lib/apt/lists/*

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

COPY conf/www.conf /etc/php/7.4/fpm/pool.d/
COPY tools/install-wp.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install-wp.sh

RUN mkdir -p /run/php /var/www/html /var/lib/php/sessions && \
    chown -R www-data:www-data /run/php /var/www/html /var/lib/php

WORKDIR /var/www/html

ENTRYPOINT ["/usr/local/bin/install-wp.sh"]
```

### www.conf (Minimal):
```ini
[www]
user = www-data
group = www-data
listen = 0.0.0.0:9000

pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3

php_value[session.save_path] = /var/lib/php/sessions
php_value[upload_max_filesize] = 64M
php_value[post_max_size] = 64M

clear_env = no
```

### install-wp.sh:
Keep as-is, just fix secrets vs env vars.

---

## Recommended Configuration (Balanced)

### Dockerfile (Recommended):
```dockerfile
FROM debian:11

# Install PHP and WordPress requirements
RUN apt-get update && \
    apt-get install -y \
    php7.4-fpm \
    php7.4-mysqli \
    php7.4-mbstring \
    php7.4-gd \
    php7.4-curl \
    php7.4-zip \
    php7.4-xml \
    mariadb-client \
    curl && \
    rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Copy configuration and scripts
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY tools/install-wp.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install-wp.sh

# Create necessary directories
RUN mkdir -p /run/php /var/www/html /var/lib/php/sessions && \
    chown -R www-data:www-data /run/php /var/www/html /var/lib/php

WORKDIR /var/www/html
EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/install-wp.sh"]
```

### www.conf (Recommended):
```ini
[www]
user = www-data
group = www-data

# Network configuration
listen = 0.0.0.0:9000

# Process management
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 500

# Logging
php_admin_flag[log_errors] = on
php_admin_value[error_log] = /var/log/php7.4-fpm.log

# PHP session handling
php_value[session.save_handler] = files
php_value[session.save_path] = /var/lib/php/sessions

# Security
php_admin_value[disable_functions] = exec,passthru,shell_exec,system

# Upload limits
php_value[upload_max_filesize] = 64M
php_value[post_max_size] = 64M
php_value[max_execution_time] = 60
php_value[memory_limit] = 128M

# Debugging
catch_workers_output = yes

# Environment variables
clear_env = no
```

### install-wp.sh (Recommended):
```bash
#!/bin/bash
set -e

# Get passwords
# If using environment variables:
MYSQL_PASSWORD=${MYSQL_PASSWORD}
WP_ADMIN_PASSWORD=${WP_ADMIN_PASSWORD}
WP_USER_PASSWORD=${WP_USER_PASSWORD}

# Wait for MariaDB
echo "Waiting for MariaDB to be ready..."
until mariadb -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
    echo "MariaDB is unavailable - sleeping"
    sleep 3
done

echo "MariaDB is up and running!"

cd /var/www/html

# Install WordPress if not already installed
if [ ! -f "wp-config.php" ]; then
    echo "Downloading WordPress..."
    rm -rf /var/www/html/*
    
    wp core download --allow-root
    
    echo "Configuring WordPress..."
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost=mariadb:3306 \
        --dbcharset="utf8mb4" \
        --dbcollate="utf8mb4_unicode_ci" \
        --allow-root
    
    wp core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root
    
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=editor \
        --allow-root
    
    echo "WordPress installation complete!"
else
    echo "WordPress already installed, skipping installation..."
fi

# Set permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo "Starting PHP-FPM..."
exec php-fpm7.4 -F
```

---

## What to Remove

### From Dockerfile:
❌ `php8.2-intl` (optional)  
❌ `php8.2-soap` (unnecessary)  
❌ `php8.2-bcmath` (unnecessary)  
❌ `wget` (redundant)  
❌ Separate directory creation RUN commands (combine)  
❌ `/var/lib/php/wsdlcache` directory (SOAP cache not needed)  

### From www.conf:
❌ `pm.status_path` and `ping.path` (not used)  
❌ `soap.wsdl_cache_dir` (remove SOAP entirely)  
❌ `php_admin_flag[allow_url_fopen] = off` (breaks WordPress!)  

### Adjust in www.conf:
⚠️ `pm.max_children = 10` → `5`  
⚠️ `memory_limit = 256M` → `128M`  
⚠️ `max_execution_time = 300` → `60`  
⚠️ `max_input_time = 300` → `60`  

---

## PHP Version Decision

You need to decide on PHP version consistency:

### Option A: PHP 7.4 (Debian 11) - More Common
```
All containers: FROM debian:11
WordPress: php7.4-fpm
Paths: /etc/php/7.4/
Script: php-fpm7.4 -F
```

### Option B: PHP 8.2 (Debian 12) - More Modern
```
All containers: FROM debian:12
WordPress: php8.2-fpm
Paths: /etc/php/8.2/
Script: php-fpm8.2 -F
```

**Recommendation:** Use Option A (PHP 7.4) because:
- More examples online use PHP 7.4
- Debian 11 is what most 42 resources show
- More stable and tested
- But either works fine!

---

## Files Comparison

### Current vs Recommended Line Count:

| File | Current | Minimal | Recommended |
|------|---------|---------|-------------|
| Dockerfile | 55 lines | 26 lines | 31 lines |
| www.conf | 47 lines | 15 lines | 30 lines |
| install-wp.sh | 70 lines | 70 lines | 65 lines |
| **Total** | **172 lines** | **111 lines** | **126 lines** |

**Reduction:** From 172 to 126 lines (27% less code!)

---

## TL;DR - What to Do

### Critical Fixes:
1. ✅ Fix `allow_url_fopen = off` → should be `on` or remove line
2. ✅ Decide on PHP version and be consistent (7.4 or 8.2)
3. ✅ Match Debian version across all containers
4. ✅ Check Docker secrets vs environment variables

### Recommended Changes:
1. Remove unnecessary PHP extensions (intl, soap, bcmath)
2. Remove wget (use curl only)
3. Reduce resource limits (max_children, memory_limit)
4. Remove SOAP cache directory

### Optional Improvements:
1. Combine RUN commands (fewer layers)
2. Remove status/ping endpoints (not used)
3. Adjust timeouts to reasonable values

**Use the "Recommended" configuration** - it's clean, secure, and appropriate for Inception! 🎯
