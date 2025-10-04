#!/bin/bash
sudo apt-get update -qq
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
echo "<h1>Web Server 1</h1><p>Hostname: $(hostname)</p><p>IP: $(hostname -I)</p>" | sudo tee /var/www/html/index.html
sudo systemctl status nginx --no-pager | head -5

