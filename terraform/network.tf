# -------------------------------------------------------
# VPC
# -------------------------------------------------------
resource "yandex_vpc_network" "main" {
  name = "main-network"
}

# -------------------------------------------------------
# Публичная подсеть — для Bastion, Grafana, Kibana, ALB
# -------------------------------------------------------
resource "yandex_vpc_subnet" "public" {
  name           = "public-subnet"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# -------------------------------------------------------
# Приватные подсети — для web, Prometheus, Elasticsearch
# Две зоны для отказоустойчивости веб-серверов
# -------------------------------------------------------
resource "yandex_vpc_subnet" "private_b" {
  name           = "private-subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.nat_route.id
}

resource "yandex_vpc_subnet" "private_d" {
  name           = "private-subnet-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.30.0/24"]
  route_table_id = yandex_vpc_route_table.nat_route.id
}

# -------------------------------------------------------
# NAT-шлюз — чтобы приватные ВМ могли выходить в интернет
# (для установки пакетов через Ansible)
# -------------------------------------------------------
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "nat_route" {
  name       = "nat-route-table"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}
