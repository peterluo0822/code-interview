USE [GWDataDB]
GO


IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[V_%Outbound_IFName%]'))
DROP VIEW [dbo].[V_%Outbound_IFName%]
GO

IF OBJECT_ID ( '%Inbound_IFName%_%Outbound_IFName%_IsRedundant', 'P' ) IS NOT NULL 
    DROP PROCEDURE %Inbound_IFName%_%Outbound_IFName%_IsRedundant;
GO

IF OBJECT_ID ( '%Inbound_IFName%_%Outbound_IFName%_IsConflict', 'P' ) IS NOT NULL 
    DROP PROCEDURE %Inbound_IFName%_%Outbound_IFName%_IsConflict;
GO

IF OBJECT_ID ( '%Inbound_IFName%_%Outbound_IFName%_DeleteRecord', 'P' ) IS NOT NULL 
    DROP PROCEDURE %Inbound_IFName%_%Outbound_IFName%_DeleteRecord;
GO

IF OBJECT_ID ( '%Inbound_IFName%_%Outbound_IFName%_InsertRecord', 'P' ) IS NOT NULL 
    DROP PROCEDURE %Inbound_IFName%_%Outbound_IFName%_InsertRecord;
GO


IF OBJECT_ID ( '%Inbound_IFName%_%Outbound_IFName%_PKIsExisted', 'P' ) IS NOT NULL 
    DROP PROCEDURE %Inbound_IFName%_%Outbound_IFName%_PKIsExisted;
GO


IF OBJECT_ID ( '%Inbound_IFName%_%Outbound_IFName%_CleanOutTables', 'P' ) IS NOT NULL 
    DROP PROCEDURE %Inbound_IFName%_%Outbound_IFName%_CleanOutTables;
GO

/****** Object:  Table [dbo].[%Trigger%]    Script Date: 11/02/2006 10:01:13 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[%Inbound_IFName%_%Outbound_IFName%_Trigger]') )
DROP Trigger [dbo].[%Inbound_IFName%_%Outbound_IFName%_Trigger]

GO


