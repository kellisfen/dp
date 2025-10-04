#!/bin/bash
cd /home/ubuntu
sudo docker-compose -f grafana-compose.yml up -d
sudo docker ps | grep grafana

