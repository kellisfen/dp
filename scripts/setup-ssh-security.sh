#!/bin/bash

# Скрипт для безопасной настройки SSH ключей
# Автор: DevOps Team
# Версия: 1.0

set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция логирования
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Проверка наличия SSH ключа
check_ssh_key() {
    local key_file="$1"
    
    if [[ ! -f "$key_file" ]]; then
        error "SSH ключ не найден: $key_file"
    fi
    
    log "SSH ключ найден: $key_file"
}

# Установка безопасных прав доступа
set_secure_permissions() {
    local key_file="$1"
    
    log "Установка безопасных прав доступа для SSH ключа..."
    
    # Права только для владельца (600)
    chmod 600 "$key_file"
    
    # Проверка прав доступа
    local perms=$(stat -c "%a" "$key_file" 2>/dev/null || stat -f "%A" "$key_file" 2>/dev/null)
    
    if [[ "$perms" == "600" ]]; then
        log "Права доступа установлены корректно: $perms"
    else
        warn "Права доступа могут быть небезопасными: $perms"
    fi
}

# Проверка содержимого ключа
validate_key_content() {
    local key_file="$1"
    
    log "Проверка содержимого SSH ключа..."
    
    # Проверка формата ключа
    if ssh-keygen -l -f "$key_file" >/dev/null 2>&1; then
        log "SSH ключ имеет корректный формат"
        
        # Получение информации о ключе
        local key_info=$(ssh-keygen -l -f "$key_file")
        log "Информация о ключе: $key_info"
        
        # Проверка длины ключа
        local key_bits=$(echo "$key_info" | awk '{print $1}')
        if [[ "$key_bits" -ge 2048 ]]; then
            log "Длина ключа безопасна: $key_bits бит"
        else
            warn "Длина ключа может быть небезопасной: $key_bits бит (рекомендуется >= 2048)"
        fi
    else
        error "SSH ключ имеет некорректный формат или поврежден"
    fi
}

# Создание backup ключа
backup_key() {
    local key_file="$1"
    local backup_dir="./backups"
    
    log "Создание резервной копии SSH ключа..."
    
    mkdir -p "$backup_dir"
    local backup_file="$backup_dir/$(basename "$key_file").backup.$(date +%Y%m%d_%H%M%S)"
    
    cp "$key_file" "$backup_file"
    chmod 600 "$backup_file"
    
    log "Резервная копия создана: $backup_file"
}

# Проверка SSH агента
check_ssh_agent() {
    log "Проверка SSH агента..."
    
    if ssh-add -l >/dev/null 2>&1; then
        log "SSH агент запущен и содержит ключи"
        ssh-add -l
    else
        warn "SSH агент не запущен или не содержит ключей"
        log "Для запуска SSH агента выполните: eval \$(ssh-agent -s)"
        log "Для добавления ключа выполните: ssh-add /path/to/your/key"
    fi
}

# Основная функция
main() {
    local key_file="${1:-ssh_key.pem}"
    
    log "Начало проверки безопасности SSH ключа: $key_file"
    
    # Проверки
    check_ssh_key "$key_file"
    set_secure_permissions "$key_file"
    validate_key_content "$key_file"
    backup_key "$key_file"
    check_ssh_agent
    
    log "Проверка безопасности SSH ключа завершена успешно!"
    
    # Рекомендации
    echo
    log "РЕКОМЕНДАЦИИ ПО БЕЗОПАСНОСТИ:"
    echo "1. Никогда не делитесь приватными ключами"
    echo "2. Используйте парольную фразу для защиты ключей"
    echo "3. Регулярно ротируйте SSH ключи"
    echo "4. Используйте SSH агент для безопасного управления ключами"
    echo "5. Ограничьте доступ к ключам на уровне файловой системы"
    echo "6. Используйте современные алгоритмы (Ed25519, RSA >= 2048 бит)"
}

# Проверка аргументов
if [[ $# -gt 1 ]]; then
    error "Использование: $0 [путь_к_ssh_ключу]"
fi

# Запуск основной функции
main "$@"