# 🚀 Дипломный проект DevOps

![Status](https://img.shields.io/badge/status-production-success)
![Terraform](https://img.shields.io/badge/terraform-1.11.3-blue)
![Ansible](https://img.shields.io/badge/ansible-2.9.6-red)
![Yandex Cloud](https://img.shields.io/badge/yandex%20cloud-active-yellow)
![License](https://img.shields.io/badge/license-MIT-green)

Автоматизированное развертывание отказоустойчивой веб-инфраструктуры в Yandex Cloud с использованием Infrastructure as Code (Terraform) и Configuration Management (Ansible).

## 🎯 Статус выполнения

- ✅ **Задача 1:** Elasticsearch установлен через Docker (8.11.0)
- ✅ **Задача 2:** Kibana установлена через Docker (8.11.0)
- ✅ **Задача 3:** Prometheus + Grafana + Node Exporter настроены
- ✅ **Задача 4:** Профессиональные HTML страницы развернуты
- ✅ **Задача 5:** Проект очищен от временных файлов
- ✅ **Задача 6:** Документация обновлена для GitHub

## 🚀 Быстрый старт

### 1. Клонирование репозитория
```bash
git clone https://github.com/your-username/diplom.git
cd diplom
```

### 2. Настройка учетных данных
```bash
# Создайте файл с учетными данными Yandex Cloud
cp .env.example .env
# Отредактируйте .env и добавьте свои credentials

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
```

### 4. Настройка серверов через Ansible
```bash
cd ../ansible
ansible-playbook -i inventory/hosts.yml site.yml
```

### 5. Проверка работоспособности
```bash
# Проверка Load Balancer
curl http://YOUR_LOAD_BALANCER_IP

# Проверка Grafana
curl http://YOUR_KIBANA_SERVER_IP:3000

# Проверка Prometheus
curl http://YOUR_KIBANA_SERVER_IP:9090
```

## 🌐 Доступ к сервисам

| Сервис | URL | Порт | Учетные данные |
|--------|-----|------|----------------|
| **Load Balancer** | `http://YOUR_LB_IP` | 80 | - |
| **Grafana** | `http://YOUR_KIBANA_IP:3000` | 3000 | admin / your_password |
| **Prometheus** | `http://YOUR_KIBANA_IP:9090` | 9090 | - |
| **Kibana** | `http://YOUR_KIBANA_IP:5601` | 5601 | - |
| **Elasticsearch** | `http://10.0.4.34:9200` | 9200 | - (internal) |
| **Bastion Host** | `ssh ubuntu@YOUR_BASTION_IP` | 22 | SSH key |

> 📝 **Примечание:** Замените `YOUR_*_IP` на реальные IP адреса из вывода Terraform.
> Подробные инструкции по доступу см. в [ACCESS_GUIDE.md](ACCESS_GUIDE.md)

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

## Архитектура

Проект развертывает следующую инфраструктуру:

### Сетевая архитектура
- **VPC** с подсетями в двух зонах доступности
- **Bastion Host** для безопасного доступа к внутренним ресурсам
- **NAT Gateway** для доступа в интернет из приватных подсетей
- **Application Load Balancer** для распределения нагрузки

### Серверы
- **Bastion Host** - точка входа для администрирования
- **Load Balancer** - распределение нагрузки между веб-серверами
- **Web Server 1** (Nginx 1.18.0 + PHP 7.4) - зона ru-central1-a
- **Web Server 2** (Nginx 1.18.0 + PHP 7.4) - зона ru-central1-b
- **Kibana Server** - хостинг для Kibana, Grafana, Prometheus
- **Elasticsearch Server** - хранение и индексация логов
- **Zabbix Server** - мониторинг инфраструктуры (опционально)

> 📝 **Примечание:** IP адреса генерируются динамически при развертывании.
> Получите актуальные IP командой: `terraform output`

### Мониторинг и логирование
- **Zabbix** - мониторинг состояния серверов и сервисов
- **ELK Stack** - сбор, обработка и визуализация логов
- **Filebeat** - агент для сбора логов на всех серверах
- **Prometheus Stack** - современный стек мониторинга:
  - **Prometheus** - сбор и хранение метрик
  - **Grafana** - визуализация метрик и дашборды
  - **AlertManager** - управление алертами и уведомлениями
  - **Node Exporter** - экспорт системных метрик
  - **Blackbox Exporter** - мониторинг доступности сервисов
  - **cAdvisor** - мониторинг контейнеров
- **Loki + Promtail** - централизованное логирование
- **Jaeger** - трассировка распределенных систем

## Структура проекта

```
diplom/
├── terraform/                 # Инфраструктура как код
│   ├── main.tf                # Основная конфигурация
│   ├── variables.tf           # Переменные
│   ├── outputs.tf             # Выходные значения
│   ├── network.tf             # Сетевая инфраструктура
│   ├── compute.tf             # Вычислительные ресурсы
│   ├── load_balancer.tf       # Балансировщик нагрузки
│   └── security.tf            # Группы безопасности
├── ansible/                   # Конфигурация серверов
│   ├── site.yml               # Главный playbook
│   ├── inventory/             # Инвентарь серверов
│   ├── roles/                 # Роли Ansible
│   ├── templates/             # Шаблоны конфигураций
│   └── group_vars/            # Переменные групп
├── monitoring/                # Стек мониторинга
│   ├── docker-compose.yml     # Развертывание контейнеров
│   ├── prometheus/            # Конфигурация Prometheus
│   │   ├── prometheus.yml     # Основная конфигурация
│   │   └── rules/             # Правила алертов
│   ├── grafana/               # Конфигурация Grafana
│   │   ├── dashboards/        # Дашборды
│   │   └── provisioning/      # Автоматическая настройка
│   ├── alertmanager/          # Конфигурация AlertManager
│   ├── loki/                  # Конфигурация Loki
│   ├── promtail/              # Конфигурация Promtail
│   └── jaeger/                # Конфигурация Jaeger
├── docs/                      # Документация
│   ├── user-guide.md          # Руководство пользователя
│   ├── architecture/          # Архитектурная документация
│   ├── deployment/            # Документация по развертыванию
│   └── troubleshooting/       # Устранение неполадок
├── scripts/                   # Скрипты автоматизации
├── deploy.ps1                 # Скрипт развертывания
└── README.md                  # Документация
```

## Предварительные требования

### Программное обеспечение
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) >= 2.9
- [Yandex Cloud CLI](https://cloud.yandex.ru/docs/cli/quickstart)
- PowerShell 7+ (для Windows)

### Yandex Cloud
1. Создайте аккаунт в [Yandex Cloud](https://cloud.yandex.ru/)
2. Создайте облако и каталог
3. Получите OAuth токен или создайте сервисный аккаунт
4. Установите переменные окружения:

```powershell
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

## Доступ к сервисам

После успешного развертывания доступны следующие сервисы:

### Основные сервисы
- **Веб-сайт:** `http://84.201.168.191` (Load Balancer)
- **Zabbix:** `http://158.160.33.170/zabbix` (admin/zabbix)
- **Kibana:** `http://158.160.119.108:5601`

### Внутренние сервисы (доступ через Bastion Host)
- **Elasticsearch:** `http://10.0.4.17:9200` (HTTP API)
- **Elasticsearch Transport:** `10.0.4.17:9300` (внутренний протокол)
- **Web Server 1:** `http://10.0.2.5:80` (Nginx)
- **Web Server 2:** `http://10.0.3.24:80` (Nginx)
- **Zabbix Server:** `10.0.1.7:10051` (Zabbix Agent)

### Стек мониторинга (Docker на локальной машине)
- **Grafana:** `http://localhost:3000` (admin/admin)
- **Prometheus:** `http://localhost:9090`
- **AlertManager:** `http://localhost:9093`
- **Jaeger UI:** `http://localhost:16686`

### Подключение к серверам

#### Bastion Host (точка входа)
```bash
ssh -i ssh_key.pem ubuntu@158.160.99.254
```

#### Веб-серверы (через Bastion Host)
```bash
# Web Server 1
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.2.5

# Web Server 2  
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.24
```

#### Серверы мониторинга и логирования (через Bastion Host)
```bash
# Zabbix Server
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.1.7

# Elasticsearch Server
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.4.17
```

#### Прямое подключение к серверам с внешними IP
```bash
# Zabbix Server (прямое подключение)
ssh -i ssh_key.pem ubuntu@158.160.33.170

# Kibana Server (прямое подключение)  
ssh -i ssh_key.pem ubuntu@158.160.119.108
```

### Порты и протоколы

| Сервис | Порт | Протокол | Описание |
|--------|------|----------|----------|
| Nginx | 80 | HTTP | Веб-сервер |
| Nginx | 443 | HTTPS | Веб-сервер (SSL) |
| Elasticsearch | 9200 | HTTP | REST API |
| Elasticsearch | 9300 | TCP | Transport протокол |
| Kibana | 5601 | HTTP | Веб-интерфейс |
| Zabbix Web | 80 | HTTP | Веб-интерфейс |
| Zabbix Server | 10051 | TCP | Zabbix протокол |
| SSH | 22 | SSH | Удаленный доступ |
| Beats | 5044 | TCP | Logstash протокол |

### Быстрый запуск мониторинга

```powershell
# Переход в папку мониторинга
cd monitoring

# Запуск всего стека мониторинга
docker-compose up -d

# Проверка статуса сервисов
docker-compose ps

# Просмотр логов
docker-compose logs -f
```

## Мониторинг

### Zabbix (Традиционный мониторинг)
- Автоматически настроенный мониторинг всех серверов
- Шаблоны для Linux серверов, Nginx, MySQL
- Уведомления о проблемах

### ELK Stack (Логирование)
- Централизованный сбор логов с всех серверов
- Дашборды для анализа логов Nginx
- Поиск и фильтрация логов в Kibana

### Prometheus Stack (Современный мониторинг)
- **Метрики по методологии USE** (Utilization, Saturation, Errors)
- **Grafana дашборды** с готовыми визуализациями
- **AlertManager** для управления уведомлениями
- **Автоматическое обнаружение** сервисов
- **Экспортеры** для различных систем:
  - Node Exporter (системные метрики)
  - Blackbox Exporter (проверка доступности)
  - cAdvisor (метрики контейнеров)
  - PostgreSQL, Redis, Nginx экспортеры

### Loki Stack (Современное логирование)
- **Promtail** для сбора логов
- **Loki** для хранения и индексации
- **Интеграция с Grafana** для единого интерфейса

### Jaeger (Трассировка)
- **Распределенная трассировка** микросервисов
- **Анализ производительности** запросов
- **Визуализация** зависимостей между сервисами

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
- **Terraform 1.11.3** - Управление инфраструктурой
- **Yandex Cloud Provider 0.159.0** - Провайдер для Yandex Cloud

### Configuration Management
- **Ansible 2.9.6** - Автоматизация настройки серверов

### Web Stack
- **Nginx 1.18.0** - Веб-сервер
- **PHP 7.4-FPM** - Backend обработка
- **Bootstrap 5.3.2** - Frontend фреймворк

### Monitoring & Logging
- **Prometheus 2.48.0** - Сбор метрик
- **Grafana 10.2.2** - Визуализация метрик
- **Node Exporter 1.7.0** - Системные метрики
- **Elasticsearch 8.11.0** - Хранение логов
- **Kibana 8.11.0** - Анализ логов

### Containerization
- **Docker 26.1.3** - Контейнеризация
- **Docker Compose 1.25.0** - Оркестрация контейнеров

### Operating System
- **Ubuntu 20.04 LTS** - Базовая ОС для всех серверов

## 🧪 Тестирование

### Проверка всех сервисов

Используйте автоматический скрипт проверки:

```bash
chmod +x check_all_services.sh
./check_all_services.sh
```

### Ручная проверка

```bash
# Load Balancer
curl http://YOUR_LOAD_BALANCER_IP

# Grafana
curl -I http://YOUR_KIBANA_SERVER_IP:3000

# Prometheus
curl http://YOUR_KIBANA_SERVER_IP:9090/api/v1/status/config

# Kibana
curl http://YOUR_KIBANA_SERVER_IP:5601/api/status
```

## 🔒 Безопасность

### Важные замечания

⚠️ **Перед публикацией в Git:**
1. Все чувствительные файлы добавлены в `.gitignore`
2. Пароли заменены на примеры в документации
3. SSH ключи не включены в репозиторий
4. Terraform state файлы исключены из Git

### Рекомендации

- Используйте сильные пароли (минимум 12 символов)
- Регулярно обновляйте SSH ключи
- Храните `authorized_key.json` в безопасном месте
- Используйте Terraform remote backend для production
- Включите MFA для Yandex Cloud аккаунта

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

## 🎓 Автор

**Дипломный проект DevOps**
Автоматизированное развертывание отказоустойчивой инфраструктуры в Yandex Cloud

**Дата завершения:** Октябрь 2025
**Статус:** ✅ Все задачи выполнены

---

<div align="center">

**⭐ Если проект был полезен, поставьте звезду! ⭐**

Made with ❤️ using Terraform, Ansible, and Yandex Cloud

</div>