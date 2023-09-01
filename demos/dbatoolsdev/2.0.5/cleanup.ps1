[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    $module = "dbatools"
)
# Which process should we be looking for?
if ($psedition -eq 'Core') {
    $process = "pwsh"
} else {
    $process = "powershell"
}
if (($PSVersionTable.PSVersion.Major -le 5) -or ($PSVersionTable.PSVersion.Major -gt 6 -and $PSVersionTable.OS -contains "Windows")) {
    $isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    $ise = Get-Process powershell_ise -ErrorAction SilentlyContinue
    if ($ise) {
        return "PowerShell ISE found in use. Please close this program before using this script."
    }
} else {
    $isElevated = $null;
    $ise = $null;
}
$installedVersion = Get-InstalledModule $module -AllVersions | Select-Object Version, InstalledLocation
Write-Output "The currently installed version(s) of $module is/are: "
$installedVersion.Version

$results =
foreach ($v in $installedVersion) {
    if ($v.InstalledLocation -match "C:\\Users") {
        Add-Member -Force -InputObject $v -MemberType NoteProperty -Name IsUserScope -value $true
    } else {
        if (-not $isElevated) {
            Write-Output "$module version $v.Version cannot be removed without elevated session."
        }
        Add-Member -Force -InputObject $v -MemberType NoteProperty -Name IsUserScope -value $false
    }
    $v
}

$newestVersion = Find-Module $module | Select-Object Version
Write-Output "`nThe latest version of $module in the PSGallery is: $($newestVersion.Version)"
$olderVersions = @( )
if ($installedVersion.Count -gt 1) {
    $olderVersions = @($installedVersion | Where-Object { [version]$_.Version -lt [version]$newestVersion.Version })
}

if ( ($olderVersions.Count -gt 0) -and $newestVersion.Version -in $installedVersion.Version ) {
    Write-Output "Latest version of $module found on $env:COMPUTERNAME."
    Write-Output "Older versions of $module also found. These will be uninstalled now."
    if ($isElevated) {
        $processes = Get-Process $process -IncludeUserName -ErrorAction SilentlyContinue | Where-Object Id -NE $pid
    } else {
        $processes = Get-Process $process -ErrorAction SilentlyContinue | Where-Object Id -NE $PID
    }
    if ($processes.Count -gt 0) {
        if ($Pscmdlet.ShouldProcess("$env:COMPUTERNAME", "Killing $($processes.Count) processes of powershell running")) {
            Write-Output "Death to the following process(es): $(($processes.Id) -join ",")"
            $processes | Stop-Process -ErrorVariable dangit -ErrorAction SilentlyContinue -Force
            if ($dangit) {
                Write-Warning "Not able to kill following processes: $((Get-Process $process | Where-Object Id -NE $pid).Id -join ",")"
            }
        }
    }
    if ($Pscmdlet.ShouldProcess("$env:COMPUTERNAME", "Removing old versions of $module.")) {
        foreach ($v in $olderVersions.Version) {
            Uninstall-Module $module -RequiredVersion $v -ErrorVariable dangit -ErrorAction SilentlyContinue -Force
            if ($dangit) {
                if ($dangit.Exception -like "*Administrator rights*") {
                    Write-Warning "Elevated session is required to uninstall $module version: $v"
                } else {
                    Write-Warning "Unable to remove $module version [$v] due to: `n`t$($dangit.Exception)"
                }
            }
        }
    }
    Write-Output "The End"
} elseif ( ($olderVersions.Count -gt 0) -and $newestVersion.Version -notin $installedVersion.Version ) {
    Write-Output "Update of $module is available"
    Write-Output "Older versions of $module found. These will be uninstalled now."
    if ($isElevated) {
        $processes = Get-Process $process -ErrorAction SilentlyContinue -IncludeUserName | Where-Object Id -NE $pid
    } else {
        $processes = Get-Process $process -ErrorAction SilentlyContinue | Where-Object Id -NE $PID
    }
    if ($processes.Count -gt 0) {
        if ($Pscmdlet.ShouldProcess("$env:COMPUTERNAME", "Killing $($processes.Count) processes of powershell running")) {
            Write-Output "Death to the following process(es): $(($processes.Id) -join ",")"
            $processes | Stop-Process -ErrorVariable dangit -ErrorAction SilentlyContinue -Force
            if ($dangit) {
                Write-Warning "Not able to kill following processes: $((Get-Process $process | Where-Object Id -NE $pid).Id -join ",")"
            }
        }
    }
    if ($Pscmdlet.ShouldProcess("$env:COMPUTERNAME", "Removing old versions of $module.")) {
        foreach ($v in $olderVersions.Version) {
            Uninstall-Module $module -RequiredVersion $v -ErrorVariable dangit -ErrorAction SilentlyContinue -Force
            if ($dangit) {
                if ($dangit.Exception -like "*Administrator rights*") {
                    Write-Warning "Elevated session is required to uninstall $module version: $v"
                } else {
                    Write-Warning "Unable to remove $module version [$v] due to: `n`t$($dangit.Exception)"
                }
            }
        }
    }
    Write-Output "Continuing to install latest release of $module"
    Install-Module $module -Force
    Write-Output "The End"
} else {
    Write-Output "No update/actions required."
}

