output "azure_destination_id" {
  description = "ID de la destination Azure Blob Storage"
  value       = airbyte_destination_azure_blob_storage.azure_processed.destination_id
}

output "faker_to_azure_connection_id" {
  description = "ID de la connexion Faker vers Azure"
  value       = airbyte_connection.faker_to_azure.connection_id
}

output "gcs_to_azure_connection_id" {
  description = "ID de la connexion GCS vers Azure (si configurée)"
  value       = length(airbyte_connection.gcs_to_azure) > 0 ? airbyte_connection.gcs_to_azure[0].connection_id : ""
}
