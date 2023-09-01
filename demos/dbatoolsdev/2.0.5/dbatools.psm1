#requires -Version 3.0
param(
    [Collections.IDictionary]
    [Alias('Options')]
    $Option = @{ }
)

$script:start = [DateTime]::Now

function Write-ImportTime {
    param (
        [string]$Text,
        $Timestamp = ([DateTime]::now)
    )
    if (-not $script:dbatools_previousImportPerformance) {
        $script:dbatools_previousImportPerformance = $script:start
    }

    $duration = New-TimeSpan -Start $script:dbatools_previousImportPerformance -End $Timestamp

    if (-not $script:dbatools_ImportPerformance) {
        $script:dbatools_ImportPerformance = New-Object Collections.ArrayList
    }

    $script:dbatools_ImportPerformance.Add(
        [pscustomobject]@{
            Action   = $Text
            Duration = $duration
        })

    $script:dbatools_previousImportPerformance = $Timestamp
}
Write-ImportTime -Text "Started" -Timestamp $script:start

$script:PSModuleRoot = $PSScriptRoot

if (-not $Env:TEMP) {
    $Env:TEMP = [System.IO.Path]::GetTempPath()
}

$script:libraryroot = Get-DbatoolsLibraryPath -ErrorAction Ignore

if (-not $script:libraryroot) {
    # for the people who bypass the psd1
    Import-Module dbatools.library -ErrorAction Ignore
    $script:libraryroot = Get-DbatoolsLibraryPath -ErrorAction Ignore

    if (-not $script:libraryroot) {
        throw "The dbatools library, dbatools.library, was module not found. Please install it from the PowerShell Gallery."
    }
    Write-ImportTime -Text "Couldn't find location for dbatools library module, loading it up"
}

try {
    $dll = [System.IO.Path]::Combine($script:libraryroot, "lib", "dbatools.dll")
    Import-Module $dll
} catch {
    throw "Couldn't import dbatools library | $PSItem"
}
Write-ImportTime -Text "Imported dbatools library"

Import-Command -Path "$script:PSModuleRoot/bin/typealiases.ps1"
Write-ImportTime -Text "Loading type aliases"

# Tell the library where the module is based, just in case
[Dataplat.Dbatools.dbaSystem.SystemHost]::ModuleBase = $script:PSModuleRoot

If ($PSVersionTable.PSEdition -in "Desktop", $null) {
    $netversion = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse -ErrorAction Ignore | Get-ItemProperty -Name version -ErrorAction Ignore | Where-Object PSChildName -EQ Full | Select-Object -First 1 -ExpandProperty Version
    if ($netversion -lt [version]"4.6") {
        # it actually works with 4.6 somehow, but 4.6.2 and above is recommended
        throw "Modern versions of dbatools require at least .NET 4.6.2. Please update your .NET Framework or downgrade to dbatools 1.0.173"
    }
}
Write-ImportTime -Text "Checking for .NET"

if (($PSVersionTable.PSVersion.Major -lt 6) -or ($PSVersionTable.Platform -and $PSVersionTable.Platform -eq 'Win32NT')) {
    $script:isWindows = $true
} else {
    $script:isWindows = $false

    # this doesn't exist by default
    # https://github.com/PowerShell/PowerShell/issues/1262
    try {
        $env:COMPUTERNAME = hostname
    } catch {
        $env:COMPUTERNAME = "unknown"
    }
}

Write-ImportTime -Text "Setting some OS variables"

Add-Type -AssemblyName System.Security
Write-ImportTime -Text "Loading System.Security"

# SQLSERVER:\ path not supported
if ($ExecutionContext.SessionState.Path.CurrentLocation.Drive.Name -eq 'SqlServer') {
    Write-Warning "SQLSERVER:\ provider not supported. Please change to another directory and reload the module."
    Write-Warning "Going to continue loading anyway, but expect issues."
}
Write-ImportTime -Text "Resolved path to not SQLSERVER PSDrive"

if ($PSVersionTable.PSEdition -and $PSVersionTable.PSEdition -ne 'Desktop') {
    $script:core = $true
} else {
    $script:core = $false
}

if ($psVersionTable.Platform -ne 'Unix' -and 'Microsoft.Win32.Registry' -as [Type]) {
    $regType = 'Microsoft.Win32.Registry' -as [Type]
    $hkcuNode = $regType::CurrentUser.OpenSubKey("SOFTWARE\Microsoft\WindowsPowerShell\dbatools\System")
    if ($dbaToolsSystemNode) {
        $userValues = @{ }
        foreach ($v in $hkcuNode.GetValueNames()) {
            $userValues[$v] = $hkcuNode.GetValue($v)
        }
        $dbatoolsSystemUserNode = $systemValues
    }
    $hklmNode = $regType::LocalMachine.OpenSubKey("SOFTWARE\Microsoft\WindowsPowerShell\dbatools\System")
    if ($dbaToolsSystemNode) {
        $systemValues = @{ }
        foreach ($v in $hklmNode.GetValueNames()) {
            $systemValues[$v] = $hklmNode.GetValue($v)
        }
        $dbatoolsSystemSystemNode = $systemValues
    }
} else {
    $dbatoolsSystemUserNode = @{ }
    $dbatoolsSystemSystemNode = @{ }
}

Write-ImportTime -Text "Checking for OS and loaded registry values"

#region Dot Sourcing
# Detect whether at some level dotsourcing was enforced
$script:serialimport = $dbatools_dotsourcemodule -or
$dbatoolsSystemSystemNode.SerialImport -or
$dbatoolsSystemUserNode.SerialImport -or
$option.SerialImport


$gitDir = $script:PSModuleRoot, '.git' -join [IO.Path]::DirectorySeparatorChar
$pubDir = $script:PSModuleRoot, 'public' -join [IO.Path]::DirectorySeparatorChar

if ($dbatools_enabledebug -or $option.Debug -or $DebugPreference -ne 'SilentlyContinue' -or [IO.Directory]::Exists($gitDir)) {
    if ([IO.Directory]::Exists($pubDir)) {
        $script:serialimport = $true
    } else {
        Write-Message -Level Verbose -Message "Debugging is enabled, but the public folder is missing so we can't do a serial import to actually enable debugging."
    }
}
Write-ImportTime -Text "Checking for debugging preference"
#endregion Dot Sourcing

# People will need to unblock files for themselves, unblocking code removed

<#
    Do the rest of the loading
    # This technique helped a little bit
    # https://becomelotr.wordpress.com/2017/02/13/expensive-dot-sourcing/
#>

if (-not (Test-Path -Path "$script:PSModuleRoot\dbatools.dat") -or $script:serialimport) {
    # All internal functions privately available within the toolset
    foreach ($file in (Get-ChildItem -Path "$script:PSModuleRoot/private/functions/" -Recurse -Filter *.ps1)) {
        . $file.FullName
    }

    Write-ImportTime -Text "Loading internal commands via dotsource"

    # All exported functions
    foreach ($file in (Get-ChildItem -Path "$script:PSModuleRoot/public/" -Recurse -Filter *.ps1)) {
        . $file.FullName
    }

    Write-ImportTime -Text "Loading external commands via dotsource"
} else {
    try {
        Import-Command -Path "$script:PSModuleRoot/dbatools.dat" -ErrorAction Stop
    } catch {
        # sometimes the file is in use by another process
        # not sure why, bc it's opened like this: using (FileStream fs = File.Open(Path, FileMode.Open, FileAccess.Read))
        function Test-FileInuse {
            param (
                [string]$FilePath
            )
            try {
                [IO.File]::OpenWrite($FilePath).Close()
                $false
            } catch {
                $true
            }
        }

        $waitsec = 0

        do {
            Write-Message -Level Verbose -Message "Waiting for dbatools.dat to be released by another process"
            Start-Sleep -Seconds 2
            $waitsec++
        } while ((Test-FileInuse -FilePath "$script:PSModuleRoot/dbatools.dat") -and $waitsec -lt 10)

        Import-Command -Path "$script:PSModuleRoot/dbatools.dat"
    }
}

# Load configuration system - Should always go after library and path setting
# this has its own Write-ImportTimes
foreach ($file in (Get-ChildItem -File -Path "$script:PSModuleRoot/private/configurations")) {
    Import-Command -Path $file.FullName
}

# Resolving the path was causing trouble when it didn't exist yet
# Not converting the path separators based on OS was also an issue.

if (-not ([Dataplat.Dbatools.Message.LogHost]::LoggingPath)) {
    [Dataplat.Dbatools.Message.LogHost]::LoggingPath = Join-DbaPath $script:AppData "PowerShell" "dbatools"
}

# Run all optional code
# Note: Each optional file must include a conditional governing whether it's run at all.
# Validations were moved into the other files, in order to prevent having to update dbatools.psm1 every time

if ($PSVersionTable.PSVersion.Major -lt 5) {
    foreach ($file in (Get-ChildItem -File -Path "$script:PSScriptRoot/opt")) {
        Import-Command -Path $file.FullName
    }
    Write-ImportTime -Text "Loading Optional Commands"
}

# Process TEPP parameters
if (-not $env:DBATOOLS_DISABLE_TEPP -and -not $script:disablerunspacetepp -and -not (Get-Runspace -Name dbatools-import-tepp)) {
    foreach ($file in (Get-ChildItem -File -Path "$script:PSModuleRoot/private/scripts/insertTepp*")) {
        Import-Command -Path $file.FullName
    }
    Write-ImportTime -Text "Loading TEPP"
}

