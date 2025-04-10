variable "airbyte_image" {
  description = "The Docker image for Airbyte."
  type        = string
  default     = "airbyte/airbyte:latest"
}

variable "airbyte_port" {
  description = "The port on which Airbyte will be exposed."
  type        = number
  default     = 8000
}

variable "airbyte_db_url" {
  description = "The database URL for Airbyte to connect to."
  type        = string
}

variable "airbyte_db_user" {
  description = "The database user for Airbyte."
  type        = string
}

variable "airbyte_db_password" {
  description = "The database password for Airbyte."
  type        = string
}

variable "airbyte_workspace" {
  description = "The workspace name for Airbyte."
  type        = string
  default     = "default"
}

variable "network_name" {
  description = "Name of the Docker network"
  type        = string
  default     = "airbyte_network"
}


variable "postgres_host" {
  description = "PostgreSQL host"
  type        = string
  default     = "airbyte_postgres"
}

variable "postgres_port" {
  description = "PostgreSQL port"
  type        = number
  default     = 5432
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "admin"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  default     = "admin"
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "mydatabase"
}

variable "airbyte_api_key" {
  description = "API key for Airbyte"
  type        = string
  default     = ""
}