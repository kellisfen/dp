#!/bin/bash

# Скрипт для исправления конфигурации Prometheus
# Изменяет localhost:9100 на 10.0.1.3:9100 для node_exporter

set -e

echo "=== Исправление конфигурации Prometheus ==="
echo ""

BASTION_IP="158.160.104.48"
KIBANA_IP="10.0.1.3"
SSH_KEY="$HOME/.ssh/diplom_key.pem"

if [ ! -f "$SSH_KEY" ]; then
    echo "❌ SSH ключ не найден: $SSH_KEY"
    exit 1
fi

echo "1. Создание резервной копии конфигурации..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@$BASTION_IP \
    "ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@$KIBANA_IP \
    'sudo cp /etc/prometheus/prometheus.yml /etc/prometheus/prometheus.yml.backup-\$(date +%Y%m%d-%H%M%S)'"

if [ $? -eq 0 ]; then
    echo "✅ Резервная копия создана"
else
    echo "❌ Ошибка создания резервной копии"
    exit 1
fi

echo ""
echo "2. Исправление конфигурации..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@$BASTION_IP \
    "ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@$KIBANA_IP \
    'sudo sed -i \"s/localhost:9100/10.0.1.3:9100/\" /etc/prometheus/prometheus.yml'"

if [ $? -eq 0 ]; then
    echo "✅ Конфигурация исправлена"
else
    echo "❌ Ошибка исправления конфигурации"
    exit 1
fi

echo ""
echo "3. Проверка новой конфигурации..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@$BASTION_IP \
    "ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@$KIBANA_IP \
    'cat /etc/prometheus/prometheus.yml | grep -A 3 node_exporter'"

echo ""
echo "4. Перезапуск Prometheus..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@$BASTION_IP \
    "ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@$KIBANA_IP \
    'sudo systemctl restart prometheus'"

if [ $? -eq 0 ]; then
    echo "✅ Prometheus перезапущен"
else
    echo "❌ Ошибка перезапуска Prometheus"
    exit 1
fi

echo ""
echo "5. Проверка статуса Prometheus..."
sleep 3
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@$BASTION_IP \
    "ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@$KIBANA_IP \
    'sudo systemctl status prometheus | head -10'"

echo ""
echo "✅ Конфигурация Prometheus успешно исправлена!"
echo ""
echo "Проверьте targets в Prometheus:"
echo "http://62.84.112.42:9090/targets"
echo ""
echo "node_exporter должен стать UP через 15-30 секунд"

