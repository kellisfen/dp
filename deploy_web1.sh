#!/bin/bash
set -e

echo "=== Deploying Web Server 1 ==="

# Install PHP if not installed
sudo apt-get update -qq
sudo apt-get install -y php-fpm php-cli

# Copy files
sudo cp /tmp/index.html /var/www/html/index.html
sudo cp /tmp/server-info.php /var/www/html/server-info.php

# Set permissions
sudo chown www-data:www-data /var/www/html/*
sudo chmod 644 /var/www/html/*

# Configure Nginx for PHP
sudo tee /etc/nginx/sites-available/default > /dev/null <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html index.php;
    
    server_name _;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    }
}
EOF

# Restart services
sudo systemctl restart nginx
sudo systemctl restart php7.4-fpm

echo "=== Web Server 1 deployed successfully ==="
echo "Test: curl http://localhost/"

