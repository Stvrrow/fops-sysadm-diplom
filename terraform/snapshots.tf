# -------------------------------------------------------
# Расписание снапшотов — ежедневно, хранить 7 дней
# -------------------------------------------------------
resource "yandex_compute_snapshot_schedule" "daily_backup" {
  name = "daily-snapshot-schedule"

  # Каждый день в 03:00 UTC
  schedule_policy {
    expression = "0 3 * * *"
  }

  # Хранить последние 7 снапшотов (= 1 неделя)
  retention_period = "168h"

  snapshot_spec {
    description = "auto-daily-snapshot"
  }

  disk_ids = [
    yandex_compute_instance.bastion.boot_disk[0].disk_id,
    yandex_compute_instance.web1.boot_disk[0].disk_id,
    yandex_compute_instance.web2.boot_disk[0].disk_id,
    yandex_compute_instance.prometheus.boot_disk[0].disk_id,
    yandex_compute_instance.grafana.boot_disk[0].disk_id,
    yandex_compute_instance.elasticsearch.boot_disk[0].disk_id,
    yandex_compute_instance.kibana.boot_disk[0].disk_id,
  ]
}
