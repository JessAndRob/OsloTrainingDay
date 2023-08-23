provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}


  resource "azurerm_mssql_server" "sql" {

    name                         = var.sql_instance_name
    resource_group_name          = azurerm_resource_group.rg.name
    location                     = var.location
    tags                         = var.tags
    version = "12.0"
    identity {
      type = "SystemAssigned"
    }
    administrator_login          = var.administrator_login
    administrator_login_password = var.administrator_login_password
    minimum_tls_version =            var.minimum_tls_version
    public_network_access_enabled = var.public_network_access
    azuread_administrator {
          login_username = var.active_directory_admin_user
    object_id      = var.active_directory_admin_sid
    tenant_id = var.tenantid
    azuread_authentication_only = var.azuread_authentication_only
    }
  }


  resource "azurerm_mssql_database" "databases" {
    count = length(var.sql_database_names)

    name                 = "${var.sql_database_names[count.index]}-${var.environment}"
    tags                 = var.tags
    server_id = azurerm_mssql_server.sql.id
    collation            = var.collation
    sku_name = var.db_sku_name
    zone_redundant = var.zone_redundant
    license_type = var.license_type
  }
