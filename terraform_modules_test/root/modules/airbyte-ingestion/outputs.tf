# Outputs du module Airbyte Ingestion - Pipeline Faker vers ADLS

output "faker_source_id" {
  description = "ID de la source Faker créée"
  value       = airbyte_source_faker.main_faker.source_id
}

output "azure_destination_id" {
  description = "ID de la destination Azure Blob Storage"
  value       = airbyte_destination_azure_blob_storage.main_adls.destination_id
}

output "main_connection_id" {
  description = "ID de la connexion principale Faker vers Azure"
  value       = airbyte_connection.main_faker_to_adls.connection_id
}

output "connection_info" {
  description = "Informations de la connexion pour le monitoring"
  value = {
    connection_name = airbyte_connection.main_faker_to_adls.name
    source_name     = airbyte_source_faker.main_faker.name
    destination_name = airbyte_destination_azure_blob_storage.main_adls.name
    storage_account = var.storage_account_name
    container      = var.csv_container_name
  }
}
