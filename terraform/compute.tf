locals {
  ssh_keys = "ubuntu:${file(var.ssh_public_key_path)}"
}

# -------------------------------------------------------
# Bastion Host — единственная ВМ с публичным IP и SSH
# -------------------------------------------------------
resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  platform_id = "standard-v2"
  zone        = "ru-central1-b"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu_image_id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion.id]
  }

  metadata = {
    ssh-keys = local.ssh_keys
  }

  scheduling_policy {
    preemptible = true
  }
}

# -------------------------------------------------------
# Web-сервер 1 — зона ru-central1-b, приватная подсеть
# -------------------------------------------------------
resource "yandex_compute_instance" "web1" {
  name        = "web1"
  platform_id = "standard-v2"
  zone        = "ru-central1-b"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu_image_id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_b.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.web.id, yandex_vpc_security_group.internal_ssh.id]
  }

  metadata = {
    ssh-keys = local.ssh_keys
  }

  scheduling_policy {
    preemptible = true
  }
}

# -------------------------------------------------------
# Web-сервер 2 — зона ru-central1-d, приватная подсеть
# -------------------------------------------------------
resource "yandex_compute_instance" "web2" {
  name        = "web2"
  platform_id = "standard-v2"
  zone        = "ru-central1-d"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu_image_id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_d.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.web.id, yandex_vpc_security_group.internal_ssh.id]
  }

  metadata = {
    ssh-keys = local.ssh_keys
  }

  scheduling_policy {
    preemptible = true
  }
}

# -------------------------------------------------------
# Prometheus — приватная подсеть
# -------------------------------------------------------
resource "yandex_compute_instance" "prometheus" {
  name        = "prometheus"
  platform_id = "standard-v2"
  zone        = "ru-central1-b"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu_image_id
      size     = 15
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_b.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.prometheus.id, yandex_vpc_security_group.internal_ssh.id]
  }

  metadata = {
    ssh-keys = local.ssh_keys
  }

  scheduling_policy {
    preemptible = true
  }
}

# -------------------------------------------------------
# Grafana — публичная подсеть
# -------------------------------------------------------
resource "yandex_compute_instance" "grafana" {
  name        = "grafana"
  platform_id = "standard-v2"
  zone        = "ru-central1-b"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu_image_id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.grafana.id, yandex_vpc_security_group.internal_ssh.id]
  }

  metadata = {
    ssh-keys = local.ssh_keys
  }

  scheduling_policy {
    preemptible = true
  }
}

# -------------------------------------------------------
# Elasticsearch — приватная подсеть
# -------------------------------------------------------
resource "yandex_compute_instance" "elasticsearch" {
  name        = "elasticsearch"
  platform_id = "standard-v2"
  zone        = "ru-central1-b"

  resources {
    cores         = 2
    memory        = 8
    core_fraction = 50
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu_image_id
      size     = 30
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_b.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.elasticsearch.id, yandex_vpc_security_group.internal_ssh.id]
  }

  metadata = {
    ssh-keys = local.ssh_keys
  }

  scheduling_policy {
    preemptible = true
  }
}

# -------------------------------------------------------
# Kibana — публичная подсеть (нужен доступ из браузера)
# -------------------------------------------------------
resource "yandex_compute_instance" "kibana" {
  name        = "kibana"
  platform_id = "standard-v2"
  zone        = "ru-central1-b"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu_image_id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.kibana.id, yandex_vpc_security_group.internal_ssh.id]
  }

  metadata = {
    ssh-keys = local.ssh_keys
  }

  scheduling_policy {
    preemptible = true
  }
}
