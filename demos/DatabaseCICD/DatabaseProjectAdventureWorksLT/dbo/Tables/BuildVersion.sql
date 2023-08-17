CREATE TABLE [dbo].[BuildVersion] (
    [SystemInformationID] TINYINT       IDENTITY (1, 1) NOT NULL,
    [Database Version]    NVARCHAR (25) NOT NULL,
    [VersionDate]         DATETIME      NOT NULL,
    [ModifiedDate2]        DATETIME      CONSTRAINT [DF_BuildVersion_ModifiedDate] DEFAULT (getdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([SystemInformationID] ASC)
);


GO

