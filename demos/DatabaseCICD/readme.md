# Database CI\CD 

## Create a Database Project
Using the Azure Data Studio 'SQL Database Projects' extension we can create a project from an existing database.

### Prereqs
- Create a SQL Server - jesssqlserver.database.windows.net
- Create a SQL Database with sample data - AdventureWorksLT

### Process
1. Open Azure Data Studio
2. Make sure the 'Sql Database Projects' extension is installed
    - Extension: https://marketplace.visualstudio.com/items?itemName=ms-mssql.sql-database-projects-vscode
    - Docs: https://learn.microsoft.com/en-us/sql/azure-data-studio/extensions/sql-database-project-extension-getting-started?view=sql-server-ver16
3. Create a project from an existing `A`

## Schema Compare
1. 

## Create a dacpac

To deploy our project we need to create a dacpac - this can be created from our Database project in ADS.

1. Build - Database Projects view, right-click the database project's root node and select Build
2. Publish - To publish a database project, in the Database Projects view right-click the database project's root node and select Publish.


## GitHub Action to Deploy

https://github.com/azure/sql-action