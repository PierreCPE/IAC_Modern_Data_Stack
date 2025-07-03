# Outputs du module Airbyte Ingestion - Pipeline Azure Blob vers Raw Data

output "source_blob_id" {
  description = "ID de la source Azure Blob Storage"
  value       = airbyte_source_azure_blob_storage.source_blob.source_id
}

output "azure_destination_id" {
  description = "ID de la destination Azure Blob Storage Raw"
  value       = airbyte_destination_azure_blob_storage.raw_adls.destination_id
}

output "main_connection_id" {
  description = "ID de la connexion principale Blob Source vers Raw Data"
  value       = airbyte_connection.source_to_raw.connection_id
}

output "connection_info" {
  description = "Informations de la connexion pour le monitoring"
  value = {
    connection_name = airbyte_connection.source_to_raw.name
    source_name     = airbyte_source_azure_blob_storage.source_blob.name
    destination_name = airbyte_destination_azure_blob_storage.raw_adls.name
    storage_account = local.connection_parts.account_name
    source_container = var.source_container_name
    raw_container   = var.raw_container_name
  }
}

# Output pour la prochaine étape du pipeline (Azure Function)
output "pipeline_info" {
  description = "Informations pour configurer la suite du pipeline"
  value = {
    storage_account     = local.connection_parts.account_name
    raw_container      = var.raw_container_name
    parquet_container  = var.parquet_container_name
    next_step         = "Configure Azure Function: raw-data → parquet"
  }
}
