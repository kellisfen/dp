#!/bin/bash
# Setup Node Exporter

set -e

echo "=== Installing Node Exporter ==="

# Variables
NODE_EXPORTER_VERSION="1.7.0"
NODE_EXPORTER_USER="node_exporter"
NODE_EXPORTER_DIR="/opt/node_exporter"

# Create node_exporter user
sudo useradd --no-create-home --shell /bin/false ${NODE_EXPORTER_USER} 2>/dev/null || echo "User already exists"

# Download and install Node Exporter
cd /tmp
wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mkdir -p ${NODE_EXPORTER_DIR}
sudo cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter ${NODE_EXPORTER_DIR}/
sudo chown -R ${NODE_EXPORTER_USER}:${NODE_EXPORTER_USER} ${NODE_EXPORTER_DIR}

# Create systemd service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=${NODE_EXPORTER_USER}
Group=${NODE_EXPORTER_USER}
Type=simple
ExecStart=${NODE_EXPORTER_DIR}/node_exporter --web.listen-address=0.0.0.0:9100

Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start Node Exporter
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Cleanup
rm -rf /tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*

echo "=== Node Exporter installed ==="
echo "Access: http://$(hostname -I | awk '{print $1}'):9100/metrics"
echo "Status: sudo systemctl status node_exporter"

