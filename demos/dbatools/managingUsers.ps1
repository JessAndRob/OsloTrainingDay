# create a docker container with dbatools container
docker run -p 2500:1433  --volume shared:/shared:z --name dbatools1 --hostname dbatools1 --network localnet -d dbatools/sqlinstance

# create a client alias
New-DbaClientAlias -Name dbatools1 -ServerName localhost -Port 2500

# Read in logins from csv
## PS4+ syntax!
(Import-Csv .\users.csv).foreach{
    $server = Connect-DbaInstance -SqlInstance $psitem.Server
    New-DbaLogin -SqlInstance $server -Login $psitem.User -Password ($psitem.Password | ConvertTo-SecureString -asPlainText -Force)
    New-DbaDbUser -SqlInstance $server -Login $psitem.User -Database $psitem.Database
    Add-DbaDbRoleMember -SqlInstance $server -User $psitem.User -Database $psitem.Database -Role $psitem.Role.split(',') -Confirm:$false
}

<#
## PS Version 3 & Lower
foreach($user in $users) {
    $server = Connect-DbaInstance -SqlInstance $user.Server
    New-DbaLogin -SqlInstance $server -Login $user.User -Password ($user.Password | ConvertTo-SecureString -asPlainText -Force)
    New-DbaDbUser -SqlInstance $server -Login $user.User -Database $user.Database
    Add-DbaDbRoleMember -SqlInstance $server -User $user.User -Database $user.Database -Role $user.Role.split(',') -Confirm:$false
}
#>