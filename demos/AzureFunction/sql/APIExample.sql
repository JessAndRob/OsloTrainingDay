-- create the proc
--CREATE OR ALTER PROCEDURE GetSpeakers
  --@Name varchar(24) --= 'jesstestads178712345'
--as

-- if API requires a subscription you need to create it as a DATABASE SCOPED CREDENTIAL

  -- create a database master key if there isn't one
  IF NOT EXISTS(SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
  BEGIN
      create master key encryption by password = '*********'
  END

  -- create a database scoped credential for managed identity (or Request Headers or Query String)
  CREATE DATABASE SCOPED CREDENTIAL [https://pom-api.azure-api.net/conference/speakers]
  WITH IDENTITY = 'HTTPEndpointHeaders', SECRET = '{"Ocp-Apim-Subscription-Key":"e0de06144f7c4765882d971c310489bb"}';




drop table if exists #temp 

declare @url varchar(500)

set @url = 'https://pom-api.azure-api.net/conference/speakers'

declare @ret as int, @response as nvarchar(max);

exec @ret = sp_invoke_external_rest_endpoint 
	@method = 'GET',
	@url = @url,
  @credential = [https://pom-api.azure-api.net/conference/speakers],
 	@response = @response output;
	
select @ret as ReturnCode, @response as Response
into #temp


declare @data as nvarchar(max);

select 
	@data = JSON_QUERY(response, '$.result.collection.items')
from #temp;

select 
	response
from #temp


SELECT [value] as FullName, url
FROM OPENJSON(@data) WITH (
	data2 NVARCHAR(MAX) '$.data' AS JSON,
    url NVARCHAR(50) '$.href'
    )CROSS APPLY OPENJSON(data2)
WITH ([value] NVARCHAR(50))



