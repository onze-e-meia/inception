# NGINX Configuration Deep Dive - Inception Project

## Overview

You have **TWO** NGINX configuration files:

1. **`nginx.conf`** - Main/global NGINX configuration
2. **`default.conf`** - Server block (virtual host) configuration

**Do you need both?** YES, but they can be simplified significantly.

---

## File 1: nginx.conf (Main Configuration)

### Purpose
This is the **main NGINX configuration file**. It sets global settings that apply to the entire NGINX instance.

### Line-by-Line Analysis

```nginx
user www-data;
```
- **What it does:** Tells NGINX to run worker processes as the `www-data` user
- **Why:** Security - NGINX master runs as root, but workers run as unprivileged user
- **For Inception:** ✅ **ESSENTIAL** - Needed for proper permissions with WordPress files

```nginx
worker_processes auto;
```
- **What it does:** Sets number of worker processes (auto = one per CPU core)
- **Why:** Performance optimization for multi-core systems
- **For Inception:** ⚠️ **OPTIONAL** - Default is 1, which is fine for this project
- **Simplify:** Can remove, default is sufficient

```nginx
pid /run/nginx.pid;
```
- **What it does:** Location where NGINX stores its process ID
- **Why:** Used by init systems and for process management
- **For Inception:** ⚠️ **OPTIONAL** - Default location works fine
- **Simplify:** Can remove

```nginx
error_log /var/log/nginx/error.log warn;
```
- **What it does:** Where to write error logs and minimum severity level
- **Why:** Debugging and monitoring
- **For Inception:** ✅ **USEFUL** - Helps debug issues during evaluation
- **Keep this**

```nginx
events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}
```
- **What it does:**
  - `worker_connections 1024`: Max simultaneous connections per worker
  - `use epoll`: Linux-specific efficient event mechanism
  - `multi_accept on`: Accept multiple connections at once
- **Why:** Performance tuning for high-traffic sites
- **For Inception:** ❌ **OVERKILL** 
  - You'll have 1-2 evaluators connecting, not 1024 simultaneous users
  - Default (512 connections) is more than enough
- **Simplify:** Keep only `worker_connections 1024;` or remove entire block (uses defaults)

```nginx
http {
```
- **What it does:** Starts the HTTP configuration block
- **For Inception:** ✅ **ESSENTIAL** - Everything else goes inside this

```nginx
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
```
- **What it does:** 
  - `sendfile`: Efficient file serving (kernel-level)
  - `tcp_nopush`: Send headers in one packet
  - `tcp_nodelay`: Don't buffer small packets
- **Why:** Performance optimizations for file transfer
- **For Inception:** ⚠️ **OPTIONAL** - Marginal benefit for small WordPress site
- **Simplify:** Can remove all three, defaults work fine

```nginx
    keepalive_timeout 65;
```
- **What it does:** How long to keep connections open (in seconds)
- **Why:** Reduces overhead of opening new connections
- **For Inception:** ⚠️ **OPTIONAL** - Default (75s) is fine
- **Simplify:** Can remove

```nginx
    types_hash_max_size 2048;
```
- **What it does:** Hash table size for MIME types
- **Why:** Performance for sites with many file types
- **For Inception:** ❌ **UNNECESSARY** - WordPress uses standard types
- **Simplify:** Remove

```nginx
    server_tokens off;
```
- **What it does:** Hides NGINX version in error pages and headers
- **Why:** Security - don't reveal version to attackers
- **For Inception:** ✅ **GOOD PRACTICE** - Easy security win
- **Keep this**

```nginx
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
```
- **What it does:**
  - Include file that maps extensions to MIME types (.jpg → image/jpeg)
  - Default MIME type if file extension unknown
- **Why:** Browsers need correct content types
- **For Inception:** ✅ **ESSENTIAL** - WordPress needs proper MIME types for images, CSS, JS
- **Keep both**

```nginx
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
```
- **What it does:** 
  - Only allow TLS 1.2 and 1.3 (no older, insecure protocols)
  - Server chooses cipher (not client)
  - List of allowed encryption ciphers
- **Why:** Security - modern encryption only
- **For Inception:** ✅ **ESSENTIAL** - Subject REQUIRES TLSv1.2/1.3 only!
- **Keep this - it's a requirement!**

