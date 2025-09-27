terraform {
  required_version = ">= 1.0"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.84"
    }
  }
}

# Конфигурация провайдера Yandex Cloud
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.default_zone
}

# Зоны доступности определены в локальных переменных

# Получение образа Ubuntu 20.04 LTS
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2004-lts"
}

# Локальные переменные
locals {
  network_name = "diplom-network"
  zones = ["ru-central1-a", "ru-central1-b", "ru-central1-c"]
}