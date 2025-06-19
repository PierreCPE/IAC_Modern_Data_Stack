# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"    }
    airbyte = {
      source  = "airbytehq/airbyte"
      version = "0.5.1"  # Version spécifique plus stable
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

provider "airbyte" {
  # Configuration pour Airbyte OSS - flexible avec variables
  server_url = var.airbyte_server_url
  username   = "admin.admin@admin.com"
  password   = "password"
}


#module "azure-datalake" {
#  source = "./modules/order-test/submodules/azure-datalake"
#
#}

module "order-test" {
  source = "./modules/order-test"

}


# Create ADLS container
resource "azurerm_storage_container" "pi_mod_test" {
  name                  = "rootmoduletest"
  storage_account_name  = module.order-test.adls_name
  container_access_type = "private"
}

# Module d'ingestion Airbyte
module "airbyte-ingestion" {
  source = "./modules/airbyte-ingestion"
  
  # Dépendances : utilise les outputs du module de stockage
  storage_account_name = module.order-test.adls_name
  storage_account_key  = module.order-test.adls_primary_access_key
  
  # Configuration des containers
  csv_container_name     = "foldercsv"
  parquet_container_name = "folderparquet"
  
  # Configuration Airbyte
  workspace_id      = var.workspace_id
  airbyte_server_url = var.airbyte_server_url
  
  # Configuration GCS optionnelle (pour compatibilité)
  gcs_bucket_name          = var.gcs_bucket_name
  gcs_service_account_key  = var.gcs_service_account_key
  
  # Le module Airbyte attend que le stockage soit créé
  depends_on = [module.order-test]
}

# Variables pour la configuration Airbyte
variable "workspace_id" {
  description = "ID du workspace Airbyte OSS"
  type        = string
  default     = "5ae6b09b-fdec-41af-aed7-204436cc6af6"
}

variable "airbyte_server_url" {
  description = "URL du serveur Airbyte"
  type        = string
  default     = "http://localhost:8000"
}

# Variables pour la configuration GCS (optionnelles)
variable "gcs_bucket_name" {
  description = "Nom du bucket GCS contenant les fichiers CSV (optionnel)"
  type        = string
  default     = ""
}

variable "gcs_service_account_key" {
  description = "Clé JSON du service account GCS (optionnel)"
  type        = string
  default     = ""
  sensitive   = true
}

# Outputs pour exposer les informations du pipeline d'ingestion
output "airbyte_faker_source_id" {
  description = "ID de la source Faker Airbyte"
  value       = module.airbyte-ingestion.faker_source_id
}

output "airbyte_azure_destination_id" {
  description = "ID de la destination Azure Airbyte"
  value       = module.airbyte-ingestion.azure_destination_id
}

output "airbyte_connection_id" {
  description = "ID de la connexion principale Faker vers ADLS"
  value       = module.airbyte-ingestion.main_connection_id
}

output "connection_info" {
  description = "Informations de la connexion pour le monitoring"
  value       = module.airbyte-ingestion.connection_info
}

output "deployment_info" {
  description = "Informations complètes du déploiement"
  value = {
    storage_account = module.order-test.adls_name
    container      = "foldercsv"
    airbyte_url    = var.airbyte_server_url
    next_steps = [
      "1. Ouvrir ${var.airbyte_server_url}",
      "2. Login: airbyte / password",
      "3. Connections → 'Production Faker to ADLS'",
      "4. Cliquer 'Sync now'",
      "5. Vérifier Azure Portal → ModernDataStack → ${module.order-test.adls_name} → foldercsv"
    ]
  }
}

output "storage_info" {
  description = "Informations du stockage ADLS"
  value = {
    storage_account_name = module.order-test.adls_name
    resource_group      = "ModernDataStack"  # Nom défini en dur dans le sous-module
    container          = azurerm_storage_container.pi_mod_test.name
  }
}
