##############################
# create docker environment
##############################
# create a shared network
docker network create localnet

# Expose engines and setup shared path for migrations
docker run -p 2500:1433  --volume shared:/shared:z --name mssql1 --hostname mssql1 --network localnet -d dbatools/sqlinstance
docker run -p 2600:1433 --volume shared:/shared:z --name mssql2 --hostname mssql2 --network localnet -d dbatools/sqlinstance2

##############################
# save the password for ease
##############################
$securePassword = ('dbatools.IO' | ConvertTo-SecureString -AsPlainText -Force)
$credential = New-Object System.Management.Automation.PSCredential('sqladmin', $securePassword)

$PSDefaultParameterValues = @{
    "*:SqlCredential"            = $credential
    "*:DestinationCredential"    = $credential
    "*:DestinationSqlCredential" = $credential
    "*:SourceSqlCredential"      = $credential
    "*:PublisherSqlCredential"   = $credential
    "*:SubscriberSqlCredential"   = $credential
}

##############################
# change silly defaults
##############################
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true  -PassThru | Register-DbatoolsConfig #-Scope SystemMandatory
Set-DbatoolsConfig -FullName sql.connection.EncryptConnection -Value optional -PassThru | Register-DbatoolsConfig #-Scope SystemMandatory

##############################
# Test connections
##############################
Connect-DbaInstance -SqlInstance mssql1,mssql2 -OutVariable SqlInstances

# OutVariable magic!
$SqlInstances