# To add to the IaC to get this all deployed through code

Did the following manually and need to add this to IaC

## Configure Managed Identity ofr for the function app to connect to the SQL Database

-- 1. Enable Azure AD authentication to the SQL database
    -- assign an Azure AD user as the AD admin of the server
    -- https://portal.azure.com/#@jpomfret7gmail.onmicrosoft.com/resource/subscriptions/bbd50fd8-6a3e-4d6f-8d20-cf6f43c9c461/resourceGroups/dbatools-azure-lab/providers/Microsoft.Sql/servers/dsoslo-server/activeDirectoryAdmin
-- 2. Enable Azure Function managed identity
    -- https://portal.azure.com/#@jpomfret7gmail.onmicrosoft.com/resource/subscriptions/bbd50fd8-6a3e-4d6f-8d20-cf6f43c9c461/resourceGroups/dbatools-azure-lab/providers/Microsoft.Web/sites/dsoslo2023/msi
-- 3. Grant SQL Database access to the managed identity

    -- system managed identity so the user name is the same as your function app name
    CREATE USER dsoslo2023 FROM EXTERNAL PROVIDER;
    ALTER ROLE db_datareader ADD MEMBER dsoslo2023;
    ALTER ROLE db_datawriter ADD MEMBER dsoslo2023;
    GO

-- 4. Configure Azure Function SQL connection string
    -- system managed identity
        -- Server=demo.database.windows.net; Authentication=Active Directory Managed Identity; Database=testdb
    -- user managed identity
        -- Server=demo.database.windows.net; Authentication=Active Directory Managed Identity; User Id=ClientIdOfManagedIdentity; Database=testdb


## NewStorageAcct - managed identity permissions
    -- using managed identity to create storage accounts
    -- managed identity needs
        -- permissions to create storage accounts in the resource group
        -- reader permissions to the subscription 

