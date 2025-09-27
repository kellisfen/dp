# Скрипт развертывания дипломного проекта
# PowerShell скрипт для Windows

param(
    [switch]$Plan,
    [switch]$Apply,
    [switch]$Destroy,
    [switch]$Ansible,
    [switch]$All
)

$ErrorActionPreference = "Stop"

Write-Host "=== Дипломный проект DevOps - Развертывание инфраструктуры ===" -ForegroundColor Green

# Проверка наличия необходимых инструментов
function Test-Prerequisites {
    Write-Host "Проверка предварительных требований..." -ForegroundColor Yellow
    
    # Проверка Terraform
    try {
        $terraformVersion = terraform version
        Write-Host "✓ Terraform найден: $($terraformVersion[0])" -ForegroundColor Green
    }
    catch {
        Write-Error "Terraform не найден. Установите Terraform и добавьте его в PATH."
        exit 1
    }
    
    # Проверка Ansible
    try {
        $ansibleVersion = ansible --version | Select-Object -First 1
        Write-Host "✓ Ansible найден: $ansibleVersion" -ForegroundColor Green
    }
    catch {
        Write-Error "Ansible не найден. Установите Ansible и добавьте его в PATH."
        exit 1
    }
    
    # Проверка переменных окружения
    if (-not $env:YC_TOKEN) {
        Write-Error "Переменная окружения YC_TOKEN не установлена."
        exit 1
    }
    
    if (-not $env:YC_CLOUD_ID) {
        Write-Error "Переменная окружения YC_CLOUD_ID не установлена."
        exit 1
    }
    
    if (-not $env:YC_FOLDER_ID) {
        Write-Error "Переменная окружения YC_FOLDER_ID не установлена."
        exit 1
    }
    
    Write-Host "✓ Все предварительные требования выполнены" -ForegroundColor Green
}

# Terraform операции
function Invoke-TerraformPlan {
    Write-Host "Выполнение Terraform Plan..." -ForegroundColor Yellow
    Set-Location terraform
    terraform init
    terraform plan -var="cloud_id=$env:YC_CLOUD_ID" -var="folder_id=$env:YC_FOLDER_ID"
    Set-Location ..
}

function Invoke-TerraformApply {
    Write-Host "Выполнение Terraform Apply..." -ForegroundColor Yellow
    Set-Location terraform
    terraform init
    terraform apply -auto-approve -var="cloud_id=$env:YC_CLOUD_ID" -var="folder_id=$env:YC_FOLDER_ID"
    
    # Сохранение SSH ключа
    terraform output -raw ssh_private_key | Out-File -FilePath "../ssh_key.pem" -Encoding ASCII
    
    # Получение IP адресов
    $bastionIP = terraform output -raw bastion_external_ip
    $zabbixIP = terraform output -raw zabbix_external_ip
    $kibanaIP = terraform output -raw kibana_external_ip
    $lbIP = terraform output -raw load_balancer_external_ip
    
    Write-Host "=== IP адреса серверов ===" -ForegroundColor Green
    Write-Host "Bastion Host: $bastionIP" -ForegroundColor Cyan
    Write-Host "Zabbix: $zabbixIP" -ForegroundColor Cyan
    Write-Host "Kibana: $kibanaIP" -ForegroundColor Cyan
    Write-Host "Load Balancer: $lbIP" -ForegroundColor Cyan
    
    # Создание файла с IP адресами для Ansible
    @"
bastion_external_ip: $bastionIP
zabbix_external_ip: $zabbixIP
kibana_external_ip: $kibanaIP
load_balancer_external_ip: $lbIP
"@ | Out-File -FilePath "../ansible/group_vars/terraform_outputs.yml" -Encoding UTF8
    
    Set-Location ..
}

function Invoke-TerraformDestroy {
    Write-Host "Выполнение Terraform Destroy..." -ForegroundColor Red
    Set-Location terraform
    terraform destroy -auto-approve -var="cloud_id=$env:YC_CLOUD_ID" -var="folder_id=$env:YC_FOLDER_ID"
    Set-Location ..
    
    # Удаление созданных файлов
    if (Test-Path "ssh_key.pem") { Remove-Item "ssh_key.pem" }
    if (Test-Path "ansible/group_vars/terraform_outputs.yml") { Remove-Item "ansible/group_vars/terraform_outputs.yml" }
}

# Ansible операции
function Invoke-AnsiblePlaybook {
    Write-Host "Выполнение Ansible Playbook..." -ForegroundColor Yellow
    
    if (-not (Test-Path "ssh_key.pem")) {
        Write-Error "SSH ключ не найден. Сначала выполните Terraform Apply."
        exit 1
    }
    
    # Установка правильных прав на SSH ключ (для WSL/Linux подсистемы)
    if (Get-Command "wsl" -ErrorAction SilentlyContinue) {
        wsl chmod 600 ssh_key.pem
    }
    
    Set-Location ansible
    
    # Шифрование vault файла (если еще не зашифрован)
    if (-not (Select-String -Path "group_vars/vault.yml" -Pattern "ANSIBLE_VAULT" -Quiet)) {
        Write-Host "Шифрование vault файла..." -ForegroundColor Yellow
        ansible-vault encrypt group_vars/vault.yml --ask-vault-pass
    }
    
    # Запуск playbook
    ansible-playbook site.yml --ask-vault-pass
    
    Set-Location ..
}

# Основная логика
Test-Prerequisites

if ($Plan) {
    Invoke-TerraformPlan
}
elseif ($Apply) {
    Invoke-TerraformApply
}
elseif ($Destroy) {
    Invoke-TerraformDestroy
}
elseif ($Ansible) {
    Invoke-AnsiblePlaybook
}
elseif ($All) {
    Invoke-TerraformApply
    Start-Sleep -Seconds 60  # Ожидание готовности серверов
    Invoke-AnsiblePlaybook
}
else {
    Write-Host @"
Использование:
  .\deploy.ps1 -Plan      # Показать план Terraform
  .\deploy.ps1 -Apply     # Применить конфигурацию Terraform
  .\deploy.ps1 -Ansible   # Запустить Ansible playbooks
  .\deploy.ps1 -All       # Выполнить полное развертывание
  .\deploy.ps1 -Destroy   # Удалить инфраструктуру

Перед запуском установите переменные окружения:
  `$env:YC_TOKEN = "your_token"
  `$env:YC_CLOUD_ID = "your_cloud_id"
  `$env:YC_FOLDER_ID = "your_folder_id"
"@ -ForegroundColor Yellow
}

Write-Host "Готово!" -ForegroundColor Green