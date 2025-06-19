output "faker_source_id" {
  description = "ID de la source Faker créée"
  value       = module.airbyte-sources.faker_source_id
}

output "gcs_source_id" {
  description = "ID de la source GCS créée (si configurée)"
  value       = module.airbyte-sources.gcs_source_id
}

output "azure_destination_id" {
  description = "ID de la destination Azure Blob Storage"
  value       = module.airbyte-connections.azure_destination_id
}

output "faker_to_azure_connection_id" {
  description = "ID de la connexion Faker vers Azure"
  value       = module.airbyte-connections.faker_to_azure_connection_id
}

output "gcs_to_azure_connection_id" {
  description = "ID de la connexion GCS vers Azure (si configurée)"
  value       = module.airbyte-connections.gcs_to_azure_connection_id
}
