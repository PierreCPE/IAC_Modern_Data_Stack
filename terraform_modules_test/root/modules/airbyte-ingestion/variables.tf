# Variables du module Airbyte Ingestion - Pipeline Faker vers ADLS

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

variable "workspace_id" {
  description = "ID du workspace Airbyte OSS"
  type        = string
  default     = "5ae6b09b-fdec-41af-aed7-204436cc6af6"
}

variable "airbyte_server_url" {
  description = "URL du serveur Airbyte"
  type        = string
  default     = "http://localhost:8000"
}

# Variables GCS optionnelles (pour compatibilité avec la config existante)
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
