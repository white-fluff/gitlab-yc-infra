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

# ==== Boot Disk vars ==== #
variable "boot_disk_name" {
  description = "Boot disk name"
  type        = string
  default     = ""
}

variable "boot_disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "network-ssd"
}

variable "boot_disk_size" {
  description = "Boot disk size"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
  default     = ""
}