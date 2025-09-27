# Обзор сервисов

## Архитектура сервисов

Проект включает в себя несколько ключевых сервисов, обеспечивающих веб-приложение, мониторинг и логирование.

## Веб-сервисы

### Nginx Web Servers
- **Серверы:** `10.0.1.5`, `10.0.2.5`
- **Порт:** 80 (HTTP)
- **Назначение:** Обслуживание веб-контента
- **Конфигурация:**
  - Статический контент
  - Gzip сжатие
  - Кэширование статических файлов
  - Логирование доступа и ошибок

#### Конфигурация Nginx
```nginx
server {
    listen 80;
    server_name _;
    
    root /var/www/html;
    index index.html index.htm;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Логирование
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    # Gzip сжатие
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
}
```

### Application Load Balancer
- **IP-адрес:** `158.160.99.254`
- **Порты:** 80 (HTTP), 443 (HTTPS)
- **Алгоритм:** Round Robin
- **Health Checks:** HTTP GET / каждые 30 секунд
- **Таймауты:** 
  - Подключение: 5 секунд
  - Ответ: 30 секунд

## Мониторинг

### Zabbix Server
- **Сервер:** `10.0.3.5`
- **Веб-интерфейс:** `http://158.160.99.254:80/zabbix`
- **Порты:** 
  - 80 (HTTP) - веб-интерфейс
  - 10051 (TCP) - Zabbix Server
- **Учетные данные:** admin/zabbix

#### Мониторируемые метрики
- **Системные ресурсы:**
  - CPU utilization
  - Memory usage
  - Disk space
  - Network traffic
  - Load average

- **Сервисы:**
  - Nginx status
  - SSH availability
  - HTTP response time
  - Elasticsearch cluster health

#### Настроенные триггеры
- CPU > 80% в течение 5 минут
- Memory > 90% в течение 3 минут
- Disk space < 10%
- HTTP service недоступен
- SSH service недоступен

### Prometheus Stack (Docker)
- **Prometheus:** `http://localhost:9090`
- **Grafana:** `http://localhost:3000` (admin/admin)
- **AlertManager:** `http://localhost:9093`

#### Экспортеры
- **Node Exporter:** Системные метрики
- **Blackbox Exporter:** Проверка доступности
- **cAdvisor:** Метрики контейнеров

## Логирование

### Elasticsearch Cluster
- **Сервер:** `10.0.3.5`
- **Порты:**
  - 9200 (HTTP) - REST API
  - 9300 (TCP) - Transport протокол
- **Кластер:** docker-cluster
- **Статус:** Yellow (single node)

#### Индексы
- **logs** - основные логи приложений
- **test-logs** - тестовые записи
- **.geoip_databases** - геолокационные данные

#### Конфигурация
```yaml
cluster.name: docker-cluster
node.name: elasticsearch
network.host: 0.0.0.0
discovery.type: single-node
xpack.security.enabled: false
```

### Kibana
- **Сервер:** `10.0.3.5`
- **Порт:** 5601
- **Доступ:** `http://158.160.99.254:5601`
- **Подключение:** Elasticsearch на `localhost:9200`

#### Настроенные индексы
- **logs*** - паттерн для всех логов
- **test-logs*** - паттерн для тестовых логов

### Log Shipping
- **Протокол:** Beats (порт 5044)
- **Агент:** Python скрипт `log_shipper.py`
- **Источники логов:**
  - `/var/log/nginx/access.log`
  - `/var/log/nginx/error.log`
  - `/var/log/syslog`
  - `/var/log/auth.log`

#### Конфигурация log_shipper.py
```python
ELASTICSEARCH_HOST = "10.0.3.5"
ELASTICSEARCH_PORT = 9200
LOG_FILES = [
    "/var/log/nginx/access.log",
    "/var/log/nginx/error.log",
    "/var/log/syslog",
    "/var/log/auth.log"
]
```

### Loki Stack (Docker)
- **Loki:** `http://localhost:3100`
- **Promtail:** Агент сбора логов
- **Интеграция:** Grafana datasource

## Безопасность

### SSH Access
- **Bastion Host:** `158.160.99.254:22`
- **Аутентификация:** Только SSH ключи
- **Пользователь:** ubuntu

#### Подключение к серверам
```bash
# Bastion Host
ssh -i ssh_key.pem ubuntu@158.160.99.254

# Web Server 1 (через Bastion)
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.1.5

# Web Server 2 (через Bastion)
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.2.5

# Monitoring Server (через Bastion)
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5
```

### Firewall Rules
- **Входящий трафик:** Только разрешенные порты
- **Исходящий трафик:** HTTP/HTTPS для обновлений
- **Внутренний трафик:** Между серверами по необходимости

## Резервное копирование

### Конфигурации
- Ansible playbooks автоматически создают резервные копии конфигураций
- Конфигурации хранятся в Git репозитории

### Данные
- Elasticsearch snapshots (настраивается отдельно)
- Zabbix database backup (настраивается отдельно)

## Мониторинг состояния сервисов

### Health Checks
- **Load Balancer:** HTTP GET / каждые 30 секунд
- **Zabbix:** Мониторинг всех сервисов каждые 60 секунд
- **Prometheus:** Scraping метрик каждые 15 секунд

### Алерты
- **Zabbix:** Email уведомления при проблемах
- **AlertManager:** Интеграция с Slack/Email
- **Grafana:** Встроенные алерты на дашбордах

## Производительность

### Оптимизация Nginx
- Gzip сжатие для текстовых файлов
- Кэширование статических ресурсов
- Keep-alive соединения
- Worker processes = CPU cores

### Оптимизация Elasticsearch
- Heap size = 50% от RAM
- Индексирование в batch режиме
- Оптимизированные mapping'и для логов

### Мониторинг производительности
- Response time мониторинг через Blackbox Exporter
- Resource utilization через Node Exporter
- Application metrics через custom exporters