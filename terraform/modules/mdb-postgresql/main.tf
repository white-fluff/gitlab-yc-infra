locals {
    pg_version = "15"
    host_type = "s3-c2-m8"
    dick_type = "network-ssd"
    disk_size = 10
}

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

resource "yandex_mdb_postgresql_cluster" "postgresql-cluster" {
  name        = "postgresql-cluster"
  environment = "PRODUCTION"
  network_id  = var.network_id
  security_group_ids = [var.security_group_ids]

  config {
    version = local.pg_version
    resources {
      resource_preset_id = local.host_type
      disk_type_id       = local.dick_type
      disk_size          = local.disk_size
    }

    postgresql_config = {
      max_connections                = 395
      enable_parallel_hash           = true
      autovacuum_vacuum_scale_factor = 0.34
      default_transaction_isolation  = "TRANSACTION_ISOLATION_READ_COMMITTED"
      shared_preload_libraries       = "SHARED_PRELOAD_LIBRARIES_AUTO_EXPLAIN,SHARED_PRELOAD_LIBRARIES_PG_HINT_PLAN"
    }

    access = {
      data_lens = true
      web_sql = true
      serverless = true
      }
    
    performance_diagnostics = {
      enabled = true
      }

  }

  maintenance_window {
    type = "WEEKLY"
    day  = "SAT"
    hour = 12
  }

  host {
    zone             = var.default_zone
    name             = "host0"
    subnet_id        = var.subnet_id
    assign_public_ip = true
  }
}

# resource "yandex_mdb_postgresql_user" "konst" {
#   cluster_id = yandex_mdb_postgresql_cluster.foo.id
#   name       = "konst"
#   password   = var.pg_user_konst_password
# }

# resource "yandex_mdb_postgresql_database" "testdb" {
#   cluster_id = yandex_mdb_postgresql_cluster.postgresql-cluster.id
#   name       = "testdb"
#   owner      = yandex_mdb_postgresql_user.konst.name
#   lc_collate = "en_US.UTF-8"
#   lc_type    = "en_US.UTF-8"
# }
