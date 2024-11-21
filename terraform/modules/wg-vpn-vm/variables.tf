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

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
  default     = ""
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
  default     = 10737418240
}

variable "boot_disk_image_id" {
  description = "Boot disk image ID"
  type        = string
  default     = "fd86idv7gmqapoeiq5ld"  # ubuntu-24-04-lts-v20241118
}
