# PROVIDER DESCRIPTION
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

# PROVIDER CONNECTION
provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id = "b1givhukbagupnl466fc"
  folder_id = "b1g7nkfc490qgggp3ljq"
  zone = "ru-central1-a"
}

# LOCALS
locals { 
  common_config = {
    ubuntu_image_id = "fd874d4jo8jbroqs6d7i"
    subnet_id = "e9biopolv3b0tihpvqc0"
    cores  = 2
    memory = 4
    disk_type = "network-ssd"
    zone = "ru-central1-a"
  }
  instances = {
    ubuntu_server_1 = { name = "master", ip_address = "10.128.0.10", disk_size = 30 },
    ubuntu_server_2 = { name = "worker", ip_address = "10.128.0.11", disk_size = 30 }
  }
}

# NODES CREATING
resource "yandex_compute_instance" "ubuntu_servers" {
  for_each = local.instances

  name = each.value.name
  zone = local.common_config.zone
  platform_id = "standard-v1"
  allow_stopping_for_update = true

  resources {
    cores = local.common_config.cores
    memory = local.common_config.memory
  }

  boot_disk {
    initialize_params {
      image_id = local.common_config.ubuntu_image_id
      size = each.value.disk_size
    }
    auto_delete = true
  }

  network_interface {
    subnet_id = local.common_config.subnet_id
    ip_address = each.value.ip_address
    nat = true
  }

  metadata = {
    user-data = templatefile("${path.module}/cloud-init.yaml", {
      name = each.value.name
    })
  }
}

output "instance_ips" {
  value = [
    for instance in yandex_compute_instance.ubuntu_servers : instance.network_interface[0].ip_address
  ]
}
