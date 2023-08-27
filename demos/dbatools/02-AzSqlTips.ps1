## Connect to a Azure SQL Database
$server = 'dsoslo-server.database.windows.net'
$database = 'dsoslo-db-dev'

$sqladmin = Get-Credential sqladmin
$adminUser = Get-Credential adminuser

# Run the tips for one database - same as you would do in SSMS\ADS
Invoke-DbaAzSqlDbTip -SqlInstance $server -SqlCredential $sqladmin -Database $database


# for two databases with different credentials
$servers = @()
$servers += Connect-DbaInstance -SqlInstance 'dsoslo-server.database.windows.net' -SqlCredential $sqladmin
$servers += Connect-DbaInstance -SqlInstance 'jesssqlserver.database.windows.net' -SqlCredential $adminUser
$servers

$databases = 'dsoslo-db-dev','AdventureWorksLT'

# clean up test file if it exists
$filename = 'c:\temp\sqltips.xlsx'
if (Test-Path $filename) {Remove-Item $filename}

# for tips against multiple databases
Invoke-DbaAzSqlDbTip -SqlInstance $servers -Database $databases | Export-Excel -Path c:\temp\sqltips.xlsx -AutoSize -Show -TableName tips -WorksheetName tips

# load the spreadsheet
$excel = Open-ExcelPackage -Path $filename -KillExcel
# setup definition for the first pivot table; note the IncludePivotChart
$PTDef =  New-PivotTableDefinition -PivotTableName "P1" -SourceWorkSheet "Tips" -PivotRows "SqlInstance" -PivotData @{'tip_id' = 'count'} -IncludePivotChart -ChartType BarClustered3D
$PTDef +=  New-PivotTableDefinition -PivotTableName "P2" -SourceWorkSheet "Tips" -PivotRows "SqlInstance" -PivotData @{'tip_id' = 'count'} -IncludePivotChart -ChartType PieExploded3D
# join the definition for the second pivot table
Export-Excel -ExcelPackage $excel -PivotTableDefinition $PTDef -Show -Activate

