terraform {
  backend "azurerm" {
    resource_group_name  = "dbatools-azure-lab"
    storage_account_name = "testpostman1233456"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
