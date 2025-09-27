-- Скрипт для настройки базы данных Zabbix
-- Этот скрипт нужно выполнить на сервере Zabbix

-- Удаляем существующего пользователя и базу данных (если есть)
DROP USER IF EXISTS 'zabbix'@'localhost';
DROP DATABASE IF EXISTS zabbix;

-- Создаем новую базу данных
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

-- Создаем пользователя с паролем
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'SecureZabbixPassword123!';

-- Предоставляем все права на базу данных zabbix
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';

-- Применяем изменения
FLUSH PRIVILEGES;

-- Показываем созданные объекты
SHOW DATABASES LIKE 'zabbix';
SELECT User, Host FROM mysql.user WHERE User = 'zabbix';