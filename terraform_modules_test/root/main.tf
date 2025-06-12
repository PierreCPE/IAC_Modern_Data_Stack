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


#module "azure-datalake" {
#  source = "./modules/order-test/submodules/azure-datalake"
#
#}

module "order-test" {
  source = "./modules/order-test"

}


# Create ADLS container
resource "azurerm_storage_container" "pi_mod_test" {
  name                  = "rootmoduletest"
  storage_account_name  = module.order-test.adls_name
  container_access_type = "private"
}
