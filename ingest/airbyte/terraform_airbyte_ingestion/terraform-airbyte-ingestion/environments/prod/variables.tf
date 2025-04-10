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
  description = "The URL for the database that Airbyte will connect to."
  type        = string
}

variable "airbyte_db_user" {
  description = "The username for the database that Airbyte will connect to."
  type        = string
}

variable "airbyte_db_password" {
  description = "The password for the database that Airbyte will connect to."
  type        = string
}

variable "airbyte_db_name" {
  description = "The name of the database that Airbyte will connect to."
  type        = string
}