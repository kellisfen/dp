# 🔐 РУКОВОДСТВО ПО ДОСТУПУ К СЕРВИСАМ

**Версия:** 1.0  
**Дата:** 04.10.2025  
**Статус:** Все основные сервисы работают ✅

---

## 📋 СОДЕРЖАНИЕ

1. [Получение IP адресов](#получение-ip-адресов)
2. [Web-серверы и Load Balancer](#web-серверы-и-load-balancer)
3. [Grafana - Визуализация метрик](#grafana---визуализация-метрик)
4. [Prometheus - Сбор метрик](#prometheus---сбор-метрик)
5. [Kibana - Анализ логов](#kibana---анализ-логов)
6. [Elasticsearch - Хранение логов](#elasticsearch---хранение-логов)
7. [Bastion Host - SSH доступ](#bastion-host---ssh-доступ)
8. [Проверка работоспособности](#проверка-работоспособности)

---

## 🌐 ПОЛУЧЕНИЕ IP АДРЕСОВ

После развертывания инфраструктуры получите все IP адреса:

```bash
cd terraform
terraform output
```

**Основные выходные переменные:**
- `bastion_external_ip` - IP Bastion Host
- `load_balancer_external_ip` - IP Load Balancer
- `kibana_external_ip` - IP сервера с Kibana/Grafana/Prometheus
- `web1_internal_ip` - Внутренний IP Web Server 1
- `web2_internal_ip` - Внутренний IP Web Server 2
- `elasticsearch_internal_ip` - Внутренний IP Elasticsearch

---

## 🌍 WEB-СЕРВЕРЫ И LOAD BALANCER

### Доступ через Load Balancer

**URL:** `http://YOUR_LOAD_BALANCER_IP`

### Проверка балансировки

Load Balancer распределяет запросы между двумя веб-серверами:

```bash
# Выполните несколько запросов
for i in {1..10}; do
  curl -s http://YOUR_LOAD_BALANCER_IP | grep "WEB SERVER"
done
```

**Ожидаемый результат:**
```
WEB SERVER 1
WEB SERVER 2
WEB SERVER 1
WEB SERVER 2
...
```

### Особенности веб-страниц

- **Web Server 1:** Фиолетовая цветовая схема
- **Web Server 2:** Зеленая цветовая схема
- **Технологии:** Bootstrap 5.3.2, PHP 7.4, Nginx 1.18.0
- **Функции:**
  - Счетчик запросов
  - Отображение времени в реальном времени
  - Информация о сервере (hostname, IP, uptime)
  - Адаптивный дизайн

### Проверка отдельных серверов

Через Bastion Host можно проверить каждый сервер отдельно:

```bash
# Web Server 1
ssh -i ~/.ssh/diplom_key.pem ubuntu@YOUR_BASTION_IP \
  "curl -s http://10.0.2.21 | grep 'WEB SERVER'"

# Web Server 2
ssh -i ~/.ssh/diplom_key.pem ubuntu@YOUR_BASTION_IP \
  "curl -s http://10.0.3.3 | grep 'WEB SERVER'"
```

---

## 📊 GRAFANA - ВИЗУАЛИЗАЦИЯ МЕТРИК

### Доступ к Grafana

**URL:** `http://YOUR_KIBANA_SERVER_IP:3000`

### Учетные данные

- **Логин:** `admin`
- **Пароль по умолчанию:** `admin` (измените при первом входе!)
- **Рекомендуемый пароль:** Используйте сложный пароль (минимум 12 символов)

### Первый вход

1. Откройте браузер и перейдите по URL
2. Введите логин `admin` и пароль `admin`
3. Система предложит изменить пароль - **обязательно измените!**
4. После входа вы увидите главную страницу Grafana

### Настроенные компоненты

#### Data Source: Prometheus
- **Имя:** Prometheus
- **Тип:** Prometheus
- **URL:** http://localhost:9090
- **Статус:** ✅ Подключен и работает

#### Dashboard: Node Exporter Full
- **ID:** 1860
- **Описание:** Полный мониторинг системных метрик
- **Метрики:**
  - CPU Usage (загрузка процессора)
  - Memory Usage (использование памяти)
  - Disk I/O (операции чтения/записи)
  - Network Traffic (сетевой трафик)
  - System Load (нагрузка системы)
  - Disk Space (свободное место на дисках)

### Просмотр дашбордов

1. В левом меню выберите **Dashboards** (иконка с четырьмя квадратами)
2. Найдите дашборд **Node Exporter Full**
3. Выберите сервер из выпадающего списка:
   - Web Server 1 (10.0.2.21:9100)
   - Web Server 2 (10.0.3.3:9100)
   - Kibana Server (10.0.1.3:9100)

### Создание собственных дашбордов

1. Нажмите **+ Create** → **Dashboard**
2. Добавьте панель: **Add visualization**
3. Выберите **Prometheus** как источник данных
4. Введите PromQL запрос, например:
   ```promql
   # CPU Usage
   100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

   # Memory Usage
   100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))

   # Disk Usage
   100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)
   ```

5. Настройте визуализацию:
   - **Тип:** Time series, Gauge, Stat, Bar gauge, Table
   - **Единицы:** Percent (0-100), Bytes, Seconds
   - **Пороги:** Green (0-70), Yellow (70-85), Red (85-100)
   - **Легенда:** {{instance}}, {{job}}, {{device}}

6. Сохраните панель и дашборд

> 📚 **Подробное руководство:** См. [GRAFANA_DASHBOARDS_GUIDE.md](GRAFANA_DASHBOARDS_GUIDE.md)
> 📊 **Примеры запросов:** См. [PROMQL_QUERIES.md](PROMQL_QUERIES.md)

### Проверка работоспособности

```bash
# Проверка доступности
curl -I http://YOUR_KIBANA_SERVER_IP:3000

# Проверка API
curl http://YOUR_KIBANA_SERVER_IP:3000/api/health

# Ожидаемый ответ
# {"commit":"...","database":"ok","version":"10.2.2"}
```

---

## 🔍 PROMETHEUS - СБОР МЕТРИК

### Доступ к Prometheus

**URL:** `http://YOUR_KIBANA_SERVER_IP:9090`

### Интерфейс Prometheus

Prometheus не требует аутентификации и доступен сразу после открытия URL.

### Основные разделы

#### 1. Graph (Графики)
- Выполнение PromQL запросов
- Построение графиков метрик
- Просмотр данных в табличном виде

#### 2. Alerts (Алерты)
- Просмотр активных алертов
- Статус правил алертинга

#### 3. Status (Статус)
- **Targets:** Список всех целей мониторинга
- **Configuration:** Текущая конфигурация
- **Rules:** Правила алертинга
- **Service Discovery:** Обнаружение сервисов

### Проверка целей мониторинга

1. Откройте **Status** → **Targets**
2. Убедитесь, что все цели в статусе **UP**:
   - `prometheus` (localhost:9090)
   - `web_servers` (10.0.2.21:9100, 10.0.3.3:9100)

**Ожидаемый вид:**
```
Endpoint                State    Labels
http://10.0.2.21:9100   UP       job="web_servers", instance="10.0.2.21:9100"
http://10.0.3.3:9100    UP       job="web_servers", instance="10.0.3.3:9100"
http://localhost:9090   UP       job="prometheus", instance="localhost:9090"
```

### Примеры PromQL запросов

#### Загрузка CPU
```promql
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

#### Использование памяти
```promql
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes
```

#### Свободное место на диске
```promql
node_filesystem_avail_bytes{mountpoint="/"}
```

#### Сетевой трафик (входящий)
```promql
rate(node_network_receive_bytes_total[5m])
```

#### Uptime серверов
```promql
node_time_seconds - node_boot_time_seconds
```

### Проверка работоспособности

```bash
# Проверка доступности
curl -I http://YOUR_KIBANA_SERVER_IP:9090

# Проверка конфигурации
curl http://YOUR_KIBANA_SERVER_IP:9090/api/v1/status/config

# Проверка целей
curl http://YOUR_KIBANA_SERVER_IP:9090/api/v1/targets

# Выполнение запроса
curl 'http://YOUR_KIBANA_SERVER_IP:9090/api/v1/query?query=up'
```

---

## 📈 KIBANA - АНАЛИЗ ЛОГОВ

### Доступ к Kibana

**URL:** `http://YOUR_KIBANA_SERVER_IP:5601`

### Первый вход

1. Откройте браузер и перейдите по URL
2. Kibana загрузится автоматически (аутентификация отключена)
3. При первом запуске может потребоваться несколько минут для инициализации

### Основные разделы

#### 1. Discover (Обнаружение)
- Поиск и фильтрация логов
- Просмотр отдельных событий
- Создание запросов KQL (Kibana Query Language)

#### 2. Dashboard (Дашборды)
- Визуализация данных
- Создание графиков и диаграмм
- Мониторинг в реальном времени

#### 3. Dev Tools (Инструменты разработчика)
- Выполнение запросов к Elasticsearch
- Тестирование API
- Отладка индексов

### Подключение к Elasticsearch

Kibana автоматически подключена к Elasticsearch:
- **URL:** http://10.0.4.34:9200
- **Статус:** Проверьте в **Stack Management** → **Index Management**

### Проверка работоспособности

```bash
# Проверка доступности
curl -I http://YOUR_KIBANA_SERVER_IP:5601

# Проверка API статуса
curl http://YOUR_KIBANA_SERVER_IP:5601/api/status

# Ожидаемый ответ (упрощенно)
# {"status":{"overall":{"level":"available"}}}
```

---

## 🗄️ ELASTICSEARCH - ХРАНЕНИЕ ЛОГОВ

### Доступ к Elasticsearch

**Внутренний IP:** `10.0.4.34`  
**Порт:** `9200`

> ⚠️ **Важно:** Elasticsearch доступен только из внутренней сети!

### Подключение через Bastion

```bash
# Через SSH туннель
ssh -i ~/.ssh/diplom_key.pem -L 9200:10.0.4.34:9200 ubuntu@YOUR_BASTION_IP

# Теперь Elasticsearch доступен локально
curl http://localhost:9200
```

### Проверка работоспособности

```bash
# Через Bastion Host
ssh -i ~/.ssh/diplom_key.pem ubuntu@YOUR_BASTION_IP \
  "curl -s http://10.0.4.34:9200"

# Ожидаемый ответ
{
  "name" : "elasticsearch",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "...",
  "version" : {
    "number" : "8.11.0",
    ...
  },
  "tagline" : "You Know, for Search"
}
```

### Основные API endpoints

```bash
# Информация о кластере
curl http://10.0.4.34:9200/_cluster/health

# Список индексов
curl http://10.0.4.34:9200/_cat/indices?v

# Статистика узлов
curl http://10.0.4.34:9200/_nodes/stats
```

---

## 🔐 BASTION HOST - SSH ДОСТУП

### Подключение к Bastion

**IP:** `YOUR_BASTION_IP`  
**Пользователь:** `ubuntu`  
**Ключ:** `~/.ssh/diplom_key.pem`

```bash
ssh -i ~/.ssh/diplom_key.pem ubuntu@YOUR_BASTION_IP
```

### Доступ к внутренним серверам

Все внутренние серверы доступны только через Bastion (ProxyJump):

```bash
# Web Server 1
ssh -i ~/.ssh/diplom_key.pem -o ProxyCommand="ssh -i ~/.ssh/diplom_key.pem -W %h:%p ubuntu@YOUR_BASTION_IP" ubuntu@10.0.2.21

# Web Server 2
ssh -i ~/.ssh/diplom_key.pem -o ProxyCommand="ssh -i ~/.ssh/diplom_key.pem -W %h:%p ubuntu@YOUR_BASTION_IP" ubuntu@10.0.3.3

# Kibana Server
ssh -i ~/.ssh/diplom_key.pem -o ProxyCommand="ssh -i ~/.ssh/diplom_key.pem -W %h:%p ubuntu@YOUR_BASTION_IP" ubuntu@10.0.1.3

# Elasticsearch Server
ssh -i ~/.ssh/diplom_key.pem -o ProxyCommand="ssh -i ~/.ssh/diplom_key.pem -W %h:%p ubuntu@YOUR_BASTION_IP" ubuntu@10.0.4.34
```

### Упрощенный доступ через SSH config

Создайте файл `~/.ssh/config`:

```
Host bastion
    HostName YOUR_BASTION_IP
    User ubuntu
    IdentityFile ~/.ssh/diplom_key.pem

Host web1
    HostName 10.0.2.21
    User ubuntu
    ProxyJump bastion
    IdentityFile ~/.ssh/diplom_key.pem

Host web2
    HostName 10.0.3.3
    User ubuntu
    ProxyJump bastion
    IdentityFile ~/.ssh/diplom_key.pem

Host kibana
    HostName 10.0.1.3
    User ubuntu
    ProxyJump bastion
    IdentityFile ~/.ssh/diplom_key.pem

Host elasticsearch
    HostName 10.0.4.34
    User ubuntu
    ProxyJump bastion
    IdentityFile ~/.ssh/diplom_key.pem
```

Теперь подключение упрощается:
```bash
ssh web1
ssh web2
ssh kibana
ssh elasticsearch
```

---

## ✅ ПРОВЕРКА РАБОТОСПОСОБНОСТИ

### Быстрая проверка всех сервисов

```bash
#!/bin/bash
# Сохраните как check_services.sh

echo "=== Проверка Load Balancer ==="
curl -I http://YOUR_LOAD_BALANCER_IP

echo -e "\n=== Проверка Grafana ==="
curl -I http://YOUR_KIBANA_SERVER_IP:3000

echo -e "\n=== Проверка Prometheus ==="
curl -I http://YOUR_KIBANA_SERVER_IP:9090

echo -e "\n=== Проверка Kibana ==="
curl -I http://YOUR_KIBANA_SERVER_IP:5601

echo -e "\n=== Проверка Elasticsearch (через Bastion) ==="
ssh -i ~/.ssh/diplom_key.pem ubuntu@YOUR_BASTION_IP \
  "curl -s http://10.0.4.34:9200 | jq '.version.number'"

echo -e "\n=== Проверка Node Exporter на Web1 ==="
ssh -i ~/.ssh/diplom_key.pem ubuntu@YOUR_BASTION_IP \
  "curl -s http://10.0.2.21:9100/metrics | head -n 5"

echo -e "\n=== Проверка Node Exporter на Web2 ==="
ssh -i ~/.ssh/diplom_key.pem ubuntu@YOUR_BASTION_IP \
  "curl -s http://10.0.3.3:9100/metrics | head -n 5"
```

### Ожидаемые результаты

Все сервисы должны возвращать:
- **HTTP 200 OK** для веб-интерфейсов
- **HTTP 302 Found** для редиректов (Grafana)
- **JSON ответы** для API endpoints

---

## 🆘 TROUBLESHOOTING

### Сервис недоступен

1. Проверьте статус Docker контейнера:
   ```bash
   ssh kibana
   sudo docker ps
   ```

2. Проверьте логи:
   ```bash
   sudo docker logs grafana
   sudo docker logs kibana
   sudo docker logs elasticsearch
   ```

3. Перезапустите контейнер:
   ```bash
   sudo docker restart grafana
   ```

### Prometheus не видит targets

1. Проверьте конфигурацию:
   ```bash
   ssh kibana
   cat /etc/prometheus/prometheus.yml
   ```

2. Проверьте статус сервиса:
   ```bash
   sudo systemctl status prometheus
   ```

3. Перезапустите Prometheus:
   ```bash
   sudo systemctl restart prometheus
   ```

### Node Exporter не отвечает

1. Проверьте статус:
   ```bash
   ssh web1
   sudo systemctl status node_exporter
   ```

2. Проверьте порт:
   ```bash
   sudo netstat -tulpn | grep 9100
   ```

3. Перезапустите сервис:
   ```bash
   sudo systemctl restart node_exporter
   ```

---

## 📞 ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ

### Документация
- [CREDENTIALS.md](CREDENTIALS.md) - Полный список учетных данных
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Руководство по развертыванию
- [CLEANUP_REPORT.md](CLEANUP_REPORT.md) - Отчет об очистке проекта
- [README.md](README.md) - Общая информация о проекте

### Полезные ссылки
- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Kibana Guide](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Elasticsearch Reference](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)

---

*Документ обновлен: 04.10.2025*

