variable "airbyte_image" {
  description = "The Docker image to use for Airbyte."
  type        = string
  default     = "airbyte/airbyte:latest"
}

variable "airbyte_port" {
  description = "The port on which Airbyte will be exposed."
  type        = number
  default     = 8000
}

variable "airbyte_db_url" {
  description = "The URL of the database to be used by Airbyte."
  type        = string
}

variable "airbyte_db_user" {
  description = "The username for the Airbyte database."
  type        = string
}

variable "airbyte_db_password" {
  description = "The password for the Airbyte database."
  type        = string
}

variable "airbyte_workspace" {
  description = "The workspace name for Airbyte."
  type        = string
  default     = "default"
}