# Variables du module Airbyte Ingestion - Pipeline Azure Blob vers ADLS

# Configuration du stockage Azure via connection string (sécurisé)

variable "workspace_id" {
  description = "ID du workspace Airbyte"
  type        = string
}
variable "azure_connection_string" {
  description = "Connection string Azure pour accéder au stockage de l'entreprise"
  type        = string
  sensitive   = true
  default     = ""
}

# Alternative : configuration traditionnelle (optionnelle, pour rétrocompatibilité)
variable "storage_account_name" {
  description = "Nom du storage account Azure (optionnel si connection_string fournie)"
  type        = string
  default     = ""
}

variable "storage_account_key" {
  description = "Clé du storage account Azure (optionnel si connection_string fournie)"
  type        = string
  default     = ""
  sensitive   = true
}

# Configuration des containers pour le pipeline
variable "source_container_name" {
  description = "Nom du container source (source-test)"
  type        = string
  default     = "source-test"
}

variable "raw_container_name" {
  description = "Nom du container pour les données raw après Airbyte"
  type        = string
  default     = "raw-data"
}

variable "csv_container_name" {
  description = "Nom du container pour les fichiers CSV (pour rétrocompatibilité)"
  type        = string
  default     = "foldercsv"
}

variable "parquet_container_name" {
  description = "Nom du container pour les fichiers Parquet" 
  type        = string
  default     = "parquet"
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
