CREATE TABLE [dbo].[storageAcct] (
    [storageAcctId]   INT          IDENTITY (1, 1) NOT NULL,
    [storageAcctName] VARCHAR (50) NOT NULL,
    PRIMARY KEY CLUSTERED ([storageAcctId] ASC)
);


GO
ALTER TABLE [dbo].[storageAcct] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO

