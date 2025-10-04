# 📊 РУКОВОДСТВО ПО ДАШБОРДАМ GRAFANA

**Версия:** 1.0  
**Дата:** 04.10.2025  
**Grafana:** 10.2.2

---

## 📋 СОДЕРЖАНИЕ

1. [Первый вход в Grafana](#первый-вход-в-grafana)
2. [Импорт готовых дашбордов](#импорт-готовых-дашбордов)
3. [Создание собственного дашборда](#создание-собственного-дашборда)
4. [Настройка панелей](#настройка-панелей)
5. [Рекомендуемые дашборды](#рекомендуемые-дашборды)
6. [Troubleshooting](#troubleshooting)

---

## 🚀 ПЕРВЫЙ ВХОД В GRAFANA

### 1. Открытие Grafana

Откройте браузер и перейдите по адресу:
```
http://YOUR_KIBANA_SERVER_IP:3000
```

Замените `YOUR_KIBANA_SERVER_IP` на реальный IP адрес (получите через `terraform output kibana_external_ip`).

### 2. Вход в систему

**Учетные данные по умолчанию:**
- **Логин:** `admin`
- **Пароль:** `admin` (или пароль, установленный при настройке)

При первом входе Grafana предложит изменить пароль - **обязательно измените!**

### 3. Проверка Data Source

После входа проверьте подключение к Prometheus:

1. В левом меню выберите **⚙️ Configuration** → **Data Sources**
2. Найдите **Prometheus** в списке
3. Нажмите на него
4. Прокрутите вниз и нажмите **Save & Test**
5. Должно появиться сообщение: **✅ Data source is working**

Если Data Source отсутствует, добавьте его:
1. Нажмите **Add data source**
2. Выберите **Prometheus**
3. Заполните:
   - **Name:** Prometheus
   - **URL:** http://localhost:9090
   - **Access:** Server (default)
4. Нажмите **Save & Test**

---

## 📥 ИМПОРТ ГОТОВЫХ ДАШБОРДОВ

### Дашборд: Node Exporter Full (ID: 1860)

Это самый популярный дашборд для мониторинга серверов с Node Exporter.

**Шаги импорта:**

1. В левом меню нажмите **➕** (плюс) → **Import**
2. В поле **Import via grafana.com** введите: `1860`
3. Нажмите **Load**
4. Настройте параметры:
   - **Name:** Node Exporter Full (можно оставить)
   - **Folder:** General (или создайте новую папку)
   - **Prometheus:** Выберите ваш Prometheus data source
5. Нажмите **Import**

**Что включает дашборд:**
- ✅ CPU Usage (по ядрам и общий)
- ✅ Memory Usage (детальная разбивка)
- ✅ Disk I/O (чтение/запись)
- ✅ Network Traffic (входящий/исходящий)
- ✅ System Load
- ✅ Disk Space
- ✅ Uptime
- ✅ И многое другое (40+ панелей)

### Другие рекомендуемые дашборды

#### 1. Node Exporter Server Metrics (ID: 405)
```
Import ID: 405
```
Упрощенная версия с основными метриками.

#### 2. Node Exporter for Prometheus Dashboard (ID: 11074)
```
Import ID: 11074
```
Современный дизайн с красивыми визуализациями.

#### 3. Prometheus 2.0 Stats (ID: 3662)
```
Import ID: 3662
```
Мониторинг самого Prometheus.

---

## 🎨 СОЗДАНИЕ СОБСТВЕННОГО ДАШБОРДА

### Шаг 1: Создание нового дашборда

1. В левом меню нажмите **➕** → **Dashboard**
2. Нажмите **Add visualization**
3. Выберите **Prometheus** как data source

### Шаг 2: Добавление панели CPU Usage

**Настройки панели:**

1. **Query:**
   ```promql
   100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
   ```

2. **Panel options:**
   - **Title:** CPU Usage
   - **Description:** CPU utilization percentage

3. **Standard options:**
   - **Unit:** Percent (0-100)
   - **Min:** 0
   - **Max:** 100

4. **Thresholds:**
   - **Green:** 0-70
   - **Yellow:** 70-85
   - **Red:** 85-100

5. **Visualization:** Time series (или Gauge для текущего значения)

6. Нажмите **Apply**

### Шаг 3: Добавление панели Memory Usage

1. Нажмите **Add** → **Visualization**
2. Выберите **Prometheus**

**Query:**
```promql
100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))
```

**Panel options:**
- **Title:** Memory Usage
- **Unit:** Percent (0-100)
- **Visualization:** Time series

### Шаг 4: Добавление панели Disk Usage

**Query:**
```promql
100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)
```

**Panel options:**
- **Title:** Disk Usage (Root)
- **Unit:** Percent (0-100)
- **Visualization:** Bar gauge (horizontal)

### Шаг 5: Добавление панели Network Traffic

**Query A (Receive):**
```promql
rate(node_network_receive_bytes_total{device!~"lo|veth.*"}[5m]) * 8 / 1000000
```

**Query B (Transmit):**
```promql
rate(node_network_transmit_bytes_total{device!~"lo|veth.*"}[5m]) * 8 / 1000000
```

**Panel options:**
- **Title:** Network Traffic
- **Unit:** Mbps
- **Visualization:** Time series
- **Legend:** {{instance}} - {{device}}

### Шаг 6: Сохранение дашборда

1. Нажмите **💾 Save dashboard** (иконка дискеты в правом верхнем углу)
2. Введите имя: **Web Servers Monitoring**
3. Выберите папку или создайте новую
4. Нажмите **Save**

---

## ⚙️ НАСТРОЙКА ПАНЕЛЕЙ

### Типы визуализаций

#### 1. Time Series (График)
**Использование:** Отображение метрик во времени  
**Подходит для:** CPU, Memory, Network, Disk I/O

**Настройки:**
- **Graph styles:** Lines, Bars, Points
- **Line width:** 1-3
- **Fill opacity:** 0-100%
- **Point size:** 1-10

#### 2. Gauge (Датчик)
**Использование:** Текущее значение метрики  
**Подходит для:** CPU Usage, Memory Usage, Disk Usage

**Настройки:**
- **Show threshold labels:** Yes
- **Show threshold markers:** Yes
- **Orientation:** Auto, Horizontal, Vertical

#### 3. Stat (Статистика)
**Использование:** Одно числовое значение  
**Подходит для:** Uptime, Total Memory, CPU Count

**Настройки:**
- **Text mode:** Auto, Value, Name
- **Color mode:** Value, Background
- **Graph mode:** None, Area

#### 4. Bar Gauge (Столбчатая диаграмма)
**Использование:** Сравнение значений  
**Подходит для:** Disk Usage по разделам, CPU по ядрам

**Настройки:**
- **Orientation:** Horizontal, Vertical
- **Display mode:** Basic, LCD, Gradient

#### 5. Table (Таблица)
**Использование:** Детальные данные  
**Подходит для:** Список серверов с метриками

**Настройки:**
- **Column width:** Auto, Fixed
- **Cell display mode:** Auto, Color text, Color background

### Переменные (Variables)

Переменные позволяют фильтровать данные на дашборде.

**Создание переменной для выбора сервера:**

1. Откройте дашборд
2. Нажмите **⚙️ Dashboard settings** → **Variables**
3. Нажмите **Add variable**
4. Заполните:
   - **Name:** `server`
   - **Type:** Query
   - **Data source:** Prometheus
   - **Query:** `label_values(node_cpu_seconds_total, instance)`
   - **Multi-value:** Yes
   - **Include All option:** Yes
5. Нажмите **Apply**

**Использование переменной в запросах:**
```promql
node_cpu_seconds_total{instance=~"$server"}
```

### Временные интервалы

**Настройка автообновления:**

1. В правом верхнем углу нажмите на иконку часов
2. Выберите временной диапазон: Last 5 minutes, Last 15 minutes, Last 1 hour, etc.
3. Включите автообновление: 5s, 10s, 30s, 1m, 5m
4. Нажмите **Apply**

**Рекомендуемые настройки:**
- **Для мониторинга в реальном времени:** Last 5 minutes, refresh 10s
- **Для анализа:** Last 1 hour, refresh 1m
- **Для отчетов:** Last 24 hours, refresh 5m

---

## 📊 РЕКОМЕНДУЕМЫЕ ДАШБОРДЫ

### Дашборд 1: Web Servers Overview

**Панели:**
1. **CPU Usage** (Time series) - все серверы на одном графике
2. **Memory Usage** (Time series) - все серверы
3. **Disk Usage** (Bar gauge) - по серверам
4. **Network Traffic** (Time series) - входящий/исходящий
5. **System Load** (Time series) - Load Average 1/5/15
6. **Uptime** (Stat) - время работы серверов

### Дашборд 2: Server Details

**Панели:**
1. **CPU Usage by Core** (Time series) - загрузка каждого ядра
2. **Memory Breakdown** (Time series) - Used/Buffers/Cached/Free
3. **Disk I/O** (Time series) - Read/Write operations
4. **Network Packets** (Time series) - Received/Transmitted
5. **Processes** (Stat) - Running/Blocked
6. **File Descriptors** (Gauge) - Open/Maximum

### Дашборд 3: Alerts Overview

**Панели:**
1. **High CPU Servers** (Table) - серверы с CPU > 80%
2. **Low Memory Servers** (Table) - серверы с Memory > 90%
3. **Full Disks** (Table) - диски заполнены > 90%
4. **Down Nodes** (Stat) - количество недоступных серверов

---

## 🔧 TROUBLESHOOTING

### Проблема: "No data" в панелях

**Решение:**

1. Проверьте Data Source:
   ```
   Configuration → Data Sources → Prometheus → Test
   ```

2. Проверьте Prometheus targets:
   ```
   http://YOUR_KIBANA_SERVER_IP:9090/targets
   ```
   Все targets должны быть в состоянии "UP"

3. Проверьте PromQL запрос:
   - Откройте Prometheus Graph
   - Выполните запрос вручную
   - Убедитесь, что данные возвращаются

4. Проверьте временной диапазон:
   - Убедитесь, что выбран правильный период
   - Попробуйте "Last 5 minutes"

### Проблема: Медленная загрузка дашборда

**Решение:**

1. Уменьшите количество панелей на дашборде
2. Увеличьте интервал обновления (refresh interval)
3. Используйте более короткие временные диапазоны
4. Оптимизируйте PromQL запросы (используйте `rate()` вместо `irate()` для долгих периодов)

### Проблема: Ошибка "Unauthorized"

**Решение:**

1. Проверьте, что вы вошли в Grafana
2. Проверьте права доступа к дашборду
3. Проверьте настройки Data Source (должен быть Server access, не Browser)

### Проблема: Дашборд не сохраняется

**Решение:**

1. Проверьте права доступа (нужна роль Editor или Admin)
2. Проверьте, что дашборд не в режиме "View only"
3. Попробуйте "Save As" вместо "Save"

---

## 📚 ДОПОЛНИТЕЛЬНЫЕ РЕСУРСЫ

- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Grafana Dashboards Library](https://grafana.com/grafana/dashboards/)
- [PromQL Queries Guide](PROMQL_QUERIES.md)
- [Access Guide](ACCESS_GUIDE.md)

---

## 🎯 СЛЕДУЮЩИЕ ШАГИ

1. ✅ Импортируйте дашборд Node Exporter Full (ID: 1860)
2. ✅ Создайте собственный дашборд для веб-серверов
3. ✅ Настройте переменные для фильтрации серверов
4. ✅ Настройте автообновление дашбордов
5. ✅ Создайте алерты для критических метрик (опционально)
6. ✅ Сделайте скриншоты для документации

---

*Документ обновлен: 04.10.2025*

