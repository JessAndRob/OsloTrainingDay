CREATE USER [sqladmin] FROM LOGIN [sqladmin];
GO

GRANT CONNECT TO [sqladmin];
GO

ALTER ROLE [db_owner] ADD MEMBER [sqladmin];
GO