# SIG # Begin signature block
# MIIlGwYJKoZIhvcNAQcCoIIlDDCCJQgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBbC7m38uJKN0Fh
# yce8/lpvD8KrpB4HRQCSsGB5ShHRlaCCDMgwggZOMIIENqADAgECAhBLMDfpm+8T
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
# 9w0BCQQxIgQgxFo7tvuZh43sYEnNnWnmu3BLi1Yr5ON4X7iYPy96i0kwDQYJKoZI
# hvcNAQEBBQAEggGAj2VxcCRvAZVC8w6KFdvzHYPMW85uYmxO4WcZft3TkMhecmFF
# d/lPjq4ah7wHxCmF+EuMdfuVGu+YZYYnFUC8bjGmd8kXTiSlq4JXtBxnL0TGfJmo
# lAeqkQ4UOa/ZnKZ1WUzjH63A4zs2b7Qa5mxR+oETmsPnd+KbWQudgx+hZza2WQOu
# 2tfOXxMaFs4dOhLP9pbHiqcLI+6EohsLPFOsu29r5H1UgJz6gLHcZ52SUUJZyMFL
# mfTtNHXmiHcCkoLUyp2ZzJjTB2WhT18PJr7nPV3XoiVwmVyqgSZMEOAdzLUUAFcw
# UrhojTzVpEMwTai+M4nW4KyuH0UuQ63e2C3tepWTLBvw5YGaU+zvCNKmWfx12Yuf
# 4IhQj1i42+P8Ej9zm6otyoTBW/EorK5pEkN7J3zi5tby4rFjIOVtQiTeUGbr4tBL
# eKbwFzh9FHyWq6o/4JD/PBE+agLltvhPFOMp073OdXeoiE9K33jNVy8dLeiKL+VZ
# M9orywHdBLX38hffoYIU7zCCFOsGCisGAQQBgjcDAwExghTbMIIU1wYJKoZIhvcN
# AQcCoIIUyDCCFMQCAQMxDTALBglghkgBZQMEAgEwdwYLKoZIhvcNAQkQAQSgaARm
# MGQCAQEGDCsGAQQBgqkwAQMGATAxMA0GCWCGSAFlAwQCAQUABCBpoX8pWb0WDHZg
# oyZ89nq6nsyvOb06sARpS+v8Yr0kMAIIaitzEbQSkZ0YDzIwMjMwNzI1MTE0NTA5
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
# MDlaMCgGCSqGSIb3DQEJNDEbMBkwCwYJYIZIAWUDBAIBoQoGCCqGSM49BAMCMC8G
# CSqGSIb3DQEJBDEiBCAYQTU8Z9aZqLG7h+y05cofYAXlR/ldiRtTqHkSLufsJzCB
# yQYLKoZIhvcNAQkQAi8xgbkwgbYwgbMwgbAEII3FxCVC0k8Vz/XIGW7UWoNo1MrW
# vcvkIaneI1Cdi9MiMIGLMHekdTBzMQswCQYDVQQGEwJVUzEOMAwGA1UECAwFVGV4
# YXMxEDAOBgNVBAcMB0hvdXN0b24xETAPBgNVBAoMCFNTTCBDb3JwMS8wLQYDVQQD
# DCZTU0wuY29tIFRpbWVzdGFtcGluZyBJc3N1aW5nIFJTQSBDQSBSMQIQGtYIp9Y0
# tc3el8ujzPDQSzAKBggqhkjOPQQDAgRHMEUCICGvzwbINJf9xVU6k5rED77TEZ3k
# ALazjY+uG9HGd/RwAiEAyp22TG+yTGfJ0S2/FbOKZQGFKhL5UybGKx9+3U+37QY=
# SIG # End signature block
