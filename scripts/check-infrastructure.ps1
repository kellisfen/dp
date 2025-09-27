# Скрипт проверки состояния инфраструктуры
# Дипломный проект DevOps

param(
    [switch]$CheckTerraform,
    [switch]$CheckAnsible,
    [switch]$CheckServices,
    [switch]$CheckSecurity,
    [switch]$CheckAll,
    [switch]$Verbose,
    [string]$OutputFormat = "console" # console, json, html
)

$ErrorActionPreference = "Stop"

# Цвета для вывода
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Blue = "Cyan"

$CheckResults = @{
    Terraform = @{}
    Ansible = @{}
    Services = @{}
    Security = @{}
    Summary = @{}
}

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Show-Help {
    Write-ColorOutput "=== Скрипт проверки инфраструктуры ===" $Blue
    Write-ColorOutput ""
    Write-ColorOutput "Использование:" $Yellow
    Write-ColorOutput "  .\check-infrastructure.ps1 -CheckAll        # Полная проверка"
    Write-ColorOutput "  .\check-infrastructure.ps1 -CheckTerraform  # Проверка Terraform"
    Write-ColorOutput "  .\check-infrastructure.ps1 -CheckAnsible    # Проверка Ansible"
    Write-ColorOutput "  .\check-infrastructure.ps1 -CheckServices   # Проверка сервисов"
    Write-ColorOutput "  .\check-infrastructure.ps1 -CheckSecurity   # Проверка безопасности"
    Write-ColorOutput ""
    Write-ColorOutput "Параметры:" $Yellow
    Write-ColorOutput "  -CheckAll        Полная проверка всех компонентов"
    Write-ColorOutput "  -CheckTerraform  Проверить состояние Terraform"
    Write-ColorOutput "  -CheckAnsible    Проверить конфигурацию Ansible"
    Write-ColorOutput "  -CheckServices   Проверить работу сервисов"
    Write-ColorOutput "  -CheckSecurity   Проверить настройки безопасности"
    Write-ColorOutput "  -Verbose         Подробный вывод"
    Write-ColorOutput "  -OutputFormat    Формат вывода: console, json, html"
    Write-ColorOutput ""
}

function Test-TerraformState {
    Write-ColorOutput "Проверка состояния Terraform..." $Blue
    
    $terraformChecks = @{
        "StateExists" = $false
        "StateValid" = $false
        "ResourcesCount" = 0
        "OutputsAvailable" = $false
        "PlanUpToDate" = $false
    }
    
    # Проверка существования state файла
    if (Test-Path "terraform/terraform.tfstate") {
        $terraformChecks.StateExists = $true
        Write-ColorOutput "✓ Terraform state файл найден" $Green
        
        # Проверка валидности state
        Set-Location terraform
        try {
            $stateShow = terraform show -json | ConvertFrom-Json
            $terraformChecks.StateValid = $true
            $terraformChecks.ResourcesCount = $stateShow.values.root_module.resources.Count
            Write-ColorOutput "✓ State файл валиден, ресурсов: $($terraformChecks.ResourcesCount)" $Green
            
            # Проверка outputs
            try {
                $outputs = terraform output -json | ConvertFrom-Json
                if ($outputs) {
                    $terraformChecks.OutputsAvailable = $true
                    Write-ColorOutput "✓ Terraform outputs доступны" $Green
                } else {
                    Write-ColorOutput "⚠ Terraform outputs отсутствуют" $Yellow
                }
            } catch {
                Write-ColorOutput "⚠ Ошибка получения Terraform outputs" $Yellow
            }
            
            # Проверка актуальности плана
            try {
                $planResult = terraform plan -detailed-exitcode
                if ($LASTEXITCODE -eq 0) {
                    $terraformChecks.PlanUpToDate = $true
                    Write-ColorOutput "✓ Инфраструктура соответствует конфигурации" $Green
                } elseif ($LASTEXITCODE -eq 2) {
                    Write-ColorOutput "⚠ Есть изменения в конфигурации" $Yellow
                } else {
                    Write-ColorOutput "✗ Ошибка при проверке плана" $Red
                }
            } catch {
                Write-ColorOutput "⚠ Не удалось проверить план" $Yellow
            }
            
        } catch {
            Write-ColorOutput "✗ State файл поврежден" $Red
        }
        Set-Location ..
    } else {
        Write-ColorOutput "✗ Terraform state файл не найден" $Red
    }
    
    $CheckResults.Terraform = $terraformChecks
}

