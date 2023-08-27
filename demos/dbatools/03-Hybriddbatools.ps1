## Running dbatools commands against a hybrid environment

# this should contain the two az sql instances
$servers

# lets add some 'on-prem'

# very secure.... credential for containers
$securePassword = ('dbatools.IO' | ConvertTo-SecureString -AsPlainText -Force)
$credential = New-Object System.Management.Automation.PSCredential('sqladmin', $securePassword)


$servers += Connect-DbaInstance -SqlInstance mssql1, mssql2 -SqlCredential $credential

# now we have 2 in the cloud and 2 on prem
$servers

## lets get a list of databases
Get-DbaDatabase -SqlInstance $servers -OutVariable dbs

$dbs | Format-Table ComputerName, SqlInstance, Name, Compatibility, @{l='parent';e={$_.Parent.ServerType}}