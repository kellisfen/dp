# Создание VPC
resource "yandex_vpc_network" "diplom_network" {
  name        = local.network_name
  description = "Network for diplom project"
}

# Публичная подсеть для bastion, zabbix, kibana, load balancer
resource "yandex_vpc_subnet" "public_subnet" {
  name           = "public-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom_network.id
  v4_cidr_blocks = ["10.0.1.0/24"]
  description    = "Public subnet for bastion, zabbix, kibana"
}

# Приватная подсеть для веб-серверов зона A
resource "yandex_vpc_subnet" "private_subnet_a" {
  name           = "private-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom_network.id
  v4_cidr_blocks = ["10.0.2.0/24"]
  route_table_id = yandex_vpc_route_table.private_route_table.id
  description    = "Private subnet for web servers zone A"
}

# Приватная подсеть для веб-серверов зона B
resource "yandex_vpc_subnet" "private_subnet_b" {
  name           = "private-subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.diplom_network.id
  v4_cidr_blocks = ["10.0.3.0/24"]
  route_table_id = yandex_vpc_route_table.private_route_table.id
  description    = "Private subnet for web servers zone B"
}

# Приватная подсеть для Elasticsearch
resource "yandex_vpc_subnet" "private_subnet_elastic" {
  name           = "private-subnet-elastic"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.diplom_network.id
  v4_cidr_blocks = ["10.0.4.0/24"]
  route_table_id = yandex_vpc_route_table.private_route_table.id
  description    = "Private subnet for Elasticsearch"
}

# NAT Gateway для исходящего трафика из приватных подсетей
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "diplom-nat-gateway"
  shared_egress_gateway {}
}

# Таблица маршрутизации для приватных подсетей
resource "yandex_vpc_route_table" "private_route_table" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.diplom_network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

# Привязка таблицы маршрутизации к приватным подсетям
# Обновляем существующие подсети для добавления маршрутизации