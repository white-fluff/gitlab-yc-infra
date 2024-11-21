variable "default_zone" {
  description = "Default accessibility zone"
  type        = string
  default     = ""
}

variable "folder_id" {
  description = "Default accessibility zone"
  type        = string
  default     = ""
}

# ==== Network Interface vars ==== #
variable "subnet_id" {
  description = "Subnet ID"
  type        = string
  default     = "e2lpgdg7bkt1jcevim8d"
}

variable "security_group_ids" {
  description = "Security group ids"
  type        = set(string)
  default     = ["enpp72203p4k5vat9hvn"]
}

variable "static_ip_address" {
  description = "Static IP-address ID"
  type        = string
  default     = "e2lksodlkglh0kosrdi0"
}

# ==== Boot Disk vars ==== #
variable "boot_disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "network-ssd"
}

variable "boot_disk_size" {
  description = "Boot disk size"
  type        = number
  default     = 10
}

variable "boot_disk_image_id" {
  description = "Boot disk image ID"
  type        = string
  default     = "fd86idv7gmqapoeiq5ld"  # ubuntu-24-04-lts-v20241118
}
