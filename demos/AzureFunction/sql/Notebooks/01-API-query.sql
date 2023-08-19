drop table if exists #temp 

declare @url varchar(500) = 'https://pom-api.azure-api.net/conference/speakers'

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
	ReturnCode, Response
from #temp