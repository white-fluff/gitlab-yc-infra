terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }

  required_version = ">= 0.128.0"

  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    bucket = "tf-service-bucket"
    region = "ru-central1"
    key    = "infra.tfstate"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true

    dynamodb_endpoint = "https://docapi.serverless.yandexcloud.net/ru-central1/b1g02u7oe05n4bt41qpi/etnh0gd932lqlgnqci28"
    dynamodb_table = "tf_lock"
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

# Add k8s module
module "k8s-cluster" {
  source         = "./modules/k8s-cluster"
  default_zone   = var.zone
  folder_id      = var.folder_id
}

# module "compute-instance" {
#   source         = "./modules/compute-instance"
#   default_zone   = var.zone
#   folder_id      = var.folder_id
# }