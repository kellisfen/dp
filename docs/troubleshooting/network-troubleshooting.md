# Справочник по устранению неполадок

## Проблемы с подключением

### SSH подключение к Bastion Host

#### Проблема: Connection refused
```bash
ssh: connect to host 158.160.99.254 port 22: Connection refused
```

**Решения:**
1. Проверьте доступность хоста:
   ```bash
   ping 158.160.99.254
   ```

2. Проверьте права доступа к SSH ключу:
   ```bash
   chmod 600 ssh_key.pem
   ```

3. Проверьте правильность пути к ключу:
   ```bash
   ls -la ssh_key.pem
   ```

4. Попробуйте подключение с отладкой:
   ```bash
   ssh -v -i ssh_key.pem ubuntu@158.160.99.254
   ```

#### Проблема: Permission denied (publickey)
```bash
ubuntu@158.160.99.254: Permission denied (publickey).
```

**Решения:**
1. Убедитесь, что используете правильный ключ:
   ```bash
   ssh-keygen -l -f ssh_key.pem
   ```

2. Проверьте формат ключа (должен быть PEM):
   ```bash
   head -1 ssh_key.pem
   # Должно начинаться с -----BEGIN RSA PRIVATE KEY-----
   ```

3. Попробуйте добавить ключ в SSH агент:
   ```bash
   ssh-add ssh_key.pem
   ssh ubuntu@158.160.99.254
   ```

### SSH подключение к внутренним серверам

#### Проблема: Connection timed out через ProxyCommand
```bash
ssh: connect to host 10.0.1.5 port 22: Connection timed out
```

**Решения:**
1. Проверьте подключение к Bastion Host:
   ```bash
   ssh -i ssh_key.pem ubuntu@158.160.99.254 "echo 'Bastion OK'"
   ```

2. Проверьте доступность внутреннего сервера с Bastion Host:
   ```bash
   ssh -i ssh_key.pem ubuntu@158.160.99.254 "ping -c 3 10.0.1.5"
   ```

3. Проверьте SSH сервис на целевом хосте:
   ```bash
   ssh -i ssh_key.pem ubuntu@158.160.99.254 "nc -zv 10.0.1.5 22"
   ```

4. Используйте полную команду с отладкой:
   ```bash
   ssh -v -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.1.5
   ```

#### Проблема: Host key verification failed
```bash
Host key verification failed.
```

**Решения:**
1. Очистите known_hosts:
   ```bash
   ssh-keygen -R 10.0.1.5
   ssh-keygen -R 158.160.99.254
   ```

2. Используйте опцию StrictHostKeyChecking:
   ```bash
   ssh -i ssh_key.pem -o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.1.5
   ```

## Проблемы с веб-сервисами

### Недоступность веб-сайта

#### Проблема: Сайт не открывается (http://84.201.168.191)
**Диагностика:**
1. Проверьте доступность Load Balancer:
   ```bash
   curl -I http://84.201.168.191
   ```

2. Проверьте статус Nginx на веб-серверах:
   ```bash
   ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.1.5 "sudo systemctl status nginx"
   ```

3. Проверьте логи Nginx:
   ```bash
   ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.1.5 "sudo tail -f /var/log/nginx/error.log"
   ```

**Решения:**
1. Перезапустите Nginx:
   ```bash
   sudo systemctl restart nginx
   ```

2. Проверьте конфигурацию Nginx:
   ```bash
   sudo nginx -t
   ```

3. Проверьте порты:
   ```bash
   sudo netstat -tulpn | grep :80
   ```

### Недоступность Zabbix

#### Проблема: Zabbix не открывается (http://158.160.33.170/zabbix)
**Диагностика:**
1. Проверьте статус Apache/Nginx:
   ```bash
   ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5 "sudo systemctl status apache2"
   ```

2. Проверьте статус Zabbix сервера:
   ```bash
   ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5 "sudo systemctl status zabbix-server"
   ```

3. Проверьте логи Zabbix:
   ```bash
   sudo tail -f /var/log/zabbix/zabbix_server.log
   ```

### Недоступность Kibana

#### Проблема: Kibana не открывается (http://158.160.119.108:5601)
**Диагностика:**
1. Проверьте статус Elasticsearch:
   ```bash
   curl -X GET "localhost:9200/_cluster/health?pretty"
   ```

2. Проверьте статус Kibana:
   ```bash
   docker ps | grep kibana
   docker logs kibana_container_name
   ```

3. Проверьте порт 5601:
   ```bash
   sudo netstat -tulpn | grep :5601
   ```

## Проблемы с SSH туннелями

### Туннель для Grafana не работает

