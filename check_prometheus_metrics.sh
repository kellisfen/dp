#!/bin/bash

# Скрипт проверки метрик Prometheus и Node Exporter
# Использование: ./check_prometheus_metrics.sh

set -e

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Получение IP адресов
echo -e "${CYAN}=== Получение IP адресов ===${NC}"
cd terraform
KIBANA_IP=$(terraform output -raw kibana_external_ip 2>/dev/null || echo "")
BASTION_IP=$(terraform output -raw bastion_external_ip 2>/dev/null || echo "")
cd ..

if [ -z "$KIBANA_IP" ]; then
    echo -e "${RED}❌ Не удалось получить IP адрес Kibana Server${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Kibana Server IP: $KIBANA_IP${NC}"
echo -e "${GREEN}✅ Bastion IP: $BASTION_IP${NC}"
echo ""

PROMETHEUS_URL="http://$KIBANA_IP:9090"
GRAFANA_URL="http://$KIBANA_IP:3000"

echo -e "${CYAN}Prometheus: $PROMETHEUS_URL${NC}"
echo -e "${CYAN}Grafana: $GRAFANA_URL${NC}"
echo ""

# Проверка доступности Prometheus
echo -e "${CYAN}=== Проверка Prometheus ===${NC}"
if curl -s -o /dev/null -w "%{http_code}" "$PROMETHEUS_URL" | grep -q "200"; then
    echo -e "${GREEN}✅ Prometheus доступен${NC}"
else
    echo -e "${RED}❌ Prometheus недоступен${NC}"
    exit 1
fi

# Проверка targets
echo ""
echo -e "${CYAN}=== Проверка Prometheus Targets ===${NC}"
targets_response=$(curl -s "$PROMETHEUS_URL/api/v1/targets")

# Подсчет активных targets
up_count=$(echo "$targets_response" | grep -o '"health":"up"' | wc -l)
down_count=$(echo "$targets_response" | grep -o '"health":"down"' | wc -l)

echo "Активных targets (UP): $up_count"
echo "Неактивных targets (DOWN): $down_count"

if [ $up_count -ge 3 ]; then
    echo -e "${GREEN}✅ Все основные targets активны${NC}"
else
    echo -e "${YELLOW}⚠️  Некоторые targets неактивны${NC}"
fi

# Извлечение информации о targets
echo ""
echo -e "${CYAN}Детали targets:${NC}"
echo "$targets_response" | grep -o '"job":"[^"]*","instance":"[^"]*","health":"[^"]*"' | while read line; do
    job=$(echo "$line" | grep -o '"job":"[^"]*"' | cut -d'"' -f4)
    instance=$(echo "$line" | grep -o '"instance":"[^"]*"' | cut -d'"' -f4)
    health=$(echo "$line" | grep -o '"health":"[^"]*"' | cut -d'"' -f4)
    
    if [ "$health" = "up" ]; then
        echo -e "  ${GREEN}✅${NC} $job - $instance - $health"
    else
        echo -e "  ${RED}❌${NC} $job - $instance - $health"
    fi
done

# Проверка метрик Node Exporter
echo ""
echo -e "${CYAN}=== Проверка метрик Node Exporter ===${NC}"

# CPU метрики
echo -n "Проверка CPU метрик... "
cpu_query='node_cpu_seconds_total'
cpu_result=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=$cpu_query" | grep -o '"status":"success"')
if [ -n "$cpu_result" ]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAILED${NC}"
fi

# Memory метрики
echo -n "Проверка Memory метрик... "
mem_query='node_memory_MemTotal_bytes'
mem_result=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=$mem_query" | grep -o '"status":"success"')
if [ -n "$mem_result" ]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAILED${NC}"
fi

# Disk метрики
echo -n "Проверка Disk метрик... "
disk_query='node_filesystem_size_bytes'
disk_result=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=$disk_query" | grep -o '"status":"success"')
if [ -n "$disk_result" ]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAILED${NC}"
fi

# Network метрики
echo -n "Проверка Network метрик... "
net_query='node_network_receive_bytes_total'
net_result=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=$net_query" | grep -o '"status":"success"')
if [ -n "$net_result" ]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAILED${NC}"
fi

# Тестовые PromQL запросы
echo ""
echo -e "${CYAN}=== Тестовые PromQL запросы ===${NC}"

