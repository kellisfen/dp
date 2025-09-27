# Скрипт для прямого выполнения команд MySQL на сервере Zabbix
param(
    [string]$ZabbixServer = "158.160.33.170"
)

Write-Host "🔧 Настройка базы данных Zabbix на сервере $ZabbixServer" -ForegroundColor Green

# Команды MySQL для выполнения
$mysqlCommands = @(
    "DROP USER IF EXISTS 'zabbix'@'localhost';",
    "DROP DATABASE IF EXISTS zabbix;",
    "CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;",
    "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'SecureZabbixPassword123!';",
    "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';",
    "FLUSH PRIVILEGES;",
    "SHOW DATABASES;",
    "SELECT User, Host FROM mysql.user WHERE User = 'zabbix';"
)

Write-Host "📋 Команды для выполнения на сервере MySQL:" -ForegroundColor Yellow

foreach ($cmd in $mysqlCommands) {
    Write-Host "mysql -u root -e `"$cmd`"" -ForegroundColor Cyan
}

Write-Host "`n💡 Для выполнения этих команд на сервере:" -ForegroundColor Yellow
Write-Host "1. Подключитесь к серверу: ssh -i ssh_key.pem yc-user@$ZabbixServer" -ForegroundColor White
Write-Host "2. Выполните команды MySQL как root пользователь" -ForegroundColor White
Write-Host "3. Или выполните: sudo mysql < /path/to/setup_zabbix_db.sql" -ForegroundColor White

Write-Host "`n🔑 После настройки используйте эти параметры в веб-интерфейсе:" -ForegroundColor Cyan
Write-Host "Database type: MySQL" -ForegroundColor White
Write-Host "Database host: localhost" -ForegroundColor White
Write-Host "Database port: 0 (default)" -ForegroundColor White
Write-Host "Database name: zabbix" -ForegroundColor White
Write-Host "User: zabbix" -ForegroundColor White
Write-Host "Password: SecureZabbixPassword123!" -ForegroundColor White

Write-Host "`n🌐 Веб-интерфейс: http://$ZabbixServer/zabbix/" -ForegroundColor Green