#### Проблема: localhost:3000 недоступен после создания туннеля
**Диагностика:**
1. Проверьте, что туннель активен:
   ```bash
   ps aux | grep "ssh.*3000"
   ```

2. Проверьте статус Grafana на сервере:
   ```bash
   ssh -i ssh_key.pem -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5 "docker ps | grep grafana"
   ```

3. Проверьте логи Grafana:
   ```bash
   docker logs grafana_container_name
   ```

**Решения:**
1. Пересоздайте туннель:
   ```bash
   # Завершите существующий туннель
   pkill -f "ssh.*3000"
   
   # Создайте новый туннель
   ssh -i ssh_key.pem -L 3000:localhost:3000 -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5
   ```

2. Используйте другой локальный порт:
   ```bash
   ssh -i ssh_key.pem -L 3001:localhost:3000 -o ProxyCommand="ssh -W %h:%p -q ubuntu@158.160.99.254 -i ssh_key.pem" ubuntu@10.0.3.5
   ```

## Проблемы с мониторингом

### Zabbix не получает данные

#### Проблема: Хосты показывают статус "Недоступен"
**Диагностика:**
1. Проверьте Zabbix агент на хосте:
   ```bash
   sudo systemctl status zabbix-agent
   ```

2. Проверьте конфигурацию агента:
   ```bash
   sudo cat /etc/zabbix/zabbix_agentd.conf | grep Server
   ```

3. Проверьте сетевое соединение:
   ```bash
   telnet zabbix_server_ip 10050
   ```

**Решения:**
1. Перезапустите Zabbix агент:
   ```bash
   sudo systemctl restart zabbix-agent
   ```

2. Проверьте firewall:
   ```bash
   sudo ufw status
   sudo ufw allow 10050
   ```

### Prometheus не собирает метрики

#### Проблема: Targets показывают статус "Down"
**Диагностика:**
1. Проверьте доступность экспортеров:
   ```bash
   curl http://target_host:9100/metrics
   ```

2. Проверьте конфигурацию Prometheus:
   ```bash
   docker exec prometheus_container cat /etc/prometheus/prometheus.yml
   ```

3. Проверьте логи Prometheus:
   ```bash
   docker logs prometheus_container
   ```

## Проблемы с логированием

### Elasticsearch недоступен

#### Проблема: Kibana показывает ошибку подключения к Elasticsearch
**Диагностика:**
1. Проверьте статус Elasticsearch:
   ```bash
   curl -X GET "localhost:9200/_cluster/health?pretty"
   ```

2. Проверьте использование памяти:
   ```bash
   free -h
   docker stats elasticsearch_container
   ```

3. Проверьте логи Elasticsearch:
   ```bash
   docker logs elasticsearch_container
   ```

**Решения:**
1. Увеличьте память для Elasticsearch:
   ```bash
   # В docker-compose.yml
   environment:
     - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
   ```

2. Очистите старые индексы:
   ```bash
   curl -X DELETE "localhost:9200/old_index_name"
   ```

### Логи не поступают в Elasticsearch

#### Проблема: В Kibana нет новых логов
**Диагностика:**
1. Проверьте статус log shipper:
   ```bash
   ps aux | grep log_shipper
   ```

2. Проверьте логи log shipper:
   ```bash
   tail -f /var/log/log_shipper.log
   ```

3. Проверьте сетевое соединение:
   ```bash
   telnet elasticsearch_host 9200
   ```

## Общие команды диагностики

### Проверка сетевой связности
```bash
# Ping
ping -c 3 target_host

# Traceroute
traceroute target_host

# Проверка портов
nc -zv target_host port_number

# Проверка DNS
nslookup target_host
dig target_host
```

### Проверка системных ресурсов
```bash
# CPU и память
htop
top

# Использование диска
df -h
du -sh /var/log/*

# Сетевые соединения
netstat -tulpn
ss -tulpn

# Процессы
ps aux | grep service_name
```

### Проверка логов системы
```bash
# Системные логи
sudo journalctl -f
sudo journalctl -u service_name

# Логи аутентификации
sudo tail -f /var/log/auth.log

# Логи ядра
sudo dmesg | tail
```

## Контакты для поддержки

При возникновении критических проблем:
1. Проверьте статус всех сервисов
2. Соберите логи ошибок
3. Задокументируйте шаги воспроизведения
4. Обратитесь к системному администратору

### Полезные ссылки
- [Документация Zabbix](https://www.zabbix.com/documentation)
- [Документация Elasticsearch](https://www.elastic.co/guide/)
- [Документация Prometheus](https://prometheus.io/docs/)
- [Документация Grafana](https://grafana.com/docs/)