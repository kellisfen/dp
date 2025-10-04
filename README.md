# 🚀 Дипломный проект DevOps

![Status](https://img.shields.io/badge/status-production%20ready-success)
![Terraform](https://img.shields.io/badge/terraform-1.6+-623CE4?logo=terraform)
![Ansible](https://img.shields.io/badge/ansible-2.15+-EE0000?logo=ansible)
![Yandex Cloud](https://img.shields.io/badge/yandex%20cloud-infrastructure-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![GitHub Release](https://img.shields.io/badge/release-v1.0.0-blue)

Автоматизированное развертывание отказоустойчивой веб-инфраструктуры в Yandex Cloud с использованием Infrastructure as Code (Terraform) и Configuration Management (Ansible).

**Статистика проекта:**
- 📦 **100+ файлов**, 15,000+ строк кода
- 🏗️ **26 Terraform ресурсов**, 6 виртуальных машин
- 📚 **15 документов**, 115+ страниц документации
- 🔧 **20+ Ansible playbooks**, 30+ скриптов автоматизации

## 🎯 Статус выполнения

- ✅ **Задача 1:** Elasticsearch установлен через Docker (8.11.0)
- ✅ **Задача 2:** Kibana установлена через Docker (8.11.0)
- ✅ **Задача 3:** Prometheus + Grafana + Node Exporter настроены
- ✅ **Задача 4:** Профессиональные HTML страницы развернуты
- ✅ **Задача 5:** Проект очищен от временных файлов
- ✅ **Задача 6:** Документация обновлена для GitHub
- ✅ **Задача 7:** Проект опубликован на GitHub

**Выполнение: 100%** | **Статус: Production Ready**

## 🚀 Быстрый старт

### 1. Клонирование репозитория
```bash
git clone https://github.com/kellisfen/dp.git
cd dp
```

### 2. Настройка учетных данных
```bash
# Создайте файл с учетными данными Yandex Cloud
# Скопируйте пример конфигурации
cp ansible/group_vars/all.yml.example ansible/group_vars/all.yml

# Создайте authorized_key.json с вашим service account key
# (см. документацию Yandex Cloud)
```

### 3. Развертывание инфраструктуры
```bash
# Инициализация Terraform
cd terraform
terraform init

# Проверка плана
terraform plan

# Применение конфигурации
terraform apply -auto-approve

# Получение SSH ключа
terraform output -raw ssh_private_key > ~/.ssh/diplom_key.pem
chmod 600 ~/.ssh/diplom_key.pem

# Получение IP адресов
terraform output
```

### 4. Настройка серверов через Ansible
```bash
cd ../ansible

# Обновите IP адреса в group_vars/all.yml из вывода terraform output
# Затем запустите настройку
ansible-playbook -i inventory/hosts.yml site.yml
```

### 5. Проверка работоспособности
```bash
# Проверка Load Balancer
curl http://158.160.168.17

# Проверка Grafana
curl http://62.84.112.42:3000

# Проверка Prometheus
curl http://62.84.112.42:9090

# Проверка Kibana
curl http://62.84.112.42:5601
```

## 🌐 Доступ к сервисам

| Сервис | URL | Порт | Учетные данные |
|--------|-----|------|----------------|
| **Load Balancer** | http://158.160.168.17 | 80 | - |
| **Grafana** | http://62.84.112.42:3000 | 3000 | См. [CREDENTIALS.md](CREDENTIALS.md) |
| **Prometheus** | http://62.84.112.42:9090 | 9090 | - |
| **Kibana** | http://62.84.112.42:5601 | 5601 | - |
| **Zabbix** | http://158.160.112.98 | 80 | См. [CREDENTIALS.md](CREDENTIALS.md) |
| **Elasticsearch** | http://10.0.4.34:9200 | 9200 | - (internal) |
| **Bastion Host** | `ssh ubuntu@158.160.104.48` | 22 | SSH key |

> 📝 **Примечание:** Это реальные IP адреса развернутой инфраструктуры.
> Подробные инструкции по доступу см. в [ACCESS_GUIDE.md](ACCESS_GUIDE.md)
>
> 🔒 **Безопасность:** Учетные данные см. в [CREDENTIALS.md](CREDENTIALS.md)

## 📊 Скриншоты системы

### Мониторинг Zabbix
![Zabbix Dashboard](scr/Снимок%20экрана%202025-09-27%20204926.png)
*Главная панель мониторинга Zabbix с отображением состояния всех хостов и сервисов инфраструктуры*

### Веб-интерфейс Kibana
![Kibana Interface](scr/Снимок%20экрана%202025-09-27%20215033.png)
*Интерфейс Kibana для анализа логов, создания дашбордов и поиска по централизованным логам*

### Конфигурация системы мониторинга
![System Configuration](scr/Снимок%20экрана%202025-09-27%20215051.png)
*Настройки и конфигурация системы мониторинга с отображением параметров производительности*

### Статистика производительности и метрики
![Performance Stats](scr/Снимок%20экрана%202025-09-27%20215105.png)
*Детальная статистика производительности системы, метрики использования ресурсов и графики нагрузки*

## 🏗️ Архитектура

Проект развертывает отказоустойчивую инфраструктуру в Yandex Cloud:

### Сетевая архитектура
- **VPC Network** `diplom-network` с 4 подсетями в двух зонах доступности
- **Bastion Host** (158.160.104.48) для безопасного доступа к внутренним ресурсам
- **NAT Gateway** для доступа в интернет из приватных подсетей
- **Application Load Balancer** (158.160.168.17) для распределения нагрузки
- **Security Groups** с настроенными правилами firewall

### Серверы (6 VMs, Ubuntu 22.04)
- **Bastion Host** (158.160.104.48) - точка входа для администрирования
- **Zabbix Server** (158.160.112.98, 10.0.1.14) - мониторинг инфраструктуры
- **Kibana Server** (62.84.112.42, 10.0.1.3) - хостинг для Kibana, Grafana, Prometheus
- **Web Server 1** (10.0.2.21) - Nginx + PHP, зона ru-central1-a
- **Web Server 2** (10.0.3.3) - Nginx + PHP, зона ru-central1-b
- **Elasticsearch Server** (10.0.4.34) - хранение и индексация логов

### Terraform Resources (26 ресурсов)
- 6 Virtual Machines
- 1 VPC Network
- 4 Subnets
- 6 Security Groups
- 1 Application Load Balancer
- 1 Target Group
- 1 Backend Group
- 1 HTTP Router
- 1 Virtual Host
- NAT Gateway и Route Tables

### Мониторинг и логирование
**Zabbix 6.4** (http://158.160.112.98)
- Мониторинг состояния всех серверов
- Автоматическое обнаружение сервисов
- Настроенные триггеры и уведомления

**ELK Stack**
- **Elasticsearch 8.11.0** (10.0.4.34:9200) - хранение и индексация логов
- **Kibana 8.11.0** (http://62.84.112.42:5601) - визуализация логов
- **Filebeat** - агент для сбора логов на всех серверах

**Prometheus Stack** (http://62.84.112.42:9090)
- **Prometheus 2.48.0** - сбор и хранение метрик (4 targets, 100+ метрик)
- **Grafana 10.2.2** (http://62.84.112.42:3000) - визуализация метрик
- **Node Exporter 1.7.0** - системные метрики на всех серверах
- **Дашборды:** Node Exporter Full (31+ панелей)

**Метрики:**
- CPU Usage (по ядрам и общий)
- Memory Usage (детальная разбивка)
- Disk I/O (чтение/запись)
- Network Traffic (входящий/исходящий)
- System Load, Uptime, Processes

## 📁 Структура проекта

```
diplom/
├── terraform/                          # Инфраструктура как код (26 ресурсов)
│   ├── main.tf                         # Основная конфигурация
│   ├── variables.tf                    # Переменные
│   ├── outputs.tf                      # Выходные значения (IP адреса)
│   ├── network.tf                      # VPC, подсети, NAT Gateway
│   ├── bastion.tf                      # Bastion Host
│   ├── web_servers.tf                  # Web серверы (2 VM)
│   ├── monitoring.tf                   # Zabbix, Kibana серверы
│   ├── elasticsearch.tf                # Elasticsearch сервер
│   ├── load_balancer.tf                # Application Load Balancer
│   ├── security_groups.tf              # Группы безопасности (6 групп)
│   └── ssh_key.tf                      # SSH ключи
├── ansible/                            # Конфигурация серверов (20+ playbooks)
│   ├── site.yml                        # Главный playbook
│   ├── inventory/                      # Инвентарь серверов
│   │   ├── hosts.yml                   # Основной инвентарь
│   │   ├── hosts_bastion.yml           # Через Bastion
│   │   └── hosts_wsl.yml               # Для WSL
│   ├── playbooks/                      # Playbooks для настройки
│   │   ├── setup_web_dashboards.yml    # Веб-страницы
│   │   ├── monitoring_on_kibana.yml    # Prometheus + Grafana
│   │   ├── install_exporters.yml       # Node Exporter
│   │   └── ...                         # 15+ других playbooks
│   ├── templates/                      # Шаблоны конфигураций (30+ файлов)
│   │   ├── prometheus.yml.j2           # Prometheus config
│   │   ├── node_exporter.service.j2    # Node Exporter service
│   │   └── ...                         # Другие шаблоны
│   ├── group_vars/                     # Переменные групп
│   │   ├── all.yml                     # Общие переменные (IP, пароли)
│   │   └── all.yml.example             # Пример конфигурации
│   └── README_MONITORING.md            # Документация по мониторингу
├── docs/                               # Документация проекта
│   └── (см. раздел Документация)
├── scripts/                            # Скрипты автоматизации (30+ файлов)
│   ├── setup_*.sh                      # Скрипты установки сервисов
│   ├── check_*.sh                      # Скрипты проверки
│   ├── configure_*.sh                  # Скрипты настройки
│   └── *.ps1                           # PowerShell скрипты
├── monitoring/                         # Docker compose для мониторинга
│   ├── elasticsearch-docker-compose.yml
│   ├── kibana-docker-compose.yml
│   └── grafana-docker-compose.yml
├── scr/                                # Скриншоты системы
├── .gitignore                          # Git ignore (216 строк)
├── .gitattributes                      # Git attributes (100 строк)
├── LICENSE                             # MIT License
└── README.md                           # Этот файл
```

**Статистика:**
- 📦 100+ файлов
- 💻 15,000+ строк кода
- 📚 15 документов (115+ страниц)
- 🔧 20+ Ansible playbooks
- 📜 30+ скриптов автоматизации

## ⚙️ Предварительные требования

### Программное обеспечение
- [Terraform](https://www.terraform.io/downloads.html) >= 1.6.0
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) >= 2.15.0
- [Yandex Cloud CLI](https://cloud.yandex.ru/docs/cli/quickstart) (опционально)
- PowerShell 7+ (для Windows) или Bash (для Linux/macOS)
- SSH клиент
- Git

### Yandex Cloud
1. Создайте аккаунт в [Yandex Cloud](https://cloud.yandex.ru/)
2. Создайте облако и каталог
3. Создайте сервисный аккаунт с ролями:
   - `editor` - для управления ресурсами
   - `vpc.admin` - для управления сетью
4. Создайте авторизованный ключ для сервисного аккаунта
5. Сохраните ключ в файл `authorized_key.json`

### Переменные окружения (опционально)

```bash
# Linux/macOS
export YC_TOKEN="your_oauth_token"
export YC_CLOUD_ID="your_cloud_id"
export YC_FOLDER_ID="your_folder_id"

# Windows PowerShell
$env:YC_TOKEN = "your_oauth_token"
$env:YC_CLOUD_ID = "your_cloud_id"
$env:YC_FOLDER_ID = "your_folder_id"
```

## Развертывание

### Быстрый старт

1. **Клонируйте репозиторий:**
   ```bash
   git clone <repository_url>
   cd diplom
   ```

2. **Установите переменные окружения:**
   ```powershell
   $env:YC_TOKEN = "your_token"
   $env:YC_CLOUD_ID = "your_cloud_id"
   $env:YC_FOLDER_ID = "your_folder_id"
   ```

3. **Выполните полное развертывание:**
   ```powershell
   .\deploy.ps1 -All
   ```

### Пошаговое развертывание

1. **Планирование инфраструктуры:**
   ```powershell
   .\deploy.ps1 -Plan
   ```

2. **Создание инфраструктуры:**
   ```powershell
   .\deploy.ps1 -Apply
   ```

3. **Настройка серверов:**
   ```powershell
   .\deploy.ps1 -Ansible
   ```

### Удаление инфраструктуры

```powershell
.\deploy.ps1 -Destroy
```

## 🔗 Доступ к развернутым сервисам

После успешного развертывания доступны следующие сервисы:

### Основные сервисы (внешний доступ)
- **Веб-сайт:** http://158.160.168.17 (Load Balancer)
- **Zabbix:** http://158.160.112.98 (см. [CREDENTIALS.md](CREDENTIALS.md))
- **Kibana:** http://62.84.112.42:5601
- **Grafana:** http://62.84.112.42:3000 (см. [CREDENTIALS.md](CREDENTIALS.md))
- **Prometheus:** http://62.84.112.42:9090

### Внутренние сервисы (доступ через Bastion Host)
- **Elasticsearch:** http://10.0.4.34:9200 (HTTP API)
- **Web Server 1:** http://10.0.2.21:80 (Nginx, зона ru-central1-a)
- **Web Server 2:** http://10.0.3.3:80 (Nginx, зона ru-central1-b)
- **Zabbix Server:** 10.0.1.14:10051 (Zabbix Agent)
- **Kibana Server:** 10.0.1.3 (внутренний IP)

### 🔐 Подключение к серверам

#### Bastion Host (точка входа)
```bash
ssh -i ssh_key.pem ubuntu@158.160.104.48
```

#### Веб-серверы (через Bastion Host)
```bash
# Web Server 1 (ru-central1-a)
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.104.48 -i ssh_key.pem" ubuntu@10.0.2.21

# Web Server 2 (ru-central1-b)
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.104.48 -i ssh_key.pem" ubuntu@10.0.3.3
```

#### Серверы мониторинга и логирования

**Прямое подключение (с внешними IP):**
```bash
# Zabbix Server
ssh -i ssh_key.pem ubuntu@158.160.112.98

# Kibana Server (Grafana, Prometheus, Kibana)
ssh -i ssh_key.pem ubuntu@62.84.112.42
```

**Через Bastion Host (внутренние IP):**
```bash
# Elasticsearch Server
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.104.48 -i ssh_key.pem" ubuntu@10.0.4.34
```

> 📝 **Примечание:** SSH ключ генерируется Terraform и сохраняется в `ssh_key.pem`
> Подробные инструкции см. в [ACCESS_GUIDE.md](ACCESS_GUIDE.md)

### 🔌 Порты и протоколы

| Сервис | Порт | Протокол | Описание |
|--------|------|----------|----------|
| **Nginx** | 80 | HTTP | Веб-сервер |
| **Elasticsearch** | 9200 | HTTP | REST API |
| **Kibana** | 5601 | HTTP | Веб-интерфейс |
| **Grafana** | 3000 | HTTP | Веб-интерфейс |
| **Prometheus** | 9090 | HTTP | Веб-интерфейс |
| **Node Exporter** | 9100 | HTTP | Метрики системы |
| **Zabbix Web** | 80 | HTTP | Веб-интерфейс |
| **Zabbix Server** | 10051 | TCP | Zabbix протокол |
| **SSH** | 22 | SSH | Удаленный доступ |

### 📊 Проверка работоспособности

```bash
# Проверка Load Balancer
curl http://158.160.168.17

# Проверка Grafana
curl http://62.84.112.42:3000

# Проверка Prometheus
curl http://62.84.112.42:9090

# Проверка Kibana
curl http://62.84.112.42:5601

# Проверка метрик Node Exporter
curl http://62.84.112.42:9100/metrics

# Просмотр логов
docker-compose logs -f
```

## 📊 Мониторинг и метрики

### Zabbix 6.4 (http://158.160.112.98)
**Традиционный мониторинг инфраструктуры:**
- ✅ Автоматически настроенный мониторинг всех 6 серверов
- ✅ Шаблоны для Linux серверов, Nginx
- ✅ Уведомления о проблемах
- ✅ Графики производительности

### ELK Stack (Централизованное логирование)
**Elasticsearch 8.11.0 + Kibana 8.11.0:**
- ✅ Централизованный сбор логов со всех серверов
- ✅ Дашборды для анализа логов Nginx
- ✅ Поиск и фильтрация логов в Kibana (http://62.84.112.42:5601)
- ✅ Индексация и хранение логов в Elasticsearch (10.0.4.34:9200)

### Prometheus Stack (Современный мониторинг)
**Prometheus 2.48.0 + Grafana 10.2.2:**
- ✅ **Prometheus** (http://62.84.112.42:9090) - сбор метрик с 4 targets
- ✅ **Grafana** (http://62.84.112.42:3000) - визуализация метрик
- ✅ **Node Exporter 1.7.0** - системные метрики на всех серверах
- ✅ **100+ метрик:** CPU, Memory, Disk, Network, Load Average
- ✅ **Дашборды:** Node Exporter Full (ID: 1860) с 31+ панелями

**Доступные метрики:**
- CPU Usage (по ядрам и общий)
- Memory Usage (детальная разбивка)
- Disk I/O (чтение/запись)
- Network Traffic (входящий/исходящий)
- System Load, Uptime, Processes
- Disk Space Usage

**Примеры PromQL запросов:**
```promql
# CPU Usage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory Usage
100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))

# Disk Usage
100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100)
```

> 📚 **Подробнее:** См. [PROMQL_QUERIES.md](PROMQL_QUERIES.md) для полного справочника запросов
> 📊 **Дашборды:** См. [GRAFANA_DASHBOARDS_GUIDE.md](GRAFANA_DASHBOARDS_GUIDE.md) для настройки

## Безопасность

### Сетевая безопасность
- Все серверы находятся в приватных подсетях
- Доступ к серверам только через Bastion Host
- Группы безопасности ограничивают сетевой трафик
- SSH ключи для аутентификации
- Ansible Vault для хранения паролей

### Защита конфиденциальных данных

⚠️ **ВАЖНО:** В проекте содержатся конфиденциальные файлы с данными Yandex Cloud:

#### Конфиденциальные файлы:
- `info.txt` - содержит идентификаторы облака, папки и сервисного аккаунта
- `authorized_key.json` - содержит приватный ключ сервисного аккаунта

#### Меры защиты:
1. **Git исключения:** Файлы добавлены в `.gitignore` и не попадают в репозиторий
2. **Права доступа:** Установлены ограниченные права доступа только для владельца файлов
3. **Переменные окружения:** Используйте переменные окружения вместо хранения секретов в коде

#### Рекомендации по безопасности:
- Никогда не коммитьте конфиденциальные файлы в Git
- Используйте `.env` файлы для локальной разработки (также исключены из Git)
- Регулярно ротируйте ключи сервисных аккаунтов
- Ограничивайте права доступа к файлам с секретами
- Используйте системы управления секретами в продакшене

#### Проверка безопасности:

Для автоматической проверки безопасности используйте специальный скрипт:

```powershell
# Запуск полной проверки безопасности
.\check_security.ps1

# Запуск с подробным выводом
.\check_security.ps1 -Verbose
```

Скрипт проверяет:
- ✅ Существование конфиденциальных файлов
- 🔐 Права доступа к файлам (только владелец)
- 📝 Наличие файлов в .gitignore
- 📊 Статус Git (файлы не отслеживаются)
- 🌍 Переменные окружения Yandex Cloud

Ручная проверка (при необходимости):

```powershell
# Проверка прав доступа к конфиденциальным файлам
icacls "info.txt"
icacls "authorized_key.json"

# Проверка исключений Git
git status --ignored
```

## Отказоустойчивость

- Веб-серверы развернуты в двух зонах доступности
- Application Load Balancer с health checks
- Автоматическое переключение трафика при отказе сервера
- Резервное копирование конфигураций

## Масштабирование

Для масштабирования инфраструктуры:

1. Измените переменную `web_servers_count` в `terraform/variables.tf`
2. Выполните `terraform apply`
3. Запустите Ansible для настройки новых серверов

## Устранение неполадок

### Проблемы с SSH
- Убедитесь, что SSH ключ имеет правильные права доступа (600)
- Проверьте подключение к Bastion Host

### Проблемы с Ansible
- Убедитесь, что все серверы доступны
- Проверьте правильность паролей в vault файле

### Проблемы с Terraform
- Проверьте переменные окружения Yandex Cloud
- Убедитесь в наличии квот в облаке

## 📚 Дополнительная документация

- **[ACCESS_GUIDE.md](ACCESS_GUIDE.md)** - Подробное руководство по доступу ко всем сервисам
- **[CREDENTIALS.md](CREDENTIALS.md)** - Учетные данные и SSH доступ
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Пошаговое руководство по развертыванию
- **[CLEANUP_REPORT.md](CLEANUP_REPORT.md)** - Отчет об очистке проекта
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Детальная архитектура системы

## 🛠️ Технологический стек

### Infrastructure as Code
- **Terraform 1.6+** - Управление инфраструктурой (26 ресурсов)
- **Yandex Cloud** - Облачная платформа

### Configuration Management
- **Ansible 2.15+** - Автоматизация настройки серверов (20+ playbooks)

### Web Stack
- **Nginx 1.18.0** - Веб-сервер (2 инстанса)
- **PHP 7.4-FPM** - Backend обработка
- **Bootstrap 5.3.2** - Frontend фреймворк
- **Application Load Balancer** - Распределение нагрузки

### Monitoring & Logging
- **Zabbix 6.4** - Традиционный мониторинг
- **Prometheus 2.48.0** - Сбор метрик (4 targets)
- **Grafana 10.2.2** - Визуализация метрик
- **Node Exporter 1.7.0** - Системные метрики (на всех серверах)
- **Elasticsearch 8.11.0** - Хранение логов
- **Kibana 8.11.0** - Анализ логов
- **Filebeat** - Агент сбора логов

### Containerization
- **Docker 26.1.3** - Контейнеризация (Elasticsearch, Kibana, Grafana)
- **Docker Compose** - Оркестрация контейнеров

### Operating System
- **Ubuntu 22.04 LTS** - Базовая ОС для всех 6 серверов

### Cloud Infrastructure
- **VPC Network** - Виртуальная сеть
- **Subnets** - 4 подсети (public, private-a, private-b, elastic)
- **Security Groups** - 6 групп безопасности
- **NAT Gateway** - Доступ в интернет
- **Bastion Host** - Безопасный доступ

## 🧪 Тестирование

### Проверка всех сервисов

Используйте автоматический скрипт проверки:

```bash
chmod +x check_all_services.sh
./check_all_services.sh
```

### Ручная проверка сервисов

```bash
# Load Balancer (веб-сайт)
curl http://158.160.168.17

# Grafana (визуализация метрик)
curl -I http://62.84.112.42:3000

# Prometheus (сбор метрик)
curl http://62.84.112.42:9090/api/v1/status/config

# Kibana (анализ логов)
curl http://62.84.112.42:5601/api/status

# Zabbix (мониторинг)
curl -I http://158.160.112.98

# Node Exporter (метрики системы)
curl http://62.84.112.42:9100/metrics
```

### Проверка метрик Prometheus

```bash
# Проверка targets
curl http://62.84.112.42:9090/api/v1/targets

# Проверка метрик CPU
curl -G http://62.84.112.42:9090/api/v1/query \
  --data-urlencode 'query=100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)'

# Проверка метрик Memory
curl -G http://62.84.112.42:9090/api/v1/query \
  --data-urlencode 'query=100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))'
```

> 📚 **Подробнее:** См. [PROMQL_QUERIES.md](PROMQL_QUERIES.md) для полного списка запросов

## 🔒 Безопасность

### Реализованные меры безопасности

✅ **Сетевая безопасность:**
- Все серверы в приватных подсетях (кроме Bastion, Zabbix, Kibana)
- Доступ к внутренним серверам только через Bastion Host
- 6 Security Groups с настроенными правилами firewall
- SSH ключи для аутентификации (пароли отключены)

✅ **Защита данных:**
- Все чувствительные файлы в `.gitignore` (216 строк)
- SSH ключи (*.pem, *.key) исключены из Git
- Terraform state файлы (*.tfstate*) исключены из Git
- Файлы с учетными данными (authorized_key.json) исключены
- Примеры конфигураций (*.example) для публичного использования

✅ **Документация безопасности:**
- [SECURITY.md](SECURITY.md) - политика безопасности
- [CREDENTIALS.md](CREDENTIALS.md) - управление учетными данными
- [ACCESS_GUIDE.md](ACCESS_GUIDE.md) - безопасный доступ к сервисам

### Рекомендации для production

- Используйте сильные пароли (минимум 16 символов)
- Регулярно ротируйте SSH ключи и пароли
- Храните `authorized_key.json` в безопасном месте (не в Git!)
- Используйте Terraform remote backend (S3, Terraform Cloud)
- Включите MFA для Yandex Cloud аккаунта
- Настройте регулярные бэкапы
- Используйте Ansible Vault для секретов
- Мониторьте логи безопасности в Zabbix и Kibana

## 🤝 Вклад в проект

Этот проект создан в образовательных целях. Если вы хотите улучшить проект:

1. Fork репозитория
2. Создайте feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit изменений (`git commit -m 'Add some AmazingFeature'`)
4. Push в branch (`git push origin feature/AmazingFeature`)
5. Откройте Pull Request

## 📞 Поддержка

Для получения помощи:
1. Проверьте [ACCESS_GUIDE.md](ACCESS_GUIDE.md) для инструкций по доступу
2. Изучите [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) для troubleshooting
3. Проверьте логи развертывания
4. Убедитесь в выполнении всех предварительных требований
5. Проверьте документацию [Yandex Cloud](https://cloud.yandex.ru/docs)

## 📄 Лицензия

Этот проект создан в образовательных целях для дипломной работы DevOps инженера.

**MIT License** - см. файл [LICENSE](LICENSE) для деталей.

---

## 🎓 О проекте

**Дипломный проект DevOps**
Автоматизированное развертывание отказоустойчивой веб-инфраструктуры в Yandex Cloud

### Статистика проекта

| Метрика | Значение |
|---------|----------|
| **Файлов** | 100+ |
| **Строк кода** | 15,000+ |
| **Terraform ресурсов** | 26 |
| **Виртуальных машин** | 6 |
| **Ansible playbooks** | 20+ |
| **Скриптов автоматизации** | 30+ |
| **Документов** | 15 (115+ страниц) |
| **Выполнение задач** | 100% |

### Ключевые достижения

✅ **Инфраструктура:**
- Развернута отказоустойчивая инфраструктура в 2 зонах доступности
- Настроен Application Load Balancer с health checks
- Реализована сетевая безопасность с Security Groups

✅ **Мониторинг:**
- Настроен полный стек мониторинга (Zabbix, Prometheus, Grafana)
- Собираются 100+ метрик с 4 targets
- Созданы дашборды для визуализации

✅ **Логирование:**
- Развернут ELK Stack (Elasticsearch, Kibana, Filebeat)
- Централизованный сбор логов со всех серверов

✅ **Автоматизация:**
- 100% автоматизация через Terraform и Ansible
- 30+ скриптов для управления и проверки
- Полная документация процессов

### Дата завершения
**04 октября 2025**

### Статус
**✅ Production Ready - Все 7 задач выполнены на 100%**

---

<div align="center">

**⭐ Если проект был полезен, поставьте звезду! ⭐**

**Репозиторий:** https://github.com/kellisfen/dp
**Release:** [v1.0.0](https://github.com/kellisfen/dp/releases/tag/v1.0.0)

Made with ❤️ using Terraform, Ansible, and Yandex Cloud

</div>