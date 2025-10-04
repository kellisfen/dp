#!/bin/bash
set -e

echo "=== Configuring Grafana ==="

# Wait for Grafana to be ready
echo "Waiting for Grafana to be ready..."
sleep 10

# Change admin password
echo "Changing admin password..."
curl -X PUT -H "Content-Type: application/json" -d '{
  "oldPassword": "admin",
  "newPassword": "DevOps2025!",
  "confirmNew": "DevOps2025!"
}' http://admin:admin@localhost:3000/api/user/password 2>/dev/null || echo "Password already changed"

# Add Prometheus data source
echo "Adding Prometheus data source..."
curl -X POST -H "Content-Type: application/json" -d '{
  "name": "Prometheus",
  "type": "prometheus",
  "url": "http://localhost:9090",
  "access": "proxy",
  "isDefault": true,
  "jsonData": {
    "httpMethod": "POST",
    "timeInterval": "15s"
  }
}' http://admin:DevOps2025!@localhost:3000/api/datasources 2>/dev/null || echo "Data source already exists"

# Import Node Exporter Full dashboard
echo "Importing Node Exporter Full dashboard..."
curl -X POST -H "Content-Type: application/json" -d '{
  "dashboard": {
    "id": null,
    "uid": null,
    "title": "Node Exporter Full",
    "tags": ["prometheus", "node-exporter"],
    "timezone": "browser",
    "schemaVersion": 16,
    "version": 0
  },
  "folderId": 0,
  "overwrite": false,
  "inputs": [
    {
      "name": "DS_PROMETHEUS",
      "type": "datasource",
      "pluginId": "prometheus",
      "value": "Prometheus"
    }
  ]
}' http://admin:DevOps2025!@localhost:3000/api/dashboards/import 2>/dev/null || echo "Dashboard import may need manual setup"

echo ""
echo "=== Grafana configuration complete ==="
echo "Access: http://$(hostname -I | awk '{print $1}'):3000"
echo "Username: admin"
echo "Password: DevOps2025!"
echo ""
echo "Next steps:"
echo "1. Login to Grafana"
echo "2. Go to Dashboards -> Import"
echo "3. Enter dashboard ID: 1860 (Node Exporter Full)"
echo "4. Select Prometheus data source"
echo "5. Click Import"

