# Configure the Azure provider
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


#module "azure-datalake" {
#  source = "./modules/order-test/submodules/azure-datalake"
#
#}

module "order-test" {
  source = "./modules/order-test"

}


# Create ADLS container
resource "azurerm_storage_container" "pi_mod_test" {
  name                 = "rootmoduletest"
  storage_account_id   = module.order-test.adls_id
  container_access_type = "private"
}

# Module d'ingestion Airbyte (nouveau)
module "airbyte-ingestion" {
  source = "./modules/airbyte-ingestion"
  
  # Dépendances : utilise les outputs du module de stockage
  storage_account_name = module.order-test.adls_name
  storage_account_key  = module.order-test.adls_primary_access_key
  
  # Configuration des containers
  csv_container_name     = "foldercsv"
  parquet_container_name = "folderparquet"
  
  # Configuration GCS optionnelle
  gcs_bucket_name          = var.gcs_bucket_name
  gcs_service_account_key  = var.gcs_service_account_key
  
  # Le module Airbyte attend que le stockage soit créé
  depends_on = [module.order-test]
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

# Outputs pour exposer les IDs des ressources créées
output "airbyte_faker_source_id" {
  description = "ID de la source Faker Airbyte"
  value       = module.airbyte-ingestion.faker_source_id
}

output "airbyte_azure_destination_id" {
  description = "ID de la destination Azure Airbyte"
  value       = module.airbyte-ingestion.azure_destination_id
}
