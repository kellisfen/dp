# Скрипт для исправления базы данных Zabbix через бастион
param(
    [string]$BastionIP = "158.160.99.254",
    [string]$ZabbixInternalIP = "10.0.1.7",
    [string]$SSHKey = "ssh_key.pem"
)

Write-Host "🔧 Исправление базы данных Zabbix через бастион" -ForegroundColor Green
Write-Host "Бастион: $BastionIP" -ForegroundColor Yellow
Write-Host "Zabbix (внутренний): $ZabbixInternalIP" -ForegroundColor Yellow

# Команды MySQL для выполнения
$mysqlCommands = @(
    "sudo systemctl stop zabbix-server",
    "sudo mysql -u root -e `"DROP USER IF EXISTS 'zabbix'@'localhost';`"",
    "sudo mysql -u root -e `"DROP DATABASE IF EXISTS zabbix;`"",
    "sudo mysql -u root -e `"CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;`"",
    "sudo mysql -u root -e `"CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'SecureZabbixPassword123!';`"",
    "sudo mysql -u root -e `"GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';`"",
    "sudo mysql -u root -e `"FLUSH PRIVILEGES;`"",
    "sudo sed -i 's/^DBPassword=.*/DBPassword=SecureZabbixPassword123!/' /etc/zabbix/zabbix_server.conf",
    "sudo mysql -u zabbix -p'SecureZabbixPassword123!' zabbix < /usr/share/zabbix-sql-scripts/mysql/server.sql.gz",
    "sudo systemctl start zabbix-server",
    "sudo systemctl enable zabbix-server",
    "sudo systemctl status zabbix-server"
)

Write-Host "`n📋 Выполнение команд на Zabbix сервере..." -ForegroundColor Cyan

foreach ($cmd in $mysqlCommands) {
    Write-Host "`n🔄 Выполняю: $cmd" -ForegroundColor Yellow
    
    # Формируем SSH команду через бастион
    $sshCommand = "ssh -o StrictHostKeyChecking=no -i $SSHKey -o ProxyCommand=`"ssh -W $ZabbixInternalIP`:22 -q ubuntu@$BastionIP -i $SSHKey`" ubuntu@$ZabbixInternalIP `"$cmd`""
    
    try {
        $result = Invoke-Expression $sshCommand
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Успешно выполнено" -ForegroundColor Green
            if ($result) {
                Write-Host "Результат: $result" -ForegroundColor White
            }
        } else {
            Write-Host "⚠️ Команда завершилась с кодом: $LASTEXITCODE" -ForegroundColor Yellow
            if ($result) {
                Write-Host "Вывод: $result" -ForegroundColor White
            }
        }
    }
    catch {
        Write-Host "❌ Ошибка выполнения: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Start-Sleep -Seconds 2
}

Write-Host "`n🔍 Проверка подключения к базе данных..." -ForegroundColor Cyan
$testCommand = "mysql -u zabbix -p'SecureZabbixPassword123!' -e `"SELECT 'Connection successful' AS status;`""
$sshTestCommand = "ssh -o StrictHostKeyChecking=no -i $SSHKey -o ProxyCommand=`"ssh -W $ZabbixInternalIP`:22 -q ubuntu@$BastionIP -i $SSHKey`" ubuntu@$ZabbixInternalIP `"$testCommand`""

try {
    $testResult = Invoke-Expression $sshTestCommand
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Подключение к базе данных успешно!" -ForegroundColor Green
        Write-Host "Результат: $testResult" -ForegroundColor White
    } else {
        Write-Host "❌ Ошибка подключения к базе данных" -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ Ошибка тестирования подключения: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🌐 Параметры для веб-интерфейса Zabbix:" -ForegroundColor Green
Write-Host "URL: http://158.160.33.170/zabbix/" -ForegroundColor White
Write-Host "Database type: MySQL" -ForegroundColor White
Write-Host "Database host: localhost" -ForegroundColor White
Write-Host "Database port: 0 (default)" -ForegroundColor White
Write-Host "Database name: zabbix" -ForegroundColor White
Write-Host "User: zabbix" -ForegroundColor White
Write-Host "Password: SecureZabbixPassword123!" -ForegroundColor White