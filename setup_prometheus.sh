#!/bin/bash
# Setup Prometheus on Kibana server

set -e

echo "=== Installing Prometheus ==="

# Variables
PROMETHEUS_VERSION="2.48.0"
PROMETHEUS_USER="prometheus"
PROMETHEUS_DIR="/opt/prometheus"
PROMETHEUS_CONFIG_DIR="/etc/prometheus"
PROMETHEUS_DATA_DIR="/var/lib/prometheus"

# Create prometheus user
sudo useradd --no-create-home --shell /bin/false ${PROMETHEUS_USER} 2>/dev/null || echo "User already exists"

# Download and install Prometheus
cd /tmp
wget -q https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar xzf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
sudo mkdir -p ${PROMETHEUS_DIR}
sudo cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus ${PROMETHEUS_DIR}/
sudo cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool ${PROMETHEUS_DIR}/
sudo mkdir -p ${PROMETHEUS_CONFIG_DIR}
sudo cp -r prometheus-${PROMETHEUS_VERSION}.linux-amd64/consoles ${PROMETHEUS_CONFIG_DIR}/
sudo cp -r prometheus-${PROMETHEUS_VERSION}.linux-amd64/console_libraries ${PROMETHEUS_CONFIG_DIR}/

# Create directories
sudo mkdir -p ${PROMETHEUS_DATA_DIR}
sudo chown -R ${PROMETHEUS_USER}:${PROMETHEUS_USER} ${PROMETHEUS_DIR} ${PROMETHEUS_CONFIG_DIR} ${PROMETHEUS_DATA_DIR}

# Create Prometheus configuration
sudo tee ${PROMETHEUS_CONFIG_DIR}/prometheus.yml > /dev/null <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'web_servers'
    static_configs:
      - targets: 
        - '10.0.2.21:9100'
        - '10.0.3.3:9100'
        labels:
          group: 'web'

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          instance: 'kibana-server'
EOF

sudo chown ${PROMETHEUS_USER}:${PROMETHEUS_USER} ${PROMETHEUS_CONFIG_DIR}/prometheus.yml

# Create systemd service
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=${PROMETHEUS_USER}
Group=${PROMETHEUS_USER}
Type=simple
ExecStart=${PROMETHEUS_DIR}/prometheus \\
  --config.file=${PROMETHEUS_CONFIG_DIR}/prometheus.yml \\
  --storage.tsdb.path=${PROMETHEUS_DATA_DIR} \\
  --web.console.templates=${PROMETHEUS_CONFIG_DIR}/consoles \\
  --web.console.libraries=${PROMETHEUS_CONFIG_DIR}/console_libraries \\
  --web.listen-address=0.0.0.0:9090

Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start Prometheus
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

# Cleanup
rm -rf /tmp/prometheus-${PROMETHEUS_VERSION}.linux-amd64*

echo "=== Prometheus installed ==="
echo "Access: http://$(hostname -I | awk '{print $1}'):9090"
echo "Status: sudo systemctl status prometheus"

