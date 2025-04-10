variable "airbyte_image" {
  description = "The Docker image for Airbyte"
  type        = string
  default     = "airbyte/airbyte:latest"
}

variable "airbyte_port" {
  description = "The port on which Airbyte will run"
  type        = number
  default     = 8000
}

variable "airbyte_db_url" {
  description = "The database URL for Airbyte to connect to."
  type        = string
  default     = "jdbc:postgresql://airbyte_postgres:5432/mydatabase"
}

variable "airbyte_db_user" {
  description = "The database user for Airbyte."
  type        = string
  default     = "admin"
}

variable "airbyte_db_password" {
  description = "The database password for Airbyte."
  type        = string
  default     = "admin"
}

variable "airbyte_workspace" {
  description = "The workspace name for Airbyte"
  type        = string
  default     = "default"
}

variable "POSTGRES_HOST" {
  description = "PostgreSQL host"
  default     = "airbyte_postgres"
}