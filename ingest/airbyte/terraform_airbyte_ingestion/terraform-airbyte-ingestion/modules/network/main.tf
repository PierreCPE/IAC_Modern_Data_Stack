terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

resource "docker_network" "main" {
  name = var.network_name
  driver = "bridge"
  
  # Optional IPAM configuration if needed
  ipam_config {
    subnet = var.network_subnet
    gateway = var.network_gateway
  }
}