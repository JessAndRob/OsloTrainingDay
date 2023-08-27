CREATE TABLE [dbo].[ToDo] (
    [Id]        INT            IDENTITY (1, 1) NOT NULL,
    [order]     INT            NULL,
    [title]     NVARCHAR (200) NOT NULL,
    [url]       NVARCHAR (200) NOT NULL,
    [completed] BIT            NOT NULL,
    [ANewCol]   INT            NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO

