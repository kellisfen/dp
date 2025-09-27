# Target Group для веб-серверов
resource "yandex_alb_target_group" "web_target_group" {
  name = "web-target-group"

  target {
    subnet_id  = yandex_vpc_subnet.private_subnet_a.id
    ip_address = yandex_compute_instance.web1.network_interface.0.ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.private_subnet_b.id
    ip_address = yandex_compute_instance.web2.network_interface.0.ip_address
  }
}

# Backend Group
resource "yandex_alb_backend_group" "web_backend_group" {
  name = "web-backend-group"

  http_backend {
    name             = "web-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web_target_group.id]

    load_balancing_config {
      panic_threshold = 50
    }

    healthcheck {
      timeout             = "10s"
      interval            = "2s"
      healthy_threshold   = 10
      unhealthy_threshold = 15

      http_healthcheck {
        path = "/"
      }
    }
  }
}

# HTTP Router
resource "yandex_alb_http_router" "web_router" {
  name = "web-router"
}

# Virtual Host
resource "yandex_alb_virtual_host" "web_virtual_host" {
  name           = "web-virtual-host"
  http_router_id = yandex_alb_http_router.web_router.id

  route {
    name = "web-route"

    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_backend_group.id
        timeout          = "60s"
      }
    }
  }
}

# Application Load Balancer
resource "yandex_alb_load_balancer" "web_load_balancer" {
  name               = "web-load-balancer"
  network_id         = yandex_vpc_network.diplom_network.id
  security_group_ids = [yandex_vpc_security_group.alb_sg.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public_subnet.id
    }
  }

  listener {
    name = "web-listener-http"

    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }

    http {
      handler {
        http_router_id = yandex_alb_http_router.web_router.id
      }
    }
  }

  # HTTPS listener (условный)
  dynamic "listener" {
    for_each = var.enable_https ? [1] : []
    content {
      name = "web-listener-https"

      endpoint {
        address {
          external_ipv4_address {
          }
        }
        ports = [443]
      }

      tls {
        default_handler {
          certificate_ids = [yandex_cm_certificate.web_certificate.id]
          http_handler {
            http_router_id = yandex_alb_http_router.web_router.id
          }
        }
      }
    }
  }
}