CREATE TABLE [dbo].[tfvars]
(
  [Id] INT NOT NULL PRIMARY KEY IDENTITY(1,1),
  resource_group_name varchar(255),
  sql_instance_name varchar(150),
  location varchar(100), 
  tags varchar(max),
  administrator_login varchar(255),
  environment varchar(50),
  minimum_tls_version varchar(50),
  public_network_access bit,
  active_directory_admin_user varchar(255),
  active_directory_admin_sid varchar(255),
  tenantid varchar(255),
  sql_database_names varchar(max)
)
