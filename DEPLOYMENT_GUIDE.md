# 🚀 РУКОВОДСТВО ПО ЗАВЕРШЕНИЮ РАЗВЕРТЫВАНИЯ

## ✅ УЖЕ ВЫПОЛНЕНО

- ✅ Terraform инфраструктура развернута (26 ресурсов)
- ✅ Web Server 1 настроен и работает
- ✅ Web Server 2 настроен и работает
- ✅ Load Balancer работает и балансирует трафик
- ✅ Bastion Host доступен
- ✅ Ansible установлен на Bastion

## 📋 ОСТАВШИЕСЯ ШАГИ

### 1. Настройка Zabbix Server

```bash
# Подключиться к Bastion
ssh -i ~/.ssh/diplom_key.pem ubuntu@158.160.104.48

# Скопировать скрипт на Zabbix сервер
scp -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no setup_zabbix.sh ubuntu@10.0.1.14:/tmp/

# Подключиться к Zabbix серверу
ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@10.0.1.14

# Запустить установку
chmod +x /tmp/setup_zabbix.sh
/tmp/setup_zabbix.sh
```

**Доступ после установки:**
- URL: http://158.160.112.98
- Логин: Admin
- Пароль: zabbix

**Время установки:** ~10-15 минут

---

### 2. Настройка Elasticsearch

```bash
# С Bastion скопировать скрипт
scp -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no setup_elasticsearch.sh ubuntu@10.0.4.34:/tmp/

# Подключиться к Elasticsearch серверу
ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@10.0.4.34

# Запустить установку
chmod +x /tmp/setup_elasticsearch.sh
/tmp/setup_elasticsearch.sh
```

**Проверка:**
```bash
curl http://10.0.4.34:9200
```

**Время установки:** ~5-7 минут

---

### 3. Настройка Kibana

```bash
# С Bastion скопировать скрипт
scp -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no setup_kibana.sh ubuntu@10.0.1.3:/tmp/

# Подключиться к Kibana серверу
ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@10.0.1.3

# Запустить установку
chmod +x /tmp/setup_kibana.sh
/tmp/setup_kibana.sh
```

**Доступ после установки:**
- URL: http://62.84.112.42:5601

**Время установки:** ~5-7 минут  
**Примечание:** Kibana может запускаться 1-2 минуты после установки

---

## 🔧 БЫСТРАЯ УСТАНОВКА ВСЕХ СЕРВИСОВ

Для автоматической установки всех оставшихся сервисов:

```bash
# 1. Подключиться к Bastion
ssh -i ~/.ssh/diplom_key.pem ubuntu@158.160.104.48

# 2. Скопировать все скрипты на Bastion (если еще не скопированы)
# Скрипты уже должны быть в /tmp/ на Bastion

# 3. Запустить установку Elasticsearch (в фоне)
ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@10.0.4.34 'bash -s' < /tmp/setup_elasticsearch.sh > /tmp/elasticsearch_install.log 2>&1 &

# 4. Запустить установку Zabbix (в фоне)
ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@10.0.1.14 'bash -s' < /tmp/setup_zabbix.sh > /tmp/zabbix_install.log 2>&1 &

# 5. Подождать 5 минут для Elasticsearch
sleep 300

# 6. Запустить установку Kibana
ssh -i /tmp/diplom_key.pem -o StrictHostKeyChecking=no ubuntu@10.0.1.3 'bash -s' < /tmp/setup_kibana.sh > /tmp/kibana_install.log 2>&1 &

# 7. Проверить логи
tail -f /tmp/*_install.log
```

---

## 📊 ПРОВЕРКА РАБОТОСПОСОБНОСТИ

### Load Balancer
```bash
curl http://158.160.168.17
# Должен возвращать страницы от Web Server 1 или Web Server 2
```

### Zabbix
```bash
curl -I http://158.160.112.98
# Должен вернуть HTTP 200
```

