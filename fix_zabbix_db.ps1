# Скрипт для исправления настроек базы данных Zabbix
# Использует SSH для выполнения команд на удаленном сервере

param(
    [string]$ZabbixServer = "158.160.33.170",
    [string]$SSHKey = "ssh_key.pem"
)

Write-Host "🔧 Исправление настроек базы данных Zabbix на сервере $ZabbixServer" -ForegroundColor Green

# Команды для выполнения на удаленном сервере
$commands = @(
    "sudo systemctl status mysql",
    "sudo mysql -u root -e 'DROP USER IF EXISTS ''zabbix''@''localhost'';'",
    "sudo mysql -u root -e 'CREATE USER ''zabbix''@''localhost'' IDENTIFIED BY ''SecureZabbixPassword123!'';'",
    "sudo mysql -u root -e 'DROP DATABASE IF EXISTS zabbix;'",
    "sudo mysql -u root -e 'CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;'",
    "sudo mysql -u root -e 'GRANT ALL PRIVILEGES ON zabbix.* TO ''zabbix''@''localhost'';'",
    "sudo mysql -u root -e 'FLUSH PRIVILEGES;'",
    "sudo mysql -u root -e 'SHOW DATABASES;'",
    "sudo mysql -u root -e 'SELECT User, Host FROM mysql.user WHERE User = ''zabbix'';'"
)

Write-Host "📋 Выполняем команды настройки БД..." -ForegroundColor Yellow

foreach ($cmd in $commands) {
    Write-Host "Выполняем: $cmd" -ForegroundColor Cyan
    try {
        # Используем plink для выполнения команд через SSH
        $result = & plink -batch -i $SSHKey yc-user@$ZabbixServer $cmd 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Успешно" -ForegroundColor Green
            if ($result) { Write-Host $result -ForegroundColor White }
        } else {
            Write-Host "❌ Ошибка: $result" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Исключение: $($_.Exception.Message)" -ForegroundColor Red
    }
    Start-Sleep -Seconds 1
}

Write-Host "`n🔑 Параметры для веб-интерфейса Zabbix:" -ForegroundColor Cyan
Write-Host "Database type: MySQL" -ForegroundColor White
Write-Host "Database host: localhost" -ForegroundColor White
Write-Host "Database port: 0 (default)" -ForegroundColor White
Write-Host "Database name: zabbix" -ForegroundColor White
Write-Host "User: zabbix" -ForegroundColor White
Write-Host "Password: SecureZabbixPassword123!" -ForegroundColor White

Write-Host "`n🌐 Откройте веб-интерфейс: http://$ZabbixServer/zabbix/" -ForegroundColor Green
Write-Host "И введите указанные выше параметры в форму настройки БД" -ForegroundColor Green