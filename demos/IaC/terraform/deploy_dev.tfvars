resource_group_name = "dbatools-azure-lab"

sql_instance_name="dsoslo-server"

location = "westeurope"

tags={
    {"for" : "dsoslo2023"}
}

administrator_login="sqladmin"

environment="dev"

minimum_tls_version= "Disabled"

public_network_access= 0

active_directory_admin_user= "jess@jpomfret7gmail.onmicrosoft.com"

active_directory_admin_sid= "0c97d81f-a7c6-40d4-9077-ade0dfbfe968"

tenantid="f98042ad-9bbc-499d-adb4-17193696b9a3"

sql_database_names= [["dsoslo-db", "dsoslo-db-cdc","new-db","another-new-db"]] # "database1", "database2"

