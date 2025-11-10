# Comprehensive Analysis: Inception Docker Infrastructure Project

## 1. Technical Architecture & Requirements

### Core Infrastructure Design

The project implements a **three-tier web application architecture** using Docker containers:

**Service Interaction Flow:**

```
Internet → NGINX (TLS:443) → WordPress+PHP-FPM → MariaDB
                ↓
         Docker Network (Internal)
                ↓
         Persistent Volumes
```

**Why Each Service Gets Its Own Container:**

1. **Single Responsibility Principle**: Each container should do one thing well. This mirrors the Unix philosophy and makes:
   - **Debugging easier**: If WordPress crashes, NGINX stays up
   - **Scaling independent**: Need more app servers? Replicate WordPress containers without touching the database
   - **Updates safer**: Update PHP version without rebuilding your entire stack

2. **Security Isolation**: If WordPress is compromised, the attacker doesn't automatically have database credentials or NGINX configuration access

3. **Resource Management**: You can set different CPU/memory limits per service based on actual needs

**TLS and Network Isolation Significance:**

- **TLSv1.2/1.3 Only**: Forces modern encryption, preventing downgrade attacks. Older protocols (SSLv3, TLSv1.0/1.1) have known vulnerabilities (POODLE, BEAST)

- **Port 443 as Sole Entry**: Creates a **single attack surface**. All traffic must pass through NGINX where you can implement:
  - Rate limiting
  - Request filtering
  - TLS termination
  - Header security policies

- **Prohibiting `--link` and `network: host`**:
  - `--link` is deprecated and creates tight coupling
  - `network: host` breaks container isolation, exposing services directly to the host network
  - Custom networks provide **DNS-based service discovery** and **IP isolation**

---

## 2. Docker Best Practices & Constraints

### The PID 1 Problem

**Why `tail -f`, `sleep infinity`, and infinite loops are forbidden:**

In Unix systems, **PID 1 has special responsibilities**:

- It must reap zombie processes (clean up terminated child processes)
- It receives signals (SIGTERM for graceful shutdown)
- When it exits, the container stops

**The Problem with Hacky Solutions:**

```dockerfile
# ❌ BAD: Keeps container alive but serves no purpose
CMD ["tail", "-f", "/dev/null"]

# ❌ BAD: Blocks signal handling
CMD ["bash", "-c", "while true; do sleep 1000; done"]
```

These approaches:

- Don't properly handle SIGTERM (containers won't shut down gracefully)
- Don't run your actual service as PID 1
- Create zombie processes if child processes fork

**The Correct Approach:**

```dockerfile
# ✅ GOOD: Run the actual daemon in foreground
CMD ["nginx", "-g", "daemon off;"]

# ✅ GOOD: PHP-FPM in foreground mode
CMD ["php-fpm", "-F"]

# ✅ GOOD: MariaDB without detaching
CMD ["mysqld"]
```

**Key Principle**: Your main process should run in the **foreground** as PID 1, so it receives signals directly and the container lifecycle matches the service lifecycle.

### Custom Dockerfiles vs Pre-Built Images

**Why Build Your Own:**

1. **Learning**: You understand every layer, every dependency
2. **Security**: No hidden backdoors or malicious code
3. **Size Optimization**: Include only what you need (Alpine base = ~5MB vs bloated pre-built images)
4. **Compliance**: You control exactly which packages and versions are installed
5. **Customization**: Tailor configuration for your specific requirements

**Real-World Parallel**: In production, you'd likely use official images but heavily customize them. This project teaches you the fundamentals.

### Docker Volumes vs Container Storage

**Container Storage (Ephemeral Layer)**:

- Lives with the container
- **Deleted when container is removed**
- Uses copy-on-write filesystem
- Slower performance

**Volumes (Persistent Storage)**:

```yaml
volumes:
  wordpress_data:
  mariadb_data:
```

**Why Separate Volumes:**

1. **Data Persistence**: Survive container recreation/updates
2. **Performance**: Direct host filesystem access (no copy-on-write overhead)
3. **Backup/Migration**: Easy to snapshot/transfer
4. **Sharing**: Multiple containers can mount the same volume (e.g., NGINX serving static files from WordPress volume)

**Critical for This Project:**

- **MariaDB volume**: Your database must survive WordPress updates
- **WordPress volume**: Your uploaded media, themes, plugins persist

---

## 3. Security & Configuration Management

### Multi-Layered Security Strategy

**Layer 1: Dockerfile Exclusion**

```dockerfile
# ❌ NEVER DO THIS
ENV MYSQL_ROOT_PASSWORD=supersecret123
```

Why? Dockerfiles are:

- Committed to version control (GitHub)
- Visible in image layers (`docker history`)
- Shared with teams/public

**Layer 2: Environment Variables**

```yaml
# docker-compose.yml
environment:
  - MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
```

Better, but still visible in:

- `docker inspect`
- Container environment (`docker exec env`)

**Layer 3: Docker Secrets (Best Practice)**

```yaml
secrets:
  db_root_password:
    file: ./secrets/db_root_password.txt

services:
  mariadb:
    secrets:
      - db_root_password
```

**Inside container**: Secret appears at `/run/secrets/db_root_password` (tmpfs, RAM-only, not written to disk)

**Security Progression**:

