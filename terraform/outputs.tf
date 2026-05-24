# -------------------------------------------------------
# Публичные адреса (для подключения и тестирования)
# -------------------------------------------------------
output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
}

output "grafana_public_ip" {
  description = "Grafana public IP"
  value       = yandex_compute_instance.grafana.network_interface[0].nat_ip_address
}

output "kibana_public_ip" {
  description = "Kibana public IP"
  value       = yandex_compute_instance.kibana.network_interface[0].nat_ip_address
}

output "alb_public_ip" {
  description = "ALB public IP"
  value       = yandex_alb_load_balancer.web_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

# -------------------------------------------------------
# Приватные адреса (для Ansible inventory)
# -------------------------------------------------------
output "web1_private_ip" {
  description = "Web1 private IP"
  value       = yandex_compute_instance.web1.network_interface[0].ip_address
}

output "web2_private_ip" {
  description = "Web2 private IP"
  value       = yandex_compute_instance.web2.network_interface[0].ip_address
}

output "prometheus_private_ip" {
  description = "Prometheus private IP"
  value       = yandex_compute_instance.prometheus.network_interface[0].ip_address
}

output "grafana_private_ip" {
  description = "Grafana private IP"
  value       = yandex_compute_instance.grafana.network_interface[0].ip_address
}

output "elasticsearch_private_ip" {
  description = "Elasticsearch private IP"
  value       = yandex_compute_instance.elasticsearch.network_interface[0].ip_address
}

output "kibana_private_ip" {
  description = "Kibana private IP"
  value       = yandex_compute_instance.kibana.network_interface[0].ip_address
}
