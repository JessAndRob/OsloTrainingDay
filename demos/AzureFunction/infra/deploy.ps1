Connect-AzAccount -UseDeviceAuthentication

Set-AzContext -Subscription bbd50fd8-6a3e-4d6f-8d20-cf6f43c9c461

# create a new resource group
$resourceGroupName = "dbatools-azure-lab"
$location = "westeurope"
#New-AzResourceGroup -Name $resourceGroupName -Location $location

# secure string for password
$securePassword = ConvertTo-SecureString -String 'dbatools.IO1' -AsPlainText -Force

# deploy bicep template
$deploymentName = "oslo-deployment"

$splat = @{
    Name                       = $deploymentName
    ResourceGroupName          = $resourceGroupName
    TemplateFile               = '.\demos\AzureFunction\infra\main.bicep'
    serverName                 = 'dsoslo-server'
    databaseName               = 'dsoslo-db'
    databaseName2              = 'dsoslo-db-cdc'
    environment                = 'dev'
    location                   = $location
    administratorLogin         = 'sqladmin'
    administratorLoginPassword = $securePassword
    appName                    = 'dsoslo2023'
    tags                       = @{'for'='dsoslo2023'}
    cosmosDbName               = 'dsoslo-cosmos'
    containerName              = 'dsoslo-container'
}
$deployment = New-AzResourceGroupDeployment @splat #-whatif