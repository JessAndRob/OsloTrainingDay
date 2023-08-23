# Lets have a look at some bicep and terraform for our SQL Servers and Databases

#region bicep

#region first some set up
# We need to connect to Azure and set the subscription
Connect-AzAccount -UseDeviceAuthentication

Set-AzContext -Subscription bbd50fd8-6a3e-4d6f-8d20-cf6f43c9c461

# we'll set some variables for the resource group and location as well
$resourceGroupName = "dbatools-azure-lab"
$location = "westeurope"

# secure string for password
$securePassword = ConvertTo-SecureString -String 'dbatools.IO1' -AsPlainText -Force

# deploy bicep template name

$deploymentName = "oslo-IAC-{0}" -f (Get-Date -Format 'yyMMddhhmmss')
#endregion first some set up

#region existing resources
# what do we have ?

Start-Process  https://portal.azure.com/#@jpomfret7gmail.onmicrosoft.com/resource/subscriptions/bbd50fd8-6a3e-4d6f-8d20-cf6f43c9c461/resourceGroups/dbatools-azure-lab/overview

Get-AzResource -ResourceGroupName $resourceGroupName

# thats not so useful

Get-AzResource -ResourceGroupName $resourceGroupName | Select Name, ResourceType

# lets just concentrate on the oslo SQL resources
Get-AzResource -ResourceGroupName $resourceGroupName| Where Name -like '*oslo*' | Select Name, ResourceType

#endregion existing resources

#region deploy bicep

# lets take a look at the bicep template

code .\demos\IaC\bicep\Data\SqlInstance.bicep

# lets deploy it with a WhatIf
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
#endregion deploy bicep
#endregion bicep

#region terraform

#region first some set up
# we need to login with the az cli
az login
# set the subscription
az account set --subscription 'bbd50fd8-6a3e-4d6f-8d20-cf6f43c9c461'

# this time we need to set the admin password as an environment variable
$ENV:TF_VAR_administrator_login_password="dbatools.IO1"

# its easier to set the directory to the terraform directory
cd demos\IaC\terraform

# I am going to use a local state file so I am removing any existing ones so you can see what is happening

Remove-Item localterraform.tfstate -ErrorAction SilentlyContinue -Force
Remove-Item localterraform.tfstate.backup -ErrorAction SilentlyContinue -Force
Remove-Item .terraform.lock.hcl -ErrorAction SilentlyContinue -Force

#endregion first some set up

#region terraform
# lets take a look at the terraform template

code main.tf

# looks pretty much like the bicep template

# lets take a look at the variables

code variables.tf

# thats the definition of the variables that we will use
# here are the values we will use

code deploydev.tfvars

# first we need to initialise terraform

terraform init

# now we can plan This is like a whatif except we can create a plan file that we can use to apply the changes later (CI/CD)

terraform plan -out tfplan -var-file="deploydev.tfvars"


# WAIT - WHAT? YOU ARE GOING TO CREATE

# pokker





# Thats not what I want

# lets look at the current state

# This is different from bicep. Bicep looks at the resources in the resource group and compares them to the template. Terraform looks at the state file and compares it to the template.

terraform state list

#So we need to import the resources into the state file.
# so we have to jump through hoops to import the resources - we have ot escape with a ` we have to provide the var  file BEFORE the resource name. We have to give the full resource id for each one.

terraform import -var-file="deploydev.tfvars"  azurerm_resource_group.rg /subscriptions/bbd50fd8-6a3e-4d6f-8d20-cf6f43c9c461/resourceGroups/dbatools-azure-lab

terraform import -var-file="deploydev.tfvars"  azurerm_mssql_server.sql /subscriptions/bbd50fd8-6a3e-4d6f-8d20-cf6f43c9c461/resourceGroups/dbatools-azure-lab/providers/Microsoft.Sql/servers/dsoslo-server

terraform import -var-file="deploydev.tfvars" azurerm_mssql_database.databases[0] /subscriptions/bbd50fd8-6a3e-4d6f-8d20-cf6f43c9c461/resourceGroups/dbatools-azure-lab/providers/Microsoft.Sql/servers/dsoslo-server/databases/dsoslo-db-dev

terraform import -var-file="deploydev.tfvars" azurerm_mssql_database.databases[1] /subscriptions/bbd50fd8-6a3e-4d6f-8d20-cf6f43c9c461/resourceGroups/dbatools-azure-lab/providers/Microsoft.Sql/servers/dsoslo-server/databases/dsoslo-db-cdc-dev



terraform state list
terraform state show -state="localterraform.tfstate" azurerm_mssql_server.sql
terraform state show -state="localterraform.tfstate" azurerm_mssql_database.databases[0]

# Now we can plan with the resources

terraform plan -out tfplan -var-file="deploydev.tfvars"

#endregion terraform