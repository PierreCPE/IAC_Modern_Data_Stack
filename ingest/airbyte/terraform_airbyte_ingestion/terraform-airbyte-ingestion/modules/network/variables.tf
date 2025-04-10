variable "network_name" {
  description = "Name for the Docker network"
  type        = string
  default     = "airbyte_network"
}

variable "network_subnet" {
  description = "Subnet for the Docker network"
  type        = string
  default     = "172.28.0.0/16"
}

variable "network_gateway" {
  description = "Gateway for the Docker network"
  type        = string
  default     = "172.28.0.1"
}