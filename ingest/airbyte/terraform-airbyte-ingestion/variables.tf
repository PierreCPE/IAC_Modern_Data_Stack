variable "client_id" {
  type    = string
  default = "YOUR_CLIENT_ID"
}

variable "client_secret" {
  type    = string
  default = "YOUR_CLIENT_SECRET"
}

variable "workspace_id" {
  type    = string
  default = "YOUR_AIRBYTE_WORKSPACE_ID"
}

variable "azure_storage_account_name" {
  type        = string
  description = "Azure Storage account name"
  sensitive   = true
}

variable "azure_container_name" {
  type        = string
  description = "Azure Storage container name"
}

variable "azure_sas_token" {
  type        = string
  description = "SAS token for Azure Storage"
  sensitive   = true
}

variable "azure_storage_account_key" {
  type        = string
  description = "Account key for Azure Storage"
  sensitive   = true
  default     = "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=="
}

variable "gcs_bucket_name" {
  type        = string
  description = "GCS bucket name containing CSV files"
  default     = "your-gcs-bucket-name"
}

variable "gcs_service_account_key" {
  type        = string
  description = "GCS service account key JSON"
  sensitive   = true
}