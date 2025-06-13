terraform {
  required_providers {
    airbyte = {
      source  = "airbytehq/airbyte"
      version = "0.9.0"
    }
  }
}

provider "airbyte" {
  // highlight-start
  client_id     = var.client_id
  client_secret = var.client_secret

  # Include server_url if running locally
  server_url = "http://localhost:8000/api/public/v1/"
  // highlight-end
}
resource "airbyte_source_faker" "my_source_faker" {
  name         = "My Faker Source"
  workspace_id = var.workspace_id

  configuration = {
    count = 1000
    seed  = 42
  }
}


resource "airbyte_destination_custom" "my_adls_destination" {
  name         = "My ADLS Gen2 Destination"
  workspace_id = var.workspace_id

  configuration = <<-EOF
    {
      "destinationType": "azure-blob-storage",
      "azure_blob_storage_account_name": "${var.azure_storage_account_name}",
      "azure_blob_storage_container_name": "${var.azure_container_name}",
      "azure_blob_storage_endpoint_domain_name": "host.docker.internal:10000",
      "azure_blob_storage_account_key": "${var.azure_storage_account_key}",
      "format": {
        "format_type": "CSV",
        "flattening": "No flattening",
        "compression": {
          "compression_type": "No compression"
        }
      }
    }
  EOF
}

resource "airbyte_connection" "faker_to_adls" {
  name           = "Faker to ADLS Gen2"
  source_id      = airbyte_source_faker.my_source_faker.source_id
  destination_id = airbyte_destination_custom.my_adls_destination.destination_id

  # Configure the sync settings
  namespace_definition = "source"
  namespace_format     = "${airbyte_source_faker.my_source_faker.name}_${airbyte_destination_custom.my_adls_destination.name}"

  # Set the sync schedule (optional)
  schedule = {
    schedule_type = "manual"
  }
}


# Nouvelle source GCS pour le use case

resource "airbyte_source_custom" "gcs_source" {
  name         = "GCS CSV Source"
  workspace_id = var.workspace_id

  configuration = <<-EOF
    {
      "sourceType": "gcs",
      "bucket": "${var.gcs_bucket_name}",
      "service_account_key": "${var.gcs_service_account_key}",
      "path_pattern": "**/*.csv",
      "format": {
        "filetype": "csv"
      }
    }
  EOF
}


# Connexion GCS vers ADLS existant
resource "airbyte_connection" "gcs_to_azurite" {
  name           = "GCS to Azurite"
  source_id      = airbyte_source_custom.gcs_source.source_id
  destination_id = airbyte_destination_custom.my_adls_destination.destination_id

  namespace_definition = "source"
  namespace_format     = "GCS_${airbyte_destination_custom.my_adls_destination.name}"

  schedule = {
    schedule_type = "manual"
  }
}