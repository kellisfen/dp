#!/bin/bash
# Script to setup all servers from Bastion

set -e

KEY="/tmp/diplom_key.pem"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"

echo "=== Setting up Web Servers ==="

# Web Server 1
echo "Configuring Web Server 1 (10.0.2.21)..."
ssh -i $KEY $SSH_OPTS ubuntu@10.0.2.21 << 'EOF'
sudo apt-get update -qq
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
echo "<h1>Web Server 1 - $(hostname)</h1><p>IP: $(hostname -I)</p>" | sudo tee /var/www/html/index.html
sudo systemctl status nginx --no-pager
EOF

# Web Server 2
echo "Configuring Web Server 2 (10.0.3.3)..."
ssh -i $KEY $SSH_OPTS ubuntu@10.0.3.3 << 'EOF'
sudo apt-get update -qq
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
echo "<h1>Web Server 2 - $(hostname)</h1><p>IP: $(hostname -I)</p>" | sudo tee /var/www/html/index.html
sudo systemctl status nginx --no-pager
EOF

echo "=== Setting up Zabbix Server ==="
ssh -i $KEY $SSH_OPTS ubuntu@10.0.1.14 << 'EOF'
sudo apt-get update -qq
sudo apt-get install -y wget gnupg2
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu20.04_all.deb
sudo dpkg -i zabbix-release_6.4-1+ubuntu20.04_all.deb
sudo apt-get update -qq
sudo apt-get install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent mysql-server
echo "Zabbix packages installed"
EOF

echo "=== Setting up Elasticsearch ==="
ssh -i $KEY $SSH_OPTS ubuntu@10.0.4.34 << 'EOF'
sudo apt-get update -qq
sudo apt-get install -y apt-transport-https
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt-get update -qq
sudo apt-get install -y elasticsearch
sudo systemctl enable elasticsearch
echo "Elasticsearch installed"
EOF

echo "=== Setting up Kibana ==="
ssh -i $KEY $SSH_OPTS ubuntu@10.0.1.3 << 'EOF'
sudo apt-get update -qq
sudo apt-get install -y apt-transport-https
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt-get update -qq
sudo apt-get install -y kibana
sudo systemctl enable kibana
echo "Kibana installed"
EOF

echo "=== Setup Complete ==="
echo "Web Server 1: http://10.0.2.21"
echo "Web Server 2: http://10.0.3.3"
echo "Zabbix: http://10.0.1.14"
echo "Kibana: http://10.0.1.3:5601"

