#!/bin/bash

# Скрипт установки Node Exporter на Kibana Server

set -e

echo "=== Установка Node Exporter на Kibana Server ==="
echo ""

BASTION_IP="158.160.104.48"
KIBANA_IP="10.0.1.3"
SSH_KEY="$HOME/.ssh/diplom_key.pem"
NODE_EXPORTER_VERSION="1.7.0"

if [ ! -f "$SSH_KEY" ]; then
    echo "❌ SSH ключ не найден: $SSH_KEY"
    exit 1
fi

echo "1. Скачивание Node Exporter..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@$BASTION_IP \
    "ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@$KIBANA_IP \
    'cd /tmp && wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz'"

if [ $? -eq 0 ]; then
    echo "✅ Node Exporter скачан"
else
    echo "❌ Ошибка скачивания"
    exit 1
fi

echo ""
echo "2. Распаковка архива..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@$BASTION_IP \
    "ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@$KIBANA_IP \
    'cd /tmp && tar xzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz'"

if [ $? -eq 0 ]; then
    echo "✅ Архив распакован"
else
    echo "❌ Ошибка распаковки"
    exit 1
fi

echo ""
echo "3. Установка Node Exporter..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@$BASTION_IP \
    "ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@$KIBANA_IP \
    'sudo mkdir -p /opt/node_exporter && sudo cp /tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /opt/node_exporter/ && sudo chmod +x /opt/node_exporter/node_exporter'"

if [ $? -eq 0 ]; then
    echo "✅ Node Exporter установлен"
else
    echo "❌ Ошибка установки"
    exit 1
fi

echo ""
echo "4. Создание systemd service..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@$BASTION_IP \
    "ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@$KIBANA_IP \
    'sudo tee /etc/systemd/system/node_exporter.service > /dev/null << EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/node_exporter/node_exporter --web.listen-address=0.0.0.0:9100
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF'"

if [ $? -eq 0 ]; then
    echo "✅ Systemd service создан"
else
    echo "❌ Ошибка создания service"
    exit 1
fi

echo ""
echo "5. Запуск Node Exporter..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@$BASTION_IP \
    "ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@$KIBANA_IP \
    'sudo systemctl daemon-reload && sudo systemctl enable node_exporter && sudo systemctl start node_exporter'"

if [ $? -eq 0 ]; then
    echo "✅ Node Exporter запущен"
else
    echo "❌ Ошибка запуска"
    exit 1
fi

echo ""
echo "6. Проверка статуса..."
sleep 2
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@$BASTION_IP \
    "ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@$KIBANA_IP \
    'sudo systemctl status node_exporter | head -10'"

echo ""
echo "7. Проверка метрик..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@$BASTION_IP \
    "ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@$KIBANA_IP \
    'curl -s http://localhost:9100/metrics | head -5'"

echo ""
echo "✅ Node Exporter успешно установлен на Kibana Server!"
echo ""
echo "Проверьте targets в Prometheus через 15-30 секунд:"
echo "http://62.84.112.42:9090/targets"

