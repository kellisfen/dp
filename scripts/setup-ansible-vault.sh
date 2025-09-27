#!/bin/bash

# Скрипт для настройки Ansible Vault
# Автор: DevOps Team
# Версия: 1.0

set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Проверка наличия Ansible
check_ansible() {
    if ! command -v ansible-vault &> /dev/null; then
        error "Ansible не установлен. Установите Ansible для продолжения."
    fi
    
    log "Ansible найден: $(ansible --version | head -n1)"
}

# Создание пароля для vault
create_vault_password() {
    local vault_pass_file=".vault_pass"
    
    if [[ -f "$vault_pass_file" ]]; then
        warn "Файл с паролем vault уже существует: $vault_pass_file"
        read -p "Перезаписать? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Использую существующий файл с паролем"
            return 0
        fi
    fi
    
    log "Создание нового пароля для Ansible Vault..."
    
    # Генерация случайного пароля
    local password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    
    echo "$password" > "$vault_pass_file"
    chmod 600 "$vault_pass_file"
    
    log "Пароль для vault создан и сохранен в $vault_pass_file"
    warn "ВАЖНО: Сохраните этот пароль в безопасном месте!"
    warn "Без него вы не сможете расшифровать vault файлы!"
}

# Шифрование vault файла
encrypt_vault_file() {
    local vault_file="$1"
    local vault_pass_file=".vault_pass"
    
    if [[ ! -f "$vault_file" ]]; then
        error "Vault файл не найден: $vault_file"
    fi
    
    if [[ ! -f "$vault_pass_file" ]]; then
        error "Файл с паролем vault не найден: $vault_pass_file"
    fi
    
    log "Проверка статуса шифрования файла: $vault_file"
    
    # Проверка, зашифрован ли уже файл
    if ansible-vault view "$vault_file" --vault-password-file="$vault_pass_file" &>/dev/null; then
        warn "Файл уже зашифрован: $vault_file"
        return 0
    elif head -n1 "$vault_file" | grep -q '^\$ANSIBLE_VAULT;'; then
        warn "Файл зашифрован, но пароль может быть неверным: $vault_file"
        return 1
    fi
    
    log "Создание резервной копии незашифрованного файла..."
    cp "$vault_file" "${vault_file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    log "Шифрование файла: $vault_file"
    ansible-vault encrypt "$vault_file" --vault-password-file="$vault_pass_file"
    
    if [[ $? -eq 0 ]]; then
        log "Файл успешно зашифрован: $vault_file"
    else
        error "Ошибка при шифровании файла: $vault_file"
    fi
}

# Проверка зашифрованного файла
verify_encrypted_file() {
    local vault_file="$1"
    local vault_pass_file=".vault_pass"
    
    log "Проверка зашифрованного файла: $vault_file"
    
    if ansible-vault view "$vault_file" --vault-password-file="$vault_pass_file" &>/dev/null; then
        log "Файл корректно зашифрован и может быть расшифрован"
        
        # Показать первые несколько строк для проверки
        info "Первые строки расшифрованного содержимого:"
        ansible-vault view "$vault_file" --vault-password-file="$vault_pass_file" | head -n5
    else
        error "Не удается расшифровать файл или файл поврежден"
    fi
}

# Настройка ansible.cfg для работы с vault
setup_ansible_config() {
    local ansible_cfg="ansible/ansible.cfg"
    local vault_pass_file="../.vault_pass"
    
    if [[ ! -f "$ansible_cfg" ]]; then
        warn "Файл ansible.cfg не найден: $ansible_cfg"
        return 1
    fi
    
    log "Настройка ansible.cfg для работы с vault..."
    
    # Проверка, есть ли уже настройка vault_password_file
    if grep -q "vault_password_file" "$ansible_cfg"; then
        warn "Настройка vault_password_file уже существует в ansible.cfg"
    else
        # Добавление настройки vault_password_file
        sed -i '/^\[defaults\]/a vault_password_file = '"$vault_pass_file" "$ansible_cfg"
        log "Добавлена настройка vault_password_file в ansible.cfg"
    fi
}

