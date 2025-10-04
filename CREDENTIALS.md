# 🔐 УЧЕТНЫЕ ДАННЫЕ И ДОСТУП К СЕРВИСАМ

> ⚠️ **ВАЖНО:** Этот файл содержит примеры учетных данных для демонстрации.
> При развертывании собственной инфраструктуры замените все пароли на безопасные!

**Дата обновления:** 04.10.2025
**Статус:** ✅ Все основные сервисы развернуты и работают

---

## 🌐 ПУБЛИЧНЫЕ СЕРВИСЫ

### Load Balancer ✅
- **URL:** `http://YOUR_LOAD_BALANCER_IP`
- **Описание:** Балансирует трафик между Web Server 1 и Web Server 2
- **Статус:** ✅ Активен и работает
- **Проверка:** `curl http://YOUR_LOAD_BALANCER_IP`
- **Примечание:** IP адрес получите командой `terraform output load_balancer_external_ip`

### Grafana ✅
- **URL:** `http://YOUR_KIBANA_SERVER_IP:3000`
- **Логин:** `admin`
- **Пароль:** `your_secure_password_here` (измените при первом входе!)
- **Статус:** ✅ Работает
- **Дашборды:** Node Exporter Full (ID: 1860)
- **Data Source:** Prometheus (http://localhost:9090)

### Prometheus ✅
- **URL:** `http://YOUR_KIBANA_SERVER_IP:9090`
- **Аутентификация:** Не требуется
- **Статус:** ✅ Работает
- **Targets:** Web Server 1, Web Server 2, Kibana Server
- **Проверка:** `curl http://YOUR_KIBANA_SERVER_IP:9090/api/v1/status/config`

### Kibana ✅
- **URL:** `http://YOUR_KIBANA_SERVER_IP:5601`
- **Аутентификация:** Отключена (для разработки)
- **Статус:** ✅ Работает
- **Elasticsearch:** http://10.0.4.34:9200
- **Проверка:** `curl http://YOUR_KIBANA_SERVER_IP:5601/api/status`

### Zabbix Server (Опционально)
- **URL:** `http://YOUR_ZABBIX_IP`
- **Логин:** `Admin`
- **Пароль:** `your_zabbix_password`
- **База данных:**
  - Имя: `zabbix`
  - Пользователь: `zabbix`
  - Пароль: `your_db_password`
- **Статус:** ⏳ Опциональный компонент
- **Примечание:** Установка через скрипт `/tmp/setup_zabbix.sh`

---

## 🖥️ ВНУТРЕННИЕ СЕРВИСЫ

### Web Server 1 ✅
- **IP:** `10.0.2.21` (пример, может отличаться)
- **Зона:** ru-central1-a
- **ОС:** Ubuntu 20.04 LTS
- **Сервисы:** Nginx 1.18.0 + PHP 7.4-FPM
- **Статус:** ✅ Активен
- **Доступ:** Через Load Balancer или Bastion
- **Мониторинг:** Node Exporter на порту 9100

### Web Server 2 ✅
- **IP:** `10.0.3.3` (пример, может отличаться)
- **Зона:** ru-central1-b
- **ОС:** Ubuntu 20.04 LTS
- **Сервисы:** Nginx 1.18.0 + PHP 7.4-FPM
- **Статус:** ✅ Активен
- **Доступ:** Через Load Balancer или Bastion
- **Мониторинг:** Node Exporter на порту 9100

### Elasticsearch ✅
- **IP:** `10.0.4.34` (пример, может отличаться)
- **Порт:** 9200, 9300
- **Зона:** ru-central1-b
- **ОС:** Ubuntu 20.04 LTS
- **Версия:** 8.11.0 (Docker)
- **Статус:** ✅ Работает
- **Режим:** Single-node
- **Проверка:** `curl http://10.0.4.34:9200`

### Kibana Server (Мультисервисный) ✅
- **IP:** `10.0.1.3` (пример, может отличаться)
- **Зона:** ru-central1-a
- **ОС:** Ubuntu 20.04 LTS
- **Статус:** ✅ Активен
- **Сервисы:**
  - Kibana 8.11.0 (Docker) - порт 5601
  - Grafana 10.2.2 (Docker) - порт 3000
  - Prometheus 2.48.0 - порт 9090
  - Node Exporter 1.7.0 - порт 9100

---

## 🔑 SSH ДОСТУП

### Получение SSH ключа

После развертывания инфраструктуры получите SSH ключ:

```bash
cd terraform
terraform output -raw ssh_private_key > ~/.ssh/diplom_key.pem
chmod 600 ~/.ssh/diplom_key.pem
```

### Bastion Host
- **IP:** `YOUR_BASTION_IP` (получите через `terraform output bastion_external_ip`)
- **Пользователь:** `ubuntu`
- **Ключ:** `~/.ssh/diplom_key.pem`
- **Команда подключения:**
  ```bash
  ssh -i ~/.ssh/diplom_key.pem ubuntu@YOUR_BASTION_IP
  ```

### Подключение к внутренним серверам

Все внутренние серверы доступны только через Bastion Host (ProxyJump).

#### Web Server 1
```bash
ssh -i ~/.ssh/diplom_key.pem -o ProxyCommand="ssh -i ~/.ssh/diplom_key.pem -W %h:%p ubuntu@YOUR_BASTION_IP" ubuntu@10.0.2.21
```

#### Web Server 2
```bash
ssh -i ~/.ssh/diplom_key.pem -o ProxyCommand="ssh -i ~/.ssh/diplom_key.pem -W %h:%p ubuntu@YOUR_BASTION_IP" ubuntu@10.0.3.3
```

#### Kibana Server (Grafana, Prometheus)
```bash
ssh -i ~/.ssh/diplom_key.pem -o ProxyCommand="ssh -i ~/.ssh/diplom_key.pem -W %h:%p ubuntu@YOUR_BASTION_IP" ubuntu@10.0.1.3
```

#### Elasticsearch Server
```bash
ssh -i ~/.ssh/diplom_key.pem -o ProxyCommand="ssh -i ~/.ssh/diplom_key.pem -W %h:%p ubuntu@YOUR_BASTION_IP" ubuntu@10.0.4.34
```

#### Zabbix Server
```bash
ssh -i ~/.ssh/diplom_key.pem -o ProxyCommand="ssh -i ~/.ssh/diplom_key.pem -W %h:%p ubuntu@158.160.104.48" ubuntu@10.0.1.14
```

#### Kibana Server
```bash
ssh -i ~/.ssh/diplom_key.pem -o ProxyCommand="ssh -i ~/.ssh/diplom_key.pem -W %h:%p ubuntu@158.160.104.48" ubuntu@10.0.1.3
```

#### Elasticsearch
```bash
ssh -i ~/.ssh/diplom_key.pem -o ProxyCommand="ssh -i ~/.ssh/diplom_key.pem -W %h:%p ubuntu@158.160.104.48" ubuntu@10.0.4.34
```

### Упрощенное подключение с Bastion

После подключения к Bastion:
```bash
# Web Server 1
ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@10.0.2.21

# Web Server 2
ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@10.0.3.3

# Zabbix
ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@10.0.1.14

# Kibana
ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@10.0.1.3

# Elasticsearch
ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@10.0.4.34
```

---

## ☁️ YANDEX CLOUD

### Учетные данные
- **Cloud ID:** b1gacd76ggtuvbh46emd
- **Folder ID:** b1g2k7uoqgh74u5ddj31
- **Service Account ID:** aje8vmm1drutck6a20uv
- **Ключ аутентификации:** `authorized_key.json` (в корне проекта)

### Terraform
- **Версия:** 1.11.3
- **Провайдер:** yandex-cloud/yandex v0.159.0
- **State файл:** `terraform/terraform.tfstate`
- **Создано ресурсов:** 26

---

## 📁 РАСПОЛОЖЕНИЕ ФАЙЛОВ

### SSH Ключи
- **Windows:** `C:\temp\ssh_key_python.pem`
- **WSL:** `~/.ssh/diplom_key.pem`
- **Bastion:** `/tmp/diplom_key.pem`

### Скрипты установки (на Bastion)
- `/tmp/setup_web1.sh` - Установка Web Server 1 ✅
- `/tmp/setup_web2.sh` - Установка Web Server 2 ✅
- `/tmp/setup_zabbix.sh` - Установка Zabbix Server ⏳
- `/tmp/setup_elasticsearch.sh` - Установка Elasticsearch ⏳
- `/tmp/setup_kibana.sh` - Установка Kibana ⏳

### Ansible (на Bastion)
- `/tmp/ansible/` - Ansible playbooks и роли
- `/tmp/ansible/inventory/hosts_bastion.yml` - Inventory для запуска с Bastion

---

## 🔒 БЕЗОПАСНОСТЬ

### Security Groups

#### Bastion
- **Входящий:** SSH (22) от 0.0.0.0/0
- **Исходящий:** Все

#### Web Servers
- **Входящий:** 
  - SSH (22) от Bastion
  - HTTP (80) от Load Balancer
  - Zabbix Agent (10050) от Zabbix Server
- **Исходящий:** Все

#### Zabbix Server
- **Входящий:**
  - SSH (22) от Bastion
  - HTTP (80) от 0.0.0.0/0
  - Zabbix Server (10051) от 10.0.0.0/8
- **Исходящий:** Все

#### Elasticsearch
- **Входящий:**
  - SSH (22) от Bastion
  - API (9200) от Kibana и Web Servers
  - Beats (5044) от 10.0.0.0/8
- **Исходящий:** Все

#### Kibana
- **Входящий:**
  - SSH (22) от Bastion
  - Web (5601) от 0.0.0.0/0
- **Исходящий:** Все

---

## ⚠️ ВАЖНЫЕ ЗАМЕЧАНИЯ

1. **Пароли по умолчанию:** Необходимо изменить после первого входа
2. **SSL/TLS:** Не настроен, требуется для production
3. **Firewall:** Настроен через Security Groups
4. **Резервное копирование:** Snapshot schedule создан в Terraform
5. **Мониторинг:** Требует настройки после установки Zabbix

---

## 📞 КОМАНДЫ ДЛЯ БЫСТРОГО ДОСТУПА

### Проверка статуса Load Balancer
```bash
curl -I http://158.160.168.17
```

### Проверка балансировки
```bash
for i in {1..5}; do curl -s http://158.160.168.17 | grep "Web Server"; done
```

### Подключение к Bastion
```bash
ssh -i ~/.ssh/diplom_key.pem ubuntu@158.160.104.48
```

### Просмотр логов на серверах
```bash
# Nginx access log
sudo tail -f /var/log/nginx/access.log

# Nginx error log
sudo tail -f /var/log/nginx/error.log

# System log
sudo journalctl -f
```

---

## 📊 СТАТУС СЕРВИСОВ

| Сервис | IP | Статус | URL |
|--------|----|----|-----|
| Load Balancer | 158.160.168.17 | ✅ Работает | http://158.160.168.17 |
| Web Server 1 | 10.0.2.21 | ✅ Работает | Внутренний |
| Web Server 2 | 10.0.3.3 | ✅ Работает | Внутренний |
| Bastion | 158.160.104.48 | ✅ Доступен | SSH |
| Zabbix | 158.160.112.98 | ⏳ Ожидает | http://158.160.112.98 |
| Kibana | 62.84.112.42 | ⏳ Ожидает | http://62.84.112.42:5601 |
| Elasticsearch | 10.0.4.34 | ⏳ Ожидает | Внутренний:9200 |

**Легенда:**
- ✅ Работает - Сервис установлен и функционирует
- ⏳ Ожидает - Требуется установка/настройка
- ❌ Ошибка - Требуется исправление

---

**Последнее обновление:** 04.10.2025, 13:05 UTC