# Process transforms
foreach ($file in (Get-ChildItem -File -Path "$script:PSModuleRoot/private/scripts/message-transforms*")) {
    Import-Command -Path $file.FullName
}
Write-ImportTime -Text "Loading Message Transforms"

# Load scripts that must be individually run at the end #
#-------------------------------------------------------#
<#
DBATOOLS_DISABLE_LOGGING    -- used to disable runspace that handles message logging to local filesystem
DBATOOLS_DISABLE_TEPP       -- used to disable TEPP, we will not even import the code behind 😉
#>
# Start the logging system (requires the configuration system up and running)
if (-not $env:DBATOOLS_DISABLE_LOGGING) {
    foreach ($file in (Get-ChildItem -File -Path "$script:PSModuleRoot/private/scripts/logfilescript*")) {
        Import-Command -Path $file.FullName
    }
    Write-ImportTime -Text "Loading Script: Logging"
}

if (-not $env:DBATOOLS_DISABLE_TEPP -and -not $script:disablerunspacetepp) {
    # Start the tepp asynchronous update system (requires the configuration system up and running)
    foreach ($file in (Get-ChildItem -File -Path "$script:PSModuleRoot/private/scripts/updateTeppAsync*")) {
        Import-Command -Path $file.FullName
    }
    Write-ImportTime -Text "Loading Script: Asynchronous TEPP Cache"
}

if (-not $env:DBATOOLS_DISABLE_LOGGING) {
    # Start the maintenance system (requires pretty much everything else already up and running)
    foreach ($file in (Get-ChildItem -File -Path "$script:PSModuleRoot/private/scripts/dbatools-maintenance*")) {
        Import-Command -Path $file.FullName
    }
    Write-ImportTime -Text "Loading Script: Maintenance"
}

# New 3-char aliases
$shortcuts = @{
    'ivq' = 'Invoke-DbaQuery'
    'cdi' = 'Connect-DbaInstance'
}
foreach ($sc in $shortcuts.GetEnumerator()) {
    New-Alias -Name $sc.Key -Value $sc.Value
}

# Leave forever
$forever = @{
    'Get-DbaRegisteredServer' = 'Get-DbaRegServer'
    'Attach-DbaDatabase'      = 'Mount-DbaDatabase'
    'Detach-DbaDatabase'      = 'Dismount-DbaDatabase'
    'Start-SqlMigration'      = 'Start-DbaMigration'
    'Write-DbaDataTable'      = 'Write-DbaDbTableData'
    'Get-DbaDbModule'         = 'Get-DbaModule'
    'Get-DbaBuildReference'   = 'Get-DbaBuild'
    'Copy-DbaSysDbUserObject' = 'Copy-DbaSystemDbUserObject'
}
foreach ($_ in $forever.GetEnumerator()) {
    Set-Alias -Name $_.Key -Value $_.Value
}
#endregion Aliases

