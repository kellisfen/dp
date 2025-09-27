output "bastion_external_ip" {
  description = "External IP address of bastion host"
  value       = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

output "load_balancer_external_ip" {
  description = "External IP address of load balancer"
  value       = yandex_alb_load_balancer.web_load_balancer.listener.0.endpoint.0.address.0.external_ipv4_address.0.address
}

output "zabbix_external_ip" {
  description = "External IP address of Zabbix server"
  value       = yandex_compute_instance.zabbix.network_interface.0.nat_ip_address
}

output "kibana_external_ip" {
  description = "External IP address of Kibana server"
  value       = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}

output "web1_internal_ip" {
  description = "Internal IP address of web server 1"
  value       = yandex_compute_instance.web1.network_interface.0.ip_address
}

output "web2_internal_ip" {
  description = "Internal IP address of web server 2"
  value       = yandex_compute_instance.web2.network_interface.0.ip_address
}

output "elasticsearch_internal_ip" {
  description = "Internal IP address of Elasticsearch server"
  value       = yandex_compute_instance.elasticsearch.network_interface.0.ip_address
}

output "kibana_internal_ip" {
  description = "Internal IP address of Kibana server"
  value       = yandex_compute_instance.kibana.network_interface.0.ip_address
}

output "ssh_private_key" {
  description = "SSH private key for accessing VMs"
  value       = tls_private_key.ssh_key.private_key_pem
  sensitive   = true
}

output "ansible_inventory" {
  description = "Ansible inventory information"
  value = {
    bastion = {
      ansible_host = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
      ansible_user = var.vm_user
    }
    web_servers = {
      web1 = {
        ansible_host = "${yandex_compute_instance.web1.name}.${var.domain_name}"
        ansible_user = var.vm_user
        internal_ip  = yandex_compute_instance.web1.network_interface.0.ip_address
      }
      web2 = {
        ansible_host = "${yandex_compute_instance.web2.name}.${var.domain_name}"
        ansible_user = var.vm_user
        internal_ip  = yandex_compute_instance.web2.network_interface.0.ip_address
      }
    }
    monitoring = {
      zabbix = {
        ansible_host = yandex_compute_instance.zabbix.network_interface.0.nat_ip_address
        ansible_user = var.vm_user
        internal_ip  = yandex_compute_instance.zabbix.network_interface.0.ip_address
      }
    }
    logging = {
      elasticsearch = {
        ansible_host = "${yandex_compute_instance.elasticsearch.name}.${var.domain_name}"
        ansible_user = var.vm_user
        internal_ip  = yandex_compute_instance.elasticsearch.network_interface.0.ip_address
      }
      kibana = {
        ansible_host = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
        ansible_user = var.vm_user
        internal_ip  = yandex_compute_instance.kibana.network_interface.0.ip_address
      }
    }
  }
}