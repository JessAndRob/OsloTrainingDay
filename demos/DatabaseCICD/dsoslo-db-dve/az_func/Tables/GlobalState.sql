CREATE TABLE [az_func].[GlobalState] (
    [UserFunctionID]  CHAR (16) NOT NULL,
    [UserTableID]     INT       NOT NULL,
    [LastSyncVersion] BIGINT    NOT NULL,
    [LastAccessTime]  DATETIME  DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([UserFunctionID] ASC, [UserTableID] ASC)
);


GO

