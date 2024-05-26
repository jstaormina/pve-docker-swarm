variable "pve_endpoint" {
  description = "http address of pve host"
  type        = string
}

variable "pve_username" {
  description = "pve service account user name"
  type        = string
}

variable "pve_password" {
  description = "pve service account password"
  type        = string
  sensitive   = true
}

variable "swarm_network_address" {
  description = "IPv4 network address of the swarm"
  type        = string
}

variable "swarm_manager_id" {
  description = "Node ID of the swarm manager"
  type        = string
}

variable "swarm_servers" {
  description = "list of IDs for the swarm servers. This will also be used as an ID in pve as well as in the IPv4 host address for the server."
  type        = set(string)
}

variable "swarm_gateway" {
  description = "IPv4 of swarm gateway server"
  type        = string
}

variable "vm_image_url" {
  description = "Swarm node vm image"
  type        = string
}

variable "cicd_pub_key_path" {
  description = "File path to cicd host pub key"
  type        = string
}
