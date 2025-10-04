#!/bin/bash

# Скрипт проверки работоспособности всех сервисов
# Использование: ./check_all_services.sh

set -e

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для проверки HTTP статуса
check_http() {
    local url=$1
    local name=$2
    
    echo -n "Проверка $name... "
    
    if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" | grep -q "200\|302"; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ FAILED${NC}"
        return 1
    fi
}

# Получение IP адресов из Terraform
echo "=== Получение IP адресов из Terraform ==="
cd terraform

BASTION_IP=$(terraform output -raw bastion_external_ip 2>/dev/null || echo "")
LB_IP=$(terraform output -raw load_balancer_external_ip 2>/dev/null || echo "")
KIBANA_IP=$(terraform output -raw kibana_external_ip 2>/dev/null || echo "")

if [ -z "$BASTION_IP" ] || [ -z "$LB_IP" ] || [ -z "$KIBANA_IP" ]; then
    echo -e "${RED}❌ Не удалось получить IP адреса из Terraform${NC}"
    echo "Убедитесь, что инфраструктура развернута: terraform apply"
    exit 1
fi

echo -e "${GREEN}✅ IP адреса получены:${NC}"
echo "  Bastion: $BASTION_IP"
echo "  Load Balancer: $LB_IP"
echo "  Kibana Server: $KIBANA_IP"
echo ""

cd ..

# Проверка публичных сервисов
echo "=== Проверка публичных сервисов ==="

check_http "http://$LB_IP" "Load Balancer"
check_http "http://$KIBANA_IP:3000" "Grafana"
check_http "http://$KIBANA_IP:9090" "Prometheus"
check_http "http://$KIBANA_IP:5601" "Kibana"

echo ""

# Проверка балансировки
echo "=== Проверка балансировки Load Balancer ==="
echo "Выполняем 10 запросов..."

server1_count=0
server2_count=0

for i in {1..10}; do
    response=$(curl -s "http://$LB_IP" | grep -o "WEB SERVER [12]" || echo "ERROR")
    
    if [[ $response == "WEB SERVER 1" ]]; then
        ((server1_count++))
        echo -e "  Запрос $i: ${GREEN}Server 1${NC}"
    elif [[ $response == "WEB SERVER 2" ]]; then
        ((server2_count++))
        echo -e "  Запрос $i: ${GREEN}Server 2${NC}"
    else
        echo -e "  Запрос $i: ${RED}ERROR${NC}"
    fi
    
    sleep 0.5
done

echo ""
echo "Результаты балансировки:"
echo "  Server 1: $server1_count запросов"
echo "  Server 2: $server2_count запросов"

if [ $server1_count -gt 0 ] && [ $server2_count -gt 0 ]; then
    echo -e "${GREEN}✅ Балансировка работает корректно${NC}"
else
    echo -e "${RED}❌ Проблема с балансировкой${NC}"
fi

echo ""

# Проверка Prometheus targets
echo "=== Проверка Prometheus Targets ==="
targets=$(curl -s "http://$KIBANA_IP:9090/api/v1/targets" | grep -o '"health":"up"' | wc -l)
echo "Активных targets: $targets"

if [ $targets -ge 3 ]; then
    echo -e "${GREEN}✅ Все targets активны${NC}"
else
    echo -e "${YELLOW}⚠️  Некоторые targets неактивны${NC}"
fi

echo ""

# Проверка внутренних сервисов через Bastion
echo "=== Проверка внутренних сервисов (через Bastion) ==="

SSH_KEY="~/.ssh/diplom_key.pem"

if [ ! -f "$SSH_KEY" ]; then
    echo -e "${YELLOW}⚠️  SSH ключ не найден: $SSH_KEY${NC}"
    echo "Получите ключ командой: terraform output -raw ssh_private_key > $SSH_KEY && chmod 600 $SSH_KEY"
else
    echo -n "Проверка Elasticsearch... "
    if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=5 "ubuntu@$BASTION_IP" \
        "curl -s http://10.0.4.34:9200" | grep -q "You Know, for Search"; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ FAILED${NC}"
    fi
    
    echo -n "Проверка Node Exporter на Web1... "
    if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=5 "ubuntu@$BASTION_IP" \
        "curl -s http://10.0.2.21:9100/metrics" | grep -q "node_exporter"; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ FAILED${NC}"
    fi
    
    echo -n "Проверка Node Exporter на Web2... "
    if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=5 "ubuntu@$BASTION_IP" \
        "curl -s http://10.0.3.3:9100/metrics" | grep -q "node_exporter"; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ FAILED${NC}"
    fi
fi

echo ""

# Итоговый отчет
echo "=== ИТОГОВЫЙ ОТЧЕТ ==="
echo -e "${GREEN}✅ Проверка завершена${NC}"
echo ""
echo "Доступ к сервисам:"
echo "  Load Balancer:  http://$LB_IP"
echo "  Grafana:        http://$KIBANA_IP:3000 (admin / your_password)"
echo "  Prometheus:     http://$KIBANA_IP:9090"
echo "  Kibana:         http://$KIBANA_IP:5601"
echo "  Bastion SSH:    ssh -i $SSH_KEY ubuntu@$BASTION_IP"
echo ""
echo "Подробная информация: ACCESS_GUIDE.md"

