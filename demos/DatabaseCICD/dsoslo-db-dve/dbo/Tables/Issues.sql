CREATE TABLE [dbo].[Issues] (
    [Id]          INT           IDENTITY (1, 1) NOT NULL,
    [IssueTitle]  VARCHAR (100) NULL,
    [IssueNumber] VARCHAR (10)  NULL,
    [IssueLink]   VARCHAR (250) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO

