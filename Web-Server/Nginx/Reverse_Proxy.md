# Nginx Reverse Proxy with SSL and Load Balancing + Ansible Automation for SSL Rotation

---

## Table of Contents

- [1. Nginx Reverse Proxy with SSL and Load Balancing](#1-nginx-reverse-proxy-with-ssl-and-load-balancing)
  - [1.1 Installing Nginx](#11-installing-nginx)
  - [1.2 SSL Certificate Setup](#12-ssl-certificate-setup)
  - [1.3 Nginx Configuration](#13-nginx-configuration)
  - [1.4 Enable and Reload Nginx](#14-enable-and-reload-nginx)
  - [1.5 Load Balancing Methods](#15-load-balancing-methods)
  - [1.6 Firewall Configuration](#16-firewall-configuration)

- [2. Ansible Playbook for Easier SSL Rotation and Automation](#2-ansible-playbook-for-easier-ssl-rotation-and-automation)
  - [2.1 Assumptions](#21-assumptions)
  - [2.2 Full Ansible Playbook](#22-full-ansible-playbook)
  - [2.3 How to Use](#23-how-to-use)
  - [2.4 Playbook Description](#24-playbook-description)

---

## 1. Nginx Reverse Proxy with SSL and Load Balancing

### 1.1 Installing Nginx

**On Ubuntu/Debian:**

```bash
sudo apt update
sudo apt install nginx -y
```

**On CentOS/RHEL:**

```bash
sudo yum install epel-release -y
sudo yum install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx
```

**1.2 SSL Certificate Setup**

Option A: Use Let's Encrypt (Recommended)

```bash 
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d example.com -d www.example.com
```

Option B: Self-Signed Certificate (For Testing)

```bash
sudo mkdir -p /etc/ssl/private
sudo openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout /etc/ssl/private/selfsigned.key \
  -out /etc/ssl/private/selfsigned.crt \
  -subj "/C=US/ST=State/L=City/O=Org/OU=IT/CN=example.com"
```

**1.3 Nginx Configuration**
Create /etc/nginx/sites-available/reverse-proxy.conf with the following content:

```bash
# Reverse Proxy and Load Balancing with SSL

upstream backend_servers {
    server 192.168.1.101:3000;
    server 192.168.1.102:3000;
    server 192.168.1.103:3000;
    # Add more backend servers as needed
}

server {
    listen 80;
    server_name example.com www.example.com;

    # Redirect HTTP to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name example.com www.example.com;

    # SSL Configuration
    ssl_certificate /etc/ssl/private/selfsigned.crt;     # Or Let's Encrypt cert path
    ssl_certificate_key /etc/ssl/private/selfsigned.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://backend_servers;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site by creating a symbolic link:

```bash
sudo ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/
```

**1.4 Enable and Reload Nginx**
Test the configuration and reload Nginx:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

**1.5 Load Balancing Methods (Optional)**
1) Round Robin (default):

```bash
upstream backend_servers {
    server 192.168.1.101:3000;
    server 192.168.1.102:3000;
}

```

2) Least Connections:
```bash
upstream backend_servers {
    least_conn;
    server 192.168.1.101:3000;
    server 192.168.1.102:3000;
}

```
3) IP Hash (Sticky Sessions):

```bash
upstream backend_servers {
    ip_hash;
    server 192.168.1.101:3000;
    server 192.168.1.102:3000;
}
```

**1.6 Firewall Configuration**
Allow HTTP and HTTPS traffic through the firewall:
```bash
sudo ufw allow 'Nginx Full'
```



