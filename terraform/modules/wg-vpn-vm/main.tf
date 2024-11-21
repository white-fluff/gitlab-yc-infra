terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

resource "yandex_compute_disk" "boot-disk" {
  name     = "wireguard-boot-disk"
  type     = var.boot_disk_type
  zone     = var.default_zone
  size     = var.boot_disk_size
  image_id = var.boot_disk_image_id
}

resource "yandex_compute_instance" "wireguard" {
  name                      = "wireguard-vm"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = var.default_zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk.id
  }

  network_interface {
    subnet_id          = var.subnet_id
    nat                = true
    nat_ip_address     = var.static_ip_address
    security_group_ids = var.security_group_ids
  }

  metadata = {
    ssh-keys = "wg-user:${"~/.ssh/own-yc-key"}"
  }
}
