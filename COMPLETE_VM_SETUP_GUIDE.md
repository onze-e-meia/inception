# Complete Inception VM Setup Guide

## Prerequisites Checklist

- [ ] VirtualBox installed on host
- [ ] Debian 12 netinstall ISO downloaded
- [ ] At least 20GB free disk space
- [ ] Inception project files ready on host
- [ ] Your 42 login name (replace `tforster` with yours throughout)

---

## Part 1: VM Creation and Installation

### 1.1 Create VM in VirtualBox

```
Name: inception-vm
Type: Linux
Version: Debian (64-bit)
Memory: 4096 MB (4GB recommended, minimum 2GB)
Hard Disk: Create virtual hard disk now
  - Type: VDI (VirtualBox Disk Image)
  - Storage: Dynamically allocated
  - Size: 20 GB
```

### 1.2 Configure VM Settings (Before First Boot)

```
Settings → System → Processor: 2 CPUs
Settings → Network → Adapter 1:
  - Attached to: Bridged Adapter
  - Name: (select your network card)
  - Advanced → Promiscuous Mode: Allow All
Settings → Storage → Controller: IDE:
  - Click "Empty"
  - Click disk icon → Choose disk file
  - Select your debian-12.x.x-amd64-netinst.iso
```

### 1.3 Install Debian (Headless Server)

Start the VM and follow these steps:

```
1. Select: "Install" (NOT Graphical Install)

2. Language: English
3. Location: Your country
4. Keyboard: Your keyboard layout

5. Network configuration:
   - Hostname: inception-vm
   - Domain name: (leave empty or type "local")

6. Set up users:
   - Root password: <create strong password>
   - Full name: Your Name
   - Username: tforster (or your preferred username)
   - Password: <create strong password>

7. Partition disks:
   → Guided - use entire disk
   → Select the disk (usually only one option)
   → All files in one partition (recommended for beginners)
   → Finish partitioning and write changes to disk
   → Yes (confirm write changes)

8. Configure the package manager:
   → Scan extra installation media? No
   → Debian archive mirror country: Your country
   → Debian archive mirror: deb.debian.org (default)
   → HTTP proxy: (leave empty)

9. Participate in the package usage survey? No

10. Software selection (CRITICAL):
    Use SPACE to select/deselect:

    [ ] Debian desktop environment     ← MUST BE UNCHECKED
    [ ] ... GNOME                      ← MUST BE UNCHECKED
    [ ] ... XFCE                       ← MUST BE UNCHECKED
    [ ] ... KDE                        ← MUST BE UNCHECKED
    [ ] ... Cinnamon                   ← MUST BE UNCHECKED
    [ ] ... MATE                       ← MUST BE UNCHECKED
    [ ] ... LXDE                       ← MUST BE UNCHECKED
    [ ] web server                     ← MUST BE UNCHECKED
    [ ] print server                   ← MUST BE UNCHECKED
    [X] SSH server                     ← MUST BE CHECKED
    [X] standard system utilities      ← MUST BE CHECKED

11. Install GRUB boot loader:
    → Yes
    → Device: /dev/sda

12. Finish installation → Continue
    (VM will reboot)
```

---

## Part 2: Initial VM Configuration

### 2.1 First Login and Network Setup

At the VM console:

```bash
# Login with your username and password
inception-vm login: tforster
Password: <your password>

# Find your VM's IP address
ip addr show

# Look for something like:
# 2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP>
#     inet 192.168.1.100/24 brd 192.168.1.255 scope global dynamic enp0s3
#
# Your IP is: 192.168.1.100 (write this down!)

# Test internet connectivity
ping -c 3 google.com
```

**Important:** Write down your VM's IP address. You'll need it for SSH.

### 2.2 Connect via SSH from Host

From your **host computer** terminal:

```bash
# SSH into VM (replace IP with yours)
ssh tforster@192.168.1.100

# If you get a warning about host authenticity, type: yes
# Enter your password

# You should now see:
tforster@inception-vm:~$
```

✅ From now on, work via SSH. Close the VirtualBox window (VM keeps running).

---

## Part 3: Install Required Software

### 3.1 Install sudo

```bash
# Switch to root
su -
# Enter root password

# Update package list
apt update

# Install sudo
apt install -y sudo

# Add your user to sudo group
usermod -aG sudo tforster

# Verify user is in sudo group
groups tforster
# Should show: tforster : tforster cdrom floppy audio dip video plugdev netdev sudo

# Exit root shell
exit

# Test sudo (should ask for YOUR password, not root)
sudo whoami
# Should print: root

# If sudo doesn't work, log out and back in:
exit
ssh tforster@192.168.1.100
sudo whoami
```

### 3.2 Clean Old Docker Installations (if any)

```bash
# Remove any existing Docker packages
sudo apt remove -y docker docker-engine docker.io containerd runc docker-compose

# Clean up
sudo apt autoremove -y
```

### 3.3 Install Docker Engine + Compose V2 (Official Method)

```bash
# Install prerequisites
sudo apt update
sudo apt install -y ca-certificates curl gnupg

# Create directory for keyrings
sudo install -m 0755 -d /etc/apt/keyrings

# Download Docker's official GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set read permissions
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository to apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index with Docker packages
sudo apt update

# Install Docker Engine, CLI, Containerd, and Compose V2
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to docker group (no sudo needed for docker commands)
sudo usermod -aG docker $USER

# IMPORTANT: Log out and back in for group changes to take effect
exit

# SSH back in
ssh tforster@192.168.1.100
```

### 3.4 Verify Docker Installation

```bash
# Check Docker version
docker --version
# Expected: Docker version 27.x.x, build ...

# Check Docker Compose version (V2 with space!)
docker compose version
# Expected: Docker Compose version v2.x.x

# Check Docker is running
sudo systemctl status docker
# Should show: active (running)

# Test Docker without sudo
docker run hello-world
# Should download and run successfully

# If you get permission denied, your user isn't in docker group yet
# Log out and back in again:
exit
ssh tforster@192.168.1.100
docker run hello-world
```

### 3.5 Install Additional Development Tools

```bash
# Install make, git, vim, and curl
sudo apt install -y make git vim curl net-tools

# Verify installations
make --version
git --version
vim --version | head -1
curl --version | head -1
```

---

## Part 4: Domain Configuration

### 4.1 Configure Domain on VM

```bash
# Add domain to /etc/hosts on VM
sudo bash -c 'echo "127.0.0.1 tforster.42.fr" >> /etc/hosts'

# Verify it was added
cat /etc/hosts
# Should show your domain at the bottom

# Test domain resolution
ping -c 3 tforster.42.fr
# Should ping 127.0.0.1 successfully

# Test with curl (will fail since nothing is running yet, but DNS should work)
curl http://tforster.42.fr
# Expected: Connection refused (this is OK - means DNS works, no service yet)
```

### 4.2 Configure Domain on Host (Optional - for direct browser access)

**If you CAN'T edit /etc/hosts on your host machine**, skip this and use SSH tunnel (shown later).

**If you CAN edit /etc/hosts on your host:**

```bash
# On Linux/Mac host:
sudo nano /etc/hosts
# Add this line (replace with your VM's IP):
192.168.1.100 tforster.42.fr

# On Windows host (run Notepad as Administrator):
# Edit: C:\Windows\System32\drivers\etc\hosts
# Add:
192.168.1.100 tforster.42.fr
```

---

## Part 5: Project Setup

### 5.1 Transfer Project Files to VM

From your **host computer**:

```bash
# Navigate to your inception project directory
cd /path/to/your/inception

# Copy entire project to VM
scp -r inception tforster@10.13.200.19:~/

# This will copy all files and folders
# Enter your VM password when prompted

# Verify upload
ssh tforster@192.168.1.100
ls -la ~/inception/
```

### 5.2 Create Required Data Directories