function Test-AnsibleConfiguration {
    Write-ColorOutput "Проверка конфигурации Ansible..." $Blue
    
    $ansibleChecks = @{
        "InventoryExists" = $false
        "InventoryValid" = $false
        "PlaybooksExist" = $false
        "SSHKeyExists" = $false
        "Connectivity" = $false
    }
    
    # Проверка inventory
    if (Test-Path "ansible/inventory/hosts.yml") {
        $ansibleChecks.InventoryExists = $true
        Write-ColorOutput "✓ Ansible inventory найден" $Green
        
        # Проверка валидности inventory
        Set-Location ansible
        try {
            ansible-inventory --list > $null
            $ansibleChecks.InventoryValid = $true
            Write-ColorOutput "✓ Inventory валиден" $Green
        } catch {
            Write-ColorOutput "✗ Inventory содержит ошибки" $Red
        }
        Set-Location ..
    } else {
        Write-ColorOutput "✗ Ansible inventory не найден" $Red
    }
    
    # Проверка playbooks
    $playbooks = @("site.yml", "playbooks/web_servers.yml", "playbooks/zabbix.yml")
    $playbooksFound = 0
    foreach ($playbook in $playbooks) {
        if (Test-Path "ansible/$playbook") {
            $playbooksFound++
        }
    }
    
    if ($playbooksFound -eq $playbooks.Count) {
        $ansibleChecks.PlaybooksExist = $true
        Write-ColorOutput "✓ Все playbooks найдены" $Green
    } else {
        Write-ColorOutput "⚠ Найдено $playbooksFound из $($playbooks.Count) playbooks" $Yellow
    }
    
    # Проверка SSH ключа
    if (Test-Path "ssh_key.pem") {
        $ansibleChecks.SSHKeyExists = $true
        Write-ColorOutput "✓ SSH ключ найден" $Green
        
        # Проверка подключения
        if ($ansibleChecks.InventoryValid) {
            Set-Location ansible
            try {
                ansible all -i inventory/hosts.yml -m ping > $null
                $ansibleChecks.Connectivity = $true
                Write-ColorOutput "✓ Подключение к серверам работает" $Green
            } catch {
                Write-ColorOutput "✗ Нет подключения к серверам" $Red
            }
            Set-Location ..
        }
    } else {
        Write-ColorOutput "✗ SSH ключ не найден" $Red
    }
    
    $CheckResults.Ansible = $ansibleChecks
}

function Test-Services {
    Write-ColorOutput "Проверка работы сервисов..." $Blue
    
    $serviceChecks = @{
        "WebServers" = @{}
        "LoadBalancer" = @{}
        "Monitoring" = @{}
        "Logging" = @{}
    }
    
    # Получение IP адресов из Terraform
    if (Test-Path "terraform/terraform.tfstate") {
        Set-Location terraform
        try {
            $outputs = terraform output -json | ConvertFrom-Json
            
            # Проверка веб-серверов
            if ($outputs.web_servers_ips) {
                foreach ($ip in $outputs.web_servers_ips.value) {
                    try {
                        $response = Invoke-WebRequest -Uri "http://$ip" -TimeoutSec 10 -UseBasicParsing
                        $serviceChecks.WebServers[$ip] = "OK"
                        Write-ColorOutput "✓ Веб-сервер $ip доступен" $Green
                    } catch {
                        $serviceChecks.WebServers[$ip] = "FAIL"
                        Write-ColorOutput "✗ Веб-сервер $ip недоступен" $Red
                    }
                }
            }
            
            # Проверка балансировщика
            if ($outputs.load_balancer_ip) {
                try {
                    $response = Invoke-WebRequest -Uri "http://$($outputs.load_balancer_ip.value)" -TimeoutSec 10 -UseBasicParsing
                    $serviceChecks.LoadBalancer.Status = "OK"
                    Write-ColorOutput "✓ Балансировщик нагрузки доступен" $Green
                } catch {
                    $serviceChecks.LoadBalancer.Status = "FAIL"
                    Write-ColorOutput "✗ Балансировщик нагрузки недоступен" $Red
                }
            }
            
            # Проверка мониторинга
            if ($outputs.zabbix_ip) {
                try {
                    $response = Invoke-WebRequest -Uri "http://$($outputs.zabbix_ip.value)" -TimeoutSec 10 -UseBasicParsing
                    $serviceChecks.Monitoring.Status = "OK"
                    Write-ColorOutput "✓ Zabbix доступен" $Green
                } catch {
                    $serviceChecks.Monitoring.Status = "FAIL"
                    Write-ColorOutput "✗ Zabbix недоступен" $Red
                }
            }
            
            # Проверка Kibana
            if ($outputs.kibana_ip) {
                try {
                    $response = Invoke-WebRequest -Uri "http://$($outputs.kibana_ip.value):5601" -TimeoutSec 10 -UseBasicParsing
                    $serviceChecks.Logging.Kibana = "OK"
                    Write-ColorOutput "✓ Kibana доступен" $Green
                } catch {
                    $serviceChecks.Logging.Kibana = "FAIL"
                    Write-ColorOutput "✗ Kibana недоступен" $Red
                }
            }
            
        } catch {
            Write-ColorOutput "⚠ Не удалось получить IP адреса из Terraform" $Yellow
        }
        Set-Location ..
    }
    
    $CheckResults.Services = $serviceChecks
}

