# Скрипт проверки готовности дипломного проекта
# Проверяет наличие всех необходимых файлов и конфигураций

$ErrorActionPreference = "Stop"

Write-Host "=== Проверка готовности дипломного проекта ===" -ForegroundColor Green

$projectRoot = Get-Location
$errors = @()
$warnings = @()

# Функция проверки файла
function Test-ProjectFile {
    param(
        [string]$FilePath,
        [string]$Description,
        [switch]$Required = $true
    )
    
    if (Test-Path $FilePath) {
        Write-Host "✓ $Description" -ForegroundColor Green
        return $true
    } else {
        if ($Required) {
            $script:errors += "✗ $Description - файл не найден: $FilePath"
        } else {
            $script:warnings += "⚠ $Description - файл не найден: $FilePath"
        }
        return $false
    }
}

# Функция проверки директории
function Test-ProjectDirectory {
    param(
        [string]$DirPath,
        [string]$Description
    )
    
    if (Test-Path $DirPath -PathType Container) {
        Write-Host "✓ $Description" -ForegroundColor Green
        return $true
    } else {
        $script:errors += "✗ $Description - директория не найдена: $DirPath"
        return $false
    }
}

Write-Host "`n--- Проверка структуры проекта ---" -ForegroundColor Yellow

# Основные директории
Test-ProjectDirectory "terraform" "Директория Terraform"
Test-ProjectDirectory "ansible" "Директория Ansible"
Test-ProjectDirectory "ansible/roles" "Директория ролей Ansible"
Test-ProjectDirectory "ansible/templates" "Директория шаблонов Ansible"
Test-ProjectDirectory "ansible/group_vars" "Директория переменных Ansible"
Test-ProjectDirectory "ansible/inventory" "Директория инвентаря Ansible"

Write-Host "`n--- Проверка файлов Terraform ---" -ForegroundColor Yellow

# Terraform файлы
Test-ProjectFile "terraform/main.tf" "Основной файл Terraform"
Test-ProjectFile "terraform/variables.tf" "Переменные Terraform"
Test-ProjectFile "terraform/outputs.tf" "Выходные значения Terraform"
Test-ProjectFile "terraform/network.tf" "Сетевая конфигурация"
Test-ProjectFile "terraform/compute.tf" "Вычислительные ресурсы"
Test-ProjectFile "terraform/load_balancer.tf" "Балансировщик нагрузки"
Test-ProjectFile "terraform/security_groups.tf" "Группы безопасности"

Write-Host "`n--- Проверка файлов Ansible ---" -ForegroundColor Yellow

# Ansible файлы
Test-ProjectFile "ansible/site.yml" "Главный playbook Ansible"
Test-ProjectFile "ansible/ansible.cfg" "Конфигурация Ansible"
Test-ProjectFile "ansible/inventory/hosts.yml" "Инвентарь хостов"
Test-ProjectFile "ansible/group_vars/all.yml" "Общие переменные"
Test-ProjectFile "ansible/group_vars/vault.yml" "Зашифрованные переменные"

# Роли Ansible
$roles = @("common", "nginx", "zabbix-server", "zabbix-agent", "elasticsearch", "kibana", "filebeat")
foreach ($role in $roles) {
    Test-ProjectDirectory "ansible/roles/$role" "Роль $role"
    Test-ProjectFile "ansible/roles/$role/tasks/main.yml" "Задачи роли $role"
    Test-ProjectFile "ansible/roles/$role/handlers/main.yml" "Обработчики роли $role" -Required:$false
}

# Шаблоны
$templates = @(
    "nginx.conf.j2",
    "index.html.j2", 
    "zabbix_agentd.conf.j2",
    "mysql.cnf.j2",
    "elasticsearch.yml.j2",
    "jvm.options.j2",
    "kibana.yml.j2",
    "kibana_nginx.conf.j2",
    "filebeat.yml.j2",
    "nginx_module.yml.j2"
)

foreach ($template in $templates) {
    Test-ProjectFile "ansible/templates/$template" "Шаблон $template"
}

