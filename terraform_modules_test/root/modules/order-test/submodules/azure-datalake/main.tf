# Configure the Azure provider
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


# Create resource group
resource "azurerm_resource_group" "pi_rg" {
  name     = "ModernDataStack"
  location = "francecentral"
}


# Create VMs
# to do

# Create ADLS
resource "azurerm_storage_account" "pi_dl" {
  name                     = "pimdsdatalake"
  resource_group_name      = azurerm_resource_group.pi_rg.name
  location                 = azurerm_resource_group.pi_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

output "adls_id" {
  value     = azurerm_storage_account.pi_dl.id
  sensitive = true
}

output "adls_name" {
  value     = azurerm_storage_account.pi_dl.name
  sensitive = true
}

# Create ADLS containers 
resource "azurerm_storage_container" "pi_fcsv" {
  name                  = "foldercsv"
  storage_account_name  = azurerm_storage_account.pi_dl.name
  container_access_type = "private"
}

output "csv_folder_id" {
  value     = azurerm_storage_container.pi_fcsv.id
  sensitive = true
}

resource "azurerm_storage_container" "pi_fpqt" {
  name                  = "folderparquet"
  storage_account_name  = azurerm_storage_account.pi_dl.name
  container_access_type = "private"
}

output "pqt_folder_id" {
  value     = azurerm_storage_container.pi_fpqt.id
  sensitive = true
}

# Create Data factory
resource "azurerm_data_factory" "pi_df" {
  name                = "pimdsdatafactory"
  location            = azurerm_resource_group.pi_rg.location
  resource_group_name = azurerm_resource_group.pi_rg.name
}

# Create Data factory datalake linked service
resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "df_ls_dl" {
  name                = "AzureDataLakeStorageMDS"
  data_factory_id     = azurerm_data_factory.pi_df.id
  storage_account_key = azurerm_storage_account.pi_dl.primary_access_key
  url                 = "https://pimdsdatalake.dfs.core.windows.net/"
}

# Create data factory datasets
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

# Time for correct pipeline deletion
resource "time_sleep" "wait_pipeline_deletion" {
  depends_on = [azurerm_data_factory_dataset_delimited_text.df_ds_csv, azurerm_data_factory_dataset_parquet.df_ds_pqt]

  destroy_duration = "5s"
}

# Create Copy to parquet job
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