### Elasticsearch
```bash
curl http://10.0.4.34:9200
# Должен вернуть JSON с информацией о кластере
```

### Kibana
```bash
curl -I http://62.84.112.42:5601
# Должен вернуть HTTP 302 или 200
```

---

## 🔐 УЧЕТНЫЕ ДАННЫЕ

### Zabbix
- **URL:** http://158.160.112.98
- **Логин:** Admin
- **Пароль:** zabbix
- **База данных:** zabbix / zabbix_password

### Kibana
- **URL:** http://62.84.112.42:5601
- **Аутентификация:** Отключена (для разработки)

### SSH
- **Ключ:** `~/.ssh/diplom_key.pem` или `C:\temp\ssh_key_python.pem`
- **Пользователь:** ubuntu
- **Bastion:** 158.160.104.48

---

## 📝 ДОПОЛНИТЕЛЬНЫЕ НАСТРОЙКИ

### Настройка мониторинга веб-серверов в Zabbix

После установки Zabbix:

1. Войти в веб-интерфейс Zabbix
2. Configuration → Hosts → Create host
3. Добавить Web Server 1 (10.0.2.21) и Web Server 2 (10.0.3.3)
4. Применить шаблон "Linux by Zabbix agent"
5. Установить Zabbix Agent на веб-серверы:

```bash
# На каждом веб-сервере
sudo apt-get install -y zabbix-agent
sudo sed -i 's/Server=127.0.0.1/Server=10.0.1.14/' /etc/zabbix/zabbix_agentd.conf
sudo systemctl restart zabbix-agent
sudo systemctl enable zabbix-agent
```

### Настройка сбора логов в Elasticsearch

На каждом веб-сервере установить Filebeat:

```bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt-get update
sudo apt-get install -y filebeat

# Настроить Filebeat
sudo filebeat modules enable system nginx
sudo sed -i 's|output.elasticsearch:|#output.elasticsearch:|' /etc/filebeat/filebeat.yml
sudo sed -i 's|hosts: \["localhost:9200"\]|#hosts: ["localhost:9200"]|' /etc/filebeat/filebeat.yml
echo "output.elasticsearch:" | sudo tee -a /etc/filebeat/filebeat.yml
echo "  hosts: [\"10.0.4.34:9200\"]" | sudo tee -a /etc/filebeat/filebeat.yml

sudo filebeat setup
sudo systemctl enable filebeat
sudo systemctl start filebeat
```

---

## ⚠️ ВАЖНЫЕ ЗАМЕЧАНИЯ

1. **Стоимость:** Все серверы работают и начисляется оплата
2. **Безопасность:** Для production необходимо:
   - Включить SSL/TLS
   - Настроить аутентификацию в Kibana
   - Изменить пароли по умолчанию
   - Ограничить доступ через Security Groups
3. **Резервное копирование:** Настроить snapshot schedule для важных данных
4. **Мониторинг:** После настройки Zabbix добавить все серверы в мониторинг

---

## 📞 ПОДДЕРЖКА

При возникновении проблем:

1. Проверить логи: `sudo journalctl -u <service-name> -f`
2. Проверить статус: `sudo systemctl status <service-name>`
3. Проверить подключение: `telnet <ip> <port>`
4. Проверить Security Groups в Yandex Cloud Console

---

## ✅ ЧЕКЛИСТ ЗАВЕРШЕНИЯ

- [x] Terraform инфраструктура развернута
- [x] Web Server 1 настроен
- [x] Web Server 2 настроен
- [x] Load Balancer работает
- [ ] Zabbix Server установлен и настроен
- [ ] Elasticsearch установлен и работает
- [ ] Kibana установлена и доступна
- [ ] Zabbix Agent установлен на веб-серверах
- [ ] Filebeat настроен для сбора логов
- [ ] Все сервисы добавлены в мониторинг Zabbix
- [ ] Проведено тестирование отказоустойчивости
- [ ] Документация обновлена

**Текущий прогресс:** 4/12 (33%)

