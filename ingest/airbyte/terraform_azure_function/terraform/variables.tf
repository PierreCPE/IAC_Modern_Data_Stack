variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "rg-data-pipeline"
}

variable "location" {
  description = "Azure region"
  default     = "francesouth"
}

variable "storage_account_name" {
  description = "IaC Modern Data Stack Storage Account Name"
  default     = "adlsdatapipeline"
}

variable "function_app_name" {
  description = "Name for the Azure Function App"
  default     = "func-csv-to-parquet"
}