```nginx
    access_log /var/log/nginx/access.log;
```
- **What it does:** Log every request
- **Why:** Debugging, analytics, monitoring
- **For Inception:** ✅ **USEFUL** - Helps show evaluator that connections work
- **Keep this**

```nginx
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;
```
- **What it does:** Compress responses to save bandwidth
- **Why:** Performance - smaller files = faster page loads
- **For Inception:** ❌ **OVERKILL** 
  - You're on localhost/local network - speed isn't an issue
  - Adds CPU overhead
  - Cool to have but not needed
- **Simplify:** Can remove entire gzip block

```nginx
    include /etc/nginx/conf.d/*.conf;
}
```
- **What it does:** Load all `.conf` files from conf.d directory (your `default.conf`)
- **Why:** Organize configs - one file per website/service
- **For Inception:** ✅ **ESSENTIAL** - This loads your server block!
- **Keep this**

---

## File 2: default.conf (Server Block)

### Purpose
This defines your **virtual host** - the actual WordPress website configuration.

### Line-by-Line Analysis

```nginx
server {
```
- **What it does:** Start a server block (virtual host)
- **For Inception:** ✅ **ESSENTIAL**

```nginx
    listen 443 ssl;
    listen [::]:443 ssl;
```
- **What it does:**
  - Listen on port 443 (HTTPS) with SSL enabled
  - Second line is IPv6 version
- **Why:** HTTPS is required
- **For Inception:** ✅ **ESSENTIAL** - Subject requires HTTPS
- **Note:** Could remove IPv6 line if not needed, but harmless to keep

```nginx
    server_name tforster.42.fr;
```
- **What it does:** Domain name this server block responds to
- **Why:** If NGINX has multiple sites, it knows which config to use
- **For Inception:** ✅ **ESSENTIAL** - Required by subject (login.42.fr format)

```nginx
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
```
- **What it does:** Location of SSL certificate and private key
- **Why:** HTTPS requires certificates
- **For Inception:** ✅ **ESSENTIAL** - No HTTPS without these

```nginx
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
```
- **What it does:** Same as in nginx.conf
- **Why:** Can override global settings per-site
- **For Inception:** ⚠️ **DUPLICATE** 
  - You already have this in nginx.conf
  - Doesn't hurt to have here, but redundant
- **Simplify:** Can remove from here if it's in nginx.conf

```nginx
    root /var/www/html;
    index index.php index.html index.htm;
```
- **What it does:**
  - `root`: Where website files are located
  - `index`: What file to serve for directory requests
- **Why:** NGINX needs to know where files are
- **For Inception:** ✅ **ESSENTIAL** - Must point to WordPress directory

