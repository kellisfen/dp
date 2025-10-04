#!/bin/bash
# Setup Kibana 8.x

set -e

echo "=== Installing Kibana ==="

# Install dependencies
sudo apt-get update -qq
sudo apt-get install -y apt-transport-https gnupg2 wget

# Add Elasticsearch GPG key and repository
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg 2>/dev/null || echo "GPG key already exists"

echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# Install Kibana
sudo apt-get update -qq
sudo apt-get install -y kibana=8.11.0

# Configure Kibana
echo "Configuring Kibana..."
sudo sed -i 's/#server.port: 5601/server.port: 5601/' /etc/kibana/kibana.yml
sudo sed -i 's/#server.host: "localhost"/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml
sudo sed -i 's|#elasticsearch.hosts:.*|elasticsearch.hosts: ["http://10.0.4.34:9200"]|' /etc/kibana/kibana.yml

# Disable xpack security for simplicity
echo "xpack.security.enabled: false" | sudo tee -a /etc/kibana/kibana.yml
echo "xpack.encryptedSavedObjects.encryptionKey: \"fhjskloppd678ehkdfdlliverpoolfcr32\"" | sudo tee -a /etc/kibana/kibana.yml

# Start Kibana
sudo systemctl daemon-reload
sudo systemctl enable kibana
sudo systemctl start kibana

echo "=== Kibana installed ==="
echo "Access: http://$(hostname -I | awk '{print $1}'):5601"
echo "Note: Kibana may take 1-2 minutes to start"
echo "Check status: sudo systemctl status kibana"
echo "Check logs: sudo journalctl -u kibana -f"

