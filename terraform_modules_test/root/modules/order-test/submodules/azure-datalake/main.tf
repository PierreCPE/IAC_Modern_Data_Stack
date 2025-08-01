# Configuration du Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}


# Création du groupe de ressources
# Ceci est le groupe de ressources où le Data Lake et Data Factory seront déployés
resource "azurerm_resource_group" "pi_rg" {
  name     = "ModernDataStack"
  location = "francecentral"
}


# Création du Data Lake
# Ceci déploie le Data Lake dans le groupe de ressources et à sa même localisation
resource "azurerm_storage_account" "pi_dl" {
  name                     = "pimdsdatalake"
  resource_group_name      = azurerm_resource_group.pi_rg.name
  location                 = azurerm_resource_group.pi_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

# Envoie l'id du Data Lake en sortie pour être utilisé dans les modules dépendants
output "adls_id" {
  value     = azurerm_storage_account.pi_dl.id
  sensitive = true
}

# Envoie le nom du Data Lake en sortie pour être utilisé dans les modules dépendants
output "adls_name" {
  value     = azurerm_storage_account.pi_dl.name
  sensitive = true
}

# Création des conteneurs du Data Lake
# Ceci est le conteneur pour les fichiers CSV
resource "azurerm_storage_container" "pi_fcsv" {
  name                  = "foldercsv"
  storage_account_name  = azurerm_storage_account.pi_dl.name
  container_access_type = "private"
}

# Envoie l'id du conteneur CSV en sortie pour être utilisé dans les modules dépendants
output "csv_folder_id" {
  value     = azurerm_storage_container.pi_fcsv.id
  sensitive = true
}

# Ceci est le conteneur pour les fichiers Parquet après la conversion
resource "azurerm_storage_container" "pi_fpqt" {
  name                  = "folderparquet"
  storage_account_name  = azurerm_storage_account.pi_dl.name
  container_access_type = "private"
}

# Envoie l'id du conteneur Parquet en sortie pour être utilisé dans les modules dépendants
output "pqt_folder_id" {
  value     = azurerm_storage_container.pi_fpqt.id
  sensitive = true
}

# Création de la Data Factory
# Déploie la Data Factory pour faire la conversion des fichiers CSV en Parquet
resource "azurerm_data_factory" "pi_df" {
  name                = "pimdsdatafactory"
  location            = azurerm_resource_group.pi_rg.location
  resource_group_name = azurerm_resource_group.pi_rg.name
}

# Création du linked service de la Data Factory
# Ceci crée le lien entre la Data Factory et le Data Lake
resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "df_ls_dl" {
  name                = "AzureDataLakeStorageMDS"
  data_factory_id     = azurerm_data_factory.pi_df.id
  storage_account_key = azurerm_storage_account.pi_dl.primary_access_key
  url                 = "https://pimdsdatalake.dfs.core.windows.net/"
}

# Création des datasets de la Data Factory
# Ceci permet à la Data Factory d'accéder au conteneur CSV du Data Lake
resource "azurerm_data_factory_dataset_delimited_text" "df_ds_csv" {
  name                = "SourceDataset_CSV"
  data_factory_id     = azurerm_data_factory.pi_df.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.df_ls_dl.name

  azure_blob_storage_location {
    container = azurerm_storage_container.pi_fcsv.name
  }

  column_delimiter    = ","
  row_delimiter       = "\n"
  encoding            = "UTF-8"
  quote_character     = "\""
  escape_character    = "\\"
  first_row_as_header = true
}

# Ceci permet à la Data Factory d'accéder au conteneur Parquet du Data Lake
resource "azurerm_data_factory_dataset_parquet" "df_ds_pqt" {
  name                = "DestinationDataset_Parquet"
  data_factory_id     = azurerm_data_factory.pi_df.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.df_ls_dl.name

  azure_blob_storage_location {
    container = azurerm_storage_container.pi_fpqt.name
    path      = "folderparquet"
  }
  compression_codec = "gzip"
}

# Temps d'attente de la suppression de la pipeline
# Cette ressource ne déploie rien, mais cause un temps d'attente avant de supprimer la pipeline
# Sans cette ressource, terraform destroy échouera car la pipeline sera supprimée avant d'autres ressources qui en dépendent
resource "time_sleep" "wait_pipeline_deletion" {
  depends_on = [azurerm_data_factory_dataset_delimited_text.df_ds_csv, azurerm_data_factory_dataset_parquet.df_ds_pqt]

  destroy_duration = "5s"
}

# Création du job de conversion de CSV en Parquet
# Ceci déploie une pipeline avec une activité de Copie en Parquet.
# Lorsque déclenchée, cette pipeline copie tous les fichiers dans le conteneur CSV dans le conteneur Parquet en faisant la conversion.
resource "azurerm_data_factory_pipeline" "pi_job" {
  name            = "convertcsvtoparquet"
  data_factory_id = azurerm_data_factory.pi_df.id
  description     = "Copies all csv files in the CSV folder to parquet files in the Parquet folder"
  depends_on      = [time_sleep.wait_pipeline_deletion]
  activities_json = jsonencode([{
    "name" : "Copy_CSV_to_Parquet",
    "type" : "Copy",
    "dependsOn" : [],
    "policy" : {
      "timeout" : "0.12:00:00",
      "retry" : 0,
      "retryIntervalInSeconds" : 30,
      "secureOutput" : false,
      "secureInput" : false
    },
    "userProperties" : [
      {
        "name" : "Source",
        "value" : "folderCSV/*"
      },
      {
        "name" : "Destination",
        "value" : "folderParquet/"
      }
    ],
    "typeProperties" : {
      "source" : {
        "type" : "DelimitedTextSource",
        "storeSettings" : {
          "type" : "AzureBlobFSReadSettings",
          "recursive" : true,
          "wildcardFileName" : "*",
          "enablePartitionDiscovery" : false
        },
        "formatSettings" : {
          "type" : "DelimitedTextReadSettings",
          "skipLineCount" : 0
        }
      },
      "sink" : {
        "type" : "ParquetSink",
        "storeSettings" : {
          "type" : "AzureBlobFSWriteSettings"
        },
        "formatSettings" : {
          "type" : "ParquetWriteSettings"
        }
      },
      "enableStaging" : false,
      "validateDataConsistency" : false,
      "translator" : {
        "type" : "TabularTranslator",
        "typeConversion" : true,
        "typeConversionSettings" : {
          "allowDataTruncation" : true,
          "treatBooleanAsNumber" : false
        }
      }
    },
    "inputs" : [
      {
        "referenceName" : azurerm_data_factory_dataset_delimited_text.df_ds_csv.name,
        "type" : "DatasetReference"
      }
    ],
    "outputs" : [
      {
        "referenceName" : "DestinationDataset_Parquet",
        "type" : "DatasetReference"
      }
    ]
  }])
}