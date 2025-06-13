provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Storage Account with ADLS Gen2 capabilities
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true # Hierarchical Namespace for ADLS Gen2

  # Free tier optimizations
  min_tls_version = "TLS1_2"
}

# Storage container for raw data
resource "azurerm_storage_container" "raw" {
  name                 = "raw"
  storage_account_name = azurerm_storage_account.storage.name
}

# Storage container for processed data
resource "azurerm_storage_container" "processed" {
  name                 = "processed"
  storage_account_name = azurerm_storage_account.storage.name
}

# App Service Plan (Consumption Plan = free tier for Functions)
resource "azurerm_service_plan" "asp" {
  name                = "${var.function_app_name}-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan (serverless)
}

# Storage account for Function App (required for Function Apps)
resource "azurerm_storage_account" "function_storage" {
  name                     = "${var.function_app_name}storage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Function App
resource "azurerm_linux_function_app" "function" {
  name                        = var.function_app_name
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  service_plan_id             = azurerm_service_plan.asp.id
  storage_account_name        = azurerm_storage_account.function_storage.name
  storage_account_access_key  = azurerm_storage_account.function_storage.primary_access_key

  site_config {
    application_stack {
      python_version = "3.9"
    }
    application_insights_key = azurerm_application_insights.insights.instrumentation_key
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"     = "python"
    "STORAGE_CONNECTION_STRING"    = azurerm_storage_account.storage.primary_connection_string
    "AzureWebJobsDisableHomepage"  = "true"
    "WEBSITE_RUN_FROM_PACKAGE"     = "1"
  }
}

# Application Insights for monitoring (free tier includes some monitoring) a potentiellement enlevé si ca coute de l'argent
resource "azurerm_application_insights" "insights" {
  name                = "${var.function_app_name}-insights"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  application_type    = "web"
}