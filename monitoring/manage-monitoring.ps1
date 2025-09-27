#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Скрипт управления стеком мониторинга
.DESCRIPTION
    Этот скрипт позволяет запускать, останавливать и управлять различными профилями мониторинга
.PARAMETER Action
    Действие: start, stop, restart, status, logs
.PARAMETER Profile
    Профиль: all, basic, logging, tracing, postgres, redis, nginx
.EXAMPLE
    .\manage-monitoring.ps1 -Action start -Profile basic
    .\manage-monitoring.ps1 -Action start -Profile all
    .\manage-monitoring.ps1 -Action logs -Service prometheus
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "restart", "status", "logs", "cleanup")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("all", "basic", "logging", "tracing", "postgres", "redis", "nginx")]
    [string]$Profile = "basic",
    
    [Parameter(Mandatory=$false)]
    [string]$Service = ""
)

# Цвета для вывода
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = $Reset)
    Write-Host "$Color$Message$Reset"
}

function Test-DockerCompose {
    try {
        $null = docker-compose --version
        return $true
    }
    catch {
        Write-ColorOutput "❌ Docker Compose не найден. Установите Docker Desktop." $Red
        return $false
    }
}

function Test-Docker {
    try {
        $null = docker --version
        $dockerStatus = docker info 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "❌ Docker не запущен. Запустите Docker Desktop." $Red
            return $false
        }
        return $true
    }
    catch {
        Write-ColorOutput "❌ Docker не найден. Установите Docker Desktop." $Red
        return $false
    }
}

function Start-MonitoringStack {
    param([string]$Profile)
    
    Write-ColorOutput "🚀 Запуск стека мониторинга (профиль: $Profile)..." $Blue
    
    switch ($Profile) {
        "basic" {
            docker-compose up -d prometheus grafana alertmanager node-exporter cadvisor blackbox-exporter
        }
        "logging" {
            docker-compose --profile logging up -d
        }
        "tracing" {
            docker-compose --profile tracing up -d
        }
        "postgres" {
            docker-compose --profile postgres up -d postgres-exporter
        }
        "redis" {
            docker-compose --profile redis up -d redis-exporter
        }
        "nginx" {
            docker-compose --profile nginx up -d nginx-exporter
        }
        "all" {
            docker-compose --profile logging --profile tracing --profile postgres --profile redis --profile nginx up -d
        }
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Стек мониторинга успешно запущен!" $Green
        Show-ServiceUrls
    } else {
        Write-ColorOutput "❌ Ошибка при запуске стека мониторинга!" $Red
    }
}

function Stop-MonitoringStack {
    Write-ColorOutput "🛑 Остановка стека мониторинга..." $Yellow
    docker-compose down
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Стек мониторинга остановлен!" $Green
    } else {
        Write-ColorOutput "❌ Ошибка при остановке стека мониторинга!" $Red
    }
}

function Restart-MonitoringStack {
    param([string]$Profile)
    Write-ColorOutput "🔄 Перезапуск стека мониторинга..." $Yellow
    Stop-MonitoringStack
    Start-Sleep -Seconds 3
    Start-MonitoringStack -Profile $Profile
}

function Show-Status {
    Write-ColorOutput "📊 Статус контейнеров:" $Blue
    docker-compose ps
    
    Write-ColorOutput "`n🔍 Использование ресурсов:" $Blue
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
}

function Show-Logs {
    param([string]$Service)
    
    if ($Service) {
        Write-ColorOutput "📋 Логи сервиса $Service:" $Blue
        docker-compose logs -f --tail=100 $Service
    } else {
        Write-ColorOutput "📋 Логи всех сервисов:" $Blue
        docker-compose logs -f --tail=50
    }
}

function Show-ServiceUrls {
    Write-ColorOutput "`n🌐 Доступные сервисы:" $Green
    Write-ColorOutput "├── Grafana:          http://localhost:3000 (admin/admin123)" $Green
    Write-ColorOutput "├── Prometheus:       http://localhost:9090" $Green
    Write-ColorOutput "├── AlertManager:     http://localhost:9093" $Green
    Write-ColorOutput "├── Node Exporter:    http://localhost:9100" $Green
    Write-ColorOutput "├── cAdvisor:         http://localhost:8080" $Green
    Write-ColorOutput "├── Blackbox:         http://localhost:9115" $Green
    
    # Проверяем запущенные профили
    $runningContainers = docker-compose ps --services --filter "status=running"
    
    if ($runningContainers -contains "loki") {
        Write-ColorOutput "├── Loki:             http://localhost:3100" $Green
    }
    if ($runningContainers -contains "jaeger") {
        Write-ColorOutput "├── Jaeger UI:        http://localhost:16686" $Green
    }
    if ($runningContainers -contains "postgres-exporter") {
        Write-ColorOutput "├── PostgreSQL Exp:   http://localhost:9187" $Green
    }
    if ($runningContainers -contains "redis-exporter") {
        Write-ColorOutput "├── Redis Exporter:   http://localhost:9121" $Green
    }
    if ($runningContainers -contains "nginx-exporter") {
        Write-ColorOutput "└── Nginx Exporter:   http://localhost:9113" $Green
    }
}

function Cleanup-MonitoringStack {
    Write-ColorOutput "🧹 Очистка стека мониторинга..." $Yellow
    docker-compose down -v --remove-orphans
    docker system prune -f
    
    Write-ColorOutput "✅ Очистка завершена!" $Green
}

# Основная логика
if (-not (Test-Docker)) {
    exit 1
}

if (-not (Test-DockerCompose)) {
    exit 1
}

# Переходим в директорию со скриптом
Set-Location $PSScriptRoot

switch ($Action) {
    "start" {
        Start-MonitoringStack -Profile $Profile
    }
    "stop" {
        Stop-MonitoringStack
    }
    "restart" {
        Restart-MonitoringStack -Profile $Profile
    }
    "status" {
        Show-Status
    }
    "logs" {
        Show-Logs -Service $Service
    }
    "cleanup" {
        Cleanup-MonitoringStack
    }
}

Write-ColorOutput "`n💡 Подсказка: Используйте 'Get-Help .\manage-monitoring.ps1' для получения справки" $Blue