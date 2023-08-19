-- create a database master key
IF NOT EXISTS(SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    create master key encryption by password = '*********'
END

-- create a database scoped credential for managed identity (or Request Headers or Query String)
CREATE DATABASE SCOPED CREDENTIAL [https://psconfeu2023.azurewebsites.net/api/NewStorageAcct]
WITH IDENTITY = 'Managed Identity', SECRET = '{"resourceid":"66878375-e836-4e2b-8420-1c435e9b5cf9"}';

drop database scoped credential [https://psconfeu2023.azurewebsites.net/api/NewStorageAcct]

-- lets try with auth token
create database scoped credential [https://psconfeu2023.azurewebsites.net/api/NewStorageAcct]
with identity = 'HTTPEndpointHeaders', secret = '{"Zy-rfQ-By4ZAO7CYMbvnm2Cgy9WeiWXLQuV3GU9AAyK6AzFuxlnsHg==":""}';



go 

-- create the proc
CREATE OR ALTER PROCEDURE NewStorageAccount
  -- Storage account names must be between 3 and 24 characters in length and may contain numbers and lowercase letters only
  @Name varchar(24) --= 'jesstestads178712345'
as
declare @url varchar(500)

set @url = 'https://psconfeu2023.azurewebsites.net/api/NewStorageAcct?name=' + LOWER(@Name)

declare @ret as int, @response as nvarchar(max);

exec @ret = sp_invoke_external_rest_endpoint 
	@method = 'GET',
	@url = @url,
    @timeout = 230, -- max value which is 3.8 mins
    @credential = [https://psconfeu2023.azurewebsites.net/api/NewStorageAcct],
 	@response = @response output;
	
select @ret as ReturnCode, @response as Response;

exec @ret = sp_invoke_external_rest_endpoint 
	@method = 'GET',
	@url = @url,
 	@response = @response output;


GO

-- call the proc
exec NewStorageAccount @Name = 'test77778jess'