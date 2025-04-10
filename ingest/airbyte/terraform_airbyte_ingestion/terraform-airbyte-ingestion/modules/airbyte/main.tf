terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

resource "docker_container" "airbyte" {
  image = "airbyte/airbyte:latest"
  name  = "airbyte"
  ports {
    internal = 8000
    external = 8000
  }
  restart = "always"

  networks_advanced {
    name = var.network_name
  }

  environment = {
    AIRBYTE_DATABASE_URL = "postgresql://admin:admin@${var.postgres_host}:${var.postgres_port}/mydatabase"
    AIRBYTE_API_KEY      = var.airbyte_api_key
  }

  depends_on = [
    docker_container.postgres
  ]
}

resource "docker_container" "postgres" {
  image = "postgres:latest"
  name  = "airbyte_postgres"
  ports {
    internal = 5432
    external = 5432
  }

  networks_advanced {
    name = var.network_name
  }

  environment = {
    POSTGRES_USER     = "admin"
    POSTGRES_PASSWORD = "admin"
    POSTGRES_DB      = "mydatabase"
  }
  restart = "always"
  
}