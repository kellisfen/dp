# PowerShell скрипт для импорта дашборда Node Exporter Full в Grafana
# Использование: .\import_grafana_dashboard.ps1

Write-Host "=== Импорт дашборда Node Exporter Full в Grafana ===" -ForegroundColor Cyan
Write-Host ""

# Параметры
$GRAFANA_URL = "http://62.84.112.42:3000"
$GRAFANA_USER = "admin"
$GRAFANA_PASSWORD = "DevOps2025!"  # Замените на ваш пароль
$DASHBOARD_ID = 1860

# Создание учетных данных для Basic Auth
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${GRAFANA_USER}:${GRAFANA_PASSWORD}"))
$headers = @{
    "Authorization" = "Basic $base64AuthInfo"
    "Content-Type" = "application/json"
}

Write-Host "1. Проверка подключения к Grafana..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "$GRAFANA_URL/api/health" -Method Get -TimeoutSec 10
    Write-Host "   ✅ Grafana доступна (версия: $($health.version))" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Grafana недоступна: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "2. Проверка аутентификации..." -ForegroundColor Yellow
try {
    $user = Invoke-RestMethod -Uri "$GRAFANA_URL/api/user" -Method Get -Headers $headers -TimeoutSec 10
    Write-Host "   ✅ Аутентификация успешна (пользователь: $($user.login))" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Ошибка аутентификации: $_" -ForegroundColor Red
    Write-Host "   Проверьте логин и пароль в скрипте" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "3. Проверка Data Source Prometheus..." -ForegroundColor Yellow
try {
    $datasources = Invoke-RestMethod -Uri "$GRAFANA_URL/api/datasources" -Method Get -Headers $headers -TimeoutSec 10
    $prometheus = $datasources | Where-Object { $_.type -eq "prometheus" } | Select-Object -First 1
    
    if ($prometheus) {
        Write-Host "   ✅ Prometheus Data Source найден (ID: $($prometheus.id), Name: $($prometheus.name))" -ForegroundColor Green
        $PROMETHEUS_UID = $prometheus.uid
    } else {
        Write-Host "   ❌ Prometheus Data Source не найден" -ForegroundColor Red
        Write-Host "   Создайте Data Source вручную в Grafana" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "   ❌ Ошибка получения Data Sources: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "4. Скачивание дашборда с Grafana.com..." -ForegroundColor Yellow
try {
    $dashboardJson = Invoke-RestMethod -Uri "https://grafana.com/api/dashboards/$DASHBOARD_ID/revisions/latest/download" -Method Get -TimeoutSec 30
    Write-Host "   ✅ Дашборд скачан (ID: $DASHBOARD_ID)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Ошибка скачивания дашборда: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "5. Подготовка дашборда для импорта..." -ForegroundColor Yellow

# Обновление Data Source в дашборде
if ($dashboardJson.PSObject.Properties.Name -contains "__inputs") {
    foreach ($input in $dashboardJson.__inputs) {
        if ($input.type -eq "datasource" -and $input.pluginId -eq "prometheus") {
            $input.value = $PROMETHEUS_UID
        }
    }
}

# Создание payload для импорта
$importPayload = @{
    dashboard = $dashboardJson
    overwrite = $true
    inputs = @(
        @{
            name = "DS_PROMETHEUS"
            type = "datasource"
            pluginId = "prometheus"
            value = $PROMETHEUS_UID
        }
    )
} | ConvertTo-Json -Depth 100

Write-Host "   ✅ Дашборд подготовлен" -ForegroundColor Green

Write-Host ""
Write-Host "6. Импорт дашборда в Grafana..." -ForegroundColor Yellow
try {
    $result = Invoke-RestMethod -Uri "$GRAFANA_URL/api/dashboards/import" -Method Post -Headers $headers -Body $importPayload -TimeoutSec 30
    Write-Host "   ✅ Дашборд успешно импортирован!" -ForegroundColor Green
    Write-Host "   Dashboard ID: $($result.dashboardId)" -ForegroundColor White
    Write-Host "   Dashboard UID: $($result.uid)" -ForegroundColor White
    Write-Host "   Dashboard URL: $GRAFANA_URL$($result.url)" -ForegroundColor White
} catch {
    Write-Host "   ❌ Ошибка импорта дашборда: $_" -ForegroundColor Red
    
    # Попытка получить детали ошибки
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "   Детали: $responseBody" -ForegroundColor Yellow
    }
    exit 1
}

Write-Host ""
Write-Host "=== ИМПОРТ ЗАВЕРШЕН ===" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Дашборд 'Node Exporter Full' успешно импортирован!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Откройте дашборд в браузере:" -ForegroundColor Yellow
Write-Host "   $GRAFANA_URL$($result.url)" -ForegroundColor White
Write-Host ""
Write-Host "Или перейдите в Grafana:" -ForegroundColor Yellow
Write-Host "   1. Откройте $GRAFANA_URL" -ForegroundColor White
Write-Host "   2. Войдите с учетными данными (admin / ваш_пароль)" -ForegroundColor White
Write-Host "   3. В меню слева выберите 'Dashboards'" -ForegroundColor White
Write-Host "   4. Найдите 'Node Exporter Full'" -ForegroundColor White
Write-Host ""
Write-Host "💡 Дашборд содержит 40+ панелей с метриками:" -ForegroundColor Cyan
Write-Host "   - CPU Usage (по ядрам и общий)" -ForegroundColor White
Write-Host "   - Memory Usage (детальная разбивка)" -ForegroundColor White
Write-Host "   - Disk I/O (чтение/запись)" -ForegroundColor White
Write-Host "   - Network Traffic (входящий/исходящий)" -ForegroundColor White
Write-Host "   - System Load, Uptime, Processes" -ForegroundColor White
Write-Host ""

# Открыть дашборд в браузере
$openBrowser = Read-Host "Открыть дашборд в браузере? (y/n)"
if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
    Start-Process "$GRAFANA_URL$($result.url)"
    Write-Host "✅ Дашборд открыт в браузере" -ForegroundColor Green
}

Write-Host ""
Write-Host "Готово!" -ForegroundColor Green

