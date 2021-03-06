SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Combination]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Combination](
	[DataIn] [nvarchar](64) NOT NULL,
	[DataOut] [nvarchar](64) NOT NULL,
	[Data_Mapping_File] [nvarchar](256) NULL,
 CONSTRAINT [PK_Combination] PRIMARY KEY CLUSTERED 
(
	[DataIn] ASC,
	[DataOut] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DEVICE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DEVICE](
	[DEVICE_ID] [int] IDENTITY(1,1) NOT NULL,
	[DEVICE_NAME] [nvarchar](64) NOT NULL,
	[DEVICE_DIRECT] [nvarchar](1) NOT NULL,
	[DEVICE_TYPE] [nvarchar](2) NOT NULL,
	[DEVICE_DESC] [nvarchar](max) NULL,
	[FILE_FOLDER] [nvarchar](256) NOT NULL,
	[INDEX_FILE] [nvarchar](256) NOT NULL,
 CONSTRAINT [PK_DEVICE] PRIMARY KEY CLUSTERED 
(
	[DEVICE_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[INTERFACE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[INTERFACE](
	[INTERFACE_ID] [int] IDENTITY(1,1) NOT NULL,
	[INTERFACE_NAME] [nvarchar](64) NULL,
	[INTERFACE_DESC] [nvarchar](max) NULL,
	[DEVICE_ID] [int] NULL,
	[DEVICE_NAME] [nvarchar](64) NULL,
	[DEVICE_DIRECT] [nvarchar](1) NULL,
	[DEVICE_TYPE] [nvarchar](2) NULL,
	[FILE_FOLDER] [nvarchar](255) NULL,
	[INDEX_FILE] [nvarchar](255) NULL,
	[LAST_BACKUP_DIR] [nvarchar](255) NULL,
	[LAST_BACKUP_DATETIME] [nvarchar](64) NULL,
	[EVENT_TYPE] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[INTERFACE_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END


INSERT INTO [GWConfigDB].[dbo].[DEVICE]
           ([DEVICE_NAME]
           ,[DEVICE_DIRECT]
           ,[DEVICE_TYPE]
           ,[DEVICE_DESC]
           ,[FILE_FOLDER]
           ,[INDEX_FILE])
     VALUES
           ('SQL_IN','I','1','SQL Inbound Adapter','Device\Device_1','DeviceDir')

INSERT INTO [GWConfigDB].[dbo].[DEVICE]
           ([DEVICE_NAME]
           ,[DEVICE_DIRECT]
           ,[DEVICE_TYPE]
           ,[DEVICE_DESC]
           ,[FILE_FOLDER]
           ,[INDEX_FILE])
     VALUES
           ('SQL_OUT','O','1','SQL Outbound Adapter','Device\Device_2','DeviceDir')

INSERT INTO [GWConfigDB].[dbo].[DEVICE]
           ([DEVICE_NAME]
           ,[DEVICE_DIRECT]
           ,[DEVICE_TYPE]
           ,[DEVICE_DESC]
           ,[FILE_FOLDER]
           ,[INDEX_FILE])
     VALUES
           ('GC_SOCKET_IN','I','2','Socket Inbound Adapter','Device\Device_3','DeviceDir')

INSERT INTO [GWConfigDB].[dbo].[DEVICE]
           ([DEVICE_NAME]
           ,[DEVICE_DIRECT]
           ,[DEVICE_TYPE]
           ,[DEVICE_DESC]
           ,[FILE_FOLDER]
           ,[INDEX_FILE])
     VALUES
           ('GC_SOCKET_OUT','O','2','Socket Outbound Adapter','Device\Device_4','DeviceDir')

INSERT INTO [GWConfigDB].[dbo].[DEVICE]
           ([DEVICE_NAME]
           ,[DEVICE_DIRECT]
           ,[DEVICE_TYPE]
           ,[DEVICE_DESC]
           ,[FILE_FOLDER]
           ,[INDEX_FILE])
     VALUES
           ('FILE_IN','I','3','File Inbound Adapter','Device\Device_5','DeviceDir')

INSERT INTO [GWConfigDB].[dbo].[DEVICE]
           ([DEVICE_NAME]
           ,[DEVICE_DIRECT]
           ,[DEVICE_TYPE]
           ,[DEVICE_DESC]
           ,[FILE_FOLDER]
           ,[INDEX_FILE])
     VALUES
           ('FILE_OUT','O','3','File Outbound Adapter','Device\Device_6','DeviceDir')



INSERT INTO [GWConfigDB].[dbo].[DEVICE]
           ([DEVICE_NAME]
           ,[DEVICE_DIRECT]
           ,[DEVICE_TYPE]
           ,[DEVICE_DESC]
           ,[FILE_FOLDER]
           ,[INDEX_FILE])
     VALUES
           ('DICOM_MWL_OUT','O','5','DICOM MWL Outbound Adapter','Device\Device_8','DeviceDir')

INSERT INTO [GWConfigDB].[dbo].[DEVICE]
           ([DEVICE_NAME]
           ,[DEVICE_DIRECT]
           ,[DEVICE_TYPE]
           ,[DEVICE_DESC]
           ,[FILE_FOLDER]
           ,[INDEX_FILE])
     VALUES
           ('DICOM_SSCP_IN','I','5','DICOM Storage Inbound Adapter','Device\Device_9','DeviceDir')

INSERT INTO [GWConfigDB].[dbo].[DEVICE]
           ([DEVICE_NAME]
           ,[DEVICE_DIRECT]
           ,[DEVICE_TYPE]
           ,[DEVICE_DESC]
           ,[FILE_FOLDER]
           ,[INDEX_FILE])
     VALUES
           ('RDET_MWL_OUT','O','6','RDET Outbound Adapter','Device\Device_10','DeviceDir')