# apparently this is no longer required? :O
if ($PSVersionTable.PSVersion.Major -lt 5) {
    # region Commands
    $script:xplat = @(
        'Start-DbaMigration',
        'Copy-DbaDatabase',
        'Copy-DbaLogin',
        'Copy-DbaAgentServer',
        'Copy-DbaSpConfigure',
        'Copy-DbaDbMail',
        'Copy-DbaDbAssembly',
        'Copy-DbaAgentSchedule',
        'Copy-DbaAgentOperator',
        'Copy-DbaAgentJob',
        'Copy-DbaCustomError',
        'Copy-DbaInstanceAuditSpecification',
        'Copy-DbaEndpoint',
        'Copy-DbaInstanceAudit',
        'Copy-DbaServerRole',
        'Copy-DbaResourceGovernor',
        'Copy-DbaXESession',
        'Copy-DbaInstanceTrigger',
        'Copy-DbaRegServer',
        'Copy-DbaSystemDbUserObject',
        'Copy-DbaAgentProxy',
        'Copy-DbaAgentAlert',
        'Copy-DbaStartupProcedure',
        'Get-DbaDbDetachedFileInfo',
        'Copy-DbaAgentJobCategory',
        'Get-DbaLinkedServerLogin',
        'Test-DbaPath',
        'Export-DbaLogin',
        'Watch-DbaDbLogin',
        'Expand-DbaDbLogFile',
        'Test-DbaMigrationConstraint',
        'Test-DbaNetworkLatency',
        'Find-DbaDbDuplicateIndex',
        'Remove-DbaDatabaseSafely',
        'Set-DbaTempdbConfig',
        'Test-DbaTempdbConfig',
        'Repair-DbaDbOrphanUser',
        'Remove-DbaDbOrphanUser',
        'Find-DbaDbUnusedIndex',
        'Get-DbaDbSpace',
        'Test-DbaDbOwner',
        'Set-DbaDbOwner',
        'Test-DbaAgentJobOwner',
        'Set-DbaAgentJobOwner',
        'Measure-DbaDbVirtualLogFile',
        'Get-DbaDbRestoreHistory',
        'Get-DbaTcpPort',
        'Test-DbaDbCompatibility',
        'Test-DbaDbCollation',
        'Test-DbaConnectionAuthScheme',
        'Test-DbaInstanceName',
        'Repair-DbaInstanceName',
        'Stop-DbaProcess',
        'Find-DbaOrphanedFile',
        'Get-DbaAvailabilityGroup',
        'Get-DbaLastGoodCheckDb',
        'Get-DbaProcess',
        'Get-DbaRunningJob',
        'Set-DbaMaxDop',
        'Test-DbaDbRecoveryModel',
        'Test-DbaMaxDop',
        'Remove-DbaBackup',
        'Get-DbaPermission',
        'Get-DbaLastBackup',
        'Connect-DbaInstance',
        'Get-DbaDbBackupHistory',
        'Get-DbaAgBackupHistory',
        'Read-DbaBackupHeader',
        'Test-DbaLastBackup',
        'Get-DbaMaxMemory',
        'Set-DbaMaxMemory',
        'Get-DbaDbSnapshot',
        'Remove-DbaDbSnapshot',
        'Get-DbaDbRoleMember',
        'Get-DbaServerRoleMember',
        'Get-DbaDbAsymmetricKey',
        'New-DbaDbAsymmetricKey',
        'Remove-DbaDbAsymmetricKey',
        'Invoke-DbaDbTransfer',
        'Invoke-DbaDbAzSqlTips',
        'New-DbaDbTransfer',
        'Remove-DbaDbData',
        'Resolve-DbaNetworkName',
        'Export-DbaAvailabilityGroup',
        'Write-DbaDbTableData',
        'New-DbaDbSnapshot',
        'Restore-DbaDbSnapshot',
        'Get-DbaInstanceTrigger',
        'Get-DbaDbTrigger',
        'Get-DbaDbState',
        'Set-DbaDbState',
        'Get-DbaHelpIndex',
        'Get-DbaAgentAlert',
        'Get-DbaAgentOperator',
        'Get-DbaSpConfigure',
        'Rename-DbaLogin',
        'Find-DbaAgentJob',
        'Find-DbaDatabase',
        'Get-DbaXESession',
        'Export-DbaXESession',
        'Test-DbaOptimizeForAdHoc',
        'Find-DbaStoredProcedure',
        'Measure-DbaBackupThroughput',
        'Get-DbaDatabase',
        'Find-DbaUserObject',
        'Get-DbaDependency',
        'Find-DbaCommand',
        'Backup-DbaDatabase',
        'Test-DbaBackupEncrypted',
        'New-DbaDirectory',
        'Get-DbaDbQueryStoreOption',
        'Set-DbaDbQueryStoreOption',
        'Restore-DbaDatabase',
        'Get-DbaDbFileMapping',
        'Copy-DbaDbQueryStoreOption',
        'Get-DbaExecutionPlan',
        'Export-DbaExecutionPlan',
        'Set-DbaSpConfigure',
        'Test-DbaIdentityUsage',
        'Get-DbaDbAssembly',
        'Get-DbaAgentJob',
        'Get-DbaCustomError',
        'Get-DbaCredential',
        'Get-DbaBackupDevice',
        'Get-DbaAgentProxy',
        'Get-DbaDbEncryption',
        'Disable-DbaDbEncryption',
        'Enable-DbaDbEncryption',
        'Get-DbaDbEncryptionKey',
        'New-DbaDbEncryptionKey',
        'Remove-DbaDbEncryptionKey',
        'Start-DbaDbEncryption',
        'Stop-DbaDbEncryption',
        'Remove-DbaDatabase',
        'Get-DbaQueryExecutionTime',
        'Get-DbaTempdbUsage',
        'Find-DbaDbGrowthEvent',
        'Test-DbaLinkedServerConnection',
        'Get-DbaDbFile',
        'Get-DbaDbFileGrowth',
        'Set-DbaDbFileGrowth',
        'Read-DbaTransactionLog',
        'Get-DbaDbTable',
        'Remove-DbaDbTable',
        'Invoke-DbaDbShrink',
        'Get-DbaEstimatedCompletionTime',
        'Get-DbaLinkedServer',
        'New-DbaAgentJob',
        'Get-DbaLogin',
        'New-DbaScriptingOption',
        'Save-DbaDiagnosticQueryScript',
        'Invoke-DbaDiagnosticQuery',
        'Export-DbaDiagnosticQuery',
        'Invoke-DbaWhoIsActive',
        'Set-DbaAgentJob',
        'Remove-DbaAgentJob',
        'New-DbaAgentJobStep',
        'Set-DbaAgentJobStep',
        'Remove-DbaAgentJobStep',
        'New-DbaAgentSchedule',
        'Set-DbaAgentSchedule',
        'Remove-DbaAgentSchedule',
        'Backup-DbaDbCertificate',
        'Get-DbaDbCertificate',
        'Copy-DbaDbCertificate',
        'Get-DbaEndpoint',
        'Get-DbaDbMasterKey',
        'Get-DbaSchemaChangeHistory',
        'Get-DbaInstanceAudit',
        'Get-DbaInstanceAuditSpecification',
        'Get-DbaProductKey',
        'Get-DbatoolsError',
        'Get-DbatoolsLog',
        'Restore-DbaDbCertificate',
        'New-DbaDbCertificate',
        'New-DbaDbMasterKey',
        'New-DbaServiceMasterKey',
        'Remove-DbaDbCertificate',
        'Remove-DbaDbMasterKey',
        'Get-DbaInstanceProperty',
        'Get-DbaInstanceUserOption',
        'New-DbaConnectionString',
        'Get-DbaAgentSchedule',
        'Read-DbaTraceFile',
        'Get-DbaInstanceInstallDate',
        'Backup-DbaDbMasterKey',
        'Get-DbaAgentJobHistory',
        'Get-DbaMaintenanceSolutionLog',
        'Invoke-DbaDbLogShipRecovery',
        'Find-DbaTrigger',
        'Find-DbaView',
        'Invoke-DbaDbUpgrade',
        'Get-DbaDbUser',
        'Get-DbaAgentLog',
        'Get-DbaDbMailLog',
        'Get-DbaDbMailHistory',
        'Get-DbaDbView',
        'Remove-DbaDbView',
        'New-DbaSqlParameter',
        'Get-DbaDbUdf',
        'Get-DbaDbPartitionFunction',
        'Get-DbaDbPartitionScheme',
        'Remove-DbaDbPartitionScheme',
        'Remove-DbaDbPartitionFunction',
        'Get-DbaDefaultPath',
        'Get-DbaDbStoredProcedure',
        'Test-DbaDbCompression',
        'Mount-DbaDatabase',
        'Dismount-DbaDatabase',
        'Get-DbaAgReplica',
        'Get-DbaAgDatabase',
        'Get-DbaModule',
        'Sync-DbaLoginPermission',
        'New-DbaCredential',
        'Get-DbaFile',
        'Set-DbaDbCompression',
        'Get-DbaTraceFlag',
        'Invoke-DbaCycleErrorLog',
        'Get-DbaAvailableCollation',
        'Get-DbaUserPermission',
        'Get-DbaAgHadr',
        'Find-DbaSimilarTable',
        'Get-DbaTrace',
        'Get-DbaSuspectPage',
        'Get-DbaWaitStatistic',
        'Clear-DbaWaitStatistics',
        'Get-DbaTopResourceUsage',
        'New-DbaLogin',
        'Get-DbaAgListener',
        'Invoke-DbaDbClone',
        'Disable-DbaTraceFlag',
        'Enable-DbaTraceFlag',
        'Start-DbaAgentJob',
        'Stop-DbaAgentJob',
        'New-DbaAgentProxy',
        'Test-DbaDbLogShipStatus',
        'Get-DbaXESessionTarget',
        'New-DbaXESmartTargetResponse',
        'New-DbaXESmartTarget',
        'Get-DbaDbVirtualLogFile',
        'Get-DbaBackupInformation',
        'Start-DbaXESession',
        'Stop-DbaXESession',
        'Set-DbaDbRecoveryModel',
        'Get-DbaDbRecoveryModel',
        'Get-DbaWaitingTask',
        'Remove-DbaDbUser',
        'Get-DbaDump',
        'Invoke-DbaAdvancedRestore',
        'Format-DbaBackupInformation',
        'Get-DbaAgentJobStep',
        'Test-DbaBackupInformation',
        'Invoke-DbaBalanceDataFiles',
        'Select-DbaBackupInformation',
        'Publish-DbaDacPackage',
        'Copy-DbaDbTableData',
        'Copy-DbaDbViewData',
        'Invoke-DbaQuery',
        'Remove-DbaLogin',
        'Get-DbaAgentJobCategory',
        'New-DbaAgentJobCategory',
        'Remove-DbaAgentJobCategory',
        'Set-DbaAgentJobCategory',
        'Get-DbaServerRole',
        'Find-DbaBackup',
        'Remove-DbaXESession',
        'New-DbaXESession',
        'Get-DbaXEStore',
        'New-DbaXESmartTableWriter',
        'New-DbaXESmartReplay',
        'New-DbaXESmartEmail',
        'New-DbaXESmartQueryExec',
        'Start-DbaXESmartTarget',
        'Get-DbaDbOrphanUser',
        'Get-DbaOpenTransaction',
        'Get-DbaDbLogShipError',
        'Test-DbaBuild',
        'Get-DbaXESessionTemplate',
        'ConvertTo-DbaXESession',
        'Start-DbaTrace',
        'Stop-DbaTrace',
        'Remove-DbaTrace',
        'Set-DbaLogin',
        'Copy-DbaXESessionTemplate',
        'Get-DbaXEObject',
        'ConvertTo-DbaDataTable',
        'Find-DbaDbDisabledIndex',
        'Get-DbaXESmartTarget',
        'Remove-DbaXESmartTarget',
        'Stop-DbaXESmartTarget',
        'Get-DbaRegServerGroup',
        'New-DbaDbUser',
        'Measure-DbaDiskSpaceRequirement',
        'New-DbaXESmartCsvWriter',
        'Invoke-DbaXeReplay',
        'Find-DbaInstance',
        'Test-DbaDiskSpeed',
        'Get-DbaDbExtentDiff',
        'Read-DbaAuditFile',
        'Get-DbaDbCompression',
        'Invoke-DbaDbDecryptObject',
        'Get-DbaDbForeignKey',
        'Get-DbaDbCheckConstraint',
        'Remove-DbaDbCheckConstraint',
        'Set-DbaAgentAlert',
        'Get-DbaWaitResource',
        'Get-DbaDbPageInfo',
        'Get-DbaConnection',
        'Test-DbaLoginPassword',
        'Get-DbaErrorLogConfig',
        'Set-DbaErrorLogConfig',
        'Get-DbaPlanCache',
        'Clear-DbaPlanCache',
        'ConvertTo-DbaTimeline',
        'Get-DbaDbMail',
        'Get-DbaDbMailAccount',
        'Get-DbaDbMailProfile',
        'Get-DbaDbMailConfig',
        'Get-DbaDbMailServer',
        'New-DbaDbMailServer',
        'New-DbaDbMailAccount',
        'New-DbaDbMailProfile',
        'Get-DbaResourceGovernor',
        'Get-DbaRgResourcePool',
        'Get-DbaRgWorkloadGroup',
        'Get-DbaRgClassifierFunction',
        'Export-DbaInstance',
        'Invoke-DbatoolsRenameHelper',
        'Measure-DbatoolsImport',
        'Get-DbaDeprecatedFeature',
        'Test-DbaDeprecatedFeature'
        'Get-DbaDbFeatureUsage',
        'Stop-DbaEndpoint',
        'Start-DbaEndpoint',
        'Set-DbaDbMirror',
        'Repair-DbaDbMirror',
        'Remove-DbaEndpoint',
        'Remove-DbaDbMirrorMonitor',
        'Remove-DbaDbMirror',
        'New-DbaEndpoint',
        'Invoke-DbaDbMirroring',
        'Invoke-DbaDbMirrorFailover',
        'Get-DbaDbMirrorMonitor',
        'Get-DbaDbMirror',
        'Add-DbaDbMirrorMonitor',
        'Test-DbaEndpoint',
        'Get-DbaDbSharePoint',
        'Get-DbaDbMemoryUsage',
        'Clear-DbaLatchStatistics',
        'Get-DbaCpuRingBuffer',
        'Get-DbaIoLatency',
        'Get-DbaLatchStatistic',
        'Get-DbaSpinLockStatistic',
        'Add-DbaAgDatabase',
        'Add-DbaAgListener',
        'Add-DbaAgReplica',
        'Grant-DbaAgPermission',
        'Invoke-DbaAgFailover',
        'Join-DbaAvailabilityGroup',
        'New-DbaAvailabilityGroup',
        'Remove-DbaAgDatabase',
        'Remove-DbaAgListener',
        'Remove-DbaAvailabilityGroup',
        'Revoke-DbaAgPermission',
        'Get-DbaDbCompatibility',
        'Set-DbaDbCompatibility',
        'Invoke-DbatoolsFormatter',
        'Remove-DbaAgReplica',
        'Resume-DbaAgDbDataMovement',
        'Set-DbaAgListener',
        'Set-DbaAgReplica',
        'Set-DbaAvailabilityGroup',
        'Set-DbaEndpoint',
        'Suspend-DbaAgDbDataMovement',
        'Sync-DbaAvailabilityGroup',
        'Get-DbaMemoryCondition',
        'Remove-DbaDbBackupRestoreHistory',
        'New-DbaDatabase'
        'New-DbaDacOption',
        'Get-DbaDbccHelp',
        'Get-DbaDbccMemoryStatus',
        'Get-DbaDbccProcCache',
        'Get-DbaDbccUserOption',
        'Get-DbaAgentServer',
        'Set-DbaAgentServer',
        'Invoke-DbaDbccFreeCache'
        'Export-DbatoolsConfig',
        'Import-DbatoolsConfig',
        'Reset-DbatoolsConfig',
        'Unregister-DbatoolsConfig',
        'Join-DbaPath',
        'Resolve-DbaPath',
        'Import-DbaCsv',
        'Invoke-DbaDbDataMasking',
        'New-DbaDbMaskingConfig',
        'Get-DbaDbccSessionBuffer',
        'Get-DbaDbccStatistic',
        'Get-DbaDbDbccOpenTran',
        'Invoke-DbaDbccDropCleanBuffer',
        'Invoke-DbaDbDbccCheckConstraint',
        'Invoke-DbaDbDbccCleanTable',
        'Invoke-DbaDbDbccUpdateUsage',
        'Get-DbaDbIdentity',
        'Set-DbaDbIdentity',
        'Get-DbaRegServer',
        'Get-DbaRegServerStore',
        'Add-DbaRegServer',
        'Add-DbaRegServerGroup',
        'Export-DbaRegServer',
        'Import-DbaRegServer',
        'Move-DbaRegServer',
        'Move-DbaRegServerGroup',
        'Remove-DbaRegServer',
        'Remove-DbaRegServerGroup',
        'New-DbaCustomError',
        'Remove-DbaCustomError',
        'Get-DbaDbSequence',
        'New-DbaDbSequence',
        'Remove-DbaDbSequence',
        'Select-DbaDbSequenceNextValue',
        'Set-DbaDbSequence',
        'Get-DbaDbUserDefinedTableType',
        'Get-DbaDbServiceBrokerService',
        'Get-DbaDbServiceBrokerQueue ',
        'Set-DbaResourceGovernor',
        'New-DbaRgResourcePool',
        'Set-DbaRgResourcePool',
        'Remove-DbaRgResourcePool',
        'Get-DbaDbServiceBrokerQueue',
        'New-DbaLinkedServer',
        # Config system
        'Get-DbatoolsConfig',
        'Get-DbatoolsConfigValue',
        'Set-DbatoolsConfig',
        'Register-DbatoolsConfig',
        # Data generator
        'New-DbaDbDataGeneratorConfig',
        'Invoke-DbaDbDataGenerator',
        'Get-DbaRandomizedValue',
        'Get-DbaRandomizedDatasetTemplate',
        'Get-DbaRandomizedDataset',
        'Get-DbaRandomizedType',
        'Export-DbaDbTableData',
        'Export-DbaBinaryFile',
        'Import-DbaBinaryFile',
        'Get-DbaBinaryFileTable',
        'Backup-DbaServiceMasterKey',
        'Invoke-DbaDbPiiScan',
        'New-DbaAzAccessToken',
        'Add-DbaDbRoleMember',
        'Disable-DbaStartupProcedure',
        'Enable-DbaStartupProcedure',
        'Get-DbaDbFilegroup',
        'Get-DbaDbObjectTrigger',
        'Get-DbaStartupProcedure',
        'Get-DbatoolsChangeLog',
        'Get-DbaXESessionTargetFile',
        'Get-DbaDbRole',
        'New-DbaDbRole',
        'New-DbaDbTable',
        'New-DbaDiagnosticAdsNotebook',
        'New-DbaServerRole',
        'Remove-DbaDbRole',
        'Remove-DbaDbRoleMember',
        'Remove-DbaServerRole',
        'Test-DbaDbDataGeneratorConfig',
        'Test-DbaDbDataMaskingConfig',
        'Get-DbaAgentAlertCategory',
        'New-DbaAgentAlertCategory',
        'Install-DbaAgentAdminAlert',
        'Remove-DbaAgentAlert',
        'Remove-DbaAgentAlertCategory',
        'Save-DbaKbUpdate',
        'Get-DbaKbUpdate',
        'Get-DbaDbLogSpace',
        'Export-DbaDbRole',
        'Export-DbaServerRole',
        'Get-DbaBuild',
        'Update-DbaBuildReference',
        'Install-DbaFirstResponderKit',
        'Install-DbaWhoIsActive',
        'Update-Dbatools',
        'Add-DbaServerRoleMember',
        'Get-DbatoolsPath',
        'Set-DbatoolsPath',
        'Export-DbaSysDbUserObject',
        'Test-DbaDbQueryStore',
        'Install-DbaMultiTool',
        'New-DbaAgentOperator',
        'Remove-DbaAgentOperator',
        'Remove-DbaDbTableData',
        'Get-DbaDbSchema',
        'New-DbaDbSchema',
        'Set-DbaDbSchema',
        'Remove-DbaDbSchema',
        'Get-DbaDbSynonym',
        'New-DbaDbSynonym',
        'Remove-DbaDbSynonym',
        'Install-DbaDarlingData',
        'New-DbaDbFileGroup',
        'Remove-DbaDbFileGroup',
        'Set-DbaDbFileGroup',
        'Remove-DbaLinkedServer',
        'Test-DbaAvailabilityGroup',
        'Export-DbaUser',
        'Get-DbaSsisExecutionHistory',
        'New-DbaConnectionStringBuilder',
        'New-DbatoolsSupportPackage',
        'Export-DbaScript',
        'Get-DbaAgentJobOutputFile',
        'Set-DbaAgentJobOutputFile',
        'Import-DbaXESessionTemplate',
        'Export-DbaXESessionTemplate',
        'Import-DbaSpConfigure',
        'Export-DbaSpConfigure',
        'Test-DbaMaxMemory',
        'Install-DbaMaintenanceSolution',
        'Get-DbaManagementObject',
        'Set-DbaAgentOperator',
        'Remove-DbaExtendedProperty',
        'Get-DbaExtendedProperty',
        'Set-DbaExtendedProperty',
        'Add-DbaExtendedProperty',
        'Get-DbaOleDbProvider',
        'Get-DbaConnectedInstance',
        'Disconnect-DbaInstance',
        'Set-DbaDefaultPath',
        'New-DbaDacProfile',
        'Export-DbaDacPackage',
        'Remove-DbaDbUdf',
        'Save-DbaCommunitySoftware',
        'Update-DbaMaintenanceSolution',
        'Remove-DbaServerRoleMember',
        'Remove-DbaDbMailProfile',
        'Remove-DbaDbMailAccount',
        'Set-DbaRgWorkloadGroup',
        'New-DbaRgWorkloadGroup',
        'Remove-DbaRgWorkloadGroup',
        'New-DbaLinkedServerLogin',
        'Remove-DbaLinkedServerLogin',
        'Remove-DbaCredential',
        'Remove-DbaAgentProxy'
    )
    $script:noncoresmo = @(
        # SMO issues
        'Get-DbaRepDistributor',
        'Copy-DbaPolicyManagement',
        'Copy-DbaDataCollector',
        'Get-DbaPbmCategory',
        'Get-DbaPbmCategorySubscription',
        'Get-DbaPbmCondition',
        'Get-DbaPbmObjectSet',
        'Get-DbaPbmPolicy',
        'Get-DbaPbmStore',
        'Get-DbaRepPublication',
        'Test-DbaRepLatency',
        'Export-DbaRepServerSetting',
        'Get-DbaRepServer'
    )
    $script:windowsonly = @(
        # filesystem (\\ related),
        'Move-DbaDbFile'
        'Copy-DbaBackupDevice',
        'Read-DbaXEFile',
        'Watch-DbaXESession',
        # Registry
        'Get-DbaRegistryRoot',
        # GAC
        'Test-DbaManagementObject',
        # CM and Windows functions
        'Get-DbaInstalledPatch',
        'Get-DbaFirewallRule',
        'New-DbaFirewallRule',
        'Remove-DbaFirewallRule',
        'Rename-DbaDatabase',
        'Get-DbaNetworkConfiguration',
        'Set-DbaNetworkConfiguration',
        'Get-DbaExtendedProtection',
        'Set-DbaExtendedProtection',
        'Install-DbaInstance',
        'Invoke-DbaAdvancedInstall',
        'Update-DbaInstance',
        'Invoke-DbaAdvancedUpdate',
        'Invoke-DbaPfRelog',
        'Get-DbaPfDataCollectorCounter',
        'Get-DbaPfDataCollectorCounterSample',
        'Get-DbaPfDataCollector',
        'Get-DbaPfDataCollectorSet',
        'Start-DbaPfDataCollectorSet',
        'Stop-DbaPfDataCollectorSet',
        'Export-DbaPfDataCollectorSetTemplate',
        'Get-DbaPfDataCollectorSetTemplate',
        'Import-DbaPfDataCollectorSetTemplate',
        'Remove-DbaPfDataCollectorSet',
        'Add-DbaPfDataCollectorCounter',
        'Remove-DbaPfDataCollectorCounter',
        'Get-DbaPfAvailableCounter',
        'Export-DbaXECsv',
        'Get-DbaOperatingSystem',
        'Get-DbaComputerSystem',
        'Set-DbaPrivilege',
        'Set-DbaTcpPort',
        'Set-DbaCmConnection',
        'Get-DbaUptime',
        'Get-DbaMemoryUsage',
        'Clear-DbaConnectionPool',
        'Get-DbaLocaleSetting',
        'Get-DbaFilestream',
        'Enable-DbaFilestream',
        'Disable-DbaFilestream',
        'Get-DbaCpuUsage',
        'Get-DbaPowerPlan',
        'Get-DbaWsfcAvailableDisk',
        'Get-DbaWsfcCluster',
        'Get-DbaWsfcDisk',
        'Get-DbaWsfcNetwork',
        'Get-DbaWsfcNetworkInterface',
        'Get-DbaWsfcNode',
        'Get-DbaWsfcResource',
        'Get-DbaWsfcResourceGroup',
        'Get-DbaWsfcResourceType',
        'Get-DbaWsfcRole',
        'Get-DbaWsfcSharedVolume',
        'Export-DbaCredential',
        'Export-DbaLinkedServer',
        'Get-DbaFeature',
        'Update-DbaServiceAccount',
        'Remove-DbaClientAlias',
        'Disable-DbaAgHadr',
        'Enable-DbaAgHadr',
        'Stop-DbaService',
        'Start-DbaService',
        'Restart-DbaService',
        'New-DbaClientAlias',
        'Get-DbaClientAlias',
        'Stop-DbaExternalProcess',
        'Get-DbaExternalProcess',
        'Remove-DbaNetworkCertificate',
        'Enable-DbaForceNetworkEncryption',
        'Disable-DbaForceNetworkEncryption',
        'Get-DbaForceNetworkEncryption',
        'Get-DbaHideInstance',
        'Enable-DbaHideInstance',
        'Disable-DbaHideInstance',
        'New-DbaComputerCertificateSigningRequest',
        'Remove-DbaComputerCertificate',
        'New-DbaComputerCertificate',
        'Get-DbaComputerCertificate',
        'Add-DbaComputerCertificate',
        'Backup-DbaComputerCertificate',
        'Test-DbaComputerCertificateExpiration',
        'Get-DbaNetworkCertificate',
        'Set-DbaNetworkCertificate',
        'Remove-DbaDbLogshipping',
        'Invoke-DbaDbLogShipping',
        'New-DbaCmConnection',
        'Get-DbaCmConnection',
        'Remove-DbaCmConnection',
        'Test-DbaCmConnection',
        'Get-DbaCmObject',
        'Set-DbaStartupParameter',
        'Get-DbaNetworkActivity',
        'Get-DbaInstanceProtocol',
        'Get-DbaPrivilege',
        'Get-DbaMsdtc',
        'Get-DbaPageFileSetting',
        'Copy-DbaCredential',
        'Test-DbaConnection',
        'Reset-DbaAdmin',
        'Copy-DbaLinkedServer',
        'Get-DbaDiskSpace',
        'Test-DbaDiskAllocation',
        'Test-DbaPowerPlan',
        'Set-DbaPowerPlan',
        'Test-DbaDiskAlignment',
        'Get-DbaStartupParameter',
        'Get-DbaSpn',
        'Test-DbaSpn',
        'Set-DbaSpn',
        'Remove-DbaSpn',
        'Get-DbaService',
        'Get-DbaClientProtocol',
        'Get-DbaWindowsLog',
        # WPF
        'Show-DbaInstanceFileSystem',
        'Show-DbaDbList',
        # AD
        'Test-DbaWindowsLogin',
        'Find-DbaLoginInGroup',
        # 3rd party non-core DLL or sqlpackage.exe
        'Install-DbaSqlWatch',
        'Uninstall-DbaSqlWatch',
        # Unknown
        'Get-DbaErrorLog'
    )

    # If a developer or appveyor calls the psm1 directly, they want all functions
    # So do not explicitly export because everything else is then implicitly excluded
    if (-not $script:serialimport) {
        $exports =
        @(if (($PSVersionTable.Platform)) {
                if ($PSVersionTable.Platform -ne "Win32NT") {
                    $script:xplat
                } else {
                    $script:xplat
                    $script:windowsonly
                }
            } else {
                $script:xplat
                $script:windowsonly
                $script:noncoresmo
            })

        $aliasExport = @(
            foreach ($k in $script:Renames.Keys) {
                $k
            }
            foreach ($k in $script:Forever.Keys) {
                $k
            }
            foreach ($c in $script:shortcuts.Keys) {
                $c
            }
        )

        Export-ModuleMember -Alias $aliasExport -Function $exports -Cmdlet Select-DbaObject, Set-DbatoolsConfig
        Write-ImportTime -Text "Exporting explicit module members"
    } else {
        Export-ModuleMember -Alias * -Function * -Cmdlet *
        Write-ImportTime -Text "Exporting all module members"
    }
}

