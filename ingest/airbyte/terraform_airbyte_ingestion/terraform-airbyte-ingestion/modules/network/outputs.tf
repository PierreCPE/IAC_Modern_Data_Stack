output "network_id" {
  description = "ID of the Docker network"
  value       = docker_network.main.id
}

output "network_name" {
  description = "Name of the Docker network"
  value       = docker_network.main.name
}