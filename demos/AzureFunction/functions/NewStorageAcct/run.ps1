using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

try {

    $name = $Request.Query.Name
    $sku = 'Standard_LRS'
    $location = 'uksouth'

    $splatStorage = @{
        Name              = $name
        ResourceGroupName = 'psconfeu-rg'
        Location          = $location
        SkuName           = $sku
        Tag               = @{ 'CreatedBy' = 'AzFunc' }
    }
    $results = New-AzStorageAccount @splatStorage -ErrorAction Stop

    $body = [PSCustomObject]@{
        StorageAccountName = $Name
        ProvisioningState  = $results.ProvisioningState
        CreationTime       = $results.CreationTime
        Tags               = $results.Tags
    }
    $status = [HttpStatusCode]::OK

} catch {
    $body = [PSCustomObject]@{
        Error = $_.Exception.Message
        #Success = $false
        ProvisioningState =  $results.ProvisioningState
    }
    $status = [HttpStatusCode]::BadRequest
} finally {

    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $status
        Body = (ConvertTo-Json $body)
    })

}