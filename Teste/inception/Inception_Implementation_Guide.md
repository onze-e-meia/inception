**Comprehensive Inception Project Implementation Guide:**

Build a secure, production-grade Docker infrastructure for WordPress hosting by following his structured implementation roadmap. At each stage, ensure you can explain your choices and onfigurations to peers during evaluation.

---

## **PHASE 1: Environment Setup & Planning (Before Writing Code)**

**Pre-Implementation Tasks:**

- Set up a Virtual Machine (VM) with Docker and Docker Compose installed. Which Linux istribution will you use (Debian vs Alpine) and why does this choice matter for container ize and security?
- Design your docker-network architecture: What subnet will you use? How will containers iscover each other by service name?
- Plan your directory structure following the requirements (Makefile at root, srcs/ folder, equirements/ subdirectories). Create a skeleton structure before writing any Dockerfiles.
- Configure `/etc/hosts` or local DNS to resolve `[your-login].42.fr` to your localhost IP 127.0.0.1 or your VM's IP). Test this resolution works.
- Create a `.gitignore` to exclude `.env`, `secrets/`, and any credential files from version ontrol.

**Security Planning:**

- Generate TLS/SSL certificates for NGINX (self-signed for development). What are the ertificate requirements for TLSv1.2/1.3?
- Plan your secrets storage strategy: Will you use Docker secrets, a `secrets/` folder, or oth? Document the variables you'll need: DB_ROOT_PASSWORD, DB_USER, DB_PASSWORD, WP_ADMIN redentials.
- Choose strong, non-obvious administrator usernames that avoid 'admin', 'administrator', tc. Why is this important for security?

---

## **PHASE 2: Database Layer (MariaDB Container)**

**Implementation Steps:**

