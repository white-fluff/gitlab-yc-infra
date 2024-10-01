locals {

  k8s_version = "1.29" 
  sa_name     = "sa-k8s-adm"
}

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

# Creating service account for Kubernetes cluster
resource "yandex_iam_service_account" "sa-k8s-admin" {
  name        = local.sa_name
  description = "K8S service account – terraform"
}

# Adding roles for a service account
resource "yandex_resourcemanager_folder_iam_member" "editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa-k8s-admin.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s-clusters-agent" {
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.sa-k8s-admin.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "vpc-public-admin" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.sa-k8s-admin.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "images-puller" { 
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.sa-k8s-admin.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "certificates-downloader" {
  folder_id = var.folder_id
  role      = "certificate-manager.certificates.downloader"
  member    = "serviceAccount:${yandex_iam_service_account.sa-k8s-admin.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "load-balancer-admin" {  
  folder_id = var.folder_id
  role      = "load-balancer.admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa-k8s-admin.id}"
}

# Create a key to encrypt important information such as passwords, OAuth tokens, and SSH keys.
resource "yandex_kms_symmetric_key" "kms-key" {
  name              = "kms-key"
  default_algorithm = "AES_128"
  rotation_period   = "8760h" # 1 year.
}

# Creating VPC
resource "yandex_vpc_network" "k8s-network" {
  name = "k8s-network"
}

# Creating subnet
resource "yandex_vpc_subnet" "k8s-subnet" {
  v4_cidr_blocks = ["10.123.0.0/16"]
  zone           = var.default_zone
  network_id     = yandex_vpc_network.k8s-network.id
}

resource "yandex_vpc_security_group" "k8s-main-sg" {
  name        = "k8s-main-sg"
  description = "Правила группы обеспечивают базовую работоспособность кластера. Примените ее к кластеру и группам узлов."
  network_id  = yandex_vpc_network.k8s-network.id
  
  ingress {
    protocol          = "TCP"
    description       = "Правило разрешает проверки доступности с диапазона адресов балансировщика нагрузки. Нужно для работы отказоустойчивого кластера и сервисов балансировщика."
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ANY"
    description       = "Правило разрешает взаимодействие мастер-узел и узел-узел внутри группы безопасности."
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ANY"
    description       = "Правило разрешает взаимодействие под-под и сервис-сервис. Укажите подсети вашего кластера и сервисов."
    v4_cidr_blocks    = concat(yandex_vpc_subnet.k8s-subnet.v4_cidr_blocks)
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ICMP"
    description       = "Правило разрешает отладочные ICMP-пакеты из внутренних подсетей."
    v4_cidr_blocks    = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
  egress {
    protocol          = "ANY"
    description       = "Правило разрешает весь исходящий трафик. Узлы могут связаться с Yandex Container Registry, Yandex Object Storage, Docker Hub и т. д."
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 65535
  }
}

resource "yandex_vpc_security_group" "k8s-public-services" {
  name        = "k8s-public-services"
  description = "Правила группы разрешают подключение к сервисам из интернета. Примените правила только для групп узлов."
  network_id  = yandex_vpc_network.k8s-network.id

  ingress {
    protocol          = "TCP"
    description       = "Правило разрешает входящий трафик из интернета на диапазон портов NodePort. Добавьте или измените порты на нужные вам."
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 30000
    to_port           = 32767
  }
}

resource "yandex_vpc_security_group" "k8s-master-whitelist" {
  name        = "k8s-master-whitelist"
  description = "Правила группы разрешают доступ к API Kubernetes из интернета. Примените правила только к кластеру."
  network_id  = yandex_vpc_network.k8s-network.id

  ingress {
    protocol          = "TCP"
    description       = "Правило для доступа к API Kubernetes и HTTPS по порту 443"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    port              = 443
  }
  ingress {
    protocol          = "TCP"
    description       = "Правило для доступа к API Kubernetes по порту 6443"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    port              = 6443
  }
}

# If you need to access the cluster hosts directly via SSH, uncomment and change this block
/* 

resource "yandex_vpc_security_group" "k8s-nodes-ssh-access" {
  name        = "k8s-nodes-ssh-access"
  description = "Правила группы разрешают подключение к узлам кластера по SSH. Примените правила только для групп узлов."
  network_id  = yandex_vpc_network.k8s-network.id

  ingress {
    protocol       = "TCP"
    description    = "Правило разрешает подключение к узлам по SSH с указанных IP-адресов."
    v4_cidr_blocks = ["85.32.32.22/32"]
    port           = 22
  }
}

*/

# Creating Kubernetes cluster
resource "yandex_kubernetes_cluster" "k8s-cluster-zonal" {
  name = "my-cluster"
  release_channel = "STABLE"
  
  network_id = yandex_vpc_network.k8s-network.id

  master {
    version = local.k8s_version
    security_group_ids = [
      yandex_vpc_security_group.k8s-main-sg.id,
      yandex_vpc_security_group.k8s-master-whitelist.id
      ]
    
    public_ip = true

    zonal {
      zone      = yandex_vpc_subnet.k8s-subnet.zone
      subnet_id = yandex_vpc_subnet.k8s-subnet.id
    }
  }

  service_account_id      = yandex_iam_service_account.sa-k8s-admin.id
  node_service_account_id = yandex_iam_service_account.sa-k8s-admin.id
  
  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s-clusters-agent,
    yandex_resourcemanager_folder_iam_member.vpc-public-admin,
    yandex_resourcemanager_folder_iam_member.images-puller
  ]

  kms_provider {
    key_id = yandex_kms_symmetric_key.kms-key.id
  }
}

# Creating Node Group
resource "yandex_kubernetes_node_group" "node_group_worker" {
  cluster_id  = yandex_kubernetes_cluster.k8s-cluster-zonal.id
  name        = "worker"
  version     = local.k8s_version
  instance_template {
    platform_id = "standard-v1"
    name        = "worker-{instance.short_id}"
    network_interface {
      nat                = true
      subnet_ids         = [yandex_vpc_subnet.k8s-subnet.id]
      security_group_ids = [
        yandex_vpc_security_group.k8s-main-sg.id,
        yandex_vpc_security_group.k8s-public-services.id 
      ]
    metadata = {
      ssh-keys = "k8s-adm:${file("/tmp/ssh_node_key.pub")}"
    }
    } 
    resources {
      memory = 4
      cores  = 2
    }

    boot_disk {
      type = "network-ssd"
      size = 30
    }

    scheduling_policy {
      preemptible = false
    }
  }
 
  scale_policy {
    auto_scale {
      min     = 1
      max     = 3
      initial = 2
    }
  }
  
  allocation_policy {
    location {
      zone = var.default_zone
    }
  }
}
