# Variables d'entrée
variable "workspace_id" {
  description = "ID du workspace Airbyte"
  type        = string
}

# tout ceci est optionnel, on peut ne pas utiliser GCS (surtout si je veux pas payer pour un bucket)
variable "gcs_bucket_name" {
  description = "Nom du bucket GCS (optionnel)"
  type        = string
  default     = ""
}

variable "gcs_service_account_key" {
  description = "Clé du service account GCS (optionnel)"
  type        = string
  default     = ""
  sensitive   = true
}

# Source Faker pour générer des données de test
resource "airbyte_source_faker" "demo_data" {
  name         = "Demo Faker Source"
  workspace_id = var.workspace_id

  configuration = {
    count                = 1000
    seed                 = 12345
    records_per_slice    = 100
    records_per_sync     = 1000
    always_updated       = false
    parallelism          = 1
  }
}

# Source GCS (conditionnelle - seulement si bucket configuré)
resource "airbyte_source_gcs" "gcs_data" {
  count = var.gcs_bucket_name != "" ? 1 : 0
  
  name         = "GCS CSV Source"
  workspace_id = var.workspace_id

  configuration = {
    bucket              = var.gcs_bucket_name
    service_account_key = var.gcs_service_account_key
    start_date          = "2024-01-01T00:00:00Z"
    
    streams = [
      {
        name = "csv_files"
        format = {
          filetype = "csv"
          delimiter = ","
          quote_char = "\""
          escape_char = "\\"
          encoding = "utf8"
          newlines_in_values = false
          skip_rows_before_header = 0
          skip_rows_after_header = 0
        }
        globs = ["**/*.csv"]
        validation_policy = "Emit Record"
      }
    ]
  }
}
