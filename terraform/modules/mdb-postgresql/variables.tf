variable "default_zone" {
  description = "Default accessibility zone"
  type        = string
  default     = ""
}

variable "folder_id" {
  description = "Default folder id"
  type        = string
  default     = ""
}

variable "network_id" {
  description = "Network id for cluster"
  type        = string
  default     = "enpk9ovmha0tqdhhka39"
}

variable "subnet_id" {
  description = "Subnet id for host"
  type        = string
  default     = "e2lpgdg7bkt1jcevim8d"
}

variable "security_group_ids" {
  description = "SG id for cluster"
  type        = string
  default     = "enp2l5k12mafr81j7754"
}

# variable "pg_user_konst_password" {
#     description = "My PG password"
#     type        = string
# }