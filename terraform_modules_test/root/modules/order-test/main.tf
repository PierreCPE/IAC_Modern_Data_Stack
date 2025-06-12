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

module "azure-datalake" {
  source = "./submodules/azure-datalake"

}


# Create ADLS container
resource "azurerm_storage_container" "pi_othrmod_test" {
  name                  = "secondmoduletest"
  storage_account_name  = module.azure-datalake.adls_name
  container_access_type = "private"
}

output "adls_name" {
  value     = module.azure-datalake.adls_name
  sensitive = true
}