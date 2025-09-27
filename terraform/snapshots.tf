# Snapshot schedule для всех дисков
resource "yandex_compute_snapshot_schedule" "daily_snapshots" {
  name = "daily-snapshots"

  schedule_policy {
    expression = "0 2 * * *" # Каждый день в 2:00
  }

  snapshot_count = 7 # Хранить 7 снапшотов (неделя)

  snapshot_spec {
    description = "Daily snapshot"
    labels = {
      environment = "diplom"
      type        = "daily-backup"
    }
  }

  disk_ids = [
    yandex_compute_instance.bastion.boot_disk.0.disk_id,
    yandex_compute_instance.web1.boot_disk.0.disk_id,
    yandex_compute_instance.web2.boot_disk.0.disk_id,
    yandex_compute_instance.zabbix.boot_disk.0.disk_id,
    yandex_compute_instance.elasticsearch.boot_disk.0.disk_id,
    yandex_compute_instance.kibana.boot_disk.0.disk_id,
  ]
}