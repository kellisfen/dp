# Скрипт автоматического развертывания инфраструктуры
# Дипломный проект DevOps

param(
    [switch]$Init,
    [switch]$Plan,
    [switch]$Apply,
    [switch]$Destroy,
    [switch]$EnableHttps,
    [string]$VarFile = "terraform.tfvars",
    [switch]$AutoApprove,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Цвета для вывода
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Blue = "Cyan"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Show-Help {
    Write-ColorOutput "=== Скрипт развертывания дипломного проекта ===" $Blue
    Write-ColorOutput ""
    Write-ColorOutput "Использование:" $Yellow
    Write-ColorOutput "  .\deploy.ps1 -Init                    # Инициализация Terraform"
    Write-ColorOutput "  .\deploy.ps1 -Plan                    # Планирование изменений"
    Write-ColorOutput "  .\deploy.ps1 -Apply                   # Применение изменений"
    Write-ColorOutput "  .\deploy.ps1 -Apply -EnableHttps      # Применение с HTTPS"
    Write-ColorOutput "  .\deploy.ps1 -Destroy                 # Удаление инфраструктуры"
    Write-ColorOutput ""
    Write-ColorOutput "Параметры:" $Yellow
    Write-ColorOutput "  -Init          Инициализация Terraform"
    Write-ColorOutput "  -Plan          Показать план изменений"
    Write-ColorOutput "  -Apply         Применить изменения"
    Write-ColorOutput "  -Destroy       Удалить инфраструктуру"
    Write-ColorOutput "  -EnableHttps   Включить HTTPS (требует настройки DNS)"
    Write-ColorOutput "  -VarFile       Файл переменных (по умолчанию: terraform.tfvars)"
    Write-ColorOutput "  -AutoApprove   Автоматическое подтверждение"
    Write-ColorOutput "  -Verbose       Подробный вывод"
    Write-ColorOutput ""
}

function Test-Prerequisites {
    Write-ColorOutput "Проверка предварительных требований..." $Blue
    
    # Проверка Terraform
    try {
        $terraformVersion = terraform version
        Write-ColorOutput "✓ Terraform установлен: $($terraformVersion[0])" $Green
    } catch {
        Write-ColorOutput "✗ Terraform не найден. Установите Terraform." $Red
        exit 1
    }
    
    # Проверка Ansible
    try {
        $ansibleVersion = ansible --version | Select-Object -First 1
        Write-ColorOutput "✓ Ansible установлен: $ansibleVersion" $Green
    } catch {
        Write-ColorOutput "⚠ Ansible не найден. Установите Ansible для настройки серверов." $Yellow
    }
    
    # Проверка файлов конфигурации
    if (!(Test-Path "terraform\main.tf")) {
        Write-ColorOutput "✗ Файл terraform\main.tf не найден" $Red
        exit 1
    }
    
    if (!(Test-Path $VarFile)) {
        Write-ColorOutput "⚠ Файл переменных $VarFile не найден. Создайте его на основе terraform.tfvars.example" $Yellow
    }
    
    Write-ColorOutput "✓ Предварительные проверки пройдены" $Green
}

function Initialize-Terraform {
    Write-ColorOutput "Инициализация Terraform..." $Blue
    Set-Location terraform
    
    try {
        terraform init
        Write-ColorOutput "✓ Terraform инициализирован успешно" $Green
    } catch {
        Write-ColorOutput "✗ Ошибка инициализации Terraform" $Red
        exit 1
    } finally {
        Set-Location ..
    }
}

function Plan-Infrastructure {
    Write-ColorOutput "Планирование изменений инфраструктуры..." $Blue
    Set-Location terraform
    
    $planArgs = @()
    if (Test-Path "..\$VarFile") {
        $planArgs += "-var-file=..\$VarFile"
    }
    
    if ($EnableHttps) {
        $planArgs += "-var=enable_https=true"
    }
    
    if ($Verbose) {
        $planArgs += "-detailed-exitcode"
    }
    
    try {
        terraform plan @planArgs
        Write-ColorOutput "✓ План создан успешно" $Green
    } catch {
        Write-ColorOutput "✗ Ошибка создания плана" $Red
        exit 1
    } finally {
        Set-Location ..
    }
}

function Apply-Infrastructure {
    Write-ColorOutput "Применение изменений инфраструктуры..." $Blue
    Set-Location terraform
    
    $applyArgs = @()
    if (Test-Path "..\$VarFile") {
        $applyArgs += "-var-file=..\$VarFile"
    }
    
    if ($EnableHttps) {
        $applyArgs += "-var=enable_https=true"
    }
    
    if ($AutoApprove) {
        $applyArgs += "-auto-approve"
    }
    
    try {
        terraform apply @applyArgs
        Write-ColorOutput "✓ Инфраструктура развернута успешно" $Green
        
        # Генерация inventory для Ansible
        Write-ColorOutput "Генерация Ansible inventory..." $Blue
        terraform output -json > ..\ansible\inventory\terraform_outputs.json
        
        Write-ColorOutput "✓ Готово! Теперь можно запустить настройку серверов через Ansible" $Green
        Write-ColorOutput "Команда: ansible-playbook -i inventory/hosts.yml site.yml" $Yellow
        
    } catch {
        Write-ColorOutput "✗ Ошибка применения изменений" $Red
        exit 1
    } finally {
        Set-Location ..
    }
}

function Destroy-Infrastructure {
    Write-ColorOutput "Удаление инфраструктуры..." $Red
    Write-ColorOutput "ВНИМАНИЕ: Это действие необратимо!" $Red
    
    if (!$AutoApprove) {
        $confirmation = Read-Host "Вы уверены, что хотите удалить всю инфраструктуру? (yes/no)"
        if ($confirmation -ne "yes") {
            Write-ColorOutput "Операция отменена" $Yellow
            return
        }
    }
    
    Set-Location terraform
    
    $destroyArgs = @()
    if (Test-Path "..\$VarFile") {
        $destroyArgs += "-var-file=..\$VarFile"
    }
    
    if ($AutoApprove) {
        $destroyArgs += "-auto-approve"
    }
    
    try {
        terraform destroy @destroyArgs
        Write-ColorOutput "✓ Инфраструктура удалена" $Green
    } catch {
        Write-ColorOutput "✗ Ошибка удаления инфраструктуры" $Red
        exit 1
    } finally {
        Set-Location ..
    }
}

# Основная логика
if (!$Init -and !$Plan -and !$Apply -and !$Destroy) {
    Show-Help
    exit 0
}

Test-Prerequisites

if ($Init) {
    Initialize-Terraform
}

if ($Plan) {
    Plan-Infrastructure
}

if ($Apply) {
    Apply-Infrastructure
}

if ($Destroy) {
    Destroy-Infrastructure
}

Write-ColorOutput "Скрипт завершен успешно!" $Green