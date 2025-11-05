# Inception - Docker Infrastructure Project

A complete Docker-based infrastructure hosting WordPress with NGINX and MariaDB, built according to 42 School project specifications.

## Project Structure

```
inception/
├── Makefile                      # Build automation
├── secrets/                      # Secret credentials (git-ignored)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── wp_admin_password.txt
└── srcs/
    ├── docker-compose.yml        # Service orchestration
    ├── .env                      # Environment variables (git-ignored)
    └── requirements/
        ├── mariadb/              # MariaDB container
        │   ├── Dockerfile
        │   ├── conf/50-server.cnf
        │   └── tools/init-db.sh
        ├── wordpress/            # WordPress + PHP-FPM container
        │   ├── Dockerfile
        │   ├── conf/www.conf
        │   └── tools/install-wp.sh
        └── nginx/                # NGINX with TLS container
            ├── Dockerfile
            ├── conf/
            │   ├── nginx.conf
            │   ├── default.conf
            │   ├── nginx.crt
            │   └── nginx.key
            └── tools/
```

## Architecture

- **NGINX**: Reverse proxy with TLSv1.2/1.3 only, serving on port 4443 (mapped from internal 443)
- **WordPress**: PHP 7.4-FPM with WordPress CLI, accessible only via NGINX
- **MariaDB**: Database server with two users (admin + regular)
- **Volumes**: Persistent storage for WordPress files and MariaDB data
- **Network**: Custom bridge network for inter-container communication

## Prerequisites

- Docker Engine
- Docker Compose V2
- Make

## Installation & Usage

### 1. Configure Domain Resolution

Add the following line to `/etc/hosts` (requires sudo):

```bash
127.0.0.1 tforster.42.fr
```

### 2. Build and Start

```bash
# Build images and start all containers
make

# Or step by step:
make build    # Build Docker images
make up       # Start containers
```

### 3. Access WordPress

Open your browser and navigate to:
```
https://tforster.42.fr:4443
```

**Note**: You'll see a security warning due to self-signed certificate. This is expected for development.

### 4. WordPress Credentials

- **Admin User**: `wpmaster`
- **Admin Password**: Check `srcs/.env` file
- **Admin Email**: `wpmaster@example.com`

- **Regular User**: `content_editor`
- **Regular Password**: Check `srcs/.env` file

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make` or `make all` | Build and start all containers (default) |
| `make up` | Start containers |
| `make build` | Build Docker images |
| `make down` | Stop containers |
| `make clean` | Stop containers and remove images |
| `make fclean` | Full cleanup (containers, images, volumes, data) |
| `make re` | Rebuild everything from scratch |
| `make logs` | Show container logs (follow mode) |
| `make ps` | Show container status |
| `make status` | Show detailed Docker status |

## Key Features & Design Decisions

### Security

- ✅ **TLS 1.2/1.3 Only**: Modern encryption, no legacy protocols
- ✅ **No Passwords in Dockerfiles**: All credentials via environment variables
- ✅ **Non-admin Usernames**: Admin user is 'wpmaster' (not 'admin')
- ✅ **Secret Management**: Passwords stored in git-ignored files
- ✅ **Network Isolation**: Services communicate via custom network
- ✅ **Single Entry Point**: Only NGINX exposed to host

### Docker Best Practices

- ✅ **No `latest` Tags**: All images use specific versions (Debian 11)
- ✅ **PID 1 Correctly Handled**: Services run as PID 1 (no tail -f hacks)
- ✅ **Foreground Daemons**: NGINX and PHP-FPM run in foreground mode
- ✅ **Health Checks**: All containers have health monitoring
- ✅ **Automatic Restart**: Containers restart on failure
- ✅ **Custom Dockerfiles**: All images built from scratch (no pre-built)

### Service Configuration

**MariaDB**:
- Listens on 0.0.0.0 (accessible to Docker network)
- UTF8MB4 character encoding
- Optimized for container environment
- Automatic database initialization

**WordPress**:
- PHP-FPM on port 9000
- WP-CLI for automated installation
- Waits for MariaDB to be ready
- Persistent file storage

**NGINX**:
- TLS-only configuration
- FastCGI proxy to WordPress
- Security headers enabled
- Static file caching

## Important Notes

### Port Configuration

The project uses **port 4443** instead of 443 because:
- Docker is running in rootless mode
- Ports <1024 require root privileges
- Port 4443 maps to internal container port 443

For production deployment with proper privileges, change in `docker-compose.yml`:
```yaml
ports:
  - "443:443"  # Instead of ""
```

### Data Persistence

Data is stored in Docker volumes:
- MariaDB: `/var/lib/docker/volumes/srcs_mariadb-data`
- WordPress: `/var/lib/docker/volumes/srcs_wordpress-data`

To completely reset (WARNING: deletes all data):
```bash
make fclean
```

### Environment Variables

Edit `srcs/.env` to customize:
- Domain name
- Database credentials
- WordPress admin credentials
- User credentials

**Remember**: Never commit `.env` to version control!

## Troubleshooting

### Containers won't start

```bash
# Check logs
make logs

# Check container status
docker ps -a

# Restart from scratch
make re
```

### Can't access WordPress

1. Verify all containers are running: `make ps`
2. Check NGINX logs: `docker logs nginx`
3. Ensure `/etc/hosts` is configured
4. Try accessing: `https://localhost:4443`

### Database connection errors

1. Check MariaDB is healthy: `docker ps`
2. View MariaDB logs: `docker logs mariadb`
3. Verify environment variables in `srcs/.env`

### Permission errors

```bash
# Reset volumes and data
make fclean
make
```

## Testing Checklist

- [ ] All three containers start successfully
- [ ] WordPress accessible at https://tforster.42.fr:4443
- [ ] Can log in with admin user (wpmaster)
- [ ] Can log in with regular user (content_editor)
- [ ] Can create and publish posts
- [ ] Data persists after `make down && make up`
- [ ] Containers auto-restart after crash
- [ ] No passwords in Dockerfiles
- [ ] TLS certificate valid for TLSv1.2/1.3

## Compliance with Subject Requirements

| Requirement | Status | Implementation |
|-------------|--------|----------------|
| Three separate containers | ✅ | NGINX, WordPress, MariaDB |
| TLSv1.2/1.3 only | ✅ | NGINX SSL configuration |
| Custom Dockerfiles | ✅ | All services built from Debian 11 |
| No pre-built images | ✅ | Only Alpine/Debian base allowed |
| No `latest` tag | ✅ | Explicit version: debian:11 |
| Environment variables | ✅ | All config via .env file |
| Docker secrets | ✅ | Passwords in secrets/ folder |
| Two volumes | ✅ | MariaDB data + WordPress files |
| Custom network | ✅ | inception-network (bridge) |
| Auto-restart | ✅ | restart: unless-stopped |
| No infinite loops | ✅ | Services run as PID 1 |
| No hacky patches | ✅ | Proper daemon management |
| WordPress users | ✅ | wpmaster (admin) + content_editor |
| Non-admin username | ✅ | 'wpmaster' (not 'admin') |

## License

This project is part of the 42 School curriculum.

## Author

tforster
