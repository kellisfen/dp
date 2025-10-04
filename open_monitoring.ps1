# PowerShell скрипт для открытия веб-интерфейсов мониторинга
# Использование: .\open_monitoring.ps1

Write-Host "=== Открытие веб-интерфейсов мониторинга ===" -ForegroundColor Cyan
Write-Host ""

# Получение IP адресов из Terraform
Write-Host "Получение IP адресов..." -ForegroundColor Yellow
cd terraform

try {
    $kibana_ip = terraform output -raw kibana_external_ip 2>&1
    $lb_ip = terraform output -raw load_balancer_external_ip 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Ошибка получения IP адресов из Terraform" -ForegroundColor Red
        Write-Host "Убедитесь, что инфраструктура развернута: terraform apply" -ForegroundColor Yellow
        cd ..
        exit 1
    }
    
    Write-Host "✅ IP адреса получены" -ForegroundColor Green
    Write-Host "   Kibana Server: $kibana_ip" -ForegroundColor White
    Write-Host "   Load Balancer: $lb_ip" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "❌ Ошибка: $_" -ForegroundColor Red
    cd ..
    exit 1
}

cd ..

# Формирование URL
$prometheus_url = "http://${kibana_ip}:9090"
$grafana_url = "http://${kibana_ip}:3000"
$kibana_url = "http://${kibana_ip}:5601"
$lb_url = "http://${lb_ip}"

# Проверка доступности сервисов
Write-Host "Проверка доступности сервисов..." -ForegroundColor Yellow

function Test-ServiceAvailability {
    param (
        [string]$url,
        [string]$name
    )
    
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 302) {
            Write-Host "   ✅ $name доступен" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "   ❌ $name недоступен" -ForegroundColor Red
        return $false
    }
    return $false
}

$prometheus_ok = Test-ServiceAvailability -url $prometheus_url -name "Prometheus"
$grafana_ok = Test-ServiceAvailability -url $grafana_url -name "Grafana"
$kibana_ok = Test-ServiceAvailability -url $kibana_url -name "Kibana"
$lb_ok = Test-ServiceAvailability -url $lb_url -name "Load Balancer"

Write-Host ""

# Меню выбора
Write-Host "=== Выберите сервис для открытия ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Prometheus (метрики и графики)" -ForegroundColor White
Write-Host "   URL: $prometheus_url" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Grafana (дашборды и визуализация)" -ForegroundColor White
Write-Host "   URL: $grafana_url" -ForegroundColor Gray
Write-Host "   Логин: admin / your_password" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Kibana (анализ логов)" -ForegroundColor White
Write-Host "   URL: $kibana_url" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Load Balancer (веб-серверы)" -ForegroundColor White
Write-Host "   URL: $lb_url" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Открыть все сервисы" -ForegroundColor Yellow
Write-Host ""
Write-Host "0. Выход" -ForegroundColor Red
Write-Host ""

