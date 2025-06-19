# Configuration Terraform pour test WSL - Faker → ADLS
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
    airbyte = {
      source  = "airbytehq/airbyte"
      version = "~> 0.6.0"
    }
  }
  required_version = ">= 1.1.0"
}

# Provider Azure optimisé pour WSL
provider "azurerm" {
  features {}
  use_cli = true  # Utilise Azure CLI pour l'authentification
}

# Variables
variable "airbyte_server_url" {
  description = "URL du serveur Airbyte (auto-détectée par le script)"
  type        = string
  default     = "http://localhost:8000"
}

variable "workspace_id" {
  description = "ID du workspace Airbyte OSS"
  type        = string
  default     = "5ae6b09b-fdec-41af-aed7-204436cc6af6"
}

# Provider Airbyte avec URL flexible
provider "airbyte" {
  server_url = var.airbyte_server_url
  username   = "airbyte"
  password   = "password"
}

# Utilisation du module de stockage existant (chemin relatif)
module "storage" {
  source = "../root/modules/order-test"
}

# Source Faker simple pour test
resource "airbyte_source_faker" "wsl_faker" {
  name         = "WSL Test Faker"
  workspace_id = var.workspace_id

  configuration = {
    count                = 100
    seed                 = 42
    records_per_slice    = 25
    records_per_sync     = 100
    always_updated       = false
    parallelism          = 1
  }
}

# Destination ADLS
resource "airbyte_destination_azure_blob_storage" "wsl_adls" {
  name         = "WSL Test ADLS"
  workspace_id = var.workspace_id

  configuration = {
    azure_blob_storage_account_name      = module.storage.adls_name
    azure_blob_storage_account_key       = module.storage.adls_primary_access_key
    azure_blob_storage_container_name    = "foldercsv"
    azure_blob_storage_endpoint_domain_name = "blob.core.windows.net"
    
    format = {
      format_type = "CSV"
      flattening  = "Root level flattening"
    }
  }

  depends_on = [module.storage]
}

# Connexion Faker → ADLS
resource "airbyte_connection" "wsl_faker_to_adls" {
  name           = "WSL Faker to ADLS"
  source_id      = airbyte_source_faker.wsl_faker.source_id
  destination_id = airbyte_destination_azure_blob_storage.wsl_adls.destination_id

  namespace_definition = "source"
  namespace_format     = "wsl_test"

  configurations = {
    streams = [
      {
        name      = "users"
        sync_mode = "full_refresh_overwrite"
      }
    ]
  }

  schedule = {
    schedule_type = "manual"
  }

  depends_on = [
    airbyte_source_faker.wsl_faker,
    airbyte_destination_azure_blob_storage.wsl_adls
  ]
}

# Outputs
output "test_info" {
  value = {
    airbyte_url       = var.airbyte_server_url
    storage_account   = module.storage.adls_name
    container        = "foldercsv"
    faker_source_id  = airbyte_source_faker.wsl_faker.source_id
    destination_id   = airbyte_destination_azure_blob_storage.wsl_adls.destination_id
    connection_id    = airbyte_connection.wsl_faker_to_adls.connection_id
  }
}

output "next_steps" {
  value = {
    step_1 = "1. Ouvrir ${var.airbyte_server_url}"
    step_2 = "2. Login: airbyte / password"
    step_3 = "3. Connections → 'WSL Faker to ADLS'"
    step_4 = "4. Cliquer 'Sync now'"
    step_5 = "5. Vérifier Azure Portal → ModernDataStack → ${module.storage.adls_name} → foldercsv"
  }
}
