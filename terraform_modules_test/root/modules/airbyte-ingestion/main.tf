# Module Airbyte Ingestion - Pipeline Azure Blob Source vers ADLS Raw
# Pipeline: [Azure Blob: source-test] --> (Airbyte) --> [Azure Blob: raw-data]
# Basé sur la logique validée du test WSL

# Configure the Airbyte provider
terraform {
  required_providers {    
    airbyte = {
      source  = "airbytehq/airbyte"
      version = "~> 0.6.0"
    }
  }
}

# Extraction des informations de la connection string pour les configurations
locals {
  # Parse de la connection string pour extraire les informations nécessaires
  connection_parts = var.azure_connection_string != "" ? {
    account_name = regex("AccountName=([^;]+)", var.azure_connection_string)[0]
    account_key  = regex("AccountKey=([^;]+)", var.azure_connection_string)[0]
  } : {
    account_name = var.storage_account_name
    account_key  = var.storage_account_key
  }
}

# Source Azure Blob Storage (container source-test)
resource "airbyte_source_azure_blob_storage" "source_blob" {
  name         = "Enterprise Azure Blob Source"
  workspace_id = var.workspace_id

  configuration = {
    azure_blob_storage_account_name         = local.connection_parts.account_name
    azure_blob_storage_container_name       = var.source_container_name
    azure_blob_storage_endpoint_domain_name = "blob.core.windows.net"
    
    # Configuration des credentials obligatoire
    credentials = {
      authenticate_via_storage_account_key = {
        azure_blob_storage_account_key = local.connection_parts.account_key
      }
    }
    
    # Configuration des streams obligatoire
    streams = [
      {
        name = "**"  # Tous les fichiers du container
        format = {
          csv_format = {
            delimiter = ","
            quote_char = "\""
            escape_char = "\""
            encoding = "utf8"
            double_quote = true
            newlines_in_values = false
          }
        }
      }
    ]
  }
}

# Destination ADLS pour les données raw
resource "airbyte_destination_azure_blob_storage" "raw_adls" {
  name         = "Enterprise ADLS Raw Destination"
  workspace_id = var.workspace_id

  configuration = {
    azure_blob_storage_account_name         = local.connection_parts.account_name
    azure_blob_storage_account_key          = local.connection_parts.account_key
    azure_blob_storage_container_name       = var.raw_container_name
    azure_blob_storage_endpoint_domain_name = "blob.core.windows.net"
    
    # Configuration des credentials obligatoire
    credentials = {
      azure_blob_storage_account_key = local.connection_parts.account_key
    }
    
    # Format de sortie corrigé
    format = {
      csv_comma_separated_values = {
        flattening = "Root level flattening"
        compression = {
          compression_type = "No Compression"
        }
      }
    }
  }
}

# Connexion principale Azure Blob Source → ADLS Raw
resource "airbyte_connection" "source_to_raw" {
  name           = "Enterprise Blob to Raw Data"
  source_id      = airbyte_source_azure_blob_storage.source_blob.source_id
  destination_id = airbyte_destination_azure_blob_storage.raw_adls.destination_id

  namespace_definition = "source"
  namespace_format     = "raw_data"

  configurations = {
    streams = [
      {
        name = "**"  # Correspond au stream configuré dans la source
        sync_mode = "full_refresh_overwrite"
      }
    ]
  }

  schedule = {
    schedule_type = "manual"  # Peut être changé en cron si besoin
  }

  depends_on = [
    airbyte_source_azure_blob_storage.source_blob,
    airbyte_destination_azure_blob_storage.raw_adls
  ]
}

# Source Faker de test (commentée, gardée pour référence)
# resource "airbyte_source_faker" "test_faker" {
#   name         = "Test Faker Source"
#   workspace_id = var.workspace_id
#
#   configuration = {
#     count                = 100
#     seed                 = 42
#     records_per_slice    = 10
#     records_per_sync     = 100
#     always_updated       = false
#     parallelism          = 1
#   }
# }