$choice = Read-Host "Введите номер"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "Открытие Prometheus..." -ForegroundColor Green
        Start-Process $prometheus_url
        Write-Host ""
        Write-Host "📊 Полезные разделы Prometheus:" -ForegroundColor Cyan
        Write-Host "   - Graph: $prometheus_url/graph" -ForegroundColor White
        Write-Host "   - Targets: $prometheus_url/targets" -ForegroundColor White
        Write-Host "   - Alerts: $prometheus_url/alerts" -ForegroundColor White
        Write-Host ""
        Write-Host "📚 Примеры PromQL запросов: PROMQL_QUERIES.md" -ForegroundColor Yellow
    }
    "2" {
        Write-Host ""
        Write-Host "Открытие Grafana..." -ForegroundColor Green
        Start-Process $grafana_url
        Write-Host ""
        Write-Host "📊 Учетные данные Grafana:" -ForegroundColor Cyan
        Write-Host "   Логин: admin" -ForegroundColor White
        Write-Host "   Пароль: (установленный при настройке)" -ForegroundColor White
        Write-Host ""
        Write-Host "📚 Руководство по дашбордам: GRAFANA_DASHBOARDS_GUIDE.md" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "💡 Рекомендуемые действия:" -ForegroundColor Cyan
        Write-Host "   1. Войдите с учетными данными" -ForegroundColor White
        Write-Host "   2. Откройте дашборд 'Node Exporter Full'" -ForegroundColor White
        Write-Host "   3. Выберите сервер из выпадающего списка" -ForegroundColor White
        Write-Host "   4. Изучите метрики CPU, Memory, Disk, Network" -ForegroundColor White
    }
    "3" {
        Write-Host ""
        Write-Host "Открытие Kibana..." -ForegroundColor Green
        Start-Process $kibana_url
        Write-Host ""
        Write-Host "📊 Kibana открыта" -ForegroundColor Cyan
        Write-Host "   Аутентификация отключена для разработки" -ForegroundColor White
    }
    "4" {
        Write-Host ""
        Write-Host "Открытие Load Balancer..." -ForegroundColor Green
        Start-Process $lb_url
        Write-Host ""
        Write-Host "🌐 Load Balancer открыт" -ForegroundColor Cyan
        Write-Host "   Обновите страницу несколько раз для проверки балансировки" -ForegroundColor White
        Write-Host "   Вы увидите чередование Web Server 1 и Web Server 2" -ForegroundColor White
    }
    "5" {
        Write-Host ""
        Write-Host "Открытие всех сервисов..." -ForegroundColor Green
        
        if ($prometheus_ok) {
            Start-Process $prometheus_url
            Start-Sleep -Milliseconds 500
        }
        
        if ($grafana_ok) {
            Start-Process $grafana_url
            Start-Sleep -Milliseconds 500
        }
        
        if ($kibana_ok) {
            Start-Process $kibana_url
            Start-Sleep -Milliseconds 500
        }
        
        if ($lb_ok) {
            Start-Process $lb_url
        }
        
        Write-Host ""
        Write-Host "✅ Все доступные сервисы открыты в браузере" -ForegroundColor Green
        Write-Host ""
        Write-Host "📚 Документация:" -ForegroundColor Cyan
        Write-Host "   - ACCESS_GUIDE.md - Руководство по доступу" -ForegroundColor White
        Write-Host "   - GRAFANA_DASHBOARDS_GUIDE.md - Настройка дашбордов" -ForegroundColor White
        Write-Host "   - PROMQL_QUERIES.md - Примеры запросов" -ForegroundColor White
    }
    "0" {
        Write-Host ""
        Write-Host "Выход..." -ForegroundColor Yellow
        exit 0
    }
    default {
        Write-Host ""
        Write-Host "❌ Неверный выбор" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Готово!" -ForegroundColor Green
Write-Host ""

# Дополнительная информация
Write-Host "=== Дополнительная информация ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Проверка метрик:" -ForegroundColor Yellow
Write-Host "   bash check_prometheus_metrics.sh" -ForegroundColor White
Write-Host ""
Write-Host "📚 Документация:" -ForegroundColor Yellow
Write-Host "   - ACCESS_GUIDE.md" -ForegroundColor White
Write-Host "   - GRAFANA_DASHBOARDS_GUIDE.md" -ForegroundColor White
Write-Host "   - PROMQL_QUERIES.md" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Troubleshooting:" -ForegroundColor Yellow
Write-Host "   Если сервис недоступен, проверьте:" -ForegroundColor White
Write-Host "   1. Статус Docker контейнеров: ssh kibana 'sudo docker ps'" -ForegroundColor Gray
Write-Host "   2. Статус Prometheus: ssh kibana 'sudo systemctl status prometheus'" -ForegroundColor Gray
Write-Host "   3. Логи: ssh kibana 'sudo docker logs grafana'" -ForegroundColor Gray
Write-Host ""

