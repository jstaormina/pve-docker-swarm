provider "proxmox" {
  endpoint = var.pve_endpoint
  username = var.pve_username
  password = var.pve_password
  insecure = true
  ssh {
    agent = true
  }
}

resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve"
  url          = var.vm_image_url
}

resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  nodes = {
    manager = {
      init_cmd = [
        "systemctl enable qemu-guest-agent",
        "systemctl start qemu-guest-agent",
        "docker swarm init --advertise-addr ${var.swarm_network_address}${var.swarm_manager_id}",
        "docker swarm join-token worker -q | tee /tmp/swarm-worker-token.txt"
      ]
    }
    worker = {
      init_cmd = [
        "systemctl enable qemu-guest-agent",
        "systemctl start qemu-guest-agent",
        "until nc -vzw 2 ${var.swarm_network_address}${var.swarm_manager_id} 2377; do sleep 10; done",
        "scp -i /etc/ssh/ssh_host_rsa_key -o \"StrictHostKeyChecking no\" ubuntu@${var.swarm_network_address}${var.swarm_manager_id}:/tmp/swarm-worker-token.txt /tmp/swarm-worker-token.txt",
        "docker swarm join --token \"$(cat /tmp/swarm-worker-token.txt)\" ${var.swarm_network_address}${var.swarm_manager_id}:2377"
      ]
    }
  }
}

resource "proxmox_virtual_environment_file" "cloud_config" {
  for_each = var.swarm_servers

  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve"
  source_raw {
    data = templatefile("./templates/cloud-config.yml.tftpl", {
      cicd_pub_key_path = "${trimspace(file(var.cicd_pub_key_path))}"
      server_public_key = "${trimspace(tls_private_key.rsa_key.public_key_openssh)}"
      private_key       = tls_private_key.rsa_key.private_key_pem
      init_commands     = local.nodes[each.value == var.swarm_manager_id ? "manager" : "worker"].init_cmd
      host_name = "swarm-node-${each.value}"
    })
    file_name = "cloud-config-${each.value}.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "swarm_node" {
  depends_on = [proxmox_virtual_environment_file.cloud_config]
  for_each   = var.swarm_servers

  name      = each.value == var.swarm_manager_id ? "swarm-manager-${each.value}" : "swarm-worker-${each.value}"
  node_name = "pve"
  vm_id     = each.value
  agent {
    enabled = true
  }
  cpu {
    cores = 2
  }
  memory {
    dedicated = 4096
  }
  initialization {
    datastore_id = "data"
    ip_config {
      ipv4 {
        address = "${var.swarm_network_address}${each.value}/24"
        gateway = var.swarm_gateway
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.cloud_config[each.value].id
  }
  network_device {
    bridge   = "vmbr0"
    firewall = false
  }
  disk {
    datastore_id = "data"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }
}

