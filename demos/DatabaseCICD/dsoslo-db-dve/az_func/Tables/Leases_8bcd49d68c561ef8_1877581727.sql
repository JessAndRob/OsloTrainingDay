CREATE TABLE [az_func].[Leases_8bcd49d68c561ef8_1877581727] (
    [storageAcctId]                INT           NOT NULL,
    [_az_func_ChangeVersion]       BIGINT        NOT NULL,
    [_az_func_AttemptCount]        INT           NOT NULL,
    [_az_func_LeaseExpirationTime] DATETIME2 (7) NULL,
    PRIMARY KEY CLUSTERED ([storageAcctId] ASC)
);


GO

