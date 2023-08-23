Connect-AzAccount -UseDeviceAuthentication

Set-AzContext -Subscription bbd50fd8-6a3e-4d6f-8d20-cf6f43c9c461

$resourceGroupName = "dbatools-azure-lab"
$location = "westeurope"

Get-AzResource -ResourceGroupName $resourceGroupName

# secure string for password
$securePassword = ConvertTo-SecureString -String 'dbatools.IO1' -AsPlainText -Force

# deploy bicep template
$deploymentName = "oslo-IAC-deployment"

$splat = @{
    Name                               = $deploymentName
    ResourceGroupName                  = $resourceGroupName
    TemplateFile                       = '.\demos\IaC\bicep\Data\SqlInstance.bicep'
    SqlInstanceName                    = 'dsoslo-server'
    SqldatabaseNames                   = @('dsoslo-db', 'dsoslo-db-cdc')
    environment                        = 'dev'
    location                           = $location
    administratorLogin                 = 'sqladmin'
    administratorLoginPassword         = $securePassword
    ActiveDirectoryAdminUser           = 'jess@jpomfret7gmail.onmicrosoft.com'
    ActiveDirectoryAdminUserSid        = '0c97d81f-a7c6-40d4-9077-ade0dfbfe968'
    ExternalAdministratorPrincipalType = 'User'
    tenantid                           = 'f98042ad-9bbc-499d-adb4-17193696b9a3'
    dbSkuName                          = 'GP_Gen5'
    dbSkuFamily                        = 'Gen5'
    tags                               = @{'for' = 'dsoslo2023' }
    minimalTlsVersion                  = 'None'
    publicNetworkAccess               = 'Enabled'

}
$deployment = New-AzResourceGroupDeployment @splat -WhatIf

az login

az account set --subscription 'bbd50fd8-6a3e-4d6f-8d20-cf6f43c9c461'

$ENV:TF_VAR_administrator_login_password="dbatools.IO1"
cd demos\IaC\terraform

Remove-Item localterraform.tfstate -ErrorAction SilentlyContinue -Force
Remove-Item localterraform.tfstate.backup -ErrorAction SilentlyContinue -Force

terraform init

terraform plan -out tfplan -var-file="deploydev.tfvars"

# WAIT - WHAT? YOU ARE GOING TO CREATE

# pokker

# Thats not what I want

# lets loo9k at the current state

terraform state show -state="localterraform.tfstate"

# so we have to jump through hoops to import the resources - we have ot escape with a ` we have to provide the var  file BEFORE the resource name.

terraform import -var-file="deploydev.tfvars"  azurerm_resource_group.rg /subscriptions/bbd50fd8-6a3e-4d6f-8d20-cf6f43c9c461/resourceGroups/dbatools-azure-lab

terraform import -var-file="deploydev.tfvars"  azurerm_mssql_server.sql /subscriptions/bbd50fd8-6a3e-4d6f-8d20-cf6f43c9c461/resourceGroups/dbatools-azure-lab/providers/Microsoft.Sql/servers/dsoslo-server

terraform import -var-file="deploydev.tfvars" azurerm_mssql_database.databases[0] /subscriptions/bbd50fd8-6a3e-4d6f-8d20-cf6f43c9c461/resourceGroups/dbatools-azure-lab/providers/Microsoft.Sql/servers/dsoslo-server/databases/dsoslo-db-dev

terraform import -var-file="deploydev.tfvars" azurerm_mssql_database.databases[1] /subscriptions/bbd50fd8-6a3e-4d6f-8d20-cf6f43c9c461/resourceGroups/dbatools-azure-lab/providers/Microsoft.Sql/servers/dsoslo-server/databases/dsoslo-db-cdc-dev

# Now we can plan wiht the resources

terraform plan -out tfplan -var-file="deploydev.tfvars"

# Grrrrr
terraform state list
terraform state show -state="localterraform.tfstate" azurerm_mssql_server.sql
terraform state show -state="localterraform.tfstate" azurerm_mssql_database.databases[`"dsoslo-db-cdc-dev`"]

terraform import -var-file="deploydev.tfvars" azurerm_mssql_database.databases[0] /subscriptions/bbd50fd8-6a3e-4d6f-8d20-cf6f43c9c461/resourceGroups/dbatools-azure-lab/providers/Microsoft.Sql/servers/dsoslo-server/databases/dsoslo-db-dev

terraform import -var-file="deploydev.tfvars" azurerm_mssql_database.databases[1] /subscriptions/bbd50fd8-6a3e-4d6f-8d20-cf6f43c9c461/resourceGroups/dbatools-azure-lab/providers/Microsoft.Sql/servers/dsoslo-server/databases/dsoslo-db-cdc-dev

terraform state list
terraform state show -state="localterraform.tfstate" azurerm_mssql_server.sql
terraform state show -state="localterraform.tfstate" azurerm_mssql_database.databases[`"dsoslo-db-cdc-dev`"]

# Now we can plan wiht the resources

terraform plan -out tfplan -var-file="deploydev.tfvars"