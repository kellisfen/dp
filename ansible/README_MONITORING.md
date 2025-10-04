# Система мониторинга и логирования

Этот проект настраивает полную систему мониторинга и логирования для веб-серверов с использованием Prometheus, Grafana, Elasticsearch и Kibana.

## Архитектура системы

### Компоненты мониторинга (на сервере Kibana):
- **Prometheus** (порт 9090) - сбор и хранение метрик
- **Grafana** (порт 3000) - визуализация метрик
- **AlertManager** (порт 9093) - управление оповещениями
- **Blackbox Exporter** (порт 9115) - проверка доступности сервисов

### Компоненты логирования:
- **Elasticsearch** - хранение и индексация логов
- **Kibana** (порт 5601) - визуализация и анализ логов
- **Filebeat** - сбор логов с веб-серверов

### Exporters:
- **Node Exporter** (порт 9100) - системные метрики на всех серверах
- **Nginx Exporter** (порт 9113) - метрики Nginx на веб-серверах
- **Elasticsearch Exporter** (порт 9114) - метрики Elasticsearch

## Установка

### 1. Подготовка инвентаря
Убедитесь, что в файле `inventory/hosts.yml` правильно настроены группы серверов:
```yaml
all:
  children:
    web_servers:
      hosts:
        web1:
          ansible_host: IP_WEB_SERVER_1
        web2:
          ansible_host: IP_WEB_SERVER_2
    elasticsearch:
      hosts:
        elasticsearch:
          ansible_host: IP_ELASTICSEARCH_SERVER
    kibana:
      hosts:
        kibana:
          ansible_host: IP_KIBANA_SERVER
```

### 2. Запуск полной установки
```bash
# Установка всей системы
ansible-playbook -i inventory/hosts.yml site.yml

# Установка только мониторинга
ansible-playbook -i inventory/hosts.yml site.yml --tags monitoring

# Установка только логирования
ansible-playbook -i inventory/hosts.yml site.yml --tags logging

# Только проверка системы
ansible-playbook -i inventory/hosts.yml site.yml --tags verify
```

### 3. Поэтапная установка

#### Установка exporters на все серверы:
```bash
ansible-playbook -i inventory/hosts.yml playbooks/install_exporters.yml
```

#### Установка стека мониторинга на сервер Kibana:
```bash
ansible-playbook -i inventory/hosts.yml playbooks/monitoring_on_kibana.yml
```

#### Проверка работы системы:
```bash
ansible-playbook -i inventory/hosts.yml playbooks/verify_monitoring.yml
```

## Доступ к сервисам

После успешной установки сервисы будут доступны по следующим адресам:

### Мониторинг:
- **Prometheus**: http://KIBANA_SERVER_IP:9090
- **Grafana**: http://KIBANA_SERVER_IP:3000
  - Логин: `admin`
  - Пароль: `admin` (будет предложено изменить при первом входе)
- **AlertManager**: http://KIBANA_SERVER_IP:9093

### Логирование:
- **Kibana**: http://KIBANA_SERVER_IP:5601
- **Elasticsearch**: http://ELASTICSEARCH_SERVER_IP:9200

### Метрики:
- **Node Exporter**: http://SERVER_IP:9100/metrics (на всех серверах)
- **Nginx Exporter**: http://WEB_SERVER_IP:9113/metrics (на веб-серверах)
- **Elasticsearch Exporter**: http://ELASTICSEARCH_SERVER_IP:9114/metrics

## Настройка Grafana

### Добавление источника данных Prometheus:
1. Откройте Grafana (http://KIBANA_SERVER_IP:3000)
2. Войдите с учетными данными admin/admin
3. Перейдите в Configuration → Data Sources
4. Добавьте Prometheus:
   - URL: `http://localhost:9090`
   - Access: `Server (default)`

### Импорт дашбордов:
Дашборды автоматически создаются при установке:
- **System Metrics** - системные метрики серверов
- **Nginx Metrics** - метрики веб-серверов Nginx
- **Elasticsearch Metrics** - метрики Elasticsearch

## Настройка Kibana

### Создание индексных паттернов:
1. Откройте Kibana (http://KIBANA_SERVER_IP:5601)
2. Перейдите в Stack Management → Index Patterns
3. Создайте паттерн `filebeat-*` для логов веб-серверов
4. Выберите `@timestamp` как поле времени

### Просмотр логов:
- Перейдите в Discover для просмотра логов в реальном времени
- Используйте фильтры для поиска по конкретным серверам или типам логов

## Мониторинг и оповещения

### Prometheus targets:
Prometheus автоматически настроен для мониторинга:
- Самого Prometheus
- Node Exporter на всех серверах
- Nginx Exporter на веб-серверах
- Elasticsearch Exporter
- Blackbox проверки доступности сервисов

### AlertManager:
Настроен для отправки оповещений через webhook. Для настройки email-уведомлений отредактируйте файл `/etc/prometheus/alertmanager.yml` на сервере Kibana.

## Устранение неполадок

### Проверка статуса сервисов:
```bash
# На сервере Kibana
sudo systemctl status prometheus
sudo systemctl status grafana-server
sudo systemctl status alertmanager
sudo systemctl status blackbox_exporter

# На всех серверах
sudo systemctl status node_exporter

# На веб-серверах
sudo systemctl status nginx_exporter
sudo systemctl status filebeat

# На сервере Elasticsearch
sudo systemctl status elasticsearch_exporter
```

### Просмотр логов:
```bash
sudo journalctl -u prometheus -f
sudo journalctl -u grafana-server -f
sudo journalctl -u filebeat -f
```

### Проверка конфигурации Prometheus:
```bash
# Проверка синтаксиса конфигурации
sudo /usr/local/bin/promtool check config /etc/prometheus/prometheus.yml

# Перезагрузка конфигурации без перезапуска
sudo curl -X POST http://localhost:9090/-/reload
```

## Безопасность

### Firewall:
Автоматически настраиваются правила UFW для необходимых портов:
- 9090 (Prometheus)
- 3000 (Grafana)
- 9093 (AlertManager)
- 9100 (Node Exporter)
- 9113 (Nginx Exporter)
- 9114 (Elasticsearch Exporter)
- 9115 (Blackbox Exporter)
- 5601 (Kibana)

### Рекомендации:
1. Измените пароль администратора Grafana после первого входа
2. Настройте HTTPS для веб-интерфейсов
3. Ограничьте доступ к портам мониторинга только с необходимых IP-адресов
4. Регулярно обновляйте компоненты системы

## Масштабирование

Система легко масштабируется:
- Добавьте новые серверы в инвентарь
- Запустите playbook установки exporters
- Prometheus автоматически обнаружит новые targets

## Поддержка

При возникновении проблем:
1. Проверьте статус всех сервисов
2. Просмотрите логи соответствующих компонентов
3. Убедитесь, что все порты открыты и доступны
4. Проверьте конфигурационные файлы на синтаксические ошибки