terraform {
  required_providers {
    airbyte = {
      source = "airbytehq/airbyte"
      version = "0.9.0"
    }
  }
}

provider "airbyte" {
    // highlight-start
    client_id = var.client_id
    client_secret = var.client_secret

    # Include server_url if running locally
    server_url = "http://localhost:8000/api/public/v1/"
    // highlight-end
}
resource "airbyte_source_faker" "my_source_faker" {
  name = "My Faker Source"
  workspace_id = var.workspace_id
  
  configuration = {
    count = 1000
    seed = 42
  }
}


resource "airbyte_destination_azure_blob_storage" "my_adls_destination" {
  name = "My ADLS Gen2 Destination"
  workspace_id = var.workspace_id
  
  configuration = {
    azure_blob_storage_account_name = var.azure_storage_account_name
    azure_blob_storage_container_name = var.azure_container_name
    azure_blob_storage_endpoint_domain_name = "localhost:10000"  # Default endpoint, change if using a custom endpoint

    azure_blob_storage_account_key = var.azure_storage_account_key
    
    format = {
      format_type = "JSONL"
      compression = "NO_COMPRESSION"
    }
    
    file_name_pattern = "{date}-{hour}-{minute}-{second}-{epoch}-{random}-{namespace}"
    blob_path_prefix = "airbyte/faker-data"
  }
}


resource "airbyte_connection" "faker_to_adls" {
  name = "Faker to ADLS Gen2"
  source_id = airbyte_source_faker.my_source_faker.source_id
  destination_id = airbyte_destination_azure_blob_storage.my_adls_destination.destination_id
  
  # Configure the sync settings
  namespace_definition = "source"
  namespace_format = "${airbyte_source_faker.my_source_faker.name}_${airbyte_destination_azure_blob_storage.my_adls_destination.name}"
  
  # Set the sync schedule (optional)
  schedule = {
    schedule_type = "manual"
    }
}
