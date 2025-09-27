# Certificate Manager для HTTPS (временно отключен из-за проблем с провайдером)
# resource "yandex_cm_certificate" "web_certificate" {
#   name    = "web-certificate"
#   domains = ["${var.domain_name}", "www.${var.domain_name}"]
#
#   managed {
#     challenge_type = "DNS_CNAME"
#   }
#
#   labels = {
#     environment = "production"
#     service     = "web"
#   }
# }

# Дополнительные переменные для сертификата определены в variables.tf

# Условное создание HTTPS listener для ALB
resource "yandex_alb_virtual_host" "web_virtual_host_https" {
  count          = var.enable_https ? 1 : 0
  name           = "web-virtual-host-https"
  http_router_id = yandex_alb_http_router.web_router.id

  route {
    name = "web-route-https"

    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_backend_group.id
        timeout          = "60s"
      }
    }
  }
}

# Output для Certificate Manager (временно отключен)
# output "certificate_id" {
#   description = "Certificate ID for HTTPS"
#   value       = var.enable_https ? yandex_cm_certificate.web_certificate.id : null
# }

output "certificate_status" {
  description = "Certificate status"
  value       = "disabled"
}