```bash
# On VM, create data directories for Docker volumes
mkdir -p ~/data/mariadb
mkdir -p ~/data/wordpress

# Verify
ls -la ~/data/
```

### 5.3 Verify Project Structure

Your project should have this structure:

```bash
cd ~/inception
tree -L 3
# Or if tree isn't installed:
find . -type d -maxdepth 3
```

Expected structure:
```
inception/
├── Makefile
├── secrets/                    (git-ignored)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── wp_admin_password.txt
└── srcs/
    ├── docker-compose.yml
    ├── .env                    (git-ignored)
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── nginx/
            ├── Dockerfile
            ├── conf/
            └── tools/
```

### 5.4 Verify Makefile Uses Correct Syntax

```bash
# Check if Makefile uses "docker compose" (V2 syntax)
grep "docker compose" ~/inception/Makefile

# If found, you're good!
# If NOT found and it uses "docker-compose", update it:
sed -i 's/docker-compose/docker compose/g' ~/inception/Makefile
```

### 5.5 Correct Makefile (Docker Compose V2)

Your `~/inception/Makefile` should look like this:

```makefile
.PHONY: all up build down clean fclean re logs ps

all: up

up: build
	@mkdir -p $(HOME)/data/mariadb
	@mkdir -p $(HOME)/data/wordpress
	@docker compose -f srcs/docker-compose.yml up -d

build:
	@docker compose -f srcs/docker-compose.yml build

down:
	@docker compose -f srcs/docker-compose.yml down

clean: down
	@docker compose -f srcs/docker-compose.yml down --rmi all
	@docker system prune -af

fclean: clean
	@docker compose -f srcs/docker-compose.yml down -v
	@sudo rm -rf $(HOME)/data/mariadb
	@sudo rm -rf $(HOME)/data/wordpress

re: fclean all

logs:
	@docker compose -f srcs/docker-compose.yml logs -f

ps:
	@docker compose -f srcs/docker-compose.yml ps
```

Note: Uses `docker compose` (space) not `docker-compose` (hyphen).

### 5.6 Verify .env File

```bash
# Check if .env exists
cat ~/inception/srcs/.env

# Should contain something like:
DOMAIN_NAME=tforster.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=your_password
MYSQL_ROOT_PASSWORD=your_root_password
WP_ADMIN_USER=wpmaster
WP_ADMIN_PASSWORD=your_admin_password
WP_ADMIN_EMAIL=wpmaster@example.com
WP_USER=content_editor
WP_USER_PASSWORD=your_user_password
WP_USER_EMAIL=editor@example.com
```

### 5.7 Verify docker-compose.yml

```bash
# Check critical settings in docker-compose.yml
cat ~/inception/srcs/docker-compose.yml
```

Verify:
- ✅ nginx ports: `""` or `"443:443"`
- ✅ volumes point to: `${HOME}/data/mariadb` and `${HOME}/data/wordpress`
- ✅ networks defined
- ✅ services: nginx, wordpress, mariadb

---

## Part 6: Build and Run

### 6.1 Build Docker Images

```bash
cd ~/inception

# Build images
make build

# This will take several minutes on first run
# You should see:
# Building Docker images...
# [+] Building mariadb
# [+] Building wordpress
# [+] Building nginx
```

### 6.2 Start Containers

```bash
# Start all services
make up

# Or if you want to see logs in real-time:
docker compose -f srcs/docker-compose.yml up

# To run in background:
docker compose -f srcs/docker-compose.yml up -d
```

### 6.3 Verify Containers are Running

```bash
# Check container status
docker ps

# Expected output:
# CONTAINER ID   IMAGE                    STATUS         PORTS
# xxxxxxxxxxxx   srcs-nginx              Up X minutes   0.0.0.0:4443->443/tcp
# xxxxxxxxxxxx   srcs-wordpress          Up X minutes   9000/tcp
# xxxxxxxxxxxx   srcs-mariadb            Up X minutes   3306/tcp

# All should show "Up" status
```

