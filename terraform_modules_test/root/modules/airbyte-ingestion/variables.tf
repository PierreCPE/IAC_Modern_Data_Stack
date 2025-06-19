variable "workspace_id" {
  description = "ID du workspace Airbyte"
  type        = string
  default     = ""
}

variable "storage_account_name" {
  description = "Nom du storage account Azure créé par le module azure-datalake"
  type        = string
}

variable "storage_account_key" {
  description = "Clé du storage account Azure"
  type        = string
  sensitive   = true
}

variable "csv_container_name" {
  description = "Nom du container pour les fichiers CSV"
  type        = string
  default     = "foldercsv"
}

variable "parquet_container_name" {
  description = "Nom du container pour les fichiers Parquet" 
  type        = string
  default     = "folderparquet"
}

variable "gcs_bucket_name" {
  description = "Nom du bucket GCS source (optionnel)"
  type        = string
  default     = ""
}

variable "gcs_service_account_key" {
  description = "Clé du service account GCS (optionnel)"
  type        = string
  default     = ""
  sensitive   = true
}
