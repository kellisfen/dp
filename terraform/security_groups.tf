# Security Group для Bastion Host
resource "yandex_vpc_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  network_id  = yandex_vpc_network.diplom_network.id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    description    = "All outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для веб-серверов
resource "yandex_vpc_security_group" "web_sg" {
  name        = "web-sg"
  description = "Security group for web servers"
  network_id  = yandex_vpc_network.diplom_network.id

  ingress {
    protocol          = "TCP"
    description       = "SSH from bastion"
    security_group_id = yandex_vpc_security_group.bastion_sg.id
    port              = 22
  }

  ingress {
    protocol          = "TCP"
    description       = "HTTP from load balancer"
    security_group_id = yandex_vpc_security_group.alb_sg.id
    port              = 80
  }

  ingress {
    protocol          = "TCP"
    description       = "Zabbix agent"
    security_group_id = yandex_vpc_security_group.zabbix_sg.id
    port              = 10050
  }

  ingress {
    protocol          = "TCP"
    description       = "Node Exporter from Kibana"
    security_group_id = yandex_vpc_security_group.kibana_sg.id
    port              = 9100
  }

  egress {
    protocol       = "ANY"
    description    = "All outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для Zabbix
resource "yandex_vpc_security_group" "zabbix_sg" {
  name        = "zabbix-sg"
  description = "Security group for Zabbix server"
  network_id  = yandex_vpc_network.diplom_network.id

  ingress {
    protocol          = "TCP"
    description       = "SSH from bastion"
    security_group_id = yandex_vpc_security_group.bastion_sg.id
    port              = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "Zabbix web interface"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "Zabbix server"
    v4_cidr_blocks = ["10.0.0.0/8"]
    port           = 10051
  }

  egress {
    protocol       = "ANY"
    description    = "All outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для Elasticsearch
resource "yandex_vpc_security_group" "elasticsearch_sg" {
  name        = "elasticsearch-sg"
  description = "Security group for Elasticsearch"
  network_id  = yandex_vpc_network.diplom_network.id

  ingress {
    protocol          = "TCP"
    description       = "SSH from bastion"
    security_group_id = yandex_vpc_security_group.bastion_sg.id
    port              = 22
  }

  ingress {
    protocol          = "TCP"
    description       = "Elasticsearch API from Kibana"
    security_group_id = yandex_vpc_security_group.kibana_sg.id
    port              = 9200
  }

  ingress {
    protocol          = "TCP"
    description       = "Elasticsearch API from web servers"
    security_group_id = yandex_vpc_security_group.web_sg.id
    port              = 9200
  }

  ingress {
    protocol       = "TCP"
    description    = "Beats input"
    v4_cidr_blocks = ["10.0.0.0/8"]
    port           = 5044
  }

  egress {
    protocol       = "ANY"
    description    = "All outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для Kibana
resource "yandex_vpc_security_group" "kibana_sg" {
  name        = "kibana-sg"
  description = "Security group for Kibana"
  network_id  = yandex_vpc_network.diplom_network.id

  ingress {
    protocol          = "TCP"
    description       = "SSH from bastion"
    security_group_id = yandex_vpc_security_group.bastion_sg.id
    port              = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "Kibana web interface"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  ingress {
    protocol       = "TCP"
    description    = "Grafana web interface"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 3000
  }

  ingress {
    protocol       = "TCP"
    description    = "Prometheus web interface"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 9090
  }

  egress {
    protocol       = "ANY"
    description    = "All outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для Application Load Balancer
resource "yandex_vpc_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for Application Load Balancer"
  network_id  = yandex_vpc_network.diplom_network.id

  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol       = "TCP"
    description    = "Health checks"
    v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"]
    port           = 30080
  }

  egress {
    protocol       = "ANY"
    description    = "All outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}