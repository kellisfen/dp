# Исправленный скрипт импорта дашборда с правильной настройкой Data Source

Write-Host "=== ИМПОРТ ДАШБОРДА NODE EXPORTER FULL (ИСПРАВЛЕННЫЙ) ===" -ForegroundColor Cyan
Write-Host ""

$GRAFANA_URL = "http://62.84.112.42:3000"
$GRAFANA_USER = "admin"
$GRAFANA_PASSWORD = "DevOps2025!"
$DASHBOARD_ID = 1860

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${GRAFANA_USER}:${GRAFANA_PASSWORD}"))
$headers = @{
    "Authorization" = "Basic $base64AuthInfo"
    "Content-Type" = "application/json"
}

Write-Host "1. Получение Data Source Prometheus..." -ForegroundColor Yellow
try {
    $datasources = Invoke-RestMethod -Uri "$GRAFANA_URL/api/datasources" -Method Get -Headers $headers
    $prometheus = $datasources | Where-Object { $_.name -eq "Prometheus" -and $_.type -eq "prometheus" } | Select-Object -First 1
    
    if ($prometheus) {
        Write-Host "   ✅ Prometheus найден (UID: $($prometheus.uid))" -ForegroundColor Green
        $PROMETHEUS_UID = $prometheus.uid
    } else {
        Write-Host "   ❌ Prometheus Data Source не найден" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ❌ Ошибка: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "2. Скачивание дашборда..." -ForegroundColor Yellow
try {
    $dashboardJson = Invoke-RestMethod -Uri "https://grafana.com/api/dashboards/$DASHBOARD_ID/revisions/latest/download" -Method Get -TimeoutSec 30
    Write-Host "   ✅ Дашборд скачан" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Ошибка: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "3. Обработка дашборда..." -ForegroundColor Yellow

# Функция для рекурсивной замены datasource в объекте
function Replace-DataSource {
    param($obj, $uid)
    
    if ($obj -is [System.Collections.IDictionary]) {
        foreach ($key in @($obj.Keys)) {
            if ($key -eq "datasource") {
                if ($obj[$key] -is [string]) {
                    $obj[$key] = @{ type = "prometheus"; uid = $uid }
                } elseif ($obj[$key] -is [System.Collections.IDictionary]) {
                    $obj[$key]["uid"] = $uid
                    $obj[$key]["type"] = "prometheus"
                }
            } else {
                Replace-DataSource $obj[$key] $uid
            }
        }
    } elseif ($obj -is [System.Collections.IEnumerable] -and $obj -isnot [string]) {
        foreach ($item in $obj) {
            Replace-DataSource $item $uid
        }
    }
}

# Замена всех datasource на наш Prometheus
Replace-DataSource $dashboardJson $PROMETHEUS_UID

# Удаление __inputs и __requires
$dashboardJson.PSObject.Properties.Remove('__inputs')
$dashboardJson.PSObject.Properties.Remove('__requires')

# Удаление id для создания нового дашборда
$dashboardJson.PSObject.Properties.Remove('id')

# Установка uid в null для автогенерации
$dashboardJson | Add-Member -NotePropertyName "uid" -NotePropertyValue $null -Force

Write-Host "   ✅ Дашборд обработан" -ForegroundColor Green

Write-Host ""
Write-Host "4. Импорт дашборда..." -ForegroundColor Yellow

$importPayload = @{
    dashboard = $dashboardJson
    overwrite = $true
    folderId = 0
} | ConvertTo-Json -Depth 100 -Compress

try {
    $result = Invoke-RestMethod -Uri "$GRAFANA_URL/api/dashboards/db" -Method Post -Headers $headers -Body $importPayload -TimeoutSec 30
    Write-Host "   ✅ Дашборд импортирован!" -ForegroundColor Green
    Write-Host "   Dashboard UID: $($result.uid)" -ForegroundColor White
    Write-Host "   Dashboard URL: $GRAFANA_URL$($result.url)" -ForegroundColor White
    
    $dashboardUrl = "$GRAFANA_URL$($result.url)"
} catch {
    Write-Host "   ❌ Ошибка импорта: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "   Детали: $responseBody" -ForegroundColor Yellow
    }
    exit 1
}

Write-Host ""
Write-Host "5. Проверка дашборда..." -ForegroundColor Yellow
try {
    $dashboard = Invoke-RestMethod -Uri "$GRAFANA_URL/api/dashboards/uid/$($result.uid)" -Method Get -Headers $headers
    $panelsCount = $dashboard.dashboard.panels.Count
    Write-Host "   ✅ Дашборд содержит $panelsCount панелей" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Не удалось проверить дашборд" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== ИМПОРТ ЗАВЕРШЕН УСПЕШНО ===" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Дашборд 'Node Exporter Full' готов к использованию!" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌐 URL дашборда:" -ForegroundColor Yellow
Write-Host "   $dashboardUrl" -ForegroundColor White
Write-Host ""
Write-Host "💡 Что дальше:" -ForegroundColor Cyan
Write-Host "   1. Откройте дашборд в браузере" -ForegroundColor White
Write-Host "   2. В верхней части выберите сервер из выпадающего списка 'Host'" -ForegroundColor White
Write-Host "   3. Изучите метрики: CPU, Memory, Disk, Network" -ForegroundColor White
Write-Host "   4. Настройте временной диапазон (Last 5 minutes, Last 1 hour, etc.)" -ForegroundColor White
Write-Host "   5. Включите автообновление (5s, 10s, 30s, 1m)" -ForegroundColor White
Write-Host ""

$openBrowser = Read-Host "Открыть дашборд в браузере? (y/n)"
if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
    Start-Process $dashboardUrl
    Write-Host "✅ Дашборд открыт в браузере" -ForegroundColor Green
}

Write-Host ""
Write-Host "Готово! 🎉" -ForegroundColor Green

