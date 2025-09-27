# Инструкция по настройке Zabbix

## Проблема
Веб-интерфейс Zabbix доступен по адресу http://158.160.33.170/zabbix/, но показывает ошибку подключения к базе данных:
- "Cannot connect to the database"
- "Access denied for user 'zabbix'@'localhost' (using password: YES)"

## Решение

### Вариант 1: Настройка через веб-интерфейс
1. Откройте http://158.160.33.170/zabbix/
2. На странице "Configure DB connection" введите следующие параметры:
   - **Database type**: MySQL
   - **Database host**: localhost
   - **Database port**: 0 (использовать порт по умолчанию)
   - **Database name**: zabbix
   - **User**: zabbix
   - **Password**: SecureZabbixPassword123!

### Вариант 2: Если нужно создать базу данных вручную
Если база данных еще не создана, выполните следующие команды на сервере Zabbix:

```sql
-- Подключитесь к MySQL как root
mysql -u root -p

-- Выполните следующие команды:
DROP USER IF EXISTS 'zabbix'@'localhost';
DROP DATABASE IF EXISTS zabbix;
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'SecureZabbixPassword123!';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### Вариант 3: Импорт схемы базы данных
После создания базы данных импортируйте схему Zabbix:

```bash
# Найдите файл схемы
find /usr/share -name "*.sql.gz" | grep zabbix

# Импортируйте схему (обычно это один из этих файлов):
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql -u zabbix -p'SecureZabbixPassword123!' zabbix
# или
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u zabbix -p'SecureZabbixPassword123!' zabbix
```

### Проверка настроек Zabbix сервера
Убедитесь, что в файле `/etc/zabbix/zabbix_server.conf` указаны правильные параметры:

```
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=SecureZabbixPassword123!
```

После изменения конфигурации перезапустите Zabbix сервер:
```bash
sudo systemctl restart zabbix-server
sudo systemctl status zabbix-server
```

## Доступ к веб-интерфейсу
После успешной настройки базы данных:
- URL: http://158.160.33.170/zabbix/
- Логин по умолчанию: Admin
- Пароль по умолчанию: zabbix

## Статус SSH подключения
⚠️ **Внимание**: SSH подключение к серверам в данный момент не работает. Возможные причины:
- Проблемы с SSH ключами
- Настройки файрвола
- Конфигурация безопасности

Для решения проблем с SSH может потребоваться:
1. Проверить настройки Security Groups в Yandex Cloud
2. Убедиться, что SSH ключи правильно настроены
3. Проверить конфигурацию sshd на серверах