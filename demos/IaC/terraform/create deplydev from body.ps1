# create the json
$body = @{
    resource_group_name         = 'resource_group_name'
    sql_instance_name           = 'sql_instance_name'
    location                    = 'location'
    tags                        = 'tags'
    administrator_login         = 'administrator_login'
    environment                 = 'environment'
    minimum_tls_version         = 'minimum_tls_version'
    public_network_access       = 1
    active_directory_admin_user = 'active_directory_admin_user'
    active_directory_admin_sid  = 'active_directory_admin_sid'
    tenantid                    = 'tenantid'
    sql_database_names          = '"database1", "database2","database3"'
}

$varfile = ".\demos\IaC\terraform\deploydev_template.tfvars"

$Content = Get-Content $varfile

# Iterate through the hashtable and replace placeholders
$body.GetEnumerator() | ForEach-Object {
    $placeholder = "__" + $_.Key + "__"
    $content = $content -replace [regex]::Escape($placeholder), $_.Value
}

$newfile = ".\demos\IaC\terraform\deploy_new_dev.tfvars"
Set-Content $newfile $content

# Display the modified content
$content