$myInv = $MyInvocation
if ($option.LoadTypes -or
    ($myInv.Line -like '*.psm1*' -and
        (-not (Get-TypeData -TypeName Microsoft.SqlServer.Management.Smo.Server)
        ))) {
    Update-TypeData -AppendPath (Resolve-Path -Path "$script:PSModuleRoot\xml\dbatools.Types.ps1xml")
    Write-ImportTime -Text "Updating type data"
}

Import-Command -Path "$script:PSModuleRoot/bin/type-extensions.ps1"
Write-ImportTime -Text "Loading type extensions"

$loadedModuleNames = (Get-Module sqlserver, sqlps -ErrorAction Ignore).Name
if ($loadedModuleNames -contains 'sqlserver' -or $loadedModuleNames -contains 'sqlps') {
    if (Get-DbatoolsConfigValue -FullName Import.SqlpsCheck) {
        Write-Warning -Message 'SQLPS or SqlServer was previously imported during this session. If you encounter weird issues with dbatools, please restart PowerShell, then import dbatools without loading SQLPS or SqlServer first.'
        Write-Warning -Message 'To disable this message, type: Set-DbatoolsConfig -Name Import.SqlpsCheck -Value $false -PassThru | Register-DbatoolsConfig'
    }
}
Write-ImportTime -Text "Checking for SqlServer or SQLPS"
#endregion Post-Import Cleanup