### 6.4 Check Container Logs

```bash
# View all logs
docker compose -f ~/inception/srcs/docker-compose.yml logs

# Follow logs in real-time
docker compose -f ~/inception/srcs/docker-compose.yml logs -f

# Check specific container
docker logs nginx
docker logs wordpress
docker logs mariadb

# Look for errors (there should be none)
```

### 6.5 Wait for WordPress Installation

WordPress needs time to install. Wait about 30-60 seconds, then:

```bash
# Check if WordPress is ready
docker logs wordpress | tail -20

# Should see something like:
# WordPress installed successfully
# or
# Success: WordPress is already installed
```

---

## Part 7: Testing Access

### 7.1 Test on VM Locally

```bash
# Test NGINX responds
curl -k https://localhost:4443

# Test with domain name
curl -k https://tforster.42.fr:4443

# Both should return HTML (WordPress page)
# If you get "Connection refused", containers aren't ready yet

# Check if you can see "WordPress" in the response
curl -k https://tforster.42.fr:4443 | grep -i wordpress
```

### 7.2 Test from Host Computer

**Method 1: SSH Tunnel (Works even if you can't edit /etc/hosts)**

```bash
# From your HOST computer, open a new terminal
ssh -L 4443:localhost:4443 tforster@192.168.1.100

# Keep this terminal open!
# In your browser: https://localhost:4443
```

**Method 2: Direct IP Access**

```bash
# In your HOST browser:
https://192.168.1.100:4443

# You'll get SSL warning (self-signed certificate)
# Click "Advanced" → "Proceed to 192.168.1.100"
```

**Method 3: Domain Name (if you edited /etc/hosts on host)**

```bash
# In your HOST browser:
https://tforster.42.fr:4443

# You'll get SSL warning (self-signed certificate)
# Click "Advanced" → "Proceed to tforster.42.fr"
```

### 7.3 Login to WordPress

```
URL: https://tforster.42.fr:4443/wp-admin
Username: wpmaster (or your WP_ADMIN_USER from .env)
Password: (your WP_ADMIN_PASSWORD from .env)
```

---

## Part 8: Common Issues and Solutions

### Issue 1: "docker compose: command not found"

```bash
# Check if you have V2:
docker compose version

# If not found, you might have V1:
docker-compose --version

# If V1 is installed, update Makefile:
sed -i 's/docker compose/docker-compose/g' ~/inception/Makefile

# Or reinstall Docker properly (see Part 3.3)
```

### Issue 2: "Permission denied" when running docker

```bash
# Check if you're in docker group:
groups

# If "docker" is not listed:
sudo usermod -aG docker $USER

# Log out and back in:
exit
ssh tforster@192.168.1.100
```

### Issue 3: Containers exit immediately

```bash
# Check container status:
docker ps -a

# Check logs for errors:
docker logs mariadb
docker logs wordpress
docker logs nginx

# Common causes:
# - Missing .env file
# - Wrong permissions on volumes
# - Incorrect Dockerfile syntax
```

### Issue 4: "Connection refused" when accessing WordPress

```bash
# Wait longer (WordPress takes time to install)
sleep 60

# Check if containers are running:
docker ps

# Check NGINX logs:
docker logs nginx

# Check if port is listening:
sudo ss -tlnp | grep 4443
# Should show: LISTEN on 0.0.0.0:4443
```

### Issue 5: Can't access from host browser

```bash
# On VM, check if port is exposed:
docker ps
# Should show: 0.0.0.0:4443->443/tcp

# Test from VM first:
curl -k https://localhost:4443

# If VM works but host doesn't:
# 1. Check VM firewall (should be none by default)
sudo iptables -L

# 2. Check VirtualBox network is Bridged
# 3. Try SSH tunnel method instead
```

### Issue 6: SSL certificate errors

This is **EXPECTED** with self-signed certificates.

In browser:
1. Click "Advanced"
2. Click "Proceed to <domain>"
3. This is normal for development

### Issue 7: Domain doesn't resolve

```bash
# On VM, check /etc/hosts:
cat /etc/hosts | grep tforster
# Should show: 127.0.0.1 tforster.42.fr

# Test resolution:
ping tforster.42.fr
# Should ping 127.0.0.1

# If not working, re-add it:
sudo bash -c 'echo "127.0.0.1 tforster.42.fr" >> /etc/hosts'
```

---

## Part 9: Useful Commands Reference

### Docker Compose Commands

```bash
# Build images
docker compose -f srcs/docker-compose.yml build

# Start containers
docker compose -f srcs/docker-compose.yml up -d

# Stop containers
docker compose -f srcs/docker-compose.yml down

# View logs
docker compose -f srcs/docker-compose.yml logs -f

# Restart a service
docker compose -f srcs/docker-compose.yml restart nginx

# Rebuild a specific service
docker compose -f srcs/docker-compose.yml build --no-cache nginx

# Remove everything including volumes
docker compose -f srcs/docker-compose.yml down -v
```

### Makefile Commands

```bash
# Build and start
make

# Just build
make build

# Stop containers
make down

# Full cleanup
make fclean

# Rebuild from scratch
make re

# View logs
make logs

# Check status
make ps
```

### Docker Commands

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# View container logs
docker logs <container_name>

# Execute command in container
docker exec -it nginx /bin/bash

# View container resource usage
docker stats

# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove everything (careful!)
docker system prune -a
```

### System Commands

```bash
# Check disk space
df -h

# Check memory usage
free -h

# Check Docker disk usage
docker system df

# Find VM's IP address
ip addr show

# Test port is listening
sudo ss -tlnp | grep 4443

# Check service status
sudo systemctl status docker
```

---

## Part 10: For 42 Evaluation

### What to Show Evaluator

```bash
# 1. SSH into VM
ssh tforster@192.168.1.100

# 2. Show system configuration
cat /etc/hosts | grep tforster
docker --version
docker compose version

# 3. Show project structure
cd ~/inception
ls -la
tree -L 2 srcs/

# 4. Show containers running
docker ps

# 5. Show domain resolves correctly
ping -c 2 tforster.42.fr

# 6. Test WordPress access
curl -k https://tforster.42.fr:4443 | head -20

# 7. Show logs are clean (no errors)
docker logs nginx | tail
docker logs wordpress | tail
docker logs mariadb | tail

# 8. Show volumes
docker volume ls
ls -la ~/data/

# 9. Show network
docker network ls
docker network inspect inception-network

# 10. Access in browser (SSH tunnel if needed)
# From evaluator's computer:
ssh -L 4443:localhost:4443 tforster@192.168.1.100
# Then: https://localhost:4443
```

### What Evaluator Will Check

- ✅ Three separate containers (NGINX, WordPress, MariaDB)
- ✅ TLS 1.2/1.3 only on NGINX
- ✅ Custom Dockerfiles (not pre-built images)
- ✅ No `latest` tags
- ✅ Environment variables used (no hardcoded passwords)
- ✅ Two volumes (database + wordpress files)
- ✅ Custom network
- ✅ Auto-restart configured
- ✅ No infinite loops (tail -f, sleep infinity)
- ✅ WordPress has two users (admin not named "admin")
- ✅ Domain name `login.42.fr` points to localhost
- ✅ Accessible via HTTPS on port 443 (or 4443)

### Quick Demo Script

```bash
# Complete demonstration in 5 minutes:

# 1. Show clean start
cd ~/inception
make fclean

# 2. Rebuild everything
make

# 3. Wait for services to start
sleep 30

# 4. Show everything running
docker ps
docker compose -f srcs/docker-compose.yml ps

# 5. Test access
curl -k https://tforster.42.fr:4443 | grep -i wordpress

# 6. Show in browser
# (Use SSH tunnel or direct IP)

# 7. Login to WordPress
# Show admin user (not named "admin")
# Show regular user exists
```

---

## Part 11: Maintenance and Cleanup

### Regular Cleanup

```bash
# Remove stopped containers
docker container prune -f

# Remove unused images
docker image prune -f

# Remove unused volumes (careful!)
docker volume prune -f

# Remove unused networks
docker network prune -f

# Complete system cleanup
docker system prune -af
```

### Reset Everything

```bash
cd ~/inception

# Stop and remove everything
make fclean

# Rebuild from scratch
make

# Or manually:
docker compose -f srcs/docker-compose.yml down -v
sudo rm -rf ~/data/mariadb ~/data/wordpress
docker system prune -af
make
```

### Backup Data

```bash
# Backup WordPress files
tar -czf wordpress-backup.tar.gz ~/data/wordpress/

# Backup MariaDB data
tar -czf mariadb-backup.tar.gz ~/data/mariadb/

# Copy backups to host
# From host:
scp tforster@192.168.1.100:~/*.tar.gz ./
```

### Update Containers

```bash
cd ~/inception

# Rebuild specific service
docker compose -f srcs/docker-compose.yml build --no-cache nginx

# Recreate container
docker compose -f srcs/docker-compose.yml up -d --force-recreate nginx
```

---

## Part 12: Advanced Tips

### View Container Details

```bash
# Inspect container
docker inspect nginx

# View environment variables
docker exec nginx env

# Check running processes
docker top nginx

# View resource usage
docker stats nginx
```

### Debug Inside Container

```bash
# Get shell in container
docker exec -it nginx /bin/bash

# Run single command
docker exec nginx ls -la /etc/nginx/

# Check logs in real-time
docker logs -f wordpress
```

### Network Debugging

```bash
# Test container connectivity
docker exec wordpress ping mariadb

# Check DNS resolution
docker exec wordpress nslookup mariadb

# View network details
docker network inspect inception-network
```

### Performance Monitoring

```bash
# Real-time resource usage
docker stats

# Disk usage by Docker
docker system df

# View container processes
docker compose -f srcs/docker-compose.yml top
```

---

## Summary Checklist

Installation:
- [x] Debian 12 installed (headless, SSH only)
- [x] sudo installed and configured
- [x] Docker Engine installed
- [x] Docker Compose V2 installed (`docker compose` command works)
- [x] Additional tools installed (make, git, vim, curl)

Configuration:
- [x] Domain configured in /etc/hosts on VM
- [x] User added to docker group (no sudo needed)
- [x] Data directories created (~/data/mariadb, ~/data/wordpress)
- [x] Project files transferred to VM
- [x] .env file configured
- [x] secrets directory created (if needed)

Testing:
- [x] All three containers running
- [x] Domain resolves to 127.0.0.1
- [x] WordPress accessible via https://tforster.42.fr:4443
- [x] Can login to WordPress admin
- [x] No errors in container logs
- [x] Volumes persist data

Access:
- [x] Can SSH to VM from host
- [x] Can access WordPress from host browser
- [x] SSL certificate works (with expected warning)

---

## Quick Reference Card

```bash
# VM Access
ssh tforster@192.168.1.100

# Project Location
cd ~/inception

# Build & Run
make

# Stop
make down

# Full Reset
make fclean && make

# Logs
make logs
docker logs <container>

# Status
docker ps
make ps

# Access from Host
ssh -L 4443:localhost:4443 tforster@192.168.1.100
# Browser: https://localhost:4443

# Test on VM
curl -k https://tforster.42.fr:4443
```

---

## Support Resources

- Docker Documentation: https://docs.docker.com/
- Docker Compose: https://docs.docker.com/compose/
- Debian Documentation: https://www.debian.org/doc/
- 42 Inception Subject: Your school intranet

---

**Document Version:** 1.0
**Last Updated:** November 2025
**Tested On:** Debian 12 (Bookworm), Docker 27.x, Docker Compose V2.x

---

**Good luck with your Inception project! 🚀**
