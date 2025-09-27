# Руководство по развертыванию

## Обзор

Данное руководство содержит пошаговые инструкции по развертыванию инфраструктуры проекта с использованием Terraform и Ansible.

## Предварительные требования

### Программное обеспечение
- **Terraform** >= 1.0
- **Ansible** >= 2.9
- **Git**
- **SSH клиент**

### Учетные данные Yandex Cloud
- Service Account с ролями:
  - `editor` - для создания ресурсов
  - `vpc.admin` - для управления сетью
  - `load-balancer.admin` - для балансировщика
- Авторизованный ключ в формате JSON

### Переменные окружения
```bash
export YC_TOKEN="your_oauth_token"
export YC_CLOUD_ID="your_cloud_id"
export YC_FOLDER_ID="your_folder_id"
```

## Этап 1: Подготовка

### 1.1 Клонирование репозитория
```bash
git clone <repository_url>
cd diplom
```

### 1.2 Настройка Terraform
```bash
cd terraform
```

Создайте файл `terraform.tfvars`:
```hcl
cloud_id    = "your_cloud_id"
folder_id   = "your_folder_id"
zone        = "ru-central1-a"
```

### 1.3 Генерация SSH ключей
```bash
ssh-keygen -t rsa -b 4096 -f ssh_key.pem -N ""
```

## Этап 2: Развертывание инфраструктуры

### 2.1 Инициализация Terraform
```bash
terraform init
```

### 2.2 Планирование развертывания
```bash
terraform plan
```

Проверьте план развертывания:
- **VPC и подсети:** 3 подсети в разных зонах доступности
- **Compute instances:** 4 виртуальные машины
- **Load Balancer:** Application Load Balancer
- **Security Groups:** Правила безопасности

### 2.3 Применение конфигурации
```bash
terraform apply
```

Подтвердите развертывание введя `yes`.

### 2.4 Получение выходных данных
```bash
terraform output
```

Ожидаемые выходные данные:
```
bastion_external_ip = "158.160.99.254"
load_balancer_ip = "158.160.99.254"
web_server_1_internal_ip = "10.0.1.5"
web_server_2_internal_ip = "10.0.2.5"
monitoring_server_internal_ip = "10.0.3.5"
zabbix_url = "http://158.160.99.254:80/zabbix"
kibana_url = "http://158.160.99.254:5601"
```

## Этап 3: Настройка серверов с Ansible

### 3.1 Подготовка Ansible
```bash
cd ../ansible
```

### 3.2 Проверка инвентаря
Убедитесь, что файл `inventory.ini` содержит актуальные IP-адреса:
```ini
[bastion]
bastion ansible_host=158.160.99.254 ansible_user=ubuntu ansible_ssh_private_key_file=ssh_key.pem

[webservers]
web1 ansible_host=10.0.1.5 ansible_user=ubuntu ansible_ssh_private_key_file=ssh_key.pem
web2 ansible_host=10.0.2.5 ansible_user=ubuntu ansible_ssh_private_key_file=ssh_key.pem

[monitoring]
monitoring ansible_host=10.0.3.5 ansible_user=ubuntu ansible_ssh_private_key_file=ssh_key.pem

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem"'
```

### 3.3 Тестирование подключения
```bash
# Проверка подключения к Bastion
ansible bastion -i inventory.ini -m ping

# Проверка подключения ко всем серверам
ansible all -i inventory.ini -m ping
```

### 3.4 Запуск playbook'ов

#### Настройка веб-серверов
```bash
ansible-playbook -i inventory.ini playbooks/webservers.yml
```

Этот playbook:
- Устанавливает Nginx
- Настраивает веб-сайт
- Настраивает логирование
- Запускает log shipper

#### Настройка мониторинга
```bash
ansible-playbook -i inventory.ini playbooks/monitoring.yml
```

Этот playbook:
- Устанавливает Docker и Docker Compose
- Настраивает Zabbix Server
- Настраивает Elasticsearch и Kibana
- Настраивает Prometheus, Grafana, Loki
- Настраивает Jaeger

## Этап 4: Проверка развертывания

### 4.1 Проверка веб-сервисов
```bash
# Проверка Load Balancer
curl -I http://158.160.99.254

# Проверка веб-серверов напрямую
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.1.5 "curl -I localhost"
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.2.5 "curl -I localhost"
```

### 4.2 Проверка мониторинга

#### Zabbix
- URL: `http://158.160.99.254:80/zabbix`
- Логин: `admin`
- Пароль: `zabbix`

Проверьте:
- Все хосты в статусе "Enabled"
- Последние данные поступают
- Триггеры настроены