# Removal of runspaces is needed to successfully close PowerShell ISE
if (Test-Path -Path Variable:global:psISE) {
    $onRemoveScript = {
        Get-Runspace | Where-Object Name -Like dbatools* | ForEach-Object -Process { $_.Dispose() }
    }
    $ExecutionContext.SessionState.Module.OnRemove += $onRemoveScript
    Register-EngineEvent -SourceIdentifier ([System.Management.Automation.PsEngineEvent]::Exiting) -Action $onRemoveScript
}
Write-ImportTime -Text "Checking for some ISE stuff"

# Create collection for servers
$script:connectionhash = @{ }


if (Get-DbatoolsConfigValue -FullName Import.EncryptionMessageCheck) {
    $trustcert = Get-DbatoolsConfigValue -FullName sql.connection.trustcert
    $encrypt = Get-DbatoolsConfigValue -FullName sql.connection.encrypt
    if (-not $trustcert -or $encrypt -in "Mandatory", "$true") {
        # keep it write-host for psv3
        Write-Message -Level Output -Message '
/   /                                                                     /   /
| O |                                                                     | O |
|   |- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -|   |
| O |                                                                     | O |
|   |                                                                     |   |
| O |                                                                     | O |
|   |                       C O M P U T E R                               |   |
| O |                                                                     | O |
|   |                               M E S S A G E                         |   |
| O |                                                                     | O |
|   |                                                                     |   |
| O |- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -| O |
|   |                                                                     |   |

Microsoft changed the encryption defaults in their SqlClient library, which may
cause your connections to fail.

You can change the defaults with Set-DbatoolsConfig but dbatools also makes it
easy to setup encryption. Check out dbatools.io/newdefaults for more information.

To disable this message, run:

Set-DbatoolsConfig -Name Import.EncryptionMessageCheck -Value $false -PassThru |
Register-DbatoolsConfig'
    }
}

