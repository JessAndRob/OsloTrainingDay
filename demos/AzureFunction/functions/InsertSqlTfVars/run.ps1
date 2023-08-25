using namespace System.Net

param($Request)

Write-Host "PowerShell function with SQL Output Binding processed a request."

# Update req_body with the body of the request
$req_body = $Request.Body

write-host $req_body.tostring()

# Assign the value we want to pass to the SQL Output binding. 
# The -Name value corresponds to the name property in the function.json for the binding
Push-OutputBinding -Name tfvars -Value $req_body

Push-OutputBinding -Name res -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $req_body
})