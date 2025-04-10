output "airbyte_url" {
  value = "http://${docker_container.airbyte.name}:8000"
}

output "postgres_url" {
  value = "postgresql://${docker_container.postgres.name}:5432/mydatabase"
}