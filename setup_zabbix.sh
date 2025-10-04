#!/bin/bash
# Setup Zabbix Server with MySQL

set -e

echo "=== Installing Zabbix Server ==="

# Install Zabbix repository
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu20.04_all.deb
sudo dpkg -i zabbix-release_6.4-1+ubuntu20.04_all.deb
sudo apt-get update -qq

# Install Zabbix server, frontend, agent
sudo apt-get install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent mysql-server

# Start MySQL
sudo systemctl start mysql
sudo systemctl enable mysql

# Create database
sudo mysql -e "CREATE DATABASE IF NOT EXISTS zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'zabbix'@'localhost' IDENTIFIED BY 'zabbix_password';"
sudo mysql -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
sudo mysql -e "SET GLOBAL log_bin_trust_function_creators = 1;"
sudo mysql -e "FLUSH PRIVILEGES;"

# Import initial schema
sudo zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | sudo mysql --default-character-set=utf8mb4 zabbix

sudo mysql -e "SET GLOBAL log_bin_trust_function_creators = 0;"

# Configure Zabbix server
sudo sed -i 's/# DBPassword=/DBPassword=zabbix_password/' /etc/zabbix/zabbix_server.conf

# Start Zabbix services
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2

echo "=== Zabbix Server installed ==="
echo "Access: http://$(hostname -I | awk '{print $1}')"
echo "Default credentials: Admin / zabbix"

