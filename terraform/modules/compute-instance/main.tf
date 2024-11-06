locals {
#   k8s_version = "1.29" 
#   sa_name     = "sa-k8s-adm"
}

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

resource "yandex_compute_disk" "boot-disk" {
  name     = var.boot_disk_name
  type     = var.boot_disk_type
  zone     = var.default_zone
  size     = var.boot_disk_type
  image_id = "fd83h72fb5urnmt6vkfd"
}

resource "yandex_compute_instance" "selfhosted-apps" {
  name                      = "selfhosted-apps-vm"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = var.default_zone

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk.id
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
    ssh-keys = "<имя_пользователя>:<содержимое_SSH-ключа>"
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "<зона_доступности>"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id     = "${yandex_vpc_network.network-1.id}"
}
