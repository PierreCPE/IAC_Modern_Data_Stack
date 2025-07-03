# Outputs du module Airbyte Ingestion - Pipeline Azure Blob vers Raw Data

output "source_blob_id" {
  description = "ID de la source Azure Blob Storage"
  value       = airbyte_source_azure_blob_storage.source_blob.source_id
  sensitive   = true
}

output "azure_destination_id" {
  description = "ID de la destination Azure Blob Storage Raw"
  value       = airbyte_destination_azure_blob_storage.raw_adls.destination_id
  sensitive   = true
}

output "main_connection_id" {
  description = "ID de la connexion principale Blob Source vers Raw Data"
  value       = airbyte_connection.source_to_raw.connection_id
  sensitive   = true
}

output "source_name" {
  description = "Nom de la source Azure Blob Storage"
  value       = airbyte_source_azure_blob_storage.source_blob.name
}

output "destination_name" {
  description = "Nom de la destination Azure Blob Storage"
  value       = airbyte_destination_azure_blob_storage.raw_adls.name
}

output "connection_name" {
  description = "Nom de la connexion"
  value       = airbyte_connection.source_to_raw.name
}

# Output pour la prochaine étape du pipeline (Azure Function)
output "pipeline_info" {
  description = "État du pipeline de données"
  value = {
    pipeline_status = "Pipeline Azure Blob → ADLS configuré"
    next_steps = [
      "1. Uploadez des fichiers CSV dans le container 'source-test'",
      "2. Lancez la synchronisation via l'interface Airbyte",
      "3. Vérifiez les données dans le container 'raw-data'",
      "4. Développez l'Azure Function pour traiter raw-data → parquet"
    ]
    containers_required = [
      "source-test",
      "raw-data", 
      "parquet"
    ]
  }
  sensitive = true
}

output "connection_info" {
  description = "Informations de connexion du pipeline Airbyte"
  value = {
    source_name      = airbyte_source_azure_blob_storage.source_blob.name
    destination_name = airbyte_destination_azure_blob_storage.raw_adls.name
    connection_name  = airbyte_connection.source_to_raw.name
    containers = {
      source    = var.source_container_name
      raw_data  = var.raw_container_name
      parquet   = var.parquet_container_name
    }
  }
  sensitive = true
}