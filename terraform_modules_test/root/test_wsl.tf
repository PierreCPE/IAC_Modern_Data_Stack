# Configuration Terraform optimisée pour WSL
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

# Provider Azure avec authentification CLI (meilleur pour WSL)
provider "azurerm" {
  features {}
  use_cli                = true
  skip_provider_registration = true
}

# Variables pour configuration flexible WSL
variable "airbyte_server_url" {
  description = "URL du serveur Airbyte (auto-détectée)"
  type        = string
  default     = "http://localhost:8000"
}

variable "workspace_id" {
  description = "ID du workspace Airbyte OSS par défaut"
  type        = string
  default     = "5ae6b09b-fdec-41af-aed7-204436cc6af6"
}

# Provider Airbyte avec URL flexible
provider "airbyte" {
  server_url = var.airbyte_server_url
  username   = "airbyte"
  password   = "password"
}

# Module stockage existant (inchangé)
module "order-test" {
  source = "./modules/order-test"
}

# Source Faker optimisée pour test rapide
resource "airbyte_source_faker" "test_faker" {
  name         = "WSL Test Faker"
  workspace_id = var.workspace_id

  configuration = {
    count                = 100   # Réduit pour test rapide
    seed                 = 42
    records_per_slice    = 25
    records_per_sync     = 100
    always_updated       = false
    parallelism          = 1
  }
}

# Destination Azure avec configuration explicite
resource "airbyte_destination_azure_blob_storage" "test_adls" {
  name         = "WSL Test ADLS Destination"
  workspace_id = var.workspace_id

  configuration = {
    azure_blob_storage_account_name      = module.order-test.adls_name
    azure_blob_storage_account_key       = module.order-test.adls_primary_access_key
    azure_blob_storage_container_name    = "foldercsv"
    azure_blob_storage_endpoint_domain_name = "blob.core.windows.net"
    
    format = {
      format_type = "CSV"
      flattening  = "Root level flattening"
    }
  }
  
  # Assurer que le stockage est créé avant
  depends_on = [module.order-test]
}

# Connexion simple pour test
resource "airbyte_connection" "faker_to_adls_test" {
  name           = "WSL Faker to ADLS Test"
  source_id      = airbyte_source_faker.test_faker.source_id
  destination_id = airbyte_destination_azure_blob_storage.test_adls.destination_id

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
    schedule_type = "manual"  # Test manuel
  }
  
  # Dépendances explicites
  depends_on = [
    airbyte_source_faker.test_faker,
    airbyte_destination_azure_blob_storage.test_adls
  ]
}

# Outputs détaillés pour debugging
output "azure_info" {
  description = "Informations Azure"
  value = {
    resource_group    = "ModernDataStack"
    storage_account   = module.order-test.adls_name
    container        = "foldercsv"
    region           = "francecentral"
  }
}

output "airbyte_info" {
  description = "Informations Airbyte"
  value = {
    ui_url           = var.airbyte_server_url
    credentials      = "airbyte / password"
    workspace_id     = var.workspace_id
    faker_source_id  = airbyte_source_faker.test_faker.source_id
    destination_id   = airbyte_destination_azure_blob_storage.test_adls.destination_id
    connection_id    = airbyte_connection.faker_to_adls_test.connection_id
  }
}

output "test_instructions" {
  description = "Instructions pour tester"
  value = {
    step_1 = "Ouvrir ${var.airbyte_server_url} dans le navigateur"
    step_2 = "Login: airbyte / password"
    step_3 = "Connections → 'WSL Faker to ADLS Test'"
    step_4 = "Cliquer 'Sync now'"
    step_5 = "Vérifier dans Azure Portal: ModernDataStack → ${module.order-test.adls_name} → foldercsv"
  }
}

# Données de debug
data "azurerm_client_config" "current" {}

output "debug_info" {
  description = "Informations de debug"
  value = {
    subscription_id = data.azurerm_client_config.current.subscription_id
    tenant_id      = data.azurerm_client_config.current.tenant_id
    object_id      = data.azurerm_client_config.current.object_id
  }
  sensitive = true
}