```nginx
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
```
- **What it does:** Security headers to protect against various attacks:
  - `X-Frame-Options`: Prevent clickjacking (can't embed in iframe from other sites)
  - `X-Content-Type-Options`: Prevent MIME-type sniffing
  - `X-XSS-Protection`: Enable browser XSS filter
  - `Referrer-Policy`: Control referrer information
- **Why:** Defense in depth security
- **For Inception:** ⚠️ **GOOD PRACTICE but OPTIONAL**
  - Cool security features
  - Not strictly required for basic functionality
  - Shows you understand security
- **Verdict:** Nice to have, but can remove if simplifying

```nginx
    client_max_body_size 64M;
```
- **What it does:** Maximum upload file size (for images, themes, plugins)
- **Why:** Default is 1MB - too small for WordPress media uploads
- **For Inception:** ✅ **USEFUL** - WordPress users will upload images
- **Keep this**

```nginx
    access_log /var/log/nginx/wordpress_access.log;
    error_log /var/log/nginx/wordpress_error.log;
```
- **What it does:** Per-site logs (separate from global logs)
- **Why:** Easier debugging when you have multiple sites
- **For Inception:** ⚠️ **OPTIONAL**
  - You only have one site
  - Global logs in nginx.conf are sufficient
- **Simplify:** Can remove and rely on global logs

```nginx
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
```
- **What it does:** For any request:
  1. Try to find the exact file (`$uri`)
  2. Try to find a directory (`$uri/`)
  3. If neither exist, route to index.php (WordPress handles it)
- **Why:** WordPress uses "pretty URLs" (/blog/my-post instead of ?p=123)
- **For Inception:** ✅ **ESSENTIAL** - WordPress won't work without this

```nginx
    location ~ \.php$ {
        try_files $uri =404;
```
- **What it does:** Handle all PHP files
  - First line: Return 404 if PHP file doesn't exist (security)
- **Why:** Prevent NGINX from passing fake requests to PHP-FPM
- **For Inception:** ✅ **ESSENTIAL** - WordPress is PHP

```nginx
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
```
- **What it does:** Split URL into script name and path info
  - Example: `/index.php/foo/bar` → script: `/index.php`, path: `/foo/bar`
- **Why:** Some apps use this, WordPress sometimes does
- **For Inception:** ⚠️ **OPTIONAL** - WordPress rarely uses this pattern
- **Simplify:** Can remove, but harmless

```nginx
        fastcgi_pass wordpress:9000;
```
- **What it does:** Send PHP requests to WordPress container on port 9000
- **Why:** PHP-FPM (WordPress) listens there
- **For Inception:** ✅ **ESSENTIAL** - This is how NGINX talks to WordPress!

```nginx
        fastcgi_index index.php;
```
- **What it does:** Default file if directory requested
- **Why:** Fallback for edge cases
- **For Inception:** ⚠️ **OPTIONAL** - `try_files` already handles this
- **Simplify:** Can remove

```nginx
        include fastcgi_params;
```
- **What it does:** Include standard FastCGI parameters (like environment variables)
- **Why:** PHP needs these to work properly
- **For Inception:** ✅ **ESSENTIAL** - PHP won't work without these

```nginx
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param HTTPS on;
```
- **What it does:**
  - `SCRIPT_FILENAME`: Full path to PHP script
  - `PATH_INFO`: Additional path after script name
  - `HTTPS on`: Tell PHP we're using HTTPS
- **Why:** PHP needs to know these things
- **For Inception:** ✅ **ESSENTIAL** (especially SCRIPT_FILENAME and HTTPS)
  - `PATH_INFO` less critical
- **Keep:** SCRIPT_FILENAME and HTTPS at minimum

```nginx
        fastcgi_buffering on;
        fastcgi_buffer_size 4k;
        fastcgi_buffers 8 4k;
        fastcgi_busy_buffers_size 8k;
```
- **What it does:** Configure memory buffers for PHP responses
- **Why:** Performance tuning - buffer responses before sending
- **For Inception:** ❌ **OVERKILL**
  - Default buffering works fine
  - These are for high-traffic sites
- **Simplify:** Remove entire buffering block

```nginx
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 300s;
        fastcgi_read_timeout 300s;
```
- **What it does:** Timeouts for PHP-FPM communication
- **Why:** Prevent hanging if PHP is slow
- **For Inception:** ⚠️ **OPTIONAL but USEFUL**
  - Default timeouts are shorter
  - WordPress admin can be slow sometimes
- **Verdict:** Can keep 60s timeouts or remove (defaults usually fine)

```nginx
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
```
- **What it does:** Block access to hidden files (.htaccess, .git, etc.)
- **Why:** Security - don't expose sensitive files
- **For Inception:** ✅ **GOOD SECURITY PRACTICE**
  - Protects against info disclosure
- **Keep this**

```nginx
    location ~* wp-config.php {
        deny all;
    }
```
- **What it does:** Block direct access to WordPress config file
- **Why:** Contains database credentials!
- **For Inception:** ✅ **IMPORTANT SECURITY**
  - Prevents credential theft
- **Keep this**

```nginx
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
```
- **What it does:** Cache static files for 30 days
- **Why:** Performance - browser doesn't re-download images every time
- **For Inception:** ❌ **UNNECESSARY**
  - Localhost/local network is fast already
  - Cache can actually make development annoying
- **Simplify:** Remove

---

## Summary: What's Essential vs Optional

### MUST KEEP (Core Functionality)

#### nginx.conf:
```nginx
user www-data;
error_log /var/log/nginx/error.log warn;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    
    access_log /var/log/nginx/access.log;
    server_tokens off;
    
    include /etc/nginx/conf.d/*.conf;
}
```

#### default.conf:
```nginx
server {
    listen 443 ssl;
    server_name tforster.42.fr;
    
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    
    root /var/www/html;
    index index.php index.html;
    
    client_max_body_size 64M;
    
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass wordpress:9000;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTPS on;
    }
    
    location ~ /\. {
        deny all;
    }
    
    location ~* wp-config.php {
        deny all;
    }
}
```

### NICE TO HAVE (Good Practice)

- Security headers (X-Frame-Options, etc.)
- `server_tokens off`
- Hidden file blocking
- wp-config.php blocking

### CAN REMOVE (Overkill)

- Gzip compression
- Static file caching
- FastCGI buffering tuning
- Specific performance optimizations (tcp_nopush, sendfile, etc.)
- Separate log files per site
- Long FastCGI timeouts

---

## Minimal Configuration (Bare Bones)

If you want the absolute minimum for Inception:

### nginx.conf (Minimal):
```nginx
user www-data;

events {
    worker_connections 512;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # REQUIRED BY SUBJECT
    ssl_protocols TLSv1.2 TLSv1.3;
    
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    include /etc/nginx/conf.d/*.conf;
}
```

### default.conf (Minimal):
```nginx
server {
    listen 443 ssl;
    server_name tforster.42.fr;
    
    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    
    # WordPress Root
    root /var/www/html;
    index index.php;
    
    # WordPress Permalinks
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    # PHP Processing
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass wordpress:9000;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTPS on;
    }
}
```

**This minimal config:**
- ✅ Meets all Inception requirements
- ✅ Serves WordPress correctly
- ✅ Uses TLSv1.2/1.3 only
- ✅ ~30 lines total (vs your current ~130)

---

## Recommended Configuration (Balanced)

Best balance of simplicity and good practices:

### nginx.conf (Recommended):
```nginx
user www-data;
error_log /var/log/nginx/error.log warn;

events {
    worker_connections 1024;
}

http {
    # Basic Settings
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    server_tokens off;
    
    # SSL Settings (REQUIRED)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    
    # Logging
    access_log /var/log/nginx/access.log;
    
    # Load Virtual Hosts
    include /etc/nginx/conf.d/*.conf;
}
```

### default.conf (Recommended):
```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    
    server_name tforster.42.fr;
    
    # SSL Certificates
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    
    # WordPress Configuration
    root /var/www/html;
    index index.php index.html;
    
    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Max Upload Size
    client_max_body_size 64M;
    
    # WordPress Permalinks
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    # PHP Processing via FastCGI
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass wordpress:9000;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTPS on;
    }
    
    # Security: Block Hidden Files
    location ~ /\. {
        deny all;
    }
    
    # Security: Block wp-config.php
    location ~* wp-config.php {
        deny all;
    }
}
```

**This recommended config:**
- ✅ All requirements met
- ✅ Good security practices
- ✅ ~55 lines (still half your current size)
- ✅ Clean and readable
- ✅ Shows you understand NGINX

---

## Why Two Files?

**Q: Can't I put everything in one file?**

A: Technically yes, but two files is better practice:

1. **Separation of Concerns:**
   - `nginx.conf` = global settings (affect all sites)
   - `default.conf` = specific site settings (just WordPress)

2. **Scalability:**
   - Easy to add more sites: just create `site2.conf`, `site3.conf`
   - Don't need to edit main config

3. **Standard Practice:**
   - This is how production servers are configured
   - Evaluators expect this structure

**For Inception:** Keep two files - it's the right way to do it.

---

## TL;DR - What to Do

### Option 1: Use Your Current Config ✅
**Verdict:** It works and shows you did research. Nothing is broken.

### Option 2: Use Recommended Config (Balanced) ⭐
**Verdict:** Best choice - removes bloat but keeps important features.

### Option 3: Use Minimal Config (Bare Bones)
**Verdict:** Works but looks too simple. Might lose points for lack of security.

---

## Final Recommendation

**Use the "Recommended" configuration above.**

**Why:**
1. ✅ Meets all subject requirements
2. ✅ Shows security awareness
3. ✅ Clean and understandable
4. ✅ Not over-engineered
5. ✅ Easy to explain during evaluation

**What to change in your current files:**

Remove from **nginx.conf**:
- `pid` line
- `worker_processes auto` (or keep, not harmful)
- `use epoll` and `multi_accept`
- `sendfile`, `tcp_nopush`, `tcp_nodelay`
- `keepalive_timeout`
- `types_hash_max_size`
- Entire `gzip` block

Remove from **default.conf**:
- Duplicate SSL protocol settings (keep in nginx.conf)
- Per-site logging
- `fastcgi_split_path_info`
- `fastcgi_index`
- `PATH_INFO` fastcgi_param
- Entire FastCGI buffering block
- Timeout settings
- Static file caching block

**Result:** Clean, professional configuration that's easy to explain! 🎯