# Создание примера использования
create_usage_example() {
    local example_file="VAULT_USAGE.md"
    
    log "Создание примера использования vault..."
    
    cat > "$example_file" << 'EOF'
# Использование Ansible Vault

## Основные команды

### Шифрование файла
```bash
ansible-vault encrypt ansible/group_vars/vault.yml --vault-password-file=.vault_pass
```

### Расшифровка файла
```bash
ansible-vault decrypt ansible/group_vars/vault.yml --vault-password-file=.vault_pass
```

### Просмотр зашифрованного файла
```bash
ansible-vault view ansible/group_vars/vault.yml --vault-password-file=.vault_pass
```

### Редактирование зашифрованного файла
```bash
ansible-vault edit ansible/group_vars/vault.yml --vault-password-file=.vault_pass
```

### Изменение пароля vault
```bash
ansible-vault rekey ansible/group_vars/vault.yml --vault-password-file=.vault_pass
```

## Запуск playbook с зашифрованными переменными

### С файлом пароля
```bash
ansible-playbook playbook.yml --vault-password-file=.vault_pass
```

### С запросом пароля
```bash
ansible-playbook playbook.yml --ask-vault-pass
```

## Безопасность

1. **Никогда не коммитьте файл с паролем vault в git**
2. **Храните пароль vault в безопасном месте**
3. **Используйте разные пароли для разных окружений**
4. **Регулярно меняйте пароли vault**
5. **Ограничьте доступ к файлам vault на уровне файловой системы**

## Структура vault файлов

```
ansible/
├── group_vars/
│   ├── all.yml          # Открытые переменные
│   └── vault.yml        # Зашифрованные секреты
├── host_vars/
│   └── hostname/
│       ├── vars.yml     # Открытые переменные хоста
│       └── vault.yml    # Зашифрованные секреты хоста
└── ansible.cfg          # Конфигурация с vault_password_file
```

## Переменные в vault.yml

Все секретные переменные должны начинаться с префикса `vault_`:

```yaml
# Пароли баз данных
vault_mysql_root_password: "secure_password_here"
vault_postgresql_password: "another_secure_password"

# API ключи
vault_api_key: "your_api_key_here"
vault_secret_key: "your_secret_key_here"

# Сертификаты и ключи
vault_ssl_private_key: |
  -----BEGIN PRIVATE KEY-----
  ...
  -----END PRIVATE KEY-----
```

## Использование в playbooks

```yaml
- name: Configure MySQL
  mysql_user:
    name: root
    password: "{{ vault_mysql_root_password }}"
    state: present
  no_log: true  # Не логировать чувствительные данные
```
EOF

    log "Создан файл с примерами использования: $example_file"
}

# Основная функция
main() {
    local vault_file="${1:-ansible/group_vars/vault.yml}"
    
    log "Начало настройки Ansible Vault"
    
    # Проверки и настройка
    check_ansible
    create_vault_password
    
    if [[ -f "$vault_file" ]]; then
        encrypt_vault_file "$vault_file"
        verify_encrypted_file "$vault_file"
    else
        warn "Vault файл не найден: $vault_file"
        warn "Создайте файл с секретными переменными перед шифрованием"
    fi
    
    setup_ansible_config
    create_usage_example
    
    log "Настройка Ansible Vault завершена!"
    
    # Рекомендации
    echo
    log "СЛЕДУЮЩИЕ ШАГИ:"
    echo "1. Сохраните пароль vault в безопасном месте"
    echo "2. Добавьте .vault_pass в .gitignore (уже добавлено)"
    echo "3. Создайте или обновите vault.yml с секретными переменными"
    echo "4. Используйте ansible-vault edit для редактирования секретов"
    echo "5. Запускайте playbook с --vault-password-file=.vault_pass"
    
    warn "ВАЖНО: Файл .vault_pass содержит пароль для расшифровки!"
    warn "Не коммитьте его в git и храните в безопасном месте!"
}

# Проверка аргументов
if [[ $# -gt 1 ]]; then
    error "Использование: $0 [путь_к_vault_файлу]"
fi

# Запуск основной функции
main "$@"