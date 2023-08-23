 variable "resource_group_name" {
    type        = string
    description = "The name of the resource group"
  }
 variable "sql_instance_name" {
    type        = string
    description = "The name of the SQL server"
  }

  variable "location" {
    type        = string
    description = "The location for the SQL Server"
    default     = "northeurope"
  }

  variable "tags" {
    type        = map(string)
    description = "Tags for the resources"
  }

  variable "administrator_login" {
    type        = string
    description = "The name of the administrator login"
  }

  variable "administrator_login_password" {
    type        = string
    description = "The password for the SQL Server Administrator"
  }

  variable "environment" {
    type        = string
    description = "The environment that is being deployed"
    default     = ""
  }

  variable "minimum_tls_version" {
    type        = string
    description = "The minimal TLS version"
    default     = "Disabled"
  }

  variable "public_network_access" {
    type        = bool
    description = "Public network access"
    default     = true
  }

  variable "active_directory_admin_user" {
    type = string
    description = "the Active Directory Admin User name"
  }

  variable "active_directory_admin_sid" {
    type = string
    description = "the Active Directory Admin User SID"
  }

  variable "tenantid" {
    type = string
    description = "the tenant id"
  }

  variable "azuread_authentication_only" {
    type    = bool
    default = false
    description = "Should Azure AD only authentication be enabled?"
  }

  # variable "external_administrator_principal_type" {
  #   type = string
  #   description = "The external administrator principal type - User Group etc"
  # }

  variable "sql_database_names" {
    type    = list(string)
    description = "Name of the inventory databases"
  }

  variable "db_sku_name" {
    type = string
    default = "GP_Gen5_2"
  }

  # variable "db_sku_family" {
  #   type = string
  #   default = "Gen5"
  # }

  variable "collation" {
    type        = string
    description = "Collation"
    default     = "SQL_Latin1_General_CP1_CI_AS"
  }

  variable "zone_redundant" {
    type    = bool
    default = false
  }

  variable "license_type" {
    type    = string
    default = "LicenseIncluded"
  }
