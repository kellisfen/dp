#!/bin/bash
set -e

echo "=== Installing Grafana via Docker ==="

# Stop and remove existing Grafana container if exists
sudo docker stop grafana 2>/dev/null || true
sudo docker rm grafana 2>/dev/null || true

# Create Grafana data directory
sudo mkdir -p /var/lib/grafana-data
sudo chown -R 472:472 /var/lib/grafana-data

# Run Grafana container
sudo docker run -d \
  --name grafana \
  --restart unless-stopped \
  -p 0.0.0.0:3000:3000 \
  -v /var/lib/grafana-data:/var/lib/grafana \
  -e "GF_SERVER_HTTP_ADDR=0.0.0.0" \
  -e "GF_SERVER_HTTP_PORT=3000" \
  -e "GF_SECURITY_ADMIN_PASSWORD=admin" \
  -e "GF_INSTALL_PLUGINS=grafana-clock-panel" \
  grafana/grafana:10.2.2

echo ""
echo "Waiting for Grafana to start..."
sleep 15

# Check if Grafana is running
if sudo docker ps | grep -q grafana; then
    echo "=== Grafana installed successfully ==="
    echo "Container status:"
    sudo docker ps | grep grafana
    echo ""
    echo "Access: http://$(hostname -I | awk '{print $1}'):3000"
    echo "Default credentials: admin / admin"
    echo ""
    echo "Grafana logs:"
    sudo docker logs grafana 2>&1 | tail -20
else
    echo "ERROR: Grafana container failed to start"
    sudo docker logs grafana 2>&1 | tail -50
    exit 1
fi

