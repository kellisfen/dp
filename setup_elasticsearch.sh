#!/bin/bash
# Setup Elasticsearch

set -e

echo "=== Installing Elasticsearch ==="

# Install dependencies
sudo apt-get update -qq
sudo apt-get install -y apt-transport-https gnupg2

# Add Elasticsearch GPG key and repository
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# Install Elasticsearch
sudo apt-get update -qq
sudo apt-get install -y elasticsearch

# Configure Elasticsearch
sudo sed -i 's/#network.host: 192.168.0.1/network.host: 0.0.0.0/' /etc/elasticsearch/elasticsearch.yml
sudo sed -i 's/#http.port: 9200/http.port: 9200/' /etc/elasticsearch/elasticsearch.yml
echo "xpack.security.enabled: false" | sudo tee -a /etc/elasticsearch/elasticsearch.yml
echo "discovery.type: single-node" | sudo tee -a /etc/elasticsearch/elasticsearch.yml

# Start Elasticsearch
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch

# Wait for Elasticsearch to start
sleep 30

echo "=== Elasticsearch installed ==="
echo "Access: http://$(hostname -I | awk '{print $1}'):9200"
curl -s http://localhost:9200 || echo "Elasticsearch starting..."

