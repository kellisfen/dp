-- Скрипт для настройки базы данных Zabbix
-- Выполнить как root пользователь MySQL

-- Удаление существующего пользователя (если есть)
DROP USER IF EXISTS 'zabbix'@'localhost';

-- Удаление существующей базы данных (если есть)
DROP DATABASE IF EXISTS zabbix;

-- Создание базы данных
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

-- Создание пользователя
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'SecureZabbixPassword123!';

-- Предоставление прав
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';

-- Обновление привилегий
FLUSH PRIVILEGES;

-- Показать созданные базы данных
SHOW DATABASES;

-- Показать пользователей
SELECT User, Host FROM mysql.user WHERE User = 'zabbix';

-- Проверка подключения
-- Эта команда должна выполняться отдельно для проверки:
-- mysql -u zabbix -p'SecureZabbixPassword123!' -e "SELECT 'Connection successful' AS status;"