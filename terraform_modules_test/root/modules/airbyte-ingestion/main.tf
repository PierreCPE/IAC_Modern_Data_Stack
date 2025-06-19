# Module Airbyte Ingestion - Pipeline Faker vers ADLS
# Basé sur la logique validée du test WSL

# Configure the Airbyte provider
terraform {
  required_providers {
    airbyte = {
      source  = "airbytehq/airbyte"
      version = "0.5.1"  # Aligné avec le main.tf principal
    }
  }
}

# Source Faker principale pour ingestion
resource "airbyte_source_faker" "main_faker" {
  name         = "Production Faker Source"
  workspace_id = var.workspace_id

  configuration = {
    count                = 1000      # Plus de données pour la prod
    seed                 = 42
    records_per_slice    = 100
    records_per_sync     = 1000
    always_updated       = false
    parallelism          = 4         # Plus de parallélisme pour la prod
  }
}

# Destination ADLS principale
resource "airbyte_destination_azure_blob_storage" "main_adls" {
  name         = "Production ADLS Destination"
  workspace_id = var.workspace_id

  configuration = {
    azure_blob_storage_account_name      = var.storage_account_name
    azure_blob_storage_account_key       = var.storage_account_key
    azure_blob_storage_container_name    = var.csv_container_name
    azure_blob_storage_endpoint_domain_name = "blob.core.windows.net"
    
    format = {
      csv_comma_separated_values = {
        flattening = "Root level flattening"
      }
    }
  }
}

# Connexion principale Faker → ADLS
resource "airbyte_connection" "main_faker_to_adls" {
  name           = "Production Faker to ADLS"
  source_id      = airbyte_source_faker.main_faker.source_id
  destination_id = airbyte_destination_azure_blob_storage.main_adls.destination_id

  namespace_definition = "source"
  namespace_format     = "production_data"

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
    schedule_type = "manual"  # Peut être changé en cron si besoin
  }

  depends_on = [
    airbyte_source_faker.main_faker,
    airbyte_destination_azure_blob_storage.main_adls
  ]
}
