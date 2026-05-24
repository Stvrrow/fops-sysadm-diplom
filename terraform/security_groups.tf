# -------------------------------------------------------
# Security Group: Bastion
# Единственная ВМ с публичным SSH (порт 22)
# -------------------------------------------------------
resource "yandex_vpc_security_group" "bastion" {
  name        = "sg-bastion"
  description = "Bastion host — only SSH from internet"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "SSH from anywhere"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------------------------------
# Security Group: внутренний трафик
# Все ВМ принимают SSH от Bastion и любой трафик внутри VPC
# -------------------------------------------------------
resource "yandex_vpc_security_group" "internal_ssh" {
  name        = "sg-internal-ssh"
  description = "Allow SSH from Bastion and all internal VPC traffic"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol          = "TCP"
    description       = "SSH from Bastion SG"
    security_group_id = yandex_vpc_security_group.bastion.id
    port              = 22
  }

  ingress {
    protocol       = "ANY"
    description    = "Allow all internal VPC traffic"
    v4_cidr_blocks = ["192.168.0.0/16"]
    from_port      = 0
    to_port        = 65535
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------------------------------
# Security Group: Web-серверы (nginx)
# -------------------------------------------------------
resource "yandex_vpc_security_group" "web" {
  name        = "sg-web"
  description = "Web servers — nginx"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol          = "TCP"
    description       = "HTTP from ALB"
    security_group_id = yandex_vpc_security_group.alb.id
    port              = 80
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------------------------------
# Security Group: Prometheus
# -------------------------------------------------------
resource "yandex_vpc_security_group" "prometheus" {
  name        = "sg-prometheus"
  description = "Prometheus server"
  network_id  = yandex_vpc_network.main.id

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound (scraping exporters)"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------------------------------
# Security Group: Grafana
# -------------------------------------------------------
resource "yandex_vpc_security_group" "grafana" {
  name        = "sg-grafana"
  description = "Grafana — public web UI"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "Grafana UI from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 3000
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------------------------------
# Security Group: Elasticsearch
# -------------------------------------------------------
resource "yandex_vpc_security_group" "elasticsearch" {
  name        = "sg-elasticsearch"
  description = "Elasticsearch — only from internal network"
  network_id  = yandex_vpc_network.main.id

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------------------------------
# Security Group: Kibana
# -------------------------------------------------------
resource "yandex_vpc_security_group" "kibana" {
  name        = "sg-kibana"
  description = "Kibana — public web UI"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "Kibana UI from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------------------------------
# Security Group: ALB (Application Load Balancer)
# -------------------------------------------------------
resource "yandex_vpc_security_group" "alb" {
  name        = "sg-alb"
  description = "Application Load Balancer"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "HTTP from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "ALB healthcheck probes"
    v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"]
    from_port      = 0
    to_port        = 65535
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