[Dataplat.Dbatools.dbaSystem.SystemHost]::ModuleImported = $true
# SIG # Begin signature block
# MIIlGwYJKoZIhvcNAQcCoIIlDDCCJQgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDjItJRA4cMOCH2
# SVzkZhziuardDr6SQL6ZiLCLAtMwd6CCDMgwggZOMIIENqADAgECAhBLMDfpm+8T
# XqyVT0PdZkLSMA0GCSqGSIb3DQEBCwUAMHgxCzAJBgNVBAYTAlVTMQ4wDAYDVQQI
# DAVUZXhhczEQMA4GA1UEBwwHSG91c3RvbjERMA8GA1UECgwIU1NMIENvcnAxNDAy
# BgNVBAMMK1NTTC5jb20gQ29kZSBTaWduaW5nIEludGVybWVkaWF0ZSBDQSBSU0Eg
# UjEwHhcNMjMwNjIwMTk1MTIxWhcNMjYwNjE5MTk1MTIxWjBXMQswCQYDVQQGEwJV
# UzERMA8GA1UECAwIVmlyZ2luaWExDzANBgNVBAcMBlZpZW5uYTERMA8GA1UECgwI
# ZGJhdG9vbHMxETAPBgNVBAMMCGRiYXRvb2xzMIIBojANBgkqhkiG9w0BAQEFAAOC
# AY8AMIIBigKCAYEAsnNUw/26q2McXrWYtcUI80TpswxXxVdfPZZGDJIqI2njrR39
# Qa2wJVjR6/Wgzhn4NdVUBdmAxlXVcD7dqaaB2fjHOiBnGparqk0jM1YslANmqRtQ
# 4nV3dxB3A0O+usmGuYudGOGCV2r90aT0TQck4abKIfoYQTjiRH/PflzPxG/KGZq6
# JwcsPRddX7hybl1BKNsTtCNPV/vLX78K1oFpUH80VDoBK5ZYkVSIdQHyUP7a6iHD
# esT6FOY/ek8IysyeO+49avBLNlUmkTex0yCCrcWz4EVYZ73cDDRB6xkkiVEKxIIU
# zudMudqkrcchJXMJ28ClS6urNkeengtpj3406xAdzJdA1XMXSXuj6GMSEBZh07KN
# qtLKIH93ZDFLi6sOADUYfzg9vJNOMka4BlXPepaxSxGoIvVcShCKLV3NYC/NizA+
# uTNyT0/p8no50y3uu4UiU5nO7AYgLc7tBzaS/pKgWaidhdamvCrZU7Xmw1QRtn1z
# Gb5Ar5cfFFLtu9QJAgMBAAGjggFzMIIBbzAMBgNVHRMBAf8EAjAAMB8GA1UdIwQY
# MBaAFFTC/hCVAJPNavXnwNfZsku4jwzjMFgGCCsGAQUFBwEBBEwwSjBIBggrBgEF
# BQcwAoY8aHR0cDovL2NlcnQuc3NsLmNvbS9TU0xjb20tU3ViQ0EtQ29kZVNpZ25p
# bmctUlNBLTQwOTYtUjEuY2VyMFEGA1UdIARKMEgwCAYGZ4EMAQQBMDwGDCsGAQQB
# gqkwAQMDATAsMCoGCCsGAQUFBwIBFh5odHRwczovL3d3dy5zc2wuY29tL3JlcG9z
# aXRvcnkwEwYDVR0lBAwwCgYIKwYBBQUHAwMwTQYDVR0fBEYwRDBCoECgPoY8aHR0
# cDovL2NybHMuc3NsLmNvbS9TU0xjb20tU3ViQ0EtQ29kZVNpZ25pbmctUlNBLTQw
# OTYtUjEuY3JsMB0GA1UdDgQWBBQN3V4L0H/4IdRfPzpFyba6iDG14TAOBgNVHQ8B
# Af8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIBAFxbDgeQywYqapKmqmA8yC3YLCYM
# 0dDdt/YeSVY+ASC3yEvnOWvBM3ZY9ku7+GqerCg9RL5+o/c0De2W+WJVsJ3OFdep
# lrQX/6YDymxA209vqLNsoCQ++k5ae6GFd7pVlNoK5sQF0PtX4snD0ppiXAns1OnX
# vuqa+cq1JnAxS1igQbdpNsqOwbDi5Rkom4U/dVhVrPW9aRqD2c4iSJyZbz8aAFK3
# AW9C9nOMDksZsiBsPNi2CVF/SkdUBTY33jRl3N1asA511lVRthc8rLeRO8b61fls
# C8KvTWQ8xOIjC64urNnNZ8Z9c/YwMKU7e4qsD0FmE80iDWG1AK46YC12tHTZOhlh
# YtKBRynaDjOn1+nl9SAdSEQobV4G8dGVZkVT2Q5BQlrgolOPoYEs0qzSc8iKdH0A
# SrRwo6UWlo20ZePKS05ArJh8yWAvhFhO35weL8b0upXmVDczSedQmSRfv30ikV+4
# EwLS71RjKaYmy5MwQ27ADvMyG7seEXAoADsvuP1HaLdHxznNQ3DnX4EFnMgavhuq
# q798/nWPDN+M/dN1c4u5Pb0zqiq7/dBBmvJSmTYF/qsY7o4uXnejuH9Z9VklAVfg
# exA0fUAalcp5QlG9fsseY/KFynn/mM++zrI2eQiMedW0BBnNNVPHv42QLdmCXyQb
# DwRh3hv2B3uW5sSuMIIGcjCCBFqgAwIBAgIIZDNR08c4nwgwDQYJKoZIhvcNAQEL
# BQAwfDELMAkGA1UEBhMCVVMxDjAMBgNVBAgMBVRleGFzMRAwDgYDVQQHDAdIb3Vz
# dG9uMRgwFgYDVQQKDA9TU0wgQ29ycG9yYXRpb24xMTAvBgNVBAMMKFNTTC5jb20g
# Um9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eSBSU0EwHhcNMTYwNjI0MjA0NDMw
# WhcNMzEwNjI0MjA0NDMwWjB4MQswCQYDVQQGEwJVUzEOMAwGA1UECAwFVGV4YXMx
# EDAOBgNVBAcMB0hvdXN0b24xETAPBgNVBAoMCFNTTCBDb3JwMTQwMgYDVQQDDCtT
# U0wuY29tIENvZGUgU2lnbmluZyBJbnRlcm1lZGlhdGUgQ0EgUlNBIFIxMIICIjAN
# BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAn4MTc6qwxm0hy9uLeod00HHcjpdy
# muS7iDS03YADxi9FpHSavx4PUOqebXjzn/pRJqk9ndGylFc++zmJG5ErVu9ny+YL
# 4w45jMY19Iw93SXpAawXQn1YFkDc+dUoRB2VZDBhOmTyl9dzTH17IwJt83XrVT1v
# qi3Er750rF3+arb86lx56Q9DnLVSBQ/vPrGxj9BJrabjQhlUP/MvDqHLfP4T+SM5
# 2iUcuD4ASjpvMjA3ZB7HrnUH2FXSGMkOiryjXPB8CqeFgcIOr4+ZXNNgJbyDWmkc
# JRPNcvXrnICb3CxnxN3JCZjVc+vEIaPlMo4+L1KYxmA3ZIyyb0pUchjMJ4f6zXWi
# YyFMtT1k/Summ1WvJkxgtLlc/qtDva3QE2ZQHwvSiab/14AG8cMRAjMzYRf3Vh+O
# Lzto5xXxd1ZKKZ4D2sIrJmEyW6BW5UkpjTan9cdSolYDIC84eIC99gauQTTLlEW9
# m8eJGB8Luv+prmpAmRPd71DfAbryBNbQMd80OF5XW8g4HlbUrEim7f/5uME77cIk
# vkRgp3fN1T2YWbRD6qpgfc3C5S/x6/XUINWXNG5dBGsFEdLTkowJJ0TtTzUxRn50
# GQVi7Inj6iNwmOTRL9SKExhGk2XlWHPTTD0neiI/w/ijVbf55oeC7EUexW46fLFO
# uato95tj1ZFBvKkCAwEAAaOB+zCB+DAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQY
# MBaAFN0ECQei9Xp9UlMSkpXuOIAlDaZZMDAGCCsGAQUFBwEBBCQwIjAgBggrBgEF
# BQcwAYYUaHR0cDovL29jc3BzLnNzbC5jb20wEQYDVR0gBAowCDAGBgRVHSAAMBMG
# A1UdJQQMMAoGCCsGAQUFBwMDMDsGA1UdHwQ0MDIwMKAuoCyGKmh0dHA6Ly9jcmxz
# LnNzbC5jb20vc3NsLmNvbS1yc2EtUm9vdENBLmNybDAdBgNVHQ4EFgQUVML+EJUA
# k81q9efA19myS7iPDOMwDgYDVR0PAQH/BAQDAgGGMA0GCSqGSIb3DQEBCwUAA4IC
# AQD1DyaHcK+Zosr11snwjWY9OYLTiCPYgr+PVIQnttODB9eeJ4lNhI5U0SDuYEPb
# V0I8x7CV9r7M6qM9jk8GxitZhn/rcxvK5UAm4D1vzPa9ccbNfQ4gQDnWBdKvlAi/
# f8JRtyu1e4Mh8GPa5ZzhaS51HU7LYR71pTPfAp0V2e1pk1e6RkUugLxlvucSPt5H
# /5CcEK32VrKk1PrW/C68lyGzdoPSkfoGUNGxgCiA/tutD2ft+H3c2XBberpotbNK
# ZheP5/DnV91p/rxe4dWMnxO7lZoV+3krhdVtPmdHbhsHXPtURQ8WES4Rw7C8tW4c
# M1eUHv5CNEaOMVBO2zNXlfo45OYS26tYLkW32SLK9FpHSSwo6E+MQjxkaOnmQ6wZ
# kanHE4Jf/HEKN7edUHs8XfeiUoI15LXn0wpva/6N+aTX1R1L531iCPjZ16yZSdu1
# hEEULvYuYJdTS5r+8Yh6dLqedeng2qfJzCw7e0wKeM+U9zZgtoM8ilTLTg1oKpQR
# dSYU6iA3zOt5F3ZVeHFt4kk4Mzfb5GxZxyNi5rzOLlRL/V4DKsjdHktxRNB1PjFi
# ZYsppu0k4XodhDR/pBd8tKx9PzVYy8O/Gt2fVFZtReVT84iKKzGjyj5Q0QA07CcI
# w2fGXOhov88uFmW4PGb/O7KVq5qNncyU8O14UH/sZEejnTGCF6kwghelAgEBMIGM
# MHgxCzAJBgNVBAYTAlVTMQ4wDAYDVQQIDAVUZXhhczEQMA4GA1UEBwwHSG91c3Rv
# bjERMA8GA1UECgwIU1NMIENvcnAxNDAyBgNVBAMMK1NTTC5jb20gQ29kZSBTaWdu
# aW5nIEludGVybWVkaWF0ZSBDQSBSU0EgUjECEEswN+mb7xNerJVPQ91mQtIwDQYJ
# YIZIAWUDBAIBBQCgfDAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG
# 9w0BCQQxIgQgdjZc8CIBG9hiuf5e6UjLtjVX3gP0lyNrR/mCkDDQaaEwDQYJKoZI
# hvcNAQEBBQAEggGAWOoAH6mczzpWzI5fsE04WoooKgn92NnAkixCqnwwcqrZYr7A
# veJYbEeT2mmw75hOd1QDSBCoLQdhwNJ/PMdOZVNpzSRpgRzlD+/CwfRIJqfKTcjP
# ejmb4k7TOrIGlsK02rzOa0LwhTvQ6Z3nurOyjj8bcdB+rAhlf3JoSpqPqegxOt4u
# FUGTkGp8ELbVpy5kjsnxcsgnd2TLuOHRx9TilznUZLbinvAz54yKCN6IRs8CgRpc
# p0o7Q3JkP/SZbM14gSPpX4QdsocrGTjoOSRRZdMpeNVllqL4cl1wZiUJfYFYIwRZ
# deOAKSUJs+vfZHY6tjrZIHUj0q9+TE0yuSJ+zCFYgruOI08DYojoEn1eCjRoskQT
# ACqXD05BRYN761d5Yq2NeEAHglPVN2t3d+UhHXDArSgcZGINz5kM756TN+ZC/f7U
# cq7WWeUAwqqMmrcx7YJ1OQQ56lSGKVfx4AnIxdRrRMueWwk+5E0DIOrNkk/IzZII
# conkL9TGNbwBCbnToYIU7zCCFOsGCisGAQQBgjcDAwExghTbMIIU1wYJKoZIhvcN
# AQcCoIIUyDCCFMQCAQMxDTALBglghkgBZQMEAgEwdwYLKoZIhvcNAQkQAQSgaARm
# MGQCAQEGDCsGAQQBgqkwAQMGATAxMA0GCWCGSAFlAwQCAQUABCD7nqktnarT3nWu
# opQVlnIOi/epIrjSX4BRXAgZjR/PFAIIKyddChMhPq0YDzIwMjMwNzI1MTE0NTQx
# WjADAgEBoIIR2TCCBPkwggLhoAMCAQICEBrWCKfWNLXN3pfLo8zw0EswDQYJKoZI
# hvcNAQELBQAwczELMAkGA1UEBhMCVVMxDjAMBgNVBAgMBVRleGFzMRAwDgYDVQQH
# DAdIb3VzdG9uMREwDwYDVQQKDAhTU0wgQ29ycDEvMC0GA1UEAwwmU1NMLmNvbSBU
# aW1lc3RhbXBpbmcgSXNzdWluZyBSU0EgQ0EgUjEwHhcNMjIxMjA5MTgzMDUxWhcN
# MzIxMjA2MTgzMDUwWjBrMQswCQYDVQQGEwJVUzEOMAwGA1UECAwFVGV4YXMxEDAO
# BgNVBAcMB0hvdXN0b24xETAPBgNVBAoMCFNTTCBDb3JwMScwJQYDVQQDDB5TU0wu
# Y29tIFRpbWVzdGFtcGluZyBVbml0IDIwMjIwWTATBgcqhkjOPQIBBggqhkjOPQMB
# BwNCAATefPqSJZSy2TTZyF4GhypEr9YCY44KQr+4/R2+4QOHyAxCLyYMIolVLQza
# qOySeI6nI4j/+L1aB3Jv9HeBPTu4o4IBWjCCAVYwHwYDVR0jBBgwFoAUDJ0QJY6a
# pxuZh0PPCH7hvYGQ9M8wUQYIKwYBBQUHAQEERTBDMEEGCCsGAQUFBzAChjVodHRw
# Oi8vY2VydC5zc2wuY29tL1NTTC5jb20tdGltZVN0YW1waW5nLUktUlNBLVIxLmNl
# cjBRBgNVHSAESjBIMDwGDCsGAQQBgqkwAQMGATAsMCoGCCsGAQUFBwIBFh5odHRw
# czovL3d3dy5zc2wuY29tL3JlcG9zaXRvcnkwCAYGZ4EMAQQCMBYGA1UdJQEB/wQM
# MAoGCCsGAQUFBwMIMEYGA1UdHwQ/MD0wO6A5oDeGNWh0dHA6Ly9jcmxzLnNzbC5j
# b20vU1NMLmNvbS10aW1lU3RhbXBpbmctSS1SU0EtUjEuY3JsMB0GA1UdDgQWBBQF
# upPR3+IUrCAqhlkxfyhyDq2sXzAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQEL
# BQADggIBAFqotJYQYw1EaMzHk5NlJLaJzxDf3njeZNS3iMrOvZPAMnJxzPeIWGqn
# eI6rxGdOwewqS3gYcCPZKEag2WVTjrhBpFtN5oCdbnaCQuWcJHvf3H104NBhYsqk
# CrMwWoo3E2Udaw49PBeZoZFMykPraTG/I3W76FoP1BuzI9xhSG56DzRn3lIwIg80
# JgimsRASJEwcw4K2Uk0a1aO3hJ8/RHhZ7EZ2bSEQfyym66kUbuGsksxzbgtCSZpk
# 76XLfT+rSOIL5SY+WCIiVd+FrUPfLhFMSzxjwbVuRA5FLdcL7+p9kuSggpUI+m2f
# zwropdX6GHpp5EfYdpWGZDdB9R+fbKiLC54gbzd2ubArEn1QHOwe5K1qXqjYrela
# tIbNlA5NUS7BJmmcjlLtiGMfqw/fmSfGOvo1le1HFnRFj1QJYX9rYku2iTtjGS6j
# iUAmP6Q2yiunn8nNVtgUYCorD5NsgbmVEqzccIIkKImW9IxWHOSFGu41ZswpSGKD
# ABcdq+NcUVTwjg6QlvGi3rQtAVZKaXWzbbZSiR7hM0CDtcPwXPKdhbtdGkJmvCvB
# fX357q7+dmkB3XHYLteoxEfClzMRMJ9AKF0qSh6hf4PTg9WbLwFNCClWQeM9CXtp
# i5EWD3wu5DlfIDpInNwUZDPOrVO0DGu9+msd72naMPXZTl+cvrv9MIIF2DCCBMCg
# AwIBAgIRAOQnBJX2jJHW0Ox7SU6k3xwwDQYJKoZIhvcNAQELBQAwfjELMAkGA1UE
# BhMCUEwxIjAgBgNVBAoTGVVuaXpldG8gVGVjaG5vbG9naWVzIFMuQS4xJzAlBgNV
# BAsTHkNlcnR1bSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTEiMCAGA1UEAxMZQ2Vy
# dHVtIFRydXN0ZWQgTmV0d29yayBDQTAeFw0xODA5MTEwOTI2NDdaFw0yMzA5MTEw
# OTI2NDdaMHwxCzAJBgNVBAYTAlVTMQ4wDAYDVQQIDAVUZXhhczEQMA4GA1UEBwwH
# SG91c3RvbjEYMBYGA1UECgwPU1NMIENvcnBvcmF0aW9uMTEwLwYDVQQDDChTU0wu
# Y29tIFJvb3QgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkgUlNBMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEA+Q/doyt9y9Aq/uxnhabnLhu6d+Hj9a+k7PpK
# XZHEV0drGHdrdvL9k+Q9D8IWngtmw1aUnheDhc5W7/IW/QBi9SIJVOhlF05BueBP
# RpeqG8i4bmJeabFf2yoCfvxsyvNB2O3Q6Pw/YUjtsAMUHRAOSxngu07shmX/NvNe
# ZwILnYZVYf16OO3+4hkAt2+hUGJ1dDyg+sglkrRueiLH+B6h47LdkTGrKx0E/6VK
# BDfphaQzK/3i1lU0fBmkSmjHsqjTt8qhk4jrwZe8jPkd2SKEJHTHBD1qqSmTzOu4
# W+H+XyWqNFjIwSNUnRuYEcM4nH49hmylD0CGfAL0XAJPKMuucZ8POsgz/hElNer8
# usVgPdl8GNWyqdN1eANyIso6wx/vLOUuqfqeLLZRRv2vA9bqYGjqhRY2a4XpHsCz
# 3cQk3IAqgUFtlD7I4MmBQQCeXr9/xQiYohgsQkCz+W84J0tOgPQ9gUfgiHzqHM61
# dVxRLhwrfxpyKOcAtdF0xtfkn60Hk7ZTNTX8N+TD9l0WviFz3pIK+KBjaryWkmo+
# +LxlVZve9Q2JJgT8JRqmJWnLwm3KfOJZX5es6+8uyLzXG1k8K8zyGciTaydjGc/8
# 6Sb4ynGbf5P+NGeETpnr/LN4CTNwumamdu0bc+sapQ3EIhMglFYKTixsTrH9z5wJ
# uqIz7YcCAwEAAaOCAVEwggFNMBIGA1UdEwEB/wQIMAYBAf8CAQIwHQYDVR0OBBYE
# FN0ECQei9Xp9UlMSkpXuOIAlDaZZMB8GA1UdIwQYMBaAFAh2zcsH/yT2xc3tu5C8
# 4oQ3RnX3MA4GA1UdDwEB/wQEAwIBBjA2BgNVHR8ELzAtMCugKaAnhiVodHRwOi8v
# c3NsY29tLmNybC5jZXJ0dW0ucGwvY3RuY2EuY3JsMHMGCCsGAQUFBwEBBGcwZTAp
# BggrBgEFBQcwAYYdaHR0cDovL3NzbGNvbS5vY3NwLWNlcnR1bS5jb20wOAYIKwYB
# BQUHMAKGLGh0dHA6Ly9zc2xjb20ucmVwb3NpdG9yeS5jZXJ0dW0ucGwvY3RuY2Eu
# Y2VyMDoGA1UdIAQzMDEwLwYEVR0gADAnMCUGCCsGAQUFBwIBFhlodHRwczovL3d3
# dy5jZXJ0dW0ucGwvQ1BTMA0GCSqGSIb3DQEBCwUAA4IBAQAflZojVO6FwvPUb7np
# BI9Gfyz3MsCnQ6wHAO3gqUUt/Rfh7QBAyK+YrPXAGa0boJcwQGzsW/ujk06MiWIb
# fPA6X6dCz1jKdWWcIky/dnuYk5wVgzOxDtxROId8lZwSaZQeAHh0ftzABne6cC2H
# LNdoneO6ha1J849ktBUGg5LGl6RAk4ut8WeUtLlaZ1Q8qBvZBc/kpPmIEgAGiCWF
# 1F7u85NX1oH4LK739VFIq7ZiOnnb7C7yPxRWOsjZy6SiTyWo0ZurLTAgUAcab/Hx
# lB05g2PoH/1J0OgdRrJGgia9nJ3homhBSFFuevw1lvRU0rwrROVH13eCpUqrX5cz
# qyQRMIIG/DCCBOSgAwIBAgIQbVIYcIfoI02FYADQgI+TVjANBgkqhkiG9w0BAQsF
# ADB8MQswCQYDVQQGEwJVUzEOMAwGA1UECAwFVGV4YXMxEDAOBgNVBAcMB0hvdXN0
# b24xGDAWBgNVBAoMD1NTTCBDb3Jwb3JhdGlvbjExMC8GA1UEAwwoU1NMLmNvbSBS
# b290IENlcnRpZmljYXRpb24gQXV0aG9yaXR5IFJTQTAeFw0xOTExMTMxODUwMDVa
# Fw0zNDExMTIxODUwMDVaMHMxCzAJBgNVBAYTAlVTMQ4wDAYDVQQIDAVUZXhhczEQ
# MA4GA1UEBwwHSG91c3RvbjERMA8GA1UECgwIU1NMIENvcnAxLzAtBgNVBAMMJlNT
# TC5jb20gVGltZXN0YW1waW5nIElzc3VpbmcgUlNBIENBIFIxMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEArlEQE9L5PCCgIIXeyVAcZMnh/cXpNP8KfzFI
# 6HJaxV6oYf3xh/dRXPu35tDBwhOwPsJjoqgY/Tg6yQGBqt65t94wpx0rAgTVgEGM
# qGri6vCI6rEtSZVy9vagzTDHcGfFDc0Eu71mTAyeNCUhjaYTBkyANqp9m6IRrYEX
# OKdd/eREsqVDmhryd7dBTS9wbipm+mHLTHEFBdrKqKDM3fPYdBOro3bwQ6OmcDZ1
# qMY+2Jn1o0l4N9wORrmPcpuEGTOThFYKPHm8/wfoMocgizTYYeDG/+MbwkwjFZjW
# Kwb4hoHT2WK8pvGW/OE0Apkrl9CZSy2ulitWjuqpcCEm2/W1RofOunpCm5Qv10T9
# tIALtQo73GHIlIDU6xhYPH/ACYEDzgnNfwgnWiUmMISaUnYXijp0IBEoDZmGT4RT
# guiCmjAFF5OVNbY03BQoBb7wK17SuGswFlDjtWN33ZXSAS+i45My1AmCTZBV6obA
# VXDzLgdJ1A1ryyXz4prLYyfJReEuhAsVp5VouzhJVcE57dRrUanmPcnb7xi57VPh
# XnCuw26hw1Hd+ulK3jJEgbc3rwHPWqqGT541TI7xaldaWDo85k4lR2bQHPNGwHxX
# uSy3yczyOg57TcqqG6cE3r0KR6jwzfaqjTvN695GsPAPY/h2YksNgF+XBnUD9JBt
# L4c34AcCAwEAAaOCAYEwggF9MBIGA1UdEwEB/wQIMAYBAf8CAQAwHwYDVR0jBBgw
# FoAU3QQJB6L1en1SUxKSle44gCUNplkwgYMGCCsGAQUFBwEBBHcwdTBRBggrBgEF
# BQcwAoZFaHR0cDovL3d3dy5zc2wuY29tL3JlcG9zaXRvcnkvU1NMY29tUm9vdENl
# cnRpZmljYXRpb25BdXRob3JpdHlSU0EuY3J0MCAGCCsGAQUFBzABhhRodHRwOi8v
# b2NzcHMuc3NsLmNvbTA/BgNVHSAEODA2MDQGBFUdIAAwLDAqBggrBgEFBQcCARYe
# aHR0cHM6Ly93d3cuc3NsLmNvbS9yZXBvc2l0b3J5MBMGA1UdJQQMMAoGCCsGAQUF
# BwMIMDsGA1UdHwQ0MDIwMKAuoCyGKmh0dHA6Ly9jcmxzLnNzbC5jb20vc3NsLmNv
# bS1yc2EtUm9vdENBLmNybDAdBgNVHQ4EFgQUDJ0QJY6apxuZh0PPCH7hvYGQ9M8w
# DgYDVR0PAQH/BAQDAgGGMA0GCSqGSIb3DQEBCwUAA4ICAQCSGXUNplpCzxkH2fL8
# lPrAm/AV6USWWi9xM91Q5RN7mZN3D8T7cm1Xy7qmnItFukgdtiUzLbQokDJyFTrF
# 1pyLgGw/2hU3FJEywSN8crPsBGo812lyWFgAg0uOwUYw7WJQ1teICycX/Fug0KB9
# 4xwxhsvJBiRTpQyhu/2Kyu1Bnx7QQBA1XupcmfhbQrK5O3Q/yIi//kN0OkhQEiS0
# NlyPPYoRboHWC++wogzV6yNjBbKUBrMFxABqR7mkA0x1Kfy3Ud08qyLC5Z86C7JF
# BrMBfyhfPpKVlIiiTQuKz1rTa8ZW12ERoHRHcfEjI1EwwpZXXK5J5RcW6h7FZq/c
# ZE9kLRZhvnRKtb+X7CCtLx2h61ozDJmifYvuKhiUg9LLWH0Or9D3XU+xKRsRnfOu
# wHWuhWch8G7kEmnTG9CtD9Dgtq+68KgVHtAWjKk2ui1s1iLYAYxnDm13jMZm0KpR
# M9mLQHBK5Gb4dFgAQwxOFPBslf99hXWgLyYE33vTIi9p0gYqGHv4OZh1ElgGsvyK
# dUUJkAr5hfbDX6pYScJI8v9VNYm1JEyFAV9x4MpskL6kE2Sy8rOqS9rQnVnIyPWL
# i8N9K4GZvPit/Oy+8nFL6q5kN2SZbox5d69YYFe+rN1sDD4CpNWwBBTI/q0V4pkg
# vhL99IV2XasjHZf4peSrHdL4RjGCAlgwggJUAgEBMIGHMHMxCzAJBgNVBAYTAlVT
# MQ4wDAYDVQQIDAVUZXhhczEQMA4GA1UEBwwHSG91c3RvbjERMA8GA1UECgwIU1NM
# IENvcnAxLzAtBgNVBAMMJlNTTC5jb20gVGltZXN0YW1waW5nIElzc3VpbmcgUlNB
# IENBIFIxAhAa1gin1jS1zd6Xy6PM8NBLMAsGCWCGSAFlAwQCAaCCAWEwGgYJKoZI
# hvcNAQkDMQ0GCyqGSIb3DQEJEAEEMBwGCSqGSIb3DQEJBTEPFw0yMzA3MjUxMTQ1
# NDFaMCgGCSqGSIb3DQEJNDEbMBkwCwYJYIZIAWUDBAIBoQoGCCqGSM49BAMCMC8G
# CSqGSIb3DQEJBDEiBCCWzkJpf6J6yE8jxJ3/rypX8Yw5sd7Lnkl4N23LTHP9ujCB
# yQYLKoZIhvcNAQkQAi8xgbkwgbYwgbMwgbAEII3FxCVC0k8Vz/XIGW7UWoNo1MrW
# vcvkIaneI1Cdi9MiMIGLMHekdTBzMQswCQYDVQQGEwJVUzEOMAwGA1UECAwFVGV4
# YXMxEDAOBgNVBAcMB0hvdXN0b24xETAPBgNVBAoMCFNTTCBDb3JwMS8wLQYDVQQD
# DCZTU0wuY29tIFRpbWVzdGFtcGluZyBJc3N1aW5nIFJTQSBDQSBSMQIQGtYIp9Y0
# tc3el8ujzPDQSzAKBggqhkjOPQQDAgRHMEUCIDUdhYmfscOGYBhIXEOnWKvN0xyS
# RKa6gRVFNmJb/rIeAiEA6IBVbB5K17IQPWLit/6ksdn8tMnQfEAdfDesToWAZYk=
# SIG # End signature block
