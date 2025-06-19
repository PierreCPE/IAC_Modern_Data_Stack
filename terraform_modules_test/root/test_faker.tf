# Configuration Terraform pour test Faker → ADLS
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

provider "azurerm" {
  features {}
}

provider "airbyte" {
  # Configuration pour Airbyte OSS local
  server_url   = "http://localhost:8000"
  username     = "airbyte"
  password     = "password"
}

# Variables pour le test
variable "workspace_id" {
  description = "ID du workspace Airbyte (laisser vide pour auto-detect)"
  type        = string
  default     = ""
}

# Utilisation du module de stockage existant
module "order-test" {
  source = "./modules/order-test"
}

# Configuration Airbyte simplifiée pour test
locals {
  # ID de workspace par défaut d'Airbyte OSS
  airbyte_workspace_id = var.workspace_id != "" ? var.workspace_id : "5ae6b09b-fdec-41af-aed7-204436cc6af6"
}

# Source Faker pour générer des données de test
resource "airbyte_source_faker" "test_faker" {
  name         = "Test Faker Source"
  workspace_id = local.airbyte_workspace_id

  configuration = {
    count                = 1000
    seed                 = 12345
    records_per_slice    = 100
    records_per_sync     = 1000
    always_updated       = false
    parallelism          = 1
  }
}

# Destination Azure Blob Storage
resource "airbyte_destination_azure_blob_storage" "test_adls" {
  name         = "Test ADLS Destination"
  workspace_id = local.airbyte_workspace_id

  configuration = {
    azure_blob_storage_account_name = module.order-test.adls_name
    azure_blob_storage_account_key  = module.order-test.adls_primary_access_key
    azure_blob_storage_container_name = "foldercsv"
    azure_blob_storage_endpoint_domain_name = "blob.core.windows.net"
    
    format = {
      format_type = "CSV"
      flattening  = "Root level flattening"
    }
  }
}

# Connexion Faker vers ADLS
resource "airbyte_connection" "faker_to_adls_test" {
  name           = "Faker to ADLS Test"
  source_id      = airbyte_source_faker.test_faker.source_id
  destination_id = airbyte_destination_azure_blob_storage.test_adls.destination_id

  namespace_definition = "source"
  namespace_format     = "faker_test"

  configurations = {
    streams = [
      {
        name      = "users"
        sync_mode = "full_refresh_overwrite"
      },
      {
        name      = "products" 
        sync_mode = "full_refresh_overwrite"
      },
      {
        name      = "purchases"
        sync_mode = "full_refresh_overwrite"
      }
    ]
  }

  schedule = {
    schedule_type = "manual"  # Manuel pour les tests
  }
}

# Outputs pour vérification
output "faker_source_id" {
  description = "ID de la source Faker créée"
  value       = airbyte_source_faker.test_faker.source_id
}

output "adls_destination_id" {
  description = "ID de la destination ADLS créée"
  value       = airbyte_destination_azure_blob_storage.test_adls.destination_id
}

output "connection_id" {
  description = "ID de la connexion Faker → ADLS"
  value       = airbyte_connection.faker_to_adls_test.connection_id
}

output "storage_account_name" {
  description = "Nom du storage account créé"
  value       = module.order-test.adls_name
}

output "airbyte_ui_url" {
  description = "URL de l'interface Airbyte"
  value       = "http://localhost:8000"
}
