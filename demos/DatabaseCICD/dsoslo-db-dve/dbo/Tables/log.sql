CREATE TABLE [dbo].[log] (
    [logId]      INT           IDENTITY (1, 1) NOT NULL,
    [logDate]    DATETIME      DEFAULT (getdate()) NOT NULL,
    [logMessage] VARCHAR (MAX) NOT NULL,
    PRIMARY KEY CLUSTERED ([logId] ASC)
);


GO