Write-Host "`n--- Проверка документации и скриптов ---" -ForegroundColor Yellow

# Документация и скрипты
Test-ProjectFile "README.md" "Документация проекта"
Test-ProjectFile "deploy.ps1" "Скрипт развертывания"
Test-ProjectFile ".gitignore" "Файл .gitignore"
Test-ProjectFile ".env.example" "Пример переменных окружения"

Write-Host "`n--- Проверка инструментов ---" -ForegroundColor Yellow

# Проверка установленных инструментов
try {
    $terraformVersion = terraform version 2>$null
    Write-Host "✓ Terraform установлен: $($terraformVersion[0])" -ForegroundColor Green
} catch {
    $warnings += "⚠ Terraform не найден в PATH"
}

try {
    $ansibleVersion = ansible --version 2>$null | Select-Object -First 1
    Write-Host "✓ Ansible установлен: $ansibleVersion" -ForegroundColor Green
} catch {
    $warnings += "⚠ Ansible не найден в PATH"
}

try {
    $ycVersion = yc version 2>$null
    Write-Host "✓ Yandex Cloud CLI установлен: $ycVersion" -ForegroundColor Green
} catch {
    $warnings += "⚠ Yandex Cloud CLI не найден в PATH"
}

Write-Host "`n--- Проверка переменных окружения ---" -ForegroundColor Yellow

# Проверка переменных окружения
if ($env:YC_TOKEN) {
    Write-Host "✓ YC_TOKEN установлен" -ForegroundColor Green
} else {
    $warnings += "⚠ Переменная окружения YC_TOKEN не установлена"
}

if ($env:YC_CLOUD_ID) {
    Write-Host "✓ YC_CLOUD_ID установлен" -ForegroundColor Green
} else {
    $warnings += "⚠ Переменная окружения YC_CLOUD_ID не установлена"
}

if ($env:YC_FOLDER_ID) {
    Write-Host "✓ YC_FOLDER_ID установлен" -ForegroundColor Green
} else {
    $warnings += "⚠ Переменная окружения YC_FOLDER_ID не установлена"
}

# Подсчет статистики
$totalFiles = (Get-ChildItem -Recurse -File | Measure-Object).Count
$terraformFiles = (Get-ChildItem terraform -Filter "*.tf" | Measure-Object).Count
$ansibleFiles = (Get-ChildItem ansible -Recurse -Filter "*.yml" | Measure-Object).Count

Write-Host "`n--- Статистика проекта ---" -ForegroundColor Yellow
Write-Host "Общее количество файлов: $totalFiles" -ForegroundColor Cyan
Write-Host "Terraform файлов: $terraformFiles" -ForegroundColor Cyan
Write-Host "Ansible файлов: $ansibleFiles" -ForegroundColor Cyan

# Вывод результатов
Write-Host "`n=== РЕЗУЛЬТАТЫ ПРОВЕРКИ ===" -ForegroundColor Green

if ($errors.Count -eq 0) {
    Write-Host "✓ Все обязательные файлы найдены!" -ForegroundColor Green
} else {
    Write-Host "ОШИБКИ:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host $error -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "`nПРЕДУПРЕЖДЕНИЯ:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host $warning -ForegroundColor Yellow
    }
}

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "`n🎉 ПРОЕКТ ГОТОВ К РАЗВЕРТЫВАНИЮ! 🎉" -ForegroundColor Green
    Write-Host "Запустите: .\deploy.ps1 -All" -ForegroundColor Cyan
} elseif ($errors.Count -eq 0) {
    Write-Host "`n⚠ Проект готов, но есть предупреждения" -ForegroundColor Yellow
    Write-Host "Рекомендуется устранить предупреждения перед развертыванием" -ForegroundColor Yellow
} else {
    Write-Host "`n❌ Проект НЕ готов к развертыванию" -ForegroundColor Red
    Write-Host "Устраните ошибки и запустите проверку снова" -ForegroundColor Red
    exit 1
}

Write-Host "`nДля получения помощи см. README.md" -ForegroundColor Cyan