#### Kibana
- URL: `http://158.160.99.254:5601`
- Проверьте индексы: `logs*`, `test-logs*`
- Убедитесь, что логи поступают

#### Grafana (через SSH туннель)
```bash
ssh -i ssh_key.pem -L 3000:localhost:3000 -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5
```
- URL: `http://localhost:3000`
- Логин: `admin`
- Пароль: `admin`

### 4.3 Проверка логирования

#### Elasticsearch
```bash
# Проверка кластера
curl http://158.160.99.254:9200/_cluster/health

# Проверка индексов
curl http://158.160.99.254:9200/_cat/indices

# Поиск логов
curl "http://158.160.99.254:9200/logs/_search?q=*&size=5&pretty"
```

## Этап 5: Подключение к серверам

### 5.1 Bastion Host
```bash
ssh -i ssh_key.pem ubuntu@158.160.99.254
```

### 5.2 Веб-серверы

#### Web Server 1
```bash
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.1.5
```

#### Web Server 2
```bash
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.2.5
```

### 5.3 Сервер мониторинга
```bash
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5
```

### 5.4 SSH туннели для локального доступа

#### Grafana
```bash
ssh -i ssh_key.pem -L 3000:localhost:3000 -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5
```

#### Prometheus
```bash
ssh -i ssh_key.pem -L 9090:localhost:9090 -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5
```

#### AlertManager
```bash
ssh -i ssh_key.pem -L 9093:localhost:9093 -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5
```

#### Jaeger UI
```bash
ssh -i ssh_key.pem -L 16686:localhost:16686 -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5
```

## Этап 6: Настройка мониторинга

### 6.1 Zabbix
1. Войдите в веб-интерфейс Zabbix
2. Проверьте автоматически добавленные хосты
3. Настройте уведомления (Configuration → Actions)
4. Создайте дополнительные дашборды при необходимости

### 6.2 Grafana
1. Войдите в Grafana
2. Проверьте datasources (Prometheus, Loki)
3. Импортируйте готовые дашборды
4. Настройте алерты

### 6.3 Elasticsearch/Kibana
1. Войдите в Kibana
2. Создайте index patterns для логов
3. Настройте визуализации
4. Создайте дашборды для мониторинга логов

## Этап 7: Тестирование

### 7.1 Нагрузочное тестирование
```bash
# Простой тест с curl
for i in {1..100}; do curl -s http://158.160.99.254 > /dev/null; done

# Тест с ab (Apache Bench)
ab -n 1000 -c 10 http://158.160.99.254/
```

### 7.2 Тестирование отказоустойчивости
```bash
# Остановка одного веб-сервера
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.1.5 "sudo systemctl stop nginx"

# Проверка, что сайт остается доступным
curl http://158.160.99.254

# Запуск сервера обратно
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.1.5 "sudo systemctl start nginx"
```

## Устранение неполадок

### Проблемы с Terraform
- Проверьте переменные окружения YC_*
- Убедитесь в корректности terraform.tfvars
- Проверьте квоты в Yandex Cloud

### Проблемы с Ansible
- Проверьте SSH ключи и их права (chmod 600)
- Убедитесь в доступности Bastion Host
- Проверьте inventory.ini на корректность IP-адресов

### Проблемы с сервисами
- Проверьте статус сервисов: `systemctl status service_name`
- Проверьте логи: `journalctl -u service_name`
- Проверьте сетевую связность: `telnet host port`

## Удаление инфраструктуры

### Полное удаление
```bash
cd terraform
terraform destroy
```

### Частичное удаление
```bash
# Удаление конкретного ресурса
terraform destroy -target=resource_type.resource_name
```

## Резервное копирование

### Конфигурации
- Все конфигурации хранятся в Git
- Регулярно делайте commit изменений

### Данные
```bash
# Backup Elasticsearch
curl -X PUT "http://158.160.99.254:9200/_snapshot/backup_repo" -H 'Content-Type: application/json' -d'
{
  "type": "fs",
  "settings": {
    "location": "/backup/elasticsearch"
  }
}'

# Backup Zabbix database
ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5 "docker exec zabbix-mysql mysqldump -u zabbix -p zabbix > /backup/zabbix_$(date +%Y%m%d).sql"
```

## Масштабирование

### Добавление веб-серверов
1. Обновите Terraform конфигурацию
2. Примените изменения: `terraform apply`
3. Обновите Ansible inventory
4. Запустите playbook для новых серверов
5. Обновите конфигурацию Load Balancer

### Вертикальное масштабирование
1. Обновите instance_type в Terraform
2. Примените изменения: `terraform apply`
3. Перезапустите сервисы при необходимости