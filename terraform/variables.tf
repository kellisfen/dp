variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  default     = "b1gacd76ggtuvbh46emd"
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
  default     = "b1g2k7uoqgh74u5ddj31"
}

variable "service_account_key_file" {
  description = "Path to service account key file"
  type        = string
  default     = "../authorized_key.json"
}

variable "default_zone" {
  description = "Default availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "vm_user" {
  description = "Default user for VMs"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "domain_name" {
  description = "Domain name for the project"
  type        = string
  default     = "ru-central1.internal"
}

variable "enable_https" {
  description = "Enable HTTPS with Certificate Manager"
  type        = bool
  default     = false
}