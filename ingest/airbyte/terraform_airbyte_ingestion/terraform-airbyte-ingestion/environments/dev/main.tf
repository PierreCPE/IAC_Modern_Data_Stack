terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

module "network" {
  source = "../../modules/network"
  network_name = var.NETWORK_NAME

  providers = {
    docker = docker
  }
}

module "airbyte" {
  source = "../../modules/airbyte"
  airbyte_image = var.AIRBYTE_IMAGE
  airbyte_port = var.AIRBYTE_PORT
  network_name = module.network.network_name
  
  # Add these lines to provide the missing variables
  airbyte_db_url = "jdbc:postgresql://${var.POSTGRES_HOST}:5432/${var.POSTGRES_DB}"
  airbyte_db_user = var.POSTGRES_USER
  airbyte_db_password = var.POSTGRES_PASSWORD
  
  # Existing variables
  postgres_user = var.POSTGRES_USER
  postgres_password = var.POSTGRES_PASSWORD
  postgres_db = var.POSTGRES_DB
  
  depends_on = [module.network]

  providers = {
    docker = docker
  }
}