output "faker_source_id" {
  description = "ID de la source Faker"
  value       = airbyte_source_faker.demo_data.source_id
}

output "gcs_source_id" {
  description = "ID de la source GCS (si configurée)"
  value       = length(airbyte_source_gcs.gcs_data) > 0 ? airbyte_source_gcs.gcs_data[0].source_id : ""
}
