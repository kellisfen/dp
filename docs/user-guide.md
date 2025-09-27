# Руководство пользователя по развертыванию и управлению инфраструктурой

## Содержание
1. [Введение](#введение)
2. [Доступ к сервисам](#доступ-к-сервисам)
3. [Подключение к серверам](#подключение-к-серверам)
4. [Мониторинг и логирование](#мониторинг-и-логирование)
5. [Управление конфигурацией](#управление-конфигурацией)
6. [Безопасность](#безопасность)
7. [Резервное копирование](#резервное-копирование)
8. [Устранение неполадок](#устранение-неполадок)
9. [FAQ](#faq)

## Введение

Данное руководство описывает процесс использования развернутой IT-инфраструктуры. Проект включает:

- **Веб-приложение** - доступно через Load Balancer
- **Мониторинг** - Zabbix, Prometheus, Grafana
- **Логирование** - Elasticsearch, Kibana, Loki
- **Трассировка** - Jaeger
- **Безопасность** - SSH доступ через Bastion Host

## Доступ к сервисам

### Основные сервисы

#### Веб-сайт
- **URL:** `http://158.160.99.254`
- **Протокол:** HTTP
- **Порт:** 80
- **Описание:** Основное веб-приложение с балансировкой нагрузки

#### Zabbix (Мониторинг)
- **URL:** `http://158.160.99.254:80/zabbix`
- **Логин:** `admin`
- **Пароль:** `zabbix`
- **Описание:** Система мониторинга инфраструктуры

#### Kibana (Логи)
- **URL:** `http://158.160.99.254:5601`
- **Описание:** Веб-интерфейс для просмотра и анализа логов

### Сервисы через SSH туннели

Для доступа к следующим сервисам необходимо создать SSH туннель через Bastion Host:

#### Grafana
```bash
ssh -i ssh_key.pem -L 3000:localhost:3000 -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5
```
- **URL:** `http://localhost:3000`
- **Логин:** `admin`
- **Пароль:** `admin`

#### Prometheus
```bash
ssh -i ssh_key.pem -L 9090:localhost:9090 -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5
```
- **URL:** `http://localhost:9090`

#### AlertManager
```bash
ssh -i ssh_key.pem -L 9093:localhost:9093 -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5
```
- **URL:** `http://localhost:9093`

#### Jaeger UI
```bash
ssh -i ssh_key.pem -L 16686:localhost:16686 -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5
```
- **URL:** `http://localhost:16686`

## Подключение к серверам

### Требования для подключения
- SSH клиент
- Приватный ключ `ssh_key.pem` (должен находиться в папке проекта)
- Права доступа к ключу: `chmod 600 ssh_key.pem`

### Архитектура подключения
Все внутренние серверы доступны только через Bastion Host для обеспечения безопасности.

```
Интернет → Bastion Host (158.160.99.254) → Внутренние серверы
```

### Bastion Host
```bash
ssh -i ssh_key.pem ubuntu@158.160.99.254
```
- **IP:** `158.160.99.254`
- **Пользователь:** `ubuntu`
- **Порт:** 22 (SSH)
- **Назначение:** Точка входа в инфраструктуру

### Веб-серверы

#### Web Server 1
```bash
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.1.5
```
- **IP:** `10.0.1.5`
- **Сервисы:** Nginx, Log Shipper
- **Логи:** `/var/log/nginx/`

#### Web Server 2
```bash
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.2.5
```
- **IP:** `10.0.2.5`
- **Сервисы:** Nginx, Log Shipper
- **Логи:** `/var/log/nginx/`

### Сервер мониторинга и логирования
```bash
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5
```
- **IP:** `10.0.3.5`
- **Сервисы:** Zabbix, Elasticsearch, Kibana, Prometheus, Grafana, Loki, Jaeger
- **Docker контейнеры:** `docker ps` для просмотра запущенных сервисов

### Полезные команды на серверах

#### Проверка статуса сервисов
```bash
# Nginx
sudo systemctl status nginx

# Docker сервисы
docker ps
docker-compose ps

# Логи сервисов
sudo journalctl -u nginx -f
docker logs container_name
```

#### Мониторинг ресурсов
```bash
# Использование CPU и памяти
htop

# Использование диска
df -h

# Сетевые соединения
netstat -tulpn
```

## Мониторинг и логирование

### Zabbix - Системный мониторинг

#### Доступ
- **URL:** `http://158.160.99.254:80/zabbix`
- **Логин:** `admin`
- **Пароль:** `zabbix`

#### Основные функции
- **Хосты:** Мониторинг всех серверов инфраструктуры
- **Элементы данных:** CPU, память, диск, сеть
- **Триггеры:** Автоматические алерты при превышении порогов
- **Графики:** Визуализация метрик в реальном времени

#### Настроенные проверки
- Доступность SSH (порт 22)
- HTTP сервис (порт 80)
- Использование CPU > 80%
- Использование памяти > 90%
- Свободное место на диске < 10%

### Kibana - Анализ логов

#### Доступ
- **URL:** `http://158.160.99.254:5601`

#### Индексы данных
- **logs*** - основные логи приложений
- **test-logs*** - тестовые записи

#### Источники логов
- Nginx access logs
- Nginx error logs
- System logs (syslog)
- Authentication logs (auth.log)

#### Полезные запросы
```
# Ошибки Nginx
response:5* OR response:4*

# Логи за последний час
@timestamp:[now-1h TO now]

# Логи с определенного сервера
host:"10.0.1.5"
```

### Grafana - Метрики и дашборды

#### Доступ (через SSH туннель)
```bash
ssh -i ssh_key.pem -L 3000:localhost:3000 -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5
```
- **URL:** `http://localhost:3000`
- **Логин:** `admin`
- **Пароль:** `admin`

#### Источники данных
- **Prometheus** - метрики системы и приложений
- **Loki** - логи в структурированном виде

#### Готовые дашборды
- Node Exporter Full - системные метрики
- Docker Container Metrics - метрики контейнеров
- Nginx Metrics - метрики веб-сервера

### Prometheus - Сбор метрик

#### Доступ (через SSH туннель)
```bash
ssh -i ssh_key.pem -L 9090:localhost:9090 -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5
```
- **URL:** `http://localhost:9090`

#### Экспортеры
- **Node Exporter** - системные метрики (CPU, память, диск)
- **Blackbox Exporter** - проверка доступности сервисов
- **cAdvisor** - метрики Docker контейнеров

### Jaeger - Трассировка

#### Доступ (через SSH туннель)
```bash
ssh -i ssh_key.pem -L 16686:localhost:16686 -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5
```
- **URL:** `http://localhost:16686`

#### Функции
- Трассировка запросов между сервисами
- Анализ производительности
- Поиск узких мест в приложении
PUBLIC_SUBNET_CIDR=10.0.1.0/24
PRIVATE_SUBNET_CIDR=10.0.2.0/24
```

### Этап 2: Развертывание базовой инфраструктуры

```bash
cd terraform/

# Инициализация
terraform init

# Планирование изменений
terraform plan -var-file="terraform.tfvars"

# Применение изменений
terraform apply -var-file="terraform.tfvars"
```

### Этап 3: Конфигурация серверов с Ansible

```bash
cd ../ansible/

# Проверка доступности хостов
ansible all -m ping -i inventory/production.yml

# Установка базовых компонентов
ansible-playbook -i inventory/production.yml playbooks/site.yml

# Развертывание приложений
ansible-playbook -i inventory/production.yml playbooks/deploy.yml
```

## Настройка мониторинга

### Развертывание стека мониторинга

```bash
cd monitoring/

# Запуск всех сервисов
docker-compose up -d

# Проверка статуса
docker-compose ps

# Просмотр логов
docker-compose logs -f prometheus
```

### Настройка дашбордов Grafana

1. Откройте Grafana: http://localhost:3000
2. Войдите с учетными данными: admin/admin123
3. Импортируйте дашборды:
   - USE Methodology Dashboard (ID: use-methodology)
   - Node Exporter Dashboard (ID: 1860)
   - Docker Dashboard (ID: 193)

### Конфигурация алертов

Алерты настроены по методологии USE:
- **Utilization** - использование ресурсов (CPU, память, диск)
- **Saturation** - насыщение (очереди, swap)
- **Errors** - ошибки (сетевые, дисковые, памяти)

Пороговые значения:
- Warning: CPU > 80%, Memory > 85%, Disk > 85%
- Critical: CPU > 95%, Memory > 95%, Disk > 95%

## Управление конфигурацией

### Ansible Vault для секретов

```bash
# Создание зашифрованного файла
ansible-vault create group_vars/all/vault.yml

# Редактирование
ansible-vault edit group_vars/all/vault.yml

# Запуск playbook с vault
ansible-playbook -i inventory/production.yml playbooks/site.yml --ask-vault-pass
```

### Структура переменных

```yaml
# group_vars/all/main.yml
app_name: "my-application"
app_version: "1.0.0"
app_port: 8080

# group_vars/all/vault.yml (зашифровано)
vault_db_password: "secure_password"
vault_api_key: "secret_api_key"
```

### Управление версиями

```bash
# Создание тега версии
git tag -a v1.0.0 -m "Production release v1.0.0"
git push origin v1.0.0

# Откат к предыдущей версии
terraform plan -var="app_version=v0.9.0"
terraform apply -var="app_version=v0.9.0"
```

## Безопасность

### Настройка SSH ключей

```bash
# Запуск скрипта настройки SSH
./scripts/setup-ssh-security.sh

# Проверка конфигурации
ssh-keygen -l -f ~/.ssh/id_rsa.pub
```

### Настройка Ansible Vault

```bash
# Запуск скрипта настройки Vault
./scripts/setup-ansible-vault.sh

# Создание нового секрета
ansible-vault encrypt_string 'secret_value' --name 'secret_name'
```

### Файрвол и сетевая безопасность

Автоматически настраиваются:
- Ограничение SSH доступа (порт 22)
- Блокировка неиспользуемых портов
- Настройка Security Groups в AWS
- Включение логирования подключений

### Аудит безопасности

```bash
# Проверка открытых портов
ansible all -m shell -a "netstat -tuln" -i inventory/production.yml

# Проверка пользователей
ansible all -m shell -a "cat /etc/passwd" -i inventory/production.yml

# Проверка процессов
ansible all -m shell -a "ps aux" -i inventory/production.yml
```

## Резервное копирование

### Автоматическое резервное копирование

Настроено резервное копирование:
- **Базы данных** - ежедневно в 2:00
- **Конфигурации** - еженедельно
- **Логи** - ежемесячно
- **Terraform state** - при каждом изменении

### Восстановление из резервной копии

```bash
# Восстановление базы данных
ansible-playbook -i inventory/production.yml playbooks/restore-database.yml \
  -e "backup_date=2024-01-15"

# Восстановление конфигураций
ansible-playbook -i inventory/production.yml playbooks/restore-configs.yml
```

### Тестирование резервных копий

```bash
# Запуск тестов восстановления
ansible-playbook -i inventory/staging.yml playbooks/test-backup-restore.yml
```

## Устранение неполадок

### Проблемы с Terraform

**Ошибка: "Resource already exists"**
```bash
# Импорт существующего ресурса
terraform import aws_instance.web i-1234567890abcdef0

# Или удаление из state
terraform state rm aws_instance.web
```

**Ошибка: "Backend initialization required"**
```bash
terraform init -reconfigure
```

### Проблемы с Ansible

**Ошибка: "Host unreachable"**
```bash
# Проверка SSH подключения
ssh -i ~/.ssh/id_rsa user@host

# Проверка inventory
ansible-inventory -i inventory/production.yml --list
```

**Ошибка: "Permission denied"**
```bash
# Проверка прав на SSH ключ
chmod 600 ~/.ssh/id_rsa

# Добавление ключа в SSH агент
ssh-add ~/.ssh/id_rsa
```

### Проблемы с мониторингом

**Prometheus не собирает метрики**
```bash
# Проверка конфигурации
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Перезагрузка конфигурации
curl -X POST http://localhost:9090/-/reload
```

**Grafana не показывает данные**
1. Проверьте подключение к Prometheus в Data Sources
2. Убедитесь, что метрики поступают: http://localhost:9090/targets
3. Проверьте запросы в Query Inspector

### Логи и диагностика

```bash
# Логи Terraform
export TF_LOG=DEBUG
terraform apply

# Логи Ansible
ansible-playbook -vvv playbooks/site.yml

# Логи Docker
docker-compose logs -f service_name

# Системные логи
journalctl -u service_name -f
```

## FAQ

### Q: Как добавить новый сервер в мониторинг?
A: Добавьте хост в `inventory/production.yml` и запустите:
```bash
ansible-playbook -i inventory/production.yml playbooks/monitoring.yml --limit new_host
```

### Q: Как изменить пароли по умолчанию?
A: Отредактируйте файл `group_vars/all/vault.yml`:
```bash
ansible-vault edit group_vars/all/vault.yml
```

### Q: Как масштабировать инфраструктуру?
A: Измените переменные в `terraform.tfvars`:
```hcl
instance_count = 5
instance_type = "t3.large"
```
Затем выполните `terraform apply`.

### Q: Как настроить SSL сертификаты?
A: Используйте Let's Encrypt через Ansible:
```bash
ansible-playbook -i inventory/production.yml playbooks/ssl-certificates.yml
```

### Q: Как обновить приложение без простоя?
A: Используйте rolling update:
```bash
ansible-playbook -i inventory/production.yml playbooks/rolling-update.yml \
  -e "app_version=v1.1.0"
```

### Q: Как настроить дополнительные алерты?
A: Добавьте правила в `monitoring/prometheus/rules/custom-alerts.yml` и перезапустите Prometheus.

### Q: Как получить доступ к логам приложений?
A: Логи доступны через:
- Grafana Loki: http://localhost:3000
- Прямой доступ: `docker-compose logs app`
- SSH: `tail -f /var/log/app/app.log`

---

## Поддержка

Для получения поддержки:
1. Проверьте раздел [Устранение неполадок](#устранение-неполадок)
2. Изучите логи системы
3. Создайте issue в репозитории проекта
4. Обратитесь к команде DevOps

**Контакты:**
- Email: devops@company.com
- Slack: #infrastructure-support
- Документация: https://docs.company.com/infrastructure