```
Hardcoded < Environment Variables < Secrets < Vault Solutions
(BAD)        (OK for dev)          (GOOD)     (Production)
```

### Username Prohibition Rationale

**Why ban 'admin', 'administrator', etc.:**

1. **Brute Force Prevention**: These are the **first usernames** tried in attacks

   ```
   admin/admin
   admin/password123
   administrator/admin
   ```

2. **Enumeration Attacks**: WordPress exposes author URLs (`/author/admin/`), revealing valid usernames

3. **Security Through Obscurity** (Secondary): Using `johndoe` or `webmaster` isn't inherently more secure, but it's not in common brute-force dictionaries

**Better Practice**:

- Use non-obvious usernames
- Implement rate limiting
- Enable 2FA
- Use strong passwords (via secrets)

### The 'latest' Tag Problem

**Why `latest` is Prohibited:**

```dockerfile
# ❌ BAD: What version is this? Who knows!
FROM nginx:latest
```

**Problems:**

1. **Non-Reproducible Builds**: `latest` changes over time. Your working build today may break tomorrow
2. **Debugging Nightmares**: "It worked on my machine" - yeah, because you pulled `latest` at different times
3. **Security Auditing**: Can't track which vulnerabilities affect your deployment
4. **Rollback Issues**: Can't revert to a specific known-good version

**Correct Approach:**

```dockerfile
# ✅ GOOD: Pin to specific versions
FROM alpine:3.18
FROM nginx:1.24-alpine
FROM mariadb:10.11
```

**Versioning Strategy:**

- Use **semantic versioning**: `major.minor.patch`
- Pin to **minor versions** for stability with security patches
- Test updates in dev before promoting to production

---

## 4. Implementation Challenges & Solutions

### Local Domain Configuration

**The Challenge**: Make `wil.42.fr` resolve to your local VM

**Solution Layers:**

1. **Host File Method** (`/etc/hosts`):

```bash
# On host machine
echo "127.0.0.1 wil.42.fr" >> /etc/hosts
```

2. **Local DNS Server** (Better for team environments):
   - Use `dnsmasq` or similar
   - Configure wildcard: `*.42.fr → 192.168.x.x`

3. **VM-Specific Configuration**:

```bash
# Inside VM, if using different IP
echo "192.168.56.10 wil.42.fr" >> /etc/hosts
```

**Why This Matters:**

- **Simulates Production**: Your production site has a real domain; this teaches DNS/routing concepts
- **TLS Certificate Generation**: You need a domain for proper SSL certificates (even self-signed)
- **Browser Behavior**: Tests same-origin policy, cookie scoping, HTTPS enforcement

**Production Parallel**:

```
Development: /etc/hosts → Local IP
Staging: Internal DNS → Private IP
Production: Public DNS → Load Balancer IP
```

### Project Directory Structure Strategy

**Optimal Layout:**

```
inception/
├── Makefile                    # Orchestrates everything
├── secrets/                    # Git-ignored credentials
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── wordpress_admin.txt
└── srcs/
    ├── docker-compose.yml      # Service definitions
    ├── .env                    # Non-sensitive config
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── nginx.conf
        │   └── tools/
        │       └── entrypoint.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── www.conf
        │   └── tools/
        │       └── setup-wp.sh
        └── mariadb/
            ├── Dockerfile
            ├── conf/
            │   └── 50-server.cnf
            └── tools/
                └── init-db.sh
```

**Rationale:**

- **Separation of Concerns**: Each service is self-contained
- **Reusability**: Services can be easily extracted for other projects
- **Security**: Secrets directory is clearly marked for `.gitignore`
- **Clarity**: File paths clearly indicate purpose (`requirements/nginx/conf/`)

**Makefile Design Pattern:**

```makefile
all: up

up:
	@mkdir -p /home/$(USER)/data/wordpress
	@mkdir -p /home/$(USER)/data/mariadb
	@docker-compose -f srcs/docker-compose.yml up -d --build

down:
	@docker-compose -f srcs/docker-compose.yml down

clean: down
	@docker system prune -af
	@rm -rf /home/$(USER)/data

re: clean all
```

### Automatic Container Restart Strategy

**The Right Way:**

```yaml
# docker-compose.yml
services:
  nginx:
    restart: unless-stopped # or 'always'
    healthcheck:
      test: ["CMD", "curl", "-f", "https://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3
```

**Restart Policies:**

- `no`: Never restart (default)
- `always`: Always restart (even after manual stop, on daemon restart)
- `on-failure`: Restart only on error exit codes
- `unless-stopped`: Like always, but respects manual stops

**Why Health Checks Matter:**

```yaml
mariadb:
  healthcheck:
    test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
    interval: 10s
    timeout: 5s
    retries: 5
    start_period: 30s # Grace period for initialization
```

This ensures:

- **Dependent services wait**: WordPress doesn't start until MariaDB is truly ready (not just "container started")
- **Automatic recovery**: If MariaDB crashes during operation, Docker notices and restarts it
- **Monitoring integration**: External tools can query container health status

**What This Prevents:**

```
❌ Without health checks:
  MariaDB container starts → WordPress tries to connect → Connection refused → WordPress crashes

✅ With health checks:
  MariaDB container starts → Waits for actual mysqld ready → Health check passes → WordPress starts
```
