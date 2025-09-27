# Скрипт проверки безопасности конфиденциальных файлов
# Автор: Дипломный проект DevOps

param(
    [switch]$Verbose
)

Write-Host "🔒 Проверка безопасности конфиденциальных файлов" -ForegroundColor Cyan
Write-Host "=" * 60

$ErrorCount = 0
$WarningCount = 0

# Список конфиденциальных файлов
$ConfidentialFiles = @(
    "info.txt",
    "authorized_key.json"
)

# Проверка существования файлов
Write-Host "`n📁 Проверка существования конфиденциальных файлов:" -ForegroundColor Yellow
foreach ($file in $ConfidentialFiles) {
    if (Test-Path $file) {
        Write-Host "  ✅ $file - найден" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $file - не найден" -ForegroundColor Red
        $ErrorCount++
    }
}

# Проверка прав доступа
Write-Host "`n🔐 Проверка прав доступа:" -ForegroundColor Yellow
foreach ($file in $ConfidentialFiles) {
    if (Test-Path $file) {
        $acl = Get-Acl $file
        $accessRules = $acl.Access | Where-Object { $_.IdentityReference -notlike "*$env:USERNAME*" -and $_.AccessControlType -eq "Allow" }
        
        if ($accessRules.Count -eq 0) {
            Write-Host "  ✅ $file - доступ ограничен только владельцем" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  $file - обнаружены дополнительные права доступа:" -ForegroundColor Yellow
            foreach ($rule in $accessRules) {
                Write-Host "    - $($rule.IdentityReference): $($rule.FileSystemRights)" -ForegroundColor Yellow
            }
            $WarningCount++
        }
        
        if ($Verbose) {
            Write-Host "    Подробная информация о правах доступа:" -ForegroundColor Gray
            icacls $file
        }
    }
}

# Проверка .gitignore
Write-Host "`n📝 Проверка .gitignore:" -ForegroundColor Yellow
if (Test-Path ".gitignore") {
    $gitignoreContent = Get-Content ".gitignore"
    $missingFiles = @()
    
    foreach ($file in $ConfidentialFiles) {
        if ($gitignoreContent -notcontains $file) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -eq 0) {
        Write-Host "  ✅ Все конфиденциальные файлы добавлены в .gitignore" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Следующие файлы отсутствуют в .gitignore:" -ForegroundColor Red
        foreach ($file in $missingFiles) {
            Write-Host "    - $file" -ForegroundColor Red
        }
        $ErrorCount++
    }
} else {
    Write-Host "  ❌ Файл .gitignore не найден" -ForegroundColor Red
    $ErrorCount++
}

# Проверка Git статуса
Write-Host "`n📊 Проверка Git статуса:" -ForegroundColor Yellow
if (Test-Path ".git") {
    try {
        $gitStatus = git status --porcelain 2>$null
        $trackedConfidentialFiles = @()
        
        foreach ($file in $ConfidentialFiles) {
            if ($gitStatus -match $file) {
                $trackedConfidentialFiles += $file
            }
        }
        
        if ($trackedConfidentialFiles.Count -eq 0) {
            Write-Host "  ✅ Конфиденциальные файлы не отслеживаются Git" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Следующие конфиденциальные файлы отслеживаются Git:" -ForegroundColor Red
            foreach ($file in $trackedConfidentialFiles) {
                Write-Host "    - $file" -ForegroundColor Red
            }
            $ErrorCount++
        }
    } catch {
        Write-Host "  ⚠️  Не удалось проверить статус Git" -ForegroundColor Yellow
        $WarningCount++
    }
} else {
    Write-Host "  ℹ️  Git репозиторий не инициализирован" -ForegroundColor Blue
}

# Проверка переменных окружения
Write-Host "`n🌍 Проверка переменных окружения:" -ForegroundColor Yellow
$requiredEnvVars = @("YC_TOKEN", "YC_CLOUD_ID", "YC_FOLDER_ID")
$missingEnvVars = @()

foreach ($envVar in $requiredEnvVars) {
    if ([string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($envVar))) {
        $missingEnvVars += $envVar
    }
}

if ($missingEnvVars.Count -eq 0) {
    Write-Host "  ✅ Все необходимые переменные окружения установлены" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Отсутствуют переменные окружения:" -ForegroundColor Yellow
    foreach ($envVar in $missingEnvVars) {
        Write-Host "    - $envVar" -ForegroundColor Yellow
    }
    $WarningCount++
}

# Итоговый отчет
Write-Host "`n" + "=" * 60
Write-Host "📋 ИТОГОВЫЙ ОТЧЕТ:" -ForegroundColor Cyan

if ($ErrorCount -eq 0 -and $WarningCount -eq 0) {
    Write-Host "🎉 Все проверки безопасности пройдены успешно!" -ForegroundColor Green
    exit 0
} elseif ($ErrorCount -eq 0) {
    Write-Host "⚠️  Проверки пройдены с предупреждениями ($WarningCount)" -ForegroundColor Yellow
    Write-Host "Рекомендуется устранить предупреждения для повышения безопасности." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "❌ Обнаружены критические проблемы безопасности!" -ForegroundColor Red
    Write-Host "Ошибки: $ErrorCount, Предупреждения: $WarningCount" -ForegroundColor Red
    Write-Host "Необходимо устранить все ошибки перед продолжением работы." -ForegroundColor Red
    exit 1
}