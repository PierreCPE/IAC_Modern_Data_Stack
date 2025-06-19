# Configure the Airbyte provider
terraform {
  required_providers {
    airbyte = {
      source  = "airbytehq/airbyte"
      version = "~> 0.6.0"
    }
  }
}

provider "airbyte" {
  # Configuration pour Airbyte OSS local
  server_url   = "http://localhost:8000"
  username     = "airbyte"
  password     = "password"
}

# Variables reçues du module parent
variable "storage_account_name" {
  description = "Nom du storage account Azure créé par le module azure-datalake"
  type        = string
}

variable "storage_account_key" {
  description = "Clé du storage account Azure"
  type        = string
  sensitive   = true
}

variable "csv_container_name" {
  description = "Nom du container pour les fichiers CSV"
  type        = string
  default     = "foldercsv"
}

variable "parquet_container_name" {
  description = "Nom du container pour les fichiers Parquet"
  type        = string
  default     = "folderparquet"
}

# Workspace Airbyte local (utilise la variable ou un ID par défaut)
locals {
  workspace_id = var.workspace_id != "" ? var.workspace_id : "5ae6b09b-fdec-41af-aed7-204436c"
}

# Module pour configurer les sources Airbyte
module "airbyte-sources" {
  source = "./submodules/airbyte-sources"
  
  workspace_id             = local.workspace_id
  gcs_bucket_name          = var.gcs_bucket_name
  gcs_service_account_key  = var.gcs_service_account_key
}

# Module pour configurer les destinations et connexions
module "airbyte-connections" {
  source = "./submodules/airbyte-connections"
  
  workspace_id           = local.workspace_id
  faker_source_id        = module.airbyte-sources.faker_source_id
  gcs_source_id          = module.airbyte-sources.gcs_source_id
  storage_account_name   = var.storage_account_name
  storage_account_key    = var.storage_account_key
  csv_container_name     = var.csv_container_name
  parquet_container_name = var.parquet_container_name
}
