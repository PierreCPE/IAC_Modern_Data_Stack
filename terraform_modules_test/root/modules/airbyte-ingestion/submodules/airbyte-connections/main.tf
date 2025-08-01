# Variables d'entrée
variable "workspace_id" {
  description = "ID du workspace Airbyte"
  type        = string
}

variable "faker_source_id" {
  description = "ID de la source Faker"
  type        = string
}

variable "gcs_source_id" {
  description = "ID de la source GCS"
  type        = string
}

variable "storage_account_name" {
  description = "Nom du storage account Azure"
  type        = string
}

variable "storage_account_key" {
  description = "Clé du storage account Azure"
  type        = string
  sensitive   = true
}

variable "csv_container_name" {
  description = "Nom du container CSV"
  type        = string
}

variable "parquet_container_name" {
  description = "Nom du container Parquet"
  type        = string
}

# Destination Azure Blob Storage pour données brutes (CSV)
resource "airbyte_destination_azure_blob_storage" "azure_raw" {
  name         = "Azure Blob Storage - Raw Data"
  workspace_id = var.workspace_id

  configuration = {
    azure_blob_storage_account_name      = var.storage_account_name
    azure_blob_storage_account_key       = var.storage_account_key
    azure_blob_storage_container_name    = var.csv_container_name
    azure_blob_storage_endpoint_domain_name = "blob.core.windows.net"
    
    format = { # A vérifier si le format est correct pour Airbyte
      format_type = "CSV"
      flattening  = "Root level flattening"
    }
  }
}

# Destination Azure Blob Storage pour données transformées (Parquet)
resource "airbyte_destination_azure_blob_storage" "azure_processed" {
  name         = "Azure Blob Storage - Processed Data"
  workspace_id = var.workspace_id

  configuration = {
    azure_blob_storage_account_name      = var.storage_account_name
    azure_blob_storage_account_key       = var.storage_account_key
    azure_blob_storage_container_name    = var.parquet_container_name
    azure_blob_storage_endpoint_domain_name = "blob.core.windows.net"
    
    format = {
      format_type = "Parquet"
      compression_codec = "snappy"
    }
  }
}

# Connexion Faker vers Azure (données de test)
resource "airbyte_connection" "faker_to_azure" {
  name           = "Faker to Azure Raw"
  source_id      = var.faker_source_id
  destination_id = airbyte_destination_azure_blob_storage.azure_raw.destination_id

  namespace_definition = "source"
  namespace_format     = "faker_data"

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
}

# Connexion GCS vers Azure (données réelles) - conditionnelle, pblm, j'ai pas de données dans mon bucket car cout de l'argent
resource "airbyte_connection" "gcs_to_azure" {
  count = var.gcs_source_id != "" ? 1 : 0
  
  name           = "GCS CSV to Azure Parquet"
  source_id      = var.gcs_source_id
  destination_id = airbyte_destination_azure_blob_storage.azure_processed.destination_id

  namespace_definition = "source"
  namespace_format     = "gcs_data"

  configurations = {
    streams = [
      {
        name      = "csv_files"
        sync_mode = "full_refresh_overwrite"
      }
    ]
  }
}
