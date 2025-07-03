# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
    airbyte = {
      source  = "airbytehq/airbyte"
      version = "0.6.0"
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
  client_id     = "73fbea79-0b03-45da-bba0-2811a8561ac0"
  client_secret = "ffViJI9yevjxoyIa2Zq1AXAiJh78CCAP"
  # username   = "admin.admin@admin.com"
  # password   = "password"
}


# Création du stockage Azure commentée - utilisation du stockage de l'entreprise
#module "azure-datalake" {
#  source = "./modules/order-test/submodules/azure-datalake"
#}

#module "order-test" {
#  source = "./modules/order-test"
#}

# Container ADLS commenté - utilisation du stockage de l'entreprise
#resource "azurerm_storage_container" "pi_mod_test" {
#  name                  = "rootmoduletest"
#  storage_account_name  = module.order-test.adls_name
#  container_access_type = "private"
#}

# Module d'ingestion Airbyte - Pipeline utilisant le stockage de l'entreprise
module "airbyte-ingestion" {
  source = "./modules/airbyte-ingestion"
  
  # Configuration du stockage de l'entreprise via variables d'environnement
  azure_connection_string = var.azure_connection_string
  
  # Configuration des containers pour le pipeline
  source_container_name = "source-test"    # Container source
  raw_container_name    = "raw-data"       # Container raw après Airbyte
  parquet_container_name = "parquet"       # Container final parquet
  
  # Configuration Airbyte
  workspace_id      = var.workspace_id
  airbyte_server_url = var.airbyte_server_url
  
  # Pas de dépendance sur le module de stockage car utilisation du stockage existant
}

# Variables pour la configuration Azure Blob Storage de l'entreprise
variable "azure_connection_string" {
  description = "Connection string pour le stockage Azure de l'entreprise"
  type        = string
  sensitive   = true
  # Cette variable doit être définie via une variable d'environnement :
  # export TF_VAR_azure_connection_string="DefaultEndpointsProtocol=https;AccountName=...;AccountKey=...;EndpointSuffix=core.windows.net"
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
output "airbyte_source_blob_id" {
  description = "ID de la source Azure Blob Airbyte"
  value       = module.airbyte-ingestion.source_blob_id
}

output "airbyte_azure_destination_id" {
  description = "ID de la destination Azure Raw Airbyte"
  value       = module.airbyte-ingestion.azure_destination_id
}

output "airbyte_connection_id" {
  description = "ID de la connexion principale Blob Source vers Raw Data"
  value       = module.airbyte-ingestion.main_connection_id
}

output "connection_info" {
  description = "Informations de la connexion pour le monitoring"
  value       = module.airbyte-ingestion.connection_info
}

output "pipeline_info" {
  description = "Informations complètes du pipeline"
  value       = module.airbyte-ingestion.pipeline_info
}

output "deployment_info" {
  description = "Informations complètes du déploiement"
  value = {
    airbyte_url    = var.airbyte_server_url
    pipeline_stage = "Stage 1: Azure Blob → Raw Data (Airbyte)"
    next_steps = [
      "1. Ouvrir ${var.airbyte_server_url}",
      "2. Login: airbyte / password", 
      "3. Connections → 'Enterprise Blob to Raw Data'",
      "4. Cliquer 'Sync now'",
      "5. Vérifier container 'raw-data' dans Azure Portal",
      "6. Prochaine étape: Configurer Azure Function (raw-data → parquet)"
    ]
  }
}

# Informations du stockage Azure (commentées car utilisation du stockage de l'entreprise)
# output "storage_info" {
#   description = "Informations du stockage ADLS"
#   value = {
#     storage_account_name = module.order-test.adls_name
#     resource_group      = "ModernDataStack"
#     container          = azurerm_storage_container.pi_mod_test.name
#   }
# }
