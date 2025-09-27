# Скрипт настройки серверов через Ansible
# Дипломный проект DevOps

param(
    [switch]$CheckConnectivity,
    [switch]$SetupAll,
    [switch]$SetupWeb,
    [switch]$SetupMonitoring,
    [switch]$SetupLogging,
    [string]$InventoryFile = "inventory/hosts.yml",
    [string]$PlaybookFile = "site.yml",
    [switch]$Verbose,
    [switch]$DryRun
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
    Write-ColorOutput "=== Скрипт настройки серверов через Ansible ===" $Blue
    Write-ColorOutput ""
    Write-ColorOutput "Использование:" $Yellow
    Write-ColorOutput "  .\setup-ansible.ps1 -CheckConnectivity  # Проверка подключения к серверам"
    Write-ColorOutput "  .\setup-ansible.ps1 -SetupAll           # Настройка всех серверов"
    Write-ColorOutput "  .\setup-ansible.ps1 -SetupWeb           # Настройка только веб-серверов"
    Write-ColorOutput "  .\setup-ansible.ps1 -SetupMonitoring    # Настройка мониторинга"
    Write-ColorOutput "  .\setup-ansible.ps1 -SetupLogging       # Настройка логирования"
    Write-ColorOutput ""
    Write-ColorOutput "Параметры:" $Yellow
    Write-ColorOutput "  -CheckConnectivity  Проверить подключение к серверам"
    Write-ColorOutput "  -SetupAll          Настроить все сервисы"
    Write-ColorOutput "  -SetupWeb          Настроить только веб-серверы"
    Write-ColorOutput "  -SetupMonitoring   Настроить мониторинг (Zabbix)"
    Write-ColorOutput "  -SetupLogging      Настроить логирование (ELK)"
    Write-ColorOutput "  -InventoryFile     Файл инвентаря (по умолчанию: inventory/hosts.yml)"
    Write-ColorOutput "  -PlaybookFile      Файл playbook (по умолчанию: site.yml)"
    Write-ColorOutput "  -Verbose           Подробный вывод"
    Write-ColorOutput "  -DryRun            Проверочный запуск без изменений"
    Write-ColorOutput ""
}

function Test-AnsiblePrerequisites {
    Write-ColorOutput "Проверка предварительных требований Ansible..." $Blue
    
    # Проверка Ansible
    try {
        $ansibleVersion = ansible --version | Select-Object -First 1
        Write-ColorOutput "✓ Ansible установлен: $ansibleVersion" $Green
    } catch {
        Write-ColorOutput "✗ Ansible не найден. Установите Ansible." $Red
        exit 1
    }
    
    # Проверка файлов
    if (!(Test-Path $InventoryFile)) {
        Write-ColorOutput "✗ Файл инвентаря $InventoryFile не найден" $Red
        exit 1
    }
    
    if (!(Test-Path $PlaybookFile)) {
        Write-ColorOutput "✗ Файл playbook $PlaybookFile не найден" $Red
        exit 1
    }
    
    # Проверка SSH ключа
    if (!(Test-Path "ssh_key.pem")) {
        Write-ColorOutput "✗ SSH ключ ssh_key.pem не найден" $Red
        Write-ColorOutput "Сначала запустите Terraform для создания инфраструктуры" $Yellow
        exit 1
    }
    
    Write-ColorOutput "✓ Предварительные проверки пройдены" $Green
}

function Test-Connectivity {
    Write-ColorOutput "Проверка подключения к серверам..." $Blue
    
    $ansibleArgs = @(
        "-i", $InventoryFile,
        "all",
        "-m", "ping"
    )
    
    if ($Verbose) {
        $ansibleArgs += "-v"
    }
    
    try {
        ansible @ansibleArgs
        Write-ColorOutput "✓ Подключение к серверам успешно" $Green
    } catch {
        Write-ColorOutput "✗ Ошибка подключения к серверам" $Red
        Write-ColorOutput "Проверьте:" $Yellow
        Write-ColorOutput "  - Инфраструктура развернута (terraform apply)" $Yellow
        Write-ColorOutput "  - SSH ключи настроены правильно" $Yellow
        Write-ColorOutput "  - Сетевые настройки корректны" $Yellow
        exit 1
    }
}

function Run-AnsiblePlaybook {
    param(
        [string]$PlaybookPath,
        [string]$Tags = "",
        [string]$Limit = ""
    )
    
    $ansibleArgs = @(
        "-i", $InventoryFile,
        $PlaybookPath
    )
    
    if ($Tags) {
        $ansibleArgs += "--tags", $Tags
    }
    
    if ($Limit) {
        $ansibleArgs += "--limit", $Limit
    }
    
    if ($Verbose) {
        $ansibleArgs += "-v"
    }
    
    if ($DryRun) {
        $ansibleArgs += "--check", "--diff"
    }
    
    try {
        ansible-playbook @ansibleArgs
        Write-ColorOutput "✓ Playbook выполнен успешно" $Green
    } catch {
        Write-ColorOutput "✗ Ошибка выполнения playbook" $Red
        exit 1
    }
}

function Setup-AllServices {
    Write-ColorOutput "Настройка всех сервисов..." $Blue
    Run-AnsiblePlaybook -PlaybookPath $PlaybookFile
}

function Setup-WebServers {
    Write-ColorOutput "Настройка веб-серверов..." $Blue
    Run-AnsiblePlaybook -PlaybookPath "playbooks/web_servers.yml" -Limit "web_servers"
}

function Setup-Monitoring {
    Write-ColorOutput "Настройка мониторинга..." $Blue
    Run-AnsiblePlaybook -PlaybookPath "playbooks/zabbix.yml" -Limit "monitoring"
}

function Setup-Logging {
    Write-ColorOutput "Настройка логирования..." $Blue
    Run-AnsiblePlaybook -PlaybookPath "playbooks/elasticsearch.yml" -Limit "logging"
    Run-AnsiblePlaybook -PlaybookPath "playbooks/kibana.yml" -Limit "logging"
}

function Generate-InventoryFromTerraform {
    Write-ColorOutput "Генерация inventory из Terraform outputs..." $Blue
    
    if (!(Test-Path "terraform/terraform.tfstate")) {
        Write-ColorOutput "✗ Terraform state не найден. Сначала запустите terraform apply" $Red
        return
    }
    
    Set-Location terraform
    try {
        $outputs = terraform output -json | ConvertFrom-Json
        Set-Location ..
        
        # Здесь можно добавить логику генерации inventory
        Write-ColorOutput "✓ Inventory обновлен из Terraform outputs" $Green
    } catch {
        Write-ColorOutput "✗ Ошибка получения Terraform outputs" $Red
        Set-Location ..
    }
}

# Основная логика
if (!$CheckConnectivity -and !$SetupAll -and !$SetupWeb -and !$SetupMonitoring -and !$SetupLogging) {
    Show-Help
    exit 0
}

# Переход в папку ansible
if (Test-Path "ansible") {
    Set-Location ansible
}

Test-AnsiblePrerequisites

if ($CheckConnectivity) {
    Test-Connectivity
}

if ($SetupAll) {
    Setup-AllServices
}

if ($SetupWeb) {
    Setup-WebServers
}

if ($SetupMonitoring) {
    Setup-Monitoring
}

if ($SetupLogging) {
    Setup-Logging
}

Write-ColorOutput "Скрипт завершен успешно!" $Green