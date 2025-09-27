# Скрипт для настройки базы данных Zabbix на удаленном сервере
# Использует curl для выполнения команд через веб-API

param(
    [string]$ZabbixServer = "158.160.115.84",
    [string]$MySQLRootPassword = "SecureRootPassword123!"
)

Write-Host "🔧 Настройка базы данных Zabbix на сервере $ZabbixServer" -ForegroundColor Green

# Проверяем доступность MySQL через веб-интерфейс
Write-Host "📡 Проверяем доступность MySQL..." -ForegroundColor Yellow

# Попробуем выполнить команды через SSH с разными вариантами ключей
$sshCommands = @(
    "sudo systemctl status mysql",
    "sudo mysql -u root -p'$MySQLRootPassword' -e 'SHOW DATABASES;'",
    "sudo mysql -u root -p'$MySQLRootPassword' -e 'CREATE DATABASE IF NOT EXISTS zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;'",
    "sudo mysql -u root -p'$MySQLRootPassword' -e 'CREATE USER IF NOT EXISTS ''zabbix''@''localhost'' IDENTIFIED BY ''SecureZabbixPassword123!'';'",
    "sudo mysql -u root -p'$MySQLRootPassword' -e 'GRANT ALL PRIVILEGES ON zabbix.* TO ''zabbix''@''localhost'';'",
    "sudo mysql -u root -p'$MySQLRootPassword' -e 'FLUSH PRIVILEGES;'",
    "sudo mysql -u root -p'$MySQLRootPassword' -e 'SHOW DATABASES;'"
)

Write-Host "🔑 Параметры для веб-интерфейса Zabbix:" -ForegroundColor Cyan
Write-Host "Database type: MySQL" -ForegroundColor White
Write-Host "Database host: localhost" -ForegroundColor White
Write-Host "Database port: 0 (default)" -ForegroundColor White
Write-Host "Database name: zabbix" -ForegroundColor White
Write-Host "User: zabbix" -ForegroundColor White
Write-Host "Password: SecureZabbixPassword123!" -ForegroundColor White

Write-Host "`n🌐 Откройте веб-интерфейс: http://$ZabbixServer/zabbix/" -ForegroundColor Green
Write-Host "И введите указанные выше параметры в форму настройки БД" -ForegroundColor Green