#!/bin/bash
# Setup Grafana

set -e

echo "=== Installing Grafana ==="

# Install dependencies
sudo apt-get update -qq
sudo apt-get install -y apt-transport-https software-properties-common wget

# Add Grafana GPG key and repository
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

# Install Grafana
sudo apt-get update -qq
sudo apt-get install -y grafana

# Configure Grafana
sudo sed -i 's/;http_addr =/http_addr = 0.0.0.0/' /etc/grafana/grafana.ini
sudo sed -i 's/;http_port = 3000/http_port = 3000/' /etc/grafana/grafana.ini

# Start Grafana
sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

echo "=== Grafana installed ==="
echo "Access: http://$(hostname -I | awk '{print $1}'):3000"
echo "Default credentials: admin / admin"
echo "Status: sudo systemctl status grafana-server"
echo ""
echo "Next steps:"
echo "1. Login to Grafana"
echo "2. Add Prometheus data source: http://localhost:9090"
echo "3. Import dashboard 1860 (Node Exporter Full)"