# CPU Usage
echo ""
echo -e "${YELLOW}1. CPU Usage:${NC}"
cpu_usage_query='100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)'
echo "Query: $cpu_usage_query"
cpu_usage=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=$(echo $cpu_usage_query | sed 's/ /%20/g')" | grep -o '"value":\[[^]]*\]' | head -3)
if [ -n "$cpu_usage" ]; then
    echo -e "${GREEN}✅ Результат получен${NC}"
    echo "$cpu_usage" | while read line; do
        echo "  $line"
    done
else
    echo -e "${RED}❌ Нет данных${NC}"
fi

# Memory Usage
echo ""
echo -e "${YELLOW}2. Memory Usage:${NC}"
mem_usage_query='100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))'
echo "Query: $mem_usage_query"
mem_usage=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=$(echo $mem_usage_query | sed 's/ /%20/g')" | grep -o '"value":\[[^]]*\]' | head -3)
if [ -n "$mem_usage" ]; then
    echo -e "${GREEN}✅ Результат получен${NC}"
    echo "$mem_usage" | while read line; do
        echo "  $line"
    done
else
    echo -e "${RED}❌ Нет данных${NC}"
fi

# Disk Usage
echo ""
echo -e "${YELLOW}3. Disk Usage:${NC}"
disk_usage_query='100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)'
echo "Query: $disk_usage_query"
disk_usage=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=$(echo $disk_usage_query | sed 's/ /%20/g' | sed 's/\//%2F/g')" | grep -o '"value":\[[^]]*\]' | head -3)
if [ -n "$disk_usage" ]; then
    echo -e "${GREEN}✅ Результат получен${NC}"
    echo "$disk_usage" | while read line; do
        echo "  $line"
    done
else
    echo -e "${RED}❌ Нет данных${NC}"
fi

# Проверка Grafana
echo ""
echo -e "${CYAN}=== Проверка Grafana ===${NC}"
if curl -s -o /dev/null -w "%{http_code}" "$GRAFANA_URL" | grep -q "302\|200"; then
    echo -e "${GREEN}✅ Grafana доступна${NC}"
else
    echo -e "${RED}❌ Grafana недоступна${NC}"
fi

# Проверка Grafana API
echo -n "Проверка Grafana API... "
grafana_health=$(curl -s "$GRAFANA_URL/api/health" | grep -o '"database":"ok"')
if [ -n "$grafana_health" ]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${YELLOW}⚠️  Требуется аутентификация${NC}"
fi

# Проверка Node Exporter на серверах
echo ""
echo -e "${CYAN}=== Проверка Node Exporter на серверах ===${NC}"

SSH_KEY="$HOME/.ssh/diplom_key.pem"

if [ ! -f "$SSH_KEY" ]; then
    echo -e "${YELLOW}⚠️  SSH ключ не найден: $SSH_KEY${NC}"
    echo "Получите ключ командой: terraform output -raw ssh_private_key > $SSH_KEY && chmod 600 $SSH_KEY"
else
    # Web Server 1
    echo -n "Web Server 1 (10.0.2.21:9100)... "
    if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=5 "ubuntu@$BASTION_IP" \
        "curl -s http://10.0.2.21:9100/metrics | head -1" 2>/dev/null | grep -q "node_exporter"; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ FAILED${NC}"
    fi
    
    # Web Server 2
    echo -n "Web Server 2 (10.0.3.3:9100)... "
    if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=5 "ubuntu@$BASTION_IP" \
        "curl -s http://10.0.3.3:9100/metrics | head -1" 2>/dev/null | grep -q "node_exporter"; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ FAILED${NC}"
    fi
    
    # Kibana Server
    echo -n "Kibana Server (10.0.1.3:9100)... "
    if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=5 "ubuntu@$BASTION_IP" \
        "curl -s http://10.0.1.3:9100/metrics | head -1" 2>/dev/null | grep -q "node_exporter"; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ FAILED${NC}"
    fi
fi

# Итоговый отчет
echo ""
echo -e "${CYAN}=== ИТОГОВЫЙ ОТЧЕТ ===${NC}"
echo -e "${GREEN}✅ Проверка метрик завершена${NC}"
echo ""
echo "Доступ к сервисам:"
echo "  Prometheus:  $PROMETHEUS_URL"
echo "  Grafana:     $GRAFANA_URL"
echo ""
echo "Полезные ссылки:"
echo "  Targets:     $PROMETHEUS_URL/targets"
echo "  Graph:       $PROMETHEUS_URL/graph"
echo "  Alerts:      $PROMETHEUS_URL/alerts"
echo ""
echo "Учетные данные Grafana:"
echo "  Логин:       admin"
echo "  Пароль:      (установленный при настройке)"
echo ""
echo "Подробная информация: ACCESS_GUIDE.md"

