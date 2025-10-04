#!/bin/bash
echo "=== Docker containers ==="
sudo docker ps -a
echo ""
echo "=== Docker compose files ==="
ls -la /home/ubuntu/*.yml 2>/dev/null || echo "No compose files found"

