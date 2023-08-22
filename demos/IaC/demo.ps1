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
    ActiveDirectoryAdminUser           = 'jess@jpomfret7gmail.onmicrosoft.com '
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