1.  **Dockerfile Creation** (`srcs/requirements/mariadb/Dockerfile`):
    - Start from Alpine or Debian (penultimate stable version - research which version this is
    - Install MariaDB server packages
    - Copy configuration files from `conf/` directory
    - Copy initialization scripts from `tools/` directory
    - **Critical:** Ensure the container runs `mysqld` as PID 1, not a wrapper script with nfinite loops
2.  **Database Initialization Script** (`tools/init-db.sh` or similar):
    - Create the WordPress database
    - Create two users: one administrator (non-obvious username), one regular user
    - Grant appropriate privileges
    - Use environment variables for all credentials - **never hardcode**
    - Set root password from environment variable
3.  **Configuration** (`conf/my.cnf` or `mariadb.cnf`):
    - Configure MariaDB to listen on the docker network (not just localhost)
    - Set appropriate character encoding (utf8mb4)
    - Optimize for container environment (limited resources)
4.  **docker-compose.yml Entry:**
    - Define the service name: `mariadb`
    - Map the database volume: `db-data:/var/lib/mysql`
    - Expose port 3306 **only to the docker network** (not to host)
    - Set environment variables from `.env` file
    - Configure restart policy: `always` or `unless-stopped`
5.  **Testing Checkpoint:**
    - Can you start the container alone? `docker-compose up mariadb`
    - Can you connect from within the container? `docker exec -it [container] mysql -u root -p
    - Are the WordPress database and users created correctly?
    - **Peer Review:** Explain to a classmate how the initialization script works

---

## **PHASE 3: Application Layer (WordPress + PHP-FPM Container)**

**Implementation Steps:**

1.  **Dockerfile Creation** (`srcs/requirements/wordpress/Dockerfile`):
    - Base image: Alpine/Debian (same choice as MariaDB for consistency)
    - Install PHP-FPM and required extensions (mysqli, mbstring, gd, curl, zip, etc.)
    - Install WordPress CLI (wp-cli) for automated configuration
    - Copy configuration files and initialization scripts
    - Configure PHP-FPM to listen on port 9000 (for NGINX connection)
    - **No NGINX in this container** - WordPress + PHP-FPM only
2.  **WordPress Installation Script** (`tools/install-wp.sh`):
    - Use wp-cli to download WordPress core
    - Generate wp-config.php with database credentials from environment variables
    - Set database host to `mariadb:3306` (service name in docker network)
    - Configure WordPress site URL to `https://[your-login].42.fr`
    - Create administrator user (with non-obvious username)
    - Create at least one additional regular user
    - Install and activate essential plugins/themes if needed
3.  **PHP-FPM Configuration** (`conf/www.conf`):
    - Configure pool to listen on `0.0.0.0:9000` (accessible to NGINX container)
    - Set appropriate user/group for file permissions
    - Tune worker processes for container environment
4.  **docker-compose.yml Entry:**
    - Service name: `wordpress`
    - Depends on: `mariadb` (ensures database starts first)
    - Map WordPress volume: `wp-data:/var/www/html`
    - Expose port 9000 to docker network
    - Pass environment variables for DB connection and WP configuration
5.  **Testing Checkpoint:**
    - Does WordPress install successfully? Check logs: `docker-compose logs wordpress`
    - Can PHP-FPM process PHP files? Test from within container
    - Are file permissions correct in `/var/www/html`?
    - **Peer Review:** Walk through your wp-config.php generation with a peer

---

## **PHASE 4: Web Server Layer (NGINX Container with TLS)**

**Implementation Steps:**

1.  **SSL Certificate Generation:**
    - Create self-signed certificate and key for `[your-login].42.fr`
    - Command: `openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout cert.key -out ert.crt`
    - Store in `srcs/requirements/nginx/conf/` or mount as secret
2.  **Dockerfile Creation** (`srcs/requirements/nginx/Dockerfile`):
    - Base image: Alpine/Debian NGINX
    - Copy SSL certificates
    - Copy NGINX configuration file
    - Expose port 443 only (no port 80)
    - Ensure NGINX runs in foreground as PID 1: `daemon off;` in config
3.  **NGINX Configuration** (`conf/nginx.conf` or `conf/default.conf`):
    - Listen on port 443 with `ssl`
    - Configure `ssl_protocols TLSv1.2 TLSv1.3;` (no TLSv1.0 or 1.1)
    - Point to SSL certificate and key
    - Set `server_name [your-login].42.fr;`
    - Configure `root /var/www/html;` (WordPress volume mount)
    - Set up FastCGI proxy to WordPress container:
      ```nginx
      location ~ \.php$ {
          fastcgi_pass wordpress:9000;
          fastcgi_index index.php;
          include fastcgi_params;
          fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
      }
      ```
    - Configure index: `index index.php index.html;`
4.  **docker-compose.yml Entry:**
    - Service name: `nginx`
    - Depends on: `wordpress`
    - Map WordPress volume (read-only recommended): `wp-data:/var/www/html:ro`
    - Port mapping: `443:443` (only port exposed to host)
    - Mount SSL certificates
5.  **Testing Checkpoint:**
    - Can you access `https://[your-login].42.fr` in a browser? (Expect SSL warning for elf-signed cert)
    - Does WordPress installation page appear? Or if already installed, does the site load?
    - Check SSL/TLS: `openssl s_client -connect [your-login].42.fr:443 -tls1_2`
    - Are only TLSv1.2/1.3 allowed? Test with: `openssl s_client -connect localhost:443 tls1_1` (should fail)
    - **Peer Review:** Show your NGINX config to a peer and explain the FastCGI setup

---

## **PHASE 5: Orchestration & Automation**

**docker-compose.yml Final Configuration:**

```yaml
version: "3.8"

services:
  mariadb:
    # ... configuration from Phase 2

  wordpress:
    # ... configuration from Phase 3

  nginx:
    # ... configuration from Phase 4

volumes:
  db-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/[your-login]/data/mysql

  wp-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/[your-login]/data/wordpress

networks:
  inception-network:
    driver: bridge
```

**Makefile Implementation:**
Create targets for:

- `make` or `make all`: Build images and start containers (`docker-compose up --build -d`)
- `make down`: Stop and remove containers (`docker-compose down`)
- `make clean`: Remove containers and images (`docker-compose down --rmi all`)
- `make fclean`: Clean everything including volumes (`docker-compose down -v --rmi all`)
- `make re`: Rebuild everything (`make fclean` then `make all`)
- `make logs`: Show container logs (`docker-compose logs -f`)

**.env File Structure:**

```bash
# Domain
DOMAIN_NAME=[your-login].42.fr

# MySQL/MariaDB
MYSQL_ROOT_PASSWORD=your_strong_root_password
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wp_user
MYSQL_PASSWORD=wp_password

# WordPress
WP_ADMIN_USER=your_admin_username  # Not 'admin'!
WP_ADMIN_PASSWORD=admin_password
WP_ADMIN_EMAIL=admin@example.com
WP_USER=regular_user
WP_USER_PASSWORD=user_password
WP_USER_EMAIL=user@example.com
```

---

## **PHASE 6: Validation & Testing**

**Functional Testing:**

1.  Run `make` - do all containers start successfully?
2.  Check container status: `docker-compose ps` (all should be "Up")
3.  Access `https://[your-login].42.fr` - does WordPress load?
4.  Can you log in with the administrator account?
5.  Can you log in with the regular user account?
6.  Create a test post/page - does it persist after restarting containers?
7.  Test container restart: `docker-compose restart` - does everything come back up utomatically?
8.  Simulate crash: `docker kill [container-name]` - does it auto-restart?

**Security Auditing:**

1.  Check for hardcoded passwords: `grep -r "password" srcs/` (should only find variable names
2.  Verify `.env` is in `.gitignore`: `git status` (should not show .env)
3.  Check exposed ports: `docker-compose ps` (only NGINX:443 should map to host)
4.  Verify TLS configuration: `nmap --script ssl-enum-ciphers -p 443 [your-login].42.fr`
5.  Check administrator username doesn't contain 'admin': Log into WordPress and verify

**Docker Best Practices Verification:**

1.  No 'latest' tags: `docker images` - check all images have explicit versions
2.  No infinite loops: Check each Dockerfile's CMD/ENTRYPOINT - should start service directly
3.  PID 1 correctness: `docker exec [container] ps aux` - is the main service PID 1?
4.  No prohibited networking: Check docker-compose.yml - no `network_mode: host` or `links:`
5.  Volume persistence: Check `/home/[your-login]/data/` - do files exist on host?

---

## **PHASE 7: Documentation & Peer Preparation**

**Understanding Verification (for Evaluation):**

- Can you explain what happens when you run `make`? Trace the entire startup sequence.
- What would happen if you changed the MariaDB port in docker-compose.yml? What else would eed to change?
- How does NGINX know where to find PHP files? Explain the volume mounting strategy.
- What's the difference between `docker-compose down` and `docker-compose down -v`?
- Why is it important that NGINX is the only exposed service?

**Peer Review Preparation:**

- Schedule a code review with a classmate - explain each Dockerfile line-by-line
- Have them ask "what if" questions about your configuration choices
- Practice explaining the network flow: Browser → NGINX (443) → WordPress (9000) → MariaDB 3306)

**Common Pitfalls to Document:**

- File permission issues in volumes (solved by setting correct user in Dockerfile)
- Container can't resolve other container names (solved by ensuring all use same network)
- WordPress shows database connection error (check environment variables and service ependencies)
- SSL certificate warnings in browser (expected for self-signed certs, but verify TLS ersion is correct)

---

## **PHASE 8: Bonus Features (Only After Mandatory Perfection)**

**If implementing bonus services, for each one:**

1.  Create a new Dockerfile in `srcs/requirements/bonus/[service-name]/`
2.  Add service to docker-compose.yml with appropriate configuration
3.  Update Makefile if needed
4.  Document how it integrates with existing services
5.  Prepare justification: "Why is this service useful for the infrastructure?"

**Bonus Service Suggestions with Implementation Hints:**

**Redis Cache:**

- Install Redis server in dedicated container
- Configure WordPress to use Redis for object caching (WP Redis plugin or `wp-config.php` ettings)
- Connect via docker network: `redis:6379`
- Verify cache hits: `redis-cli -h redis MONITOR`

**FTP Server:**

- Set up vsftpd or proftpd in container
- Point to WordPress volume: `/var/www/html`
- Configure passive mode ports
- Create FTP user with access to WordPress files
- Test connection: `ftp [your-login].42.fr [ftp-port]`

**Adminer:**

- Simple PHP-based database management
- Create lightweight container with Adminer + PHP
- Connect to MariaDB service
- Access via subdomain or different port

**Static Website:**

- Create HTML/CSS/JS site (no PHP)
- Serve via separate NGINX container or add to main NGINX config
- Good opportunity to showcase portfolio

---

## **AI Usage Strategy (Following Project Guidelines)**

**Where AI Can Help Efficiently:**

- Generating boilerplate Dockerfile syntax: "Show me basic Alpine Dockerfile for NGINX"
- Debugging specific error messages: "What does 'php-fpm failed to connect' mean?"
- Configuration file examples: "Example NGINX FastCGI configuration for WordPress"
- Shell script syntax: "How to check if MySQL is ready in bash?"

**Where You MUST Understand Deeply (Don't Just Copy):**

- Docker networking concepts - how do containers communicate?
- Volume mounting - where does data actually live?
- TLS/SSL configuration - what makes a connection secure?
- WordPress/database initialization - what's happening in the startup sequence?
- Security implications of each configuration choice

**Peer Review Checkpoints (Use Your Classmates!):**

- After completing each Dockerfile, review with a peer
- Before finalizing docker-compose.yml, explain service dependencies to someone
- If you used AI for any configuration, ensure you can explain every line to a peer
- Practice your defense presentation with a classmate

**Red Flags (Will Fail Evaluation):**

- Can't explain what a line in your Dockerfile does
- Don't understand why certain ports are exposed
- Can't troubleshoot when evaluator changes a small configuration
- Copy-pasted scripts without understanding their flow

---

## **Success Criteria Checklist**

**Before Submission:**

- [ ] All three containers start with `make` command
- [ ] WordPress accessible at `https://[your-login].42.fr`
- [ ] Two WordPress users exist (non-admin username for administrator)
- [ ] TLS certificate valid for TLSv1.2/1.3 only
- [ ] Volumes persist data at `/home/[your-login]/data/`
- [ ] No passwords in Dockerfiles - all use environment variables
- [ ] No 'latest' tags on images
- [ ] Containers auto-restart on crash
- [ ] `.env` and secrets excluded from Git
- [ ] All Dockerfiles build without warnings
- [ ] No infinite loops or hacky patches in startup commands
- [ ] Each service runs as PID 1 correctly

**For Evaluation:**

- [ ] Can explain every line of every Dockerfile
- [ ] Can trace network flow from browser to database
- [ ] Can modify configuration if evaluator requests small change
- [ ] Can troubleshoot common issues (connection refused, permission denied, etc.)
- [ ] Can justify all security decisions
- [ ] Peer reviewed all major configurations

---

## **Final Reflection Questions**

Before considering the project complete, answer these:

1.  If you had to deploy this to a real server, what would need to change?
2.  What's the weakest part of your implementation? How could it be improved?
3.  What was the most challenging technical decision you made, and why?
4.  How does this infrastructure compare to modern alternatives (Kubernetes, Docker Swarm)?
5.  What did you learn about Docker that surprised you?

**Remember:** The goal isn't just a working infrastructure—it's a deep understanding of ontainerization, networking, security, and system administration that you can explain and efend to peers.