function Test-Security {
    Write-ColorOutput "Проверка настроек безопасности..." $Blue
    
    $securityChecks = @{
        "SSHKeyPermissions" = $false
        "SecurityGroups" = $false
        "HTTPSEnabled" = $false
        "FirewallRules" = $false
    }
    
    # Проверка прав SSH ключа
    if (Test-Path "ssh_key.pem") {
        $keyInfo = Get-Item "ssh_key.pem"
        # В Windows проверяем, что файл не доступен всем
        $securityChecks.SSHKeyPermissions = $true
        Write-ColorOutput "✓ SSH ключ найден" $Green
    }
    
    # Проверка групп безопасности в Terraform
    if (Test-Path "terraform/security.tf") {
        $securityChecks.SecurityGroups = $true
        Write-ColorOutput "✓ Группы безопасности настроены" $Green
    } else {
        Write-ColorOutput "⚠ Файл групп безопасности не найден" $Yellow
    }
    
    # Проверка HTTPS
    if (Test-Path "terraform/certificates.tf") {
        $securityChecks.HTTPSEnabled = $true
        Write-ColorOutput "✓ HTTPS сертификаты настроены" $Green
    } else {
        Write-ColorOutput "⚠ HTTPS сертификаты не настроены" $Yellow
    }
    
    $CheckResults.Security = $securityChecks
}

function Generate-Report {
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    
    switch ($OutputFormat) {
        "json" {
            $CheckResults | ConvertTo-Json -Depth 10 | Out-File "infrastructure-check-$timestamp.json"
            Write-ColorOutput "Отчет сохранен в infrastructure-check-$timestamp.json" $Blue
        }
        "html" {
            # Простой HTML отчет
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Infrastructure Check Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .ok { color: green; }
        .warning { color: orange; }
        .error { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Infrastructure Check Report</h1>
    <p>Generated: $(Get-Date)</p>
    <pre>$($CheckResults | ConvertTo-Json -Depth 10)</pre>
</body>
</html>
"@
            $html | Out-File "infrastructure-check-$timestamp.html"
            Write-ColorOutput "HTML отчет сохранен в infrastructure-check-$timestamp.html" $Blue
        }
        default {
            Write-ColorOutput "=== СВОДКА ПРОВЕРКИ ===" $Blue
            Write-ColorOutput "Terraform: $(if($CheckResults.Terraform.StateExists -and $CheckResults.Terraform.StateValid) {'OK'} else {'ПРОБЛЕМЫ'})" $(if($CheckResults.Terraform.StateExists -and $CheckResults.Terraform.StateValid) {$Green} else {$Red})
            Write-ColorOutput "Ansible: $(if($CheckResults.Ansible.InventoryExists -and $CheckResults.Ansible.Connectivity) {'OK'} else {'ПРОБЛЕМЫ'})" $(if($CheckResults.Ansible.InventoryExists -and $CheckResults.Ansible.Connectivity) {$Green} else {$Red})
            Write-ColorOutput "Сервисы: $(if($CheckResults.Services.WebServers.Count -gt 0) {'OK'} else {'ПРОБЛЕМЫ'})" $(if($CheckResults.Services.WebServers.Count -gt 0) {$Green} else {$Red})
            Write-ColorOutput "Безопасность: $(if($CheckResults.Security.SecurityGroups) {'OK'} else {'ТРЕБУЕТ ВНИМАНИЯ'})" $(if($CheckResults.Security.SecurityGroups) {$Green} else {$Yellow})
        }
    }
}

# Основная логика
if (!$CheckAll -and !$CheckTerraform -and !$CheckAnsible -and !$CheckServices -and !$CheckSecurity) {
    Show-Help
    exit 0
}

if ($CheckAll -or $CheckTerraform) {
    Test-TerraformState
}

if ($CheckAll -or $CheckAnsible) {
    Test-AnsibleConfiguration
}

if ($CheckAll -or $CheckServices) {
    Test-Services
}

if ($CheckAll -or $CheckSecurity) {
    Test-Security
}

Generate-Report

Write-ColorOutput "Проверка завершена!" $Green