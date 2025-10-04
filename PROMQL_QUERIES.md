# 📊 СПРАВОЧНИК PROMQL ЗАПРОСОВ

**Версия:** 1.0  
**Дата:** 04.10.2025  
**Для:** Prometheus 2.48.0 + Node Exporter 1.7.0

---

## 📋 СОДЕРЖАНИЕ

1. [CPU Метрики](#cpu-метрики)
2. [Memory Метрики](#memory-метрики)
3. [Disk Метрики](#disk-метрики)
4. [Network Метрики](#network-метрики)
5. [System Метрики](#system-метрики)
6. [Комплексные запросы](#комплексные-запросы)
7. [Алерты](#алерты)

---

## 🖥️ CPU МЕТРИКИ

### CPU Usage (общая загрузка)
```promql
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```
**Описание:** Процент использования CPU (усредненный по всем ядрам)  
**Диапазон:** 0-100%  
**Использование:** Основная метрика загрузки процессора

### CPU Usage по режимам
```promql
# User mode
irate(node_cpu_seconds_total{mode="user"}[5m]) * 100

# System mode
irate(node_cpu_seconds_total{mode="system"}[5m]) * 100

# I/O Wait
irate(node_cpu_seconds_total{mode="iowait"}[5m]) * 100

# Idle
irate(node_cpu_seconds_total{mode="idle"}[5m]) * 100
```

### CPU Usage по ядрам
```promql
100 - (avg by (instance, cpu) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```
**Описание:** Загрузка каждого ядра отдельно

### CPU Load Average
```promql
# 1 minute
node_load1

# 5 minutes
node_load5

# 15 minutes
node_load15
```

### CPU Count
```promql
count(node_cpu_seconds_total{mode="idle"}) by (instance)
```
**Описание:** Количество CPU ядер на сервере

---

## 💾 MEMORY МЕТРИКИ

### Memory Usage (процент)
```promql
100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))
```
**Описание:** Процент использования памяти  
**Диапазон:** 0-100%  
**Использование:** Основная метрика использования памяти

### Memory Usage (байты)
```promql
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes
```
**Описание:** Использованная память в байтах

### Memory Available
```promql
node_memory_MemAvailable_bytes
```
**Описание:** Доступная память в байтах

### Memory Total
```promql
node_memory_MemTotal_bytes
```
**Описание:** Общий объем памяти

### Memory Breakdown
```promql
# Used
node_memory_MemTotal_bytes - node_memory_MemFree_bytes - node_memory_Buffers_bytes - node_memory_Cached_bytes

# Buffers
node_memory_Buffers_bytes

# Cached
node_memory_Cached_bytes

# Free
node_memory_MemFree_bytes
```

### Swap Usage
```promql
# Swap Used (процент)
100 * (1 - (node_memory_SwapFree_bytes / node_memory_SwapTotal_bytes))

# Swap Used (байты)
node_memory_SwapTotal_bytes - node_memory_SwapFree_bytes

# Swap Total
node_memory_SwapTotal_bytes
```

---

## 💿 DISK МЕТРИКИ

### Disk Usage (процент)
```promql
100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)
```
**Описание:** Процент использования диска для корневого раздела  
**Диапазон:** 0-100%

### Disk Usage для всех разделов
```promql
100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100)
```

### Disk Space Available
```promql
node_filesystem_avail_bytes{mountpoint="/"}
```
**Описание:** Доступное место на диске в байтах

### Disk Space Total
```promql
node_filesystem_size_bytes{mountpoint="/"}
```

### Disk I/O Read
```promql
# Bytes per second
rate(node_disk_read_bytes_total[5m])

# Operations per second
rate(node_disk_reads_completed_total[5m])
```

### Disk I/O Write
```promql
# Bytes per second
rate(node_disk_written_bytes_total[5m])

# Operations per second
rate(node_disk_writes_completed_total[5m])
```

### Disk I/O Time
```promql
# Average I/O time (ms)
rate(node_disk_io_time_seconds_total[5m]) * 1000
```

### Disk Inodes Usage
```promql
100 * (1 - (node_filesystem_files_free{mountpoint="/"} / node_filesystem_files{mountpoint="/"}))
```

---

## 🌐 NETWORK МЕТРИКИ

### Network Traffic Receive (входящий)
```promql
# Bytes per second
rate(node_network_receive_bytes_total[5m])

# Megabits per second
rate(node_network_receive_bytes_total[5m]) * 8 / 1000000
```

### Network Traffic Transmit (исходящий)
```promql
# Bytes per second
rate(node_network_transmit_bytes_total[5m])

# Megabits per second
rate(node_network_transmit_bytes_total[5m]) * 8 / 1000000
```

### Network Packets
```promql
# Received packets per second
rate(node_network_receive_packets_total[5m])

# Transmitted packets per second
rate(node_network_transmit_packets_total[5m])
```

### Network Errors
```promql
# Receive errors
rate(node_network_receive_errs_total[5m])

# Transmit errors
rate(node_network_transmit_errs_total[5m])
```

### Network Drops
```promql
# Receive drops
rate(node_network_receive_drop_total[5m])

# Transmit drops
rate(node_network_transmit_drop_total[5m])
```

---

## ⚙️ SYSTEM МЕТРИКИ

### System Uptime
```promql
node_time_seconds - node_boot_time_seconds
```
**Описание:** Время работы системы в секундах

### System Uptime (дни)
```promql
(node_time_seconds - node_boot_time_seconds) / 86400
```

### System Time
```promql
node_time_seconds
```

### Boot Time
```promql
node_boot_time_seconds
```

### Context Switches
```promql
rate(node_context_switches_total[5m])
```
**Описание:** Количество переключений контекста в секунду

### Processes
```promql
# Running processes
node_procs_running

# Blocked processes
node_procs_blocked

# Total processes
node_processes_state
```

### File Descriptors
```promql
# Open file descriptors
node_filefd_allocated

# Maximum file descriptors
node_filefd_maximum
```

---

## 🔄 КОМПЛЕКСНЫЕ ЗАПРОСЫ

### Top 5 серверов по CPU
```promql
topk(5, 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100))
```

### Top 5 серверов по Memory
```promql
topk(5, 100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)))
```

### Top 5 серверов по Disk
```promql
topk(5, 100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100))
```

### Серверы с высокой загрузкой CPU (>80%)
```promql
(100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)) > 80
```

### Серверы с низкой памятью (<20% свободной)
```promql
(100 * (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) < 20
```

### Серверы с заполненным диском (>90%)
```promql
(100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)) > 90
```

### Общая статистика по всем серверам
```promql
# Average CPU across all servers
avg(100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100))

# Average Memory across all servers
avg(100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)))

# Total Memory across all servers
sum(node_memory_MemTotal_bytes)
```

---

## 🚨 АЛЕРТЫ

### CPU Alert (>90% за 5 минут)
```promql
(100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)) > 90
```

### Memory Alert (<10% свободной)
```promql
(100 * (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) < 10
```

### Disk Alert (>95% заполнен)
```promql
(100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)) > 95
```

### Node Down Alert
```promql
up{job="web_servers"} == 0
```

### High Load Alert (Load > CPU count)
```promql
node_load5 > count(node_cpu_seconds_total{mode="idle"}) by (instance)
```

---

## 📊 ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ В GRAFANA

### Panel 1: CPU Usage Gauge
```promql
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```
**Тип визуализации:** Gauge  
**Единицы:** Percent (0-100)  
**Пороги:** 
- Green: 0-70
- Yellow: 70-85
- Red: 85-100

### Panel 2: Memory Usage Graph
```promql
100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))
```
**Тип визуализации:** Time series  
**Единицы:** Percent (0-100)  
**Legend:** {{instance}}

### Panel 3: Disk Usage Bar Gauge
```promql
100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)
```
**Тип визуализации:** Bar gauge  
**Единицы:** Percent (0-100)  
**Orientation:** Horizontal

### Panel 4: Network Traffic
```promql
# Receive
rate(node_network_receive_bytes_total{device!~"lo|veth.*"}[5m]) * 8 / 1000000

# Transmit
rate(node_network_transmit_bytes_total{device!~"lo|veth.*"}[5m]) * 8 / 1000000
```
**Тип визуализации:** Time series  
**Единицы:** Mbps  
**Legend:** {{instance}} - {{device}}

---

## 🔧 ПОЛЕЗНЫЕ ФУНКЦИИ

### rate() vs irate()
```promql
# rate() - средняя скорость за период
rate(node_cpu_seconds_total[5m])

# irate() - мгновенная скорость (последние 2 точки)
irate(node_cpu_seconds_total[5m])
```
**Рекомендация:** Используйте `irate()` для быстро меняющихся метрик (CPU), `rate()` для медленных (disk I/O)

### avg, sum, min, max
```promql
# Average
avg(node_memory_MemTotal_bytes)

# Sum
sum(node_memory_MemTotal_bytes)

# Minimum
min(node_memory_MemAvailable_bytes)

# Maximum
max(node_cpu_seconds_total)
```

### by, without
```promql
# Group by instance
avg by (instance) (node_cpu_seconds_total)

# Group by all labels except mode
avg without (mode) (node_cpu_seconds_total)
```

---

## 📚 ДОПОЛНИТЕЛЬНЫЕ РЕСУРСЫ

- [Prometheus Query Documentation](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)
- [Node Exporter Metrics](https://github.com/prometheus/node_exporter#enabled-by-default)

---

*Документ обновлен: 04.10.2025*

