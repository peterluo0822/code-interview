USE [CareRis]
GO
/****** Object:  FullTextCatalog [OrderFullText]    Script Date: 2017/8/24 11:29:43 ******/
CREATE FULLTEXT CATALOG [OrderFullText]WITH ACCENT_SENSITIVITY = ON

GO
/****** Object:  FullTextCatalog [ReportFullText]    Script Date: 2017/8/24 11:29:43 ******/
CREATE FULLTEXT CATALOG [ReportFullText]WITH ACCENT_SENSITIVITY = ON

GO
/****** Object:  StoredProcedure [dbo].[procAddAnatomy]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[procAddAnatomy]
	@aid varchar(1),
	@desc varchar(255),
	@domain varchar(255)
AS
BEGIN

declare @i int
declare @iMax int

set @i=0
set @iMax=1000

begin transaction

while(@i < @iMax)
begin
if not exists(select 1 from tbAcrCodeSubAnatomical where aid=@aid and sid=cast(@i as varchar(5)))
	break

set @i=@i+1

if @i%10 = 0
	set @i=@i+1
end

-- select @i
if(@i<@iMax)
    insert into tbAcrCodeSubAnatomical(aid, sid, description,Domain) values(@aid, cast(@i as varchar(5)), @desc,@domain)

select @i as NewID from tbAcrCodeSubAnatomical where aid=@aid and sid=cast(@i as varchar(5))

commit

END



GO
/****** Object:  StoredProcedure [dbo].[procAddPathology]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[procAddPathology]
	@aid varchar(1),
	@pid varchar(1),
	@desc varchar(255),
	@domain varchar(255)
AS
BEGIN

declare @i int 
declare @iMax int

set @i=0
set @iMax=100000

begin transaction

while(@i < @iMax)
begin
	if not exists(select 1 from tbAcrCodeSubPathological where aid=@aid and pid=@pid and sid=cast(@i as varchar(5)))
		break
	set @i=@i+1
 	if @i%10 = 0
 		set @i=@i+1
end

if(@i<@iMax)
begin
	insert into tbAcrCodeSubPathological(aid, pid, sid, description,Domain) values(@aid, @pid, cast(@i as varchar(5)), @desc,@domain)
end

select @i as NewID from tbAcrCodeSubPathological where aid=@aid and pid=@pid and sid=cast(@i as varchar(5))

commit

END



GO
/****** Object:  StoredProcedure [dbo].[procAddRoleProfile]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procAddRoleProfile]
      @Name NVARCHAR(MAX), 
      @ModuleID NVARCHAR(MAX), 
      @Value NVARCHAR(MAX), 
      @Exportable int, 
      @PropertyDesc NVARCHAR(MAX), 
      @PropertyOptions NVARCHAR(MAX), 
      @Inheritance int, 
      @PropertyType int, 
      @IsHidden int, 
      @OrderingPos NVARCHAR(MAX)
AS

DECLARE cur CURSOR FOR 
 select RoleName from tbRole where rolename not in (select distinct rolename from tbRoleProfile where rolename<>'' AND name=@Name)

declare @rolename NVARCHAR(MAX)
declare @sql NVARCHAR(MAX)

set @sql = ''

open cur

FETCH NEXT FROM cur 
INTO @rolename

WHILE @@FETCH_STATUS = 0
BEGIN
	set @sql = @sql + ' INSERT INTO tbRoleProfile ( RoleName, Name, ModuleID, Value, Exportable, PropertyDesc, PropertyOptions, Inheritance, PropertyType, IsHidden, OrderingPos, [Domain] ) '
		+ ' VALUES('''+@rolename +''','''+ @Name+''','''+ @ModuleID+''','''+ @Value+''','''+ LTRIM(STR(@Exportable))+''','''+ @PropertyDesc+''','''
		+ @PropertyOptions+''','''+ LTRIM(STR(@Inheritance))+''','''+ LTRIM(STR(@PropertyType))+''','''+ LTRIM(STR(@IsHidden))+''','''+ @OrderingPos+''', (select value from tbSystemProfile where Name=''Domain'') ) ' + CHAR(13) + CHAR(10)
		
        -- Get the next vendor.
    FETCH NEXT FROM cur 
    INTO @rolename
END 
CLOSE cur
DEALLOCATE cur

if LEN(@sql) > 0
begin
	print @sql

	exec(@sql)
end
else
	print 'NO roles need add a profile FOR ' + @Name



GO
/****** Object:  StoredProcedure [dbo].[procAltertype]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[procAltertype] 
		@typename sysname,		-- name of user-defined type
		@phystype sysname,		-- physical system type of user-defined type
		@nulltype varchar(8) = null	-- nullability of new type
as
/**********
[版本号]4.0.0.0.0
[创建时间]2017.03.07  
[版权] Copyright ? 1998-2001好医生云医院管理技术有限公司
[描述]Modify user defined data type
[功能说明]
	如果该类型被主键或唯一键使用则无法修改
[参数说明]
	@typename sysname,		-- name of user-defined type
	@phystype sysname,		-- physical system type of user-defined type
	@nulltype varchar(8) = null	-- nullability of new type
[返回值]
[结果集、排序]
[调用的sp]
	sp_addtype
	sp_droptype
[调用实例]
**********/
set nocount on

declare @xusertype int
select @xusertype=xusertype from systypes where name=@typename
if @@rowcount=0
begin
	print '该用户定义类型不存在，不能修改！'
	return
end

if @xusertype<=256
begin
	print '该类型不是用户自定义，不能修改！'
	return
end

declare cs_columns insensitive cursor
for select object_name(id),name,isnullable from syscolumns where xusertype=@xusertype and name not like '@%'
for read only

declare @tabname varchar(255),	--table name
	@colname varchar(255),	--column name
	@isnullable bit,
	@colnulltype varchar(8)	--column null type

begin tran

exec sp_addtype 'ut_temp9999', @phystype, @nulltype
if @@error<>0
begin
	print '无法添加类型ut_temp9999,修改失败！'
	rollback tran
	deallocate cs_columns
	return
end

open cs_columns
fetch cs_columns into @tabname, @colname, @isnullable
while @@fetch_status=0
begin
	if @isnullable=0
		select @colnulltype='not null'
	else
		select @colnulltype='null'
	exec('alter table '+@tabname+' alter column '+@colname+' ut_temp9999 '+@colnulltype)
	if @@error<>0
	begin
		print '修改'+@tabname+'表'+@colname+'字段类型出错!'
		rollback tran
		deallocate cs_columns
		return
	end
	fetch cs_columns into @tabname, @colname, @isnullable
end
close cs_columns
deallocate cs_columns

exec sp_droptype @typename
if @@error<>0
begin
	print '无法删除旧类型,修改失败！'
	rollback tran
	return
end

exec sp_addtype @typename, @phystype, @nulltype
if @@error<>0
begin
	print '无法添加新类型,修改失败！'
	rollback tran
	return
end

select @xusertype=xusertype from systypes where name='ut_temp9999'

declare cs_columns1 insensitive cursor
for select object_name(id),name,isnullable from syscolumns where xusertype=@xusertype
for read only

open cs_columns1
fetch cs_columns1 into @tabname, @colname, @isnullable
while @@fetch_status=0
begin
	if @isnullable=0
		select @colnulltype='not null'
	else
		select @colnulltype='null'
	exec('alter table '+@tabname+' alter column '+@colname+' '+@typename+' '+@colnulltype)
	if @@error<>0
	begin
		print '修改'+@tabname+'表'+@colname+'字段类型出错!'
		rollback tran
		deallocate cs_columns1
		return
	end
	fetch cs_columns1 into @tabname, @colname, @isnullable
end
close cs_columns1
deallocate cs_columns1

exec sp_droptype 'ut_temp9999'
if @@error<>0
begin
	print '无法删除类型ut_temp9999,修改失败！'
	rollback tran
	return
end

commit tran
print '更新类型成功！'
return



GO
/****** Object:  StoredProcedure [dbo].[procBaseListCOUNT]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procBaseListCOUNT]
     @Conditions nvarchar(MAX),
     @TotalCount integer output
AS 
BEGIN
SET QUOTED_IDENTIFIER ON 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET @TotalCount=0
declare @upperCondition nvarchar(MAX)

set @upperCondition = ltrim(rtrim(upper(@Conditions)))
if len(@upperCondition) > 0 AND charindex('AND', @upperCondition) <> 1
     set @Conditions = ' and ' + @Conditions

declare @sql nvarchar(max)

if charindex('tbRegPatient.', @Conditions) < 1 and charindex('tbRegOrder.', @Conditions) < 1 and charindex('tbReport.', @Conditions) < 1 
begin
 select @sql = 'select @TotalCount=count(1) from tbRegProcedure with (nolock) where tbRegProcedure.Status>=0 '+@Conditions
 --print '3' + @sql
 EXEC sp_executesql @sql, N' @TotalCount int output ', @TotalCount output
end
else
begin
 select @sql = 'select @TotalCount=count(1) from tbRegPatient with (nolock), tbRegOrder with (nolock), tbRegProcedure with (nolock)
     left join tbReport with (nolock) on tbRegProcedure.reportGuid = tbReport.reportGuid 
     where tbRegPatient.PatientGuid = tbRegOrder.PatientGuid and tbRegOrder.OrderGuid = tbRegProcedure.OrderGuid AND tbRegProcedure.Status>=0 '
     + @Conditions
 --print '4' + @sql
 EXEC sp_executesql @sql, N' @TotalCount int output ', @TotalCount output
end

END


GO
/****** Object:  StoredProcedure [dbo].[procBaseListCountWithArchive]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procBaseListCountWithArchive]
     @Conditions varchar(MAX),
     @TotalCount integer output
AS 
BEGIN
SET QUOTED_IDENTIFIER ON 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET @TotalCount=0
declare @upperCondition nvarchar(MAX)

set @upperCondition = ltrim(rtrim(upper(@Conditions)))
if len(@upperCondition) > 0 AND charindex('AND', @upperCondition) <> 1
     set @Conditions = ' and ' + @Conditions

declare @sql nvarchar(max)

if charindex('tbRegPatient.', @Conditions) < 1 and charindex('tbRegOrder.', @Conditions) < 1 and charindex('tbReport.', @Conditions) < 1 
begin
 select @sql = ' select @TotalCount=sum(cnt) '
 select @sql = @sql + ' from ( '
 select @sql = @sql + ' select COUNT(1) cnt, 1 dummy from tbRegProcedure with (nolock) where tbRegProcedure.status >= 50 '+@Conditions
 select @sql = @sql + ' UNION '
 select @sql = @sql + ' select COUNT(1) cnt, 2 dummy from RISArchive..tbRegProcedure tbRegProcedure with (nolock) where tbRegProcedure.status >= 50 '+@Conditions
 select @sql = @sql + ' ) TEMP_TABLE_965 '
 -- exec procLongPrint '1' + @sql
 EXEC sp_executesql @sql, N' @TotalCount int output ', @TotalCount output
end
else
begin
 select @sql = ' select @TotalCount=sum(cnt) '
 select @sql = @sql + ' from ( '
 select @sql = @sql + ' select COUNT(1) cnt, 1 dummy from tbRegPatient with (nolock), tbRegOrder with (nolock), tbRegProcedure with (nolock)
     left join tbReport with (nolock) on tbRegProcedure.reportGuid = tbReport.reportGuid 
     where tbRegPatient.PatientGuid = tbRegOrder.PatientGuid and tbRegOrder.OrderGuid = tbRegProcedure.OrderGuid ' 
     + @Conditions
 select @sql = @sql + ' UNION '

 select @sql = @sql + ' select COUNT(1) cnt, 2 dummy from RISArchive..tbRegPatient tbRegPatient with (nolock), RISArchive..tbRegOrder tbRegOrder with (nolock), RISArchive..tbRegProcedure tbRegProcedure with (nolock)
     left join RISArchive..tbReport tbReport with (nolock) on tbRegProcedure.reportGuid = tbReport.reportGuid 
     where tbRegPatient.PatientGuid = tbRegOrder.PatientGuid and tbRegOrder.OrderGuid = tbRegProcedure.OrderGuid AND  tbRegProcedure.Status>=0 ' 
     + @Conditions
 select @sql = @sql + ' ) TEMP_TABLE_966 '
  
 -- exec procLongPrint '2' + @sql
 EXEC sp_executesql @sql, N' @TotalCount int output ', @TotalCount output
end

END



GO
/****** Object:  StoredProcedure [dbo].[procBaseListPage]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procBaseListPage]
 @PageIndex integer,
 @PageSize integer,
 @Columns nvarchar(MAX),
 @Conditions nvarchar(MAX),
 @OrderBy nvarchar(MAX)
AS 
BEGIN

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

if @PageSize < 1 set @PageSize = 30
if @PageIndex > 0xfffff set @PageIndex = 0xfffff
if @PageIndex < 1 set @PageIndex = 1

declare @minrowcount int
declare @maxrowcount int
set @minrowcount=(@PageIndex-1)*@PageSize+1
set @maxrowcount = @PageIndex * @PageSize

declare @rowNumOrderBy nvarchar(MAX)
set @rowNumOrderBy = @OrderBy
SET @rowNumOrderBy = REPLACE(@rowNumOrderBy, '__', '.')
if @rowNumOrderBy = '' set @rowNumOrderBy = 'Order by (select 1)'
--set @rowNumOrderBy = replace(@rowNumOrderBy, '.', '__')

declare @totalColumns nvarchar(MAX)

;WITH ColList AS (
    SELECT ColName = y.i.value('(./text())[1]', 'nvarchar(4000)')
        FROM (
            SELECT x = CONVERT(XML, '<i>' + REPLACE(REPLACE(REPLACE(@Columns, CHAR(13), ''), CHAR(10), ''), ',', '</i><i>') + '</i>').query('.')
        ) AS a CROSS APPLY x.nodes('i') AS y(i)
), Mapping (ColName, SqlText) AS (
    SELECT 'tbRegOrder__OrderMessage', 'tbRegOrder.OrderMessage AS tbRegOrder__OrderMessage' UNION ALL
    SELECT 'OrderMessageXml', 'convert(varchar(max),tbRegOrder.OrderMessage) AS OrderMessageXml' UNION ALL
    SELECT 'tbRegOrder__OrderMessage__DESC', '(case when tbRegOrder.OrderMessage IS NULL then '''' when cast(tbRegOrder.OrderMessage AS nvarchar(max))='''' then '''' when tbRegOrder.OrderMessage.exist(''/LeaveMessage[@Type]'')=1 then tbRegOrder.OrderMessage.value(''/LeaveMessage[1]/@Type[1]'',''nvarchar(64)'') when tbRegOrder.OrderMessage.exist(''/LeaveMessage[@HasCriticalSigns]'')=0 or tbRegOrder.OrderMessage.exist(''/LeaveMessage[@HasCriticalSigns="0"]'')=1 then ''a'' when tbRegOrder.OrderMessage.exist(''//Message[@IsCriticalSign="0"]'')=1 then ''ab'' else ''b'' end) AS tbRegOrder__OrderMessage__DESC' UNION ALL
    SELECT 'tbRegPatient__PatientID', 'tbRegPatient.PatientID AS tbRegPatient__PatientID' UNION ALL
    SELECT 'tbRegPatient__LocalName', 'tbRegPatient.LocalName AS tbRegPatient__LocalName' UNION ALL
    SELECT 'tbRegPatient__EnglishName', 'tbRegPatient.EnglishName AS tbRegPatient__EnglishName' UNION ALL
    SELECT 'tbRegPatient__ReferenceNo', 'tbRegPatient.ReferenceNo AS tbRegPatient__ReferenceNo' UNION ALL
    SELECT 'tbRegPatient__Birthday', 'tbRegPatient.Birthday AS tbRegPatient__Birthday' UNION ALL
    SELECT 'tbRegPatient__Gender', 'tbRegPatient.Gender AS tbRegPatient__Gender' UNION ALL
    SELECT 'tbRegPatient__Address', 'tbRegPatient.Address AS tbRegPatient__Address' UNION ALL
    SELECT 'tbRegPatient__Telephone', 'tbRegPatient.Telephone AS tbRegPatient__Telephone' UNION ALL
    SELECT 'tbRegPatient__IsVIP', 'tbRegPatient.IsVIP AS tbRegPatient__IsVIP' UNION ALL
    SELECT 'tbRegPatient__IsVIP__DESC', 'dbo.fnTranslateYesNo(tbRegPatient.IsVIP) AS tbRegPatient__IsVIP__DESC' UNION ALL
    SELECT 'tbRegPatient__CreateDt', 'tbRegPatient.CreateDt AS tbRegPatient__CreateDt' UNION ALL
    SELECT 'tbRegPatient__Comments', 'tbRegPatient.Comments AS tbRegPatient__Comments' UNION ALL
    SELECT 'tbRegPatient__RemotePID', 'tbRegPatient.RemotePID AS tbRegPatient__RemotePID' UNION ALL
    SELECT 'tbRegPatient__Optional1', 'tbRegPatient.Optional1 AS tbRegPatient__Optional1' UNION ALL
    SELECT 'tbRegPatient__Optional2', 'tbRegPatient.Optional2 AS tbRegPatient__Optional2' UNION ALL
    SELECT 'tbRegPatient__Optional3', 'tbRegPatient.Optional3 AS tbRegPatient__Optional3' UNION ALL
    SELECT 'tbRegPatient__Alias', 'tbRegPatient.Alias AS tbRegPatient__Alias' UNION ALL
    SELECT 'tbRegPatient__Marriage', 'tbRegPatient.Marriage AS tbRegPatient__Marriage' UNION ALL
    SELECT 'tbRegPatient__Domain', 'tbRegPatient.Domain AS tbRegPatient__Domain' UNION ALL
    SELECT 'tbRegPatient__GlobalID', 'tbRegPatient.GlobalID AS tbRegPatient__GlobalID' UNION ALL
    SELECT 'tbRegPatient__MedicareNo', 'tbRegPatient.MedicareNo AS tbRegPatient__MedicareNo' UNION ALL
    SELECT 'tbRegPatient__ParentName', 'tbRegPatient.ParentName AS tbRegPatient__ParentName' UNION ALL
    SELECT 'tbRegPatient__RelatedID', 'tbRegPatient.RelatedID AS tbRegPatient__RelatedID' UNION ALL
    SELECT 'tbRegPatient__Site', 'tbRegPatient.Site AS tbRegPatient__Site' UNION ALL
    SELECT 'tbRegPatient__Site__DESC', 'dbo.fnTranslateSite(tbRegPatient.Site) AS tbRegPatient__Site__DESC' UNION ALL
    SELECT 'tbRegPatient__PatientGuid', 'tbRegPatient.PatientGuid AS tbRegPatient__PatientGuid' UNION ALL
    SELECT 'tbRegPatient__SocialSecurityNo', 'tbRegPatient.SocialSecurityNo AS tbRegPatient__SocialSecurityNo' UNION ALL
    SELECT 'tbRegOrder__OrderGuid', 'tbRegOrder.OrderGuid AS tbRegOrder__OrderGuid' UNION ALL
    SELECT 'tbRegOrder__VisitGuid', 'tbRegOrder.VisitGuid AS tbRegOrder__VisitGuid' UNION ALL
    SELECT 'tbRegOrder__AccNo', 'tbRegOrder.AccNo AS tbRegOrder__AccNo' UNION ALL
    SELECT 'tbRegOrder__ApplyDept', 'tbRegOrder.ApplyDept AS tbRegOrder__ApplyDept' UNION ALL
    SELECT 'tbRegOrder__ApplyDoctor', 'tbRegOrder.ApplyDoctor AS tbRegOrder__ApplyDoctor' UNION ALL
    SELECT 'tbRegOrder__CreateDt', 'tbRegOrder.CreateDt AS tbRegOrder__CreateDt' UNION ALL
    SELECT 'tbRegOrder__IsScan', 'tbRegOrder.IsScan AS tbRegOrder__IsScan' UNION ALL
    SELECT 'tbRegOrder__IsScan__DESC', 'dbo.fnTranslateYesNo(tbRegOrder.IsScan) AS tbRegOrder__IsScan__DESC' UNION ALL
    SELECT 'tbRegOrder__Comments', 'tbRegOrder.Comments AS tbRegOrder__Comments' UNION ALL
    SELECT 'tbRegOrder__RemoteAccNo', 'tbRegOrder.RemoteAccNo AS tbRegOrder__RemoteAccNo' UNION ALL
    SELECT 'tbRegOrder__TotalFee', 'tbRegOrder.TotalFee AS tbRegOrder__TotalFee' UNION ALL
    SELECT 'tbRegOrder__Optional1', 'tbRegOrder.Optional1 AS tbRegOrder__Optional1' UNION ALL
    SELECT 'tbRegOrder__Optional2', 'tbRegOrder.Optional2 AS tbRegOrder__Optional2' UNION ALL
    SELECT 'tbRegOrder__Optional3', 'tbRegOrder.Optional3 AS tbRegOrder__Optional3' UNION ALL
    SELECT 'tbRegOrder__StudyInstanceUID', 'tbRegOrder.StudyInstanceUID AS tbRegOrder__StudyInstanceUID' UNION ALL
    SELECT 'tbRegOrder__HisID', 'tbRegOrder.HisID AS tbRegOrder__HisID' UNION ALL
    SELECT 'tbRegOrder__CardNo', 'tbRegOrder.CardNo AS tbRegOrder__CardNo' UNION ALL
    SELECT 'tbRegOrder__PatientGuid', 'tbRegOrder.PatientGuid AS tbRegOrder__PatientGuid' UNION ALL
    SELECT 'tbRegOrder__InhospitalNo', 'tbRegOrder.InhospitalNo AS tbRegOrder__InhospitalNo' UNION ALL
    SELECT 'tbRegOrder__ClinicNo', 'tbRegOrder.ClinicNo AS tbRegOrder__ClinicNo' UNION ALL
    SELECT 'tbRegOrder__PatientType', 'tbRegOrder.PatientType AS tbRegOrder__PatientType' UNION ALL
    SELECT 'tbRegOrder__Observation', 'tbRegOrder.Observation AS tbRegOrder__Observation' UNION ALL
    SELECT 'tbRegOrder__HealthHistory', 'tbRegOrder.HealthHistory AS tbRegOrder__HealthHistory' UNION ALL
    SELECT 'tbRegOrder__InhospitalRegion', 'tbRegOrder.InhospitalRegion AS tbRegOrder__InhospitalRegion' UNION ALL
    SELECT 'tbRegOrder__IsEmergency', 'tbRegOrder.IsEmergency AS tbRegOrder__IsEmergency' UNION ALL
    SELECT 'tbRegOrder__IsEmergency__DESC', 'dbo.fnTranslateYesNo(tbRegOrder.IsEmergency) AS tbRegOrder__IsEmergency__DESC' UNION ALL
    SELECT 'tbRegOrder__BedNo', 'tbRegOrder.BedNo AS tbRegOrder__BedNo' UNION ALL
    SELECT 'tbRegOrder__CurrentAge', 'dbo.fnTranslateCurrentAge(tbRegOrder.CurrentAge) AS tbRegOrder__CurrentAge' UNION ALL
    SELECT 'tbRegOrder__AgeInDays', 'tbRegOrder.AgeInDays AS tbRegOrder__AgeInDays' UNION ALL
    SELECT 'tbRegOrder__visitcomment', 'tbRegOrder.visitcomment AS tbRegOrder__visitcomment' UNION ALL
    SELECT 'tbRegOrder__ChargeType', 'tbRegOrder.ChargeType AS tbRegOrder__ChargeType' UNION ALL
    SELECT 'tbRegOrder__ErethismType', 'tbRegOrder.ErethismType AS tbRegOrder__ErethismType' UNION ALL
    SELECT 'tbRegOrder__ErethismCode', 'tbRegOrder.ErethismCode AS tbRegOrder__ErethismCode' UNION ALL
    SELECT 'tbRegOrder__ErethismGrade', 'tbRegOrder.ErethismGrade AS tbRegOrder__ErethismGrade' UNION ALL
    SELECT 'tbRegOrder__Domain', 'tbRegOrder.Domain AS tbRegOrder__Domain' UNION ALL
    SELECT 'tbRegOrder__ReferralID', 'tbRegOrder.ReferralID AS tbRegOrder__ReferralID' UNION ALL
    SELECT 'tbRegOrder__IsReferral', 'tbRegOrder.IsReferral AS tbRegOrder__IsReferral' UNION ALL
    SELECT 'tbRegOrder__IsReferral__DESC', 'dbo.fnTranslateYesNo(tbRegOrder.IsReferral) AS tbRegOrder__IsReferral__DESC' UNION ALL
    SELECT 'tbRegOrder__ExamAccNo', 'tbRegOrder.ExamAccNo AS tbRegOrder__ExamAccNo' UNION ALL
    SELECT 'tbRegOrder__ExamDomain', 'tbRegOrder.ExamDomain AS tbRegOrder__ExamDomain' UNION ALL
    SELECT 'tbRegOrder__MedicalAlert', 'tbRegOrder.MedicalAlert AS tbRegOrder__MedicalAlert' UNION ALL
    SELECT 'tbRegOrder__EXAMALERT1', 'tbRegOrder.EXAMALERT1 AS tbRegOrder__EXAMALERT1' UNION ALL
    SELECT 'tbRegOrder__EXAMALERT2', 'tbRegOrder.EXAMALERT2 AS tbRegOrder__EXAMALERT2' UNION ALL
    SELECT 'tbRegOrder__LMP', 'tbRegOrder.LMP AS tbRegOrder__LMP' UNION ALL
    SELECT 'tbRegOrder__InitialDomain', 'tbRegOrder.InitialDomain AS tbRegOrder__InitialDomain' UNION ALL
    SELECT 'tbRegOrder__ERequisition', 'tbRegOrder.ERequisition AS tbRegOrder__ERequisition' UNION ALL
    SELECT 'tbRegOrder__CurPatientName', 'tbRegOrder.CurPatientName AS tbRegOrder__CurPatientName' UNION ALL
    SELECT 'tbRegOrder__CurGender', 'tbRegOrder.CurGender AS tbRegOrder__CurGender' UNION ALL
    SELECT 'tbRegOrder__Priority', 'tbRegOrder.Priority AS tbRegOrder__Priority' UNION ALL
    SELECT 'tbRegOrder__IsCharge', 'tbRegOrder.IsCharge AS tbRegOrder__IsCharge' UNION ALL
    SELECT 'tbRegOrder__Bedside', 'tbRegOrder.Bedside AS tbRegOrder__Bedside' UNION ALL
    SELECT 'tbRegOrder__IsFilmSent', 'tbRegOrder.IsFilmSent AS tbRegOrder__IsFilmSent' UNION ALL
    SELECT 'tbRegOrder__FilmSentOperator', 'tbRegOrder.FilmSentOperator AS tbRegOrder__FilmSentOperator' UNION ALL
    SELECT 'tbRegOrder__IsCharge__DESC', 'dbo.fnTranslateYesNo(tbRegOrder.IsCharge) AS tbRegOrder__IsCharge__DESC' UNION ALL
    SELECT 'tbRegOrder__Bedside__DESC', 'dbo.fnTranslateYesNo(tbRegOrder.Bedside) AS tbRegOrder__Bedside__DESC' UNION ALL
    SELECT 'tbRegOrder__IsFilmSent__DESC', 'dbo.fnTranslateYesNo(tbRegOrder.IsFilmSent) AS tbRegOrder__IsFilmSent__DESC' UNION ALL
    SELECT 'tbRegOrder__FilmSentOperator__DESC', 'dbo.fnTranslateUser(tbRegOrder.FilmSentOperator) AS tbRegOrder__FilmSentOperator__DESC' UNION ALL
    SELECT 'tbRegOrder__FilmSentDt', 'tbRegOrder.FilmSentDt AS tbRegOrder__FilmSentDt' UNION ALL
    SELECT 'tbRegOrder__BookingSite', 'tbRegOrder.BookingSite AS tbRegOrder__BookingSite' UNION ALL
    SELECT 'tbRegOrder__RegSite', 'tbRegOrder.RegSite AS tbRegOrder__RegSite' UNION ALL
    SELECT 'tbRegOrder__ExamSite', 'tbRegOrder.ExamSite AS tbRegOrder__ExamSite' UNION ALL
    SELECT 'tbRegOrder__BookingSite__DESC', 'dbo.fnTranslateSite(tbRegOrder.BookingSite) AS tbRegOrder__BookingSite__DESC' UNION ALL
    SELECT 'tbRegOrder__RegSite__DESC', 'dbo.fnTranslateSite(tbRegOrder.RegSite) AS tbRegOrder__RegSite__DESC' UNION ALL
    SELECT 'tbRegOrder__ExamSite__DESC', 'dbo.fnTranslateSite(tbRegOrder.ExamSite) AS tbRegOrder__ExamSite__DESC' UNION ALL
    SELECT 'tbRegOrder__BodyWeight', 'tbRegOrder.BodyWeight AS tbRegOrder__BodyWeight' UNION ALL
    SELECT 'tbRegOrder__FilmFee__DESC', '(case when tbRegOrder.FilmFee > 0 then ''有'' else '''' end) AS tbRegOrder__FilmFee__DESC' UNION ALL
    SELECT 'tbRegOrder__CurrentSite', 'tbRegOrder.CurrentSite AS tbRegOrder__CurrentSite' UNION ALL
    SELECT 'tbRegOrder__ThreeDRebuild', 'tbRegOrder.ThreeDRebuild AS tbRegOrder__ThreeDRebuild' UNION ALL
    SELECT 'tbRegOrder__CurrentSite__DESC', 'dbo.fnTranslateSite(tbRegOrder.CurrentSite) AS tbRegOrder__CurrentSite__DESC' UNION ALL
    SELECT 'tbRegOrder__ThreeDRebuild__DESC', 'dbo.fnTranslateYesNo(tbRegOrder.ThreeDRebuild) AS tbRegOrder__ThreeDRebuild__DESC' UNION ALL
    SELECT 'tbRegOrder__AssignDt', 'tbRegOrder.AssignDt AS tbRegOrder__AssignDt' UNION ALL
    SELECT 'tbRegOrder__Assign2Site', 'tbRegOrder.Assign2Site AS tbRegOrder__Assign2Site' UNION ALL
    SELECT 'tbRegOrder__Assign2Site__DESC', 'dbo.fnTranslateSite(tbRegOrder.Assign2Site) AS tbRegOrder__Assign2Site__DESC' UNION ALL
    SELECT 'tbRegOrder__StudyID', 'tbRegOrder.StudyID AS tbRegOrder__StudyID' UNION ALL
    SELECT 'tbRegOrder__PathologicalFindings', 'tbRegOrder.PathologicalFindings AS tbRegOrder__PathologicalFindings' UNION ALL
    SELECT 'tbRegOrder__PhysicalCompany', 'tbRegOrder.PhysicalCompany AS tbRegOrder__PhysicalCompany' UNION ALL
    SELECT 'tbRegOrder__InternalOptional1', 'tbRegOrder.InternalOptional1 AS tbRegOrder__InternalOptional1' UNION ALL
    SELECT 'tbRegOrder__InternalOptional2', 'tbRegOrder.InternalOptional2 AS tbRegOrder__InternalOptional2' UNION ALL
    SELECT 'tbRegOrder__ExternalOptional1', 'tbRegOrder.ExternalOptional1 AS tbRegOrder__ExternalOptional1' UNION ALL
    SELECT 'tbRegOrder__ExternalOptional2', 'tbRegOrder.ExternalOptional2 AS tbRegOrder__ExternalOptional2' UNION ALL
    SELECT 'tbRegOrder__ExternalOptional3', 'tbRegOrder.ExternalOptional3 AS tbRegOrder__ExternalOptional3' UNION ALL
    SELECT 'tbRegOrder__InjectDose', 'tbRegOrder.InjectDose AS tbRegOrder__InjectDose' UNION ALL
    SELECT 'tbRegOrder__InjectTime', 'tbRegOrder.InjectTime AS tbRegOrder__InjectTime' UNION ALL
    SELECT 'tbRegOrder__BodyHeight', 'tbRegOrder.BodyHeight AS tbRegOrder__BodyHeight' UNION ALL
    SELECT 'tbRegOrder__BloodSugar', 'tbRegOrder.BloodSugar AS tbRegOrder__BloodSugar' UNION ALL
    SELECT 'tbRegOrder__Insulin', 'tbRegOrder.Insulin AS tbRegOrder__Insulin' UNION ALL
    SELECT 'tbRegOrder__GoOnGoTime', 'tbRegOrder.GoOnGoTime AS tbRegOrder__GoOnGoTime' UNION ALL
    SELECT 'tbRegOrder__InjectorRemnant', 'tbRegOrder.InjectorRemnant AS tbRegOrder__InjectorRemnant' UNION ALL
    SELECT 'tbRegOrder__SubmitHospital', 'tbRegOrder.SubmitHospital AS tbRegOrder__SubmitHospital' UNION ALL
    SELECT 'tbRegOrder__SubmitDept', 'tbRegOrder.SubmitDept AS tbRegOrder__SubmitDept' UNION ALL
    SELECT 'tbRegOrder__SubmitDoctor', 'tbRegOrder.SubmitDoctor AS tbRegOrder__SubmitDoctor' UNION ALL
    SELECT 'tbRegOrder__TakeReportDate', 'tbRegOrder.TakeReportDate AS tbRegOrder__TakeReportDate' UNION ALL
    SELECT 'tbRegOrder__ExecuteDepartment', 'tbRegOrder.ExecuteDepartment AS tbRegOrder__ExecuteDepartment' UNION ALL
    SELECT 'tbRegProcedure__ProcedureGuid', 'tbRegProcedure.ProcedureGuid AS tbRegProcedure__ProcedureGuid' UNION ALL
    SELECT 'tbRegProcedure__OrderGuid', 'tbRegProcedure.OrderGuid AS tbRegProcedure__OrderGuid' UNION ALL
    SELECT 'tbRegProcedure__ProcedureCode', 'tbRegProcedure.ProcedureCode AS tbRegProcedure__ProcedureCode' UNION ALL
    SELECT 'tbRegProcedure__ExamSystem', 'tbRegProcedure.ExamSystem AS tbRegProcedure__ExamSystem' UNION ALL
    SELECT 'tbRegProcedure__WarningTime', 'tbRegProcedure.WarningTime AS tbRegProcedure__WarningTime' UNION ALL
    SELECT 'tbRegProcedure__FilmSpec', 'tbRegProcedure.FilmSpec AS tbRegProcedure__FilmSpec' UNION ALL
    SELECT 'tbRegProcedure__FilmCount', 'tbRegProcedure.FilmCount AS tbRegProcedure__FilmCount' UNION ALL
    SELECT 'tbRegProcedure__ContrastName', 'tbRegProcedure.ContrastName AS tbRegProcedure__ContrastName' UNION ALL
    SELECT 'tbRegProcedure__ContrastDose', 'tbRegProcedure.ContrastDose AS tbRegProcedure__ContrastDose' UNION ALL
    SELECT 'tbRegProcedure__ImageCount', 'tbRegProcedure.ImageCount AS tbRegProcedure__ImageCount' UNION ALL
    SELECT 'tbRegProcedure__ExposalCount', 'tbRegProcedure.ExposalCount AS tbRegProcedure__ExposalCount' UNION ALL
    SELECT 'tbRegProcedure__Deposit', 'tbRegProcedure.Deposit AS tbRegProcedure__Deposit' UNION ALL
    SELECT 'tbRegProcedure__Charge', 'tbRegProcedure.Charge AS tbRegProcedure__Charge' UNION ALL
    SELECT 'tbRegProcedure__ModalityType', 'tbRegProcedure.ModalityType AS tbRegProcedure__ModalityType' UNION ALL
    SELECT 'tbRegProcedure__Modality', 'tbRegProcedure.Modality AS tbRegProcedure__Modality' UNION ALL
    SELECT 'tbRegProcedure__Registrar', 'tbRegProcedure.Registrar AS tbRegProcedure__Registrar' UNION ALL
    SELECT 'tbRegProcedure__Registrar__DESC', 'dbo.fnTranslateUser(tbRegProcedure.Registrar) AS tbRegProcedure__Registrar__DESC' UNION ALL
    SELECT 'tbRegProcedure__RegisterDt', 'tbRegProcedure.RegisterDt AS tbRegProcedure__RegisterDt' UNION ALL
    SELECT 'tbRegProcedure__Priority', 'tbRegProcedure.Priority AS tbRegProcedure__Priority' UNION ALL
    SELECT 'tbRegProcedure__Technician', 'tbRegProcedure.Technician AS tbRegProcedure__Technician' UNION ALL
    SELECT 'tbRegProcedure__TechDoctor', 'tbRegProcedure.TechDoctor AS tbRegProcedure__TechDoctor' UNION ALL
    SELECT 'tbRegProcedure__TechNurse', 'tbRegProcedure.TechNurse AS tbRegProcedure__TechNurse' UNION ALL
    SELECT 'tbRegProcedure__Technician__DESC', 'dbo.fnTranslateUser(tbRegProcedure.Technician) AS tbRegProcedure__Technician__DESC' UNION ALL
    SELECT 'tbRegProcedure__TechDoctor__DESC', 'dbo.fnTranslateUser(tbRegProcedure.TechDoctor) AS tbRegProcedure__TechDoctor__DESC' UNION ALL
    SELECT 'tbRegProcedure__TechNurse__DESC', 'dbo.fnTranslateUser(tbRegProcedure.TechNurse) AS tbRegProcedure__TechNurse__DESC' UNION ALL
    SELECT 'tbRegProcedure__OperationStep', 'tbRegProcedure.OperationStep AS tbRegProcedure__OperationStep' UNION ALL
    SELECT 'tbRegProcedure__ExamineDt', 'tbRegProcedure.ExamineDt AS tbRegProcedure__ExamineDt' UNION ALL
    SELECT 'tbRegProcedure__Mender', 'tbRegProcedure.Mender AS tbRegProcedure__Mender' UNION ALL
    SELECT 'tbRegProcedure__Mender__DESC', 'dbo.fnTranslateUser(tbRegProcedure.Mender) AS tbRegProcedure__Mender__DESC' UNION ALL
    SELECT 'tbRegProcedure__ModifyDt', 'tbRegProcedure.ModifyDt AS tbRegProcedure__ModifyDt' UNION ALL
    SELECT 'tbRegProcedure__IsPost', 'tbRegProcedure.IsPost AS tbRegProcedure__IsPost' UNION ALL
    SELECT 'tbRegProcedure__IsExistImage', 'tbRegProcedure.IsExistImage AS tbRegProcedure__IsExistImage' UNION ALL
    SELECT 'tbRegProcedure__Status', 'tbRegProcedure.Status AS tbRegProcedure__Status' UNION ALL
    SELECT 'tbRegProcedure__IsPost__DESC', 'dbo.fnTranslateYesNo(tbRegProcedure.IsPost) AS tbRegProcedure__IsPost__DESC' UNION ALL
    SELECT 'tbRegProcedure__IsExistImage__DESC', 'dbo.fnTranslateYesNo(tbRegProcedure.IsExistImage) AS tbRegProcedure__IsExistImage__DESC' UNION ALL
    SELECT 'tbRegProcedure__Status__DESC', 'dbo.fnTranslateDictionaryValue(13, tbRegProcedure.Status) AS tbRegProcedure__Status__DESC' UNION ALL
    SELECT 'tbRegProcedure__Comments', 'tbRegProcedure.Comments AS tbRegProcedure__Comments' UNION ALL
    SELECT 'tbRegProcedure__BookingBeginDt', 'tbRegProcedure.BookingBeginDt AS tbRegProcedure__BookingBeginDt' UNION ALL
    SELECT 'tbRegProcedure__BookingEndDt', 'tbRegProcedure.BookingEndDt AS tbRegProcedure__BookingEndDt' UNION ALL
    SELECT 'tbRegProcedure__Booker', 'tbRegProcedure.Booker AS tbRegProcedure__Booker' UNION ALL
    SELECT 'tbRegProcedure__IsCharge', 'tbRegProcedure.IsCharge AS tbRegProcedure__IsCharge' UNION ALL
    SELECT 'tbRegProcedure__Booker__DESC', 'dbo.fnTranslateUser(tbRegProcedure.Booker) AS tbRegProcedure__Booker__DESC' UNION ALL
    SELECT 'tbRegProcedure__IsCharge__DESC', 'dbo.fnTranslateUser(tbRegProcedure.IsCharge) AS tbRegProcedure__IsCharge__DESC' UNION ALL
    SELECT 'tbRegProcedure__RemoteRPID', 'tbRegProcedure.RemoteRPID AS tbRegProcedure__RemoteRPID' UNION ALL
    SELECT 'tbRegProcedure__Optional1', 'tbRegProcedure.Optional1 AS tbRegProcedure__Optional1' UNION ALL
    SELECT 'tbRegProcedure__Optional2', 'tbRegProcedure.Optional2 AS tbRegProcedure__Optional2' UNION ALL
    SELECT 'tbRegProcedure__Optional3', 'tbRegProcedure.Optional3 AS tbRegProcedure__Optional3' UNION ALL
    SELECT 'tbRegProcedure__QueueNo', 'tbRegProcedure.QueueNo AS tbRegProcedure__QueueNo' UNION ALL
    SELECT 'tbRegProcedure__BookingTimeAlias', 'tbRegProcedure.BookingTimeAlias AS tbRegProcedure__BookingTimeAlias' UNION ALL
    SELECT 'tbRegProcedure__CreateDt', 'tbRegProcedure.CreateDt AS tbRegProcedure__CreateDt' UNION ALL
    SELECT 'tbRegProcedure__ReportGuid', 'tbRegProcedure.ReportGuid AS tbRegProcedure__ReportGuid' UNION ALL
    SELECT 'tbRegProcedure__MedicineUsage', 'tbRegProcedure.MedicineUsage AS tbRegProcedure__MedicineUsage' UNION ALL
    SELECT 'tbRegProcedure__Posture', 'tbRegProcedure.Posture AS tbRegProcedure__Posture' UNION ALL
    SELECT 'tbRegProcedure__Technician1', 'tbRegProcedure.Technician1 AS tbRegProcedure__Technician1' UNION ALL
    SELECT 'tbRegProcedure__Technician2', 'tbRegProcedure.Technician2 AS tbRegProcedure__Technician2' UNION ALL
    SELECT 'tbRegProcedure__Technician3', 'tbRegProcedure.Technician3 AS tbRegProcedure__Technician3' UNION ALL
    SELECT 'tbRegProcedure__Technician4', 'tbRegProcedure.Technician4 AS tbRegProcedure__Technician4' UNION ALL
    SELECT 'tbRegProcedure__Technician1__DESC', 'dbo.fnTranslateUser(tbRegProcedure.Technician1) AS tbRegProcedure__Technician1__DESC' UNION ALL
    SELECT 'tbRegProcedure__Technician2__DESC', 'dbo.fnTranslateUser(tbRegProcedure.Technician2) AS tbRegProcedure__Technician2__DESC' UNION ALL
    SELECT 'tbRegProcedure__Technician3__DESC', 'dbo.fnTranslateUser(tbRegProcedure.Technician3) AS tbRegProcedure__Technician3__DESC' UNION ALL
    SELECT 'tbRegProcedure__Technician4__DESC', 'dbo.fnTranslateUser(tbRegProcedure.Technician4) AS tbRegProcedure__Technician4__DESC' UNION ALL
    SELECT 'tbRegProcedure__Domain', 'tbRegProcedure.Domain AS tbRegProcedure__Domain' UNION ALL
    SELECT 'tbRegProcedure__UnwrittenPreviousOwner', 'tbRegProcedure.UnwrittenPreviousOwner AS tbRegProcedure__UnwrittenPreviousOwner' UNION ALL
    SELECT 'tbRegProcedure__UnwrittenCurrentOwner', 'tbRegProcedure.UnwrittenCurrentOwner AS tbRegProcedure__UnwrittenCurrentOwner' UNION ALL
    SELECT 'tbRegProcedure__UnwrittenPreviousOwner__DESC', 'dbo.fnTranslateUser(tbRegProcedure.UnwrittenPreviousOwner) AS tbRegProcedure__UnwrittenPreviousOwner__DESC' UNION ALL
    SELECT 'tbRegProcedure__UnwrittenCurrentOwner__DESC', 'dbo.fnTranslateUser(tbRegProcedure.UnwrittenCurrentOwner) AS tbRegProcedure__UnwrittenCurrentOwner__DESC' UNION ALL
    SELECT 'tbRegProcedure__UnwrittenAssignDate', 'tbRegProcedure.UnwrittenAssignDate AS tbRegProcedure__UnwrittenAssignDate' UNION ALL
    SELECT 'tbRegProcedure__UnapprovedCurrentOwner', 'tbRegProcedure.UnapprovedCurrentOwner AS tbRegProcedure__UnapprovedCurrentOwner' UNION ALL
    SELECT 'tbRegProcedure__UnapprovedPreviousOwner', 'tbRegProcedure.UnapprovedPreviousOwner AS tbRegProcedure__UnapprovedPreviousOwner' UNION ALL
    SELECT 'tbRegProcedure__UnapprovedCurrentOwner__DESC', 'dbo.fnTranslateUser(tbRegProcedure.UnapprovedCurrentOwner) AS tbRegProcedure__UnapprovedCurrentOwner__DESC' UNION ALL
    SELECT 'tbRegProcedure__UnapprovedPreviousOwner__DESC', 'dbo.fnTranslateUser(tbRegProcedure.UnapprovedPreviousOwner) AS tbRegProcedure__UnapprovedPreviousOwner__DESC' UNION ALL
    SELECT 'tbRegProcedure__UnapprovedAssignDate', 'tbRegProcedure.UnapprovedAssignDate AS tbRegProcedure__UnapprovedAssignDate' UNION ALL
    SELECT 'tbRegProcedure__PreStatus', 'tbRegProcedure.PreStatus AS tbRegProcedure__PreStatus' UNION ALL
    SELECT 'tbRegProcedure__BookerName', 'tbRegProcedure.BookerName AS tbRegProcedure__BookerName' UNION ALL
    SELECT 'tbRegProcedure__RegistrarName', 'tbRegProcedure.RegistrarName AS tbRegProcedure__RegistrarName' UNION ALL
    SELECT 'tbRegProcedure__TechnicianName', 'tbRegProcedure.TechnicianName AS tbRegProcedure__TechnicianName' UNION ALL
    SELECT 'tbRegProcedure__BodyCategory', 'tbRegProcedure.BodyCategory AS tbRegProcedure__BodyCategory' UNION ALL
    SELECT 'tbRegProcedure__Bodypart', 'tbRegProcedure.Bodypart AS tbRegProcedure__Bodypart' UNION ALL
    SELECT 'tbRegProcedure__CheckingItem', 'tbRegProcedure.CheckingItem AS tbRegProcedure__CheckingItem' UNION ALL
    SELECT 'tbRegProcedure__RPDesc', 'tbRegProcedure.RPDesc AS tbRegProcedure__RPDesc' UNION ALL
    SELECT 'tbReport__ReportGuid', 'tbReport.ReportGuid AS tbReport__ReportGuid' UNION ALL
    SELECT 'tbReport__ReportName', 'tbReport.ReportName AS tbReport__ReportName' UNION ALL
    SELECT 'tbReport__ReportText', 'tbReport.ReportText AS tbReport__ReportText' UNION ALL
    SELECT 'tbReport__DoctorAdvice', 'tbReport.DoctorAdvice AS tbReport__DoctorAdvice' UNION ALL
    SELECT 'tbReport__IsPositive', 'tbReport.IsPositive AS tbReport__IsPositive' UNION ALL
    SELECT 'tbReport__IsPositive__DESC', 'dbo.fnTranslateDictionaryValue(21, tbReport.IsPositive) AS tbReport__IsPositive__DESC' UNION ALL
    SELECT 'tbReport__AcrCode', 'tbReport.AcrCode AS tbReport__AcrCode' UNION ALL
    SELECT 'tbReport__AcrAnatomic', 'tbReport.AcrAnatomic AS tbReport__AcrAnatomic' UNION ALL
    SELECT 'tbReport__AcrPathologic', 'tbReport.AcrPathologic AS tbReport__AcrPathologic' UNION ALL
    SELECT 'tbReport__Creater', 'tbReport.Creater AS tbReport__Creater' UNION ALL
    SELECT 'tbReport__Creater__DESC', 'dbo.fnTranslateUser(tbReport.Creater) AS tbReport__Creater__DESC' UNION ALL
    SELECT 'tbReport__CreateDt', 'tbReport.CreateDt AS tbReport__CreateDt' UNION ALL
    SELECT 'tbReport__Submitter', 'tbReport.Submitter AS tbReport__Submitter' UNION ALL
    SELECT 'tbReport__Submitter__DESC', 'dbo.fnTranslateUser(tbReport.Submitter) AS tbReport__Submitter__DESC' UNION ALL
    SELECT 'tbReport__SubmitDt', 'tbReport.SubmitDt AS tbReport__SubmitDt' UNION ALL
    SELECT 'tbReport__FirstApprover', 'tbReport.FirstApprover AS tbReport__FirstApprover' UNION ALL
    SELECT 'tbReport__FirstApprover__DESC', '(case when firstApproverName<>'''' then firstApproverName else dbo.fnTranslateUser(tbReport.firstApprover) END) AS tbReport__FirstApprover__DESC' UNION ALL
    SELECT 'tbReport__FirstApproveDt', 'tbReport.FirstApproveDt AS tbReport__FirstApproveDt' UNION ALL
    SELECT 'tbReport__SecondApprover', 'tbReport.SecondApprover AS tbReport__SecondApprover' UNION ALL
    SELECT 'tbReport__SecondApprover__DESC', 'dbo.fnTranslateUser(tbReport.SecondApprover) AS tbReport__SecondApprover__DESC' UNION ALL
    SELECT 'tbReport__SecondApproveDt', 'tbReport.SecondApproveDt AS tbReport__SecondApproveDt' UNION ALL
    SELECT 'tbReport__IsDiagnosisRight', 'tbReport.IsDiagnosisRight AS tbReport__IsDiagnosisRight' UNION ALL
    SELECT 'tbReport__KeyWord', 'tbReport.KeyWord AS tbReport__KeyWord' UNION ALL
    SELECT 'tbReport__ReportQuality', 'tbReport.ReportQuality AS tbReport__ReportQuality' UNION ALL
    SELECT 'tbReport__RejectToObject', 'tbReport.RejectToObject AS tbReport__RejectToObject' UNION ALL
    SELECT 'tbReport__Rejecter', 'tbReport.Rejecter AS tbReport__Rejecter' UNION ALL
    SELECT 'tbReport__RejectToObject__DESC', 'dbo.fnTranslateUser(tbReport.RejectToObject) AS tbReport__RejectToObject__DESC' UNION ALL
    SELECT 'tbReport__Rejecter__DESC', 'dbo.fnTranslateUser(tbReport.Rejecter) AS tbReport__Rejecter__DESC' UNION ALL
    SELECT 'tbReport__RejectDt', 'tbReport.RejectDt AS tbReport__RejectDt' UNION ALL
    SELECT 'tbReport__Status', 'tbReport.Status AS tbReport__Status' UNION ALL
    SELECT 'tbReport__Comments', 'tbReport.Comments AS tbReport__Comments' UNION ALL
    SELECT 'tbReport__DeleteMark', 'tbReport.DeleteMark AS tbReport__DeleteMark' UNION ALL
    SELECT 'tbReport__Deleter', 'tbReport.Deleter AS tbReport__Deleter' UNION ALL
    SELECT 'tbReport__Deleter__DESC', 'dbo.fnTranslateUser(tbReport.Deleter) AS tbReport__Deleter__DESC' UNION ALL
    SELECT 'tbReport__DeleteDt', 'tbReport.DeleteDt AS tbReport__DeleteDt' UNION ALL
    SELECT 'tbReport__Recuperator', 'tbReport.Recuperator AS tbReport__Recuperator' UNION ALL
    SELECT 'tbReport__Recuperator__DESC', 'dbo.fnTranslateUser(tbReport.Recuperator) AS tbReport__Recuperator__DESC' UNION ALL
    SELECT 'tbReport__ReconvertDt', 'tbReport.ReconvertDt AS tbReport__ReconvertDt' UNION ALL
    SELECT 'tbReport__Mender', 'tbReport.Mender AS tbReport__Mender' UNION ALL
    SELECT 'tbReport__Mender__DESC', '(case when menderName<>'''' then menderName else dbo.fnTranslateUser(tbReport.mender) END) AS tbReport__Mender__DESC' UNION ALL
    SELECT 'tbReport__ModifyDt', 'tbReport.ModifyDt AS tbReport__ModifyDt' UNION ALL
    SELECT 'tbReport__IsPrint', 'tbReport.IsPrint AS tbReport__IsPrint' UNION ALL
    SELECT 'tbReport__IsPrint__DESC', 'dbo.fnTranslateYesNo(tbReport.IsPrint) AS tbReport__IsPrint__DESC' UNION ALL
    SELECT 'tbReport__CheckItemName', 'tbReport.CheckItemName AS tbReport__CheckItemName' UNION ALL
    SELECT 'tbReport__Optional1', 'tbReport.Optional1 AS tbReport__Optional1' UNION ALL
    SELECT 'tbReport__Optional2', 'tbReport.Optional2 AS tbReport__Optional2' UNION ALL
    SELECT 'tbReport__Optional3', 'tbReport.Optional3 AS tbReport__Optional3' UNION ALL
    SELECT 'tbReport__IsLeaveWord', 'tbReport.IsLeaveWord AS tbReport__IsLeaveWord' UNION ALL
    SELECT 'tbReport__IsLeaveWord__DESC', 'dbo.fnTranslateYesNo(tbReport.IsLeaveWord) AS tbReport__IsLeaveWord__DESC' UNION ALL
    SELECT 'tbReport__WYSText', 'tbReport.WYSText AS tbReport__WYSText' UNION ALL
    SELECT 'tbReport__WYGText', 'tbReport.WYGText AS tbReport__WYGText' UNION ALL
    SELECT 'tbReport__IsDraw', 'tbReport.IsDraw AS tbReport__IsDraw' UNION ALL
    SELECT 'tbReport__IsDraw__DESC', 'dbo.fnTranslateYesNo(tbReport.IsDraw) AS tbReport__IsDraw__DESC' UNION ALL
    SELECT 'tbReport__DrawTime', 'tbReport.DrawTime AS tbReport__DrawTime' UNION ALL
    SELECT 'tbReport__IsLeaveSound', 'tbReport.IsLeaveSound AS tbReport__IsLeaveSound' UNION ALL
    SELECT 'tbReport__IsLeaveSound__DESC', 'dbo.fnTranslateYesNo(tbReport.IsLeaveSound) AS tbReport__IsLeaveSound__DESC' UNION ALL
    SELECT 'tbReport__TakeFilmDept', 'tbReport.TakeFilmDept AS tbReport__TakeFilmDept' UNION ALL
    SELECT 'tbReport__TakeFilmRegion', 'tbReport.TakeFilmRegion AS tbReport__TakeFilmRegion' UNION ALL
    SELECT 'tbReport__TakeFilmComment', 'tbReport.TakeFilmComment AS tbReport__TakeFilmComment' UNION ALL
    SELECT 'tbReport__PrintCopies', 'tbReport.PrintCopies AS tbReport__PrintCopies' UNION ALL
    SELECT 'tbReport__PrintTemplateGuid', 'tbReport.PrintTemplateGuid AS tbReport__PrintTemplateGuid' UNION ALL
    SELECT 'tbReport__Domain', 'tbReport.Domain AS tbReport__Domain' UNION ALL
    SELECT 'tbReport__ReadOnly', 'tbReport.ReadOnly AS tbReport__ReadOnly' UNION ALL
    SELECT 'tbReport__SubmitDomain', 'tbReport.SubmitDomain AS tbReport__SubmitDomain' UNION ALL
    SELECT 'tbReport__RejectDomain', 'tbReport.RejectDomain AS tbReport__RejectDomain' UNION ALL
    SELECT 'tbReport__FirstApproveDomain', 'tbReport.FirstApproveDomain AS tbReport__FirstApproveDomain' UNION ALL
    SELECT 'tbReport__SecondApproveDomain', 'tbReport.SecondApproveDomain AS tbReport__SecondApproveDomain' UNION ALL
    SELECT 'tbReport__RejectSite', 'tbReport.RejectSite AS tbReport__RejectSite' UNION ALL
    SELECT 'tbReport__SubmitSite', 'tbReport.SubmitSite AS tbReport__SubmitSite' UNION ALL
    SELECT 'tbReport__FirstApproveSite', 'tbReport.FirstApproveSite AS tbReport__FirstApproveSite' UNION ALL
    SELECT 'tbReport__SecondApproveSite', 'tbReport.SecondApproveSite AS tbReport__SecondApproveSite' UNION ALL
    SELECT 'tbReport__RejectSite__DESC', 'dbo.fnTranslateSite(tbReport.RejectSite) AS tbReport__RejectSite__DESC' UNION ALL
    SELECT 'tbReport__SubmitSite__DESC', 'dbo.fnTranslateSite(tbReport.SubmitSite) AS tbReport__SubmitSite__DESC' UNION ALL
    SELECT 'tbReport__FirstApproveSite__DESC', 'dbo.fnTranslateSite(tbReport.FirstApproveSite) AS tbReport__FirstApproveSite__DESC' UNION ALL
    SELECT 'tbReport__SecondApproveSite__DESC', 'dbo.fnTranslateSite(tbReport.SecondApproveSite) AS tbReport__SecondApproveSite__DESC' UNION ALL
    SELECT 'tbReport__RebuildMark', 'tbReport.RebuildMark AS tbReport__RebuildMark' UNION ALL
    SELECT 'tbReport__ReportQuality2', 'tbReport.ReportQuality2 AS tbReport__ReportQuality2' UNION ALL
    SELECT 'tbReport__SubmitterName', 'dbo.fnTranslateIntern(tbReport.SubmitterName,tbReport.Submitter) AS tbReport__SubmitterName' UNION ALL
    SELECT 'tbReport__FirstApproverName', 'tbReport.FirstApproverName AS tbReport__FirstApproverName' UNION ALL
    SELECT 'tbReport__SecondApproverName', 'tbReport.SecondApproverName AS tbReport__SecondApproverName' UNION ALL
    SELECT 'tbReport__ReportQualityComments', 'tbReport.ReportQualityComments AS tbReport__ReportQualityComments' UNION ALL
    SELECT 'tbReport__CreaterName', 'dbo.fnTranslateIntern(tbReport.CreaterName,tbReport.Creater) AS tbReport__CreaterName' UNION ALL
    SELECT 'tbReport__MenderName', 'tbReport.MenderName AS tbReport__MenderName' UNION ALL
    SELECT 'tbReport__IsModified', 'tbReport.IsModified AS tbReport__IsModified' UNION ALL
    SELECT 'tbReport__IsModified__DESC', 'dbo.fnTranslateYesNoEmpty(tbReport.IsModified) AS tbReport__IsModified__DESC' UNION ALL
    SELECT 'tbReport__TechInfo', 'tbReport.TechInfo AS tbReport__TechInfo' UNION ALL
    SELECT 'tbProcedureCode__RadiologistWeight', '(select RadiologistWeight from tbProcedureCode where ProcedureCode=tbRegProcedure.ProcedureCode) AS tbProcedureCode__RadiologistWeight' UNION ALL
    SELECT 'tbProcedureCode__ApprovedRadiologistWeight', '(select ApprovedRadiologistWeight from tbProcedureCode where ProcedureCode=tbRegProcedure.ProcedureCode) AS tbProcedureCode__ApprovedRadiologistWeight' UNION ALL
    SELECT 'tbModality__Room', '(select top 1 tbModality.Room from tbModality where tbRegProcedure.Modality=tbModality.Modality ) AS tbModality__Room' UNION ALL
    SELECT 'tbConsultation__cstStatus__DESC', '(select top 1 dbo.fnTranslateDictionaryValue(160, cstStatus) from tbConsultation where cstOrderGuid=tbRegOrder.OrderGuid Order By cstApplyTime DESC) AS tbConsultation__cstStatus__DESC' UNION ALL
    SELECT 'tbReferralList__RefStatus__DESC', '(select top 1 dbo.fnTranslateDictionaryValue(223, RefStatus) from tbReferralList where referralid=tbRegOrder.referralid) AS tbReferralList__RefStatus__DESC' UNION ALL
    SELECT 'tbRegPatient__IsAllergic', 'tbRegPatient.IsAllergic AS tbRegPatient__IsAllergic' UNION ALL
    SELECT 'tbRegPatient__IsAllergic__DESC', 'dbo.fnTranslateYesNo(tbRegPatient.IsAllergic) AS tbRegPatient__IsAllergic__DESC'
)

SELECT @totalColumns = REPLACE(REPLACE(STUFF((
    SELECT ', ' + SqlText FROM Mapping m WHERE EXISTS (SELECT 1 FROM ColList c WHERE LTRIM(RTRIM(c.ColName)) = m.ColName) FOR XML PATH('')
), 1, 2, ''), '&lt;', '<'), '&gt;', '>')

if @Columns = '' set @Columns='*'

declare @sql nvarchar(MAX)
SET @sql = '
;WITH Page AS (
    SELECT TOP '+cast(@maxrowcount as varchar(18)) +'
        ROW_NUMBER() Over(' + @rowNumOrderBy + ') as rowNum,
        ' + @totalColumns + '
        FROM tbRegPatient WITH (NOLOCK)
        JOIN tbRegOrder WITH (NOLOCK) ON tbRegPatient.PatientGuid = tbRegOrder.PatientGuid
        JOIN tbRegProcedure WITH (NOLOCK) ON tbRegOrder.OrderGuid = tbRegProcedure.OrderGuid
        LEFT JOIN tbReport WITH (NOLOCK) ON tbReport.reportguid = tbRegProcedure.reportguid
        WHERE tbRegProcedure.Status>=0 AND ' + @Conditions + '
        ' + @OrderBy + '
)
SELECT * FROM Page WITH (NOLOCK) WHERE Page.rowNum between '+cast(@minrowcount as varchar(18)) +' and '+cast(@maxrowcount as varchar(18))

EXEC(@sql)
END


GO
/****** Object:  StoredProcedure [dbo].[procBaseListPageWithArchive]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procBaseListPageWithArchive]
 @PageIndex integer,
 @PageSize integer,
 @Columns nvarchar(MAX),
 @Conditions nvarchar(MAX),
 @OrderBy nvarchar(MAX)
AS 
BEGIN

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

if @PageSize < 1 set @PageSize = 30
if @PageIndex > 0xfffff set @PageIndex = 0xfffff
if @PageIndex < 1 set @PageIndex = 1

declare @minrowcount int
declare @maxrowcount int
set @minrowcount=(@PageIndex-1)*@PageSize+1
set @maxrowcount = @PageIndex * @PageSize

declare @rowNumOrderBy nvarchar(MAX)
set @rowNumOrderBy = @OrderBy
if @rowNumOrderBy = '' set @rowNumOrderBy = 'Order by (select 1)'
set @rowNumOrderBy = replace(@rowNumOrderBy, '.', '__')
--set @OrderBy=replace(@OrderBy, '.', '__')

declare @totalColumns nvarchar(MAX)

;WITH ColList AS (
    SELECT ColName = y.i.value('(./text())[1]', 'nvarchar(4000)')
        FROM (
            SELECT x = CONVERT(XML, '<i>' + REPLACE(REPLACE(REPLACE(@Columns, CHAR(13), ''), CHAR(10), ''), ',', '</i><i>') + '</i>').query('.')
        ) AS a CROSS APPLY x.nodes('i') AS y(i)
), Mapping (ColName, SqlText) AS (
    SELECT 'tbRegOrder__OrderMessage', 'tbRegOrder.OrderMessage AS tbRegOrder__OrderMessage' UNION ALL
    SELECT 'OrderMessageXml', 'convert(varchar(max),tbRegOrder.OrderMessage) AS OrderMessageXml' UNION ALL
    SELECT 'tbRegOrder__OrderMessage__DESC', '(case when tbRegOrder.OrderMessage IS NULL then '''' when cast(tbRegOrder.OrderMessage AS nvarchar(max))='''' then '''' when tbRegOrder.OrderMessage.exist(''/LeaveMessage[@Type]'')=1 then tbRegOrder.OrderMessage.value(''/LeaveMessage[1]/@Type[1]'',''nvarchar(64)'') when tbRegOrder.OrderMessage.exist(''/LeaveMessage[@HasCriticalSigns]'')=0 or tbRegOrder.OrderMessage.exist(''/LeaveMessage[@HasCriticalSigns="0"]'')=1 then ''a'' when tbRegOrder.OrderMessage.exist(''//Message[@IsCriticalSign="0"]'')=1 then ''ab'' else ''b'' end) AS tbRegOrder__OrderMessage__DESC' UNION ALL
    SELECT 'tbRegPatient__PatientID', 'tbRegPatient.PatientID AS tbRegPatient__PatientID' UNION ALL
    SELECT 'tbRegPatient__LocalName', 'tbRegPatient.LocalName AS tbRegPatient__LocalName' UNION ALL
    SELECT 'tbRegPatient__EnglishName', 'tbRegPatient.EnglishName AS tbRegPatient__EnglishName' UNION ALL
    SELECT 'tbRegPatient__ReferenceNo', 'tbRegPatient.ReferenceNo AS tbRegPatient__ReferenceNo' UNION ALL
    SELECT 'tbRegPatient__Birthday', 'tbRegPatient.Birthday AS tbRegPatient__Birthday' UNION ALL
    SELECT 'tbRegPatient__Gender', 'tbRegPatient.Gender AS tbRegPatient__Gender' UNION ALL
    SELECT 'tbRegPatient__Address', 'tbRegPatient.Address AS tbRegPatient__Address' UNION ALL
    SELECT 'tbRegPatient__Telephone', 'tbRegPatient.Telephone AS tbRegPatient__Telephone' UNION ALL
    SELECT 'tbRegPatient__IsVIP', 'tbRegPatient.IsVIP AS tbRegPatient__IsVIP' UNION ALL
    SELECT 'tbRegPatient__IsVIP__DESC', 'dbo.fnTranslateYesNo(tbRegPatient.IsVIP) AS tbRegPatient__IsVIP__DESC' UNION ALL
    SELECT 'tbRegPatient__CreateDt', 'tbRegPatient.CreateDt AS tbRegPatient__CreateDt' UNION ALL
    SELECT 'tbRegPatient__Comments', 'tbRegPatient.Comments AS tbRegPatient__Comments' UNION ALL
    SELECT 'tbRegPatient__RemotePID', 'tbRegPatient.RemotePID AS tbRegPatient__RemotePID' UNION ALL
    SELECT 'tbRegPatient__Optional1', 'tbRegPatient.Optional1 AS tbRegPatient__Optional1' UNION ALL
    SELECT 'tbRegPatient__Optional2', 'tbRegPatient.Optional2 AS tbRegPatient__Optional2' UNION ALL
    SELECT 'tbRegPatient__Optional3', 'tbRegPatient.Optional3 AS tbRegPatient__Optional3' UNION ALL
    SELECT 'tbRegPatient__Alias', 'tbRegPatient.Alias AS tbRegPatient__Alias' UNION ALL
    SELECT 'tbRegPatient__Marriage', 'tbRegPatient.Marriage AS tbRegPatient__Marriage' UNION ALL
    SELECT 'tbRegPatient__Domain', 'tbRegPatient.Domain AS tbRegPatient__Domain' UNION ALL
    SELECT 'tbRegPatient__GlobalID', 'tbRegPatient.GlobalID AS tbRegPatient__GlobalID' UNION ALL
    SELECT 'tbRegPatient__MedicareNo', 'tbRegPatient.MedicareNo AS tbRegPatient__MedicareNo' UNION ALL
    SELECT 'tbRegPatient__ParentName', 'tbRegPatient.ParentName AS tbRegPatient__ParentName' UNION ALL
    SELECT 'tbRegPatient__RelatedID', 'tbRegPatient.RelatedID AS tbRegPatient__RelatedID' UNION ALL
    SELECT 'tbRegPatient__Site', 'tbRegPatient.Site AS tbRegPatient__Site' UNION ALL
    SELECT 'tbRegPatient__Site__DESC', 'dbo.fnTranslateSite(tbRegPatient.Site) AS tbRegPatient__Site__DESC' UNION ALL
    SELECT 'tbRegPatient__PatientGuid', 'tbRegPatient.PatientGuid AS tbRegPatient__PatientGuid' UNION ALL
    SELECT 'tbRegPatient__SocialSecurityNo', 'tbRegPatient.SocialSecurityNo AS tbRegPatient__SocialSecurityNo' UNION ALL
    SELECT 'tbRegOrder__OrderGuid', 'tbRegOrder.OrderGuid AS tbRegOrder__OrderGuid' UNION ALL
    SELECT 'tbRegOrder__VisitGuid', 'tbRegOrder.VisitGuid AS tbRegOrder__VisitGuid' UNION ALL
    SELECT 'tbRegOrder__AccNo', 'tbRegOrder.AccNo AS tbRegOrder__AccNo' UNION ALL
    SELECT 'tbRegOrder__ApplyDept', 'tbRegOrder.ApplyDept AS tbRegOrder__ApplyDept' UNION ALL
    SELECT 'tbRegOrder__ApplyDoctor', 'tbRegOrder.ApplyDoctor AS tbRegOrder__ApplyDoctor' UNION ALL
    SELECT 'tbRegOrder__CreateDt', 'tbRegOrder.CreateDt AS tbRegOrder__CreateDt' UNION ALL
    SELECT 'tbRegOrder__IsScan', 'tbRegOrder.IsScan AS tbRegOrder__IsScan' UNION ALL
    SELECT 'tbRegOrder__IsScan__DESC', 'dbo.fnTranslateYesNo(tbRegOrder.IsScan) AS tbRegOrder__IsScan__DESC' UNION ALL
    SELECT 'tbRegOrder__Comments', 'tbRegOrder.Comments AS tbRegOrder__Comments' UNION ALL
    SELECT 'tbRegOrder__RemoteAccNo', 'tbRegOrder.RemoteAccNo AS tbRegOrder__RemoteAccNo' UNION ALL
    SELECT 'tbRegOrder__TotalFee', 'tbRegOrder.TotalFee AS tbRegOrder__TotalFee' UNION ALL
    SELECT 'tbRegOrder__Optional1', 'tbRegOrder.Optional1 AS tbRegOrder__Optional1' UNION ALL
    SELECT 'tbRegOrder__Optional2', 'tbRegOrder.Optional2 AS tbRegOrder__Optional2' UNION ALL
    SELECT 'tbRegOrder__Optional3', 'tbRegOrder.Optional3 AS tbRegOrder__Optional3' UNION ALL
    SELECT 'tbRegOrder__StudyInstanceUID', 'tbRegOrder.StudyInstanceUID AS tbRegOrder__StudyInstanceUID' UNION ALL
    SELECT 'tbRegOrder__HisID', 'tbRegOrder.HisID AS tbRegOrder__HisID' UNION ALL
    SELECT 'tbRegOrder__CardNo', 'tbRegOrder.CardNo AS tbRegOrder__CardNo' UNION ALL
    SELECT 'tbRegOrder__PatientGuid', 'tbRegOrder.PatientGuid AS tbRegOrder__PatientGuid' UNION ALL
    SELECT 'tbRegOrder__InhospitalNo', 'tbRegOrder.InhospitalNo AS tbRegOrder__InhospitalNo' UNION ALL
    SELECT 'tbRegOrder__ClinicNo', 'tbRegOrder.ClinicNo AS tbRegOrder__ClinicNo' UNION ALL
    SELECT 'tbRegOrder__PatientType', 'tbRegOrder.PatientType AS tbRegOrder__PatientType' UNION ALL
    SELECT 'tbRegOrder__Observation', 'tbRegOrder.Observation AS tbRegOrder__Observation' UNION ALL
    SELECT 'tbRegOrder__HealthHistory', 'tbRegOrder.HealthHistory AS tbRegOrder__HealthHistory' UNION ALL
    SELECT 'tbRegOrder__InhospitalRegion', 'tbRegOrder.InhospitalRegion AS tbRegOrder__InhospitalRegion' UNION ALL
    SELECT 'tbRegOrder__IsEmergency', 'tbRegOrder.IsEmergency AS tbRegOrder__IsEmergency' UNION ALL
    SELECT 'tbRegOrder__IsEmergency__DESC', 'dbo.fnTranslateYesNo(tbRegOrder.IsEmergency) AS tbRegOrder__IsEmergency__DESC' UNION ALL
    SELECT 'tbRegOrder__BedNo', 'tbRegOrder.BedNo AS tbRegOrder__BedNo' UNION ALL
    SELECT 'tbRegOrder__CurrentAge', 'dbo.fnTranslateCurrentAge(tbRegOrder.CurrentAge) AS tbRegOrder__CurrentAge' UNION ALL
    SELECT 'tbRegOrder__AgeInDays', 'tbRegOrder.AgeInDays AS tbRegOrder__AgeInDays' UNION ALL
    SELECT 'tbRegOrder__visitcomment', 'tbRegOrder.visitcomment AS tbRegOrder__visitcomment' UNION ALL
    SELECT 'tbRegOrder__ChargeType', 'tbRegOrder.ChargeType AS tbRegOrder__ChargeType' UNION ALL
    SELECT 'tbRegOrder__ErethismType', 'tbRegOrder.ErethismType AS tbRegOrder__ErethismType' UNION ALL
    SELECT 'tbRegOrder__ErethismCode', 'tbRegOrder.ErethismCode AS tbRegOrder__ErethismCode' UNION ALL
    SELECT 'tbRegOrder__ErethismGrade', 'tbRegOrder.ErethismGrade AS tbRegOrder__ErethismGrade' UNION ALL
    SELECT 'tbRegOrder__Domain', 'tbRegOrder.Domain AS tbRegOrder__Domain' UNION ALL
    SELECT 'tbRegOrder__ReferralID', 'tbRegOrder.ReferralID AS tbRegOrder__ReferralID' UNION ALL
    SELECT 'tbRegOrder__IsReferral', 'tbRegOrder.IsReferral AS tbRegOrder__IsReferral' UNION ALL
    SELECT 'tbRegOrder__IsReferral__DESC', 'dbo.fnTranslateYesNo(tbRegOrder.IsReferral) AS tbRegOrder__IsReferral__DESC' UNION ALL
    SELECT 'tbRegOrder__ExamAccNo', 'tbRegOrder.ExamAccNo AS tbRegOrder__ExamAccNo' UNION ALL
    SELECT 'tbRegOrder__ExamDomain', 'tbRegOrder.ExamDomain AS tbRegOrder__ExamDomain' UNION ALL
    SELECT 'tbRegOrder__MedicalAlert', 'tbRegOrder.MedicalAlert AS tbRegOrder__MedicalAlert' UNION ALL
    SELECT 'tbRegOrder__EXAMALERT1', 'tbRegOrder.EXAMALERT1 AS tbRegOrder__EXAMALERT1' UNION ALL
    SELECT 'tbRegOrder__EXAMALERT2', 'tbRegOrder.EXAMALERT2 AS tbRegOrder__EXAMALERT2' UNION ALL
    SELECT 'tbRegOrder__LMP', 'tbRegOrder.LMP AS tbRegOrder__LMP' UNION ALL
    SELECT 'tbRegOrder__InitialDomain', 'tbRegOrder.InitialDomain AS tbRegOrder__InitialDomain' UNION ALL
    SELECT 'tbRegOrder__ERequisition', 'tbRegOrder.ERequisition AS tbRegOrder__ERequisition' UNION ALL
    SELECT 'tbRegOrder__CurPatientName', 'tbRegOrder.CurPatientName AS tbRegOrder__CurPatientName' UNION ALL
    SELECT 'tbRegOrder__CurGender', 'tbRegOrder.CurGender AS tbRegOrder__CurGender' UNION ALL
    SELECT 'tbRegOrder__Priority', 'tbRegOrder.Priority AS tbRegOrder__Priority' UNION ALL
    SELECT 'tbRegOrder__IsCharge', 'tbRegOrder.IsCharge AS tbRegOrder__IsCharge' UNION ALL
    SELECT 'tbRegOrder__Bedside', 'tbRegOrder.Bedside AS tbRegOrder__Bedside' UNION ALL
    SELECT 'tbRegOrder__IsFilmSent', 'tbRegOrder.IsFilmSent AS tbRegOrder__IsFilmSent' UNION ALL
    SELECT 'tbRegOrder__FilmSentOperator', 'tbRegOrder.FilmSentOperator AS tbRegOrder__FilmSentOperator' UNION ALL
    SELECT 'tbRegOrder__IsCharge__DESC', 'dbo.fnTranslateYesNo(tbRegOrder.IsCharge) AS tbRegOrder__IsCharge__DESC' UNION ALL
    SELECT 'tbRegOrder__Bedside__DESC', 'dbo.fnTranslateYesNo(tbRegOrder.Bedside) AS tbRegOrder__Bedside__DESC' UNION ALL
    SELECT 'tbRegOrder__IsFilmSent__DESC', 'dbo.fnTranslateYesNo(tbRegOrder.IsFilmSent) AS tbRegOrder__IsFilmSent__DESC' UNION ALL
    SELECT 'tbRegOrder__FilmSentOperator__DESC', 'dbo.fnTranslateUser(tbRegOrder.FilmSentOperator) AS tbRegOrder__FilmSentOperator__DESC' UNION ALL
    SELECT 'tbRegOrder__FilmSentDt', 'tbRegOrder.FilmSentDt AS tbRegOrder__FilmSentDt' UNION ALL
    SELECT 'tbRegOrder__BookingSite', 'tbRegOrder.BookingSite AS tbRegOrder__BookingSite' UNION ALL
    SELECT 'tbRegOrder__RegSite', 'tbRegOrder.RegSite AS tbRegOrder__RegSite' UNION ALL
    SELECT 'tbRegOrder__ExamSite', 'tbRegOrder.ExamSite AS tbRegOrder__ExamSite' UNION ALL
    SELECT 'tbRegOrder__BookingSite__DESC', 'dbo.fnTranslateSite(tbRegOrder.BookingSite) AS tbRegOrder__BookingSite__DESC' UNION ALL
    SELECT 'tbRegOrder__RegSite__DESC', 'dbo.fnTranslateSite(tbRegOrder.RegSite) AS tbRegOrder__RegSite__DESC' UNION ALL
    SELECT 'tbRegOrder__ExamSite__DESC', 'dbo.fnTranslateSite(tbRegOrder.ExamSite) AS tbRegOrder__ExamSite__DESC' UNION ALL
    SELECT 'tbRegOrder__BodyWeight', 'tbRegOrder.BodyWeight AS tbRegOrder__BodyWeight' UNION ALL
    SELECT 'tbRegOrder__FilmFee__DESC', '(case when tbRegOrder.FilmFee > 0 then ''有'' else '''' end) AS tbRegOrder__FilmFee__DESC' UNION ALL
    SELECT 'tbRegOrder__CurrentSite', 'tbRegOrder.CurrentSite AS tbRegOrder__CurrentSite' UNION ALL
    SELECT 'tbRegOrder__ThreeDRebuild', 'tbRegOrder.ThreeDRebuild AS tbRegOrder__ThreeDRebuild' UNION ALL
    SELECT 'tbRegOrder__CurrentSite__DESC', 'dbo.fnTranslateSite(tbRegOrder.CurrentSite) AS tbRegOrder__CurrentSite__DESC' UNION ALL
    SELECT 'tbRegOrder__ThreeDRebuild__DESC', 'dbo.fnTranslateYesNo(tbRegOrder.ThreeDRebuild) AS tbRegOrder__ThreeDRebuild__DESC' UNION ALL
    SELECT 'tbRegOrder__AssignDt', 'tbRegOrder.AssignDt AS tbRegOrder__AssignDt' UNION ALL
    SELECT 'tbRegOrder__Assign2Site', 'tbRegOrder.Assign2Site AS tbRegOrder__Assign2Site' UNION ALL
    SELECT 'tbRegOrder__Assign2Site__DESC', 'dbo.fnTranslateSite(tbRegOrder.Assign2Site) AS tbRegOrder__Assign2Site__DESC' UNION ALL
    SELECT 'tbRegOrder__StudyID', 'tbRegOrder.StudyID AS tbRegOrder__StudyID' UNION ALL
    SELECT 'tbRegOrder__PathologicalFindings', 'tbRegOrder.PathologicalFindings AS tbRegOrder__PathologicalFindings' UNION ALL
    SELECT 'tbRegOrder__PhysicalCompany', 'tbRegOrder.PhysicalCompany AS tbRegOrder__PhysicalCompany' UNION ALL
    SELECT 'tbRegOrder__InternalOptional1', 'tbRegOrder.InternalOptional1 AS tbRegOrder__InternalOptional1' UNION ALL
    SELECT 'tbRegOrder__InternalOptional2', 'tbRegOrder.InternalOptional2 AS tbRegOrder__InternalOptional2' UNION ALL
    SELECT 'tbRegOrder__ExternalOptional1', 'tbRegOrder.ExternalOptional1 AS tbRegOrder__ExternalOptional1' UNION ALL
    SELECT 'tbRegOrder__ExternalOptional2', 'tbRegOrder.ExternalOptional2 AS tbRegOrder__ExternalOptional2' UNION ALL
    SELECT 'tbRegOrder__ExternalOptional3', 'tbRegOrder.ExternalOptional3 AS tbRegOrder__ExternalOptional3' UNION ALL
    SELECT 'tbRegOrder__InjectDose', 'tbRegOrder.InjectDose AS tbRegOrder__InjectDose' UNION ALL
    SELECT 'tbRegOrder__InjectTime', 'tbRegOrder.InjectTime AS tbRegOrder__InjectTime' UNION ALL
    SELECT 'tbRegOrder__BodyHeight', 'tbRegOrder.BodyHeight AS tbRegOrder__BodyHeight' UNION ALL
    SELECT 'tbRegOrder__BloodSugar', 'tbRegOrder.BloodSugar AS tbRegOrder__BloodSugar' UNION ALL
    SELECT 'tbRegOrder__Insulin', 'tbRegOrder.Insulin AS tbRegOrder__Insulin' UNION ALL
    SELECT 'tbRegOrder__GoOnGoTime', 'tbRegOrder.GoOnGoTime AS tbRegOrder__GoOnGoTime' UNION ALL
    SELECT 'tbRegOrder__InjectorRemnant', 'tbRegOrder.InjectorRemnant AS tbRegOrder__InjectorRemnant' UNION ALL
    SELECT 'tbRegOrder__SubmitHospital', 'tbRegOrder.SubmitHospital AS tbRegOrder__SubmitHospital' UNION ALL
    SELECT 'tbRegOrder__SubmitDept', 'tbRegOrder.SubmitDept AS tbRegOrder__SubmitDept' UNION ALL
    SELECT 'tbRegOrder__SubmitDoctor', 'tbRegOrder.SubmitDoctor AS tbRegOrder__SubmitDoctor' UNION ALL
    SELECT 'tbRegOrder__TakeReportDate', 'tbRegOrder.TakeReportDate AS tbRegOrder__TakeReportDate' UNION ALL
    SELECT 'tbRegOrder__ExecuteDepartment', 'tbRegOrder.ExecuteDepartment AS tbRegOrder__ExecuteDepartment' UNION ALL
    SELECT 'tbRegProcedure__ProcedureGuid', 'tbRegProcedure.ProcedureGuid AS tbRegProcedure__ProcedureGuid' UNION ALL
    SELECT 'tbRegProcedure__OrderGuid', 'tbRegProcedure.OrderGuid AS tbRegProcedure__OrderGuid' UNION ALL
    SELECT 'tbRegProcedure__ProcedureCode', 'tbRegProcedure.ProcedureCode AS tbRegProcedure__ProcedureCode' UNION ALL
    SELECT 'tbRegProcedure__ExamSystem', 'tbRegProcedure.ExamSystem AS tbRegProcedure__ExamSystem' UNION ALL
    SELECT 'tbRegProcedure__WarningTime', 'tbRegProcedure.WarningTime AS tbRegProcedure__WarningTime' UNION ALL
    SELECT 'tbRegProcedure__FilmSpec', 'tbRegProcedure.FilmSpec AS tbRegProcedure__FilmSpec' UNION ALL
    SELECT 'tbRegProcedure__FilmCount', 'tbRegProcedure.FilmCount AS tbRegProcedure__FilmCount' UNION ALL
    SELECT 'tbRegProcedure__ContrastName', 'tbRegProcedure.ContrastName AS tbRegProcedure__ContrastName' UNION ALL
    SELECT 'tbRegProcedure__ContrastDose', 'tbRegProcedure.ContrastDose AS tbRegProcedure__ContrastDose' UNION ALL
    SELECT 'tbRegProcedure__ImageCount', 'tbRegProcedure.ImageCount AS tbRegProcedure__ImageCount' UNION ALL
    SELECT 'tbRegProcedure__ExposalCount', 'tbRegProcedure.ExposalCount AS tbRegProcedure__ExposalCount' UNION ALL
    SELECT 'tbRegProcedure__Deposit', 'tbRegProcedure.Deposit AS tbRegProcedure__Deposit' UNION ALL
    SELECT 'tbRegProcedure__Charge', 'tbRegProcedure.Charge AS tbRegProcedure__Charge' UNION ALL
    SELECT 'tbRegProcedure__ModalityType', 'tbRegProcedure.ModalityType AS tbRegProcedure__ModalityType' UNION ALL
    SELECT 'tbRegProcedure__Modality', 'tbRegProcedure.Modality AS tbRegProcedure__Modality' UNION ALL
    SELECT 'tbRegProcedure__Registrar', 'tbRegProcedure.Registrar AS tbRegProcedure__Registrar' UNION ALL
    SELECT 'tbRegProcedure__Registrar__DESC', 'dbo.fnTranslateUser(tbRegProcedure.Registrar) AS tbRegProcedure__Registrar__DESC' UNION ALL
    SELECT 'tbRegProcedure__RegisterDt', 'tbRegProcedure.RegisterDt AS tbRegProcedure__RegisterDt' UNION ALL
    SELECT 'tbRegProcedure__Priority', 'tbRegProcedure.Priority AS tbRegProcedure__Priority' UNION ALL
    SELECT 'tbRegProcedure__Technician', 'tbRegProcedure.Technician AS tbRegProcedure__Technician' UNION ALL
    SELECT 'tbRegProcedure__TechDoctor', 'tbRegProcedure.TechDoctor AS tbRegProcedure__TechDoctor' UNION ALL
    SELECT 'tbRegProcedure__TechNurse', 'tbRegProcedure.TechNurse AS tbRegProcedure__TechNurse' UNION ALL
    SELECT 'tbRegProcedure__Technician__DESC', 'dbo.fnTranslateUser(tbRegProcedure.Technician) AS tbRegProcedure__Technician__DESC' UNION ALL
    SELECT 'tbRegProcedure__TechDoctor__DESC', 'dbo.fnTranslateUser(tbRegProcedure.TechDoctor) AS tbRegProcedure__TechDoctor__DESC' UNION ALL
    SELECT 'tbRegProcedure__TechNurse__DESC', 'dbo.fnTranslateUser(tbRegProcedure.TechNurse) AS tbRegProcedure__TechNurse__DESC' UNION ALL
    SELECT 'tbRegProcedure__OperationStep', 'tbRegProcedure.OperationStep AS tbRegProcedure__OperationStep' UNION ALL
    SELECT 'tbRegProcedure__ExamineDt', 'tbRegProcedure.ExamineDt AS tbRegProcedure__ExamineDt' UNION ALL
    SELECT 'tbRegProcedure__Mender', 'tbRegProcedure.Mender AS tbRegProcedure__Mender' UNION ALL
    SELECT 'tbRegProcedure__Mender__DESC', 'dbo.fnTranslateUser(tbRegProcedure.Mender) AS tbRegProcedure__Mender__DESC' UNION ALL
    SELECT 'tbRegProcedure__ModifyDt', 'tbRegProcedure.ModifyDt AS tbRegProcedure__ModifyDt' UNION ALL
    SELECT 'tbRegProcedure__IsPost', 'tbRegProcedure.IsPost AS tbRegProcedure__IsPost' UNION ALL
    SELECT 'tbRegProcedure__IsExistImage', 'tbRegProcedure.IsExistImage AS tbRegProcedure__IsExistImage' UNION ALL
    SELECT 'tbRegProcedure__Status', 'tbRegProcedure.Status AS tbRegProcedure__Status' UNION ALL
    SELECT 'tbRegProcedure__IsPost__DESC', 'dbo.fnTranslateYesNo(tbRegProcedure.IsPost) AS tbRegProcedure__IsPost__DESC' UNION ALL
    SELECT 'tbRegProcedure__IsExistImage__DESC', 'dbo.fnTranslateYesNo(tbRegProcedure.IsExistImage) AS tbRegProcedure__IsExistImage__DESC' UNION ALL
    SELECT 'tbRegProcedure__Status__DESC', 'dbo.fnTranslateDictionaryValue(13, tbRegProcedure.Status) AS tbRegProcedure__Status__DESC' UNION ALL
    SELECT 'tbRegProcedure__Comments', 'tbRegProcedure.Comments AS tbRegProcedure__Comments' UNION ALL
    SELECT 'tbRegProcedure__BookingBeginDt', 'tbRegProcedure.BookingBeginDt AS tbRegProcedure__BookingBeginDt' UNION ALL
    SELECT 'tbRegProcedure__BookingEndDt', 'tbRegProcedure.BookingEndDt AS tbRegProcedure__BookingEndDt' UNION ALL
    SELECT 'tbRegProcedure__Booker', 'tbRegProcedure.Booker AS tbRegProcedure__Booker' UNION ALL
    SELECT 'tbRegProcedure__IsCharge', 'tbRegProcedure.IsCharge AS tbRegProcedure__IsCharge' UNION ALL
    SELECT 'tbRegProcedure__Booker__DESC', 'dbo.fnTranslateUser(tbRegProcedure.Booker) AS tbRegProcedure__Booker__DESC' UNION ALL
    SELECT 'tbRegProcedure__IsCharge__DESC', 'dbo.fnTranslateUser(tbRegProcedure.IsCharge) AS tbRegProcedure__IsCharge__DESC' UNION ALL
    SELECT 'tbRegProcedure__RemoteRPID', 'tbRegProcedure.RemoteRPID AS tbRegProcedure__RemoteRPID' UNION ALL
    SELECT 'tbRegProcedure__Optional1', 'tbRegProcedure.Optional1 AS tbRegProcedure__Optional1' UNION ALL
    SELECT 'tbRegProcedure__Optional2', 'tbRegProcedure.Optional2 AS tbRegProcedure__Optional2' UNION ALL
    SELECT 'tbRegProcedure__Optional3', 'tbRegProcedure.Optional3 AS tbRegProcedure__Optional3' UNION ALL
    SELECT 'tbRegProcedure__QueueNo', 'tbRegProcedure.QueueNo AS tbRegProcedure__QueueNo' UNION ALL
    SELECT 'tbRegProcedure__BookingTimeAlias', 'tbRegProcedure.BookingTimeAlias AS tbRegProcedure__BookingTimeAlias' UNION ALL
    SELECT 'tbRegProcedure__CreateDt', 'tbRegProcedure.CreateDt AS tbRegProcedure__CreateDt' UNION ALL
    SELECT 'tbRegProcedure__ReportGuid', 'tbRegProcedure.ReportGuid AS tbRegProcedure__ReportGuid' UNION ALL
    SELECT 'tbRegProcedure__MedicineUsage', 'tbRegProcedure.MedicineUsage AS tbRegProcedure__MedicineUsage' UNION ALL
    SELECT 'tbRegProcedure__Posture', 'tbRegProcedure.Posture AS tbRegProcedure__Posture' UNION ALL
    SELECT 'tbRegProcedure__Technician1', 'tbRegProcedure.Technician1 AS tbRegProcedure__Technician1' UNION ALL
    SELECT 'tbRegProcedure__Technician2', 'tbRegProcedure.Technician2 AS tbRegProcedure__Technician2' UNION ALL
    SELECT 'tbRegProcedure__Technician3', 'tbRegProcedure.Technician3 AS tbRegProcedure__Technician3' UNION ALL
    SELECT 'tbRegProcedure__Technician4', 'tbRegProcedure.Technician4 AS tbRegProcedure__Technician4' UNION ALL
    SELECT 'tbRegProcedure__Technician1__DESC', 'dbo.fnTranslateUser(tbRegProcedure.Technician1) AS tbRegProcedure__Technician1__DESC' UNION ALL
    SELECT 'tbRegProcedure__Technician2__DESC', 'dbo.fnTranslateUser(tbRegProcedure.Technician2) AS tbRegProcedure__Technician2__DESC' UNION ALL
    SELECT 'tbRegProcedure__Technician3__DESC', 'dbo.fnTranslateUser(tbRegProcedure.Technician3) AS tbRegProcedure__Technician3__DESC' UNION ALL
    SELECT 'tbRegProcedure__Technician4__DESC', 'dbo.fnTranslateUser(tbRegProcedure.Technician4) AS tbRegProcedure__Technician4__DESC' UNION ALL
    SELECT 'tbRegProcedure__Domain', 'tbRegProcedure.Domain AS tbRegProcedure__Domain' UNION ALL
    SELECT 'tbRegProcedure__UnwrittenPreviousOwner', 'tbRegProcedure.UnwrittenPreviousOwner AS tbRegProcedure__UnwrittenPreviousOwner' UNION ALL
    SELECT 'tbRegProcedure__UnwrittenCurrentOwner', 'tbRegProcedure.UnwrittenCurrentOwner AS tbRegProcedure__UnwrittenCurrentOwner' UNION ALL
    SELECT 'tbRegProcedure__UnwrittenPreviousOwner__DESC', 'dbo.fnTranslateUser(tbRegProcedure.UnwrittenPreviousOwner) AS tbRegProcedure__UnwrittenPreviousOwner__DESC' UNION ALL
    SELECT 'tbRegProcedure__UnwrittenCurrentOwner__DESC', 'dbo.fnTranslateUser(tbRegProcedure.UnwrittenCurrentOwner) AS tbRegProcedure__UnwrittenCurrentOwner__DESC' UNION ALL
    SELECT 'tbRegProcedure__UnwrittenAssignDate', 'tbRegProcedure.UnwrittenAssignDate AS tbRegProcedure__UnwrittenAssignDate' UNION ALL
    SELECT 'tbRegProcedure__UnapprovedCurrentOwner', 'tbRegProcedure.UnapprovedCurrentOwner AS tbRegProcedure__UnapprovedCurrentOwner' UNION ALL
    SELECT 'tbRegProcedure__UnapprovedPreviousOwner', 'tbRegProcedure.UnapprovedPreviousOwner AS tbRegProcedure__UnapprovedPreviousOwner' UNION ALL
    SELECT 'tbRegProcedure__UnapprovedCurrentOwner__DESC', 'dbo.fnTranslateUser(tbRegProcedure.UnapprovedCurrentOwner) AS tbRegProcedure__UnapprovedCurrentOwner__DESC' UNION ALL
    SELECT 'tbRegProcedure__UnapprovedPreviousOwner__DESC', 'dbo.fnTranslateUser(tbRegProcedure.UnapprovedPreviousOwner) AS tbRegProcedure__UnapprovedPreviousOwner__DESC' UNION ALL
    SELECT 'tbRegProcedure__UnapprovedAssignDate', 'tbRegProcedure.UnapprovedAssignDate AS tbRegProcedure__UnapprovedAssignDate' UNION ALL
    SELECT 'tbRegProcedure__PreStatus', 'tbRegProcedure.PreStatus AS tbRegProcedure__PreStatus' UNION ALL
    SELECT 'tbRegProcedure__BookerName', 'tbRegProcedure.BookerName AS tbRegProcedure__BookerName' UNION ALL
    SELECT 'tbRegProcedure__RegistrarName', 'tbRegProcedure.RegistrarName AS tbRegProcedure__RegistrarName' UNION ALL
    SELECT 'tbRegProcedure__TechnicianName', 'tbRegProcedure.TechnicianName AS tbRegProcedure__TechnicianName' UNION ALL
    SELECT 'tbRegProcedure__BodyCategory', 'tbRegProcedure.BodyCategory AS tbRegProcedure__BodyCategory' UNION ALL
    SELECT 'tbRegProcedure__Bodypart', 'tbRegProcedure.Bodypart AS tbRegProcedure__Bodypart' UNION ALL
    SELECT 'tbRegProcedure__CheckingItem', 'tbRegProcedure.CheckingItem AS tbRegProcedure__CheckingItem' UNION ALL
    SELECT 'tbRegProcedure__RPDesc', 'tbRegProcedure.RPDesc AS tbRegProcedure__RPDesc' UNION ALL
    SELECT 'tbReport__ReportGuid', 'tbReport.ReportGuid AS tbReport__ReportGuid' UNION ALL
    SELECT 'tbReport__ReportName', 'tbReport.ReportName AS tbReport__ReportName' UNION ALL
    SELECT 'tbReport__ReportText', 'tbReport.ReportText AS tbReport__ReportText' UNION ALL
    SELECT 'tbReport__DoctorAdvice', 'tbReport.DoctorAdvice AS tbReport__DoctorAdvice' UNION ALL
    SELECT 'tbReport__IsPositive', 'tbReport.IsPositive AS tbReport__IsPositive' UNION ALL
    SELECT 'tbReport__IsPositive__DESC', 'dbo.fnTranslateDictionaryValue(21, tbReport.IsPositive) AS tbReport__IsPositive__DESC' UNION ALL
    SELECT 'tbReport__AcrCode', 'tbReport.AcrCode AS tbReport__AcrCode' UNION ALL
    SELECT 'tbReport__AcrAnatomic', 'tbReport.AcrAnatomic AS tbReport__AcrAnatomic' UNION ALL
    SELECT 'tbReport__AcrPathologic', 'tbReport.AcrPathologic AS tbReport__AcrPathologic' UNION ALL
    SELECT 'tbReport__Creater', 'tbReport.Creater AS tbReport__Creater' UNION ALL
    SELECT 'tbReport__Creater__DESC', 'dbo.fnTranslateUser(tbReport.Creater) AS tbReport__Creater__DESC' UNION ALL
    SELECT 'tbReport__CreateDt', 'tbReport.CreateDt AS tbReport__CreateDt' UNION ALL
    SELECT 'tbReport__Submitter', 'tbReport.Submitter AS tbReport__Submitter' UNION ALL
    SELECT 'tbReport__Submitter__DESC', 'dbo.fnTranslateUser(tbReport.Submitter) AS tbReport__Submitter__DESC' UNION ALL
    SELECT 'tbReport__SubmitDt', 'tbReport.SubmitDt AS tbReport__SubmitDt' UNION ALL
    SELECT 'tbReport__FirstApprover', 'tbReport.FirstApprover AS tbReport__FirstApprover' UNION ALL
    SELECT 'tbReport__FirstApprover__DESC', '(case when firstApproverName<>'''' then firstApproverName else dbo.fnTranslateUser(tbReport.firstApprover) END) AS tbReport__FirstApprover__DESC' UNION ALL
    SELECT 'tbReport__FirstApproveDt', 'tbReport.FirstApproveDt AS tbReport__FirstApproveDt' UNION ALL
    SELECT 'tbReport__SecondApprover', 'tbReport.SecondApprover AS tbReport__SecondApprover' UNION ALL
    SELECT 'tbReport__SecondApprover__DESC', 'dbo.fnTranslateUser(tbReport.SecondApprover) AS tbReport__SecondApprover__DESC' UNION ALL
    SELECT 'tbReport__SecondApproveDt', 'tbReport.SecondApproveDt AS tbReport__SecondApproveDt' UNION ALL
    SELECT 'tbReport__IsDiagnosisRight', 'tbReport.IsDiagnosisRight AS tbReport__IsDiagnosisRight' UNION ALL
    SELECT 'tbReport__KeyWord', 'tbReport.KeyWord AS tbReport__KeyWord' UNION ALL
    SELECT 'tbReport__ReportQuality', 'tbReport.ReportQuality AS tbReport__ReportQuality' UNION ALL
    SELECT 'tbReport__RejectToObject', 'tbReport.RejectToObject AS tbReport__RejectToObject' UNION ALL
    SELECT 'tbReport__Rejecter', 'tbReport.Rejecter AS tbReport__Rejecter' UNION ALL
    SELECT 'tbReport__RejectToObject__DESC', 'dbo.fnTranslateUser(tbReport.RejectToObject) AS tbReport__RejectToObject__DESC' UNION ALL
    SELECT 'tbReport__Rejecter__DESC', 'dbo.fnTranslateUser(tbReport.Rejecter) AS tbReport__Rejecter__DESC' UNION ALL
    SELECT 'tbReport__RejectDt', 'tbReport.RejectDt AS tbReport__RejectDt' UNION ALL
    SELECT 'tbReport__Status', 'tbReport.Status AS tbReport__Status' UNION ALL
    SELECT 'tbReport__Comments', 'tbReport.Comments AS tbReport__Comments' UNION ALL
    SELECT 'tbReport__DeleteMark', 'tbReport.DeleteMark AS tbReport__DeleteMark' UNION ALL
    SELECT 'tbReport__Deleter', 'tbReport.Deleter AS tbReport__Deleter' UNION ALL
    SELECT 'tbReport__Deleter__DESC', 'dbo.fnTranslateUser(tbReport.Deleter) AS tbReport__Deleter__DESC' UNION ALL
    SELECT 'tbReport__DeleteDt', 'tbReport.DeleteDt AS tbReport__DeleteDt' UNION ALL
    SELECT 'tbReport__Recuperator', 'tbReport.Recuperator AS tbReport__Recuperator' UNION ALL
    SELECT 'tbReport__Recuperator__DESC', 'dbo.fnTranslateUser(tbReport.Recuperator) AS tbReport__Recuperator__DESC' UNION ALL
    SELECT 'tbReport__ReconvertDt', 'tbReport.ReconvertDt AS tbReport__ReconvertDt' UNION ALL
    SELECT 'tbReport__Mender', 'tbReport.Mender AS tbReport__Mender' UNION ALL
    SELECT 'tbReport__Mender__DESC', '(case when menderName<>'''' then menderName else dbo.fnTranslateUser(tbReport.mender) END) AS tbReport__Mender__DESC' UNION ALL
    SELECT 'tbReport__ModifyDt', 'tbReport.ModifyDt AS tbReport__ModifyDt' UNION ALL
    SELECT 'tbReport__IsPrint', 'tbReport.IsPrint AS tbReport__IsPrint' UNION ALL
    SELECT 'tbReport__IsPrint__DESC', 'dbo.fnTranslateYesNo(tbReport.IsPrint) AS tbReport__IsPrint__DESC' UNION ALL
    SELECT 'tbReport__CheckItemName', 'tbReport.CheckItemName AS tbReport__CheckItemName' UNION ALL
    SELECT 'tbReport__Optional1', 'tbReport.Optional1 AS tbReport__Optional1' UNION ALL
    SELECT 'tbReport__Optional2', 'tbReport.Optional2 AS tbReport__Optional2' UNION ALL
    SELECT 'tbReport__Optional3', 'tbReport.Optional3 AS tbReport__Optional3' UNION ALL
    SELECT 'tbReport__IsLeaveWord', 'tbReport.IsLeaveWord AS tbReport__IsLeaveWord' UNION ALL
    SELECT 'tbReport__IsLeaveWord__DESC', 'dbo.fnTranslateYesNo(tbReport.IsLeaveWord) AS tbReport__IsLeaveWord__DESC' UNION ALL
    SELECT 'tbReport__WYSText', 'tbReport.WYSText AS tbReport__WYSText' UNION ALL
    SELECT 'tbReport__WYGText', 'tbReport.WYGText AS tbReport__WYGText' UNION ALL
    SELECT 'tbReport__IsDraw', 'tbReport.IsDraw AS tbReport__IsDraw' UNION ALL
    SELECT 'tbReport__IsDraw__DESC', 'dbo.fnTranslateYesNo(tbReport.IsDraw) AS tbReport__IsDraw__DESC' UNION ALL
    SELECT 'tbReport__DrawTime', 'tbReport.DrawTime AS tbReport__DrawTime' UNION ALL
    SELECT 'tbReport__IsLeaveSound', 'tbReport.IsLeaveSound AS tbReport__IsLeaveSound' UNION ALL
    SELECT 'tbReport__IsLeaveSound__DESC', 'dbo.fnTranslateYesNo(tbReport.IsLeaveSound) AS tbReport__IsLeaveSound__DESC' UNION ALL
    SELECT 'tbReport__TakeFilmDept', 'tbReport.TakeFilmDept AS tbReport__TakeFilmDept' UNION ALL
    SELECT 'tbReport__TakeFilmRegion', 'tbReport.TakeFilmRegion AS tbReport__TakeFilmRegion' UNION ALL
    SELECT 'tbReport__TakeFilmComment', 'tbReport.TakeFilmComment AS tbReport__TakeFilmComment' UNION ALL
    SELECT 'tbReport__PrintCopies', 'tbReport.PrintCopies AS tbReport__PrintCopies' UNION ALL
    SELECT 'tbReport__PrintTemplateGuid', 'tbReport.PrintTemplateGuid AS tbReport__PrintTemplateGuid' UNION ALL
    SELECT 'tbReport__Domain', 'tbReport.Domain AS tbReport__Domain' UNION ALL
    SELECT 'tbReport__ReadOnly', 'tbReport.ReadOnly AS tbReport__ReadOnly' UNION ALL
    SELECT 'tbReport__SubmitDomain', 'tbReport.SubmitDomain AS tbReport__SubmitDomain' UNION ALL
    SELECT 'tbReport__RejectDomain', 'tbReport.RejectDomain AS tbReport__RejectDomain' UNION ALL
    SELECT 'tbReport__FirstApproveDomain', 'tbReport.FirstApproveDomain AS tbReport__FirstApproveDomain' UNION ALL
    SELECT 'tbReport__SecondApproveDomain', 'tbReport.SecondApproveDomain AS tbReport__SecondApproveDomain' UNION ALL
    SELECT 'tbReport__RejectSite', 'tbReport.RejectSite AS tbReport__RejectSite' UNION ALL
    SELECT 'tbReport__SubmitSite', 'tbReport.SubmitSite AS tbReport__SubmitSite' UNION ALL
    SELECT 'tbReport__FirstApproveSite', 'tbReport.FirstApproveSite AS tbReport__FirstApproveSite' UNION ALL
    SELECT 'tbReport__SecondApproveSite', 'tbReport.SecondApproveSite AS tbReport__SecondApproveSite' UNION ALL
    SELECT 'tbReport__RejectSite__DESC', 'dbo.fnTranslateSite(tbReport.RejectSite) AS tbReport__RejectSite__DESC' UNION ALL
    SELECT 'tbReport__SubmitSite__DESC', 'dbo.fnTranslateSite(tbReport.SubmitSite) AS tbReport__SubmitSite__DESC' UNION ALL
    SELECT 'tbReport__FirstApproveSite__DESC', 'dbo.fnTranslateSite(tbReport.FirstApproveSite) AS tbReport__FirstApproveSite__DESC' UNION ALL
    SELECT 'tbReport__SecondApproveSite__DESC', 'dbo.fnTranslateSite(tbReport.SecondApproveSite) AS tbReport__SecondApproveSite__DESC' UNION ALL
    SELECT 'tbReport__RebuildMark', 'tbReport.RebuildMark AS tbReport__RebuildMark' UNION ALL
    SELECT 'tbReport__ReportQuality2', 'tbReport.ReportQuality2 AS tbReport__ReportQuality2' UNION ALL
    SELECT 'tbReport__SubmitterName', 'dbo.fnTranslateIntern(tbReport.SubmitterName,tbReport.Submitter) AS tbReport__SubmitterName' UNION ALL
    SELECT 'tbReport__FirstApproverName', 'tbReport.FirstApproverName AS tbReport__FirstApproverName' UNION ALL
    SELECT 'tbReport__SecondApproverName', 'tbReport.SecondApproverName AS tbReport__SecondApproverName' UNION ALL
    SELECT 'tbReport__ReportQualityComments', 'tbReport.ReportQualityComments AS tbReport__ReportQualityComments' UNION ALL
    SELECT 'tbReport__CreaterName', 'dbo.fnTranslateIntern(tbReport.CreaterName,tbReport.Creater) AS tbReport__CreaterName' UNION ALL
    SELECT 'tbReport__MenderName', 'tbReport.MenderName AS tbReport__MenderName' UNION ALL
    SELECT 'tbReport__IsModified', 'tbReport.IsModified AS tbReport__IsModified' UNION ALL
    SELECT 'tbReport__IsModified__DESC', 'dbo.fnTranslateYesNoEmpty(tbReport.IsModified) AS tbReport__IsModified__DESC' UNION ALL
    SELECT 'tbReport__TechInfo', 'tbReport.TechInfo AS tbReport__TechInfo' UNION ALL
    SELECT 'tbProcedureCode__RadiologistWeight', '(select RadiologistWeight from tbProcedureCode where ProcedureCode=tbRegProcedure.ProcedureCode) AS tbProcedureCode__RadiologistWeight' UNION ALL
    SELECT 'tbProcedureCode__ApprovedRadiologistWeight', '(select ApprovedRadiologistWeight from tbProcedureCode where ProcedureCode=tbRegProcedure.ProcedureCode) AS tbProcedureCode__ApprovedRadiologistWeight' UNION ALL
    SELECT 'tbModality__Room', '(select top 1 tbModality.Room from tbModality where tbRegProcedure.Modality=tbModality.Modality ) AS tbModality__Room' UNION ALL
    SELECT 'tbConsultation__cstStatus__DESC', '(select top 1 dbo.fnTranslateDictionaryValue(160, cstStatus) from tbConsultation where cstOrderGuid=tbRegOrder.OrderGuid Order By cstApplyTime DESC) AS tbConsultation__cstStatus__DESC' UNION ALL
    SELECT 'tbReferralList__RefStatus__DESC', '(select top 1 dbo.fnTranslateDictionaryValue(223, RefStatus) from tbReferralList where referralid=tbRegOrder.referralid) AS tbReferralList__RefStatus__DESC' UNION ALL
    SELECT 'tbRegPatient__IsAllergic', 'tbRegPatient.IsAllergic AS tbRegPatient__IsAllergic' UNION ALL
    SELECT 'tbRegPatient__IsAllergic__DESC', 'dbo.fnTranslateYesNo(tbRegPatient.IsAllergic) AS tbRegPatient__IsAllergic__DESC'
)

SELECT @totalColumns = REPLACE(REPLACE(STUFF((
    SELECT ', ' + SqlText FROM Mapping m WHERE EXISTS (SELECT 1 FROM ColList c WHERE LTRIM(RTRIM(c.ColName)) = m.ColName) FOR XML PATH('')
), 1, 2, ''), '&lt;', '<'), '&gt;', '>')

if @Columns = '' set @Columns='*'

declare @sql nvarchar(MAX)

/*
set @sql = ' select * from( select ROW_NUMBER() Over('+@rowNumOrderBy+') as rowNum,' +@Columns
 +' from ('
 +'select top '+ STR(@topcount) +' '+@totalColumns
 +' FROM tbRegPatient with(nolock), tbRegOrder with(nolock), tbRegProcedure with(nolock)'
 +'  LEFT JOIN tbReport with(nolock) on tbReport.reportguid=tbRegProcedure.reportguid '
 +' where tbRegPatient.PatientGuid=tbRegOrder.PatientGuid AND tbRegOrder.OrderGuid=tbRegProcedure.OrderGuid'
 +'  AND ' + @Conditions + ' ' + @OrderBy 
 +' UNION ALL '
 +'select top '+ STR(@topcount) +' '+@totalColumns
 +' FROM RISArchive..tbRegPatient tbRegPatient with(nolock), RISArchive..tbRegOrder tbRegOrder with(nolock), RISArchive..tbRegProcedure tbRegProcedure with(nolock)'
 +'  LEFT JOIN RISArchive..tbReport tbReport with(nolock) on tbReport.reportguid=tbRegProcedure.reportguid '
 +' where tbRegPatient.PatientGuid=tbRegOrder.PatientGuid AND tbRegOrder.OrderGuid=tbRegProcedure.OrderGuid'
 +'  AND  tbRegProcedure.Status>=0 AND ' + @Conditions + ' ' + @OrderBy 
 +') table1)tale2  where tale2.rowNum between '+cast(@minrowcount as varchar(18)) +' and '+cast(@maxrowcount as varchar(18))
*/
--set @sql = ' select * from( select ROW_NUMBER() Over('+@rowNumOrderBy+') as rowNum,* '
-- +' from ('
-- +'select '+@totalColumns
-- +' FROM tbRegPatient with(nolock), tbRegOrder with(nolock), tbRegProcedure with(nolock)'
-- +'  LEFT JOIN tbReport with(nolock) on tbReport.reportguid=tbRegProcedure.reportguid '
-- +' where tbRegPatient.PatientGuid=tbRegOrder.PatientGuid AND tbRegOrder.OrderGuid=tbRegProcedure.OrderGuid'
-- +'  AND ' + @Conditions 
-- +' UNION ALL '
-- +'select '+@totalColumns
-- +' FROM RISArchive..tbRegPatient tbRegPatient with(nolock), RISArchive..tbRegOrder tbRegOrder with(nolock), RISArchive..tbRegProcedure tbRegProcedure with(nolock)'
-- +'  LEFT JOIN RISArchive..tbReport tbReport with(nolock) on tbReport.reportguid=tbRegProcedure.reportguid '
-- +' where tbRegPatient.PatientGuid=tbRegOrder.PatientGuid AND tbRegOrder.OrderGuid=tbRegProcedure.OrderGuid'
-- +'  AND  tbRegProcedure.Status>=0 AND ' + @Conditions 
-- +') table1)tale2  where tale2.rowNum between '+cast(@minrowcount as varchar(18)) +' and '+cast(@maxrowcount as varchar(18))+' '+ @OrderBy

SET @sql = '
;WITH Part1 AS (
    SELECT TOP '+cast(@maxrowcount as varchar(18)) + '
        ' + @totalColumns + '
        FROM tbRegPatient WITH (NOLOCK)
        JOIN tbRegOrder WITH (NOLOCK) ON tbRegOrder.PatientGuid = tbRegPatient.PatientGuid
        JOIN tbRegProcedure WITH (NOLOCK) ON tbRegProcedure.OrderGuid = tbRegOrder.OrderGuid
        LEFT JOIN tbReport WITH (NOLOCK) ON tbReport.ReportGuid = tbRegProcedure.ReportGuid
        WHERE tbRegProcedure.Status>=0 AND ' + @Conditions + '
        ' + @OrderBy + '
    UNION ALL
    SELECT TOP '+cast(@maxrowcount as varchar(18)) + '
        ' + @totalColumns + '
        FROM RISArchive..tbRegPatient WITH (NOLOCK)
        JOIN RISArchive..tbRegOrder WITH (NOLOCK) ON tbRegOrder.PatientGuid = tbRegPatient.PatientGuid
        JOIN RISArchive..tbRegProcedure WITH (NOLOCK) ON tbRegProcedure.OrderGuid = tbRegOrder.OrderGuid
        LEFT JOIN RISArchive..tbReport WITH (NOLOCK) ON tbReport.ReportGuid = tbRegProcedure.ReportGuid
        WHERE tbRegProcedure.Status>=0 AND ' + @Conditions + '
        ' + @OrderBy + '
), Page AS (
    SELECT TOP '+cast(@maxrowcount as varchar(18)) +'
        ROW_NUMBER() Over(' + @rowNumOrderBy + ') as rowNum, *
        FROM Part1 WITH (NOLOCK)
        ' + @rowNumOrderBy + '
)
SELECT * FROM Page WITH (NOLOCK) WHERE Page.rowNum between '+cast(@minrowcount as varchar(18)) +' and '+cast(@maxrowcount as varchar(18))

--exec procLongPrint @sql

EXEC(@sql)

END


GO
/****** Object:  StoredProcedure [dbo].[procBookingCycle]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[procBookingCycle]
	@ByOrder varchar(8),
    @Where varchar(512),
	@SQL   varchar(1024)
AS 
BEGIN
SET NOCOUNT ON;
DECLARE @strSQL VARCHAR(8000)
CREATE TABLE #bookingcyclettemp 
(	
    AccNo  varchar(128),
    BookingBeginDt datetime  NULL
    
)

if(@ByOrder='Y')
BEGIN
	SET @strSQL='INSERT INTO #bookingcyclettemp SELECT distinct tbRegOrder.AccNo,tbRegProcedure.BookingBeginDt from tbRegOrder,tbRegProcedure where tbRegOrder.OrderGuid=tbRegProcedure.OrderGuid and '+@Where
END
ELSE
BEGIN
	SET @strSQL='INSERT INTO #bookingcyclettemp SELECT tbRegOrder.AccNo,tbRegProcedure.BookingBeginDt from tbRegOrder,tbRegProcedure where tbRegOrder.OrderGuid=tbRegProcedure.OrderGuid and '+@Where
END                    
EXEC(@strSQL)
EXEC(@SQL)
END 


GO
/****** Object:  StoredProcedure [dbo].[procBookingPolicyChecking]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procBookingPolicyChecking] 

	@Key nvarchar(64),---Key，可以是PatientID,IdentityNo,MedicalNo,SocialSecurityNo,HisID,RemotePID 中之一
	@Value nvarchar(64),    
	@Modality nvarchar(64),--设备类型
	@Facility nvarchar(64),--设备名称
	@ProcedureCode nvarchar(64),--检查代码
	@CheckingItem nvarchar(64),--检查部位
	@ScheduledStartTime datetime ,
	@ScheduledEndTime datetime ,
	@Result int output,---0  没有冲突  1 有冲突
	@ErrorMessage nvarchar(256) output--- 冲突原因
	AS
	BEGIN
	SET NOCOUNT ON;
	SET @Result=0;
	SET @ErrorMessage='';


	END


GO
/****** Object:  StoredProcedure [dbo].[procChargeMonthForRadiologist]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procChargeMonthForRadiologist]
 -- Add the parameters for the stored procedure here
    @Role varchar(32),
    @DateTime varchar(512),
          @ModalityType varchar(1024),
          @BodyPart varchar(8000),
          @Staff varchar(8000),
     @strSQL varchar(8000)
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;

    -- Insert statements for procedure here
DECLARE @szSQL varchar(8000)
DECLARE @szReqDt varchar(128)
  set @szReqDt = substring(@DateTime,charindex('.',@DateTime)+1,(charindex(')',@DateTime) - charindex('.',@DateTime)-1) )

  set @szSQL='SELECT   '+@Role
      +' rp.Modality,pc.ModalityType,pc.BodyPart,pc.Description ProcedureCode,rp.Charge,DATEPART(YYYY, tbReport.'+@szReqDt+') as Year,DATEPART(MM, tbReport.'+@szReqDt+') as Month, DATEPART(DD, tbReport.'+@szReqDt
   +') AS Day '
         +' FROM '
   +' tbReport INNER JOIN tbRegProcedure AS rp ON tbReport.ReportGuid = rp.ReportGuid INNER JOIN '  
   +' tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode WHERE 1=1 AND '
 if (@DateTime<>'')
  set @szSQL=@szSQL+@DateTime

 EXEC(@szSQL+' '+@Staff+' '+@ModalityType+' '+@BodyPart+' '+@strSQL)
END 


GO
/****** Object:  StoredProcedure [dbo].[procChargeMonthForRegistrar]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procChargeMonthForRegistrar]
 -- Add the parameters for the stored procedure here
   @Year varchar(16),
   @Month varchar(16),
   @Role varchar(32),
   @ModalityType varchar(1024),
   @BodyPart varchar(8000),
   @Staff varchar(8000),
    @strSQL varchar(8000)
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;

    -- Insert statements for procedure here
  DECLARE @szSQL varchar(8000)
  set @szSQL='SELECT   '+@Role+
    ' rp.Modality,pc.ModalityType,rp.Charge,pc.BodyPart,pc.Description ProcedureCode,DATEPART(YYYY,ro.CreateDt) AS Year,DATEPART(MM,ro.CreateDt) AS Month,DATEPART(DD,ro.CreateDt) AS Day 
     FROM  tbRegOrder as Ro INNER JOIN 
                   tbRegProcedure AS rp ON ro.OrderGuid = rp.OrderGuid INNER JOIN 
                   tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode
                    WHERE (rp.Status>=20) and    (DATEPART(YY, Ro.CreateDt) = '+@Year+') AND (DATEPART(MM, Ro.CreateDt) = '+@Month+') '

      EXEC(@szSQL+' '+@Staff+' '+@ModalityType+@BodyPart+@strSQL)
END


GO
/****** Object:  StoredProcedure [dbo].[procChargeMonthForTechnician]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procChargeMonthForTechnician]
 -- Add the parameters for the stored procedure here
   @Year varchar(16),
   @Month varchar(16),
   @Role varchar(32),
   @ModalityType varchar(1024),
   @BodyPart varchar(8000),
   @Staff varchar(8000),
    @strSQL varchar(8000)
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;

    -- Insert statements for procedure here
  DECLARE @szSQL varchar(8000)
     Set @szSQL= 'SELECT '+@Role + ' rp.Modality,pc.ModalityType,rp.Charge,pc.BodyPart,pc.Description ProcedureCode,DATEPART(YYYY,rp.ExamineDt) AS Year,DATEPART(MM,rp.ExamineDt) AS Month,DATEPART(DD,rp.ExamineDt) AS Day
                  FROM tbRegProcedure AS rp INNER JOIN
                     tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode
                  WHERE (rp.Status>=50) and (DATEPART(YY, rp.ExamineDt) = '+@Year+') AND (DATEPART(MM, rp.ExamineDt) = '+@Month+') '
       
      EXEC(@szSQL+' '+@Staff+' '+@ModalityType+' '+@BodyPart+' '+@strSQL)
END


GO
/****** Object:  StoredProcedure [dbo].[procChargeTimeSliceForRadiologist]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procChargeTimeSliceForRadiologist]
-- Add the parameters for the stored procedure here
		  @DateTime varchar(1024),
          @ModalityType varchar(1024),
          @Role varchar(32),
	      @BodyPart varchar(8000),
	 	  @Staff varchar(8000),
	 	  @strSQL varchar(8000)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	 DECLARE @szSQL varchar(8000)

     set @szSQL='SELECT '+@Role+'  rp.Modality,rp.Charge,pc.ModalityType,pc.BodyPart, pc.Description ProcedureCode '
         +' FROM   '
		 +' tbReport INNER JOIN '
		 +' tbRegProcedure AS rp INNER JOIN '
		 +' tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode ON tbReport.ReportGuid = rp.ReportGuid WHERE  1=1 and  '
		 +@DateTime

	EXEC(@szSQL+' '+@ModalityType+' '+@BodyPart+' '+@Staff+' '+@strSQL)
END


GO
/****** Object:  StoredProcedure [dbo].[procChargeTimeSliceForRegistrar]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procChargeTimeSliceForRegistrar]
	@DateTime varchar(1024),
	@Staff varchar(8000),
	@ModalityType varchar(1024),
	@Role varchar (32),
	@BodyPart varchar(8000),
	@strSQL varchar(8000)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @szSQL varchar(8000)
	set @szSQL='SELECT '+ @Role +'  rp.Modality,rp.Charge,pc.ModalityType,pc.BodyPart, pc.Description ProcedureCode
				FROM tbRegOrder AS Ro INNER JOIN 
                tbRegProcedure AS rp ON Ro.OrderGuid = rp.OrderGuid INNER JOIN 
                tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode 
				WHERE (rp.Status>=20) and   '+@DateTime


		EXEC(@szSQL+' '+@ModalityType+' '+@BodyPart+' '+@Staff+' '+@strSQL)
END


GO
/****** Object:  StoredProcedure [dbo].[procChargeTimeSliceForTechnician]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procChargeTimeSliceForTechnician]
	@DateTime varchar(1024),
	@ModalityType varchar(1024),
	@Role varchar(32),
	@BodyPart varchar(8000),
	@Staff varchar(8000),
	@strSQL varchar(8000)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	 DECLARE @szSQL varchar(8000)
      Set @szSQL= 'SELECT '+@Role+ ' rp.Modality,rp.Charge,pc.ModalityType,pc.BodyPart, pc.Description ProcedureCode  '+
		' FROM tbRegProcedure AS rp INNER JOIN 
                  		 tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode 
				WHERE (rp.Status>=50) and '+@DateTime

	EXEC(@szSQL+' '+@ModalityType+' '+@BodyPart+' '+@Staff+' '+@strSQL)
END


GO
/****** Object:  StoredProcedure [dbo].[procChargeYearForRadiologist]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[procChargeYearForRadiologist]
	-- Add the parameters for the stored procedure here
	  @DateTime varchar(512),
	  @Role varchar(32),
	  @ModalityType varchar(1024),
	  @BodyPart varchar(8000),
	  @Staff varchar(8000),
 	  @strSQL varchar(8000)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
     DECLARE @szSQL varchar(8000)
	 DECLARE @szReqDt varchar(128)
	 set @szReqDt = substring(@DateTime,charindex('.',@DateTime)+1,(charindex(')',@DateTime) - charindex('.',@DateTime)-1) )

	 set @szSQL='SELECT   '
	 
     set @szSQL=@szSQL+@Role+' rp.Modality,pc.ModalityType,pc.BodyPart,pc.Description ProcedureCode,rp.Charge,  DATEPART(MM, tbReport.'+@szReqDt
		 +') AS Month '
         +' FROM  '
		 +' tbReport INNER JOIN '
		 +' tbRegProcedure AS rp INNER JOIN '
		 +' tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode ON tbReport.ReportGuid = rp.ReportGuid WHERE  1=1 and '
	
     EXEC(@szSQL+' '+@DateTime+' '+@ModalityType+' '+@Staff+' '+@BodyPart+' '+@strSQL)
END



GO
/****** Object:  StoredProcedure [dbo].[procChargeYearForRegistrar]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[procChargeYearForRegistrar]
	-- Add the parameters for the stored procedure here
	  @Year varchar(16),
	  @ModalityType varchar(1024),
	  @Role varchar (32),
	  @BodyPart varchar(8000),
	  @Staff varchar(8000),
 	  @strSQL varchar(8000)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	 DECLARE @szSQL varchar(8000)
      Set @szSQL= 'SELECT '+@Role+' rp.Modality,pc.ModalityType,pc.BodyPart,pc.Description ProcedureCode,rp.Charge,ro.CreateDt as Date,DATEPART(MM,ro.CreateDt) AS Month 
					FROM  tbRegOrder as Ro INNER JOIN 
                  	tbRegProcedure AS rp ON ro.OrderGuid = rp.OrderGuid INNER JOIN 
                  	tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode
                    WHERE (rp.Status>=20) and  (DATEPART(YY, ro.CreateDt) = ' + @Year+') '

      EXEC(@szSQL+@ModalityType+@BodyPart+@Staff+@strSQL)
END


GO
/****** Object:  StoredProcedure [dbo].[procChargeYearForTechnician]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[procChargeYearForTechnician]
	-- Add the parameters for the stored procedure here
	  @Year varchar(16),
	  @Role varchar(32),
	  @ModalityType varchar(1024),
	  @BodyPart varchar(8000),
	  @Staff varchar(8000),
 	  @strSQL varchar(8000)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	 DECLARE @szSQL varchar(8000)
     Set @szSQL= 'SELECT '+@Role + ' rp.Modality,pc.ModalityType,pc.BodyPart,pc.Description ProcedureCode,rp.Charge,rp.ExamineDt as Date,DATEPART(MM,rp.ExamineDt) AS Month
                  FROM tbRegProcedure AS rp INNER JOIN
                  		 tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode
                  WHERE (rp.Status>=50) and (DATEPART(YY, rp.ExamineDt) = ' + @Year+') '
       

      EXEC(@szSQL+' '+@ModalityType+' '+@Staff+' '+@BodyPart+' '+@strSQL)
END


GO
/****** Object:  StoredProcedure [dbo].[procCheckDeadlock]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE procedure [dbo].[procCheckDeadlock]

   as
   set nocount on

   /*
   select 
   spid
被锁进程ID,
   blocked 锁进程ID, 
   status
被锁状态, 
   SUBSTRING(SUSER_SNAME(sid),1,30) 被锁进程登陆帐号, 
   SUBSTRING(hostname,1,12)
被锁进程用户机器名称, 
   SUBSTRING(DB_NAME(dbid),1,10)
被锁进程数据名称, 
   cmd 被锁进程命令, 
   waittype 被锁进程等待类型
   FROM master..sysprocesses 
   WHERE blocked>0 

   --dbcc inputbuffer(66) 输出相关锁进程的语句

执行调用   exec procCheckDeadlock
   */

   --创建锁进程临时表
   CREATE TABLE #templocktracestatus (  
EventType
varchar(100),  
Parameters INT,  
EventInfo
varchar(200)  
)
   --创建被锁进程临时表
   CREATE TABLE #tempbelocktracestatus (  
EventType
varchar(100),  
Parameters INT,
EventInfo
varchar(200)  
)

--创建之间的关联表
CREATE TABLE #locktracestatus (  
belockspid INT,  
belockspidremark varchar(20),  
belockEventType
varchar(100),  
belockEventInfo
varchar(200),  
lockspid INT,  
lockspidremark
varchar(20),  
lockEventType
varchar(100),  
lockEventInfo
varchar(200)  
)

   --获取死锁进程
   DECLARE dbcc_inputbuffer CURSOR READ_ONLY
   FOR select spid 被锁进程ID,blocked 锁进程ID  
FROM master..sysprocesses 
WHERE blocked>0 

   DECLARE @lockedspid int
   DECLARE @belockedspid int

   OPEN dbcc_inputbuffer

   FETCH NEXT FROM dbcc_inputbuffer INTO   @belockedspid,@lockedspid
   WHILE (@@fetch_status <> -1)
   BEGIN
  
IF (@@fetch_status <> -2)
  
BEGIN
  
--print '被堵塞进程'  
--select @belockedspid  
--dbcc inputbuffer(@belockedspid)  
--print '堵塞进程'  
--select @lockedspid  
--dbcc inputbuffer(@lockedspid)
  
INSERT INTO #tempbelocktracestatus  
EXEC('DBCC INPUTBUFFER('+@belockedspid+')')
  
INSERT INTO #templocktracestatus 
EXEC('DBCC INPUTBUFFER('+@lockedspid+')')
  
INSERT INTO #locktracestatus  
select @belockedspid,'被锁进程',a.EventType,a.EventInfo,@lockedspid,'锁进程',b.EventType,b.EventInfo
   from #tempbelocktracestatus   a,#templocktracestatus b
   
END
  
FETCH NEXT FROM dbcc_inputbuffer INTO @belockedspid,@lockedspid
   END

   CLOSE dbcc_inputbuffer
   DEALLOCATE dbcc_inputbuffer
--   select belockspid as '被锁进程ID',belockspidremark  as '进程类别',belockEventType as '事件类型',belockEventinfo as '被锁语句',
--   lockspid as '锁进程ID',lockspidremark as '进程类别',lockEventType as '事件类型',lockEventinfo as '锁语句' from #locktracestatus
   select * from #locktracestatus

   return (0) -- procCheckDeadlock

--   select belockspid as '被锁进程ID',belockspidremark  as '进程类别',belockEventType as '事件类型',belockEventinfo as '被锁语句',
--   lockspid as '锁进程ID',lockspidremark as '进程类别',lockEventType as '事件类型',lockEventinfo as '锁语句' from #locktracestatus


GO
/****** Object:  StoredProcedure [dbo].[procConsultantNotifCreate]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procConsultantNotifCreate]
	-- Add the parameters for the stored procedure here
	@xmlEvent xml,
	@xmlMsg nvarchar(max) output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @receiver nvarchar(max)
	declare @ReferralID nvarchar(128)
	
	set @ReferralID = Convert(nvarchar(128),@xmlEvent.query('Event/ReferralID/text()'))
	
	select @receiver = ReceiveObject from tbMessageConfig where ReceiveType ='DEPARTMENTSTAFF' and TemplateSP ='procConsultantNotifCreate' and EventType =N'转诊通知_创建'  and tbMessageConfig.Domain = (select SourceDomain from tbReferralList where ReferralID = @ReferralID)	
	
    select  B.Alias , @ReferralID,A.ModalityType from tbReferralList A,tbDomainList B where A.ReferralID = @ReferralID and A.SourceDomain = B.Domain
    
	set @xmlMsg= '<Message><Sender></Sender><Receivers>'+@receiver+'</Receivers></Message>'
END


GO
/****** Object:  StoredProcedure [dbo].[procConsultantNotifFinish]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[procConsultantNotifFinish]
	-- Add the parameters for the stored procedure here
	@xmlEvent xml,
	@xmlMsg nvarchar(max) output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @receiver nvarchar(max)
	declare @ReferralID nvarchar(128)
	
	set @ReferralID = Convert(nvarchar(128),@xmlEvent.query('Event/ReferralID/text()'))
	
	select @receiver = ReceiveObject from tbMessageConfig where ReceiveType ='DEPARTMENTSTAFF' and TemplateSP ='procConsultantNotifFinish' and EventType =N'转诊通知_完成' and tbMessageConfig.Domain = (select TargetDomain from tbReferralList where ReferralID = @ReferralID)
	
    select  B.Alias , @ReferralID,A.ModalityType from tbReferralList A,tbDomainList B where A.ReferralID = @ReferralID and A.TargetDomain = B.Domain
    
	set @xmlMsg= '<Message><Sender></Sender><Receivers>'+@receiver+'</Receivers></Message>'
END


GO
/****** Object:  StoredProcedure [dbo].[procConsultantNotification]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create PROCEDURE [dbo].[procConsultantNotification]
	-- Add the parameters for the stored procedure here
	@xmlEvent xml,
	@xmlMsg nvarchar(max) output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @sender nvarchar(128)
	declare @receiver nvarchar(max)
	declare @orderGuid nvarchar(128)
	declare @userGuid nvarchar(max)
	declare @ModalityType nvarchar(32)
	declare @WorkTime datetime
	declare @ExamSite nvarchar(64)
	
	set @WorkTime =GETDATE()
	
	set @orderGuid = Convert(nvarchar(128),@xmlEvent.query('Event/OrderGuid/text()'))
	
	select @userGuid=ReceiveObject from tbMessageConfig where ReceiveType ='DEPARTMENTSTAFF' and TemplateSP ='procConsultantNotification' and EventType =N'转诊通知' 
	
	select @ModalityType=ModalityType from tbRegProcedure where OrderGuid = @orderGuid
	
	select @ExamSite=ExamSite from tbRegOrder where OrderGuid = @orderGuid
	
	if exists (select 1 from tbRegProcedure where OrderGuid=@orderGuid and Status = 50)
		exec procGetMatchedDoctors @ModalityType,@ExamSite,'','',@WorkTime,@userGuid,'UnwrittenReport',@receiver output
	else
		exec procGetMatchedDoctors @ModalityType,@ExamSite,'','',@WorkTime,@userGuid,'UnapprovedReport',@receiver output
	
    select tbSiteList.Alias,AccNo,@ModalityType from tbRegOrder,tbSiteList where OrderGuid = @orderGuid and tbSiteList.Site =ExamSite
	set @xmlMsg= '<Message><Sender></Sender><Receivers>'+@receiver+'</Receivers></Message>'
END

GO
/****** Object:  StoredProcedure [dbo].[procCriticalSignConfirmation]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procCriticalSignConfirmation]
	-- Add the parameters for the stored procedure here
	@xmlEvent xml,
	@xmlMsg nvarchar(max) output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @sender nvarchar(128)
	declare @receiver nvarchar(max)
	declare @sql nvarchar(max)
	
	set @sender = Convert(nvarchar(128),@xmlEvent.query('/Event/Sender/text()'))
	set @receiver = Convert(nvarchar(max),@xmlEvent.query('/Event/Receivers/text()'))
   
	declare @i int
	set @i = 1
	set @sql = 'select '
	
    while @xmlEvent.exist('(/Event/Para)[sql:variable("@i")]') = 1
    begin
    if @sql = 'select '
    begin
    set @sql = @sql + '''' + replace(convert(nvarchar(max),@xmlEvent.query('(/Event/Para/text())[sql:variable("@i")]')),'''','''''') + ''' as ' + @xmlEvent.value('(/Event/Para/@Name)[sql:variable("@i")][1]','nvarchar(max)')
    end
    else
    begin
    set @sql = @sql + ',''' + replace(convert(nvarchar(max),@xmlEvent.query('(/Event/Para/text())[sql:variable("@i")]')),'''','''''') + ''' as ' + @xmlEvent.value('(/Event/Para/@Name)[sql:variable("@i")][1]','nvarchar(max)')
    end
    set @i = @i + 1
    end
    execute(@sql); 
        
	set @xmlMsg= '<Message><Sender>'+@sender+'</Sender><Receivers>'+@receiver+'</Receivers><ReceiverStrategy>8</ReceiverStrategy></Message>' --You can add a '<ReceiverStrategy>4</ReceiverStrategy>' Element(1 = use SP's @receiver , 2 = use tbMessageConfig's receiveobject, 4 = use both's intersection, 8 = use both's union) under '<Message>' , this element is optional(default value is 4).
	
END


GO
/****** Object:  StoredProcedure [dbo].[procCriticalSignContagion]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procCriticalSignContagion]
	-- Add the parameters for the stored procedure here
	@xmlEvent xml,
	@xmlMsg nvarchar(max) output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @sender nvarchar(128)
	declare @receiver nvarchar(max)
	declare @sql nvarchar(max)
	
	set @sender = Convert(nvarchar(128),@xmlEvent.query('/Event/Sender/text()'))
	set @receiver = Convert(nvarchar(max),@xmlEvent.query('/Event/Receivers/text()'))
   
	declare @i int
	set @i = 1
	set @sql = 'select '
	
    while @xmlEvent.exist('(/Event/Para)[sql:variable("@i")]') = 1
    begin
    if @sql = 'select '
    begin
    set @sql = @sql + '''' + replace(convert(nvarchar(max),@xmlEvent.query('(/Event/Para/text())[sql:variable("@i")]')),'''','''''') + ''' as ' + @xmlEvent.value('(/Event/Para/@Name)[sql:variable("@i")][1]','nvarchar(max)')
    end
    else
    begin
    set @sql = @sql + ',''' + replace(convert(nvarchar(max),@xmlEvent.query('(/Event/Para/text())[sql:variable("@i")]')),'''','''''') + ''' as ' + @xmlEvent.value('(/Event/Para/@Name)[sql:variable("@i")][1]','nvarchar(max)')
    end
    set @i = @i + 1
    end
    execute(@sql); 
        
	set @xmlMsg= '<Message><Sender>'+@sender+'</Sender><Receivers></Receivers><ReceiverStrategy>8</ReceiverStrategy></Message>' --You can add a '<ReceiverStrategy>4</ReceiverStrategy>' Element(1 = use SP's @receiver , 2 = use tbMessageConfig's receiveobject, 4 = use both's intersection, 8 = use both's union) under '<Message>' , this element is optional(default value is 4).
	
END


GO
/****** Object:  StoredProcedure [dbo].[procCriticalSignFeedback]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procCriticalSignFeedback]
	@xmlEvent xml,
	@xmlMsg nvarchar(max) output
AS
BEGIN
	BEGIN TRY	
	SET NOCOUNT ON;
	declare @OriginalMessageGuid nvarchar(max)
	declare @sendXmlEvent xml
	declare @ErrorMessage nvarchar(1024)
	
	set @OriginalMessageGuid = Convert(nvarchar(128),@xmlEvent.query('Event/OriginalMessageGuid/text()'))
	if(len(@OriginalMessageGuid) = 0)
	BEGIN
		SET @ErrorMessage = '@OriginalMessageGuid is empty'
	    RAISERROR(@ErrorMessage, 16, 1)
	END
	select @sendXmlEvent = [Event] from RISHippa..tEvent where Guid= (select EventGuid from RISHippa..tMessage where [Guid]=@OriginalMessageGuid)
	--CallType 0 is stored procedures,current only SP type--
	set @xmlMsg = 
	'<Message>
	<Guid></Guid>
	<Calls>
	<Call Type = "0">
	<Callee>procHandleCriticalSignResponse</Callee>
	<Parameters>
	<Parameter Name ="SendXML">'+Convert(nvarchar(max), @sendXmlEvent)
	+'</Parameter>
	<Parameter Name ="ReplyXML">'+Convert(nvarchar(max),@xmlEvent)
	+'</Parameter>
	</Parameters>
	</Call>	
	</Calls>	
	</Message>'
	
	END TRY
    BEGIN CATCH
    SET @ErrorMessage = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    
    SELECT @ErrorMessage = ERROR_MESSAGE(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE();
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH		
END


GO
/****** Object:  StoredProcedure [dbo].[procCriticalSignNotification]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procCriticalSignNotification]
	-- Add the parameters for the stored procedure here
	@xmlEvent xml,
	@xmlMsg nvarchar(max) output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @sender nvarchar(128)
	declare @receiver nvarchar(max)
	declare @sql nvarchar(max)
	
	set @sender = Convert(nvarchar(128),@xmlEvent.query('/Event/Sender/text()'))
	set @receiver = Convert(nvarchar(max),@xmlEvent.query('/Event/Receivers/text()'))
   
	declare @i int
	set @i = 1
	set @sql = 'select '
	
    while @xmlEvent.exist('(/Event/Para)[sql:variable("@i")]') = 1
    begin
    if @sql = 'select '
    begin
    set @sql = @sql + '''' + replace(convert(nvarchar(max),@xmlEvent.query('(/Event/Para/text())[sql:variable("@i")]')),'''','''''') + ''' as ' + @xmlEvent.value('(/Event/Para/@Name)[sql:variable("@i")][1]','nvarchar(max)')
    end
    else
    begin
    set @sql = @sql + ',''' + replace(convert(nvarchar(max),@xmlEvent.query('(/Event/Para/text())[sql:variable("@i")]')),'''','''''') + ''' as ' + @xmlEvent.value('(/Event/Para/@Name)[sql:variable("@i")][1]','nvarchar(max)')
    end
    set @i = @i + 1
    end
    execute(@sql); 
        
	set @xmlMsg= '<Message><Sender>'+@sender+'</Sender><Receivers>'+@receiver+'</Receivers><ReceiverStrategy>8</ReceiverStrategy></Message>' --You can add a '<ReceiverStrategy>4</ReceiverStrategy>' Element(1 = use SP's @receiver , 2 = use tbMessageConfig's receiveobject, 4 = use both's intersection, 8 = use both's union) under '<Message>' , this element is optional(default value is 4).
	
END


GO
/****** Object:  StoredProcedure [dbo].[procDeleteTemplateRecursive]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procDeleteTemplateRecursive]
      @Site NVARCHAR(64), 
      @DirectoryType NVARCHAR(128)
AS
begin
	SET NOCOUNT ON;
WITH ReportDireRecursive(TemplateGuid,ItemGuid,ParentID)
 as(
	select TemplateGuid,ItemGuid,ParentID from tbReportTemplateDirec where (ParentID  = @Site or ParentID ='UserTemplate'or ParentID ='GlobalTemplate') and DirectoryType = @DirectoryType
	union all
	select  a.TemplateGuid,a.ItemGuid, a.ParentID from tbReportTemplateDirec a inner join ReportDireRecursive b on a.ParentID = b.ItemGuid and DirectoryType = @DirectoryType
 )
select * into #tmpReportTemplateDir from ReportDireRecursive 
if(UPPER(@DirectoryType) = 'PHRASE')
begin
delete from tbPhraseTemplate where TemplateGuid in (select TemplateGuid from #tmpReportTemplateDir)
end
else
begin
delete from tbReportTemplate where TemplateGuid in (select TemplateGuid from #tmpReportTemplateDir)
end
delete from tbReportTemplateDirec where ItemGUID in (select ItemGUID from #tmpReportTemplateDir)
end


GO
/****** Object:  StoredProcedure [dbo].[procDeviceMonthStatistic]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procDeviceMonthStatistic] 
 -- Add the parameters for the stored procedure here
   @Year varchar(16),
   @Month varchar(16),
   @ModalityType varchar(1024),
   @Modality varchar(2048),
    @Bodypart varchar(8000)
AS
 BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;

    -- Insert statements for procedure here
  DECLARE @szSQL varchar(1024)
     Set @szSQL= 'SELECT  rp.Modality,pc.ModalityType,pc.BodyPart,pc.CheckingItem,rp.ExamineDt as RegDate,DATEPART(YYYY,rp.ExamineDt) AS Year,DATEPART(MM,rp.ExamineDt) AS Month,DATEPART(DD,rp.ExamineDt) AS Day
                  FROM         tbRegProcedure AS rp INNER JOIN
                      tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode
                  WHERE (rp.Status>=50) and (DATEPART(YY, rp.ExamineDt) = '+@Year+') AND (DATEPART(MM, rp.ExamineDt) = '+@Month+') '
               

      EXEC(@szSQL+@Modality+@Bodypart+@ModalityType)
END


GO
/****** Object:  StoredProcedure [dbo].[procDeviceTimesliceStatistic]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[procDeviceTimesliceStatistic] 
	  @DateTime varchar(128),
	  @ModalityType varchar(1024),
	  @Modality varchar(2048),
 	  @Bodypart varchar(8000)
AS
	BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	 DECLARE @szSQL varchar(1024)
     Set @szSQL= 'SELECT  rp.Modality,pc.ModalityType,pc.BodyPart,pc.CheckingItem,rp.ExamineDt as RegDate,DATEPART(MM,rp.ExamineDt) AS Month
                  FROM         tbRegProcedure AS rp INNER JOIN
                      tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode
                  WHERE (rp.Status>=50)  and '+@DateTime
               

      EXEC(@szSQL+@Modality+@Bodypart+@ModalityType)
END



GO
/****** Object:  StoredProcedure [dbo].[procDeviceYearStatistic]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procDeviceYearStatistic] 
 -- Add the parameters for the stored procedure here
   @Year varchar(16),
   @ModalityType varchar(1024),
   @Modality varchar(2048),
    @Bodypart varchar(8000)
AS
 BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;

    -- Insert statements for procedure here
  DECLARE @szSQL varchar(1024)
     Set @szSQL= 'SELECT  rp.Modality,pc.ModalityType,pc.BodyPart,pc.CheckingItem,rp.ExamineDt as RegDate,DATEPART(YYYY,rp.ExamineDt) AS Year,DATEPART(MM,rp.ExamineDt) AS Month
                  FROM         tbRegProcedure AS rp INNER JOIN
                      tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode
                  WHERE (rp.Status>=50) and (DATEPART(YY, rp.ExamineDt) = ' + @Year+') '
               

      EXEC(@szSQL+@Modality+@Bodypart+@ModalityType)
END


GO
/****** Object:  StoredProcedure [dbo].[procDiagnosticStatistic]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[procDiagnosticStatistic]
		@strSQL varchar(8000)
AS

	BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
      EXEC(@strSQL )
END


GO
/****** Object:  StoredProcedure [dbo].[procDropPrimaryKey]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procDropPrimaryKey]
	@tablename nvarchar(64)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @SQL VARCHAR(4000)

	SELECT @SQL = 'ALTER TABLE ['+ @tablename +'] DROP CONSTRAINT ['+name+']'
			FROM sysobjects WHERE xtype = 'PK'
			AND parent_obj = OBJECT_ID(@tablename)

	EXEC (@SQL)
END


GO
/****** Object:  StoredProcedure [dbo].[procERequisitionDel]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[procERequisitionDel]
AS
BEGIN
    BEGIN TRAN

    DELETE FROM dbo.tbRequisition WHERE WorkedDate IS NOT NULL AND datediff(Day,WorkedDate,getdate())>7 

    IF (@@error!=0)
    BEGIN

        ROLLBACK TRAN
        RETURN(1)
    END

    COMMIT TRAN
END


GO
/****** Object:  StoredProcedure [dbo].[procERequisitionIns]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procERequisitionIns]
(
 @ERNo                               varchar(32),
 @PatientID                          varchar(16),
 @PatientName                        varchar(16),
 @InHospitalNo                       varchar(16),
 @ClinicNo                           varchar(16),
 @ModalityType                       varchar(32),
 @ApplyDoctor                        varchar(64),
 @ApplyDept                          varchar(64),
 @Status                             varchar(16),
 @IsBooking                          varchar(8),
 @ApplyDate                          datetime,
 @ReferralID                         varchar(128),
 @PatientType                        varchar(32),
 @IsCharge                           int,
 @InHospitalregion                   varchar(128),
 @EAcquisition                       nvarchar(max),
 @ExamAppInfo      varchar(max),
 @Site        varchar(64),
 @Domain                             nvarchar(64)
 
)
AS
BEGIN
 BEGIN TRAN
 if(@Domain is null or LEN(@Domain)=0)
  select @Domain=Value from tbSystemProfile where Name='Domain'
 if(@IsCharge is null)
  set @IsCharge=0 
  
 INSERT INTO dbo.tbRequisition (ERNo,PatientID,PatientName,InHospitalNo,ClinicNo,ModalityType,ApplyDoctor,ApplyDept,Status,IsBooking,
  ApplyDate,ReferralID,IsCharge,PatientType,EAcquisition,InHospitalregion,ExamAppInfo,Site,Domain)
 VALUES 
 (@ERNo,@PatientID,@PatientName,@InHospitalNo,@ClinicNo,@ModalityType,@ApplyDoctor,@ApplyDept,@Status,@IsBooking,
      @ApplyDate,@ReferralID,@IsCharge,@PatientType,@EAcquisition,@InHospitalregion,@ExamAppInfo,@Site,@Domain
 )
    IF (@@error!=0)
    BEGIN

        ROLLBACK TRAN
        RETURN(1)
    END
    COMMIT TRAN
END


GO
/****** Object:  StoredProcedure [dbo].[procEventsStatisitc]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[procEventsStatisitc]
		@strSQL varchar(8000)
AS

	BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
      EXEC(@strSQL )
END


GO
/****** Object:  StoredProcedure [dbo].[procExternalQualityScoringList]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procExternalQualityScoringList]

    @AccessionNo  nvarchar(128),
    @StudyInstanceUID nvarchar(128),
    @Grade int,  
	@AppraiseResult integer output 
AS 
BEGIN
SET NOCOUNT ON;
---current only scoring for ORDER level !!!
declare @RP_guid nvarchar(128)
declare @ORDER_guid nvarchar(128)
declare @ExaminateDt datetime
declare @Appraisee nvarchar(128)
declare @Appraiser nvarchar(128)
declare @Comment nvarchar(128)
declare @Count int

declare RP_cursor cursor for
select rp.ProcedureGuid,rp.OrderGuid,rp.ExamineDt,rp.Technician from tbRegProcedure rp,tbRegOrder ro where ro.accno = @AccessionNo and rp.orderguid = ro.orderguid

print 'open cursor'
	open RP_cursor
    set @Count = 0 ---initialize the count for delete action
	print  'fetch cursor'
	Fetch Next from RP_cursor into @RP_guid,@ORDER_guid,@ExaminateDt,@Appraisee
	while @@Fetch_Status=0
	begin
		 set @Count = @Count+1
		 if(@Count = 1)
			begin
				 delete from tbQualityScoring where OrderGuid = @ORDER_guid
			end
				insert into tbQualityScoring Values(NEWID(),@RP_guid,@ORDER_guid,@ExaminateDt,0,@Grade,@Appraisee,@Appraiser,getdate(),@Comment)
		 
	if(@@error<>0)
			begin
				rollback transaction
			end
	Fetch Next from RP_cursor into @RP_guid,@ORDER_guid,@ExaminateDt,@Appraisee
	end
	close RP_cursor
	deallocate RP_cursor
END


GO
/****** Object:  StoredProcedure [dbo].[procExternalSetDischargedSummary]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[procExternalSetDischargedSummary]
    @PatientID nvarchar(64),
	@Summary nvarchar(max),
	@GenerateDt datetime=null
AS
BEGIN	
	SET NOCOUNT ON

	 IF(@GenerateDt IS NULL)
        SET @GenerateDt=GETDATE()

	if len(ltrim(rtrim(@PatientID)))=0
	begin
		insert into tbErrorTable(errormessage) values('procExternalSetDischargedSummary: Patient id is null') 
		return
	end
	if len(ltrim(rtrim(@Summary)))=0
	begin
		insert into tbErrorTable(errormessage) values('procExternalSetDischargedSummary:Summary is null') 
		return
	end
		
	insert into tbDischargedSummary([PatientID],[Summary],[GenerateDt]) values(@PatientID,@Summary,@GenerateDt)
	
END


GO
/****** Object:  StoredProcedure [dbo].[procExternalSetPathologyReport]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procExternalSetPathologyReport]
    @PatientID nvarchar(64),
	@Report nvarchar(max),
	@GenerateDt datetime=null
AS
BEGIN	
	SET NOCOUNT ON
	declare @AccNo nvarchar(64)
	declare	@ErrorMessage nvarchar(256)

	 IF(@GenerateDt IS NULL)
        SET @GenerateDt=GETDATE()

	if len(ltrim(rtrim(@PatientID)))=0
	begin
		insert into tbErrorTable(errormessage) values('procExternalSetPathologyReport: Patient id is null') 
		return
	end
	if len(ltrim(rtrim(@Report)))=0
	begin
		insert into tbErrorTable(errormessage) values('procExternalSetPathologyReport:Report is null') 
		return
	end
	
	if not exists(select 1 from tbRegPatient where patientid=@PatientID)
	begin
		insert into tbErrorTable(errormessage) values('procExternalSetPathologyReport: Patient is not exist') 
		return
	end
	insert into tbPathologyReport([PatientID],[Report],[GenerateDt]) values(@PatientID,@Report,@GenerateDt)
	--Set all the orders in the patient patholoty report flag
	declare cur_accno cursor for select accno from tbRegOrder where patientguid in(select patientguid from tbRegPatient where patientid=@PatientID)
	open cur_accno
    fetch next from cur_accno into @AccNo    
    while (@@fetch_status=0)  
	begin
			
		EXEC	[dbo].[procInsertOrderMessage]
			@AccNo = @AccNo,
			@Type = N'i',
			@UserGuid = N'',
			@UserName = N'',
			@Subject = N'病理报告',
			@Context = N'',
			@ErrorMessage = @ErrorMessage OUTPUT
			
		fetch next from cur_accno into @AccNo    
	end
	 close cur_accno  
    --撤销游标  
    DEALLOCATE cur_accno

END


GO
/****** Object:  StoredProcedure [dbo].[procExternaluniapplydept]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procExternaluniapplydept]
	-- Add the parameters for the stored procedure here
	@operationtype int,      -- 1 insert 2 update 3 delete
	@applydept                          nvarchar(128),--申请部门
	@telephone                          nvarchar(128)='',--电话
	@optional1                          nvarchar(512)='',--
	@optional2                          nvarchar(512)='',
	@optional3                          nvarchar(512)='',
	@shortcutcode                       nvarchar(512)='',--快捷码
	@site                               nvarchar(64)=''
	
AS
BEGIN
	if (LEN(@applydept)=0)
		return -1;
	
		
	declare @Domain   nvarchar(64)
	select @Domain=value from tbSystemProfile where name='domain'
	
	if(@operationtype=1)
	begin
	
		if exists(select * from tbApplyDept where ApplyDept=@applydept)
			return -1;
		
		INSERT INTO dbo.tbApplyDept(ApplyDept,Telephone,Optional1,Optional2,Optional3,ShortCutCode,Site,[Domain]) VALUES(@ApplyDept,@Telephone,@Optional1,@Optional2,@Optional3,@ShortCutCode,@Site,@Domain)			
	end
	else if(@operationtype=2)
	begin
		if not exists(select * from tbApplyDept where ApplyDept=@applydept)
			return -1;
	
	UPDATE dbo.tbApplyDept  SET Telephone= @Telephone,Optional1= @Optional1,Optional2= @Optional2,Optional3 = @Optional3,ShortCutCode= @ShortCutCode,Site= @Site WHERE ApplyDept = @ApplyDept
		
	end
	else if(@operationtype=3)
	begin
		delete from tbApplyDept where ApplyDept=@applydept
	end
	
END


GO
/****** Object:  StoredProcedure [dbo].[procExternaluniapplydoctor]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procExternaluniapplydoctor]
	-- Add the parameters for the stored procedure here
	@operationtype int,      -- 1 insert 2 update 3 delete	
	@applydept    nvarchar(128),  --申请部门
	@applydoctor    nvarchar(128),--申请医生
	@gender         nvarchar(128)='',--性别
	@mobile         nvarchar(128)='',--手机号码
	@telephone      nvarchar(128)='',--电话码号
	@staffid        nvarchar(128)='',--工号
	@email          nvarchar(128)='',--
	@optional1      nvarchar(128)='',
	@optional2      nvarchar(128)='',
	@optional3      nvarchar(128)='',
	@shortcutcode   nvarchar(512)='',
	@site           nvarchar(64)=''	
	
AS
BEGIN
	if (LEN(@applydept)=0 or LEN(@applydoctor)=0)
		return -1;
	
		
	declare @Domain   nvarchar(64)
	select @Domain=value from tbSystemProfile where name='domain'
	declare @applydeptid nvarchar(64)
	select @applydeptid =ID from tbApplyDept where ApplyDept=@applydept
	
	
	if(@operationtype=1)
	begin
	
		if exists(select * from tbApplyDoctor where ApplyDoctor=@applydoctor)
			return -1;
		--insert into tbDictionaryValue table	
		INSERT INTO dbo.tbApplyDoctor(ApplyDeptID,ApplyDoctor,Gender,Mobile,Telephone,StaffID,EMail,Optional1,Optional2,Optional3,ShortCutCode,Site,[Domain])
			VALUES(@ApplyDeptID,@ApplyDoctor,@Gender,@Mobile,@Telephone,@StaffID,@EMail,@Optional1,@Optional2,@Optional3,@ShortCutCode,@Site,@Domain)
	end
	else if(@operationtype=2)
	begin
		if not exists(select * from tbApplyDoctor where ApplyDoctor=@applydoctor)
			return -1;
	
		UPDATE dbo.tbApplyDoctor  SET ApplyDeptID = @ApplyDeptID,ApplyDoctor = @ApplyDoctor,Gender=@Gender,Mobile= @Mobile,Telephone= @Telephone,StaffID= @StaffID,
		EMail  = @EMail,Optional1=@Optional1,Optional2= @Optional2,Optional3=@Optional3,ShortCutCode= @ShortCutCode,Site = @Site  WHERE ApplyDoctor = @applydoctor
		
	end
	else if(@operationtype=3)
	begin
		delete from tbApplyDoctor where ApplyDoctor=@applydoctor
	end
	
END


GO
/****** Object:  StoredProcedure [dbo].[procExternaluniapplydoctorcontact]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procExternaluniapplydoctorcontact]
	-- Add the parameters for the stored procedure here		
	@applydoctor nvarchar(128), --非空  	
	@telephone nvarchar(128)='',	--
	@mobile nvarchar(128)='',
	@address nvarchar(256)='',
	@gender nvarchar(128)=''
	
AS
BEGIN
	if (LEN(@applydoctor)=0 )
		return -1;
		

	if not exists(select * from tbApplyDoctor where Applydoctor=@applydoctor)
		return -1;	
	
	update tbApplyDoctor set Telephone=@telephone,Mobile=@mobile,Optional1=@address,Gender=@gender where ApplyDoctor=@applydoctor	
	
	
END


GO
/****** Object:  StoredProcedure [dbo].[procExternaluniapplydoctorcontactbyStaffId]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procExternaluniapplydoctorcontactbyStaffId]
-- Add the parameters for the stored procedure here
@applydoctorStaffId nvarchar(128), --非空
@telephone nvarchar(128)='',	--
@mobile nvarchar(128)='',
@address nvarchar(256)='',
@gender nvarchar(128)=''

AS
BEGIN
if (LEN(@applydoctorStaffId)=0 )
return -1;


if not exists(select * from tbApplyDoctor where StaffId=@applydoctorStaffId)
return -1;

update tbApplyDoctor set Telephone=@telephone,Mobile=@mobile,Optional1=@address,Gender=@gender where  StaffId=@applydoctorStaffId


END


GO
/****** Object:  StoredProcedure [dbo].[procExternalunichargeitem]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procExternalunichargeitem]
	-- Add the parameters for the stored procedure here
	@operationtype int,      -- 1 insert 2 update 3 delete
	@code             nvarchar(64),   --交费项目代码
	@description      nvarchar(128),--交费项目描述
	@type             nvarchar(64),--交费项目类型
	@unit             nvarchar(64),--交费项目单位
	@price            decimal(10,2),--费用单价
	@shortcutcode     nvarchar(32)=''--交费项目快捷码
AS
BEGIN
	if (LEN(@Code)=0)
		return -1;
	
		
	declare @Domain   nvarchar(64)
	select @Domain=value from tbSystemProfile where name='domain'
	
	if(@operationtype=1)
	begin
	
		if exists(select * from tbChargeItem where Code=@code)
			return -1;
		--insert into chargeitem table	
		INSERT INTO dbo.tbChargeItem	(Code,Description,Type,Unit,Price,ShortcutCode,Domain) VALUES(@code,@description,@type,@unit,@price,@shortcutcode,@domain)
			
	end
	else if(@operationtype=2)
	begin
		if not exists(select * from tbChargeItem where Code=@code)
			return -1;
	
	    UPDATE dbo.tbChargeItem   SET Description= @Description,	Type= @Type,Unit= @Unit,Price=@Price,ShortcutCode=@ShortcutCode  WHERE Code=@code
	end
	else if(@operationtype=3)
	begin
		delete from tbChargeItem where Code=@code
	end
	
END


GO
/****** Object:  StoredProcedure [dbo].[procExternalunidictionary]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procExternalunidictionary]
	-- Add the parameters for the stored procedure here
	@operationtype int,      -- 1 insert 2 update 3 delete
	@tag                                int,          --字典类型
	@value                              nvarchar(256), --字典值
	@text                               nvarchar(512),--字典描述
	@isdefault                          int=0,    --是否默认 1/0
	@shortcutcode                       nvarchar(512)='',--快捷码
	@orderid                            int=0, --排序码
	@maptag                             int=0, --病人类型和优先级关联
	@mapvalue                           nvarchar(256)='',--病人类型和优先级关联
	@site                               nvarchar(64)=''
AS
BEGIN
	if (LEN(@tag)=0 or LEN(@value)=0 or LEN(@text)=0)
		return -1;
	
		
	declare @Domain   nvarchar(64)
	select @Domain=value from tbSystemProfile where name='domain'
	
	if(@operationtype=1)
	begin
	
		if exists(select * from tbDictionaryValue where Tag=@tag and value=@value)
			return -1;
		--insert into tbDictionaryValue table	
		INSERT INTO dbo.tbDictionaryValue(Tag,[Value],Text,IsDefault,ShortcutCode,OrderID,[Domain],mapTag,MapValue,Site)	VALUES(@Tag,@Value,@Text,@IsDefault,@ShortcutCode,@OrderID,@Domain,@mapTag,@MapValue,@Site)
			
	end
	else if(@operationtype=2)
	begin
		if not exists(select * from tbDictionaryValue where Tag=@tag and value=@value)
			return -1;
	
	        UPDATE dbo.tbDictionaryValue SET Text= @Text,IsDefault=@IsDefault,ShortcutCode= @ShortcutCode,OrderID= @OrderID,mapTag = @mapTag,MapValue=@MapValue,Site= @Site  WHERE Tag=@tag and Value=@value
	end
	else if(@operationtype=3)
	begin
		delete from tbDictionaryValue where Tag=@tag and Value=@value
	end
	
END


GO
/****** Object:  StoredProcedure [dbo].[procExternalunigetuserrole]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procExternalunigetuserrole]
	-- Add the parameters for the stored procedure here	
	@loginname nvarchar(128), --非空 
	@rolename nvarchar(512) out    --角色	
	
AS
BEGIN
	declare @userguid nvarchar(128)
	declare @temp nvarchar(512)
	if (LEN(@loginname)=0)
		return -1;
	select @userguid =userguid from tbUser where LoginName=@loginname

	set @temp=(SELECT  rolename  +',' FROM tbRole2User where UserGuid =@userguid FOR XML PATH (''))
	set @rolename=LEFT(@temp,LEN(@temp)-1)		
		
END


GO
/****** Object:  StoredProcedure [dbo].[procExternalunimodality]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procExternalunimodality]
	-- Add the parameters for the stored procedure here
	@operationtype int,      -- 1 insert 2 update 3 delete		
	@modalitytype                       nvarchar(128), --设备类型
	@modality                           nvarchar(128),--设备
	@room                               nvarchar(256)='',
	@ipaddress                          nvarchar(128)='',
	@maxload                            int=0,         --一天最大预约数
	@description                        nvarchar(512)='',
	@bookingshowmode                    int=0,         --预约显示模式 0只显示数量  1显示检查部位  2显示姓名 3显示部位和姓名	
	@applyhaltperiod                    int=0
	
AS
BEGIN
	if (LEN(@modality)=0 or LEN(@modalitytype)=0)
		return -1;
	
		
	declare @Domain   nvarchar(64)
	select @Domain=value from tbSystemProfile where name='domain'

	
	if(@operationtype=1)
	begin	
		if exists(select * from tbModality where Modality=@modality)
			return -1;
		--insert into tbModality table	
		INSERT INTO dbo.tbModality(ModalityGuid, ModalityType,Modality,Room,IPAddress,MaxLoad,Description,	BookingShowMode,ApplyHaltPeriod,[Domain])
			VALUES(newid(),@ModalityType,@Modality,@Room,@IPAddress,@MaxLoad,@Description,@BookingShowMode,@ApplyHaltPeriod,@Domain)
	
	end
	else if(@operationtype=2)
	begin
		if not exists(select * from tbModality where Modality=@modality)
			return -1;
	
		 UPDATE dbo.tbModality   SET ModalityType=@ModalityType,Room= @Room,IPAddress=@IPAddress,MaxLoad=@MaxLoad,Description=@Description,BookingShowMode = @BookingShowMode,ApplyHaltPeriod = @ApplyHaltPeriod		
		     WHERE Modality=@modality
		
	end
	else if(@operationtype=3)
	begin
		delete from tbModality where Modality=@modality
	end
	
END


GO
/****** Object:  StoredProcedure [dbo].[procExternaluniprocedurecode]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procExternaluniprocedurecode]
	-- Add the parameters for the stored procedure here
	@operationtype int,      -- 1 insert 2 update 3 delete
	@ProcedureCode                      nvarchar(128),  --检查代码
	@Description                        nvarchar(512),--检查描述
	@EnglishDescription                 nvarchar(512)='',--描述英文
	@ModalityType                       varchar(64),--设备类型
	@BodyPart                           varchar(256),--部位分类
	@CheckingItem                       varchar(256),--检查部位
	@Charge                             decimal(12,2)=0,--费用
	@Preparation                        nvarchar(512)='',--检查准备
	@Frequency                          int=0,         --大部位排序频率
	@BodyCategory                       varchar(64),--检查大部位
	@Duration                           int=10,        --检查持续时间
	@FilmSpec                           nvarchar(128)='',--胶片类型
	@FilmCount                          int=0,          --胶片数量 
	@ContrastName                       nvarchar(128)='', --造影剂名称
	@ContrastDose                       nvarchar(128)='',--造影剂量
	@ImageCount                         int=0,--图像数量
	@ExposalCount                       int=0,--暴光数量
	@BookingNotice                      nvarchar(512)='',--预约注意事项
	@ShortcutCode                       nvarchar(128)='',--快捷码
	@Enhance                            int=0,--是否增强  1/0
	@ApproveWarningTime                 int=240,-- 单位分钟
	@Effective                          int=1,--是否有效 1/0
	@Externals                          int=0,--是否其它DOMAIN的检查部位  1/0
	@BodypartFrequency                  int=0,--检查分类排序频率
	@CheckingItemFrequency              int=0,--检查	部位排序频率
	@TechnicianWeight                   int=0,--技师权重
	@RadiologistWeight                  int=0,--报告提交者权重
	@ApprovedRadiologistWeight          int=0,--报告审核者权生
	@DefaultModality                    nvarchar(64)=''--默认设备
AS
BEGIN
	if (LEN(@ProcedureCode)=0 or LEN(@ModalityType)=0 or LEN(@BodyPart)=0 or LEN(@CheckingItem)=0 or LEN(@BodyCategory)=0)
		return -1;
	
		
	declare @Domain   nvarchar(64)
	select @Domain=value from tbSystemProfile where name='domain'
	
	if(@operationtype=1)
	begin
	
		if exists(select * from tbProcedureCode where ProcedureCode=@ProcedureCode)
			return -1;
			
		if exists(select * from tbProcedureCode where ModalityType=@ModalityType and BodyCategory=@BodyCategory and BodyPart=@BodyPart and CheckingItem=@CheckingItem)
			return -1;
			
			
		--insert into tbProcedureCode table	
		INSERT INTO dbo.tbProcedureCode(ProcedureCode,Description,EnglishDescription,ModalityType,BodyPart,CheckingItem,Charge,Preparation,Frequency,BodyCategory,Duration,FilmSpec,FilmCount,ContrastName,ContrastDose,ImageCount,ExposalCount,BookingNotice,ShortcutCode,Enhance,ApproveWarningTime,Effective,[Domain],Externals,BodypartFrequency,CheckingItemFrequency,TechnicianWeight,RadiologistWeight,ApprovedRadiologistWeight,DefaultModality)
		   VALUES(@ProcedureCode,@Description,@EnglishDescription,@ModalityType,@BodyPart,@CheckingItem,@Charge,@Preparation,@Frequency,@BodyCategory,@Duration,@FilmSpec,@FilmCount,@ContrastName,@ContrastDose,@ImageCount,@ExposalCount,@BookingNotice,@ShortcutCode,@Enhance,@ApproveWarningTime,@Effective,@Domain,@Externals,@BodypartFrequency,@CheckingItemFrequency,@TechnicianWeight,@RadiologistWeight,@ApprovedRadiologistWeight,@DefaultModality)		
						
	end
	else if(@operationtype=2)
	begin
		if not exists(select * from tbProcedureCode where ProcedureCode=@ProcedureCode)
				return -1;
		if exists(select * from tbProcedureCode where ModalityType=@ModalityType and BodyCategory=@BodyCategory and BodyPart=@BodyPart and CheckingItem=@CheckingItem)
			return -1;
			
		 UPDATE dbo.tbProcedureCode     SET 	Description= @Description,EnglishDescription=@EnglishDescription,ModalityType= @ModalityType,BodyPart    = @BodyPart,
		CheckingItem= @CheckingItem,Charge= @Charge,Preparation = @Preparation,Frequency= @Frequency,BodyCategory= @BodyCategory,Duration= @Duration,
		FilmSpec    = @FilmSpec,FilmCount= @FilmCount,ContrastName= @ContrastName,ContrastDose= @ContrastDose,ImageCount  = @ImageCount,ExposalCount= @ExposalCount,
		BookingNotice= @BookingNotice,ShortcutCode= @ShortcutCode,Enhance = @Enhance,ApproveWarningTime = @ApproveWarningTime,Effective= @Effective,
		Domain= @Domain,Externals=@Externals,BodypartFrequency=@BodypartFrequency,CheckingItemFrequency= @CheckingItemFrequency,TechnicianWeight          = @TechnicianWeight,
		RadiologistWeight = @RadiologistWeight,ApprovedRadiologistWeight = @ApprovedRadiologistWeight,DefaultModality = @DefaultModality
         WHERE 	ProcedureCode=@ProcedureCode		
			
	
	end
	else if(@operationtype=3)
	begin
		delete from tbProcedureCode where ProcedureCode=@ProcedureCode
	end
	
END


GO
/****** Object:  StoredProcedure [dbo].[procExternaluniupdateuserpassword]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procExternaluniupdateuserpassword]
	-- Add the parameters for the stored procedure here	
	@loginname nvarchar(128), --非空 
	@password nvarchar(128)    --密码密文	
	
AS
BEGIN
	if (LEN(@loginname)=0 or LEN(@password)=0)
		return -1;
	update tbUser set [password]=@password  where loginname=@loginname		
		
END


GO
/****** Object:  StoredProcedure [dbo].[procExternaluniusercontact]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procExternaluniusercontact]
	-- Add the parameters for the stored procedure here		
	@loginname nvarchar(128), --非空  	
	@telephone nvarchar(128)='',	--
	@mobile nvarchar(128)='',
	@address nvarchar(256)
	
AS
BEGIN
	if (LEN(@loginname)=0 )
		return -1;

	if not exists(select * from tbUser where LoginName=@loginname)
		return -1;	
	
	update tbUser2Domain set Telephone=@telephone,Mobile=@mobile where UserGuid in(select UserGuid from tbUser where LoginName=@loginname)
	update tbUser set address=@address where LoginName=@loginname
	
END


GO
/****** Object:  StoredProcedure [dbo].[procExternaluniuserinfo]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procExternaluniuserinfo]
	-- Add the parameters for the stored procedure here
	@operationtype int,      -- 1 insert 2 update 3 delete
	@rolename nvarchar(128),  --Administrator, HLRadiologist,MLRadiologist,LLRadiologist,Technician,Registrar 多角色用,分割
	@loginname nvarchar(128), --非空  	
	@localname nvarchar(128), --非空
	@englishname nvarchar(128)='',	 
	@password nvarchar(128),    --密码密文
	@title nvarchar(128)='',    --职位
	@comments nvarchar(128)='', --备注
	@department nvarchar(128)='',	 --科室
	@Telephone nvarchar(64)='',	
	@email nvarchar(128)='',	
	@issetexpiredate int=0,
	@startdt datetime,	
	@enddt datetime
	
AS
BEGIN
	if (LEN(@loginname)=0)
		return;
	
	declare @userguid nvarchar(128)	
	declare  @rn  varchar(300),@m  int,@n  int  
	declare @domain   nvarchar(64)
	select @domain=value from tbSystemProfile where name='domain'
		
	if(@operationtype=1)
	begin
		if exists(select * from tbUser where LoginName=@loginname)
		begin
		    --recover this user
		   update tbUser set DeleteMark=0 where LoginName=@loginname
		   update tbUser2Domain set IsSetExpireDate=0 where UserGuid in(select userguid from tbUser where LoginName=@loginname)
			return;
		end
		
			
		--insert into user table
		set @userguid=NEWID();
		insert into tbUser(userguid,loginname,localname,englishname,[password],Title,comments,Domain) values(@userguid,@loginname,@localname,@englishname,@password,@title,@comments,@domain)
		
		
		--insert into role2user table
		set  @m=CHARINDEX(',',@rolename)  
		set  @n=1  
		
		if(@m=0)
		begin
			set  @rn=@rolename 
			insert into tbRole2User(RoleName,UserGuid,Domain) values(@rn,@userguid,@domain)
		end
		else
		begin		
			WHILE  @m>0  
			BEGIN  
				   set  @rn=substring(@rolename,@n,@m-@n)  
				   insert into tbRole2User(RoleName,UserGuid,Domain) values(@rn,@userguid,@domain)
				   
				   set  @n=@m+1  
				   set  @m=CHARINDEX(',',@rolename,@n)  
			END	
		end	
		--insert into user2domain		
		insert into tbUser2Domain(UserGuid,Department,Domain,Email,Telephone,IsSetExpireDate,StartDate,EndDate) values(@userguid,@department,@domain,@email,@Telephone,@issetexpiredate,@startdt,@enddt)
		
	--insert into userprofile	
		declare my_Cusror cursor local FOR select Name,ModuleID,RoleName,Value,Exportable,PropertyDesc,PropertyOptions,Inheritance,PropertyType,IsHidden,OrderingPos,Domain from tbRoleProfile where inheritance > 0 and (RoleName ='' or RoleName is null)  and Domain in (select value from tbSystemProfile where Name = 'Domain')
	declare @Name varchar(128);
	declare @ModuleID varchar(64);
	declare @Value varchar(max);
	declare @Exportable int;
	declare @PropertyDesc varchar(256);
	declare @PropertyOptions varchar(256);
	declare @Inheritance int;
	declare @PropertyType int;
	declare @IsHidden int;
	declare @OrderingPos varchar(128);	
		
	OPEN my_Cusror;
    FETCH NEXT FROM my_Cusror into @Name,@ModuleID,@RoleName,@Value,@Exportable,@PropertyDesc,@PropertyOptions,@Inheritance,@PropertyType,@IsHidden,@OrderingPos,@Domain;
    set @Inheritance = @Inheritance - 1;
    
    while (@@fetch_status = 0)
    begin 
    INSERT INTO tbUserProfile(Name,ModuleID,RoleName,UserGuid,[Value],Exportable,PropertyDesc,PropertyOptions,Inheritance,PropertyType,IsHidden,OrderingPos,[Domain]) VALUES (@Name,@ModuleID,@RoleName,@UserGuid,@Value,@Exportable,@PropertyDesc,@PropertyOptions,@Inheritance,@PropertyType,1,@OrderingPos,@Domain)    
    FETCH NEXT FROM my_Cusror into @Name,@ModuleID,@RoleName,@Value,@Exportable,@PropertyDesc,@PropertyOptions,@Inheritance,@PropertyType,@IsHidden,@OrderingPos,@Domain;
    set @Inheritance = @Inheritance - 1;
    end
    	
	end
	else if(@operationtype=2)
	begin
		if not exists(select * from tbUser where LoginName=@loginname)
				return -1;
		
		update tbUser set localname=@localname,englishname=@englishname,Title=@title,comments=@comments  where loginname=@loginname
		update tbUser2Domain set Department=@department,Email=@email,Telephone=@Telephone where UserGuid in(select userguid from tbUser where LoginName=@loginname)
		
	end
	else if(@operationtype=3)
	begin
		if not exists(select * from tbUser where LoginName=@loginname)
				return -1;
		
		update tbUser set DeleteMark=1 where LoginName=@loginname
		update tbUser2Domain set IsSetExpireDate=1,StartDate='2000-1-1',EndDate='2000-1-1' where UserGuid in(select userguid from tbUser where LoginName=@loginname)	
		
	end
	
END


GO
/****** Object:  StoredProcedure [dbo].[procFilmLoanListCount]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procFilmLoanListCount]
     @Conditions varchar(MAX),
     @TotalCount integer output
AS 
BEGIN
SET QUOTED_IDENTIFIER ON 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET @TotalCount=0

declare @sql nvarchar(max)

 select @sql = 'select @TotalCount=count(1) from tbFilmLoan with (nolock)
     where '
     + @Conditions
 --print '4' + @sql
 EXEC sp_executesql @sql, N' @TotalCount int output ', @TotalCount output
END


GO
/****** Object:  StoredProcedure [dbo].[procFilmLoanListPage]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procFilmLoanListPage]
 @PageIndex integer,
 @PageSize integer,
 @Columns nvarchar(MAX),
 @Conditions nvarchar(MAX),
 @OrderBy nvarchar(MAX)
AS 
BEGIN

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

if @PageSize < 1 set @PageSize = 30
if @PageIndex > 0xfffff set @PageIndex = 0xfffff
if @PageIndex < 1 set @PageIndex = 1

declare @minrowcount int
declare @maxrowcount int
set @minrowcount=(@PageIndex-1)*@PageSize+1
set @maxrowcount = @PageIndex * @PageSize

declare @rowNumOrderBy nvarchar(MAX)
set @rowNumOrderBy = @OrderBy
if @rowNumOrderBy = '' set @rowNumOrderBy = 'Order by (select 1)'
set @rowNumOrderBy = replace(@rowNumOrderBy, '.', '__')

declare @totalColumns nvarchar(MAX)
set @totalColumns = '
tbFilmLoan.PatientID AS tbFilmLoan__PatientID
, tbFilmLoan.LocalName AS tbFilmLoan__LocalName
, tbFilmLoan.Telephone AS tbFilmLoan__Telephone
, tbFilmLoan.AccNo AS tbFilmLoan__AccNo
, tbFilmLoan.ExamineDt AS tbFilmLoan__ExamineDt
, tbFilmLoan.Loanee AS tbFilmLoan__Loanee
, tbFilmLoan.LoanQuantity AS tbFilmLoan__LoanQuantity
, tbFilmLoan.LoanDt AS tbFilmLoan__LoanDt
, tbFilmLoan.ReturnQuantity AS tbFilmLoan__ReturnQuantity
, tbFilmLoan.Comment AS tbFilmLoan__Comment
, tbFilmLoan.Remaining AS tbFilmLoan__Remaining
, tbFilmLoan.ReturnDt AS tbFilmLoan__ReturnDt
, tbFilmLoan.[Zone] AS tbFilmLoan__Zone
, tbFilmLoan.[Organization] AS tbFilmLoan__Organization
, tbFilmLoan.ClinicCode AS tbFilmLoan__ClinicCode
, tbFilmLoan.Operator AS tbFilmLoan__Operator
, dbo.fnTranslateUser(tbFilmLoan.Operator) AS tbFilmLoan__Operator__DESC
, tbFilmLoan.OperateDt AS tbFilmLoan__OperateDt
, tbFilmLoan.LoanGuid AS tbFilmLoan__LoanGuid
'
if @Columns = '' set @Columns='*'

declare @sql nvarchar(MAX)
set @sql = 'select * from (select ROW_NUMBER() Over('+@rowNumOrderBy+') as rowNum, '+@Columns+' from (select top '+cast(@maxrowcount as varchar(18)) +' '
--set @sql = 'select * from (select top '+cast(@maxrowcount as varchar(18)) +' ROW_NUMBER() Over('+@rowNumOrderBy+') as rowNum, ' 
+ @totalColumns
+ ' from tbFilmLoan where '
+ @Conditions+ + ' ' + @OrderBy
 +') TEMP_TABLE) TEMP_TABLE1 where TEMP_TABLE1.rowNum between '+cast(@minrowcount as varchar(18)) +' and '+cast(@maxrowcount as varchar(18))
--exec procLongPrint @sql

EXEC(@sql)

END


GO
/****** Object:  StoredProcedure [dbo].[procFilmMonthStatistic]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procFilmMonthStatistic]
 -- Add the parameters for the stored procedure here
   @Year varchar(16),
   @Month varchar(32),
   @FilmSpec varchar(1024),
   @ModalityType varchar(1024),
    @Bodypart varchar(8000)
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;

    -- Insert statements for procedure here
  DECLARE @szSQL varchar(1024)
     DECLARE @tempString varchar(1024)
     if(LEN(@FilmSpec)) > 0
  BEGIN
            print(@FilmSpec)
   set @tempString = @FilmSpec
  END
  ELSE
   set @tempString = ''
     Set @szSQL= 'SELECT  pc.Bodypart,rp.FilmSpec,rp.FilmCount,pc.ModalityType,DATEPART(YYYY,rp.ExamineDt) AS Year,DATEPART(MM,rp.ExamineDt) AS Month,DATEPART(DD,rp.ExamineDt) AS Day
                  FROM         tbRegProcedure AS rp INNER JOIN
                      tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode
                  WHERE (rp.Status>=50) and (DATEPART(YY, rp.ExamineDt) = '+@Year+') AND (DATEPART(MM, rp.ExamineDt) = '+@Month+') '
      +@tempString

      EXEC(@szSQL+@Bodypart+@ModalityType)
      print(@szSQL+@Bodypart+@ModalityType)
END


GO
/****** Object:  StoredProcedure [dbo].[procFilmMonthStatisticExposal]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procFilmMonthStatisticExposal]
 -- Add the parameters for the stored procedure here
   @Year varchar(16),
   @Month varchar(32),
   @ModalityType varchar(1024),
    @Bodypart varchar(8000),
   @Staff varchar(8000)
   
AS
 BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;

    -- Insert statements for procedure here
  DECLARE @szSQL varchar(1024)
     Set @szSQL= 'SELECT  rp.Technician,pc.Bodypart,rp.ExposalCount,pc.ModalityType,DATEPART(YYYY,rp.ExamineDt) AS Year,DATEPART(MM,rp.ExamineDt) AS Month,DATEPART(DD,rp.ExamineDt) AS Day
                  FROM         tbRegProcedure AS rp INNER JOIN
                      tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode
                  WHERE (rp.Status>=50) and (DATEPART(YY, rp.ExamineDt) = '+@Year+') AND (DATEPART(MM, rp.ExamineDt) = '+@Month+') '
               

      EXEC(@szSQL+@Bodypart+@ModalityType+@Staff)
END


GO
/****** Object:  StoredProcedure [dbo].[procFilmPrintStat]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procFilmPrintStat]
	@ConditionStr nvarchar(4000)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
create table #temp1
(
	ModalityType nvarchar(128),
	FilmSize nvarchar(128),
	[Count] int,
	orderIndex int
)

create table #temp2
(
	ModalityType nvarchar(128),
	FilmSize nvarchar(128),
	[Count] int
)
	declare @sql nvarchar(4000)

	set @sql ='insert into #temp1 select ModalityType, (select Text from tbDictionaryValue where tag =4 and Value = hFilmSize) as filmSize,sum(PrintTimes) as Count ,(select orderid from tbDictionaryValue where tag =4 and Value = hFilmSize) as orderIndex  from tbFilmPrintLog ,tbFilmScoring  
	where tbFilmPrintLog.AccNo = tbFilmScoring.AccNo and tbFilmPrintLog.SeriesID = tbFilmScoring.SeriesID ' + @ConditionStr+ ' Group by ModalityType,hFilmSize order by ModalityType ,orderIndex '
    exec(@sql)
	print(@sql)

	print 'open cursor'
	declare @ModalityType nvarchar(128)
	declare @SubTotal int
	declare score_cursor cursor for


	select distinct ModalityType from  #temp1
	print(@ModalityType)
	open score_cursor
	print  'fetch cursor'
	Fetch Next from score_cursor into @ModalityType
	while @@Fetch_Status=0
	begin
		
			begin
					insert into #temp2 select ModalityType,FilmSize,[Count] from  #temp1 where ModalityType = @ModalityType 
					select @SubTotal = sum([Count]) from #temp1 where ModalityType = @ModalityType
					insert into #temp2 values('小计','',@SubTotal)

			end


		if(@@error<>0)
		begin
			rollback transaction
		end
		Fetch Next from score_cursor into @ModalityType
	end
	close score_cursor
	deallocate score_cursor



    --insert the total row
	declare @Total int
	select @Total = sum([Count]) from #temp1
	if not exists (select * from #temp1)
	begin
		select ModalityType,FilmSize,[Count] from #temp2 
		return
	end
	insert into #temp2 values('总计','',@Total)
	select ModalityType,FilmSize,[Count] from #temp2 


END


GO
/****** Object:  StoredProcedure [dbo].[procFilmScoring]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procFilmScoring]
	(
    @AccNo  nvarchar(128),
    @SeriesID nvarchar(128),
	@Grade nvarchar(8) ,
	@CommandType nvarchar(8),
	@UserName nvarchar(64),
    @FilmSize nvarchar(16),
	@FilmCount nvarchar(8),
	@ActionDt nvarchar(64),
	@StudyDt nvarchar(64),
	@ModalityType nvarchar(128)
	)
AS 
BEGIN
SET NOCOUNT ON;
    declare @FilmCountTemp int

    IF(@AccNo IS NULL OR @SeriesID IS NULL)
	RETURN
    IF(LEN(@AccNo) < 1 OR LEN(@SeriesID) <1)
	RETURN

	IF(@CommandType='19')--FILM_GENERATE
		begin
		if not exists (select * from tbFilmScoring where AccNo = @AccNo and SeriesID =@SeriesID)
			begin
				insert into tbFilmScoring values(@AccNo,@SeriesID,19,@FilmSize,cast(@FilmCount as int),-1,'',NULL,@UserName,@ActionDt,@ModalityType,@StudyDt)
				if(cast(@FilmCount as int) >0)
					begin
							insert into tbFilmPrintLog values(newid(),@AccNo,@SeriesID,cast(@FilmCount as int),@UserName,@ActionDt,@FilmSize)
					end
			end
		end

	IF(@CommandType='18')--FILM_GRADE
		begin
		if exists (select * from tbFilmScoring where AccNo = @AccNo and SeriesID =@SeriesID)
			begin
				update  tbFilmScoring set CommandType = 18,  Grade = cast(@Grade as int),QAName = @UserName , QADt = @ActionDt  where AccNo = @AccNo and SeriesID =@SeriesID
			end
		end
	IF(@CommandType='20')--FILM_PRINT
		begin
		if exists (select * from tbFilmScoring where AccNo = @AccNo and SeriesID =@SeriesID)
			begin
				select @FilmCountTemp =  hFilmsCount from tbFilmScoring where AccNo = @AccNo and SeriesID = @SeriesID
				update  tbFilmScoring set hFilmsCount =(cast(@FilmCount as int)+@FilmCountTemp)  where AccNo = @AccNo and SeriesID =@SeriesID
				insert into tbFilmPrintLog values(newid(),@AccNo,@SeriesID,cast(@FilmCount as int),@UserName,@ActionDt,@FilmSize)
			end
		end

END


GO
/****** Object:  StoredProcedure [dbo].[procFilmScoringStat]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procFilmScoringStat]
	@ConditionStr nvarchar(4000)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
create table #temp1
(
	ModalityType nvarchar(128),
	Grade int,
	Element int,
	Denominator decimal(30,2),
	Rate decimal(30,2)
)
	create table #temp5
	(
		ModalityType nvarchar(128),
		Grade  nvarchar(128),
		Count  int,
		Rate decimal(30,2)
	)

declare @sql nvarchar(4000)



set @sql = 'insert into #temp1 select ModalityType,Grade, count(*) as Element, 0.00 as Denominator, 0.00 as Rate  from tbFilmScoring where 1=1 '+@ConditionStr+' group by ModalityType,Grade order by ModalityType, Grade'
print(@sql)
exec(@sql)
select ModalityType, sum(Element) as Denominator into #temp2 from #temp1 where Grade > -1 group by ModalityType order by ModalityType
update #temp1 set Denominator = (select Denominator from #temp2 where #temp1.ModalityType = #temp2.ModalityType and #temp1.Grade > -1)

select ModalityType, sum(Element) as Denominator into #temp3 from #temp1 group by ModalityType order by ModalityType
update #temp1 set Denominator = (select Denominator from #temp3 where #temp1.ModalityType = #temp3.ModalityType and #temp1.Grade = -1) where Grade = -1

update #temp1 set rate = (
case 
when Element = 0 or Denominator = 0 
then 0.00
else Element *100/Denominator 
end
)


select ModalityType, (select Text from tbDictionaryValue where tag = 57 and grade = Value) as Grade, Element as [Count] ,Rate into #temp4 from #temp1 


	print 'open cursor'
	declare @ModalityType nvarchar(128)
	declare @SubTotal int
	declare score_cursor cursor for


	select distinct ModalityType from  #temp4
	print(@ModalityType)
	open score_cursor
	print  'fetch cursor'
	Fetch Next from score_cursor into @ModalityType
	while @@Fetch_Status=0
	begin
		
			begin
					insert into #temp5 select * from  #temp4 where ModalityType = @ModalityType
					select @SubTotal = sum([Count]) from #temp4 where ModalityType = @ModalityType
					insert into #temp5 values('小计','',@SubTotal,null)

			end


		if(@@error<>0)
		begin
			rollback transaction
		end
		Fetch Next from score_cursor into @ModalityType
	end
	close score_cursor
	deallocate score_cursor

declare @Total int
select @Total = sum([Count]) from #temp5 where ModalityType != '小计'


if not exists (select * from #temp5)
	begin
	select * from #temp5
	return
	end
else
insert into #temp5(ModalityType,Grade,Count,Rate) values('总计','',@Total,null)
select * from #temp5

END



GO
/****** Object:  StoredProcedure [dbo].[procFilmTimesliceStatistic]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[procFilmTimesliceStatistic]
	-- Add the parameters for the stored procedure here
	@FilmSpec varchar(8000),
	@DateTime varchar(128),
	@Bodypart varchar (8000),
	@ModalityType varchar(1024)
AS
	BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	 DECLARE @szSQL varchar(1024)
     Set @szSQL= 'SELECT  pc.Bodypart,rp.FilmSpec,rp.FilmCount,pc.ModalityType,DATEPART(MM,rp.ExamineDt) AS Month
                  FROM         tbRegProcedure AS rp INNER JOIN
                      tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode
                  WHERE (rp.Status>=50)  '+' and '+@DateTime
               

      EXEC(@szSQL+@Bodypart+@ModalityType+@FilmSpec)
END


GO
/****** Object:  StoredProcedure [dbo].[procFilmTimesliceStatisticExposal]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[procFilmTimesliceStatisticExposal]
	-- Add the parameters for the stored procedure here
	@DateTime varchar(128),
	@Bodypart varchar (8000),
	@ModalityType varchar(1024),
  @Staff	varchar(8000)

AS
	BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	 DECLARE @szSQL varchar(1024)
     Set @szSQL= 'SELECT   rp.Technician,pc.Bodypart,rp.ExposalCount,pc.ModalityType,DATEPART(MM,rp.ExamineDt) AS Month
                  FROM         tbRegProcedure AS rp INNER JOIN
                      tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode
                  WHERE (rp.Status>=50)  and '+@DateTime
               

      EXEC(@szSQL+@Bodypart+@ModalityType+@Staff)
END


GO
/****** Object:  StoredProcedure [dbo].[procFilmYearStatistic]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


  -- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[procFilmYearStatistic]
	-- Add the parameters for the stored procedure here
	  @Year varchar(16),
	  @FilmSpec varchar(8000),
	  @ModalityType varchar(1024),
 	  @Bodypart varchar(8000)
AS
	BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	 DECLARE @szSQL varchar(1024)
     Set @szSQL= 'SELECT  pc.Bodypart,rp.FilmSpec,rp.FilmCount,pc.ModalityType,DATEPART(MM,rp.ExamineDt) AS Month
                  FROM         tbRegProcedure AS rp INNER JOIN
                      tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode
                  WHERE (rp.Status>=50) and (DATEPART(YY, rp.ExamineDt) = ' + @Year+') '
               

      EXEC(@szSQL+@Bodypart+@ModalityType+@FilmSpec)
print(@FilmSpec)
END


GO
/****** Object:  StoredProcedure [dbo].[procFilmYearStatisticExposal]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


 -- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[procFilmYearStatisticExposal]
	-- Add the parameters for the stored procedure here
	@Year varchar(16),
	@ModalityType varchar(1024),
 	@Bodypart varchar(8000),
	@Staff	varchar(8000)
AS
	BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	 DECLARE @szSQL varchar(1024)
     Set @szSQL= 'SELECT  rp.Technician,pc.Bodypart,rp.ExposalCount,pc.ModalityType,DATEPART(MM,rp.ExamineDt) AS Month
                  FROM         tbRegProcedure AS rp INNER JOIN
                      tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode
                  WHERE (rp.Status>=50) and (DATEPART(YY, rp.ExamineDt) = ' + @Year+') '
               

      EXEC(@szSQL+@Bodypart+@ModalityType+@Staff)
END


GO
/****** Object:  StoredProcedure [dbo].[procGeneralPage]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-------------------------------------------------
--For US27604 Teaching authority for low level doctor
-------------------------------------------------
CREATE PROCEDURE [dbo].[procGeneralPage]
 -- Add the parameters for the stored procedure here
 @PageIndex integer,
 @PageSize integer,
 --@tblName  varchar(256),   -----------contains primarykey 
    --@PrimaryKey varchar(256),
 @fields varchar(8000),
    --@from  varchar(8000),
 @Where varchar(8000)    -----------exclude 'where'
 --@orderType varchar(256),
 --@OrderBy varchar(256),
    --@TotalCount integer output
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;
 declare @strSQL nvarchar(max);
 declare @strWrittenSQL nvarchar(max);
 declare @strUnwrittenSQL nvarchar(max);
 declare @strUnwrittenFields nvarchar(max);
 --set @fields = REPLACE(@fields,'tbRegProcedure','P')
 --set @Where = REPLACE(@Where,'tbRegProcedure','P')
 
if @PageSize < 1 set @PageSize = 30

if @PageIndex > 0xfffff set @PageIndex = 0xfffff

if @PageIndex >= 0
BEGIN
     declare @topcount int
     set @topcount = @PageIndex * @PageSize  
     --print(@topcount) 
	set @strWrittenSQL = 'select '+@fields + ', tbTeaching.Submitter as SubmitterGuid '+
      '  from tbTeaching left join tbReport with (nolock) on tbTeaching.ReportGuid = tbReport.ReportGuid ,tbRegPatient,tbRegOrder,tbRegProcedure  where tbReport.ReportGuid =	   tbRegProcedure.ReportGuid and tbRegOrder.OrderGuid = tbRegProcedure.OrderGuid and tbRegPatient.PatientGuid = tbRegOrder.PatientGuid '+@Where 
	  set @strUnwrittenFields =@fields;
	  set @strUnwrittenFields=REPLACE(@strUnwrittenFields,'tbReport.ReportName','''''')
	  set @strUnwrittenFields=REPLACE(@strUnwrittenFields,'tbReport.AccordRate','''''')
	  set @strUnwrittenFields=REPLACE(@strUnwrittenFields,'tbReport.WYSText','''''')
	  set @strUnwrittenFields=REPLACE(@strUnwrittenFields,'tbReport.WYGText','''''')

  set @strUnwrittenSQL='select '+ @strUnwrittenFields +',tbTeaching.Submitter as SubmitterGuid   from tbTeaching, tbRegPatient,tbRegOrder,tbRegProcedure  where	tbRegOrder.OrderGuid = tbRegProcedure.OrderGuid and tbRegPatient.PatientGuid = tbRegOrder.PatientGuid and tbTeaching.ReportGuid=tbRegOrder.OrderGuid' +@where 
  if  charindex('tbReport.AccordRate',@Where)>0  or
	  charindex('tbReport.reportText',@Where)>0 or
      charindex('tbReport.Keyword',@Where)>0 or
      charindex('tbReport.WYSText',@Where)>0 or
      charindex('tbReport.WYGText',@Where)>0
     
	  begin 
	  set @strSQL =@strWrittenSQL
	  end
  else
	  begin
	  set @strSQL= @strWrittenSQL +' Union ' +@strUnwrittenSQL 
	  end

  set @strSQL ='select distinct top ' + convert(nvarchar,@topcount)+'*  from (' +@strSQL+   +') a order by tbTeaching__SubmitDt desc'
 --print(@strSQL)    
 exec (@strSQL)
END 
else if @PageIndex = -1
BEGIN 
	set @strWrittenSQL = 'select '+@fields + ', tbTeaching.Submitter as SubmitterGuid '+
      '  from tbTeaching left join tbReport with (nolock) on tbTeaching.ReportGuid = tbReport.ReportGuid ,tbRegPatient,tbRegOrder,tbRegProcedure  where tbReport.ReportGuid =	   tbRegProcedure.ReportGuid and tbRegOrder.OrderGuid = tbRegProcedure.OrderGuid and tbRegPatient.PatientGuid = tbRegOrder.PatientGuid '+@Where 
	  set @strUnwrittenFields =@fields;
	  set @strUnwrittenFields=REPLACE(@strUnwrittenFields,'tbReport.ReportName','''''')
	  set @strUnwrittenFields=REPLACE(@strUnwrittenFields,'tbReport.AccordRate','''''')
	  set @strUnwrittenFields=REPLACE(@strUnwrittenFields,'tbReport.WYSText','''''')
	  set @strUnwrittenFields=REPLACE(@strUnwrittenFields,'tbReport.WYGText','''''')

  set @strUnwrittenSQL='select '+ @strUnwrittenFields +',tbTeaching.Submitter as SubmitterGuid   from tbTeaching, tbRegPatient,tbRegOrder,tbRegProcedure  where	tbRegOrder.OrderGuid = tbRegProcedure.OrderGuid and tbRegPatient.PatientGuid = tbRegOrder.PatientGuid and tbTeaching.ReportGuid=tbRegOrder.OrderGuid' +@where 
  if  charindex('tbReport.AccordRate',@Where)>0  or
	  charindex('tbReport.reportText',@Where)>0 or
      charindex('tbReport.Keyword',@Where)>0 or
      charindex('tbReport.WYSText',@Where)>0 or
      charindex('tbReport.WYGText',@Where)>0
	  begin 
	  set @strSQL =@strWrittenSQL
	  end
  else
	  begin
	  set @strSQL= @strWrittenSQL +' Union ' +@strUnwrittenSQL 
	  end

  set @strSQL ='select count(*)  from (' +@strSQL+   +') a '
 --print(@strSQL)    
 exec (@strSQL)
END 
else if @PageIndex = -2 --search all records
BEGIN

	set @strWrittenSQL = 'select distinct ' + @fields + ', tbTeaching.Submitter as SubmitterGuid '+
	'  from tbTeaching left join tbReport with (nolock) on tbTeaching.ReportGuid = tbReport.ReportGuid ,tbRegPatient,tbRegOrder,tbRegProcedure where tbReport.ReportGuid = tbRegProcedure.ReportGuid and tbRegOrder.OrderGuid = tbRegProcedure.OrderGuid and tbRegPatient.PatientGuid = tbRegOrder.PatientGuid '+@Where 

	set @strUnwrittenFields =@fields;
	set @strUnwrittenFields=REPLACE(@strUnwrittenFields,'tbReport.ReportName','''''')
	set @strUnwrittenFields=REPLACE(@strUnwrittenFields,'tbReport.AccordRate','''''')
	set @strUnwrittenFields=REPLACE(@strUnwrittenFields,'tbReport.WYSText','''''')
	set @strUnwrittenFields=REPLACE(@strUnwrittenFields,'tbReport.WYGText','''''')

	set @strUnwrittenSQL='select '+ @strUnwrittenFields +',tbTeaching.Submitter as SubmitterGuid   from tbTeaching, tbRegPatient,tbRegOrder,tbRegProcedure  where	tbRegOrder.OrderGuid = tbRegProcedure.OrderGuid and tbRegPatient.PatientGuid = tbRegOrder.PatientGuid and tbTeaching.ReportGuid=tbRegOrder.OrderGuid' +@where 

	if  charindex('tbReport.AccordRate',@Where)>0  or
	    charindex('tbReport.reportText',@Where)>0 or
        charindex('tbReport.Keyword',@Where)>0 or
        charindex('tbReport.WYSText',@Where)>0 or
        charindex('tbReport.WYGText',@Where)>0
	  begin 
	  set @strSQL =@strWrittenSQL
	  end
	else
	  begin
	  set @strSQL= @strWrittenSQL +' Union ' +@strUnwrittenSQL 
	  end

	set @strSQL =@strSQL + ' order by tbTeaching__SubmitDt desc'
	--print(@strSQL)    
	exec (@strSQL)
END 
END



GO
/****** Object:  StoredProcedure [dbo].[procGenerateAccNo]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[procGenerateAccNo]
	@locationaccprefix nvarchar(64),
	@modalitytype nvarchar(128),
	@site nvarchar(128),
	@accno nvarchar(128) output,
	@errormsg nvarchar(64)output
as
BEGIN

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
BEGIN TRANSACTION 
DECLARE @LockResult int 
EXECUTE @LockResult = sp_getapplock 
@Resource ='generateaccno', 
@LockMode = 'Exclusive', 
@LockTimeout = -1 

	declare @accNoPolicy as int;
	declare @accNoPrefix as nvarchar(128);
	declare @accNoLength as int;
	declare @sitePrefix as nvarchar(128);
	declare @Domain as nvarchar(128);
	declare @maxCount as int;
	select @Domain = value from tbSystemProfile where Name ='Domain';
	select @accNoPolicy = dbo.fnGetprofilevalue('accnopolicy',@site);
	select @accNoLength = dbo.fnGetprofilevalue('accnolength',@site);
	select @accNoPrefix = dbo.fnGetprofilevalue('accnoprefix',@site);
	select @sitePrefix = dbo.fnGetprofilevalue('siteprefix',@site);
	set @accno = '';
	set @errormsg = '';
	
	set @accno = @sitePrefix + @accNoPrefix;
	if(@accNoPolicy = 1 )
		begin
			set @modalitytype = null;
			set @locationaccprefix = null;
		end
	if(@accNoPolicy = 2 )
		begin
			set @modalitytype = null;
			set @locationaccprefix = null;
			set @accno = @accno + CONVERT(varchar(12),getdate(),112);
		end
	if(@accNoPolicy = 3 or @accNoPolicy = 4 )
		begin
			set @locationaccprefix = null;
			set @accno = @accno + @modalitytype + CONVERT(varchar(12),getdate(),112);
			if(@accNoPolicy = 3)--policy 3 no need judge modalitytype
			set @modalitytype = null;
		end
	if(@accNoPolicy = 5 )
		begin
			set @accno = @accno + isnull(@locationaccprefix,'') + @modalitytype + CONVERT(varchar(12),getdate(),112);
		end
	
	--Site is null
	if (select COUNT(1) from tbIdMaxValue where Tag = 3 and Site = @site and isnull(ModalityType,'') = isnull(@modalitytype,'') and isnull(LocationAccNoPrefix,'') = isnull(@locationaccprefix,'') ) = 0
	begin	
		if(@accNoPolicy = '1')
			begin
				select @maxCount = value from tbIdMaxValue where Tag = 3 and Site is null;
				if(@maxCount is null)--record not exists
					set @errormsg = 'Can not get the accession number max value';
				else
					update tbIdMaxValue set Value = Value +1 where Tag = 3 and Site is null;
			end		
		else--Policy(2~5)
			if(@accNoPolicy = '5') and (select COUNT(1) from tbIdMaxValue where Tag = 3 and Site is null and isnull(ModalityType,'') = isnull(@modalitytype,'') and isnull(LocationAccNoPrefix,'') = isnull(@locationaccprefix,'') ) = 0
				-- record not exists?
				begin--not exits
					--insert by site ?
					if not exists(select 1 from tbSiteProfile where name='AccNoPolicy' and site=@site)
						insert into tbIdMaxValue(tag,value,createdt,modalitytype,locationaccnoprefix,domain) values(3,1,GETDATE(),@modalitytype,@locationaccprefix,@Domain)
					else
						insert into tbIdMaxValue(tag,value,createdt,modalitytype,locationaccnoprefix,domain,site) values(3,1,GETDATE(),@modalitytype,@locationaccprefix,@Domain,@site)				
				end
			else--record exists
				begin
					select @maxCount = value from tbIdMaxValue where Tag = 3 and Site is null and isnull(ModalityType,'') =isnull(@modalitytype,'') and isnull(LocationAccNoPrefix,'') = isnull(@locationaccprefix,'') and CONVERT(date,CreateDt) = CONVERT(date,GETDATE());
					if(@maxCount is null)--createdt not equal today
						update tbIdMaxValue set Value = 1,CreateDt = CONVERT(date,GETDATE()) where Tag = 3 and Site is null and isnull(ModalityType,'') =isnull(@modalitytype,'') and isnull(LocationAccNoPrefix,'') = isnull(@locationaccprefix,'');
					else
						update tbIdMaxValue set Value = Value +1 where Tag = 3 and Site is null and isnull(ModalityType,'') =isnull(@modalitytype,'') and isnull(LocationAccNoPrefix,'') = isnull(@locationaccprefix,'');
				end					
			end
	else--Site exists
		begin
		if(@accNoPolicy = 1)
			begin
				select @maxCount = value from tbIdMaxValue where Tag = 3 and Site =@site;
				if(@maxCount is null)--record not exists
					set @errormsg = 'Can not get the accession number max value';
				else
					update tbIdMaxValue set Value = Value +1 where Tag = 3 and Site =@site;
			end
		else
			begin
				select @maxCount = value from tbIdMaxValue where Tag = 3 and Site = @site and isnull(ModalityType,'') =isnull(@modalitytype,'') and isnull(LocationAccNoPrefix,'') = isnull(@locationaccprefix,'') and CONVERT(date,CreateDt) = CONVERT(date,GETDATE());
				if(@maxCount is null)--createdt not equal today		
					update tbIdMaxValue set Value = 1,CreateDt = CONVERT(date,GETDATE()) where Tag = 3 and Site = @site and isnull(ModalityType,'') = isnull(@modalitytype,'') and isnull(LocationAccNoPrefix,'') = isnull(@locationaccprefix,'');
				else
					update tbIdMaxValue set Value = Value +1 where Tag = 3 and Site = @site and isnull(ModalityType,'') = isnull(@modalitytype,'') and isnull(LocationAccNoPrefix,'') = isnull(@locationaccprefix,'');
			end
		end
		
		if(LEN(@errormsg) = 0)
		begin
			set @maxCount = isnull(@maxCount,0) + 1;
			--append serial number
			if(@accNoPolicy = 1)
				set @accno = @accno + (isnull(replicate('0',@accNoLength - len(isnull(@maxCount ,0))), '')) + cast(@maxCount as nvarchar(64));
			else
			if(@accNoPolicy >= 2 and @accNoPolicy <= 5)
				set @accno = @accno + (isnull(replicate('0',4 - len(isnull(@maxCount ,0))), '')) + cast(@maxCount as nvarchar(64));
		end
	EXECUTE sp_releaseapplock @Resource='generateaccno';
COMMIT TRANSACTION; 
END


GO
/****** Object:  StoredProcedure [dbo].[procGeneratePatientId]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[procGeneratePatientId]
	@site nvarchar(128),
	@patientid nvarchar(128) output,
	@errormsg nvarchar(64)output
as
BEGIN

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
BEGIN TRANSACTION 
DECLARE @LockResult int 
EXECUTE @LockResult = sp_getapplock 
@Resource ='generatepatientid', 
@LockMode = 'Exclusive', 
@LockTimeout = -1 

	declare @patientidLength as int;
	declare @curMaxPID as int;
	declare @patientidPrefix as nvarchar(64);
	set @patientid = '';
	set @errormsg = '';
	select @curMaxPID = value from tbIdMaxValue where Tag = 2 and Site = @site;
	
	if(@curMaxPID is null)
		begin
			select @curMaxPID = value from tbIdMaxValue where Tag = 2 and Site is null;
				if(@curMaxPID is null)
					set @errormsg = 'Can not get the pid max value';
				else
					UPDATE tbIdMaxValue SET Value= Value +1  WHERE Tag=2 and Site is null;
		end
	else
		begin
			UPDATE tbIdMaxValue SET Value= Value + 1 WHERE Tag=2 and Site = @site;
		end
		
	if(len(@errormsg) = 0)
		begin
			set @curMaxPID = @curMaxPID + 1;
			set @patientidPrefix =  dbo.fnGetprofilevalue('patientidprefix',@site);
			set @patientidLength = cast(dbo.fnGetprofilevalue('patientidlength',@site) as int);
			set @patientid = @patientidPrefix + (isnull(replicate('0',@patientidLength - len(isnull(@curMaxPID ,0))), '') + Cast(@curMaxPID as nvarchar(64)));
		end
	EXECUTE sp_releaseapplock @Resource='generatepatientid';
COMMIT TRANSACTION;
END


GO
/****** Object:  StoredProcedure [dbo].[procGetDateTypeAvailableDate]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------
--US26285 设备排班的获取日期类型和有效日期
-----------------------------------------------------
CREATE PROCEDURE [dbo].[procGetDateTypeAvailableDate]
( 
@Modality varchar(256), 
@BookingDate varchar(256),
@DateType varchar(256) output,
@AvailableDate varchar(256) output
)
AS 
BEGIN 
set datefirst 1
declare @Site varchar(256)
declare @CalendarDateType varchar(2)
declare @WorkingCalendarDateType varchar(2)
declare @weekday varchar(2);
set @weekday = DATEPART(WEEKDAY, @BookingDate)+4;

set @Site = (select top 1 site from tbModality where Modality = @Modality)
if exists(select * from tbWorkingCalendar where Date = @BookingDate and Modality = @Modality)
	begin
		set @WorkingCalendarDateType = (select top 1 DateType from tbWorkingCalendar where Date = @BookingDate and Modality = @Modality);
		if @WorkingCalendarDateType='1'
			begin 
				if exists(select top 1 DateType from tbModalityTimeSlice where Modality = @Modality and DateType = @weekday and AvailableDate <= @BookingDate order by AvailableDate desc)
					begin 
						set @DateType=@weekday
					end
				else
					begin 
						set @DateType=@WorkingCalendarDateType
					end
			end
		else if @WorkingCalendarDateType='2'
			begin 
				if exists(select top 1 DateType from tbModalityTimeSlice where Modality = @Modality and DateType = @weekday and AvailableDate <= @BookingDate order by AvailableDate desc)
					begin 
						set @DateType=@weekday
					end
				else
					begin 
						set @DateType=@WorkingCalendarDateType
					end
			end
		else
			begin 
				set @DateType=@WorkingCalendarDateType
			end 
	end
else if exists(select * from tbWorkingCalendar where Date = @BookingDate and Modality = '' and Site = @Site)
	begin
		set @WorkingCalendarDateType = (select top 1 DateType from tbWorkingCalendar where Date = @BookingDate and Modality = '' and Site = @Site);
		if @WorkingCalendarDateType='1'
			begin 
				if exists(select top 1 DateType from tbModalityTimeSlice where Modality = @Modality and DateType = @weekday and AvailableDate <= @BookingDate order by AvailableDate desc)
					begin 
						set @DateType=@weekday
					end
				else
					begin 
						set @DateType=@WorkingCalendarDateType
					end
			end
		else if @WorkingCalendarDateType='2'
			begin 
				if exists(select top 1 DateType from tbModalityTimeSlice where Modality = @Modality and DateType = @weekday and AvailableDate <= @BookingDate order by AvailableDate desc)
					begin 
						set @DateType=@weekday
					end
				else
					begin 
						set @DateType=@WorkingCalendarDateType
					end
			end
		else
			begin 
				set @DateType=@WorkingCalendarDateType
			end 
	end
else if exists(select * from tbWorkingCalendar where Date = @BookingDate and Modality = '' and Site = '')
	begin
		set @WorkingCalendarDateType = (select top 1 DateType from tbWorkingCalendar where Date = @BookingDate and Modality = '' and Site = '');
		if @WorkingCalendarDateType='1'
			begin 
				if exists(select top 1 DateType from tbModalityTimeSlice where Modality = @Modality and DateType = @weekday and AvailableDate <= @BookingDate order by AvailableDate desc)
					begin 
						set @DateType=@weekday
					end
				else
					begin 
						set @DateType=@WorkingCalendarDateType
					end
			end
		else if @WorkingCalendarDateType='2'
			begin 
				if exists(select top 1 DateType from tbModalityTimeSlice where Modality = @Modality and DateType = @weekday and AvailableDate <= @BookingDate order by AvailableDate desc)
					begin 
						set @DateType=@weekday
					end
				else
					begin 
						set @DateType=@WorkingCalendarDateType
					end
			end
		else
			begin 
				set @DateType=@WorkingCalendarDateType
			end 
	end
else
	begin
	set @weekday = DATEPART(WEEKDAY, @BookingDate);
	set @CalendarDateType=cast(@weekday as int)+4;
	if exists(select top 1 DateType from tbModalityTimeSlice where Modality = @Modality and DateType = @CalendarDateType and AvailableDate <= @BookingDate order by AvailableDate desc)
		begin 
			set @DateType=@CalendarDateType
		end
	else
		begin
			if (cast(@CalendarDateType as int)>9 )
				begin 
					set @DateType='2'
				end
			else
				begin
					set @DateType='1'
				end
		end
	
end

set @AvailableDate = '';
set @AvailableDate = (select top 1 AvailableDate from tbModalityTimeSlice where Modality = @Modality and DateType = @DateType and AvailableDate <= @BookingDate order by AvailableDate desc);
END 



GO
/****** Object:  StoredProcedure [dbo].[procGetDefaultModalityTimeSlice]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procGetDefaultModalityTimeSlice]
( 
@Modality varchar(256),
@ModalityType varchar(256), 
@PatientGuid varchar(128),
@BookingSite varchar(256),
@Radiography int,
@TryDays int,
@ProcedureCode NVARCHAR(MAX),       -- 2015-06-05, Oscar added (US25193), split by '|' if there are multiple items.
@RPDesc NVARCHAR(MAX),      -- 2015-06-05, Oscar added (US25193), split by '|' if there are multiple items.
@ErrorMsg varchar(256) output
)
AS 
BEGIN 
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
BEGIN TRANSACTION 
DECLARE @LockResult int 
EXECUTE @LockResult = sp_getapplock 
@Resource ='LockModalityQuota', 
@LockMode = 'Exclusive', 
@LockTimeout = -1 

set @ErrorMsg ='';
declare @LockGuid varchar(256);
set @LockGuid ='';

declare @maxBookingDays int;
set @maxBookingDays = (select Top 1 Value from tbSystemProfile where Name = 'MaxBookingDays');
declare @BookingDate varchar(256);
set @BookingDate = Convert(varchar(10),getdate(),120);--today
declare @MaxBookDate varchar(256);
if @maxBookingDays = 0
begin
set @MaxBookDate = '9999-01-01';
end
else
begin
set @MaxBookDate = Convert(varchar(10),DATEADD(dd,@maxBookingDays,getdate()),120);
end
declare @DateType varchar(256);
declare @AvailableDate varchar(256);
declare @flag int
set @flag = 0;
declare @groupid varchar(256);
set @groupid ='';
declare @lockedDate varchar(256);
declare @timeSliceGuid varchar(256);

--check if having clinical booking share
if exists (select 1 from tbModalityShare s inner join tbModalityTimeSlice t on s.TimeSliceGuid = t.TimeSliceGuid where ShareTarget = @BookingSite and TargetType = 1  and AvailableCount > 0 and (Date > @BookingDate or (Date = @BookingDate and t.StartDt >= (Convert(varchar(10),'2008-08-08',23)+' '+Convert(varchar(10),GETDATE(),24)) )))
begin
set @flag = 1;
end
else if exists (select 1 from tbModalityShare s inner join tbModalityTimeSlice t on s.TimeSliceGuid = t.TimeSliceGuid where ShareTarget = @BookingSite and TargetType = 1  and AvailableCount > 0 and Date is null and t.AvailableDate in (select MAX(AvailableDate) from tbModalityTimeSlice where AvailableDate <= @BookingDate group by Modality, DateType))
begin
set @flag =1;
end
else if exists (select 1 from tbModalityShare s inner join tbModalityTimeSlice t on s.TimeSliceGuid = t.TimeSliceGuid where ShareTarget = @BookingSite and TargetType = 1  and AvailableCount > 0 and Date is null and t.AvailableDate > @BookingDate)
begin
set @flag =1;
end

if @flag = 1
begin

while @BookingDate <= @MaxBookDate and @LockGuid = '' and @flag <= @TryDays
begin

if @ModalityType = 'US' or (not exists(select 1 from tbRegProcedure p inner join tbRegOrder o on p.OrderGuid = o.OrderGuid and p.Status = 10 and o.PatientGuid = @PatientGuid and p.ModalityType = @ModalityType where Convert(varchar(10),BookingBeginDt,120) = @BookingDate))
begin

execute procGetDateTypeAvailableDate @modality, @BookingDate, @DateType output,@AvailableDate output;
--generate modalityshare copy
if not exists(select 1 from tbModalityTimeSlice a inner join tbModalityShare b on a.TimeSliceGuid = b.TimeSliceGuid where a.Modality = @Modality  and b.Date = @BookingDate)
begin
insert into tbModalityShare select NEWID(),TimeSliceGuid,ShareTarget,TargetType,MaxCount,AvailableCount,GroupId,@BookingDate from tbModalityShare where Date is null and TimeSliceGuid in (select TimeSliceGuid  from tbModalityTimeSlice where Modality = @Modality and AvailableDate = @AvailableDate and DateType = @DateType);
end
else if exists(select 1 from tbModalityTimeSlice a inner join tbModalityShare b on a.TimeSliceGuid = b.TimeSliceGuid where a.Modality = @Modality and b.Date = @BookingDate and (a.AvailableDate <> @AvailableDate or a.DateType <> @DateType) and b.AvailableCount = b.MaxCount)
begin
delete from tbModalityShare where Guid in (select b.Guid from tbModalityTimeSlice a inner join tbModalityShare b on a.TimeSliceGuid = b.TimeSliceGuid where a.Modality = @Modality  and b.Date = @BookingDate);
insert into tbModalityShare select NEWID(),TimeSliceGuid,ShareTarget,TargetType,MaxCount,AvailableCount,GroupId,@BookingDate from tbModalityShare where Date is null and TimeSliceGuid in (select TimeSliceGuid  from tbModalityTimeSlice where Modality = @Modality and AvailableDate = @AvailableDate and DateType = @DateType);
end

if @flag = 1
begin
--try to lock today
update tbModalityShare set AvailableCount = AvailableCount - 1, @groupid = GroupId, @lockedDate= Date, @timeSliceGuid = TimeSliceGuid, @LockGuid = Guid where Guid = (
select top 1 s.Guid from tbModalityShare s inner join tbModalityTimeSlice t on s.TimeSliceGuid = t.TimeSliceGuid where t.Modality = @Modality and ShareTarget = @BookingSite and TargetType = 1  and AvailableCount > 0 and Date = @BookingDate and t.StartDt >= (Convert(varchar(10),'2008-08-08',23)+' '+Convert(varchar(10),GETDATE(),24)) order by t.StartDt, s.GroupId)
end
else
begin
--try to lock
update tbModalityShare set AvailableCount = AvailableCount - 1, @groupid = GroupId, @lockedDate= Date, @timeSliceGuid = TimeSliceGuid, @LockGuid = Guid where Guid = (
select top 1 s.Guid from tbModalityShare s inner join tbModalityTimeSlice t on s.TimeSliceGuid = t.TimeSliceGuid where t.Modality = @Modality and  ShareTarget = @BookingSite and TargetType = 1  and AvailableCount > 0 and Date = @BookingDate order by t.StartDt, s.GroupId)
end
--ct and mr cannot same day -- radiography must be last booking by date
if (@LockGuid <> '')
begin
if (@Radiography = 1)--Radiography
begin
if exists(select 1 from tbRegProcedure p inner join tbProcedureCode c on p.ProcedureCode = c.ProcedureCode and p.Status = 10 and p.BookingBeginDt > Convert(varchar(10),@BookingDate,120)+' 00:00:00' and c.Radiography = 0 inner join tbRegOrder o on p.OrderGuid = o.OrderGuid  and o.PatientGuid = @PatientGuid )
begin
update tbModalityShare set AvailableCount = AvailableCount + 1 where Guid = @LockGuid;
set @LockGuid = '';
set @errorMsg = 'There is no available quota after your non-radiography examination booking';
end
else if ((@ModalityType = 'CT' and exists(select * from tbRegProcedure p inner join tbRegOrder o on p.OrderGuid = o.OrderGuid and o.PatientGuid = @PatientGuid and p.Status = 10 and p.ModalityType = 'MR' and p.BookingBeginDt > Convert(varchar(10),@BookingDate,120)+' 00:00:00' and p.BookingBeginDt < Convert(varchar(10),@BookingDate,120)+' 23:23:59')) or (@ModalityType = 'MR' and exists(select * from tbRegProcedure p inner join tbRegOrder o on p.OrderGuid = o.OrderGuid and o.PatientGuid = @PatientGuid and p.Status = 10 and p.ModalityType = 'CT' and p.BookingBeginDt > Convert(varchar(10),@BookingDate,120)+' 00:00:00' and p.BookingBeginDt < Convert(varchar(10),@BookingDate,120)+' 23:23:59')))
begin
update tbModalityShare set AvailableCount = AvailableCount + 1 where Guid = @LockGuid;
set @LockGuid = '';
set @errorMsg = 'There is no available quota since CT and MR cannot be booked at same day';
end
end
else --not Radiography
begin
if exists(select 1 from tbRegProcedure p inner join tbProcedureCode c on p.ProcedureCode = c.ProcedureCode and p.Status = 10 and p.BookingBeginDt < Convert(varchar(10),@BookingDate,120)+' 23:23:59' and c.Radiography = 1 inner join tbRegOrder o on p.OrderGuid = o.OrderGuid  and o.PatientGuid = @PatientGuid )
begin
update tbModalityShare set AvailableCount = AvailableCount + 1 where Guid = @LockGuid;
set @LockGuid = '';
set @errorMsg = 'There is no available quota before your radiography examination booking';
set @MaxBookDate = @BookingDate;
end
else if ((@ModalityType = 'CT' and exists(select * from tbRegProcedure p inner join tbRegOrder o on p.OrderGuid = o.OrderGuid and o.PatientGuid = @PatientGuid and p.Status = 10 and p.ModalityType = 'MR' and p.BookingBeginDt > Convert(varchar(10),@BookingDate,120)+' 00:00:00' and p.BookingBeginDt < Convert(varchar(10),@BookingDate,120)+' 23:23:59')) or (@ModalityType = 'MR' and exists(select * from tbRegProcedure p inner join tbRegOrder o on p.OrderGuid = o.OrderGuid and o.PatientGuid = @PatientGuid and p.Status = 10 and p.ModalityType = 'CT' and p.BookingBeginDt > Convert(varchar(10),@BookingDate,120)+' 00:00:00' and p.BookingBeginDt < Convert(varchar(10),@BookingDate,120)+' 23:23:59')))
begin
update tbModalityShare set AvailableCount = AvailableCount + 1 where Guid = @LockGuid;
set @LockGuid = '';
set @errorMsg = 'There is no available quota since CT and MR cannot be booked at same day';
end
end
end
end

set @BookingDate = Convert(varchar(10),DATEADD(dd,1,@BookingDate),120);
set @flag = @flag + 1;
end
end

if(@LockGuid<>'')
begin
set @ErrorMsg = '';
if(@groupid <> '')
begin
update tbModalityShare set AvailableCount = AvailableCount - 1 where GroupId = @groupid and Date = @lockedDate and TimeSliceGuid = @timeSliceGuid and Guid <> @LockGuid;
end
end
else
begin
set @errorMsg = 'There is no available quota';
end

select s.*,t.StartDt,t.EndDt,t.Modality,t.ModalityType,t.DateType,t.AvailableDate,t.Description from tbModalityShare s inner join tbModalityTimeSlice t on s.TimeSliceGuid = t.TimeSliceGuid and s.Guid = @LockGuid;

EXECUTE sp_releaseapplock @Resource='LockModalityQuota' 
COMMIT TRANSACTION 
END 


GO
/****** Object:  StoredProcedure [dbo].[procGetMatchedDoctors]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[procGetMatchedDoctors]
@ModalityType nvarchar(max),
@Site nvarchar(max),
@PatientType nvarchar(max),
@ExamSystem nvarchar(max),
@WorkTime datetime, ---whether doctor is on work at this time
@SampleDoctor nvarchar(max),---'cd6a32d1-7160-4dec-a2cd-c83983dbb2e2,82aa8234-0b0c-4510-b50f-36c63abe2ca9' ,comma by ,
@ReportType nvarchar(32), -----UnwrittenReport or UnapprovedReport
@Doctors nvarchar(max) output

as 
begin

declare @sqlCondition nvarchar(max)
set @sqlCondition=' 1=1 '
set @Doctors=''
/**
if LTRIM(RTRIM(@SampleDoctor)) = ''
begin
	return
end
**/
if LTRIM(RTRIM(@ModalityType)) <> ''
	set @sqlCondition =@sqlCondition + ' and (PREFERRED_MODALITY_TYPE Like ''%'+LTRIM(RTRIM(@ModalityType))+'%'' or PREFERRED_MODALITY_TYPE='''')'

if	LTRIM(RTRIM(@PatientType)) <> ''
	set @sqlCondition =@sqlCondition+ ' and (PREFERRED_PATIENT_TYPE Like ''%'+LTRIM(RTRIM(@PatientType))+'%'' or PREFERRED_PATIENT_TYPE='''')'

if	LTRIM(RTRIM(@ExamSystem)) <> ''
	set @sqlCondition =@sqlCondition+ ' and (PREFERRED_PHYSIOLOGICAL_SYSTEM Like ''%'+LTRIM(RTRIM(@ExamSystem))+'%'' or PREFERRED_PHYSIOLOGICAL_SYSTEM='''')'
		
if	LTRIM(RTRIM(@Site)) <> ''
	set @sqlCondition =@sqlCondition+ ' and (Preferred_Site Like ''%'+LTRIM(RTRIM(@Site))+'%'' or Preferred_Site = '''')'

if	@WorkTime is not null
	set @sqlCondition =@sqlCondition+ ' and BeginDateTime <= '''+Cast(@worktime as nvarchar(32)) +''' and EndDateTime >='''+ Cast(@worktime as nvarchar(32))+''''

if	LTRIM(RTRIM(@ReportType)) <> ''
	set @sqlCondition =@sqlCondition+ ' and ReportType = '''+LTRIM(RTRIM(@ReportType))+''''


--set @sqlCondition =@sqlCondition+ ' and DOCTOR_GUID in  (select string from  fnStrSplit('''+LTRIM(RTRIM(@SampleDoctor))+''','',''))'

print 'select DOCTOR_GUID from tbReportDoctor where '+ @sqlCondition

create table #tmpDoctorID (DOCTOR_GUID nvarchar(128))
exec ('insert into #tmpDoctorID(DOCTOR_GUID) select DOCTOR_GUID from tbReportDoctor where '+ @sqlCondition)

select @Doctors=@Doctors+DOCTOR_GUID+',' from #tmpDoctorID
drop table #tmpDoctorID


if LEN(isnull(@Doctors,''))>0
	set @Doctors =SUBSTRING(@Doctors,1,Len(@Doctors)-1)  --erase ','
 
end


GO
/****** Object:  StoredProcedure [dbo].[procGetPatientExamNo]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--===========================================================
--Description: 修正[Defect]100015345,创建时间格式问题
--===========================================================
CREATE PROCEDURE [dbo].[procGetPatientExamNo]  
	@PatientID nvarchar (128),  
	@OrderGuid nvarchar (128)  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;
 declare @sql nvarchar(4000)
   
 declare @Patientguid nvarchar(128) 
 declare @Createdt datetime
 select @Patientguid=patientguid from tbRegPatient where PatientID=@PatientID
 select @Createdt=CreateDt from tbRegOrder where OrderGuid=@OrderGuid

 set @sql ='select count(1) from tbRegOrder  where PatientGuid ='''+ @patientguid+ '''	and CreateDt <= '''+Convert(nvarchar, @Createdt, 120) + ''''

 exec(@sql)  
END  


GO
/****** Object:  StoredProcedure [dbo].[procGetPrintTemplate]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procGetPrintTemplate]
    @AccNo varchar(128),
    @Type int,
	@ModalityType varchar(128),
	@Site varchar(64),
	@ReportGuid varchar(128),
	@TemplateGuid varchar(128) output,
	@MergeMultiProcedures int output--Merge multiple procedures to one row to print; 0--NO; 1--YES 
AS
BEGIN	

set @TemplateGuid = '';
declare @sql varchar(max);
declare @Temp varchar(128);
declare @OldTemplateGuid varchar(128);

if @Type = 3 --report
begin
	   
declare my_Cusror1 cursor local FOR select tbReport.FirstApproveSite,tbReport.PrintTemplateGuid from tbReport,tbRegProcedure , tbRegOrder where tbRegOrder.OrderGuid = tbRegProcedure.OrderGuid and tbRegProcedure.ReportGuid = tbReport.ReportGuid and tbRegOrder.AccNo = @AccNo;
OPEN my_Cusror1
FETCH NEXT FROM my_Cusror1 into @Temp,@OldTemplateGuid		   

-- ==============================================================================================================================
-- Description:将firstapprovesite,secondapprovesite,submitsite,rejectsite,bookingsite,examsite,ordersite,patientsite 从value改成alias 即EASTRJ改为东院诸如此类
-- ==============================================================================================================================
set @sql = 'select  tbRegOrder.OrderGuid as tbRegOrder__OrderGuid,tbRegOrder.AccNo as tbRegOrder__AccNo, tbRegOrder.ApplyDept as tbRegOrder__ApplyDept,  tbRegOrder.ApplyDoctor as tbRegOrder__ApplyDoctor, tbRegOrder.IsScan as tbRegOrder__IsScan,  tbRegOrder.Comments as tbRegOrder__Comments, tbRegOrder.RemoteAccNo as tbRegOrder__RemoteAccNo, tbRegOrder.TotalFee as tbRegOrder__TotalFee,tbRegOrder.InitialDomain as tbRegOrder__InitialDomain, tbRegOrder.HisID as tbRegOrder__HisID, tbRegOrder.CardNo as tbRegOrder__CardNo, tbRegPatient.MedicareNo as tbRegPatient__MedicareNo,tbRegOrder.ReferralId as tbRegOrder__ReferralId,tbRegOrder.IsReferral as tbRegOrder__IsReferral,  tbRegPatient.PatientGuid as tbRegPatient__PatientGuid,tbRegPatient.GlobalID as tbRegPatient__GlobalID, tbRegPatient.PatientID as tbRegPatient__PatientID, tbRegPatient.LocalName as tbRegPatient__LocalName,  tbRegPatient.EnglishName as tbRegPatient__EnglishName, tbRegPatient.ReferenceNo as tbRegPatient__ReferenceNo, tbRegPatient.Birthday as tbRegPatient__Birthday, tbRegPatient.Gender as tbRegPatient__Gender, tbRegPatient.Address as tbRegPatient__Address, tbRegPatient.Telephone as tbRegPatient__Telephone,  tbRegPatient.IsVIP as tbRegPatient__IsVIP, tbRegPatient.Comments as tbRegPatient__Comments, tbRegPatient.RemotePID as tbRegPatient__RemotePID,  tbRegPatient.CreateDt as tbRegPatient__CreateDt,  tbRegProcedure.ProcedureGuid as tbRegProcedure__ProcedureGuid, tbRegProcedure.ProcedureCode as tbRegProcedure__ProcedureCode, tbRegProcedure.ExamSystem as tbRegProcedure__ExamSystem, tbRegProcedure.WarningTime as tbRegProcedure__WarningTime, tbRegProcedure.FilmSpec as tbRegProcedure__FilmSpec, tbRegProcedure.FilmCount as tbRegProcedure__FilmCount, tbRegProcedure.ContrastName as tbRegProcedure__ContrastName, tbRegProcedure.ContrastDose as tbRegProcedure__ContrastDose,  tbRegProcedure.ImageCount as tbRegProcedure__ImageCount, tbRegProcedure.ExposalCount as tbRegProcedure__ExposalCount, tbRegProcedure.Deposit as tbRegProcedure__Deposit,  tbRegProcedure.Charge as tbRegProcedure__Charge, tbRegProcedure.ModalityType as tbRegProcedure__ModalityType, tbRegProcedure.Modality as tbRegProcedure__Modality,  tbRegProcedure.Registrar as tbRegProcedure__Registrar, tbRegProcedure.RegisterDt as tbRegProcedure__RegisterDt, tbRegProcedure.Priority as tbRegProcedure__Priority, tbRegProcedure.Technician as tbRegProcedure__Technician, tbRegProcedure.TechDoctor as tbRegProcedure__TechDoctor, tbRegProcedure.TechNurse as tbRegProcedure__TechNurse,  tbRegProcedure.OperationStep as tbRegProcedure__OperationStep, tbRegProcedure.ExamineDt as tbRegProcedure__ExamineDt, tbRegProcedure.Mender as tbRegProcedure__Mender,  tbRegProcedure.ModifyDt as tbRegProcedure__ModifyDt, tbRegProcedure.IsExistImage as tbRegProcedure__IsExistImage, tbRegProcedure.Status as tbRegProcedure__Status,  tbRegProcedure.Comments as tbRegProcedure__Comments,  tbRegProcedure.IsCharge as tbRegProcedure__IsCharge, tbRegProcedure.RemoteRPID as tbRegProcedure__RemoteRPID,  tbRegProcedure.QueueNo as tbRegProcedure__QueueNo, tbRegProcedure.CreateDt as tbRegProcedure__CreateDt, tbRegOrder.VisitGuid as tbRegOrder__VisitGuid,   tbRegProcedure.Posture as tbRegProcedure__Posture, tbRegProcedure.MedicineUsage as tbRegProcedure__MedicineUsage,   tbRegOrder.InhospitalNo as tbRegOrder__InhospitalNo, tbRegOrder.ClinicNo as tbRegOrder__ClinicNo, tbRegOrder.PatientType as tbRegOrder__PatientType, tbRegOrder.Observation as tbRegOrder__Observation,tbRegOrder.Optional2 as tbRegOrder__Inspection,  tbRegOrder.HealthHistory as tbRegOrder__HealthHistory, tbRegOrder.InhospitalRegion as tbRegOrder__InhospitalRegion, tbRegOrder.BedNo as tbRegOrder__BedNo,tbRegOrder.BedSide as tbRegOrder__BedSide, tbRegOrder.CreateDt as tbRegOrder__CreateDt,  tbRegOrder.CurrentAge as tbRegOrder__CurrentAge,tbRegOrder.VisitComment as tbRegOrder__VisitComment,tbRegOrder.ChargeType as tbRegOrder__ChargeType, tbReport.ReportGuid as tbReport__ReportGuid,  tbReport.ReportName as tbReport__ReportName, tbReport.WYS as tbReport__WYS, tbReport.WYG as tbReport__WYG, tbReport.AppendInfo as tbReport__AppendInfo, tbReport.TechInfo as tbReport__TechInfo,   tbReport.ReportText as tbReport__ReportText, tbReport.DoctorAdvice as tbReport__DoctorAdvice, tbReport.IsPositive as tbReport__IsPositive, tbReport.AcrCode as tbReport__AcrCode,   tbReport.AcrAnatomic as tbReport__AcrAnatomic, tbReport.AcrPathologic as tbReport__AcrPathologic,tbReport.CreateDt as tbReport__CreateDt, 
(case when tbReport.CreaterName IS NULL or tbReport.CreaterName = '''' then tbReport.Creater else tbReport.CreaterName end) as tbReport__Creater,
(case when tbReport.SubmitterName IS NULL or tbReport.SubmitterName = '''' then tbReport.Submitter else tbReport.SubmitterName end) as tbReport__Submitter,
tbReport.SubmitDt as tbReport__SubmitDt, tbReport.FirstApprover as tbReport__FirstApprover, tbReport.FirstApproveDt as tbReport__FirstApproveDt, tbReport.SecondApprover as tbReport__SecondApprover,   tbReport.SecondApproveDt as tbReport__SecondApproveDt, tbReport.IsDiagnosisRight as tbReport__IsDiagnosisRight, tbReport.KeyWord as tbReport__KeyWord, tbReport.ReportQuality as tbReport__ReportQuality,   tbReport.RejectToObject as tbReport__RejectToObject, tbReport.Rejecter as tbReport__Rejecter, tbReport.RejectDt as tbReport__RejectDt, tbReport.Status as tbReport__Status,   tbReport.Comments as tbReport__Comments, tbReport.DeleteMark as tbReport__DeleteMark, tbReport.Deleter as tbReport__Deleter,   tbReport.DeleteDt as tbReport__DeleteDt, tbReport.Recuperator as tbReport__Recuperator, tbReport.ReconvertDt as tbReport__ReconvertDt, tbReport.Mender as tbReport__Mender,   tbReport.ModifyDt as tbReport__ModifyDt, tbReport.IsPrint as tbReport__IsPrint, tbReport.CheckItemName as tbReport__CheckItemName, tbReport.Optional1 as tbReport__Optional1,   tbReport.Optional2 as tbReport__Optional2, tbReport.Optional3 as tbReport__Optional3, tbReport.IsLeaveWord as tbReport__IsLeaveWord, tbReport.WYSText as tbReport__WYSText,   tbReport.WYGText as tbReport__WYGText, tbReport.IsDraw as tbReport__IsDraw, tbReport.DrawerSign as tbReport__DrawerSign, tbReport.DrawTime as tbReport__DrawTime,   tbReport.IsLeaveSound as tbReport__IsLeaveSound, tbReport.TakeFilmDept as tbReport__TakeFilmDept, tbReport.TakeFilmRegion as tbReport__TakeFilmRegion,   tbReport.PrintTemplateGuid as tbReport__PrintTemplateGuid, tbReport.Domain as tbReport__Domain,  tbReport.TakeFilmComment as tbReport__TakeFilmComment, tbReport.RebuildMark as tbReport__RebuildMark,   tbProcedureCode.ProcedureCode as tbProcedureCode__ProcedureCode, tbProcedureCode.Description as tbProcedureCode__Description,   tbProcedureCode.EnglishDescription as tbProcedureCode__EnglishDescription, tbProcedureCode.ModalityType as tbProcedureCode__ModalityType,   tbProcedureCode.BodyPart as tbProcedureCode__BodyPart, tbProcedureCode.CheckingItem as tbProcedureCode__CheckingItem,   tbProcedureCode.BodyCategory as tbProcedureCode__BodyCategory,   tbReport.SubmitDomain as tbReport__SubmitDomain,   tbReport.RejectDomain as tbReport__RejectDomain,   tbReport.FirstApproveDomain as tbReport__FirstApproveDomain,   tbRegPatient.Alias as tbRegPatient__Alias,   tbRegPatient.ParentName as tbRegPatient__ParentName,   tbRegOrder.curPatientName as tbRegOrder__curPatientName,tbRegOrder.BodyWeight as tbRegOrder__BodyWeight,  tbRegOrder.curGender as tbRegOrder__curGender, tbRegOrder.IsCharge as tbRegOrder__IsCharge,  tbRegOrder.AgeInDays as tbRegOrder__AgeInDays, tbRegProcedure.Booker as tbRegProcedure__Booker,  tbRegProcedure.BookingBeginDt as tbRegProcedure__BookingBeginDt, tbRegProcedure.BookingEndDt as tbRegProcedure__BookingEndDt  ,(select Alias from tbSiteList where Site = tbRegOrder.BookingSite) AS tbRegOrder__BookingSite, (select Alias from tbSiteList where Site = tbRegOrder.ExamSite) AS tbRegOrder__ExamSite,(select Alias from tbSiteList where Site = tbRegOrder.RegSite) AS tbRegOrder__RegSite, (select Alias from tbSiteList where Site = tbRegPatient.Site) AS tbRegPatient__Site, (select Alias from tbSiteList where Site = tbReport.FirstApproveSite) AS tbReport__FirstApproveSite,(select Alias from tbSiteList where Site = tbReport.RejectSite) AS tbReport__RejectSite,(select Alias from tbSiteList where Site = tbReport.SecondApproveSite) AS tbReport__SecondApproveSite,(select Alias from tbSiteList where Site = tbReport.SubmitSite) AS tbReport__SubmitSite  , tbRegOrder.ThreeDRebuild AS tbRegOrder__ThreeDRebuild  , tbReport.ReportQuality2 as tbReport__ReportQuality2  , tbRegOrder.ORDERMESSAGE as TBREGORDER__ORDERMESSAGE  , tbRegOrder.PathologicalFindings as TBREGORDER__PathologicalFindings  , tbRegOrder.InternalOptional1 as TBREGORDER__InternalOptional1  , tbRegOrder.InternalOptional2 as TBREGORDER__InternalOptional2  , tbRegOrder.ExternalOptional1 as TBREGORDER__ExternalOptional1  , tbRegOrder.ExternalOptional2 as TBREGORDER__ExternalOptional2  , tbRegOrder.ExternalOptional3 as TBREGORDER__ExternalOptional3 , tbReport.ReportQualityComments as tbReport__ReportQualityComments,tbReport.FirstApproverName as tbReport__FirstApproverName, tbReport.SecondApproverName as tbReport__SecondApproverName, tbRegProcedure.BookerName as tbRegProcedure__BookerName, tbRegProcedure.RegistrarName as tbRegProcedure__RegistrarName, tbRegProcedure.TechnicianName as tbRegProcedure__TechnicianName, tbRegProcedure.UnwrittenCurrentOwner as tbRegProcedure__UnwrittenCurrentOwner, tbRegProcedure.UnapprovedCurrentOwner as tbRegProcedure__UnapprovedCurrentOwner, tbReport.MenderName as tbReport__MenderName, tbRegOrder.InjectDose as tbRegOrder__InjectDose, tbRegOrder.InjectTime as tbRegOrder__InjectTime, tbRegOrder.BodyHeight as tbRegOrder__BodyHeight, tbRegOrder.BloodSugar as tbRegOrder__BloodSugar, tbRegOrder.Insulin as tbRegOrder__Insulin, tbRegOrder.GoOnGoTime as tbRegOrder__GoOnGoTime, tbRegOrder.InjectorRemnant as tbRegOrder__InjectorRemnant, tbRegOrder.SubmitHospital as tbRegOrder__SubmitHospital, tbRegOrder.SubmitDept as tbRegOrder__SubmitDept, tbRegOrder.SubmitDoctor as tbRegOrder__SubmitDoctor , tbRegOrder.Optional1 as TBREGORDER__Optional1  , tbRegOrder.Optional2 as TBREGORDER__Optional2  , tbRegOrder.Optional3 as TBREGORDER__Optional3   from tbRegPatient, tbRegOrder, tbProcedureCode, tbRegProcedure  left join tbReport with (nolock) on tbRegProcedure.reportGuid = tbReport.reportGuid  where tbRegPatient.PatientGuid = tbRegOrder.PatientGuid  and tbRegOrder.OrderGuid = tbRegProcedure.OrderGuid  and tbRegProcedure.ProcedureCode = tbProcedureCode.ProcedureCode  and tbRegOrder.ACCNo = ''';

if @ReportGuid=''
begin
set @sql = @sql + @AccNo + '''';
end
else
begin
set @sql = @sql + @AccNo + '''' + ' and tbReport.ReportGuid = ''' +@ReportGuid+'''';
end
end
else
begin

set @MergeMultiProcedures = 1;

--set tbRegProcedure.BookingNotice using the unique bookingNotice template if tbRegProcedure.BookingNotice is null
set @sql = 'update tbRegProcedure set tbRegProcedure.BookingNotice = (select top 1 tbBookingNoticeTemplate.BookingNotice from tbBookingNoticeTemplate,tbProcedureCode  where tbBookingNoticeTemplate.Guid = tbProcedureCode.BookingNotice and tbProcedureCode.ProcedureCode = tbRegProcedure.ProcedureCode) where (tbRegProcedure.BookingNotice ='''' or tbRegProcedure.BookingNotice is null) and tbRegProcedure.OrderGuid in (select OrderGuid from tbRegOrder where AccNo = ''' + @AccNo + ''')'; 
execute (@sql);

set @sql = 'select tbRegProcedure.BookingNotice as BookingNotice,  tbModality.Room as Room,tbRegPatient.PatientID as PatientID,LocalName as LocalName,tbRegPatient.EnglishName as EnglishName,tbRegPatient.Birthday as Birthday,tbRegPatient.Gender as Gender,tbRegPatient.Telephone as Telephone,tbRegPatient.ReferenceNo as ReferenceNo,Address as Address,tbRegOrder.InhospitalNo as InhospitalNo,tbRegOrder.PatientType as PatientType,tbRegOrder.ClinicNo as ClinicNo,tbRegOrder.BedNo as BedNo,tbRegOrder.InhospitalRegion as InhospitalRegion,tbRegOrder.ApplyDoctor as ApplyDoctor,tbRegOrder.ApplyDept as ApplyDept, tbRegProcedure.RegisterDt as RegisterDt,tbProcedureCode.Description as Description,tbRegProcedure.ModalityType as ModalityType,tbRegProcedure.Modality as Modality,tbProcedureCode.BodyPart as BodyPart,tbProcedureCode.CheckingItem as CheckingItem,tbRegProcedure.BookingBeginDt as BookingBeginDt,tbRegProcedure.BookingEndDt as BookingEndDt  ,tbRegOrder.VisitComment as VisitComment,tbRegOrder.HealthHistory as HealthHistory,tbRegOrder.Observation as Observation,tbRegPatient.Alias as Alias,tbRegProcedure.QueueNo as QueueNo,tbRegPatient.RemotePID as RemotePID,tbRegOrder.HisID as HisID,tbRegOrder.RemoteAccNo as RemoteAccNo,tbRegOrder.CardNo as CardNo,tbRegPatient.MedicareNo as MedicareNo,tbRegOrder.Bedside as BedSide,tbRegOrder.BodyWeight as BodyWeight,tbRegProcedure.BookingTimeAlias as BookingTimeAlias,tbRegOrder.CurrentAge as Age,tbRegOrder.Comments as OrderComment,tbRegOrder.ErethismType  as ErethismType ,tbRegOrder.ErethismCode as ErethismCode,tbRegOrder.ErethismGrade as ErethismGrade,tbRegOrder.Optional1 as OrderOptional1,tbRegOrder.TakeReportDate as TakeReportDate from tbModality,tbRegPatient, tbRegOrder, tbProcedureCode, tbRegProcedure  left join tbReport with (nolock) on tbRegProcedure.reportGuid = tbReport.reportGuid  where tbRegPatient.PatientGuid = tbRegOrder.PatientGuid  and tbRegOrder.OrderGuid = tbRegProcedure.OrderGuid  and tbRegProcedure.ProcedureCode = tbProcedureCode.ProcedureCode  and tbRegProcedure.Modality = tbModality.Modality  and tbRegOrder.ACCNo = ''' + @AccNo + '''';
end	   

--added 2014-1-23 to check if OldTemplateGuid exists in tbPrintTemplate
set @OldTemplateGuid=( select TemplateGuid from tbPrintTemplate where TemplateGuid=@OldTemplateGuid)

-----------------------------------

if (@OldTemplateGuid is not null and @OldTemplateGuid <> '')
begin
set @TemplateGuid = @OldTemplateGuid;
end
else
begin

if (@Temp is not null  and @Temp <> '')
begin
set @Site =@Temp;
end

if exists(select 1 from tbPrintTemplate where Type=@Type and ModalityType =@ModalityType and IsDefaultByModality =1 and Site=@Site)
	   begin	
	   declare my_Cusror cursor local FOR select TemplateGuid from tbPrintTemplate where Type=@Type and ModalityType =@ModalityType and IsDefaultByModality =1 and Site=@Site;
	   OPEN my_Cusror
	   FETCH NEXT FROM my_Cusror into @TemplateGuid	
	   end
else if exists (select 1 from tbPrintTemplate where Type=@Type and IsDefaultByType =1 and Site=@Site)	
	   begin
	   declare my_Cusror cursor local FOR select TemplateGuid from tbPrintTemplate where Type=@Type and IsDefaultByType =1 and Site=@Site;
	   OPEN my_Cusror
	   FETCH NEXT FROM my_Cusror into @TemplateGuid
	   end
else if exists(select 1 from tbPrintTemplate where Type=@Type and ModalityType =@ModalityType and IsDefaultByModality =1 and Site='')
	   begin	
	   declare my_Cusror cursor local FOR select TemplateGuid from tbPrintTemplate where Type=@Type and ModalityType =@ModalityType and IsDefaultByModality =1 and Site='';
	   OPEN my_Cusror
	   FETCH NEXT FROM my_Cusror into @TemplateGuid	
	   end
else if exists (select 1 from tbPrintTemplate where Type=@Type and IsDefaultByType =1 and Site='')	
	   begin
	   declare my_Cusror cursor local FOR select TemplateGuid from tbPrintTemplate where Type=@Type and IsDefaultByType =1 and Site='';
	   OPEN my_Cusror
	   FETCH NEXT FROM my_Cusror into @TemplateGuid
	   end       
end
execute(@sql);  
END




GO
/****** Object:  StoredProcedure [dbo].[procGetRoleBySite]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[procGetRoleBySite]
	-- Add the parameters for the stored procedure here
	@site nvarchar(128)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @parentid varchar(128)
    -- Insert statements for procedure here
    if(LEN(@site)=0)
    begin
		select A.*,B.Description from tbRoleDir A JOIN tbRole B ON A.RoleID=B.RoleID  where Leaf=1 and ParentID=(select UniqueID from tbRoleDir where Name='GlobalRole')
    end
    else
    begin
    
		SELECT @parentid=UniqueID from tbRoleDir where Name=@site and Leaf=0
		if(LEN(@parentid)=0)
			return
		
		select * into #tempdir from tbRoleDir where ParentId =@parentid
		;        
		 with cte as(
		 select * from #tempdir 
		 union all 
		 select T.* 
				from tbRoleDir T
				inner join #tempdir  on #tempdir.UniqueID = T.ParentId
				)
		 select A.*,B.Description from cte A JOIN tbRole B ON A.RoleID=B.RoleID where leaf=1 union all select A.*,B.Description from tbRoleDir A JOIN tbRole B ON A.RoleID=B.RoleID where Leaf=1 and ParentID=(select UniqueID from tbRoleDir where Name='GlobalRole')
	end
END


GO
/****** Object:  StoredProcedure [dbo].[procGetTakeReportDate]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[procGetTakeReportDate]
	@ModalityType varchar(128),
	@TakeReportDate date output
AS
BEGIN	
	SET NOCOUNT ON
	set @TakeReportDate = GETDATE()
	
	declare @CTDate date = GETDATE()
	declare @wd int	= datepart(WEEKDAY,getdate())
	declare @sql varchar(8000)
	declare my_Cusror cursor FOR select 1 from dbo.tbWorkingCalendar where DateType = 3 and Date = convert(date,convert(varchar(32),DATEPART(year,getdate()))+'-'+convert(varchar(32),DATEPART(MONTH,GETDATE()))+'-'+convert(varchar(32),DATEPART(day,getdate())))
     
    OPEN my_Cusror
    FETCH NEXT FROM my_Cusror

    if @@fetch_status = 0
    begin--holiday
    set @CTDate = GETDATE() 
    end
    
	else
	begin--workingday and weekend
		select @CTDate =
		case @wd
			 when 1 then DATEADD(day,2,@CTDate) --sunday
			 when 2 then DATEADD(day,2,@CTDate) --monday
			 when 3 then DATEADD(day,2,@CTDate) --tuesday
			 when 4 then DATEADD(day,2,@CTDate) --wednesday
			 when 5 then DATEADD(day,5,@CTDate) --thursday
			 when 6 then DATEADD(day,4,@CTDate) --friday
			 when 7 then DATEADD(day,3,@CTDate) --saturday
		end 	
	end
	
	CLOSE my_Cusror
    DEALLOCATE my_Cusror
	
	select @TakeReportDate = 
	case @ModalityType
	     WHEN 'CR' THEN GETDATE()
	     WHEN 'CT' THEN @CTDate
	     WHEN 'MR' THEN @CTDate
	end 
	PRINT @TakeReportDate
END


GO
/****** Object:  StoredProcedure [dbo].[procGetTemplateRecursive]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procGetTemplateRecursive]
      @Site NVARCHAR(64), 
      @DirectoryType NVARCHAR(128)
AS
begin
	SET NOCOUNT ON;
WITH ReportDireRecursive(TemplateGuid,ItemGuid,ParentID)
 as(
	select TemplateGuid,ItemGuid,ParentID from tbReportTemplateDirec where (ParentID  = @Site or ParentID ='UserTemplate' or ParentID ='GlobalTemplate') and DirectoryType = @DirectoryType
	union all
	select  a.TemplateGuid,a.ItemGuid, a.ParentID from tbReportTemplateDirec a inner join ReportDireRecursive b on a.ParentID = b.ItemGuid and DirectoryType = @DirectoryType
 )
select * into #tmpReportTemplateDir from ReportDireRecursive 
if(UPPER(@DirectoryType) = 'PHRASE')
begin
select * from tbPhraseTemplate where TemplateGuid in (select TemplateGuid from #tmpReportTemplateDir)
end
else
begin
select * from tbReportTemplate where TemplateGuid in (select TemplateGuid from #tmpReportTemplateDir)
end
select * from tbReportTemplateDirec where ItemGUID in (select ItemGUID from #tmpReportTemplateDir)
end


GO
/****** Object:  StoredProcedure [dbo].[procGetUserGuid]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create procedure [dbo].[procGetUserGuid]

@szLoginName nvarchar(128), --Login name 
@szRoleName  nvarchar(128), --Role of the user
@szPassWord nvarchar(128),
@szDomain nvarchar(64)

as

if not exists (select 1 from tbUser,tbUser2Domain where tbUser.UserGuid=tbUser2Domain.UserGuid
                                    and tbUser.LoginName =@szLoginName and tbUser2Domain.Domain=@szDomain)
	                         select 1
else if @szRoleName ='' 
		begin                       
			if not exists (select 1  from tbUser,tbUser2Domain,tbRole2User where tbUser.UserGuid=tbUser2Domain.UserGuid
                             and  tbRole2User.UserGuid = tbUser.UserGuid and 
                                tbUser.LoginName = @szLoginName  and tbUser2Domain.Domain=@szDomain
                                group by tbUser.UserGuid having COUNT(tbUser.UserGuid) = 1 )
								select 2
			else --Only one Role
				select top 1 tbUser.UserGuid from tbUser, tbRole2User,tbUser2Domain where tbRole2User.UserGuid = tbUser.UserGuid and tbUser.UserGuid=tbUser2Domain.UserGuid
	                        and tbUser.LoginName = @szLoginName and  tbUser.PassWord = @szPassWord and tbUser2Domain.Domain=@szDomain
		end

else if not exists (select 1 from tbUser,tbUser2Domain,tbRole2User where tbUser.UserGuid=tbUser2Domain.UserGuid
                     and  tbRole2User.UserGuid = tbUser.UserGuid and tbRole2User.RoleName = @szRoleName and 
                          tbUser.LoginName = @szLoginName and tbUser2Domain.Domain=@szDomain)
                          select 2
     else 
			select top 1 tbUser.UserGuid from tbUser, tbRole2User,tbUser2Domain 
				where tbRole2User.UserGuid = tbUser.UserGuid and tbUser.UserGuid=tbUser2Domain.UserGuid
						and tbUser.LoginName = @szLoginName and tbRole2User.RoleName = @szRoleName and 
						tbUser.PassWord = @szPassWord and tbUser2Domain.Domain=@szDomain                                     


GO
/****** Object:  StoredProcedure [dbo].[procHandleCriticalSignResponse]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procHandleCriticalSignResponse]
	@SendXML xml,
	@ReplyXML xml
AS
BEGIN	
	SET NOCOUNT ON
	
	declare @AccNo varchar(256);
    declare @MessageId varchar(256);
	declare @CurSite nvarchar(256);
	declare @Priority nvarchar(256);
    declare @Type varchar(2); -- 1 means confirmation; 2 means reply result
    declare @NotificationType varchar(2);--1 means contagion; 0 means dont need to notification
	declare @Reply varchar(max);
	declare @UpdateSql varchar(max);
	declare @ErrorMessage varchar(256);
	declare @XML xml;	
	
	if @SendXML is null or convert(varchar(max),@SendXML) = '' or @ReplyXML is null or convert(varchar(max),@ReplyXML) = ''
	begin
	set @ErrorMessage = 'Please give proper parameters';
	RAISERROR(@ErrorMessage, 16, 1)
	return;
	end
	
	BEGIN TRY	
	
	set @UpdateSql='';
	set @ErrorMessage = '';
	
	set @AccNo = @SendXML.value('(/Event/Para[@Name="AccNo"]/text())[1]','varchar(256)');
	set @MessageId = @SendXML.value('(/Event/MessageKeyGuid/text())[1]','varchar(256)');
	set @CurSite = @ReplyXML.value('(/Event/Site/text())[1]','varchar(256)');
	set @Priority = @ReplyXML.value('(/Event/Priority/text())[1]','varchar(256)');
	set @Type = @ReplyXML.value('(/Event/Type/text())[1]','varchar(2)');
	set @NotificationType = @ReplyXML.value('(/Event/NotificationType/text())[1]','varchar(2)');
	set @Reply = @ReplyXML.value('(/Event/Reply/text())[1]','varchar(max)');
	
	if @AccNo is null or @AccNo = ''
	begin
	set @ErrorMessage = 'AccNo in @SendXML is empty!';
	RAISERROR(@ErrorMessage, 16, 1)
	return;
	end
	
	if @MessageId is null or @MessageId = ''
	begin
	set @ErrorMessage = 'MessageId in @SendXML is empty!';
	RAISERROR(@ErrorMessage, 16, 1)
	return;
	end
	
	if @CurSite is null or @CurSite = ''
	begin
	set @ErrorMessage = 'Site in @ReplyXML is empty!';
	RAISERROR(@ErrorMessage, 16, 1)
	return;
	end
	
	if @Priority is null or @Priority = ''
	begin
	set @ErrorMessage = 'Priority in @ReplyXML is empty!';
	RAISERROR(@ErrorMessage, 16, 1)
	return;
	end
	
	if @Type is null or @Type = ''
	begin
	set @ErrorMessage = 'Type in @ReplyXML is empty!';
	RAISERROR(@ErrorMessage, 16, 1)
	return;
	end
	
	if @NotificationType is null or @NotificationType = ''
	begin
	set @ErrorMessage = 'NotificationType in @ReplyXML is empty!';
	RAISERROR(@ErrorMessage, 16, 1)
	return;
	end
	
	if @Type='2' and (@Reply is null or @Reply = '')
	begin
	set @ErrorMessage = 'Reply in @ReplyXML is empty!';
	RAISERROR(@ErrorMessage, 16, 1)
	return;
	end
	
	if (@Type <> '1' and @Type <> '2')
	begin
	set @ErrorMessage = 'There is no ciritical sign response with type=' + @Type;
	RAISERROR(@ErrorMessage, 16, 1)
	return;
	end
	
	declare my_Cusror cursor local FOR select OrderMessage from dbo.tbRegOrder where AccNo = @AccNo;
     
    OPEN my_Cusror;
    FETCH NEXT FROM my_Cusror into @XML;

    if (@@fetch_status = 0)
    begin  
    -------------------------check if exit start-----------------------------------------
    if(@XML is null)
    begin
    set @ErrorMessage = 'There is no corresponding critical sign, Please make sure the accno and messageId are correct or it might have been deleted';
    RAISERROR(@ErrorMessage, 16, 1)
	return;
    end    
    else if(@XML.exist('/LeaveMessage/Message[KeyGuid=sql:variable("@MessageId") and (@Type=''b'' or @Type=''1'' or @Type=''2'')]')=0)
    begin
    set @ErrorMessage = 'There is no corresponding critical sign, Please make sure the accno and messageId are correct or it might have been deleted';
    RAISERROR(@ErrorMessage, 16, 1)
	return;
    end
    ---------------------------check if exit end----------------------------------------
     
    -------------------------update critical sign message/node start--------------------
	declare @Context varchar(max);
    declare @NewContext varchar(max);
    
    SET @Context =  @XML.value('(/LeaveMessage/Message[KeyGuid=sql:variable("@MessageId")]/Context)[1]', 'varchar(max)');   
    
    if (@Type = '1') 
    begin
    if @XML.value('(/LeaveMessage/Message[KeyGuid=sql:variable("@MessageId")]/@Type)[1]','varchar(32)') <> 'b'
    begin
    return
    end
    SET @NewContext = @Context + CHAR(13) + CHAR(13) + '危急征象确认收到 ' + convert(varchar(32),DATEPART(year,getdate()))+'-'+convert(varchar(32),DATEPART(MONTH,GETDATE()))+'-'+convert(varchar(32),DATEPART(day,getdate())) + ' '+ convert(varchar(32),DATEPART(HOUR,GETDATE())) + ':'+ convert(varchar(32),DATEPART(MINUTE,GETDATE())) + ':'+ convert(varchar(32),DATEPART(SECOND,GETDATE()));    
    end
    else
    begin
    SET @NewContext = @Context + CHAR(13) + CHAR(13) + '危急征象处理结果 ' + convert(varchar(32),DATEPART(year,getdate()))+'-'+convert(varchar(32),DATEPART(MONTH,GETDATE()))+'-'+convert(varchar(32),DATEPART(day,getdate())) + ' '+ convert(varchar(32),DATEPART(HOUR,GETDATE())) + ':'+ convert(varchar(32),DATEPART(MINUTE,GETDATE())) + ':'+ convert(varchar(32),DATEPART(SECOND,GETDATE()))+ CHAR(13) + @reply;
    end
    
    SET @XML.modify('replace value of (/LeaveMessage/Message[KeyGuid=sql:variable("@MessageId")]/@Type)[1] with sql:variable("@Type")');
    
    if(@Context is null or @Context='')
    begin
    SET @XML.modify('insert text{sql:variable("@NewContext")} into (/LeaveMessage/Message[KeyGuid=sql:variable("@MessageId")]/Context)[1] ');
    end
    else
    begin
    SET @XML.modify('replace value of (/LeaveMessage/Message[KeyGuid=sql:variable("@MessageId")]/Context/text())[1] with sql:variable("@NewContext")');
    end
    -------------------------update critical sign message/node end----------------------
    
    -------------------------update root node property--type start----------------------  
	 declare @MessageType varchar(256);
	 declare @oldchar char;
	 declare @newchar char;
	 set @MessageType = '';
	 set @oldchar = '';
	 set @newchar = '';
     set @MessageType = @XML.value('(/LeaveMessage/@Type)[1]', 'varchar(256)');     
     
	 if (charindex('b',@MessageType) > 0)    
     begin     
     set @oldchar = 'b';        
     end
     else if (charindex('1',@MessageType) > 0)   
     begin     
     set @oldchar = '1';            
     end
     else if (charindex('2',@MessageType) > 0)   
     begin     
     set @oldchar = '2';            
     end
     
     if(@XML.exist('/LeaveMessage/Message[@Type=''b'']') = 1)
     begin
     set @newchar = 'b';
     end
     else if (@XML.exist('/LeaveMessage/Message[@Type=''1'']') = 1)
     begin
     set @newchar = '1';
     end
     else if (@XML.exist('/LeaveMessage/Message[@Type=''2'']') = 1)
     begin
     set @newchar = '2';
     end
     
     set @MessageType = REPLACE(@MessageType,@oldchar,@newchar);	 
	 SET @XML.modify('replace value of (/LeaveMessage/@Type)[1] with sql:variable("@MessageType")');
    -------------------------update root node property--type end----------------------
    
    set @XML = REPLACE(convert(varchar(max),@XML),'''','''''');
    set @UpdateSql = 'update tbRegOrder set OrderMessage = ''' + convert(varchar(max),@XML) + ''' where AccNo = '''  + @AccNo + '''' ;
    if (@XML is not null)
    begin
    
    execute(@UpdateSql);
    declare @Reveiver varchar(256)
    set @Reveiver = @SendXML.value('(/Event/Receivers/text())[1]','varchar(256)');;    
    if(@Reveiver is null or @Reveiver='')
    begin
    set @Reveiver = @XML.value('(/LeaveMessage/Message[KeyGuid=sql:variable("@MessageId")]/UserGuid)[1]','varchar(256)');
    SET @SendXML.modify('insert text{sql:variable("@Reveiver")} into (/Event/Receivers)[1] ');
    end
    else
    begin   
    set @Reveiver = @XML.value('(/LeaveMessage/Message[KeyGuid=sql:variable("@MessageId")]/UserGuid)[1]','varchar(256)'); 
    SET @SendXML.modify('replace value of (/Event/Receivers/text())[1] with sql:variable("@Reveiver")');
    end
    if @Type = '1'
    begin
    exec [procPostEvent] N'危急征象已收到','',@SendXML,@Priority,@CurSite
    end
    else if @Type = '2' and @NotificationType = '1'--@NotificationType = '1' means 传染病(contagion)
    begin    
    SET @SendXML.modify('insert <Para Name="Reply">{sql:variable("@Reply")}</Para> as last into (/Event)[1]');
    exec [procPostEvent] N'危急征象已处理-传染病','',@SendXML,@Priority,@CurSite    
    end
    --else if @Type = '2' and @NotificationType = '2' --define new event type for @NotificationType = '2'
    --begin
    --exec [procPostEvent] N'','add new event type',@SendXML,@Priority,@CurSite    
    --end    
    end      
    end
    
    else
    begin
    set @ErrorMessage = 'cannot find the order with accno =' + @AccNo;
    RAISERROR(@ErrorMessage, 16, 1)
    end   
	
	CLOSE my_Cusror;
    DEALLOCATE my_Cusror;
    END TRY
    
    BEGIN CATCH
    SET @ErrorMessage = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    
    SELECT @ErrorMessage = ERROR_MESSAGE(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE();
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH
END


GO
/****** Object:  StoredProcedure [dbo].[procHelp]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[procHelp]
	@proc_name varchar(255) = NULL
as
/**********
[版本号]4.0.0
[创建时间]2017.03.07   
[版权] Copyright ? 1998-2001好医生云医院管理技术有限公司
[描述]得到存储过程参数
[功能说明]
	得到存储过程参数
[参数说明]
	@proc_name varchar(255) 	存储过程名
[返回值]
[结果集、排序]
[调用的sp]
[调用实例]
**********/
set nocount on

declare	@dbname	sysname

select @dbname = parsename(@proc_name,3)

if @dbname is not null and @dbname <> db_name()
begin
	raiserror(15250,-1,-1)
	return(1)
end

declare @objid int
declare @sysobj_type char(2)
select @objid = id, @sysobj_type = xtype from sysobjects where id = object_id(@proc_name)

if @sysobj_type in ('P ') --RF too?
begin

	if exists (select id from syscolumns where id = @objid)
	begin

		select
			'parameter_name'	= name,
			'type'				= type_name(xusertype),
            'length'			= length,
            'prec'				= case when type_name(xtype) = 'uniqueidentifier' then xprec
									else odbcprec(xtype, length, xprec) end,
            'scale'				= odbcscale(xtype,xscale),
            'param_order'		= colid,
			'collation'			= collation,
			'xtype'				= type_name(xtype)
		into #types
		from syscolumns where id = @objid

		select parameter_name, 
			(case when type='hys_rq8' then 3 when type='hys_rq16' then 4 
			when charindex(xtype, 'int')>0 or xtype='bit' then 0 
			when xtype in ('demical', 'numeric', 'float', 'real') then 1
			else 2 end) as type
			from #types
	end
end

return



GO
/****** Object:  StoredProcedure [dbo].[procIllnessStatisitc]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[procIllnessStatisitc]
		@strSQL varchar(8000)
AS

	BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
      EXEC(@strSQL )
END


GO
/****** Object:  StoredProcedure [dbo].[procImageArriveUpd]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[procImageArriveUpd]
(	
	@AccNo        varchar(32),
	@PatientID	varchar(128),
	@ModalityName  varchar(32),
	@OperatorName varchar(64),	
	@PerformedEnddt	DateTime,
	@PerformedStartdt DateTime,
	@Site varchar(128) = '', --- site name.
	@StudyID varchar(16) = '' --- site name.
)
AS
BEGIN
    if(@AccNo is NULL or len(ltrim(rtrim(@AccNo)))=0)
		return
	
    if(@PerformedEnddt is NULL)
    begin
        set @PerformedEnddt=getdate()
    end
    DECLARE @nCount int
    DECLARE @OperatorGuid nvarchar(128)
    DECLARE @OrderGuid nvarchar(128)
    
    DECLARE @HISID nvarchar(128)
    DECLARE @LocalName nvarchar(128)
    DECLARE @EnglishName nvarchar(128)
    DECLARE @Birthday datetime
    DECLARE @Telephone nvarchar(128)
    DECLARE @ReferenceNo nvarchar(128)
    DECLARE @Address nvarchar(128)
    DECLARE @Gender nvarchar(128)
    DECLARE @PatientType nvarchar(128)
    DECLARE @InhospitalRegion nvarchar(128)
    DECLARE @InhospitalNo nvarchar(128)
    DECLARE @ClinicNo nvarchar(128)
    DECLARE @CurrentAge nvarchar(128)
    DECLARE @BedNo nvarchar(128)
    DECLARE @ApplyDept nvarchar(128)
    DECLARE @ApplyDoctor nvarchar(128)
    DECLARE @RemoteAccNo nvarchar(128)
    DECLARE @IsVIP int        
    DECLARE @StudyInstanceUID nvarchar(128)
    DECLARE @PatientComment nvarchar(1024)
    DECLARE @Alias nvarchar(128)
    DECLARE @Marriage nvarchar(128)       
    DECLARE @VisitComment nvarchar(1024)
    DECLARE @Observation nvarchar(128)  
    DECLARE @OrderComment nvarchar(1024)             
    DECLARE @IsCharge int
    DECLARE @PatientGuid nvarchar(128)
    DECLARE @VisitGuid nvarchar(128)
    DECLARE @ImageArriveSensitivity nvarchar(8)	
    DECLARE @SetFirstVisitMark int
    
    if exists (select 1 from tbSiteProfile where Name ='ImageArriveSensitivity' and  ModuleID = '0600' and Site =@Site)
		select @ImageArriveSensitivity=Value from tbSiteProfile where Name ='ImageArriveSensitivity' and  ModuleID = '0600' and Site =@Site
	else 
		select @ImageArriveSensitivity=value from tbSystemProfile where Name='ImageArriveSensitivity' and ModuleID='0600'
    if(@ImageArriveSensitivity is null or len(@ImageArriveSensitivity)=0)
		set @ImageArriveSensitivity='0'

	DECLARE @Domain nvarchar(128)	
    select @Domain=value from tbSystemProfile where Name='Domain' and ModuleID='0000'

	
	--get patient,visit and order information	
	if (len(@PatientID)>0)
	BEGIN
		if(@ImageArriveSensitivity='1')--大小写敏感
			SELECT @PatientID=A.PatientID,@LocalName=A.LocalName,@EnglishName=A.EnglishName,@Birthday=A.Birthday,@Telephone=A.Telephone,@ReferenceNo=A.ReferenceNo,@Address=A.Address,@Gender=A.Gender,@IsVIP=A.IsVIP,@PatientGuid=A.PatientGuid,
			@PatientType=C.PatientType,@InhospitalRegion=C.InhospitalRegion,@InhospitalNo=C.InhospitalNo,@ClinicNo=C.ClinicNo,@CurrentAge=C.CurrentAge,@BedNo=C.BedNo,@VisitGuid=C.VisitGuid,
			@AccNo=C.AccNo,@HISID=C.HISID,@ApplyDept=C.ApplyDept,@ApplyDoctor=C.ApplyDoctor,@RemoteAccNo=C.RemoteAccNo,@StudyInstanceUID=C.StudyInstanceUID,@OrderGuid=C.OrderGuid  FROM tbRegPatient A,tbRegOrder C where A.PatientGuid=C.PatientGuid 
			and C.AccNo collate Chinese_PRC_CS_AS_WS=@AccNo and A.PatientID collate Chinese_PRC_CS_AS_WS=@PatientID
		else--大小写不敏感
			SELECT @PatientID=A.PatientID,@LocalName=A.LocalName,@EnglishName=A.EnglishName,@Birthday=A.Birthday,@Telephone=A.Telephone,@ReferenceNo=A.ReferenceNo,@Address=A.Address,@Gender=A.Gender,@IsVIP=A.IsVIP,@PatientGuid=A.PatientGuid,
			@PatientType=C.PatientType,@InhospitalRegion=C.InhospitalRegion,@InhospitalNo=C.InhospitalNo,@ClinicNo=C.ClinicNo,@CurrentAge=C.CurrentAge,@BedNo=C.BedNo,@VisitGuid=C.VisitGuid,
			@AccNo=C.AccNo,@HISID=C.HISID,@ApplyDept=C.ApplyDept,@ApplyDoctor=C.ApplyDoctor,@RemoteAccNo=C.RemoteAccNo,@StudyInstanceUID=C.StudyInstanceUID,@OrderGuid=C.OrderGuid  FROM tbRegPatient A,tbRegOrder C where A.PatientGuid=C.PatientGuid 
			and C.AccNo=@AccNo and A.PatientID=@PatientID
	
	END
	ELSE
	BEGIN
		if(@ImageArriveSensitivity='1')--大小写敏感
			SELECT @PatientID=A.PatientID,@LocalName=A.LocalName,@EnglishName=A.EnglishName,@Birthday=A.Birthday,@Telephone=A.Telephone,@ReferenceNo=A.ReferenceNo,@Address=A.Address,@Gender=A.Gender,@IsVIP=A.IsVIP,@PatientGuid=A.PatientGuid,
			@PatientType=C.PatientType,@InhospitalRegion=C.InhospitalRegion,@InhospitalNo=C.InhospitalNo,@ClinicNo=C.ClinicNo,@CurrentAge=C.CurrentAge,@BedNo=C.BedNo,@VisitGuid=C.VisitGuid,
			@AccNo=C.AccNo,@HISID=C.HISID,@ApplyDept=C.ApplyDept,@ApplyDoctor=C.ApplyDoctor,@RemoteAccNo=C.RemoteAccNo,@StudyInstanceUID=C.StudyInstanceUID,@OrderGuid=C.OrderGuid  FROM tbRegPatient A,tbRegOrder C where A.PatientGuid=C.PatientGuid 
			and C.AccNo collate Chinese_PRC_CS_AS_WS=@AccNo
		else--大小写不敏感
			SELECT @PatientID=A.PatientID,@LocalName=A.LocalName,@EnglishName=A.EnglishName,@Birthday=A.Birthday,@Telephone=A.Telephone,@ReferenceNo=A.ReferenceNo,@Address=A.Address,@Gender=A.Gender,@IsVIP=A.IsVIP,@PatientGuid=A.PatientGuid,
			@PatientType=C.PatientType,@InhospitalRegion=C.InhospitalRegion,@InhospitalNo=C.InhospitalNo,@ClinicNo=C.ClinicNo,@CurrentAge=C.CurrentAge,@BedNo=C.BedNo,@VisitGuid=C.VisitGuid,
			@AccNo=C.AccNo,@HISID=C.HISID,@ApplyDept=C.ApplyDept,@ApplyDoctor=C.ApplyDoctor,@RemoteAccNo=C.RemoteAccNo,@StudyInstanceUID=C.StudyInstanceUID,@OrderGuid=C.OrderGuid  FROM tbRegPatient A,tbRegOrder C where A.PatientGuid=C.PatientGuid 
			and C.AccNo=@AccNo

	END

	if(@OrderGuid is null or len(@OrderGuid)=0)
    BEGIN
    	return
    END	    
    DECLARE @ExamSystem nvarchar(128)
    DECLARE @Modality nvarchar(128)
	DECLARE @Charge nvarchar(128)
	DECLARE @Registrar nvarchar(128)
	DECLARE @Technician nvarchar(128)
	DECLARE @TechDoctor nvarchar(128)
	DECLARE @TechNurse nvarchar(128)
	DECLARE @Status int
	DECLARE @RegisterDt nvarchar(128)
	DECLARE @BookingBeginDt datetime
	DECLARE @BookingEndDt datetime
	DECLARE @ProcedureGuid nvarchar(128)
	DECLARE @Description nvarchar(128)
	DECLARE @ModalityType nvarchar(128)
	DECLARE @Bodypart nvarchar(128)
	DECLARE @CheckingItem nvarchar(128)
	DECLARE @BookingNotice nvarchar(1024)
	DECLARE @ProcedureCode nvarchar(128)
	DECLARE @Room nvarchar(128)
	
	DECLARE @GWGuid nvarchar(128)
	DECLARE @Charged nvarchar(8)
	DECLARE @IsExistImage int
	DECLARE @PreStatus int


    select @nCount =count(*) from tbRegProcedure where OrderGuid=@OrderGuid
    if (@nCount>0)
	BEGIN
		
		select @PatientComment=Comments,@Alias=Alias,@Marriage=Marriage from tbRegPatient where PatientGuid=@PatientGuid
	  
		select @VisitComment=VisitComment,@Observation=Observation,@OrderComment=Comments from tbRegOrder where OrderGuid=@OrderGuid
	    
	    --update examsite before update status,otherwise the trigger 'triAutoAssign' is not correctly worked
		Update tbRegOrder SET ExamAccNo=@AccNo,ExamDomain=@Domain,ExamSite =@Site,StudyID=@StudyID where OrderGuid=@OrderGuid
		
	        
		DECLARE cursor1 CURSOR FAST_FORWARD FOR   SELECT A.ProcedureCode,A.ExamSystem,A.Modality,A.Charge,A.Registrar,A.Technician,A.TechDoctor,A.TechNurse,A.Status,A.RegisterDt,
			   A.BookingBeginDt,A.BookingEndDt,A.ProcedureGuid,B.Description,B.ModalityType,B.Bodypart,B.CheckingItem,B.BookingNotice,C.Room,A.IsExistImage,A.PreStatus   
		FROM tbRegProcedure A,tbProcedureCode B,tbModality C  where A.ProcedureCode=B.ProcedureCode and A.Modality=C.Modality and A.OrderGuid=@OrderGuid FOR READ ONLY

		 
		OPEN  cursor1
		FETCH NEXT FROM cursor1 INTO @ProcedureCode,@ExamSystem,@Modality,@Charge,@Registrar,@Technician,@TechDoctor,@TechNurse,@Status,@RegisterDt,@BookingBeginDt,@BookingEndDt,@ProcedureGuid,@Description,@ModalityType,@Bodypart,@CheckingItem,@BookingNotice,@Room,@IsExistImage,@PreStatus  
		WHILE (@@FETCH_STATUS) = 0   
		BEGIN
		
			if(@PreStatus=1000)
			begin
				update tbRegProcedure set PreStatus=0 where OrderGuid=@OrderGuid
				goto endaction
			end
		
		
			if(@Status>=50 and @IsExistImage=1)
				goto notanyaction
			if(@Status < 50 )
			begin
				Update tbRegOrder set Assign2Site =@Site where OrderGuid=@OrderGuid
				exec [dbo].[procSetFirstVisitMark] @OrderGuid=@OrderGuid,@ModalityType=@ModalityType,@Site=@Site
			end
				
			
			if(len(@OperatorName)>0)--get the guid of operator			
				select @OperatorGuid=UserGuid from tbUser where LoginName=@OperatorName
			if(len(@OperatorGuid)>0)
				set @Technician=@OperatorGuid
						
			if(len(@ModalityName)>0)
				set @Modality=@ModalityName					
			
			if(@Status=0)
				UPDATE tbRegProcedure SET IsExistImage=1,Technician=@Technician,Modality=@Modality,ExamineDt =CONVERT(varchar, @PerformedEnddt, 120) WHERE ProcedureGuid=@ProcedureGuid
			else if(@Status<50)
				UPDATE tbRegProcedure SET IsExistImage=1,Status=50,Technician=@Technician,Modality=@Modality,ExamineDt =CONVERT(varchar, @PerformedEnddt, 120) WHERE ProcedureGuid=@ProcedureGuid
			else if(@Status>=50)	
				UPDATE tbRegProcedure SET IsExistImage=1,Technician=@Technician,Modality=@Modality,ExamineDt =CONVERT(varchar, @PerformedEnddt, 120) WHERE ProcedureGuid=@ProcedureGuid
			--begin UNLOCK the order in exam module(0600)
			delete from tbSync where ModuleID ='0600' and AccNo =@AccNo
			--end UNLOCK the order in exam module(0600)
			
			select @GWGuid=newid()
		                       
			--Dataindex
			INSERT INTO tbGwDataIndex(DATA_ID,DATA_DT,EVENT_TYPE,RECORD_INDEX_1,DATA_SOURCE) VALUES(@GWGuid,CONVERT(varchar, getdate(), 120),'12','','Local')

			--Patient        
			INSERT INTO tbGwPatient(DATA_ID,DATA_DT,PATIENTID,OTHER_PID,PATIENT_NAME,PATIENT_LOCAL_NAME,BIRTHDATE,SEX,PATIENT_ALIAS,ADDRESS,PHONENUMBER_HOME,MARITAL_STATUS,PATIENT_TYPE,PATIENT_LOCATION,VISIT_NUMBER,BED_NUMBER,CUSTOMER_1,CUSTOMER_2,CUSTOMER_3,CUSTOMER_4) 
			  VALUES(@GWGuid,CONVERT(varchar, getdate(), 120),@PatientID,@HISID,@EnglishName,@LocalName,CONVERT(varchar, @Birthday, 120),@Gender,@Alias,@Address,@Telephone,@Marriage,@PatientType,@InhospitalRegion,@ClinicNo,@BedNo,@EnglishName,@IsVIP,@InhospitalNo,@PatientComment)                                             

			
			if(@IsCharge<>0)
				set @Charged='Y'
			else
				set @Charged='N'	
			--Order
			INSERT INTO tbGwOrder(DATA_ID,DATA_DT,ORDER_NO,PLACER_NO,FILLER_NO,PATIENT_ID,EXAM_STATUS,PLACER_DEPARTMENT,PLACER,FILLER_DEPARTMENT,FILLER,REF_PHYSICIAN,REQUEST_REASON,REUQEST_COMMENTS,EXAM_REQUIREMENT,SCHEDULED_DT,MODALITY,STATION_NAME,EXAM_LOCATION,TECHNICIAN,BODY_PART,PROCEDURE_CODE,PROCEDURE_DESC,EXAM_COMMENT,CHARGE_STATUS,CHARGE_AMOUNT,STUDY_INSTANCE_UID,EXAM_DT) 
					VALUES(@GWGuid,CONVERT(varchar, getdate(), 120),@ProcedureGuid,@RemoteAccNo,@AccNo,@PatientID,'16',@ApplyDept,@ApplyDoctor,@ApplyDept,@ApplyDoctor,@ApplyDoctor,@Observation,@VisitComment,@BookingNotice,@RegisterDt,@ModalityType,@Modality,@Room,@Technician,@Bodypart,@ProcedureCode,@Description,@OrderComment,@Charged,@Charge,@StudyInstanceUID,CONVERT(varchar, @PerformedEnddt, 120))                                                     
			
notanyaction:
		FETCH NEXT FROM cursor1 INTO @ProcedureCode,@ExamSystem,@Modality,@Charge,@Registrar,@Technician,@TechDoctor,@TechNurse,@Status,@RegisterDt,@BookingBeginDt,@BookingEndDt,@ProcedureGuid,@Description,@ModalityType,@Bodypart,@CheckingItem,@BookingNotice,@Room,@IsExistImage ,@PreStatus 
		END
endaction:
		DEALLOCATE cursor1  
	END
	
END


GO
/****** Object:  StoredProcedure [dbo].[procImageArriveUpdex]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procImageArriveUpdex]
(	
	@AccNo        varchar(32),
	@PatientID	varchar(128),
	@ModalityName  varchar(32),
	@OperatorName varchar(64),	
	@PerformedEnddt	DateTime,
	@PerformedStartdt DateTime,
	@StudyInstanceUID varchar(128),
	@Site varchar(128) = '', --- site name.
	@StudyID varchar(16)
)
AS
BEGIN
    if(@AccNo is NULL or len(ltrim(rtrim(@AccNo)))=0)
		return
	
    if(@PerformedEnddt is NULL)
    begin
        set @PerformedEnddt=getdate()
    end
    DECLARE @nCount int
    DECLARE @OperatorGuid nvarchar(128)
    DECLARE @OrderGuid nvarchar(128)    
    DECLARE @HISID nvarchar(128)
    DECLARE @LocalName nvarchar(128)
    DECLARE @EnglishName nvarchar(128)
    DECLARE @Birthday datetime
    DECLARE @Telephone nvarchar(128)
    DECLARE @ReferenceNo nvarchar(128)
    DECLARE @Address nvarchar(128)
    DECLARE @Gender nvarchar(128)
    DECLARE @PatientType nvarchar(128)
    DECLARE @InhospitalRegion nvarchar(128)
    DECLARE @InhospitalNo nvarchar(128)
    DECLARE @ClinicNo nvarchar(128)
    DECLARE @CurrentAge nvarchar(128)
    DECLARE @BedNo nvarchar(128)
    DECLARE @ApplyDept nvarchar(128)
    DECLARE @ApplyDoctor nvarchar(128)
    DECLARE @RemoteAccNo nvarchar(128)
    DECLARE @IsVIP int        
    DECLARE @LocalStudyInstanceUID nvarchar(128)
    DECLARE @PatientComment nvarchar(1024)
    DECLARE @Alias nvarchar(128)
    DECLARE @Marital nvarchar(128)       
    DECLARE @VisitComment nvarchar(1024)
    DECLARE @Observation nvarchar(128)  
    DECLARE @OrderComment nvarchar(1024)             
    DECLARE @IsCharge int
    DECLARE @PatientGuid nvarchar(128)
    DECLARE @VisitGuid nvarchar(128)
    DECLARE @Marriage nvarchar(128)
    DECLARE @ImageArriveSensitivity nvarchar(8)	
    DECLARE @SetFirstVisitMark int
    
    if exists (select 1 from tbSiteProfile where Name ='ImageArriveSensitivity' and  ModuleID = '0600' and Site =@Site)
		select @ImageArriveSensitivity=Value from tbSiteProfile where Name ='ImageArriveSensitivity' and  ModuleID = '0600' and Site =@Site
	else 
		select @ImageArriveSensitivity=value from tbSystemProfile where Name='ImageArriveSensitivity' and ModuleID='0600'
    if(@ImageArriveSensitivity is null or len(@ImageArriveSensitivity)=0)
		set @ImageArriveSensitivity='0'
	
	DECLARE @Domain nvarchar(128)	
    select @Domain=value from tbSystemProfile where Name='Domain' and ModuleID='0000'

	--get patient,visit and order information	
	if (len(@PatientID)>0)
	BEGIN
		if(@ImageArriveSensitivity='1')--大小写敏感
			SELECT @PatientID=A.PatientID,@LocalName=A.LocalName,@EnglishName=A.EnglishName,@Birthday=A.Birthday,@Telephone=A.Telephone,@ReferenceNo=A.ReferenceNo,@Address=A.Address,@Gender=A.Gender,@IsVIP=A.IsVIP,@PatientGuid=A.PatientGuid,
			@PatientType=C.PatientType,@InhospitalRegion=C.InhospitalRegion,@InhospitalNo=C.InhospitalNo,@ClinicNo=C.ClinicNo,@CurrentAge=C.CurrentAge,@BedNo=C.BedNo,@VisitGuid=C.VisitGuid,
			@AccNo=C.AccNo,@HISID=C.HISID,@ApplyDept=C.ApplyDept,@ApplyDoctor=C.ApplyDoctor,@RemoteAccNo=C.RemoteAccNo,@LocalStudyInstanceUID=C.StudyInstanceUID,@OrderGuid=C.OrderGuid  FROM tbRegPatient A,tbRegOrder C where A.PatientGuid=C.PatientGuid 
			and C.AccNo collate Chinese_PRC_CS_AS_WS=@AccNo and A.PatientID collate Chinese_PRC_CS_AS_WS=@PatientID
		else--大小写不敏感
			SELECT @PatientID=A.PatientID,@LocalName=A.LocalName,@EnglishName=A.EnglishName,@Birthday=A.Birthday,@Telephone=A.Telephone,@ReferenceNo=A.ReferenceNo,@Address=A.Address,@Gender=A.Gender,@IsVIP=A.IsVIP,@PatientGuid=A.PatientGuid,
			@PatientType=C.PatientType,@InhospitalRegion=C.InhospitalRegion,@InhospitalNo=C.InhospitalNo,@ClinicNo=C.ClinicNo,@CurrentAge=C.CurrentAge,@BedNo=C.BedNo,@VisitGuid=C.VisitGuid,
			@AccNo=C.AccNo,@HISID=C.HISID,@ApplyDept=C.ApplyDept,@ApplyDoctor=C.ApplyDoctor,@RemoteAccNo=C.RemoteAccNo,@LocalStudyInstanceUID=C.StudyInstanceUID,@OrderGuid=C.OrderGuid  FROM tbRegPatient A,tbRegOrder C where A.PatientGuid=C.PatientGuid 
			and C.AccNo=@AccNo and A.PatientID=@PatientID
	
	END
	ELSE
	BEGIN
		if(@ImageArriveSensitivity='1')--大小写敏感
			SELECT @PatientID=A.PatientID,@LocalName=A.LocalName,@EnglishName=A.EnglishName,@Birthday=A.Birthday,@Telephone=A.Telephone,@ReferenceNo=A.ReferenceNo,@Address=A.Address,@Gender=A.Gender,@IsVIP=A.IsVIP,@PatientGuid=A.PatientGuid,
			@PatientType=C.PatientType,@InhospitalRegion=C.InhospitalRegion,@InhospitalNo=C.InhospitalNo,@ClinicNo=C.ClinicNo,@CurrentAge=C.CurrentAge,@BedNo=C.BedNo,@VisitGuid=C.VisitGuid,
			@AccNo=C.AccNo,@HISID=C.HISID,@ApplyDept=C.ApplyDept,@ApplyDoctor=C.ApplyDoctor,@RemoteAccNo=C.RemoteAccNo,@LocalStudyInstanceUID=C.StudyInstanceUID,@OrderGuid=C.OrderGuid  FROM tbRegPatient A,tbRegOrder C where A.PatientGuid=C.PatientGuid 
			and C.AccNo collate Chinese_PRC_CS_AS_WS=@AccNo
		else--大小写不敏感
			SELECT @PatientID=A.PatientID,@LocalName=A.LocalName,@EnglishName=A.EnglishName,@Birthday=A.Birthday,@Telephone=A.Telephone,@ReferenceNo=A.ReferenceNo,@Address=A.Address,@Gender=A.Gender,@IsVIP=A.IsVIP,@PatientGuid=A.PatientGuid,
			@PatientType=C.PatientType,@InhospitalRegion=C.InhospitalRegion,@InhospitalNo=C.InhospitalNo,@ClinicNo=C.ClinicNo,@CurrentAge=C.CurrentAge,@BedNo=C.BedNo,@VisitGuid=C.VisitGuid,
			@AccNo=C.AccNo,@HISID=C.HISID,@ApplyDept=C.ApplyDept,@ApplyDoctor=C.ApplyDoctor,@RemoteAccNo=C.RemoteAccNo,@LocalStudyInstanceUID=C.StudyInstanceUID,@OrderGuid=C.OrderGuid  FROM tbRegPatient A,tbRegOrder C where A.PatientGuid=C.PatientGuid 
			and C.AccNo=@AccNo

	END

	if(@OrderGuid is null or len(@OrderGuid)=0)
    BEGIN
    	return
    END	    

	
	--Update the ris studyinstanceuid use the uid from broker
	if(@StudyInstanceUID is not null and len(@StudyInstanceUID)>0)
	BEGIN
		Update tbRegOrder set StudyInstanceUID=@StudyInstanceUID where OrderGuid=@OrderGuid
		set @LocalStudyInstanceUID=@StudyInstanceUID
	END

	
    select @PatientComment=Comments,@Alias=Alias,@Marriage=Marriage from tbRegPatient where PatientGuid=@PatientGuid
  
    select @VisitComment=VisitComment,@Observation=Observation,@OrderComment=Comments from tbRegOrder where OrderGuid=@OrderGuid
    
    DECLARE @ExamSystem nvarchar(128)
    DECLARE @Modality nvarchar(128)
	DECLARE @Charge nvarchar(128)
	DECLARE @Registrar nvarchar(128)
	DECLARE @Technician nvarchar(128)
	DECLARE @TechDoctor nvarchar(128)
	DECLARE @TechNurse nvarchar(128)
	DECLARE @Status int
	DECLARE @RegisterDt nvarchar(128)
	DECLARE @BookingBeginDt datetime
	DECLARE @BookingEndDt datetime
	DECLARE @ProcedureGuid nvarchar(128)
	DECLARE @Description nvarchar(128)
	DECLARE @ModalityType nvarchar(128)
	DECLARE @Bodypart nvarchar(128)
	DECLARE @CheckingItem nvarchar(128)
	DECLARE @BookingNotice nvarchar(1024)
	DECLARE @ProcedureCode nvarchar(128)
	DECLARE @Room nvarchar(128)
	
	DECLARE @GWGuid nvarchar(128)
	DECLARE @Charged nvarchar(8)
    DECLARE @IsExistImage int
    DECLARE @PreStatus int
    
	--update examsite before update status,otherwise the trigger 'triAutoAssign' is not correctly worked
    Update tbRegOrder SET ExamAccNo=@AccNo,ExamDomain=@Domain,ExamSite =@Site,StudyID=@StudyID where OrderGuid=@OrderGuid
    
	DECLARE cursor1 CURSOR FAST_FORWARD FOR   SELECT A.ProcedureCode,A.ExamSystem,A.Modality,A.Charge,A.Registrar,A.Technician,A.TechDoctor,A.TechNurse,A.Status,A.RegisterDt,
		   A.BookingBeginDt,A.BookingEndDt,A.ProcedureGuid,B.Description,B.ModalityType,B.Bodypart,B.CheckingItem,B.BookingNotice,C.Room ,A.IsExistImage ,A.PreStatus 
	FROM tbRegProcedure A,tbProcedureCode B,tbModality C  where A.ProcedureCode=B.ProcedureCode and A.Modality=C.Modality and A.OrderGuid=@OrderGuid FOR READ ONLY

	 
OPEN  cursor1
		FETCH NEXT FROM cursor1 INTO @ProcedureCode,@ExamSystem,@Modality,@Charge,@Registrar,@Technician,@TechDoctor,@TechNurse,@Status,@RegisterDt,@BookingBeginDt,@BookingEndDt,@ProcedureGuid,@Description,@ModalityType,@Bodypart,@CheckingItem,@BookingNotice,@Room,@IsExistImage,@PreStatus  
		WHILE (@@FETCH_STATUS) = 0   
		BEGIN
			if(@PreStatus=1000)
			begin
				update tbRegProcedure set PreStatus=0 where OrderGuid=@OrderGuid
				goto endaction
			end
		
			if(@Status>=50 and @IsExistImage=1)
				goto notanyaction
				
			if(@Status < 50 )
			begin
				Update tbRegOrder set Assign2Site =@Site where OrderGuid=@OrderGuid
				exec [dbo].[procSetFirstVisitMark] @OrderGuid=@OrderGuid,@ModalityType=@ModalityType,@Site=@Site
			end
				
			if(len(@OperatorName)>0)--get the guid of operator			
				select @OperatorGuid=UserGuid from tbUser where LoginName=@OperatorName
			if(len(@OperatorGuid)>0)
				set @Technician=@OperatorGuid
						
			if(len(@ModalityName)>0)
				set @Modality=@ModalityName					
			
			if(@Status=0)
				UPDATE tbRegProcedure SET IsExistImage=1,Technician=@Technician,Modality=@Modality,ExamineDt =CONVERT(varchar, @PerformedEnddt, 120) WHERE ProcedureGuid=@ProcedureGuid
			else if(@Status<50)
				UPDATE tbRegProcedure SET IsExistImage=1,Status=50,Technician=@Technician,Modality=@Modality,ExamineDt =CONVERT(varchar, @PerformedEnddt, 120) WHERE ProcedureGuid=@ProcedureGuid
			else if(@Status >= 50) 	
				UPDATE tbRegProcedure SET IsExistImage=1,Technician=@Technician,Modality=@Modality,ExamineDt =CONVERT(varchar, @PerformedEnddt, 120) WHERE ProcedureGuid=@ProcedureGuid
			--begin UNLOCK the order in exam module(0600)
			delete from tbSync where ModuleID ='0600' and AccNo =@AccNo
			--end UNLOCK the order in exam module(0600)			
			
			select @GWGuid=newid()
		                       
			--Dataindex
			INSERT INTO tbGwDataIndex(DATA_ID,DATA_DT,EVENT_TYPE,RECORD_INDEX_1,DATA_SOURCE) VALUES(@GWGuid,CONVERT(varchar, getdate(), 120),'12','','Local')

			--Patient        
			INSERT INTO tbGwPatient(DATA_ID,DATA_DT,PATIENTID,OTHER_PID,PATIENT_NAME,PATIENT_LOCAL_NAME,BIRTHDATE,SEX,PATIENT_ALIAS,ADDRESS,PHONENUMBER_HOME,MARITAL_STATUS,PATIENT_TYPE,PATIENT_LOCATION,VISIT_NUMBER,BED_NUMBER,CUSTOMER_1,CUSTOMER_2,CUSTOMER_3,CUSTOMER_4) 
			  VALUES(@GWGuid,CONVERT(varchar, getdate(), 120),@PatientID,@HISID,@EnglishName,@LocalName,CONVERT(varchar, @Birthday, 120),@Gender,@Alias,@Address,@Telephone,@Marriage,@PatientType,@InhospitalRegion,@ClinicNo,@BedNo,@EnglishName,@IsVIP,@InhospitalNo,@PatientComment)                                             

			
			if(@IsCharge<>0)
				set @Charged='Y'
			else
				set @Charged='N'	
			--Order
			INSERT INTO tbGwOrder(DATA_ID,DATA_DT,ORDER_NO,PLACER_NO,FILLER_NO,PATIENT_ID,EXAM_STATUS,PLACER_DEPARTMENT,PLACER,FILLER_DEPARTMENT,FILLER,REF_PHYSICIAN,REQUEST_REASON,REUQEST_COMMENTS,EXAM_REQUIREMENT,SCHEDULED_DT,MODALITY,STATION_NAME,EXAM_LOCATION,TECHNICIAN,BODY_PART,PROCEDURE_CODE,PROCEDURE_DESC,EXAM_COMMENT,CHARGE_STATUS,CHARGE_AMOUNT,STUDY_INSTANCE_UID,EXAM_DT) 
					VALUES(@GWGuid,CONVERT(varchar, getdate(), 120),@ProcedureGuid,@RemoteAccNo,@AccNo,@PatientID,'16',@ApplyDept,@ApplyDoctor,@ApplyDept,@ApplyDoctor,@ApplyDoctor,@Observation,@VisitComment,@BookingNotice,@RegisterDt,@ModalityType,@Modality,@Room,@Technician,@Bodypart,@ProcedureCode,@Description,@OrderComment,@Charged,@Charge,@StudyInstanceUID,CONVERT(varchar, @PerformedEnddt, 120))                                                     
			
notanyaction:
		FETCH NEXT FROM cursor1 INTO @ProcedureCode,@ExamSystem,@Modality,@Charge,@Registrar,@Technician,@TechDoctor,@TechNurse,@Status,@RegisterDt,@BookingBeginDt,@BookingEndDt,@ProcedureGuid,@Description,@ModalityType,@Bodypart,@CheckingItem,@BookingNotice,@Room,@IsExistImage,@PreStatus  
		END
endaction:
	DEALLOCATE cursor1  

END


GO
/****** Object:  StoredProcedure [dbo].[procImageArriveUpdex2]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[procImageArriveUpdex2]
( 
 @AccNo        varchar(32),
 @PatientID varchar(128),
 @ModalityName  varchar(32),
 @OperatorName varchar(64), 
 @PerformedEnddt DateTime,
 @PerformedStartdt DateTime,
 @StudyInstanceUID varchar(128) = '',
 @RPatientName varchar(64) = '',
 @RGender varchar(16) = '',
 @RPatientNamePinyin varchar(64) = '',
 @RBirthday DateTime = null,
 @RAETitle varchar(128) = '',
 @RProcedureCode varchar(128) = '',
 @RProcedureDescription varchar(512) = '',
 @Optional1 varchar(512) = null,
 @Optional2 varchar(512) = null,
 @Site varchar(128) = '', --- site name.
 @StudyID varchar(16) = ''
)
AS
BEGIN
 DECLARE @Domain nvarchar(128) 
    select @Domain=value from tbSystemProfile where Name='Domain' and ModuleID='0000'
 DECLARE @NotMatchingReason nvarchar(128)
    if(@AccNo is NULL or len(ltrim(rtrim(@AccNo)))=0)
    begin
  set @NotMatchingReason = 'AccNoNotMatching'
  goto NotMatchingEntry
 end
 
    if(@PerformedEnddt is NULL)
    begin
        set @PerformedEnddt=getdate()
    end
    DECLARE @nCount int
    DECLARE @OperatorGuid nvarchar(128)
    DECLARE @OrderGuid nvarchar(128)    
    DECLARE @HISID nvarchar(128)
    DECLARE @LocalName nvarchar(128)
    DECLARE @EnglishName nvarchar(128)
    DECLARE @Birthday datetime
    DECLARE @Telephone nvarchar(128)
    DECLARE @ReferenceNo nvarchar(128)
    DECLARE @Address nvarchar(128)
    DECLARE @Gender nvarchar(128)
    DECLARE @PatientType nvarchar(128)
    DECLARE @InhospitalRegion nvarchar(128)
    DECLARE @InhospitalNo nvarchar(128)
    DECLARE @ClinicNo nvarchar(128)
    DECLARE @CurrentAge nvarchar(128)
    DECLARE @BedNo nvarchar(128)
    DECLARE @ApplyDept nvarchar(128)
    DECLARE @ApplyDoctor nvarchar(128)
    DECLARE @RemoteAccNo nvarchar(128)
    DECLARE @IsVIP int        
    DECLARE @LocalStudyInstanceUID nvarchar(128)
    DECLARE @PatientComment nvarchar(1024)
    DECLARE @Alias nvarchar(128)
    DECLARE @Marital nvarchar(128)       
    DECLARE @VisitComment nvarchar(1024)
    DECLARE @Observation nvarchar(128)  
    DECLARE @OrderComment nvarchar(1024)             
    DECLARE @IsCharge int
    DECLARE @PatientGuid nvarchar(128)
    DECLARE @VisitGuid nvarchar(128)
    DECLARE @Marriage nvarchar(128)
    DECLARE @ImageArriveSensitivity nvarchar(8) 
    
    DECLARE @PatientIDMatched int
    DECLARE @AccNoMatched int
    DECLARE @SetFirstVisitMark int
        
    if exists (select 1 from tbSiteProfile where Name ='ImageArriveSensitivity' and  ModuleID = '0600' and Site =@Site)
  select @ImageArriveSensitivity=Value from tbSiteProfile where Name ='ImageArriveSensitivity' and  ModuleID = '0600' and Site =@Site
 else 
  select @ImageArriveSensitivity=value from tbSystemProfile where Name='ImageArriveSensitivity' and ModuleID='0600'
    if(@ImageArriveSensitivity is null or len(@ImageArriveSensitivity)=0)
  set @ImageArriveSensitivity='0'
 
 
 --get patient,visit and order information 
 if (len(@PatientID)>0)
 BEGIN
  if(@ImageArriveSensitivity='1')--大小写敏感
   SELECT @PatientID=A.PatientID,@LocalName=A.LocalName,@EnglishName=A.EnglishName,@Birthday=A.Birthday,@Telephone=A.Telephone,@ReferenceNo=A.ReferenceNo,@Address=A.Address,@Gender=A.Gender,@IsVIP=A.IsVIP,@PatientGuid=A.PatientGuid,
   @PatientType=C.PatientType,@InhospitalRegion=C.InhospitalRegion,@InhospitalNo=C.InhospitalNo,@ClinicNo=C.ClinicNo,@CurrentAge=C.CurrentAge,@BedNo=C.BedNo,@VisitGuid=C.VisitGuid,
   @AccNo=C.AccNo,@HISID=C.HISID,@ApplyDept=C.ApplyDept,@ApplyDoctor=C.ApplyDoctor,@RemoteAccNo=C.RemoteAccNo,@LocalStudyInstanceUID=C.StudyInstanceUID,@OrderGuid=C.OrderGuid  FROM tbRegPatient A,tbRegOrder C where A.PatientGuid=C.PatientGuid 
   and C.AccNo collate Chinese_PRC_CS_AS_WS=@AccNo and A.PatientID collate Chinese_PRC_CS_AS_WS=@PatientID
  else--大小写不敏感
   SELECT @PatientID=A.PatientID,@LocalName=A.LocalName,@EnglishName=A.EnglishName,@Birthday=A.Birthday,@Telephone=A.Telephone,@ReferenceNo=A.ReferenceNo,@Address=A.Address,@Gender=A.Gender,@IsVIP=A.IsVIP,@PatientGuid=A.PatientGuid,
   @PatientType=C.PatientType,@InhospitalRegion=C.InhospitalRegion,@InhospitalNo=C.InhospitalNo,@ClinicNo=C.ClinicNo,@CurrentAge=C.CurrentAge,@BedNo=C.BedNo,@VisitGuid=C.VisitGuid,
   @AccNo=C.AccNo,@HISID=C.HISID,@ApplyDept=C.ApplyDept,@ApplyDoctor=C.ApplyDoctor,@RemoteAccNo=C.RemoteAccNo,@LocalStudyInstanceUID=C.StudyInstanceUID,@OrderGuid=C.OrderGuid  FROM tbRegPatient A,tbRegOrder C where A.PatientGuid=C.PatientGuid 
   and C.AccNo=@AccNo and A.PatientID=@PatientID
 
 END
 ELSE
 BEGIN
  if(@ImageArriveSensitivity='1')--大小写敏感
   SELECT @PatientID=A.PatientID,@LocalName=A.LocalName,@EnglishName=A.EnglishName,@Birthday=A.Birthday,@Telephone=A.Telephone,@ReferenceNo=A.ReferenceNo,@Address=A.Address,@Gender=A.Gender,@IsVIP=A.IsVIP,@PatientGuid=A.PatientGuid,
   @PatientType=C.PatientType,@InhospitalRegion=C.InhospitalRegion,@InhospitalNo=C.InhospitalNo,@ClinicNo=C.ClinicNo,@CurrentAge=C.CurrentAge,@BedNo=C.BedNo,@VisitGuid=C.VisitGuid,
   @AccNo=C.AccNo,@HISID=C.HISID,@ApplyDept=C.ApplyDept,@ApplyDoctor=C.ApplyDoctor,@RemoteAccNo=C.RemoteAccNo,@LocalStudyInstanceUID=C.StudyInstanceUID,@OrderGuid=C.OrderGuid  FROM tbRegPatient A,tbRegOrder C where A.PatientGuid=C.PatientGuid 
   and C.AccNo collate Chinese_PRC_CS_AS_WS=@AccNo
  else--大小写不敏感
   SELECT @PatientID=A.PatientID,@LocalName=A.LocalName,@EnglishName=A.EnglishName,@Birthday=A.Birthday,@Telephone=A.Telephone,@ReferenceNo=A.ReferenceNo,@Address=A.Address,@Gender=A.Gender,@IsVIP=A.IsVIP,@PatientGuid=A.PatientGuid,
   @PatientType=C.PatientType,@InhospitalRegion=C.InhospitalRegion,@InhospitalNo=C.InhospitalNo,@ClinicNo=C.ClinicNo,@CurrentAge=C.CurrentAge,@BedNo=C.BedNo,@VisitGuid=C.VisitGuid,
   @AccNo=C.AccNo,@HISID=C.HISID,@ApplyDept=C.ApplyDept,@ApplyDoctor=C.ApplyDoctor,@RemoteAccNo=C.RemoteAccNo,@LocalStudyInstanceUID=C.StudyInstanceUID,@OrderGuid=C.OrderGuid  FROM tbRegPatient A,tbRegOrder C where A.PatientGuid=C.PatientGuid 
   and C.AccNo=@AccNo
 END

 select @AccNoMatched = COUNT(1) from tbRegOrder where AccNo = @AccNo 
 if(@AccNoMatched= 0)
  begin
   set @NotMatchingReason = 'AccNoNotMatching'
   goto NotMatchingEntry
  end  
 if(@PatientID is not NULL or len(@PatientID)>0)
    BEGIN
  select @PatientIDMatched = COUNT(1) from tbRegPatient where PatientID = @PatientID  
  if(@PatientIDMatched = 0)
  begin
   set @NotMatchingReason = 'PatientIDNotMatching'
   goto NotMatchingEntry
  end 
    END 
    
    --Insert into tbNotMatching if (patientname then gender) not matching
    if(@RPatientName is not NULL and len(ltrim(rtrim(@RPatientName))) >0) 
    begin
  if(@RPatientName != @LocalName)
  begin
   set @NotMatchingReason = 'PatientNameNotMatching'
   goto NotMatchingEntry
  end
 end
     
    
    if((len(@NotMatchingReason)=0 or @NotMatchingReason is null) and @RGender is not NULL and len(ltrim(rtrim(@RGender))) >0)
    begin
  if(@RGender != @Gender)
  begin     
   set @NotMatchingReason = 'GenderNotMatching'
   goto NotMatchingEntry  
  end
    end
    
 BEGIN--Record the not matching reason to the matching failure log table
  NotMatchingEntry:
  if(len(@NotMatchingReason) >0)
  BEGIN
   Insert into tbNotMatching(
   [Guid]
           ,[PatientID]
           ,[PatientName]
           ,[EnglishName]
           ,[Gender]
           ,[Birthday]
           ,[AccNo]
           ,[AETitle]
           ,[ProcedureCode]
           ,[ProcedureDescription]
           ,[ExamineDt]
           ,[NotMatchingReason]
           ,[ProcessStatus]
           ,[Domain])
           values(
           NEWID(),
           @PatientID,
           @RPatientName,
           @RPatientNamePinyin,
     @RGender, 
     @RBirthday,
     @AccNo,
     @RAETitle,
     @RProcedureCode, 
     @RProcedureDescription, 
     @PerformedEnddt,
     @NotMatchingReason,     
     0,
     @Domain
           )
  return
  END
 END  
 
 --Update the ris studyinstanceuid use the uid from broker
 if(@StudyInstanceUID is not null and len(@StudyInstanceUID)>0)
 BEGIN
  Update tbRegOrder set StudyInstanceUID=@StudyInstanceUID where OrderGuid=@OrderGuid
  set @LocalStudyInstanceUID=@StudyInstanceUID
 END
 
    select @PatientComment=Comments,@Alias=Alias,@Marriage=Marriage from tbRegPatient where PatientGuid=@PatientGuid
  
    select @VisitComment=VisitComment,@Observation=Observation,@OrderComment=Comments from tbRegOrder where OrderGuid=@OrderGuid
    
    DECLARE @ExamSystem nvarchar(128)
    DECLARE @Modality nvarchar(128)
 DECLARE @Charge nvarchar(128)
 DECLARE @Registrar nvarchar(128)
 DECLARE @Technician nvarchar(128)
 DECLARE @TechDoctor nvarchar(128)
 DECLARE @TechNurse nvarchar(128)
 DECLARE @Status int
 DECLARE @RegisterDt nvarchar(128)
 DECLARE @BookingBeginDt datetime
 DECLARE @BookingEndDt datetime
 DECLARE @ProcedureGuid nvarchar(128)
 DECLARE @Description nvarchar(128)
 DECLARE @ModalityType nvarchar(128)
 DECLARE @Bodypart nvarchar(128)
 DECLARE @CheckingItem nvarchar(128)
 DECLARE @BookingNotice nvarchar(1024)
 DECLARE @ProcedureCode nvarchar(128)
 DECLARE @Room nvarchar(128)
 
 DECLARE @GWGuid nvarchar(128)
 DECLARE @Charged nvarchar(8)
    DECLARE @IsExistImage int
        DECLARE @PreStatus int
    DECLARE @IsEventInserted int
    set @IsEventInserted = 0
 --if(@RPatientName!=@LocalName or @RGender!=@Gender)
 --begin
 -- Update tbRegProcedure set Status=35 where Status=20 and OrderGuid=@OrderGuid
 -- return
 --end
 --update examsite before update status,otherwise the trigger 'triAutoAssign' is not correctly worked
    Update tbRegOrder SET ExamAccNo=@AccNo,ExamDomain=@Domain,ExamSite =@Site,StudyID=@StudyID where OrderGuid=@OrderGuid
    
    
 DECLARE cursor1 CURSOR FAST_FORWARD FOR   SELECT A.ProcedureCode,A.ExamSystem,A.Modality,A.Charge,A.Registrar,A.Technician,A.TechDoctor,A.TechNurse,A.Status,A.RegisterDt,
     A.BookingBeginDt,A.BookingEndDt,A.ProcedureGuid,B.Description,B.ModalityType,B.Bodypart,B.CheckingItem,B.BookingNotice,C.Room ,A.IsExistImage ,A.PreStatus 
 FROM tbRegProcedure A,tbProcedureCode B,tbModality C  where A.ProcedureCode=B.ProcedureCode and A.Modality=C.Modality and A.OrderGuid=@OrderGuid FOR READ ONLY
 
  
OPEN  cursor1
  FETCH NEXT FROM cursor1 INTO @ProcedureCode,@ExamSystem,@Modality,@Charge,@Registrar,@Technician,@TechDoctor,@TechNurse,@Status,@RegisterDt,@BookingBeginDt,@BookingEndDt,@ProcedureGuid,@Description,@ModalityType,@Bodypart,@CheckingItem,@BookingNotice,@Room,@IsExistImage,@PreStatus  
  WHILE (@@FETCH_STATUS) = 0   
  BEGIN
  
  	if(@PreStatus=1000)
	begin
		update tbRegProcedure set PreStatus=0 where OrderGuid=@OrderGuid
		goto endaction
	end
	
   if(@Status>=50 and @IsExistImage=1)
    goto notanyaction
    
   if(@Status < 50 )
   begin
    Update tbRegOrder set Assign2Site =@Site where OrderGuid=@OrderGuid
    exec [dbo].[procSetFirstVisitMark] @OrderGuid=@OrderGuid,@ModalityType=@ModalityType,@Site=@Site
   end
    
   if(len(@OperatorName)>0)--get the guid of operator   
    select @OperatorGuid=UserGuid from tbUser where LoginName=@OperatorName
   if(len(@OperatorGuid)>0)
    set @Technician=@OperatorGuid
      
   if(len(@ModalityName)>0)
    set @Modality=@ModalityName  
       
   if(@Status =0)
    UPDATE tbRegProcedure SET IsExistImage=1,Technician=@Technician,Modality=@Modality,ExamineDt =CONVERT(varchar, @PerformedEnddt, 120) WHERE ProcedureGuid=@ProcedureGuid   
   else if(@Status <50)
    begin
    UPDATE tbRegProcedure SET IsExistImage=1,Status=50,Technician=@Technician,Modality=@Modality,ExamineDt =CONVERT(varchar, @PerformedEnddt, 120) WHERE ProcedureGuid=@ProcedureGuid
    if(@IsEventInserted = 0)
    begin
     INSERT INTO tbEventLog(Guid,EventCode,ModalityType,Modality,CostTime,CreateDt,Operator,Domain) 
      VALUES(NEWID(),2,@ModalityType,@Modality,datediff(minute,CAST(@RegisterDt as datetime),getdate()),convert(nvarchar(36),GETDATE(),120),@OperatorName,@Domain)
        set @IsEventInserted = 1
    end
    end
   else if(@Status >= 50)  
    UPDATE tbRegProcedure SET IsExistImage=1,Technician=@Technician,Modality=@Modality,ExamineDt =CONVERT(varchar, @PerformedEnddt, 120) WHERE ProcedureGuid=@ProcedureGuid
   --begin UNLOCK the order in exam module(0600)
   delete from tbSync where ModuleID ='0600' and AccNo =@AccNo
   --end UNLOCK the order in exam module(0600)
      
   select @GWGuid=newid()
                         
   --Dataindex
   INSERT INTO tbGwDataIndex(DATA_ID,DATA_DT,EVENT_TYPE,RECORD_INDEX_1,DATA_SOURCE) VALUES(@GWGuid,CONVERT(varchar, getdate(), 120),'12','','Local')
   --Patient        
   INSERT INTO tbGwPatient(DATA_ID,DATA_DT,PATIENTID,OTHER_PID,PATIENT_NAME,PATIENT_LOCAL_NAME,BIRTHDATE,SEX,PATIENT_ALIAS,ADDRESS,PHONENUMBER_HOME,MARITAL_STATUS,PATIENT_TYPE,PATIENT_LOCATION,VISIT_NUMBER,BED_NUMBER,CUSTOMER_1,CUSTOMER_2,CUSTOMER_3,CUSTOMER_4) 
     VALUES(@GWGuid,CONVERT(varchar, getdate(), 120),@PatientID,@HISID,@EnglishName,@LocalName,CONVERT(varchar, @Birthday, 120),@Gender,@Alias,@Address,@Telephone,@Marriage,@PatientType,@InhospitalRegion,@ClinicNo,@BedNo,@EnglishName,@IsVIP,@InhospitalNo,@PatientComment)                                               
   if(@IsCharge<>0)
    set @Charged='Y'
   else
    set @Charged='N' 
   --Order
   INSERT INTO tbGwOrder(DATA_ID,DATA_DT,ORDER_NO,PLACER_NO,FILLER_NO,PATIENT_ID,EXAM_STATUS,PLACER_DEPARTMENT,PLACER,FILLER_DEPARTMENT,FILLER,REF_PHYSICIAN,REQUEST_REASON,REUQEST_COMMENTS,EXAM_REQUIREMENT,SCHEDULED_DT,MODALITY,STATION_NAME,EXAM_LOCATION,TECHNICIAN,BODY_PART,PROCEDURE_CODE,PROCEDURE_DESC,EXAM_COMMENT,CHARGE_STATUS,CHARGE_AMOUNT,STUDY_INSTANCE_UID,EXAM_DT) 
     VALUES(@GWGuid,CONVERT(varchar, getdate(), 120),@ProcedureGuid,@RemoteAccNo,@AccNo,@PatientID,'16',@ApplyDept,@ApplyDoctor,@ApplyDept,@ApplyDoctor,@ApplyDoctor,@Observation,@VisitComment,@BookingNotice,@RegisterDt,@ModalityType,@Modality,@Room,@Technician,@Bodypart,@ProcedureCode,@Description,@OrderComment,@Charged,@Charge,@StudyInstanceUID,CONVERT(varchar, @PerformedEnddt, 120))                                                     
   
notanyaction:
  FETCH NEXT FROM cursor1 INTO @ProcedureCode,@ExamSystem,@Modality,@Charge,@Registrar,@Technician,@TechDoctor,@TechNurse,@Status,@RegisterDt,@BookingBeginDt,@BookingEndDt,@ProcedureGuid,@Description,@ModalityType,@Bodypart,@CheckingItem,@BookingNotice,@Room,@IsExistImage,@PreStatus  
  END
endaction:
 DEALLOCATE cursor1  
END



GO
/****** Object:  StoredProcedure [dbo].[procInsert]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[procInsert] (@tablename varchar(256))
as
begin
        set nocount on
        declare @sqlstr varchar(4000)
        declare @sqlstr1 varchar(4000)
        declare @sqlstr2 varchar(4000)
        select @sqlstr='select ''insert '+@tablename
        select @sqlstr1=''
        select @sqlstr2=' ('
        select @sqlstr1= ' values ( ''+'
        select @sqlstr1=@sqlstr1+col+'+'',''+' ,@sqlstr2=@sqlstr2+name +',' from (select case 
--        when a.xtype =173 then 'case when '+a.name+' is null then ''NULL'' else '+'convert(varchar('+convert(varchar(4),a.length*2+2)+'),'+a.name +')'+' end'
        when a.xtype =127 then 'case when '+a.name+' is null then ''NULL'' else '+'convert(varchar(20),'+a.name +')'+' end'
        when a.xtype =104 then 'case when '+a.name+' is null then ''NULL'' else '+'convert(varchar(1),'+a.name +')'+' end'
        when a.xtype =175 then 'case when '+a.name+' is null then ''NULL'' else '+'''''''''+'+'replace('+a.name+','''''''','''''''''''')' + '+'''''''''+' end'
        when a.xtype =61  then 'case when '+a.name+' is null then ''NULL'' else '+'''''''''+'+'convert(varchar(23),'+a.name +',121)'+ '+'''''''''+' end'
        when a.xtype =106 then 'case when '+a.name+' is null then ''NULL'' else '+'convert(varchar('+convert(varchar(4),a.xprec+2)+'),'+a.name +')'+' end'
        when a.xtype =62  then 'case when '+a.name+' is null then ''NULL'' else '+'convert(varchar(23),'+a.name +',2)'+' end'
        when a.xtype =56  then 'case when '+a.name+' is null then ''NULL'' else '+'convert(varchar(11),'+a.name +')'+' end'
        when a.xtype =60  then 'case when '+a.name+' is null then ''NULL'' else '+'convert(varchar(22),'+a.name +')'+' end'
        when a.xtype =239 then 'case when '+a.name+' is null then ''NULL'' else '+'''''''''+'+'replace('+a.name+','''''''','''''''''''')' + '+'''''''''+' end'
        when a.xtype =108 then 'case when '+a.name+' is null then ''NULL'' else '+'convert(varchar('+convert(varchar(4),a.xprec+2)+'),'+a.name +')'+' end'
        when a.xtype =231 then 'case when '+a.name+' is null then ''NULL'' else '+'''''''''+'+'replace('+a.name+','''''''','''''''''''')' + '+'''''''''+' end'
        when a.xtype =59  then 'case when '+a.name+' is null then ''NULL'' else '+'convert(varchar(23),'+a.name +',2)'+' end'
        when a.xtype =58  then 'case when '+a.name+' is null then ''NULL'' else '+'''''''''+'+'convert(varchar(23),'+a.name +',121)'+ '+'''''''''+' end'
        when a.xtype =52  then 'case when '+a.name+' is null then ''NULL'' else '+'convert(varchar(12),'+a.name +')'+' end'
        when a.xtype =122 then 'case when '+a.name+' is null then ''NULL'' else '+'convert(varchar(22),'+a.name +')'+' end'
        when a.xtype =48  then 'case when '+a.name+' is null then ''NULL'' else '+'convert(varchar(6),'+a.name +')'+' end'
--        when a.xtype =165 then 'case when '+a.name+' is null then ''NULL'' else '+'convert(varchar('+convert(varchar(4),a.length*2+2)+'),'+a.name +')'+' end'
        when a.xtype =167 then 'case when '+a.name+' is null then ''NULL'' else '+'''''''''+'+'replace('+a.name+','''''''','''''''''''')' + '+'''''''''+' end'
        else '''NULL'''
        end as col,a.colid,a.name
        from syscolumns a where a.id = object_id(@tablename) and a.xtype <>189 and a.xtype <>34 and a.xtype <>35 and  a.xtype <>36
        )t order by colid
        
        select @sqlstr=@sqlstr+left(@sqlstr2,len(@sqlstr2)-1)+') '+left(@sqlstr1,len(@sqlstr1)-3)+')'' from '+@tablename
--  print @sqlstr
        exec( @sqlstr)
        set nocount off
end



GO
/****** Object:  StoredProcedure [dbo].[procInsertOrderMessage]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procInsertOrderMessage]
    @AccNo varchar(256), 
    @Type varchar(2),
    @UserGuid varchar(256), 
    @UserName varchar(256), 
    @Subject varchar(256), 
	@Context varchar(max),
	@ErrorMessage varchar(256) output
AS
BEGIN	
	SET NOCOUNT ON
	
	declare @Message varchar(max);
	declare @UpdateSql varchar(max);
	declare @MessageType varchar(256);
	declare @XML xml;
	
	BEGIN TRY
	set @ErrorMessage = '';
	
	if (@Type = '1' or @Type = '2' or len(@Type) > 1) 
	begin
	set @ErrorMessage = 'cannot add new message with type=' + @Type;
	print @ErrorMessage;
	return;
	end
	
	declare my_Cusror cursor local FOR select OrderMessage from dbo.tbRegOrder where AccNo = @AccNo;
     
    OPEN my_Cusror;
    FETCH NEXT FROM my_Cusror into @XML;

    if (@@fetch_status = 0)
    begin
    
    --------------------------------compatible with old records start----------------------------------
    if(not(@XML is null))
    begin
    if (@XML.exist('/LeaveMessage[@HasCriticalSigns]') = 0)	
	begin
	SET @XML.modify('insert attribute HasCriticalSigns {"0"} into (/LeaveMessage)[1]');
	SET @XML.modify('insert attribute Type {"a"} into (/LeaveMessage)[1]');
	end
	else if (@XML.exist('/LeaveMessage[@Type]') = 0 and @XML.exist('/LeaveMessage[@HasCriticalSigns=''0'']') = 1 )
	begin
	SET @XML.modify('insert attribute Type {"a"} into (/LeaveMessage)[1]');
	end
	else if (@XML.exist('/LeaveMessage[@Type]') = 0 and @XML.exist('/LeaveMessage/Message[@IsCriticalSign=''0'']') = 1 )
	begin
	SET @XML.modify('insert attribute Type {"ab"} into (/LeaveMessage)[1]');
	end
	else if (@XML.exist('/LeaveMessage[@Type]') = 0 and @XML.exist('/LeaveMessage/Message[@IsCriticalSign=''0'']') = 0 )
	begin
	SET @XML.modify('insert attribute Type {"b"} into (/LeaveMessage)[1]');
	end
	end
    --------------------------------compatible with old records end----------------------------------
    
    if (@Type = 'b')
	begin
	set @Message = '<Message IsCriticalSign="1" Type="' + @Type + '">';
	SET @XML.modify('replace value of (/LeaveMessage/@HasCriticalSigns)[1] with "1"');
	
	end
	else
	begin
	if (@Subject='')
	set @Message = '<Message IsCriticalSign="-1" Type="' + @Type + '">';
	else
	set @Message = '<Message IsCriticalSign="0" Type="' + @Type + '">';
	end
	
	set @Message = @Message + '<KeyGuid>' + convert(varchar(128),NEWID()) + '</KeyGuid>';
	set @Message = @Message + '<UserGuid><![CDATA[' + @UserGuid + ']]></UserGuid>';
	set @Message = @Message + '<UserName><![CDATA[' + @UserName + ']]></UserName>';
	set @Message = @Message + '<Subject><![CDATA[' + @Subject + ']]></Subject>';
	set @Message = @Message + '<Context><![CDATA[' + @Context + ']]></Context>';
	set @Message = @Message + '<CreateDt>' + convert(varchar(32),DATEPART(year,getdate()))+'-'+convert(varchar(32),DATEPART(MONTH,GETDATE()))+'-'+convert(varchar(32),DATEPART(day,getdate())) + ' '+ convert(varchar(32),DATEPART(HOUR,GETDATE())) + ':'+ convert(varchar(32),DATEPART(MINUTE,GETDATE())) + ':'+ convert(varchar(32),DATEPART(SECOND,GETDATE())) + '</CreateDt>';
	set @Message = @Message + '</Message>';	
	-----------------------------when ordermessage is empty or null start---------------------------------
	if (@XML is null or convert(varchar(max),@XML) = '')
	begin
	if (@Type = 'b')
	begin
	set @Message = '<LeaveMessage HasCriticalSigns="1" Type="b">' + @Message + '</LeaveMessage>';
	end
	else
	begin
	set @Message = '<LeaveMessage HasCriticalSigns="0" Type="'+ @Type +'">' + @Message + '</LeaveMessage>';
	end
	set @XML = convert(xml,@Message);
	set @XML = REPLACE(convert(varchar(max),@XML),'''','''''');
	set @UpdateSql = 'update tbRegOrder set OrderMessage = ''' + convert(varchar(max),@XML) + ''' where AccNo = '''  + @AccNo +'''';  
    execute(@UpdateSql);  
    PRINT convert(varchar(max),@XML);
	PRINT @UpdateSql;
	PRINT @ErrorMessage;
	return;
	end
	-----------------------------when ordermessage is empty or null end---------------------------------
	declare @node xml;
	set @node = CONVERT(xml,@message);
    SET @XML.modify('insert sql:variable("@node") as last into (/LeaveMessage)[1]'); 
    
     set @MessageType = @XML.value('(/LeaveMessage/@Type)[1]', 'varchar(256)');
     if (@MessageType is null or @MessageType = '')    -- set type  when none
     begin
      SET @XML.modify('replace value of (/LeaveMessage/@Type)[1] with sql:variable("@Type")');
     end
     else if (@Type = 'b' and charindex('1',@MessageType) > 0)     -- replace 1 with b  when @type = b
     begin     
     set @MessageType = REPLACE(@MessageType,'1','b');
     SET @XML.modify('replace value of (/LeaveMessage/@Type)[1] with sql:variable("@MessageType")');         
     end
     else if (@Type = 'b' and charindex('2',@MessageType) > 0)   -- replace 2 with b  when @type = b
     begin     
     set @MessageType = REPLACE(@MessageType,'2','b');
     SET @XML.modify('replace value of (/LeaveMessage/@Type)[1] with sql:variable("@MessageType")');         
     end
     else if (@Type <> 'a' and @Type <> 'b' and charindex(@Type,@MessageType) > 0 )-- already exited flag, cannot add it again
     begin     
     set @ErrorMessage = 'The Flag with type=' + @Type + 'already exits';
	 print @ErrorMessage;
	 return        
     end
     else if (charindex(@Type,@MessageType) = 0) -- insert @type into type ASC and greater than 0 then do nothing     
     begin     
     ------------sort function start-------------------------    
     declare @i int;
     declare @flag int;     
     declare @temp varchar(256);
     declare @chr char(1);
     set @i = 1;
     set @flag =0;
     set @temp ='';
     while (@i <= LEN(@MessageType))
     begin     
     set @chr = SUBSTRING(@MessageType,@i,1);
     if (@chr = '1' or @chr = '2')
     begin 
     set @chr = 'b';
     end
     if (@flag = 0 and @chr > @Type)
     begin
     set @temp = @temp + @Type;
     set @temp = @temp + SUBSTRING(@MessageType,@i,1);
     set @flag = 1;
     end
     else
     begin
      set @temp = @temp + SUBSTRING(@MessageType,@i,1);
     end
     set @i= @i + 1;     
     end
     
     if (@flag = 0)
     begin
     set @temp = @temp + @Type;
     set @flag = 1;
     end
     
     SET @XML.modify('replace value of (/LeaveMessage/@Type)[1] with sql:variable("@temp")');
     ------------sort function end---------------------------
     end
    
    set @XML = REPLACE(convert(varchar(max),@XML),'''','''''');
    set @UpdateSql = 'update tbRegOrder set OrderMessage = ''' + convert(varchar(max),@XML) + ''' where AccNo = '''  + @AccNo + '''' ;
    if (@XML is not null)
    begin
    execute(@UpdateSql)  ;
    end      
    end
    
    else
    begin
    set @ErrorMessage = 'cannot find the order with accno =' + @AccNo;
    end   
	
	CLOSE my_Cusror;
    DEALLOCATE my_Cusror;
    END TRY
    
    BEGIN CATCH
    set @ErrorMessage = ERROR_MESSAGE();
	CLOSE my_Cusror;
    DEALLOCATE my_Cusror;

    END CATCH
	PRINT convert(varchar(max),@XML);
	PRINT @UpdateSql;
	PRINT @ErrorMessage;
END




GO
/****** Object:  StoredProcedure [dbo].[procInsertPathologyTrack]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

        

CREATE PROCEDURE [dbo].[procInsertPathologyTrack]
    @PatientID nvarchar(256),
	@PatientName nvarchar(256),
	@AccNo nvarchar(256),    
    @Gender nvarchar(256), 
    @Birthday nvarchar(256),    
	@CreatorName nvarchar(256),
	@CreatorGuid nvarchar(256)
AS
BEGIN	
	SET NOCOUNT ON
	declare	@ErrorMessage nvarchar(256)
	declare @ReportGuid nvarchar(128)
	declare @ReportName nvarchar(128)

	if len(ltrim(rtrim(@PatientID)))=0
	begin
		insert into tbErrorTable(errormessage) values('procInsertPathologyTrack: patient id is null') 
		return
	end

	select top 1 @ReportGuid=ReportGuid,@ReportName=ReportName from tbReport where reportguid in(select reportguid from tbRegProcedure where status>=110 and orderguid in(select orderguid from tbRegOrder where accno=@AccNo))

	insert into tbPathologyTrack([PatientID],[PatientName],[AccNo],[Gender],[Birthday],[Diagnose],[CreatorName],[CreatorGuid],[ReportGuid],[ReportName]) 
	values(@PatientID,@PatientName,@AccNo,@Gender,@Birthday,(select wygtext+'@' from tbReport where reportguid in(select reportguid from tbRegProcedure where status>=110 and orderguid in(select orderguid from tbRegOrder where accno=@AccNo)) for xml path('')),@CreatorName,@CreatorGuid,@ReportGuid,@ReportName)
		
	
END



GO
/****** Object:  StoredProcedure [dbo].[procJfgeneratereportlist]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[procJfgeneratereportlist](@yearmonth char(7))

as
begin
        set nocount on 

	declare @curmonth datetime
	declare @nextmonth datetime

	select @curmonth = convert(datetime,@yearmonth+'-01',120)
	select @nextmonth = dateadd(month,1,@curmonth)

	--step 1 请空历史表
	delete from JFREPORTLIST where yearmonth = @yearmonth

	--step 2 把当月病人加到病人列表中去

	insert into JFPATINFO(cureno,cardno,hospno,name,sex,intime,status,operator,optime)  
	select syxh,cardno,blh,hzxm,sex,convert(datetime,(substring(ryrq,1,4)+'-'+substring(ryrq,5,2)+'-'+substring(ryrq,7,2)),120)
		,2,'00',getdate() from ZY_BRSYK where
		(substring(ryrq,1,4)+'-'+substring(ryrq,5,2)+'-'+substring(ryrq,7,2))>=@curmonth
		and (substring(ryrq,1,4)+'-'+substring(ryrq,5,2)+'-'+substring(ryrq,7,2))<@nextmonth 
		and brzt<>9 and syxh not in (select cureno from JFPATINFO)

	create table #pat (cureno int,name char(8),hospno char(20),status char(1))	

	--得到出院病人列表(更据Rep_ljf_zy04中取出院病人)	

	insert into #pat
	select distinct syxh,hzxm,blh,brzt from ZY_BRSYK where
		(substring(ryrq,1,4)+'-'+substring(ryrq,5,2)+'-'+substring(ryrq,7,2))>=@curmonth
		and (substring(ryrq,1,4)+'-'+substring(ryrq,5,2)+'-'+substring(ryrq,7,2))<@nextmonth 
		and brzt=3 and syxh not in (select cureno from JFPATINFO  where status =0 )

	--得到在院病人列表(更据Rep_ljf_zy06中取出院病人)	

	insert into #pat
	select distinct syxh,hzxm,blh,brzt from ZY_BRSYK where
		(substring(ryrq,1,4)+'-'+substring(ryrq,5,2)+'-'+substring(ryrq,7,2))>=@curmonth
		and (substring(ryrq,1,4)+'-'+substring(ryrq,5,2)+'-'+substring(ryrq,7,2))<@nextmonth 
		and brzt in (0,1,2,4,5,6,7) and syxh not in (select cureno from JFPATINFO where status =0 )	
	
	insert into #pat
	select distinct p.cureno,p.name,p.hospno,p.status
        from JFPATINFO p where status =0 

	create index #patidx_cureno on #pat(cureno)

	declare @i integer
	select @i=0
	declare @cureno integer,@name char(8),@hospno char(20),@status integer
	declare cur_pat cursor for select cureno,name,hospno,status from #pat 
	open cur_pat 

	fetch cur_pat into @cureno,@name,@hospno,@status

	while @@fetch_status = 0 
	begin  

		--得到病人当月应收款
                --丛jfcharge中得到病人期初应收款
		declare @patcurmoney2 money
                select @patcurmoney2 =0 
                select @patcurmoney2 = sum(amount) from JFCHARGE where cureno = @cureno
                select @patcurmoney2 = isnull(@patcurmoney2,0)
               
		--得到病人正常应收款每个月从charge中取
		declare @patcurmoney money,@zje1 money,@zje2 money 
		select @patcurmoney=0

	select @zje1 = isnull(sum(zje),0) 
		from ZY_BRFYMXK  
		where syxh = @cureno
		and (substring(zxrq,1,4)+'-'+substring(zxrq,5,2)+'-'+substring(zxrq,7,2)) >=@curmonth 
		and (substring(zxrq,1,4)+'-'+substring(zxrq,5,2)+'-'+substring(zxrq,7,2)) <@nextmonth 
	select @zje2 = isnull(sum(zje),0) 
		from ZY_NBRFYMXK  
		where syxh = @cureno
		and (substring(zxrq,1,4)+'-'+substring(zxrq,5,2)) >=@curmonth 
		and (substring(zxrq,1,4)+'-'+substring(zxrq,5,2)) <@nextmonth 
	select @patcurmoney =isnull(@zje1,0)+isnull(@zje2,0)
              
		if @yearmonth = '2002-02'  --期初数据处理
		select @patcurmoney = 0
                else 
		select @patcurmoney2= 0

		select @patcurmoney = @patcurmoney + @patcurmoney2
		              
		--得到病人上期末金额,预交款累计
		declare @patoldmoney money
		declare @patoldprecharge money
		declare @serialno integer

                select @serialno = 0 
		select @patoldmoney = 0,@patoldprecharge = 0

		select @serialno = isnull(serialno,-1) from JFREPORTLIST 
		where cureno = @cureno and date =(select max(date) from JFREPORTLIST where date< @curmonth 
		and cureno =@cureno)
		select @serialno =isnull(@serialno,-1)

                select @patoldmoney = isnull(dyjy,0), @patoldprecharge = isnull(yjklj,0)
		from JFREPORTLIST where serialno =@serialno and cureno =@cureno
		select @patoldmoney = isnull(@patoldmoney,0),
		       @patoldprecharge=isnull(@patoldprecharge,0)

		if @yearmonth = '2002-02'  --期初数据处理
		select @patoldmoney = 0,@patoldprecharge = 0

		--得到病人当月个人支付,医保支付,减负支付
		declare @patcurself money,@patcuryb money,@patcurjf money,@patcuryb2 money
		select  @patcurself=0,@patcuryb=0 ,@patcurjf =0, @patcuryb2 = 0
		select @patcurself = isnull(sum(money1),0),@patcuryb = isnull(sum(money2),0)
		,@patcurjf=isnull(sum(money3),0)
		from JFINVOICE 
		where cureno=@cureno
		and faredate>=@curmonth and faredate <@nextmonth
		
		--得到HIS系统统筹支付

	select @patcuryb=isnull(sum(je),0) from ZY_BRJSJEK 
      where jsxh in (select xh from ZY_BRJSK where syxh=@cureno
		and (substring(jsrq,1,4)+'-'+substring(jsrq,5,2)+'-'+substring(jsrq,7,2)) >=@curmonth 
		and (substring(jsrq,1,4)+'-'+substring(jsrq,5,2)+'-'+substring(jsrq,7,2)) <@nextmonth 	
 		and jszt in(0,1) and  ybjszt=2 and jlzt in (0,1,2)) 
      and lx in ('01','06','04','07')

		if @yearmonth = '2002-02'  --期初数据处理
		select  @patcurself=0,@patcuryb=0 ,@patcurjf =0, @patcuryb2 = 0

		--得到病人当月收入说明
		declare @patcurmemo varchar(60)
		select @patcurmemo = '' 
		select @patcurmemo = isnull(memo,'') 
		from JFINVOICE 
		where cureno=@cureno
		and faredate>=@curmonth and faredate <@nextmonth
		select @patcurmemo = isnull(@patcurmemo,'')

		--得到病人当月预交金
		declare @patcurprecharge money
		select @patcurprecharge = 0
		select @patcurprecharge = isnull(sum(amount),0) from JFPRECHARGE 
		where cureno=@cureno
		and receivedate>=@curmonth and receivedate <@nextmonth
		select @patcurprecharge = isnull(@patcurprecharge,0)

		if @yearmonth = '2002-02'  --期初数据处理
		select @patcurprecharge = 0 
		
		--得到病人当月结余 (当月应收款+上期末金额-当月个人支付-医保支付-减负支付)
		declare @patcurjy money
		select @patcurjy =0
		select @patcurjy = @patcurmoney + @patoldmoney - @patcurself - @patcuryb - @patcurjf

		--得到病人预交金当月累计
		declare @patcurprechargelj money
		select @patcurprechargelj = @patoldprecharge + @patcurprecharge

		--判断把算出的结果写入jfreportlist还是更新其数据,还是不写
		declare @haveserialno integer
                select @haveserialno =-1
		if (@patoldmoney = 0) and (@status =5) and (@patcurprechargelj =0 ) and (@patcurjy =0)
		select @haveserialno = -100
		if @haveserialno = -1 
		begin
			insert into JFREPORTLIST(yearmonth,date,cureno,hospno,xz,patname,sqmje,dyys,dygezf,dyyb,
			dyjf,dyjy,yjksr,yjklj,memo,optime)
			select  @yearmonth,@curmonth,@cureno,@hospno,@status,@name,@patoldmoney,@patcurmoney,
		       		@patcurself,@patcuryb,@patcurjf,@patcurjy,@patcurprecharge,
		       		@patcurprechargelj,@patcurmemo,getdate() 			
		end
		
		if @haveserialno = -100
		begin
			delete from JFREPORTLIST where cureno=@cureno and yearmonth = @yearmonth
		end

		fetch cur_pat into @cureno,@name,@hospno,@status
	end

        close cur_pat
        deallocate cur_pat

	drop table #pat

select 'T','数据生成成功!'
end



GO
/****** Object:  StoredProcedure [dbo].[procJfinitialreportlist]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[procJfinitialreportlist](
@cureno integer,
@yearmonth char(7),
@yjksr money ,
@dyys money ,      --当月应收
@dygezf money ,    --当月个人支付
@dyyb   money ,    --当月医保支付 
@dyjf   money ,    --当月减负
@memo   varchar(60),
@operator integer)
as
begin
	declare @curmonty datetime
	declare @nextmonty datetime

	select @curmonty = convert(datetime,@yearmonth+'-01',120)
	select @nextmonty = dateadd(month,1,@curmonty)

	declare @hospno  integer
	declare @status  integer
	declare @name    char(10)

  select @hospno=blh,@status=brzt,@name=hzxm
    from ZY_BRSYK
    where syxh=609
	
	declare @patcurjy money
	select @patcurjy = @dyys - @dygezf - @dyyb -@dyjf 

	delete from JFINVOICE where cureno =@cureno
	and memo='期初数据'
	insert into JFINVOICE(cureno,faredate,invoiceno,money1,money2,money3,memo,operator,optime)
	select @cureno,@curmonty,0,@dygezf,@dyyb,@dyjf,'期初数据',@operator,getdate()

	delete from JFPRECHARGE where cureno =@cureno and usage=1
	insert into JFPRECHARGE(cureno,amount,usage,moneytype,receivedate,operator,optime)
	select @cureno,@yjksr,1,1,@curmonty,@operator,getdate()

	delete from JFCHARGE where cureno =@cureno and status =1 
	insert into JFCHARGE(cureno,yearmonth,date,amount,status,operator,optime)
	select @cureno,@yearmonth,@curmonty,@dyys,1,@operator,getdate()

	select 'T','插入初始数据成功'
end



GO
/****** Object:  StoredProcedure [dbo].[procLockinfo]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*--处理死锁

查看当前进程,或死锁进程,并能自动杀掉死进程

因为是针对死的,所以如果有死锁进程,只能查看死锁进程
当然,你可以通过参数控制,不管有没有死锁,都只查看死锁进程

--*/

/*--调用示例

exec procLockinfo
kill 398
--*/
CREATE proc [dbo].[procLockinfo]
@kill_lock_spid bit=0,  --是否杀掉死锁的进程,1 杀掉, 0 仅显示
@show_spid_if_nolock bit=0 --如果没有死锁的进程,是否显示正常进程信息,1 显示,0 不显示
as
declare @count int,@s nvarchar(1000),@i int
select id=identity(int,1,1),标志,
进程ID=spid,线程ID=kpid,块进程ID=blocked,数据库ID=dbid,
数据库名=db_name(dbid),用户ID=uid,用户名=loginame,累计CPU时间=cpu,
登陆时间=login_time,打开事务数=open_tran, 进程状态=status,
工作站名=hostname,应用程序名=program_name,工作站进程ID=hostprocess,
域名=nt_domain,网卡地址=net_address
into #t from(
select 标志='死锁的进程',
  spid,kpid,a.blocked,dbid,uid,loginame,cpu,login_time,open_tran,
  status,hostname,program_name,hostprocess,nt_domain,net_address,
  s1=a.spid,s2=0
from master..sysprocesses a join (
  select blocked from master..sysprocesses group by blocked
  )b on a.spid=b.blocked where a.blocked=0
union all
select '|_牺牲品_>',
  spid,kpid,blocked,dbid,uid,loginame,cpu,login_time,open_tran,
  status,hostname,program_name,hostprocess,nt_domain,net_address,
  s1=blocked,s2=1
from master..sysprocesses a where blocked<>0
)a order by s1,s2

select @count=@@rowcount,@i=1

if @count=0 and @show_spid_if_nolock=1
begin
insert #t
select 标志='正常的进程',
  spid,kpid,blocked,dbid,db_name(dbid),uid,loginame,cpu,login_time,
  open_tran,status,hostname,program_name,hostprocess,nt_domain,net_address
from master..sysprocesses
set @count=@@rowcount
end

if @count>0
begin
create table #t1(id int identity(1,1),a nvarchar(30),b Int,EventInfo nvarchar(255))
if @kill_lock_spid=1
begin
  declare @spid varchar(10),@标志 varchar(10)
  while @i<=@count
  begin
   select @spid=进程ID,@标志=标志 from #t where id=@i
   insert #t1 exec('dbcc inputbuffer('+@spid+')')
   if @标志='死锁的进程' exec('kill '+@spid)
   set @i=@i+1
  end
end
else
  while @i<=@count
  begin
   select @s='dbcc inputbuffer('+cast(进程ID as varchar)+')' from #t where id=@i
   insert #t1 exec(@s)
   set @i=@i+1
  end
select a.*,进程的SQL语句=b.EventInfo
from #t a join #t1 b on a.id=b.id
end



GO
/****** Object:  StoredProcedure [dbo].[procLockModalityQuota]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procLockModalityQuota] 
( 
@Modality varchar(256), 
@DateType varchar(256), 
@AvailableDate varchar(256), 
@BookingDate varchar(256), 
@TimeSliceGuid varchar(256), 
@BookingSite varchar(256),
@UnlockGuid varchar(256),
@LockGuid varchar(256) output,
@cnt int OUTPUT
) 
AS 
BEGIN 
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
BEGIN TRANSACTION 
DECLARE @LockResult int 
EXECUTE @LockResult = sp_getapplock 
@Resource ='LockModalityQuota', 
@LockMode = 'Exclusive', 
@LockTimeout = -1 

set @LockGuid ='';
set @cnt = 0;
if @UnlockGuid='' --lock quota
begin
--generate modalityshare copy
if not exists(select 1 from tbModalityTimeSlice a inner join tbModalityShare b on a.TimeSliceGuid = b.TimeSliceGuid where a.Modality = @Modality  and b.Date = @BookingDate)
begin
insert into tbModalityShare select NEWID(),TimeSliceGuid,ShareTarget,TargetType,MaxCount,AvailableCount,GroupId,@BookingDate from tbModalityShare where Date is null and TimeSliceGuid in (select TimeSliceGuid  from tbModalityTimeSlice where Modality = @Modality and AvailableDate = @AvailableDate and DateType = @DateType);
end
else if exists(select 1 from tbModalityTimeSlice a inner join tbModalityShare b on a.TimeSliceGuid = b.TimeSliceGuid where a.Modality = @Modality and b.Date = @BookingDate and (a.AvailableDate <> @AvailableDate or a.DateType <> @DateType) and b.AvailableCount = b.MaxCount)
begin
delete from tbModalityShare where Guid in (select b.Guid from tbModalityTimeSlice a inner join tbModalityShare b on a.TimeSliceGuid = b.TimeSliceGuid where a.Modality = @Modality  and b.Date = @BookingDate);
insert into tbModalityShare select NEWID(),TimeSliceGuid,ShareTarget,TargetType,MaxCount,AvailableCount,GroupId,@BookingDate from tbModalityShare where Date is null and TimeSliceGuid in (select TimeSliceGuid  from tbModalityTimeSlice where Modality = @Modality and AvailableDate = @AvailableDate and DateType = @DateType);
end

update tbModalityShare set AvailableCount = AvailableCount - 1, @cnt = 1, @LockGuid = Guid where Guid in (select top 1 guid from tbModalityShare where TimeSliceGuid = @TimeSliceGuid and Date = @BookingDate and AvailableCount > 0 and TargetType = 1 and ShareTarget = @BookingSite and GroupId = '');

if(@cnt=0)
begin
update tbModalityShare set AvailableCount = AvailableCount - 1, @cnt = 1, @LockGuid = Guid where TimeSliceGuid = @TimeSliceGuid and Date = @BookingDate and AvailableCount > 0 and GroupId = (select top 1 GroupId from tbModalityShare where TimeSliceGuid = @TimeSliceGuid and Date = @BookingDate and AvailableCount > 0 and TargetType = 1 and ShareTarget = @BookingSite and GroupId <> '');
end
end
else --unlock quota
begin
declare @GroupId varchar(128);
set @GroupId = '';
set @GroupId = (select top 1 GroupId from tbModalityShare where Guid = @UnlockGuid);
set @TimeSliceGuid = (select top 1 TimeSliceGuid from tbModalityShare where Guid = @UnlockGuid);
set @BookingDate = (select top 1 Date from tbModalityShare where Guid = @UnlockGuid);
if @GroupId = ''
begin 
update tbModalityShare set AvailableCount = AvailableCount + 1, @cnt = 1 where Guid = @UnlockGuid and AvailableCount < MaxCount;
end
else if @GroupId = 'Default_Hide'
begin
update tbModalityShare set AvailableCount = AvailableCount + 1, @cnt = 1 where TimeSliceGuid = @TimeSliceGuid and Date = @BookingDate and AvailableCount < MaxCount;
end
else
begin
update tbModalityShare set AvailableCount = AvailableCount + 1, @cnt = 1 where Date = @BookingDate and AvailableCount < MaxCount and GroupId = @GroupId;
end
end

EXECUTE sp_releaseapplock @Resource='LockModalityQuota' 
COMMIT TRANSACTION 
END 


GO
/****** Object:  StoredProcedure [dbo].[procLogNotification]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procLogNotification]
	-- Add the parameters for the stored procedure here
	@xmlEvent xml,
	@xmlMsg nvarchar(max) output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @ClientlogDatetime nvarchar(max)
	declare @IP nvarchar(max)
	declare @ExtentsionHost nvarchar(max)
	declare @Msg nvarchar(max)
	
	set @ClientlogDatetime = Convert(nvarchar(max),@xmlEvent.query('Event/loginfo/ClientlogDatetime/text()'))
	set @IP = Convert(nvarchar(max),@xmlEvent.query('Event/loginfo/IP/text()'))
	set @ExtentsionHost = Convert(nvarchar(max),@xmlEvent.query('Event/loginfo/Hospital/text()'))
	set @Msg = Convert(nvarchar(max),@xmlEvent.query('Event/loginfo/Msg/text()'))	
	
	select @ClientlogDatetime,@IP,@ExtentsionHost,@Msg

	set @xmlMsg= '<Message><Sender>EA436D1D-D494-44F2-9C9C-0C1D5542EDE8</Sender><Receivers></Receivers><ReceiverStrategy>2</ReceiverStrategy></Message>' --You can add a  '<ReceiverStrategy>4</ReceiverStrategy>' Element(1 = use SP's @receiver , 2 = use tbMessageConfig's receiveobject, 4 = use both's intersection, 8 = use both's union) under '<Message>' , this element is optional(default value is 4).
	
END


GO
/****** Object:  StoredProcedure [dbo].[procLongPrint]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procLongPrint]
      @String NVARCHAR(MAX)

AS

DECLARE
               @CurrentEnd BIGINT, /* track the length of the next substring */
               @offset tinyint /*tracks the amount of offset needed */


set @string = replace(  replace(@string, char(13) + char(10), char(10))   , char(13), char(10))

WHILE LEN(@String) > 1
BEGIN


    IF CHARINDEX(CHAR(10), @String) between 1 AND 4000
    BEGIN

           SET @CurrentEnd =  CHARINDEX(char(10), @String) -1
           set @offset = 2
    END
    ELSE
    BEGIN
           SET @CurrentEnd = 4000
            set @offset = 1
    END   


    PRINT SUBSTRING(@String, 1, @CurrentEnd) 

    set @string = SUBSTRING(@String, @CurrentEnd+@offset, 1073741822)   

END /*End While loop*/


GO
/****** Object:  StoredProcedure [dbo].[procLspGetPatInfo]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/*=======================================================================================================================  
存储过程：procLspGetPatInfo
使用说明：THIS40 数据库  获取病人基本信息,使用系统LIS40,RIS5.0    
界面调用：  
传入参数：
	@PatType VARCHAR(10)		病员类别 （WardOrReg）  
	@HospNo  VARCHAR(20)=''		门诊住院号  
	@CardNo  VARCHAR(30)=''		病人磁卡号  
传出参数：无  
返回值：病人基本信息数据集  
说明：根据传入条件（病员类别、门诊住院号或病人磁卡号），从HIS数据库调出该病人的基本信息。  
备注：
调用举例: 
		exec procLspGetPatInfo '门急诊类','12345',null,null
		exec procLspGetPatInfo '门急诊类',null,'12345',null
		exec procLspGetPatInfo '住院类','12345',null,null
		exec procLspGetPatInfo '住院类',null,'12345',null
		......
修改纪录：2001/04/29  
作者：BurningSoft  Create
		2003-05-28 jqp modify 当使用卡号取门诊病人时，取出HospNo =Blh
		2003-05-30 jqp modify 床位不以病区代码为前缀
		2003-06-09 jqp modify 临时表#Tmp中WardOrReg改成Int型
		2003-06-26 wwr modify 返回的数据集中再增加地址，邮编，电话等数据
		2003-07-14 jqp modify 修改年龄问题,如果HIS没输入，则我们返回空
		2003-07-24 wwr modify 返回的数据集中再增加申请医生，籍贯等数据(门诊病人无法得到申请医生)
		2003-10-23 mitsukow modify 考虑年库问题,
		2003-10-24 mitsukow modify 考虑年库先查当前库，再查年库
		2004-03-03 wxx 年龄问题,如果为NULL时特殊处理一下,返回-9999
		2004-03-04 jqp 返回住院病人状态，对于已经出区(状态为2)的病人，LIS接口程序要做处理
		2004-04-17 wfy  增加对体检系统的考虑
		2004-04-28 JQP 说明：实施请注意：临床诊断ClincDesc来自 YY_YBZDDMK.zddm字段
		2004-12-06 JQP 增加<院内体检类>：上海市中医医院的需求,通过HIS的职工编码库取基本信息。
		2005-11-14 Cll 增加判断是否是干保类型的WordOrReg为2	
========================================================================================================================*/  
create proc [dbo].[procLspGetPatInfo]
(   
	@PatType    varchar(10),		--病人类别(门急诊类，住院类，其他类)
	@HospNo     varchar(20)='', 	--病历号
	@CardNo     varchar(30)='',		--磁卡号
	@ApplyNo	varchar(20)=''  	--原始申请号
)
as 
Set NoCount On  
  
CREATE TABLE #Tmp 
(  
	HospNo  VARCHAR(30) NULL,  
	CardNo  VARCHAR(30) NULL,  
	PatName  VARCHAR(20) NULL,  
	Sex  VARCHAR(8) NULL,  
	Age  INT  NULL,  
	Birthday  DATETIME NULL,  
	ApplyDept VARCHAR(20) NULL,  
	Ward  VARCHAR(20) NULL,  
	BedNo  VARCHAR(20) NULL,  
	ChargeType VARCHAR(20) NULL,  
	ToDocCode VARCHAR(20) NULL,  
	CureNo  INT  NULL,  
	ClincDesc VarChar(20) NULL,
	wardorreg INT null,
	Phone varchar(20) NULL,
	Address	varchar(50) NULL,
	Zip varchar(6) NULL,
	Csd varchar(10) NULL,
	Career varchar(16) null,
	brzt int null,
	ghxh int null
)      
  
DECLARE  
	@TmpHospNo VARCHAR(30) ,  
	@TmpCardNo VARCHAR(32) ,  
	@Name  VARCHAR(20),  
	@Sex  VARCHAR(8),  
	@Age  INT,  
	@Birthday  VarChar(8),  
	@Dept  VARCHAR(20),  
	@Ward  VARCHAR(20),  
	@BedNo  VARCHAR(20),  
	@ChargeType  VARCHAR(20),  
	@ToDoc  VARCHAR(20),  
	@CureNo varchar(20),  
	@WardOrReg  INT,  
	@ClincDesc VARCHAR(20),  
	@Phone varchar(20),
	@Address	varchar(50),
	@Zip char(6),
	@csd varchar(10),
	@career varchar(16),
	@brzt int,@ghxh int
 
IF LTRIM(RTRIM(@PatType)) = '住院类' 
	SELECT @WardOrReg = 1  
else if LTRIM(RTRIM(@PatType)) = '院内体检类'
	SELECT @WardOrReg = 9  
ELSE 
	SELECT @WardOrReg = 0   
  
IF LTRIM(RTRIM(@HospNo)) <> ''  
BEGIN  
	IF @WardOrReg = 1  
 	BEGIN  
		SELECT  @Name = A.hzxm , @Sex = CASE A.sex WHEN '男' THEN '1' WHEN  '女' THEN  '2' ELSE  '3' END ,   
		@Birthday = A.birth , @ChargeType = A.ybdm ,   
		@CureNo = A.syxh, @TmpCardNo = A.cardno ,@Dept = A.ksdm , @Ward = A.bqdm , @BedNo = A.cwdm,
		@ToDoc = A.ysdm, @ClincDesc = A.zddm, @Phone = B.lxdh, @Address = B.lxdz, @Zip = B.lxyb,
		@csd = C.name, @career = D.name,@brzt = A.brzt 
		FROM  ZY_BRSYK A, ZY_BRXXK B left join YY_DQDMK C on B.csd_x = C.id left join YY_ZYDMK D on B.zybm = D.id
		WHERE A.patid = B.patid 
		   and A.blh = @HospNo and A.brzt not in (0,3,8,9) -- modify by wang yi   
  
		if (RTrim(@Birthday) ='') or (@Birthday is null)
			select @Age = -9999,@Birthday = null  
		else
			SELECT  @Age = DATEDIFF(YEAR , @Birthday , GETDATE())
	END  
	else if @WardOrReg =9 --院内体检类：上海市中医需求,通过HIS的职工编码库取基本信息。
	begin
		set rowcount 1
		SELECT @Name = name , @Sex = CASE sex WHEN '男' THEN '1' WHEN  '女' THEN  '2' ELSE  '3' END ,   
		@Birthday = birth,
		@CureNo = id, @Dept = ks_id , @Ward = bq_id 
		FROM  YY_ZGBMK
		WHERE id = @HospNo
		set rowcount 0
	end
	ELSE  
	BEGIN  
		set rowcount 1
		SELECT  @Name = b.hzxm , @Sex = CASE b.sex WHEN '男' THEN '1' WHEN  '女' THEN  '2' ELSE  '3' END ,   
		@Birthday = b.birth , @ChargeType = a.ybdm ,   
		@CureNo = b.patid, @TmpCardNo = b.cardno, @Dept = a.ksdm, 
		@Phone = b.lxdh, @Address = b.lxdz, @Zip = b.yzbm,@ghxh = a.ghxh
		,@ToDoc = null, @csd = C.name, @career = null,@ClincDesc=D.zddm
		FROM  SF_BRJSK a (nolock) left join SF_YS_MZBLZDK D on a.ghxh=D.ghxh, SF_BRXXK b (nolock) left join YY_DQDMK C on b.qxdm = C.id
		WHERE b.blh = @HospNo and b.patid=a.patid  and a.ghsfbz=0 
		order by a.sjh desc

		if @@rowcount=0
		begin
			SELECT  @Name = b.hzxm , @Sex = CASE b.sex WHEN '男' THEN '1' WHEN  '女' THEN  '2' ELSE  '3' END ,   
			@Birthday = b.birth , @ChargeType = a.ybdm ,   
			@CureNo = b.patid, @TmpCardNo = b.cardno, @Dept = a.ksdm, 
			@Phone = b.lxdh, @Address = b.lxdz, @Zip = b.yzbm
			,@ToDoc = null, @csd = C.name, @career = null,@ClincDesc=D.zddm,@ghxh = a.ghxh
			FROM  SF_NBRJSK a (nolock)left join SF_YS_NMZBLZDK D on a.ghxh=D.ghxh, SF_BRXXK b (nolock) left join YY_DQDMK C on b.qxdm = C.id 
			WHERE b.blh = @HospNo and b.patid=a.patid and  a.ghsfbz=0  
			order by a.sjh desc
		
		  	-- wfy,增加对体检系统的考虑
		  	if @@rowcount=0 and exists(select 1 from sysobjects where name='usp_tj_yj_getpatinfo')
			begin
				exec('usp_tj_yj_getpatinfo "'+ @HospNo + '","'+ @CardNo + '","'+ @ApplyNo + '"')
				return
			end
					
		end

		set rowcount 0
  
		if (RTrim(@Birthday) ='') or (@Birthday is null)
			select @Age = -9999,@Birthday = null  
		else
		  	SELECT  @Age = DATEDIFF(YEAR , @Birthday , GETDATE())
	END  
	--查找该病人是否是干保病人
	if exists(select 1 from YY_YBFLK where ybdm = @ChargeType and pzlx in ('10','11') and bjqkdm = 1)
		select @WardOrReg = 2

	select @Name = replace(@Name, '○', ''), @Name = replace(@Name, '●', ''),
		@Name = replace(@Name, '☆', ''), @Name = replace(@Name, '★', '')

	INSERT into #Tmp VALUES ( @HospNo, @TmpCardNo, @Name , @Sex , @Age , @Birthday , @Dept , @Ward ,   
  		@BedNo , @ChargeType , @ToDoc , @CureNo,@ClincDesc,@WardOrReg, @Phone, @Address, @Zip, @csd, @career,@brzt,@ghxh)  
END  
ELSE IF LTRIM(RTRIM(@CardNo)) <> ''  
BEGIN  
	IF @WardOrReg = 1  
	BEGIN  
		SELECT  @Name = A.hzxm , @Sex = CASE A.sex WHEN '男' THEN '1' WHEN  '女' THEN  '2' ELSE  '3' END ,   
		@Birthday = A.birth , @ChargeType = A.ybdm ,   
		@CureNo = A.syxh, @TmpHospNo = A.blh ,@Dept = A.ksdm , @Ward = A.bqdm , @BedNo = A.cwdm,
		@ToDoc = A.ysdm, @ClincDesc = A.zddm, @Phone = B.lxdh, @Address = B.lxdz, @Zip = B.lxyb
		,@csd = C.name, @career = D.name,@brzt = A.brzt 
		FROM  ZY_BRSYK A, ZY_BRXXK B left join  YY_DQDMK C on B.csd_x = C.id left join YY_ZYDMK D on B.zybm = D.id 
		WHERE A.patid = B.patid 
		   and A.cardno = @CardNo and A.brzt not in (0,3,8,9)  
  
		if (RTrim(@Birthday) ='') or (@Birthday is null)
			select @Age = -9999,@Birthday = null  
		else
		SELECT  @Age = DATEDIFF(YEAR , @Birthday , GETDATE()) + 1  
	END
	else if @WardOrReg =9 --院内体检类：上海市中医需求,通过HIS的职工编码库取基本信息。
	begin
		set rowcount 1
		SELECT @Name = name , @Sex = CASE sex WHEN '男' THEN '1' WHEN  '女' THEN  '2' ELSE  '3' END ,   
		@Birthday = birth,
		@CureNo = id, @Dept = ks_id , @Ward = bq_id 
		FROM  YY_ZGBMK
		WHERE id = @CardNo
		set rowcount 0
	end	  
	ELSE  
 	BEGIN  
		set rowcount 1
		SELECT  @Name = b.hzxm , @Sex = CASE b.sex WHEN '男' THEN '1' WHEN  '女' THEN  '2' ELSE  '3' END ,   
		@Birthday = b.birth , @ChargeType = a.ybdm , 
		@TmpHospNo = b.blh,  
		@CureNo = b.patid, @TmpCardNo = b.cardno, @Dept = a.ksdm,
		@Phone = b.lxdh, @Address = b.lxdz, @Zip = b.yzbm
		,@ToDoc = null, @csd = C.name, @career = null,@ClincDesc=D.zddm,@ghxh = a.ghxh
		FROM  SF_BRJSK a (nolock) left join SF_YS_MZBLZDK D on a.ghxh=D.ghxh, SF_BRXXK b (nolock) left join  YY_DQDMK C on b.qxdm = C.id

		WHERE b.cardno = @CardNo and b.patid=a.patid and a.ghsfbz=0  
		order by a.sjh desc

		if @@rowcount=0
		begin
			SELECT  @Name = b.hzxm , @Sex = CASE b.sex WHEN '男' THEN '1' WHEN  '女' THEN  '2' ELSE  '3' END ,   
			@Birthday = b.birth , @ChargeType = a.ybdm , 
			@TmpHospNo = b.blh,  
			@CureNo = b.patid, @TmpCardNo = b.cardno, @Dept = a.ksdm,
			@Phone = b.lxdh, @Address = b.lxdz, @Zip = b.yzbm
			,@ToDoc = null, @csd = C.name, @career = null,@ClincDesc=D.zddm,@ghxh = a.ghxh
			FROM  SF_NBRJSK a (nolock) left join SF_YS_NMZBLZDK D on a.ghxh=D.ghxh, SF_BRXXK b (nolock) left join YY_DQDMK C on b.qxdm = C.id 
			WHERE b.cardno = @CardNo and b.patid=a.patid and a.ghsfbz=0  
			order by a.sjh desc

		  	-- wfy,增加对体检系统的考虑
		  	if @@rowcount=0 and exists(select 1 from sysobjects where name='usp_tj_yj_getpatinfo')
			begin
				exec('usp_tj_yj_getpatinfo "'+ @HospNo + '","'+ @CardNo + '","'+ @ApplyNo + '"')
				return
			end
					
		end

  		set rowcount 0
  
		if (RTrim(@Birthday) ='') or (@Birthday is null)
			select @Age = -9999,@Birthday = null  
  		else
	  		SELECT  @Age = DATEDIFF(YEAR , @Birthday , GETDATE()) + 1  
	END  
	--查找该病人是否是干保病人
	if exists(select 1 from YY_YBFLK where ybdm = @ChargeType and pzlx in ('10','11') and bjqkdm = 1)
		select @WardOrReg = 2

	select @Name = replace(@Name, '○', ''), @Name = replace(@Name, '●', ''),
		@Name = replace(@Name, '☆', ''), @Name = replace(@Name, '★', '')

 	INSERT into #Tmp VALUES ( @TmpHospNo, @CardNo, @Name , @Sex , @Age , @Birthday , @Dept , @Ward ,   
  		@BedNo , @ChargeType , @ToDoc , @CureNo,@ClincDesc,@WardOrReg, @Phone, @Address, @Zip, @csd, @career,@brzt,@ghxh)  
END  
  
SELECT  HospNo, CardNo, PatName, Sex,Age, Birthday, ApplyDept, 
	Ward, BedNo, ChargeType, ToDocCode, CureNo, ClincDesc, wardorreg, 
	Phone, Address,Zip, Csd, Career,'岁' As AgeUnit,brzt,ghxh 
FROM #Tmp       
return



GO
/****** Object:  StoredProcedure [dbo].[procModifyProfileCanExceedMaxBooking]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[procModifyProfileCanExceedMaxBooking]
@userName nvarchar(128),
@CanExceedMaxBooking int
as
begin
declare @UserID nvarchar(128)
set @UserID = '##'
select @UserID =userguid from tbUser where LocalName =@userName
if not exists (select 1 from tbUserProfile where UserGuid=@UserID and Name='CanExceedMaxBooking')
begin
 INSERT INTO tbUserProfile (NAME ,MODULEID ,ROLENAME ,USERGUID ,VALUE ,EXPORTABLE ,PROPERTYDESC ,PROPERTYOPTIONS ,INHERITANCE ,PROPERTYTYPE ,ISHIDDEN ,ORDERINGPOS ,DOMAIN ) 
		VALUES ('CanExceedMaxBooking','0H00','',@UserID,CAST(@CanExceedMaxBooking as nvarchar), 0,'','', 0, 11, 0,'5',(select top 1 value from tbSystemProfile where Name ='Domain'))		
end
else 
begin
	update tbUserProfile set value= CAST(@CanExceedMaxBooking as nvarchar) where UserGuid=@UserID and Name ='CanExceedMaxBooking'
end
end


GO
/****** Object:  StoredProcedure [dbo].[procMpDropColConstraint]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

    create procedure [dbo].[procMpDropColConstraint]
    	@TableName NVARCHAR(128),
    	@ColumnName NVARCHAR(128)
    as
    begin
    	if OBJECT_ID(N'#t', N'TB') is not null
    		drop table #t
    	
    	-- 查询主键约束、非空约束等
    	select ROW_NUMBER() over(order by CONSTRAINT_NAME) id, CONSTRAINT_NAME into #t from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_CATALOG=DB_NAME()
    		and TABLE_NAME=@TableName and COLUMN_NAME=@ColumnName
    		
    	-- 查询默认值约束
    	declare @cdefault int, @cname varchar(128)
    	select @cdefault=cdefault from sys.syscolumns where name=@ColumnName and id=OBJECT_ID(@TableName)
    			
    	select @cname=name from sys.sysobjects where id=@cdefault
    	if @cname is not null
    		insert into #t select coalesce(max(id), 0)+1, @cname from #t	

    	declare @i int, @imax int
    	select @i=1, @imax=max(id) from #t

    	while @i <= @imax
    	begin
    		select @cname=CONSTRAINT_NAME from #t where id=@i
    		exec('alter table ' + @tablename + ' drop constraint ' + @cname)
    		set @i = @i + 1	
    	end

    	drop table #t

    end



GO
/****** Object:  StoredProcedure [dbo].[procMpDropColConstraintAndIndex]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

    create procedure [dbo].[procMpDropColConstraintAndIndex]
    	@TableName NVARCHAR(128),
    	@ColumnName NVARCHAR(128)
    as
    begin
    	exec dbo.procMpDropColConstraint @TableName, @ColumnName
    	exec dbo.procMpDropColumnIndexes @TableName, @ColumnName
    end



GO
/****** Object:  StoredProcedure [dbo].[procMpDropColumnIndexes]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

    create procedure [dbo].[procMpDropColumnIndexes]
    	@TableName NVARCHAR(128),
    	@ColumnName NVARCHAR(128)
    as
    begin
    	if OBJECT_ID(N'#t', N'TB') is not null
    		drop table #t
    	create table #t
    	(
    		id int,		
    		name nvarchar(128)
    	)
    	
    	insert into #t select * from fnGetColumnIndexes(@TableName, @ColumnName)
    	
    	-- 删除索引
    	declare @i int, @imax int, @idxname nvarchar(128)
    	
    	select @i=1, @imax=COALESCE(max(id), 0) from #t
    	while @i<=@imax 
    	begin
    		select @idxname=name from #t
    		EXEC('drop index ' + @idxname + ' on ' + @tablename)
    		set @i=@i+1
    	end
    	
    	drop table #t
    end



GO
/****** Object:  StoredProcedure [dbo].[procOrderStatistic]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[procOrderStatistic]
		@strSQL varchar(8000)
AS

	BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
      EXEC(@strSQL )
END


GO
/****** Object:  StoredProcedure [dbo].[procPacsQcNotifyUpd]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procPacsQcNotifyUpd]
(	
	@AccNo        varchar(32),
	@PatientID		varchar(128),
	@ModalityName  varchar(32),
    @OperatorName varchar(64),
    @PerformedStartdt DateTime,	
    @PerformedEnddt	DateTime,
	@SourcePatientID varchar(32),
	@SourceAccNo varchar(32),
	@SourceAccNoEmpty varchar(32)
)
AS
BEGIN   
        DECLARE @nCount int
        DECLARE @OperatorGuid varchar(128)
        DECLARE @OrderGuid varchar(128)
        DECLARE @SourceOrderGuid varchar(128)
        DECLARE @Rpguid varchar(128)  
        DECLARE @nModify int
        SET @nModify=1  --Set Default Value to 1 by LCF, 2008-09-03
		
    	select @SourceOrderGuid=OrderGuid from tbRegOrder where AccNo=@SourceAccNo 
    	select @OrderGuid=OrderGuid from tbRegOrder where AccNo=@AccNo

    	if(@OrderGuid is null or len(@OrderGuid)=0)
		begin
    		--如果目标不存在,那就只把源置为已登记
		   if(@SourceAccNoEmpty='Y')--If sourceaccnoempty is 'Y',then restore the source to origin status.
                BEGIN                    
             	    if(len(@SourceOrderGuid)>0) 
             	    BEGIN                       
                        DECLARE cursor4 CURSOR FAST_FORWARD FOR SELECT ProcedureGuid FROM tbRegProcedure where OrderGuid=@SourceOrderGuid FOR READ ONLY   	                 
	                    OPEN  cursor4
	                    FETCH NEXT FROM cursor4 INTO @Rpguid
	                    WHILE (@@FETCH_STATUS) = 0   
	                    BEGIN
                          UPDATE tbRegProcedure SET IsExistImage=0,Status=20,ExamineDt =NULL WHERE ProcedureGuid=@Rpguid  and status<=50                     
	                      FETCH NEXT FROM cursor4 INTO @Rpguid
                        END  
						DEALLOCATE cursor4
                    END
                END

            	return
		end  	 

        select @nCount =count(*) from tbRegProcedure where OrderGuid=@OrderGuid and status<=50
        if (@nCount>0)
        BEGIN  

			--目标未写报告，把目标置为已检查，源置为已登记
            if(len(@OperatorName)>0)--get the guid of operator
            BEGIN           
                select @OperatorGuid=UserGuid from tbUser where LoginName=@OperatorName
            END                        
            
        
            DECLARE cursor1 CURSOR FAST_FORWARD FOR   SELECT ProcedureGuid FROM tbRegProcedure where OrderGuid=@OrderGuid and status<50 FOR READ ONLY   
	 
	        OPEN  cursor1
	        FETCH NEXT FROM cursor1 INTO @Rpguid
	        WHILE (@@FETCH_STATUS) = 0   
	        BEGIN	
                set @nModify=1
                if (len(@ModalityName)>0)--Update modality
                BEGIN
                    if(len(@OperatorGuid)>0)--Update operator
                        UPDATE tbRegProcedure SET IsExistImage=1,Status=50,Technician=@OperatorGuid,Modality=@ModalityName,ExamineDt =@PerformedEnddt WHERE ProcedureGuid=@Rpguid 
                    else   
                        UPDATE tbRegProcedure SET IsExistImage=1,Status=50,Modality=@ModalityName,ExamineDt =@PerformedEnddt WHERE ProcedureGuid=@Rpguid 
                END
                ELSE
                BEGIN
                    if(len(@OperatorGuid)>0)
                        UPDATE tbRegProcedure SET IsExistImage=1,Status=50,Technician=@OperatorGuid,ExamineDt =@PerformedEnddt WHERE ProcedureGuid=@Rpguid 
                    else   
                        UPDATE tbRegProcedure SET IsExistImage=1,Status=50,ExamineDt =@PerformedEnddt WHERE ProcedureGuid=@Rpguid 
           
                END        
               FETCH NEXT FROM cursor1 INTO @Rpguid
            END
		    DEALLOCATE cursor1  
            if(@nModify=1)  
            BEGIN
             if(@SourceAccNoEmpty='Y')--If sourceaccnoempty is 'Y',then restore the source to origin status.
                BEGIN                    
          	    if(len(@SourceOrderGuid)>0) 
             	    BEGIN                       
                        DECLARE cursor2 CURSOR FAST_FORWARD FOR SELECT ProcedureGuid FROM tbRegProcedure where OrderGuid=@SourceOrderGuid FOR READ ONLY   	                 
	                    OPEN  cursor2
	                    FETCH NEXT FROM cursor2 INTO @Rpguid
	                    WHILE (@@FETCH_STATUS) = 0   
	                    BEGIN
                          UPDATE tbRegProcedure SET IsExistImage=0,Status=20,ExamineDt =NULL WHERE ProcedureGuid=@Rpguid  and status<=50                     
	                      FETCH NEXT FROM cursor2 INTO @Rpguid
                        END  
						DEALLOCATE cursor2
                    END
                END
            END    
        END     
		else
		begin
			--如果目标已写报告，并且源未写报告，那就只把源置为已登记
		   if(@SourceAccNoEmpty='Y')--If sourceaccnoempty is 'Y',then restore the source to origin status.
                BEGIN                    
             	    if(len(@SourceOrderGuid)>0) 
             	    BEGIN                       
                        DECLARE cursor3 CURSOR FAST_FORWARD FOR SELECT ProcedureGuid FROM tbRegProcedure where OrderGuid=@SourceOrderGuid FOR READ ONLY   	                 
	                    OPEN  cursor3
	                    FETCH NEXT FROM cursor3 INTO @Rpguid
	                    WHILE (@@FETCH_STATUS) = 0   
	                    BEGIN
                          UPDATE tbRegProcedure SET IsExistImage=0,Status=20,ExamineDt =NULL WHERE ProcedureGuid=@Rpguid  and status<=50                     
	                      FETCH NEXT FROM cursor3 INTO @Rpguid
                        END  
						DEALLOCATE cursor3
                    END
                END
                
		end	
    
END


GO
/****** Object:  StoredProcedure [dbo].[procPatientExistDecide]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
-- =====================================================================================================
-- Author: bruce deng
-- Create date: 2014-2-12
-- Description: RISGC系统新老病人判断
-- Parameters: 
/*@globalid        可选
--@rispatientid    可选
--@hisid           必填
--@patientname     必填
--@site            必填
*/
 
--返回值:返回0行说明病人不存在, 返回1行说明在RIS系统中找到一个病人 返回多行说明在RIS系统中匹配多个病人
-- =====================================================================================================
CREATE PROCEDURE [dbo].[procPatientExistDecide] 
-- Add the parameters for the stored procedure here
@globalid nvarchar(64),          
@rispatientid nvarchar(64),
@hisid nvarchar(64),
@patientname nvarchar(64), 
@site nvarchar(64) 
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
 
 
declare @searchpatientbyname int 
declare @searchbynamenotexisthisid int 
declare @patientcount int
set @patientcount=0
 
 
if exists(select value from tbSiteProfile where name='SearchPatientByName' and site=@site)
select @searchpatientbyname=value from tbSiteProfile where name='SearchPatientByName' and site=@site
else
select @searchpatientbyname=value from tbSystemProfile where name='SearchPatientByName'
 
if exists(select value from tbSiteProfile where name='SearchByNameNotExistHisid' and site=@site)
select @searchbynamenotexisthisid =value from tbSiteProfile where name='SearchByNameNotExistHisid' and site=@site
else
select @searchbynamenotexisthisid =value from tbSystemProfile where name='SearchByNameNotExistHisid'
 
if(len(@rispatientid)>0)
begin
SELECT * FROM tbPatientList WHERE PatientID=@rispatientid
return
end
 
if(len(@globalid)>0)
begin
SELECT * FROM tbPatientList WHERE GlobalID=@globalid
return
end

-- ===================================================================================================
-- Description:增加判断hisid是否为空字符窜的情况
-- =================================================================================================== 
if(LEN(@hisid)>0)
Begin
	if(@searchpatientbyname=0)
	begin
		SELECT @patientcount=count(1) FROM tbPatientList with(nolock) WHERE PatientGuid in(select patientguid from tbAccessionNumberList with(nolock) where hisid=@hisid)
		if(@patientcount>0)
		begin
			SELECT * FROM tbPatientList with(nolock)  WHERE PatientGuid in(select patientguid from tbAccessionNumberList where hisid=@hisid)			
			return
		end
		else		
		begin
		     if(@searchbynamenotexisthisid=1)
		     begin
				select * from tbPatientList with(nolock) where LocalName = @patientname
				return
		     end
		end
	end
	else
	begin
		SELECT * FROM tbPatientList with(nolock)  WHERE PatientGuid in(select patientguid from tbAccessionNumberList with(nolock) where hisid=@hisid) Union SELECT * FROM tbPatientList with(nolock) WHERE LocalName=@patientname
		return
	end
End
 
END


GO
/****** Object:  StoredProcedure [dbo].[procPatientUpd]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procPatientUpd]
(
	@LocalName                varchar(32),
	@EnglishName              varchar(32),
	@ReferenceNo              varchar(64),
	@Birthday                 datetime,
	@Gender                   varchar(8),
	@Address                  varchar(128),
	@Telephone                varchar(64),
	@IsVIP                    int,
	@Comments                 varchar(512),
	@PATIENTID       varchar(16)
)
AS
BEGIN   
    UPDATE tbRegPatient
       SET 
		LocalName                 = @LocalName,
		EnglishName               = @EnglishName,
		ReferenceNo               = @ReferenceNo,
		Birthday                  = @Birthday,
		Gender                    = @Gender,
		Address                   = @Address,
		Telephone                 = @Telephone,
		IsVIP                     = @IsVIP,		
		Comments                  = @Comments
        WHERE 	PATIENTID = @PATIENTID   
END


GO
/****** Object:  StoredProcedure [dbo].[procPictureScoreStat]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procPictureScoreStat]
@ConditionStr nvarchar(4000)
as
Begin

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here

	create table #qualityStatTmp
(
	StatItem	nvarchar(512) null,
	Amount		bigint null,
	AllProportion	nvarchar(128) null, ---站总图像比例
	SampleProportion	nvarchar(128) null,----占采样图像比例
	AppraisedProportion	nvarchar(128) null,---- 占已评分图像比例
)


	declare @totalCount         real --总数
	declare @StatCount		    real --参评数
	declare @ItemCount			bigint--every item count
	declare @AppraiseCount		real ---已评分数
	
	declare @AddDataSql				nvarchar(4000)
	declare @sql					nvarchar(4000)
	
	

	--type=0 picture quality
	set @sql=N'select @totalCount=count(*) from tbRegProcedure where IsExistImage=1 and Status <> ''25'''
	exec sp_executesql @sql,N'@totalCount float output',@totalCount output
	set @AddDataSql=N'insert into #qualityStatTmp(StatItem,Amount,AllProportion,SampleProportion,AppraisedProportion) values ('+
					'''全部图像'''+','''+cast(@totalCount as varchar)+''','+'''100.00%'',''-'',''-'')'
	exec (@AddDataSql)
	
	set @sql=N'select @StatCount=count(*) from tbRegProcedure
				left join tbUser on tbUser.UserGuid=tbRegProcedure.Technician 
				 where tbRegProcedure.IsExistImage=1 and tbRegProcedure.Status <> ''25'''+@ConditionStr
	
	exec sp_executesql @sql,N'@StatCount int output',@StatCount output
	
	set @sql=N'select @AppraiseCount=count(*) from tbRegProcedure 
				inner join tbQualityScoring on tbRegProcedure.procedureGuid =tbQualityScoring.AppraiseObject 
				left join tbUser on tbUser.UserGuid=tbRegProcedure.Technician 
				where tbRegProcedure.IsExistImage=1 and tbRegProcedure.Status <> ''25'' and type = 0 '+@ConditionStr
	exec sp_executesql @sql,N'@AppraiseCount int output',@AppraiseCount output

	if  @totalCount<>0

		set @AddDataSql=N'insert into #qualityStatTmp(StatItem,Amount,AllProportion,SampleProportion,AppraisedProportion) values ('+
					'''统计图像'''+','''+cast(@StatCount as varchar)+''','''+cast(cast(@StatCount*100/@totalCount as Decimal(30,2)) as varchar)+'%'',''100.00%'',''-'')'
	else 
		set @AddDataSql=N'insert into #qualityStatTmp(StatItem,Amount,AllProportion,SampleProportion,AppraisedProportion) values ('+
					'''统计图像'''+','''+cast(@StatCount as varchar)+''','''+'0.00%'',''100%'',''-'',)'
	exec (@AddDataSql)
	
	if @StatCount<>0
		insert into #qualityStatTmp values('未评分',(@statCount-@AppraiseCount),cast(cast((@statCount-@AppraiseCount)*100/@totalCount as Decimal(30,2)) as varchar)+'%',
		cast(cast((@statCount-@AppraiseCount)*100/@StatCount as Decimal(30,2)) as varchar)+'%','-')
	else 
		insert into #qualityStatTmp values('未评分',0,	'0.00%','0.00%','-')

	if @StatCount<>0
		insert into #qualityStatTmp values('已评分',@AppraiseCount,cast(cast(@AppraiseCount*100/@totalCount as Decimal(30,2)) as varchar)+'%',
		cast(cast((@AppraiseCount)*100/@StatCount as Decimal(30,2)) as varchar)+'%','100.00%')
	else 
		insert into #qualityStatTmp values('已评分',0,	'0.00%','100.00%','-')
    
    
	set @sql=N'insert into #qualityStatTmp(StatItem,Amount) select result,count(result) from tbRegProcedure inner join tbQualityScoring on tbRegProcedure.procedureGuid =tbQualityScoring.AppraiseObject
			left join tbUser on tbUser.UserGuid=tbRegProcedure.Technician 
			 where tbRegProcedure.IsExistImage=1 and tbRegProcedure.Status <> ''25'' and type = 0 '+@ConditionStr+'group by tbQualityScoring.result'

	exec (@sql)
	
	--use cursor
	declare @Value    nvarchar(128)		
	declare @Text		nvarchar(512)
	declare @amount				nvarchar(128)
	declare @Proportion			nvarchar(128)
	declare score_cursor cursor for
	select Value ,Text from tbDictionaryValue where tag=57  and Text <> '未评分'

--	set @sql=N'select @ItemCount=count(*) from tbQualityScoring inner join tbRegProcedure  on procedureGuid=AppraiseObject 
--	where tbQualityScoring.type=0 and tbQualityScoring.result=@Value '+ @ConditionStr
--	set @AddDataSql=N'insert into #qualityStatTmp(StatItem,Amount,Proportion) values (
--						@Text,@amount,@proportion)'
	
	print 'open cursor'
	open score_cursor
	print  'fetch cursor'
	Fetch Next from score_cursor into @Value,@Text
	while @@Fetch_Status=0
	begin
		
		if @StatCount<>0
			begin
			if exists(select 1 from #qualityStatTmp where StatItem=@Value)
				update #qualityStatTmp set StatItem=@Text ,AllProportion=cast(cast(Amount*100/@totalCount as Decimal(30,2)) as varchar)+'%',
				SampleProportion=cast(cast(Amount*100/@StatCount as Decimal(30,2)) as varchar)+'%',
				AppraisedProportion =cast(cast(Amount*100/@AppraiseCount as Decimal(30,2)) as varchar)+'%' where StatItem=@Value
			else 
				insert into #qualityStatTmp values(@Text,0,'0.00%','0.00%','0.00%')
			end
			--set @proportion=cast(cast(@ItemCount*100/@StatCount as Decimal(30,2)) as varchar)+'%'
		else 
			begin
			if exists(select 1 from #qualityStatTmp where StatItem=@Value)
				update #qualityStatTmp set StatItem=@Text ,AllProportion='0.00%',SampleProportion='0.00%',AppraisedProportion='0.00%' where StatItem=@Value
			else 
				insert into #qualityStatTmp values(@Text,0,'0.00%','0.00%','0.00%')
			end
			--set @proportion='0.00%'
			--exec sp_executesql @AddDataSql,N'@Text nvarchar(500),@amount nvarchar(128),@proportion nvarchar(128)',@Text,@amount,@proportion
		if(@@error<>0)
		begin
			rollback transaction
		end
		Fetch Next from score_cursor into @Value,@Text
	end
	close score_cursor
	deallocate score_cursor
	
	exec('select * from #qualityStatTmp')
	
	drop table #qualityStatTmp
		
end



GO
/****** Object:  StoredProcedure [dbo].[procPositiveStatisitc]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[procPositiveStatisitc]
		@strSQL varchar(8000)
AS

	BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
      EXEC(@strSQL )
END


GO
/****** Object:  StoredProcedure [dbo].[procPostEvent]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procPostEvent]
       @EventType nvarchar(128)
      ,@MessageType nvarchar(128)
      ,@Event xml
      ,@Priority int
      ,@Site nvarchar(64)
AS
BEGIN
declare @EventsEnabledForNotificationCenter nvarchar(max)
select @EventsEnabledForNotificationCenter = value from tbSiteProfile where Name ='EventsEnabledForNotificationCenter' and Site =@Site
if(@EventsEnabledForNotificationCenter is null)--no siteprofile config item so use systemprofile value
	begin
		select @EventsEnabledForNotificationCenter = value from tbSystemProfile where Name ='EventsEnabledForNotificationCenter'
	end
if(isnull(LEN(@EventsEnabledForNotificationCenter),0)=0)--no value in profile so no need to post event
return

--if no EventsEnabledForNotificationCenter match to @EventType ,no need to post event
if not exists( select 1 from fnStrSplit(@EventsEnabledForNotificationCenter,'|') where string = @EventType)
return

insert into RISHippa..tEvent(Guid,EventType,MessageType,Event,Processed,Result,Priority,CreateDt,Site,Domain)
values(NEWID(),@EventType,@MessageType,@Event,0,NULL,@Priority,GETDATE(),@Site,(select value from tbSystemProfile where Name = 'domain'))
END


GO
/****** Object:  StoredProcedure [dbo].[procPostMessage]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procPostMessage]
	   @EventGuid 	nvarchar(128)
	  ,@MessageType nvarchar(256)
      ,@Message xml
      ,@Priority int
      ,@Site nvarchar(64)
AS
BEGIN
declare @Guid nvarchar(128) = Convert(nvarchar(128),@Message.query('Message/Guid/text()'))
insert into RISHippa..tMessage(EventGuid,Guid,MessageType,Message,Priority,CreateDt,MsgID,Processed,Result, Site,Domain)
values(@EventGuid,@Guid,@MessageType,@Message,@Priority,GETDATE(),'',0,NULL,@Site,(select value from tbSystemProfile where Name = 'domain'))
END


GO
/****** Object:  StoredProcedure [dbo].[procPrintedReport]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procPrintedReport]
	@AccessionNumber nvarchar(max), 
	@ReportGuid nvarchar(max)
AS
BEGIN
	SET NOCOUNT ON;

    if LEN(@reportguid) > 0
    begin
		update tbReport set isPrint=1 where Status=120 AND reportguid=@ReportGuid
    end
    else if LEN(@AccessionNumber) > 0
    begin
		update tbReport set isPrint=1 where Status=120 AND reportguid in 
			(select reportguid from tbRegProcedure where OrderGuid in 
				(select OrderGuid from tbRegOrder where ACCNO=@AccessionNumber)
			)
    end
END


GO
/****** Object:  StoredProcedure [dbo].[procQualityScoringList]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[procQualityScoringList]

    @PageIndex  integer,
    @PageSize integer,
    @Where varchar(8000),  
    @TotalCount integer output,
    @RandomNum integer--0~65535, 0 = not use radom

AS 
BEGIN
SET NOCOUNT ON;
declare @strSQL nvarchar(max)
declare @strRanSQLTop nvarchar(16)
declare @strRanSQLOrder nvarchar(32)

 --drop ##teachinglisttemp if exists
 if object_id('[tempdb].[dbo].##qualityscoringlisttemp') is not null
  begin
   drop table ##qualityscoringlisttemp
  end 
if(@RandomNum <> 0)
begin
set @strRanSQLTop = ' top('+cast(@RandomNum as nvarchar)+') '
set @strRanSQLOrder = ' order by newid() '
end
else
begin
set @strRanSQLTop = ''
set @strRanSQLOrder = ''
end

SET @strSQL='select' +@strRanSQLTop + ' ROW_NUMBER() Over(order by ExamineDt desc) as rowNum,
   tbRegProcedure.OrderGuid,tbRegProcedure.ProcedureGuid,tbRegProcedure.Status,tbRegOrder.AccNo,tbRegPatient.PatientID,tbRegPatient.LocalName,tbRegProcedure.ExamSystem,tbRegProcedure.Modality,
   (SELECT Text from tbDictionaryValue where tbDictionaryValue.Value=tbRegProcedure.Status and tbDictionaryValue.Tag=13) as RPStatus,
   (SELECT LocalName from tbUser where tbUser.UserGuid=tbRegProcedure.Technician) as Technician,
    tbRegPatient.Gender, tbRegOrder.ApplyDept, tbRegOrder.PatientType, tbRegProcedure.RPDesc,tbRegProcedure.Bodypart,tbRegProcedure.ExamineDt,tbReport.CreateDt,tbReport.SubmitDt,tbReport.FirstApproveDt,tbRegOrder.AssignDt,tbRegProcedure.ModalityType,tbRegProcedure.CheckingItem,tbRegProcedure.Technician as TechnicianGuid,tbReport.ReportGuid as tbReport__ReportGuid,tbReport.SubmitSite as tbReport__SubmitSite,tbReport.ScoringVersion as tbReport__ScoringVersion,tbQualityScoring.Result as tbQualityScoring__Result,tbQualityScoring.Result2 as tbQualityScoring__Result2,tbQualityScoring.Result3 as tbQualityScoring__Result3,AppraiseObject,tbQualityScoring.Comment as tbQualityScoring__Comment,tbReport.ReportQuality as tbReport__ReportQuality,tbReport.ReportQuality2 as tbReport__ReportQuality2,tbReport.ReportQualityComments as tbReport__ReportQualityComments,tbReport.AccordRate as tbReport__AccordRate
   INTO ##qualityscoringlisttemp
   FROM tbRegPatient,tbRegOrder,tbRegProcedure left join tbQualityScoring on tbRegProcedure.ProcedureGuid = tbQualityScoring.AppraiseObject left join tbReport on tbReport.ReportGuid = tbRegProcedure.ReportGuid
   where tbRegPatient.PatientGuid=tbRegOrder.PatientGuid and tbRegOrder.OrderGuid=tbRegProcedure.OrderGuid and tbRegProcedure.IsExistImage = 1  and tbRegProcedure.Status <> ''25'' 
   '+@Where + @strRanSQLOrder
                      
EXEC(@strSQL)



DECLARE @LowNum integer
DECLARE @HighNum integer
set @PageIndex=@PageIndex+1
set @LowNum=(@PageIndex-1)*@PageSize+1
set @HighNum=@PageIndex*@PageSize


set @strSQL = N'select @TotalCount = COUNT(1) from ##qualityscoringlisttemp'
exec sp_executesql @strSQL,N'@TotalCount int output',@TotalCount output


--print(@LowNum)
--print(@HighNum)
if(len(@strRanSQLTop) > 0 or @PageIndex = 0) ---@PageIndex = 0 for exporting all records
begin
set @strSQL='SELECT * FROM ##qualityscoringlisttemp'
end
else
begin
set @strSQL='SELECT * FROM ##qualityscoringlisttemp where rowNum between '+cast(@LowNum as nvarchar)+' and '+cast(@HighNum as nvarchar)
end
EXEC(@strSQL)

END


GO
/****** Object:  StoredProcedure [dbo].[procReferralDeleteFromBusiness]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
Create PROCEDURE [dbo].[procReferralDeleteFromBusiness]
 -- Add the parameters for the stored procedure here
 @orderId nvarchar(128)
AS
BEGIN
       
     declare @reportId nvarchar(128)
     --declare @PatientGuid nvarchar(128)
     
     --select @PatientGuid=patientGuid from tbRegOrder where OrderGuid = @orderId
     --delete tbRegProcedure
     
     Declare reportCur Cursor  
     for select  distinct reportGuid from tbRegProcedure rp where rp.OrderGuid =@orderId
     open reportCur
     Fetch next from reportCur into @reportId
     while @@FETCH_STATUS = 0
     begin
        --delete from tbReportList where ReportGuid = @reportId
        delete from tbReportFile where ReportGuid =@reportId
  delete from tbReport where tbReport.ReportGuid = @reportId
  Fetch next from reportCur into @reportId
     end
     close reportCur
     deallocate reportCur     
     
     delete from tbRegProcedure where OrderGuid = @orderId     
     delete from tbRequisition where AccNo in (select AccNo from tbRegOrder where OrderGuid =@orderId)
     delete from tbRegOrder where OrderGuid = @orderId    
            
end


GO
/****** Object:  StoredProcedure [dbo].[procReferralPage]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procReferralPage]
	-- Add the parameters for the stored procedure here
	@PageIndex  integer,
    @PageSize integer,
    @Where varchar(8000),  
    @TotalCount integer output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @strSQL VARCHAR(8000)


	set @strSQL ='SELECT [ReferralID],[PatientID],[LocalName],[EnglishName],[Gender],[Birthday],[TelePhone],[Address],[AccNo],[ApplyDoctor],[ApplyDt],[ModalityType],[ProcedureCode],[CheckingItem],[HealthHistory],[Observation],[RefPurpose],[RPStatus],[RefStatus],[ExamDomain],[ExamAccNo],[CreateDt],[InitialDomain],[SourceDomain] ,[TargetDomain],[TargetSite],[SourceSite],[Direction],[IsExistSnapshot],[GetReportDomain],[BookingBeginDt],[BookingEndDt],'''' as OriginalBizData,'''' as PackagedBizData,[Scope],(select Count(Memo) from tbReferralLog a where (a.Memo is not null) and len(a.Memo)> 0 and a.ReferralID = tbReferralList.ReferralID ) as MemoCount, ROW_NUMBER() OVER (ORDER BY [CreateDt] DESC ) AS ROWNUM FROM tbReferralList
					Where 1=1 ' + @Where

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	select @TotalCount=0

	DECLARE @LowNum integer
	DECLARE @HighNum integer
	set @PageIndex=@PageIndex+1
	set @LowNum=(@PageIndex-1)*@PageSize+1
	set @HighNum=@PageIndex*@PageSize

	SET @strSQL ='SELECT * FROM ('+@strSQL+') as t WHERE ROWNUM BETWEEN '+CAST(@LowNum AS VARCHAR) +' AND '+CAST(@HighNum AS VARCHAR)

	print @strSQL
	exec (@strSQL)

END


GO
/****** Object:  StoredProcedure [dbo].[procReferralPageCount]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[procReferralPageCount]
	-- Add the parameters for the stored procedure here
    @Where varchar(8000),  
    @TotalCount integer output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @strSQL NVARCHAR(4000)
    -- Insert statements for procedure here
    				
	set @strSQL ='SELECT @totalcount = count(*) FROM tbReferralList Where 1=1 '+ @Where
						
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	print (@strSQL)
	EXEC sp_executesql @strSQL, N' @TotalCount int output ', @TotalCount output


END


GO
/****** Object:  StoredProcedure [dbo].[procRegistration]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procRegistration]
	@AccNo VARCHAR(32),                 --
	@PatientID VARCHAR(32),
	@PatientName  VARCHAR(32),
    @EnglishName  VARCHAR(64),           
	@InHospitalNo VARCHAR(16),         --optional
	@InHospitalRegion VARCHAR(16),     --optional
	@ClinicNo  VARCHAR(16),            --optional
	@BedNo VARCHAR(16),                --optional
	@CurrentAge VARCHAR(16),           --optional 
	@Gender VARCHAR(8),               
	@PatientBirthday DATETIME,
	@ModalityType  VARCHAR(32),
	@Modality VARCHAR(32),              
	@ProcedureCode  VARCHAR(32), 
	@PatientType VARCHAR(32),         
	@ExamSystem  VARCHAR(32),         --optional    
	@ApplyDoctor  VARCHAR(64),        --optional
	@ApplyDept  VARCHAR(64),          --optional
	@Observation  VARCHAR(512),       --optional
	@HealthHistory VARCHAR(512),      --optional 
	@Address VARCHAR(128),            --optional
	@Telephone  VARCHAR(32),          --optional
	@IsVIP int                          
AS
BEGIN
	declare @nCount int
	declare @PatientGuid VARCHAR(64)
	declare @VisitGuid VARCHAR(64)
	declare @OrderGuid VARCHAR(64)
	SET @PatientGuid=''
	SET @VisitGuid=''
	SET @OrderGuid=''
	select @nCount =count(*) from tbRegPatient where PATIENTID=@PatientID
    if(@nCount>0)
	BEGIN
		--The patient has exists, get the patient guid 
		select @PatientGuid=PATIENTGUID FROM tbRegPatient WHERE PATIENTID=@PatientID
	END
	
	select @nCount=count(*) from tbRegOrder WHERE ACCNO=@AccNo
	if(@nCount>0)
	BEGIN
		--The order has exists, get the order guid
		select @OrderGuid=OrderGuid from tbRegOrder WHERE ACCNO=@AccNo
	END
    BEGIN TRAN
	if(len(@PatientGuid)=0 or @PatientGuid is null)
	BEGIN
		--Is new patient, so insert patient information to ris database
		select @PatientGuid=newid()
		--
		INSERT INTO tbRegPatient(PATIENTGUID,PATIENTID, LOCALNAME,ENGLISHNAME,BIRTHDAY, GENDER, ADDRESS, TELEPHONE, ISVIP) 
								VALUES(@PatientGuid,@PatientID,@PatientName,@EnglishName,@PatientBirthday,@Gender,@Address,@Telephone,@IsVIP)
	END


	if(len(@OrderGuid)=0 or @OrderGuid is null)
	BEGIN    -- 
		select @VisitGuid=newid()
		select @OrderGuid=newid()
		--Insert visit information


----------------------------------
		declare @nYear int
		declare @nMonth int
		declare @nDay int 
		declare @strUnit varchar(128)
		DECLARE @MonthNumber nvarchar(16)
		select  @MonthNumber = value from tbSystemProfile where name = 'MonthNumber'

		select @nYear=dbo.fnGetYear(@PatientBirthday,getdate())   
		select @nMonth=dbo.fnGetMonth(@PatientBirthday,getdate()) 
		select @nDay=datediff(dd,@PatientBirthday,getdate())+1
		

		if (@nYear=0 and @nMonth=0)
		begin
			set @strUnit = cast(@nDay as varchar(12))+' '+'Day'        
		end
		else
		begin	      
		   if(@nMonth<12 or @nMonth<@MonthNumber)
		   begin
				set @strUnit = cast(@nMonth as varchar(12))+' '+'Month'  
		   end
		   else
		   begin
			  set @strUnit = cast(@nYear as varchar(12))+' '+'Year'  
		   end	
		end	
---------------------
	
        --Insert reg ext information                            
		INSERT INTO TREGEXT(OBJECTGUID, DELEGATE, VALUE) VALUES(@VisitGuid,'Observation',@Observation)
		INSERT INTO TREGEXT(OBJECTGUID, DELEGATE, VALUE) VALUES(@VisitGuid,'HealthHistory',@HealthHistory)		
		--Insert order information
		INSERT INTO tbRegOrder	(ORDERGUID,VISITGUID, ACCNO, APPLYDEPT, APPLYDOCTOR,PATIENTGUID, INHOSPITALNO, CLINICNO, PATIENTTYPE, INHOSPITALREGION,ISEMERGENCY, BEDNO, CURRENTAGE)
					VALUES(@OrderGuid,@VisitGuid,@AccNo,@ApplyDept,@ApplyDoctor,@PatientGuid,@InHospitalNo,@ClinicNo,@PatientType,@InHospitalRegion,0,@BedNo,@strUnit)
        
        select @nCount=count(*) from tbDictionaryValue where tag=2 and (dictionaryvalue=@ApplyDept or description=@ApplyDept)
        if(@nCount=0)
        BEGIN
            INSERT INTO tbDictionaryValue(TAG,DICTIONARYVALUE,DESCRIPTION, SHORTCUTCODE) VALUES(2,@ApplyDept,@ApplyDept,'')            
        END
        
        select @nCount=count(*) from tbDictionaryValue where tag=8 and (dictionaryvalue=@ApplyDoctor or description=@ApplyDoctor)
        if(@nCount=0)
        BEGIN
            INSERT INTO tbDictionaryValue(TAG,DICTIONARYVALUE,DESCRIPTION, SHORTCUTCODE) VALUES(8,@ApplyDoctor,@ApplyDoctor,'')            
        END
	END
		
	if(len(@Modality)=0 or @Modality is null)
	BEGIN
		select @Modality=modality from tbModality where MODALITYTYPE=@ModalityType
	END

	--insert procedure information
	INSERT INTO tbRegProcedure	(PROCEDUREGUID,ORDERGUID,PROCEDURECODE,EXAMSYSTEM,MODALITYTYPE,MODALITY,STATUS,REGISTERDT,DEPOSIT)
					VALUES(newid(),@OrderGuid,@ProcedureCode,@ExamSystem,@ModalityType,@Modality,20,getdate(),0.0)

    IF (@@error!=0)
    BEGIN

        ROLLBACK TRAN
        RETURN(1)
    END    
    COMMIT TRAN
END



GO
/****** Object:  StoredProcedure [dbo].[procReglistPage]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   procedure   [dbo].[procReglistPage]
    @PageIndex   integer ,
    @PageSize   integer ,
    @Where   varchar ( MAX )
AS  
BEGIN
SET   NOCOUNT   ON ;
DECLARE   @strSQL   VARCHAR ( MAX )
if @PageIndex >= 0
begin
DECLARE   @LowNum   integer
DECLARE   @HighNum   integer
set   @PageIndex = @PageIndex + 1
set   @LowNum =( @PageIndex - 1 )* @PageSize + 1
set   @HighNum = @PageIndex * @PageSize
SET   @strSQL = 'SELECT * FROM (SELECT tbRegPatient.PatientID,tbRegPatient.LocalName,tbRegPatient.EnglishName,CONVERT(VARCHAR(10), birthday, 120) as birthday,tbRegPatient.Telephone,
      tbRegPatient.ReferenceNo,tbRegPatient.Address,tbRegPatient.Alias,tbRegPatient.ParentName,tbRegPatient.RelatedId,tbRegPatient.MedicareNo,tbRegPatient.SocialSecurityNo, 
      tbRegOrder.InhospitalNo,tbRegOrder.ClinicNo,tbRegOrder.CurrentAge,tbRegOrder.CurPatientName,tbRegOrder.CurGender,tbRegOrder.ERequisition,tbRegOrder.StudyID,
      (case when tbRegOrder.OrderMessage IS NULL then '''' when cast(tbRegOrder.OrderMessage as nvarchar(max))='''' then '''' when tbRegOrder.OrderMessage.exist(''/LeaveMessage[@Type]'')=1 then tbRegOrder.OrderMessage.value(''/LeaveMessage[1]/@Type[1]'',''nvarchar(64)'') when tbRegOrder.OrderMessage.exist(''/LeaveMessage[@HasCriticalSigns]'')=0 or tbRegOrder.OrderMessage.exist(''/LeaveMessage[@HasCriticalSigns="0"]'')=1 then ''a'' when tbRegOrder.OrderMessage.exist(''//Message[@IsCriticalSign="0"]'')=1 then ''ab'' else ''b'' end) as OrderMessage,
                        tbRegOrder.OrderMessage as OrderMessageXml,
                        tbRegOrder.BedNo,tbRegOrder.AccNo,tbRegOrder.HisID,tbRegProcedure.ExamSystem,tbRegProcedure.Modality,tbRegProcedure.Charge,tbRegProcedure.Status as RPStatus,
                        (SELECT LocalName from tbUser where tbUser.UserGuid=tbRegProcedure.Registrar) as Registrar,
                        (SELECT LocalName from tbUser where tbUser.UserGuid=tbRegProcedure.Technician) as Technician,
                         tbRegProcedure.Technician as TechnicianGuid,  tbRegPatient.Gender,
                        (SELECT LocalName from tbUser where tbUser.UserGuid=tbRegProcedure.TechDoctor) as TechDoctor,
                        (SELECT LocalName from tbUser where tbUser.UserGuid=tbRegProcedure.TechNurse) as TechNurse,  
                        (SELECT Text from tbDictionaryValue where tbDictionaryValue.Value=tbRegProcedure.Status and tbDictionaryValue.Tag=13) as Status,
                        tbRegOrder.ApplyDept,tbRegOrder.ApplyDoctor,tbRegOrder.PatientType,tbRegOrder.ChargeType,tbRegOrder.InhospitalRegion,cast(tbRegOrder.BedSide as NVARCHAR(32)) as BedSide,
                        cast(tbRegOrder.IsScan as NVARCHAR(32)) as IsScan,tbRegProcedure.Createdt,tbRegProcedure.RegisterDt,tbRegProcedure.ExamineDt,tbRegProcedure.BookingBeginDt,tbRegProcedure.BookingEndDt,tbRegProcedure.BookingTimeAlias,tbRegProcedure.ProcedureGuid,
                        tbProcedureCode.Description,tbRegProcedure.ModalityType,
                        (SELECT LocalName from tbUser where tbUser.UserGuid=tbRegProcedure.UnwrittenCurrentOwner) as UnwrittenCurrentOwner,
                        (SELECT LocalName from tbUser where tbUser.UserGuid=tbRegProcedure.UnapprovedCurrentOwner) as UnapprovedCurrentOwner,
                        tbModality.Room,tbRegProcedure.QueueNo,tbRegPatient.PatientGuid,tbRegOrder.VisitGuid,tbRegOrder.OrderGuid,tbRegOrder.Optional1 as OrderOptional1,
                        (SELECT Text from tbDictionaryValue where tbDictionaryValue.Value=tbRegOrder.IsReferral and tbDictionaryValue.Tag=70) as IsReferral,tbRegOrder.InitialDomain,tbRegOrder.Comments,tbRegOrder.Assign2Site,tbRegOrder.CurrentSite,tbRegOrder.RegSite,tbRegOrder.ExamSite,
                        cast(tbRegOrder.IsFilmSent as NVARCHAR(32)) as IsFilmSent,FilmSentDt,(SELECT LocalName from tbUser where tbUser.UserGuid=tbRegOrder.FilmSentOperator) as FilmSentOperator,
     cast(tbRegOrder.ThreeDRebuild as NVARCHAR(32)) as ThreeDRebuild,tbRegProcedure.RegistrarName,tbRegProcedure.TechnicianName,
   ROW_NUMBER() Over(order by tbRegProcedure.RegisterDt desc) as rowNum  
                        FROM tbRegPatient,tbRegOrder,tbRegProcedure left join tbModality on tbRegProcedure.Modality=tbModality.Modality,tbProcedureCode  
                        where tbRegPatient.PatientGuid=tbRegOrder.PatientGuid and tbRegOrder.OrderGuid=tbRegProcedure.OrderGuid and  tbRegProcedure.ProcedureCode=tbProcedureCode.ProcedureCode  ' + @Where   + ') as reglisttable '
               + ' WHERE rowNum between '      + cast ( @LowNum   as   nvarchar )+ ' and ' + cast ( @HighNum   as   nvarchar )+ ' order by registerdt desc'                

end

else if @PageIndex = -2 --search all records
begin

SET   @strSQL = 'SELECT tbRegPatient.PatientID,tbRegPatient.LocalName,tbRegPatient.EnglishName,CONVERT(VARCHAR(10), birthday, 120) as birthday,tbRegPatient.Telephone,
      tbRegPatient.ReferenceNo,tbRegPatient.Address,tbRegPatient.Alias,tbRegPatient.ParentName,tbRegPatient.RelatedId,tbRegPatient.MedicareNo,tbRegPatient.SocialSecurityNo, 
      tbRegOrder.InhospitalNo,tbRegOrder.ClinicNo,tbRegOrder.CurrentAge,tbRegOrder.CurPatientName,tbRegOrder.CurGender,tbRegOrder.ERequisition,tbRegOrder.StudyID,
      (case when tbRegOrder.OrderMessage IS NULL then '''' when cast(tbRegOrder.OrderMessage as nvarchar(max))='''' then '''' when tbRegOrder.OrderMessage.exist(''/LeaveMessage[@Type]'')=1 then tbRegOrder.OrderMessage.value(''/LeaveMessage[1]/@Type[1]'',''nvarchar(64)'') when tbRegOrder.OrderMessage.exist(''/LeaveMessage[@HasCriticalSigns]'')=0 or tbRegOrder.OrderMessage.exist(''/LeaveMessage[@HasCriticalSigns="0"]'')=1 then ''a'' when tbRegOrder.OrderMessage.exist(''//Message[@IsCriticalSign="0"]'')=1 then ''ab'' else ''b'' end) as OrderMessage,
                        tbRegOrder.OrderMessage as OrderMessageXml,
                        tbRegOrder.BedNo,tbRegOrder.AccNo,tbRegOrder.HisID,tbRegProcedure.ExamSystem,tbRegProcedure.Modality,tbRegProcedure.Charge,tbRegProcedure.Status as RPStatus,
                        (SELECT LocalName from tbUser where tbUser.UserGuid=tbRegProcedure.Registrar) as Registrar,
                        (SELECT LocalName from tbUser where tbUser.UserGuid=tbRegProcedure.Technician) as Technician,
                         tbRegProcedure.Technician as TechnicianGuid,  tbRegPatient.Gender,
                        (SELECT LocalName from tbUser where tbUser.UserGuid=tbRegProcedure.TechDoctor) as TechDoctor,
                        (SELECT LocalName from tbUser where tbUser.UserGuid=tbRegProcedure.TechNurse) as TechNurse, 
                        (SELECT Text from tbDictionaryValue where tbDictionaryValue.Value=tbRegProcedure.Status and tbDictionaryValue.Tag=13) as Status,
                        tbRegOrder.ApplyDept,tbRegOrder.ApplyDoctor,tbRegOrder.PatientType,tbRegOrder.ChargeType,tbRegOrder.InhospitalRegion,cast(tbRegOrder.BedSide as NVARCHAR(32)) as BedSide,           
                        cast(tbRegOrder.IsScan as NVARCHAR(32)) as IsScan,tbRegProcedure.Createdt,tbRegProcedure.RegisterDt,tbRegProcedure.ExamineDt,tbRegProcedure.BookingBeginDt,tbRegProcedure.BookingEndDt,tbRegProcedure.BookingTimeAlias,tbRegProcedure.ProcedureGuid,
                        tbProcedureCode.Description,tbRegProcedure.ModalityType,
                        (SELECT LocalName from tbUser where tbUser.UserGuid=tbRegProcedure.UnwrittenCurrentOwner) as UnwrittenCurrentOwner,
                        (SELECT LocalName from tbUser where tbUser.UserGuid=tbRegProcedure.UnapprovedCurrentOwner) as UnapprovedCurrentOwner,
                        tbModality.Room,tbRegProcedure.QueueNo,tbRegPatient.PatientGuid,tbRegOrder.VisitGuid,tbRegOrder.OrderGuid,tbRegOrder.Optional1 as OrderOptional1,
                        (SELECT Text from tbDictionaryValue where tbDictionaryValue.Value=tbRegOrder.IsReferral and tbDictionaryValue.Tag=70) as IsReferral,tbRegOrder.InitialDomain,tbRegOrder.Comments,tbRegOrder.Assign2Site,tbRegOrder.CurrentSite,tbRegOrder.RegSite,tbRegOrder.ExamSite,
                        cast(tbRegOrder.IsFilmSent as NVARCHAR(32)) as IsFilmSent,FilmSentDt,(SELECT LocalName from tbUser where tbUser.UserGuid=tbRegOrder.FilmSentOperator) as FilmSentOperator,
     cast(tbRegOrder.ThreeDRebuild as NVARCHAR(32)) as ThreeDRebuild,tbRegProcedure.RegistrarName,tbRegProcedure.TechnicianName
                        FROM tbRegPatient,tbRegOrder,tbRegProcedure left join tbModality on tbRegProcedure.Modality=tbModality.Modality,tbProcedureCode  
                        where tbRegPatient.PatientGuid=tbRegOrder.PatientGuid and tbRegOrder.OrderGuid=tbRegProcedure.OrderGuid and  tbRegProcedure.ProcedureCode=tbProcedureCode.ProcedureCode  ' + @Where   + ' order by tbRegProcedure.RegisterDt desc '
end                        
SET   TRANSACTION   ISOLATION   LEVEL   READ   UNCOMMITTED          

EXEC ( @strSQL )

END 


GO
/****** Object:  StoredProcedure [dbo].[procReglistTotal]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   procedure   [dbo].[procReglistTotal]     
    @Where   varchar ( MAX ),   
    @TotalCount   integer   output ,    
    @TotalFee   float   output   
AS  
BEGIN
SET   NOCOUNT   ON ;
DECLARE   @strSQL   VARCHAR ( MAX )
CREATE   TABLE   #reglisttotaltemp  
(      
    TotalCount             int ,
    TotalCharge             decimal ( 12 , 2 )   NULL     
    
)
SET   TRANSACTION   ISOLATION   LEVEL   READ   UNCOMMITTED          

set   @strSQL = 'insert into #reglisttotaltemp SELECT COUNT(1) AS counttotal,SUM(tbRegProcedure.Charge) as chargetotal  FROM tbRegPatient,tbRegOrder,tbRegProcedure left join tbModality on tbRegProcedure.Modality=tbModality.Modality,tbProcedureCode  
                        where tbRegPatient.PatientGuid=tbRegOrder.PatientGuid and tbRegOrder.OrderGuid=tbRegProcedure.OrderGuid and  tbRegProcedure.ProcedureCode=tbProcedureCode.ProcedureCode' + @Where  
                        
EXEC ( @strSQL )
SELECT   @TotalCount = TotalCount , @TotalFee = TotalCharge   from   #reglisttotaltemp

END  


GO
/****** Object:  StoredProcedure [dbo].[procReindex]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
Create Procedure [dbo].[procReindex]
                 @isautoreindexall bit,
                 @tablename varchar(40)=Null,
                 @indexname varchar(40)=Null,
                 @fillfactor tinyint=Null
/**********
[版本号]4.0.0.0.0
[创建时间]2017.03.07   
[版权] Copyright ? 1998-2001好医生云医院管理技术有限公司
[描述]重建索引
[功能说明]
	重建索引
[参数说明]
	@isautoreindexall bit,  0=手动单表, 1=自动全部表
	@tablename varchar(40)=Null,
	@indexname varchar(40)=Null,
	@fillfactor tinyint=Null[返回值]
[结果集、排序]
[调用的usp]
Sample:   1.procReindex 0,'czryk'	             -- Reindex czryk  ALL Index 
          2.procReindex 0,'ZY_BQDMK','pk_zy_qbdmk'   -- Reindex ZY_BQDMK.pk_zy_qbdmk 
          3.procReindex 1                            -- Reindex All Table、 All Index
[调用实例]
**********/
As

Set Nocount on 
Declare  @cfillfactor varchar(3)

If  @isautoreindexall=1
Begin    --Begin ReIndex all Table All Index    
	DECLARE tempcur_table CURSOR FOR 
	SELECT name From sysobjects Where type='U'  Order by name
	
	OPEN tempcur_table
	
	FETCH NEXT FROM tempcur_table 
	INTO @tablename
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		Select @tablename=Rtrim(@tablename)
		If Exists(Select name From sysindexes Where id in (Select id From sysobjects Where name=@tablename) 
			AND indid>0 and indid <255 and  (status & 8388608)=0)
		begin
			Exec('DBCC DBREINDEX ('+@tablename+', "", 100)')
			If @@error<>0 
			begin
				FETCH NEXT FROM tempcur_table INTO @tablename
				CONTINUE
			end
			Exec sp_recompile @tablename
			
			Print @tablename +'  ReIndex Ok!'
		end
		
		FETCH NEXT FROM tempcur_table INTO @tablename
	End
	CLOSE tempcur_table
	DEALLOCATE tempcur_table
	
	Return
End      --End   ReIndex all Table All Index    

If Not Exists(Select * from sysobjects Where name=@tablename and type='U')
Begin
   Raiserror('No Table Found!',1,1)
   Return
End

Select @tablename=Rtrim(@tablename)

If @indexname is not null
Begin
	If Not Exists(select id From sysindexes Where id in (Select id From sysobjects 
		Where name=@tablename) and name =@indexname AND indid>0 and indid <255 And (status & 8388608)=0)
	Begin
		Raiserror('No Index Found!',1,1)
		Return
	End
End
Else
	Select @indexname=''

If @fillfactor is Not Null
Begin
	If Not (@fillfactor>=0 or @fillfactor<=100)
	Begin
		Raiserror('FillFactor Error!',1,1)
		Return
	End
End
Else
	Select @fillfactor=0

Select @cfillfactor=Convert(char(3),@fillfactor)

If @indexname<>''
	Select @indexname=Rtrim(@indexname)

If @indexname='' and @fillfactor=0
Begin
	Exec('DBCC DBREINDEX ('+@tablename+', "", 0)')
End
Else Begin
	If @indexname<>'' 
		Exec('DBCC DBREINDEX ('+@tablename+','+@indexname+','+@cfillfactor+')')             
End
If @@Error<>0 
Begin
	Raiserror('Reindex Error!',1,1)
	Return
End          

exec sp_recompile @tablename

Print @tablename +'   REIndex Ok!'

return



GO
/****** Object:  StoredProcedure [dbo].[procReindexMz]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
Create Procedure [dbo].[procReindexMz]
                 @isautoreindexall bit,
                 @tablename varchar(40)=Null,
                 @indexname varchar(40)=Null,
                 @fillfactor tinyint=Null
/**********
[创建时间]2017.03.07   
[版权] Copyright ? 1998-2001好医生云医院管理技术有限公司
[描述]重建索引
[功能说明]
	重建索引
[参数说明]
	@isautoreindexall bit,  0=手动单表, 1=自动全部表
	@tablename varchar(40)=Null,
	@indexname varchar(40)=Null,
	@fillfactor tinyint=Null[返回值]
[结果集、排序]
[调用的usp]
Sample:   1.procReindex 0,'czryk'	             -- Reindex czryk  ALL Index 
          2.procReindex 0,'ZY_BQDMK','pk_zy_qbdmk'   -- Reindex ZY_BQDMK.pk_zy_qbdmk 
          3.procReindex 1                            -- Reindex All Table、 All Index
[调用实例]
**********/
As

Set Nocount on 
Declare  @cfillfactor varchar(3)

If  @isautoreindexall=1
Begin    --Begin ReIndex all Table All Index    
	DECLARE tempcur_table CURSOR FOR 
	SELECT name From sysobjects Where type='U' and (name like 'SF%' or name like 'GH%')  Order by name
	
	OPEN tempcur_table
	
	FETCH NEXT FROM tempcur_table 
	INTO @tablename
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		Select @tablename=Rtrim(@tablename)
		If Exists(Select name From sysindexes Where id in (Select id From sysobjects Where name=@tablename) 
			AND indid>0 and indid <255 and  (status & 8388608)=0)
		begin
			Exec('DBCC DBREINDEX ('+@tablename+', "", 100)')
			If @@error<>0 
			begin
				FETCH NEXT FROM tempcur_table INTO @tablename
				CONTINUE
			end
			Exec sp_recompile @tablename
			
			Print @tablename +'  ReIndex Ok!'
		end
		
		FETCH NEXT FROM tempcur_table INTO @tablename
	End
	CLOSE tempcur_table
	DEALLOCATE tempcur_table
	
	Return
End      --End   ReIndex all Table All Index    

If Not Exists(Select * from sysobjects Where name=@tablename and type='U')
Begin
   Raiserror('No Table Found!',1,1)
   Return
End

Select @tablename=Rtrim(@tablename)

If @indexname is not null
Begin
	If Not Exists(select id From sysindexes Where id in (Select id From sysobjects 
		Where name=@tablename) and name =@indexname AND indid>0 and indid <255 And (status & 8388608)=0)
	Begin
		Raiserror('No Index Found!',1,1)
		Return
	End
End
Else
	Select @indexname=''

If @fillfactor is Not Null
Begin
	If Not (@fillfactor>=0 or @fillfactor<=100)
	Begin
		Raiserror('FillFactor Error!',1,1)
		Return
	End
End
Else
	Select @fillfactor=0

Select @cfillfactor=Convert(char(3),@fillfactor)

If @indexname<>''
	Select @indexname=Rtrim(@indexname)

If @indexname='' and @fillfactor=0
Begin
	Exec('DBCC DBREINDEX ('+@tablename+', "", 0)')
End
Else Begin
	If @indexname<>'' 
		Exec('DBCC DBREINDEX ('+@tablename+','+@indexname+','+@cfillfactor+')')             
End
If @@Error<>0 
Begin
	Raiserror('Reindex Error!',1,1)
	Return
End          

exec sp_recompile @tablename

Print @tablename +'   REIndex Ok!'

return



GO
/****** Object:  StoredProcedure [dbo].[procReindexOther]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
Create Procedure [dbo].[procReindexOther]
                 @isautoreindexall bit,
                 @tablename varchar(40)=Null,
                 @indexname varchar(40)=Null,
                 @fillfactor tinyint=Null
/**********
[版本号]4.0.0.0.0
[创建时间]2017.03.07   
[版权] Copyright ? 1998-2001好医生云医院管理技术有限公司
[描述]重建索引
[功能说明]
	重建索引
[参数说明]
	@isautoreindexall bit,  0=手动单表, 1=自动全部表
	@tablename varchar(40)=Null,
	@indexname varchar(40)=Null,
	@fillfactor tinyint=Null[返回值]
[结果集、排序]
[调用的usp]
Sample:   1.procReindex 0,'czryk'	             -- Reindex czryk  ALL Index 
          2.procReindex 0,'ZY_BQDMK','pk_zy_qbdmk'   -- Reindex ZY_BQDMK.pk_zy_qbdmk 
          3.procReindex 1                            -- Reindex All Table、 All Index
[调用实例]
**********/
As

Set Nocount on 
Declare  @cfillfactor varchar(3)

If  @isautoreindexall=1
Begin    --Begin ReIndex all Table All Index    
	DECLARE tempcur_table CURSOR FOR 
	SELECT name From sysobjects Where type='U' and not (name like 'SF%' or name like 'GH%' or name like 'ZY%' or name like 'BQ%')  Order by name
	
	OPEN tempcur_table
	
	FETCH NEXT FROM tempcur_table 
	INTO @tablename
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		Select @tablename=Rtrim(@tablename)
		If Exists(Select name From sysindexes Where id in (Select id From sysobjects Where name=@tablename) 
			AND indid>0 and indid <255 and  (status & 8388608)=0)
		begin
			Exec('DBCC DBREINDEX ('+@tablename+', "", 100)')
			If @@error<>0 
			begin
				FETCH NEXT FROM tempcur_table INTO @tablename
				CONTINUE
			end
			Exec sp_recompile @tablename
			
			Print @tablename +'  ReIndex Ok!'
		end
		
		FETCH NEXT FROM tempcur_table INTO @tablename
	End
	CLOSE tempcur_table
	DEALLOCATE tempcur_table
	
	Return
End      --End   ReIndex all Table All Index    

If Not Exists(Select * from sysobjects Where name=@tablename and type='U')
Begin
   Raiserror('No Table Found!',1,1)
   Return
End

Select @tablename=Rtrim(@tablename)

If @indexname is not null
Begin
	If Not Exists(select id From sysindexes Where id in (Select id From sysobjects 
		Where name=@tablename) and name =@indexname AND indid>0 and indid <255 And (status & 8388608)=0)
	Begin
		Raiserror('No Index Found!',1,1)
		Return
	End
End
Else
	Select @indexname=''

If @fillfactor is Not Null
Begin
	If Not (@fillfactor>=0 or @fillfactor<=100)
	Begin
		Raiserror('FillFactor Error!',1,1)
		Return
	End
End
Else
	Select @fillfactor=0

Select @cfillfactor=Convert(char(3),@fillfactor)

If @indexname<>''
	Select @indexname=Rtrim(@indexname)

If @indexname='' and @fillfactor=0
Begin
	Exec('DBCC DBREINDEX ('+@tablename+', "", 0)')
End
Else Begin
	If @indexname<>'' 
		Exec('DBCC DBREINDEX ('+@tablename+','+@indexname+','+@cfillfactor+')')             
End
If @@Error<>0 
Begin
	Raiserror('Reindex Error!',1,1)
	Return
End          

exec sp_recompile @tablename

Print @tablename +'   REIndex Ok!'

return



GO
/****** Object:  StoredProcedure [dbo].[procReindexTj]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
Create Procedure [dbo].[procReindexTj]
                 @isautoreindexall bit,
                 @tablename varchar(40)=Null,
                 @indexname varchar(40)=Null,
                 @fillfactor tinyint=Null
/**********
[版本号]4.0.0.0.0
[创建时间]2017.03.07   
[版权] Copyright ? 1998-2001好医生云医院管理技术有限公司
[描述]重建索引
[功能说明]
	重建索引
[参数说明]
	@isautoreindexall bit,  0=手动单表, 1=自动全部表
	@tablename varchar(40)=Null,
	@indexname varchar(40)=Null,
	@fillfactor tinyint=Null[返回值]
[结果集、排序]
[调用的usp]
Sample:   1.procReindex 0,'czryk'	             -- Reindex czryk  ALL Index 
          2.procReindex 0,'ZY_BQDMK','pk_zy_qbdmk'   -- Reindex ZY_BQDMK.pk_zy_qbdmk 
          3.procReindex 1                            -- Reindex All Table、 All Index
[调用实例]
**********/
as

Set Nocount on 
Declare  @cfillfactor varchar(3)

If  @isautoreindexall=1
Begin    --Begin ReIndex all Table All Index    
	DECLARE tempcur_table CURSOR FOR 
	SELECT name From sysobjects Where type='U' and (name like 'TJ%' )  Order by name
	
	OPEN tempcur_table
	
	FETCH NEXT FROM tempcur_table 
	INTO @tablename
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		Select @tablename=Rtrim(@tablename)
		If Exists(Select name From sysindexes Where id in (Select id From sysobjects Where name=@tablename) 
			AND indid>0 and indid <255 and  (status & 8388608)=0)
		begin
			Exec('DBCC DBREINDEX ('+@tablename+', "", 100)')
			If @@error<>0 
			begin
				FETCH NEXT FROM tempcur_table INTO @tablename
				CONTINUE
			end
			Exec sp_recompile @tablename
			
			Print @tablename +'  ReIndex Ok!'
		end
		
		FETCH NEXT FROM tempcur_table INTO @tablename
	End
	CLOSE tempcur_table
	DEALLOCATE tempcur_table
	
	Return
End      --End   ReIndex all Table All Index    

If Not Exists(Select * from sysobjects Where name=@tablename and type='U')
Begin
   Raiserror('No Table Found!',1,1)
   Return
End

Select @tablename=Rtrim(@tablename)

If @indexname is not null
Begin
	If Not Exists(select id From sysindexes Where id in (Select id From sysobjects 
		Where name=@tablename) and name =@indexname AND indid>0 and indid <255 And (status & 8388608)=0)
	Begin
		Raiserror('No Index Found!',1,1)
		Return
	End
End
Else
	Select @indexname=''

If @fillfactor is Not Null
Begin
	If Not (@fillfactor>=0 or @fillfactor<=100)
	Begin
		Raiserror('FillFactor Error!',1,1)
		Return
	End
End
Else
	Select @fillfactor=0

Select @cfillfactor=Convert(char(3),@fillfactor)

If @indexname<>''
	Select @indexname=Rtrim(@indexname)

If @indexname='' and @fillfactor=0
Begin
	Exec('DBCC DBREINDEX ('+@tablename+', "", 0)')
End
Else Begin
	If @indexname<>'' 
		Exec('DBCC DBREINDEX ('+@tablename+','+@indexname+','+@cfillfactor+')')             
End
If @@Error<>0 
Begin
	Raiserror('Reindex Error!',1,1)
	Return
End          

exec sp_recompile @tablename

Print @tablename +'   REIndex Ok!'

return



GO
/****** Object:  StoredProcedure [dbo].[procReindexZy]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
Create Procedure [dbo].[procReindexZy]
                 @isautoreindexall bit,
                 @tablename varchar(40)=Null,
                 @indexname varchar(40)=Null,
                 @fillfactor tinyint=Null
/**********
[版本号]4.0.0.0.0
[创建时间]2017.03.07   
[版权] Copyright ? 1998-2001好医生云医院管理技术有限公司
[描述]重建索引
[功能说明]
	重建索引
[参数说明]
	@isautoreindexall bit,  0=手动单表, 1=自动全部表
	@tablename varchar(40)=Null,
	@indexname varchar(40)=Null,
	@fillfactor tinyint=Null[返回值]
[结果集、排序]
[调用的usp]
Sample:   1.procReindex 0,'czryk'	             -- Reindex czryk  ALL Index 
          2.procReindex 0,'ZY_BQDMK','pk_zy_qbdmk'   -- Reindex ZY_BQDMK.pk_zy_qbdmk 
          3.procReindex 1                            -- Reindex All Table、 All Index
[调用实例]
**********/
As

Set Nocount on 
Declare  @cfillfactor varchar(3)

If  @isautoreindexall=1
Begin    --Begin ReIndex all Table All Index    
	DECLARE tempcur_table CURSOR FOR 
	SELECT name From sysobjects Where type='U' and (name like 'ZY%' or name like 'BQ%')  Order by name
	
	OPEN tempcur_table
	
	FETCH NEXT FROM tempcur_table 
	INTO @tablename
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		Select @tablename=Rtrim(@tablename)
		If Exists(Select name From sysindexes Where id in (Select id From sysobjects Where name=@tablename) 
			AND indid>0 and indid <255 and  (status & 8388608)=0)
		begin
			Exec('DBCC DBREINDEX ('+@tablename+', "", 100)')
			If @@error<>0 
			begin
				FETCH NEXT FROM tempcur_table INTO @tablename
				CONTINUE
			end
			Exec sp_recompile @tablename
			
			Print @tablename +'  ReIndex Ok!'
		end
		
		FETCH NEXT FROM tempcur_table INTO @tablename
	End
	CLOSE tempcur_table
	DEALLOCATE tempcur_table
	
	Return
End      --End   ReIndex all Table All Index    

If Not Exists(Select * from sysobjects Where name=@tablename and type='U')
Begin
   Raiserror('No Table Found!',1,1)
   Return
End

Select @tablename=Rtrim(@tablename)

If @indexname is not null
Begin
	If Not Exists(select id From sysindexes Where id in (Select id From sysobjects 
		Where name=@tablename) and name =@indexname AND indid>0 and indid <255 And (status & 8388608)=0)
	Begin
		Raiserror('No Index Found!',1,1)
		Return
	End
End
Else
	Select @indexname=''

If @fillfactor is Not Null
Begin
	If Not (@fillfactor>=0 or @fillfactor<=100)
	Begin
		Raiserror('FillFactor Error!',1,1)
		Return
	End
End
Else
	Select @fillfactor=0

Select @cfillfactor=Convert(char(3),@fillfactor)

If @indexname<>''
	Select @indexname=Rtrim(@indexname)

If @indexname='' and @fillfactor=0
Begin
	Exec('DBCC DBREINDEX ('+@tablename+', "", 0)')
End
Else Begin
	If @indexname<>'' 
		Exec('DBCC DBREINDEX ('+@tablename+','+@indexname+','+@cfillfactor+')')             
End
If @@Error<>0 
Begin
	Raiserror('Reindex Error!',1,1)
	Return
End          

exec sp_recompile @tablename

Print @tablename +'   REIndex Ok!'

return



GO
/****** Object:  StoredProcedure [dbo].[procRemoveOrderMessageFlag]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procRemoveOrderMessageFlag]
(
    @AccNo varchar(256), 
    @Type varchar(2),
	@ErrorMessage varchar(256) output
)
AS
BEGIN	
	SET NOCOUNT ON
	DECLARE @LeaveMessageType nvarchar(32)
	DECLARE @NewLeaveMessageType nvarchar(32)
	declare @UpdateSql varchar(max);	
	declare @XML xml;
	
	BEGIN TRY
		set @ErrorMessage = '';
		
		select @XML=OrderMessage FROM  dbo.tbRegOrder where AccNo = @AccNo;
		--------------------------------compatible with old records start----------------------------------
		
		if(@XML is null or @XML.exist('/LeaveMessage/Message[@Type=sql:variable("@Type")]') = 0) 
			return
		
		select @LeaveMessageType=@XML.value('(/LeaveMessage[@Type=@Type]/@Type)[1]','nvarchar(32)')		
		select @NewLeaveMessageType=replace(@LeaveMessageType,@Type,'')
		select @NewLeaveMessageType
		 
		SET @XML.modify('replace value of (/LeaveMessage/@Type)[1] with sql:variable("@NewLeaveMessageType")');

		
		SET @XML.modify('delete /LeaveMessage/Message[@Type=sql:variable("@Type")]');
		set @XML = REPLACE(convert(varchar(max),@XML),'''','''''');
		set @UpdateSql = 'update tbRegOrder set OrderMessage = ''' + convert(varchar(max),@XML) + ''' where AccNo = '''  + @AccNo + '''' ;
		if (@XML is not null)		
			execute(@UpdateSql)  		
		
    END TRY    
    BEGIN CATCH
		 set @ErrorMessage = ERROR_MESSAGE();		
    END CATCH
END


GO
/****** Object:  StoredProcedure [dbo].[procReportFirstPrintStat]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procReportFirstPrintStat] 
	  @ConditionStr nvarchar(4000)
AS
BEGIN
DECLARE @szSQL  nvarchar(max)
set @szSQL ='
select printer,modalitytype,count(printer) as printcount into #tempFstPrintStat from (select tbReportPrintLog.Printer,tbRegProcedure.ModalityType,tbRegProcedure.ReportGuid,min(tbReportPrintLog.PrintDt)as fisrtPrintdt from tbReportPrintLog,tbRegProcedure where 1=1 '+@ConditionStr+
'and tbReportPrintLog.reportguid = tbRegProcedure.reportguid group by tbReportPrintLog.Printer,tbRegProcedure.ModalityType,tbRegProcedure.reportguid)as B group by printer,modalitytype order by printer desc,printcount desc,modalitytype desc
update #tempFstPrintStat set printer =(select localname from tbUser where userguid = printer)
select * from #tempFstPrintStat
drop table #tempFstPrintStat
'
EXEC(@szSQL)
END


GO
/****** Object:  StoredProcedure [dbo].[procReportPage]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--US28272
CREATE PROCEDURE [dbo].[procReportPage]
    @PageIndex integer,
     @PageSize integer,
     @Columns nvarchar(MAX),
     @Where nvarchar(MAX),
     @WhereArchive nvarchar(MAX),
     @plainColumns nvarchar(MAX) = '',
     @OrderBy nvarchar(max),
    @TotalCount integer output
AS 
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET @TotalCount=0
if @PageSize < 1 
	set @PageSize = 30
if @PageIndex > 500 
	set @PageIndex = 500
	
	
declare @minrowcount int
declare @maxrowcount int
set @minrowcount=(@PageIndex)*@PageSize+1
set @maxrowcount = (@PageIndex+1) * @PageSize

DECLARE @Sql NVARCHAR(MAX);
	
if @PageIndex >= 0
begin
 declare @topcount int
 set @topcount = (@PageIndex+1) * @PageSize
 
 /*
 if(len(@WhereArchive) > 0)
 begin
  declare @sqlunion varchar(max)
  declare @OrderBy1 varchar(max);
  select @OrderBy1 = replace(@OrderBy, '__', '.') 
  select @OrderBy = replace(@OrderBy, '.', '__')
  
  if CHARINDEX('orderMessage',@OrderBy)>0
  begin
  select @sqlunion = 'select * from( '
  select @sqlunion = @sqlunion+'select top '+ str(@topcount) +' ROW_NUMBER() Over('+@OrderBy+') as rowNum, '+@plainColumns+' from ('
  select @sqlunion = @sqlunion + 'select '+@Columns+' '+@Where
  select @sqlunion = @sqlunion + ' union '
  select @sqlunion = @sqlunion + 'select '+@Columns+' '+@WhereArchive
  select @sqlunion = @sqlunion + ') tmp8964 ' + @OrderBy
  select @sqlunion = @sqlunion + ' where tmp8964.rowNum between '+cast(@minrowcount as varchar(18)) +' and '+cast(@maxrowcount as varchar(18))
  end
  
  else
  begin
  select @sqlunion = 'select * from( '
  select @sqlunion = @sqlunion+'select top '+ str(@topcount) +' ROW_NUMBER() Over('+@OrderBy+') as rowNum, '+@plainColumns+' from ('
  select @sqlunion = @sqlunion + 'select top '+ str(@topcount) +' '+@Columns+' '+@Where
  select @sqlunion = @sqlunion + ' ' + @OrderBy1
  select @sqlunion = @sqlunion + ' union ' 
  select @sqlunion = @sqlunion + 'select top '+ str(@topcount) +' '+@Columns+' '+@WhereArchive
  select @sqlunion = @sqlunion + ' ' + @OrderBy1
  select @sqlunion = @sqlunion + ') tmp8964  order by rowNum asc) temptable'
  select @sqlunion = @sqlunion + ' where temptable.rowNum between '+cast(@minrowcount as varchar(18)) +' and '+cast(@maxrowcount as varchar(18))
  end
  
  EXEC(@sqlunion)
 end
 else
 begin
  declare @sql1 nvarchar(MAX)
  
  if CHARINDEX('orderMessage',@OrderBy)>0
  begin
  select @OrderBy = replace(@OrderBy, '.', '__')
  select @sql1 = 'select * from (select top '+ str(@topcount) +' ROW_NUMBER() Over('+@OrderBy+') as rowNum, '+@plainColumns+' from ('
  select @sql1 = @sql1 + 'select '+@Columns+' '+@Where
  select @sql1 = @sql1 + ') tmp8964 order by rowNum asc) temptable where temptable.rowNum between '
  select  @sql1 = @sql1 + cast(@minrowcount as varchar(18)) +' and '+cast(@maxrowcount as varchar(18))  
  end
  
  else
  begin
  select @OrderBy = replace(@OrderBy, '__', '.')
  set @sql1='select * from( select top '+ str(@topcount) +' ROW_NUMBER() Over('+@OrderBy+') as rowNum, '+@Columns+' '+@Where			
	+'  order by rowNum asc) temptable where temptable.rowNum between '+cast(@minrowcount as varchar(18)) +' and '+cast(@maxrowcount as varchar(18))
  end
  --insert into tbErrorTable(errormessage) values(@sql1)
  EXEC(@sql1)
 end
 */
 
 DECLARE @Top NVARCHAR(18) = CONVERT(NVARCHAR(18), @topcount)
 SET @OrderBy = REPLACE(@OrderBy, '__', '.')
 DECLARE @OrderBy2 NVARCHAR(MAX) = REPLACE(@OrderBy, '.', '__')
 IF len(@WhereArchive) > 0
 BEGIN
    SET @Sql = '
    ;With UnionAll AS (
        SELECT TOP ' + @Top + '
            ' + @Columns + '
            ' + @Where + '
            ' + @OrderBy + '
        UNION ALL
        SELECT TOP ' + @Top + '
            ' + @Columns + '
            ' + @WhereArchive + '
            ' + @OrderBy + ' 
    ), Page AS (
        SELECT TOP ' + @Top + '
            ROW_NUMBER() OVER (' + @OrderBy2 + ') AS RowNum, *
            FROM UnionAll WITH (NOLOCK)
            ' + @OrderBy2 + '
    )'
 END
 ELSE
 BEGIN
    SET @Sql = '
    ;WITH Page AS (
        SELECT TOP ' + @Top + '
            ROW_NUMBER() OVER (' + @OrderBy + ') AS RowNum,
            ' + @Columns + '
            ' + @Where + '
            ' + @OrderBy + '
    )'
 END
 SET @Sql += '
    SELECT * FROM Page WITH (NOLOCK) WHERE Page.RowNum BETWEEN '+CAST(@minrowcount AS VARCHAR(18)) +' AND '+CAST(@maxrowcount AS VARCHAR(18))
 
 EXEC sys.sp_executesql @Sql
 
end
else
begin
     --declare @sql nvarchar(4000)
     select @sql = 'select @TotalCount=count(1) '+@Where
     EXEC sp_executesql @sql, N' @TotalCount int output ', @TotalCount output
end
END


GO
/****** Object:  StoredProcedure [dbo].[procReportPageCount]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procReportPageCount]
     @condition nvarchar(MAX),
     @offlineCondition nvarchar(MAX),
     @TotalCount integer output
AS 
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET @TotalCount=0
declare @upperCondition nvarchar(MAX)
--declare @upperWhereArchive nvarchar(4000)

set @upperCondition = ltrim(rtrim(upper(@condition)))
if len(@upperCondition) > 0 AND charindex('AND', @upperCondition) <> 1
     set @condition = ' and ' + @condition

--set @upperWhereArchive = ltrim(rtrim(upper(@offlineCondition)))
--if len(@upperWhereArchive) > 0 AND charindex('AND', @upperWhereArchive) <> 1
--     set @upperWhereArchive = ' AND ' + @upperWhereArchive

declare @sql nvarchar(max)
if(len(@offlineCondition) > 0)
begin
 if charindex('tbRegPatient.', @condition) < 1 and charindex('tbRegOrder.', @condition) < 1 and charindex('tbReport.', @condition) < 1
 begin
  select @sql = ' select @TotalCount=sum(cnt) '
  select @sql = @sql + ' from ( '
  select @sql = @sql + ' select COUNT(1) cnt, 1 dummy from tbRegProcedure with (nolock) where tbRegProcedure.status >= 50 '+@condition
  select @sql = @sql + ' union '
  select @sql = @sql + ' select COUNT(1) cnt, 2 dummy from RISArchive..tbRegProcedure tbRegProcedure with (nolock) where tbRegProcedure.status >= 50 '+@condition
  select @sql = @sql + ' ) tmp8965 '
  print '1' + @sql
  EXEC sp_executesql @sql, N' @TotalCount int output ', @TotalCount output
 end
 else
 begin
  select @sql = ' select @TotalCount=sum(cnt) '
  select @sql = @sql + ' from ( '
  select @sql = @sql + ' select COUNT(1) cnt, 1 dummy from tbRegPatient with (nolock), tbRegOrder with (nolock), tbRegProcedure with (nolock)
     left join tbReport with (nolock) on tbRegProcedure.reportGuid = tbReport.reportGuid 
     where tbRegPatient.PatientGuid = tbRegOrder.PatientGuid and tbRegOrder.OrderGuid = tbRegProcedure.OrderGuid
     and tbRegProcedure.status >= 50 ' + @condition
  select @sql = @sql + ' union '
  select @sql = @sql + ' select COUNT(1) cnt, 2 dummy from RISArchive..tbRegPatient tbRegPatient with (nolock), RISArchive..tbRegOrder tbRegOrder with (nolock), RISArchive..tbRegProcedure tbRegProcedure with (nolock)
     left join RISArchive..tbReport tbReport with (nolock) on tbRegProcedure.reportGuid = tbReport.reportGuid 
     where tbRegPatient.PatientGuid = tbRegOrder.PatientGuid and tbRegOrder.OrderGuid = tbRegProcedure.OrderGuid
     and tbRegProcedure.status >= 50 ' + @condition
  select @sql = @sql + ' ) tmp8965 '
  print '2' + @sql
  EXEC sp_executesql @sql, N' @TotalCount int output ', @TotalCount output
 end
end
else
begin
 if charindex('tbRegPatient.', @condition) < 1 and charindex('tbRegOrder.', @condition) < 1 and charindex('tbReport.', @condition) < 1
 begin
   select @sql = 'select @TotalCount=count(1) from tbRegProcedure with (nolock) where tbRegProcedure.status >= 50 '+@condition
  print '3' + @sql
   EXEC sp_executesql @sql, N' @TotalCount int output ', @TotalCount output
 end
 else
 begin
   select @sql = 'select @TotalCount=count(1) from tbRegPatient with (nolock), tbRegOrder with (nolock), tbRegProcedure with (nolock)
     left join tbReport with (nolock) on tbRegProcedure.reportGuid = tbReport.reportGuid
     where tbRegPatient.PatientGuid = tbRegOrder.PatientGuid and tbRegOrder.OrderGuid = tbRegProcedure.OrderGuid
     and tbRegProcedure.status >= 50 ' + @condition
  print '4' + @sql
   EXEC sp_executesql @sql, N' @TotalCount int output ', @TotalCount output
 end
end
END


GO
/****** Object:  StoredProcedure [dbo].[procReportQualityStatistic]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procReportQualityStatistic]
		@strSQL varchar(8000)
AS

	BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
      EXEC(@strSQL )
END


GO
/****** Object:  StoredProcedure [dbo].[procReportTransReportData]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[procReportTransReportData]
	@bgdays int
as
/**********
[版本号]4.0.0.0.0
[创建时间]2017.03.07   
[版权] Copyright ? 1998-2001好医生云医院管理技术有限公司
[描述]数据迁移
[功能说明]
	报告数据从日表迁移到年表
[参数说明]
[返回值]
[结果集、排序]
[调用的sp]
[调用实例]

exec procReportTransReportData 30
[修改历史]

**********/
set nocount on
 
declare @bgdate varchar(8),

	@errmsg varchar(50),
	@now varchar(8),
	@dbname varchar(64)
/*
select @dbname=config from YJ_CONFIG (nolock) where id='0001'

select @bgdays=convert(int,config) from YJ_CONFIG (nolock) where id='0002'
if @@rowcount=0
begin
	select "F","报告日库数据保存天数设置不正确！"
	raiserror("报告日库数据保存天数设置不正确！",16,1)
	return
end
*/
select @bgdate=convert(char(8),dateadd(dd,-@bgdays,getdate()),112),
	@now=convert(char(8),getdate(),112)

create table #tjryxhtmp
(
	xh hys_xh12 not null
)
insert into #tjryxhtmp
exec('select xh from TJ_TJRYK (nolock) where jlzt=4 and ffbz=1 and ffsj<="'+@bgdate+'"')
if @@error<>0
begin
	select "F","得到已发放报告体检人员列表出错！"
	raiserror("得到已发放报告体检人员列表出错！",16,1)
	return
end

begin tran
--ris\lis主报告数据

insert into THIS4_REPORT..YJ_NREPORT
select * from THIS4_REPORT..YJ_REPORT where bsxh in (select xh from #tjryxhtmp) 
if @@error<>0
begin
	select @errmsg="迁移YJ_REPORT出错！"
	goto errlog
end

delete THIS4_REPORT..YJ_REPORT from THIS4_REPORT..YJ_REPORT a (nolock),#tjryxhtmp b where b.xh=a.bsxh
if @@error<>0
begin
	select @errmsg="迁移YJ_REPORT出错！"
	goto errlog
end

--ris明细报告数据
insert into THIS4_REPORT..YJ_RIS_NRESULT
select * from THIS4_REPORT..YJ_RIS_RESULT a (nolock) where not exists(select 1 from YJ_REPORT b where b.xh=a.repxh)
if @@error<>0
begin
	select @errmsg="迁移YJ_RIS_RESULT出错！"
	goto errlog
end

delete THIS4_REPORT..YJ_RIS_RESULT from THIS4_REPORT..YJ_RIS_RESULT a (nolock) where not exists(select 1 from YJ_REPORT b where b.xh=a.repxh)
if @@error<>0
begin
	select @errmsg="迁移YJ_RIS_RESULT出错！"
	goto errlog
end

--lis明细报告数据
insert into THIS4_REPORT..YJ_LIS_NRESULT
select * from THIS4_REPORT..YJ_LIS_RESULT a (nolock) where not exists(select 1 from THIS4_REPORT..YJ_REPORT b where b.xh=a.repxh)
if @@error<>0
begin
	select @errmsg="迁移YJ_LIS_RESULT出错！"
	goto errlog
end

delete THIS4_REPORT..YJ_RIS_RESULT from THIS4_REPORT..YJ_LIS_RESULT a (nolock) where not exists(select 1 from YJ_REPORT b where b.xh=a.repxh)
if @@error<>0
begin
	select @errmsg="迁移YJ_LIS_RESULT出错！"
	goto errlog
end

commit tran
select "T"
return

errlog:
	rollback tran
	select "F",@errmsg
	raiserror(@errmsg,16,1)
	return



GO
/****** Object:  StoredProcedure [dbo].[procSavePatient]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[procSavePatient]
	-- Add the parameters for the stored procedure here                --
	@PatientID VARCHAR(32),
	@PatientName  VARCHAR(32),
	@EnglishName  VARCHAR(32),         
	@Gender VARCHAR(8),               
	@Birthday DATETIME,
	@Address VARCHAR(128),            --optional
	@Telephone  VARCHAR(32),          --optional
	@IsVIP int,
	@HisID varchar(32),
	@CreateDt DateTime,                          
	@SzError VARCHAR(128) output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	set @szError = ''
	IF exists (select 1 from tbRegPatient where PatientID = @PatientID and LocalName = @PatientName)
	begin
		update tbRegPatient set LocalName = @PatientName,EnglishName = @EnglishName,Gender =@Gender,
		Birthday = @Birthday,ADDRESS = @Address,TELEPHONE = @Telephone,
		ISVIP = @IsVIP where PATIENTID = @PatientID
		
		INSERT INTO tbActivityLog (ALGUID ,EVENTID ,EVENTACTIONCODE ,EVENTDT ,EVENTOUTCOMEINDICATOR ,EVENTTYPECODE ,
			USERGUID ,USERNAME ,USERISREQUESTOR ,ROLENAME ,PARTOBJECTTYPECODE ,PARTOBJECTTYPECODEROLE ,
			PARTOBJECTIDTYPECODE ,PARTOBJECTID ,PARTOBJECTNAME ,PARTOBJECTDETAIL ,COMMENTS ) 
			VALUES (newid(),'Patient Record','U',getdate(),'',
			'Update Patient','','CVIS','TRUE','Registrar','Person',
			'Patient','Patient ID',@PATIENTID,@PatientName,'UserName:'+'CVIS'+'IP: ,Patient:'+@PatientName+',Action:Create Patient','')
	end
	else 
	begin
		begin
			INSERT INTO tbRegPatient(PATIENTGUID,PATIENTID, LOCALNAME,EnglishName,BIRTHDAY, GENDER, ADDRESS, TELEPHONE, ISVIP,CreateDt) 
								VALUES(newid(),@PatientID,@PatientName,@EnglishName,@Birthday,@Gender,@Address,@Telephone,@IsVIP,@CreateDt)

			INSERT INTO tbActivityLog (ALGUID ,EVENTID ,EVENTACTIONCODE ,EVENTDT ,EVENTOUTCOMEINDICATOR ,EVENTTYPECODE ,
					USERGUID ,USERNAME ,USERISREQUESTOR ,ROLENAME ,PARTOBJECTTYPECODE ,PARTOBJECTTYPECODEROLE ,
					PARTOBJECTIDTYPECODE ,PARTOBJECTID ,PARTOBJECTNAME ,PARTOBJECTDETAIL ,COMMENTS ) 
					VALUES (newid(),'Patient Record','C',getdate(),'',
					'Update Patient','','CVIS','TRUE','Registrar','Person',
					'Patient','Patient ID',@PatientID,@PatientName,'UserName:'+'CVIS'+'IP: ,Patient:'+@PatientName+',Action:Update Patient','')
		end
		
	end	
END


GO
/****** Object:  StoredProcedure [dbo].[procScriptRunTrack]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[procScriptRunTrack]
	-- Add the parameters for the stored procedure here
	@sessionid                          nvarchar(128),
	@operationtype                    int, --1 begin,  2--end
	@filename                         nvarchar(128)='',	
	@clientname                        nvarchar(128)='',
	@loginname                        nvarchar(128)=''
	
AS
BEGIN

	if(@operationtype=1)
	begin
		insert into tbScriptRunTrack(sessionid,filename,begintime,clientname,loginname) values(@sessionid,@filename,GETDATE(),@clientname,@loginname)
	end
	else
	begin
		update tbScriptRunTrack set endtime=GETDATE(),runningtime=Convert(nvarchar, datediff(ms,begintime,GETDATE()))+' ms' where sessionid=@sessionid
	end		
	
END


GO
/****** Object:  StoredProcedure [dbo].[procSearchAcrCode]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
----------------------------------------------------
create  PROCEDURE [dbo].[procSearchAcrCode]  
 @AnatomicalDesc varchar(255),  
 @PathologicalDesc varchar(255),  
 @aid varchar,  
 @asid varchar(10),  
 @pid varchar,  
 @psid varchar(10)  
 AS  
BEGIN  
  
set nocount on  
  
declare @sSQL1 varchar(2000)  
declare @sSQL2 varchar(2000)  
declare @sql varchar(4000)  
  
set  @AnatomicalDesc = ltrim(rtrim(@AnatomicalDesc))  
set  @PathologicalDesc = ltrim(rtrim(@PathologicalDesc))  
set  @asid = ltrim(rtrim(@asid))  
set  @psid = ltrim(rtrim(@psid))  
  
if @aid is null   
	set @aid = ''  
if @pid is null  
	set @pid = ''  
if @asid is null   
	set @asid = ''  
if @psid is null  
	set @psid = ''  
if @AnatomicalDesc is null   
	set @AnatomicalDesc = ''  
if @PathologicalDesc is null  
	set @PathologicalDesc = ''  
  
set @sql = ''  
  
if( @aid = '' and @asid = '' and @pid = '' and @psid = '' and @AnatomicalDesc = '' and @PathologicalDesc = '' )  
begin ----on no condition  
	set @sql = 'select 1 aid, 1 asid, 1 pid, 1 psid where 1=2'  
end  
else if( @aid <> '' and @AnatomicalDesc = '' and @PathologicalDesc = '' )  
begin  -- only on the ACR code  
	set @sSQL1 = 'if exists(select 1 from tbAcrCodeSubAnatomical where 1=1'  
	set @sSQL2 = '  select'  
  
	set @sSQL1 = @sSQL1 + ' and aid = '''+left(@aid, 1)+''' '  
	set @sSQL2 = @sSQL2 + ' '''+left(@aid, 1)+''' aid,'  
  
	--if( len(@asid) > 0 )  
	if( @asid <> '' )  
	begin  
		set @sSQL1 = @sSQL1 + ' and sid = '''+@asid+''' '  
		set @sSQL2 = @sSQL2 + ' '''+@asid+''' asid,'  
	end  
	else  
		set @sSQL2 = @sSQL2 + ' ''-1'' asid,'  
 
	set @sSQL1 = @sSQL1 + ') ' 
 
	if( @psid <> '' ) 
	set @sSQL1 = @sSQL1 + ' and exists(select 1 from tbAcrCodeSubPathological where aid = '''+@aid+'''' 
	else 
	set @sSQL1 = @sSQL1 + ' and exists(select 1 from tbAcrCodePathological where aid = '''+@aid+'''' 
  
	--if( len(@pid) > 0 )  
	if( @pid <> '' )  
	begin  
		set @sSQL1 = @sSQL1 + ' and pid = '''+@pid+''' '  
		set @sSQL2 = @sSQL2 + ' '''+left(@pid, 1)+''' pid,'  
	end  
	else  
		set @sSQL2 = @sSQL2 + ' ''-1'' pid,'  
  
	--if( len(@psid) > 0 )  
	if( @psid <> '' )  
	begin  
		set @sSQL1 = @sSQL1 + ' and sid = '''+@psid+''' '  
		set @sSQL2 = @sSQL2 + ' '''+@psid+''' psid'  
	end  
	else  
		set @sSQL2 = @sSQL2 + ' ''-1'' psid'  
	  
	set @sql = @sSQL1 + ') '+ @sSQL2 +' else select 1 aid, 1 asid, 1 pid, 1 psid where 1=2'  
end  
--else if( len(@pid ) = 0 and len(@psid) = 0 and len(@PathologicalDesc) = 0 )  
--Physon Wang, Aug.11,2005  
else if( @pid  = '' and @psid = '' and @PathologicalDesc = '' )  
begin  ---- only on the anatomical code or desc  
	set @sql = ' select sa.aid aid, sa.sid asid, ''-1'' pid, ''-1'' psid from tbACRCodeAnatomical a, tbAcrCodeSubAnatomical sa where a.aid=sa.aid'  
  
	--if( len(@aid) > 0 )  
	if( @aid <> '' )  
		set @sql = @sql + ' and sa.aid = '''+@aid+''''  
  
	--if( len(@asid) > 0 )  
	if( @asid <> '' )  
		set @sql = @sql + ' and sa.sid = '''+@asid+''''  
  
	--if( len(@AnatomicalDesc) > 0 )  
	if( @AnatomicalDesc <> '' )  
		set @sql = @sql + ' and (a.description like ''%'+@AnatomicalDesc+'%'' or sa.description like ''%'+@AnatomicalDesc+'%'')'  
	  
	set @sql = @sql + ' order by sa.aid, sa.sid '  
end  
else  
begin ---- general condition  
	set @sql = @sql + ' if exists (select * from tempdb..sysobjects where id = object_id(N''tempdb..#tmp_ACR_Y1''))  
		drop table dbo.#tmp_ACR_Y1  '  
	  
	set @sql = @sql + ' if exists (select * from tempdb..sysobjects where id = object_id(N''tempdb..#tmp_ACR_Y2''))  
		drop table dbo.#tmp_ACR_Y2 '  
	  
	set @sSQL1 = ' select a.aid, sa.sid into #tmp_ACR_Y2  
		from tbACRCodeAnatomical a, tbAcrCodeSubAnatomical sa  
		where a.aid = sa.aid'  
	--if(len(@AnatomicalDesc) > 0)  
	if(@AnatomicalDesc <> '')  
		set @sSQL1 = @sSQL1 + ' and (a.description like ''%'+ @AnatomicalDesc +'%'' or sa.description like ''%'+ @AnatomicalDesc +'%'')'  
  
	--if(len(@aid) > 0)  
	if(@aid <> '')  
		set @sSQL1 = @sSQL1 + ' and a.aid ='''+ left(@aid, 1) +''''  
  
	--if(len(@asid) > 0)  
	if(@asid <> '')  
		set @sSQL1 = @sSQL1 + ' and sa.sid ='''+ @asid +''''  
	--else if( len(@aid) > 0 or len(@AnatomicalDesc) > 0 )  
	else if( @aid <> '' or @AnatomicalDesc <> '' )  
	begin  
		set @sSQL1 = @sSQL1 + ' union select aa.aid, ''-1'' from tbACRCodeAnatomical aa where 1=1'  
		  
		--if( len(@aid) > 0 )  
		if( @aid <> '' )  
			set @sSQL1 = @sSQL1 + ' and aa.aid ='''+ @aid +''' '  
  
		--if( len(@AnatomicalDesc) > 0 )  
		if( @AnatomicalDesc <> '' )  
			set @sSQL1 = @sSQL1 + ' and aa.description like ''%'+ @AnatomicalDesc +'%'' '  
	end  
  
	set @sql = @sql + @sSQL1 + ' '  
	  
	set @sSQL2 = ' select sp.aid, sp.pid, sp.sid  into #tmp_ACR_Y1  
	 from tbAcrCodeSubPathological sp  
	 left outer join tbAcrCodePathological p on p.pid = sp.pid and p.aid = sp.aid  
	 where 1=1'  
	--if(len(@AnatomicalDesc) > 0 or len(@aid) > 0 or len(@asid) > 0)  
	if(@AnatomicalDesc <> '' or @aid <> '' or @asid <> '')  
		set @sSQL2 = @sSQL2 + ' and sp.aid in (select distinct aid from #tmp_ACR_Y2) '  
  
	--if(len(@PathologicalDesc) > 0)  
	if(@PathologicalDesc <> '')  
		set @sSQL2 = @sSQL2 + ' and (p.description like ''%'+@PathologicalDesc+'%'' or sp.description like ''%'+@PathologicalDesc+'%'')'  
  
	--if(len(@aid) > 0)  
	if(@aid <> '')  
		set @sSQL2 = @sSQL2 + ' and sp.aid ='''+ left(@aid, 1) +''''  
  
	--if(len(@pid) > 0)  
	if(@pid <> '')  
		set @sSQL2 = @sSQL2 + ' and sp.pid ='''+ left(@pid, 1) +''''  
  
	--if(len(@psid) > 0)  
	if(@psid <> '')  
		set @sSQL2 = @sSQL2 + ' and sp.sid ='''+ @psid +''''  
	--else if( len(@pid) > 0 or len(@PathologicalDesc) > 0 )  
	else if( @pid <> '' or @PathologicalDesc <> '' )  
	begin  
		set @sSQL2 = @sSQL2 + ' union select ap.aid, ap.pid, ''-1'' from tbAcrCodeSubPathological ap where 1=1'  
		  
		--if( len(@aid) > 0 )  
		if( @aid <> '' )  
			set @sSQL2 = @sSQL2 + ' and ap.aid ='''+ @aid +''' '  
  
		--if( len(@pid) > 0 )  
		if( @pid <> '' )  
			set @sSQL2 = @sSQL2 + ' and ap.pid ='''+ @pid +''' '  
  
		--if( len(@PathologicalDesc) > 0 )  
		if(@PathologicalDesc <> '' )  
			set @sSQL2 = @sSQL2 + ' and ap.description like ''%'+ @PathologicalDesc +'%'' '  
	end  
  
	set @sql = @sql + @sSQL2 + ' '  
	  
	set @sql = @sql + ' select #tmp_ACR_Y1.aid, #tmp_ACR_Y2.sid asid, #tmp_ACR_Y1.pid, #tmp_ACR_Y1.sid psid  
		from #tmp_ACR_Y1, #tmp_ACR_Y2  
		where #tmp_ACR_Y1.aid = #tmp_ACR_Y2.aid'  
	  
	set @sql = @sql + ' order by #tmp_ACR_Y1.aid, asid, pid, psid  '  
	  
	set @sql = @sql + ' drop table #tmp_ACR_Y1, #tmp_ACR_Y2  '  
  
end ---- general condition  
  
exec(@sql)  

 
END


GO
/****** Object:  StoredProcedure [dbo].[procSelectFieldValue]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procSelectFieldValue]
	@SelectTableName NVARCHAR(64),
	@SelectFieldName NVARCHAR(64),
	@UniqueFieldName NVARCHAR(64),
	@UniqueFieldValue NVARCHAR(128)
AS
BEGIN
SET NOCOUNT ON;
declare @selectSQL nvarchar(4000)
set @selectSQL = 'select '+ @SelectTableName + '.' + @SelectFieldName + ' from tbRegPatient,tbRegOrder, tbRegProcedure where tbRegPatient.PatientGuid = tbRegOrder.PatientGuid and tbRegOrder.OrderGuid = tbRegProcedure.OrderGuid and '+@UniqueFieldName +'='''+@UniqueFieldValue +''''
print(@selectSQL)
exec sp_executesql @selectSQL
END


GO
/****** Object:  StoredProcedure [dbo].[procSetBrokerXml]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procSetBrokerXml] 
	-- Add the parameters for the stored procedure here
	@dataid nvarchar(64),
	@eventtype nvarchar(64),	
	@accessionnumber nvarchar(64),	
	@reportguid nvarchar(64),
    @orderno nvarchar(64)
	AS	
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	declare @xmlpatient nvarchar(MAX) 
	declare @xmlorder nvarchar(MAX) 
	declare @xmlprocedure nvarchar(MAX) 
	declare @xmlreport nvarchar(MAX) 

	declare @patientguid nvarchar(64)
	declare @orderguid nvarchar(64)
	declare @Xml2Broker nvarchar(MAX) 	
	declare @deleter nvarchar(64)
	
	
	if(LEN(@accessionnumber)=0)
		return;
	
	--过滤event,只有配置中的event才发送
	declare @SendToBrokerXMLEvent nvarchar(128)
	select @SendToBrokerXMLEvent= value from tbSystemProfile where Name='SendToBrokerXMLEvent'
	if(LEN(@SendToBrokerXMLEvent)=0)
		return
		
	declare @in_event int
	select @in_event=CHARINDEX(@eventtype, @SendToBrokerXMLEvent) 
	if(@in_event=0)
		return
	
	--报告event type，如果@reportguid为空， 说明是gw_order call, 忽略
	declare @report_event nvarchar(128)
	declare @in_report int
	set @report_event='30,31,32,33,34,50,51,52'
	select @in_report=CHARINDEX(@eventtype, @report_event) 
	if(@in_report>0 and LEN(@reportguid)=0)
		return
		
		
	select @patientguid=patientguid,@orderguid=orderguid from tbRegOrder where AccNo=@accessionnumber

    set @xmlpatient=(select SocialSecurityNo,Site,RelatedID,ParentName,MedicareNo,GlobalID,Domain,
		Marriage,Alias,Optional3,Optional2,Optional1,RemotePID,Comments,CONVERT(VARCHAR(19),CreateDt, 120) as CreateDt
		,cast(IsVIP as varchar) as IsVIP,Telephone,Address,Gender,CONVERT(VARCHAR(10), birthday, 120) AS birthday,ReferenceNo,
		 EnglishName,LocalName,PatientID,PatientGuid  from tbRegPatient  where PatientGuid=@patientguid FOR XML PATH(''))
		 
	set @xmlorder=(select SubmitDoctor,SubmitDept,SubmitHospital,InjectorRemnant,GoOnGoTime,Insulin,
		BloodSugar,cast(BodyHeight as varchar) as BodyHeight,InjectTime,InjectDose,CONVERT(VARCHAR(19), TakeReportDate, 120) as TakeReportDate, 
		ExternalOptional3,ExternalOptional2,ExternalOptional1,
		InternalOptional2,InternalOptional1,PathologicalFindings,StudyID,Assign2Site,
		CONVERT(VARCHAR(19), AssignDt, 120) as assigndt,CurrentSite,cast(ThreeDRebuild as varchar) as threedrebuild ,cast(FilmFee as varchar) as filmfee,cast(BodyWeight as varchar)  as bodyweight,
		ExamSite ,RegSite,BookingSite,cast(OrderMessage as varchar(max)) as ordermessage,CONVERT(VARCHAR(19), FilmSentDt, 120) as filmsentdt,FilmSentOperator,
		cast(IsFilmSent as varchar) as isfilmsent,cast(Bedside as varchar) as bedside,cast(IsCharge as varchar) as ischarge,cast(Priority as varchar) as priority,CurGender,CurPatientName,
		ERequisition,InitialDomain,LMP,EXAMALERT2,EXAMALERT1,MedicalAlert,ExamDomain,ExamAccNo,
		cast(IsReferral as varchar) as isreferral,ReferralID,Domain,ErethismGrade,ErethismCode,ErethismType,ChargeType,visitcomment,
		cast(AgeInDays as varchar) as ageindays,CurrentAge,BedNo,
		cast(IsEmergency as varchar) as isemergency,InhospitalRegion,HealthHistory,Observation,PatientType,ClinicNo,
		InhospitalNo,PatientGuid,CardNo,HisID,StudyInstanceUID,Optional3,
		Optional2,Optional1,cast(TotalFee as varchar) as totalfee,RemoteAccNo,Comments,cast(IsScan as varchar) as isscan,
		CONVERT(VARCHAR(19), CreateDt, 120) as createdt,ApplyDoctor,ApplyDept,AccNo,VisitGuid,OrderGuid
		 FROM tbRegOrder where OrderGuid=@orderguid FOR XML PATH(''))		   
		   		   
	   if(@in_report>0 )--为报告的相关事件，取Procedures依据ReportGuid tbRegProcedure.orderguid=tbGwOrder.orderno
        begin       	
			   set @xmlprocedure=(select TechnicianName,RegistrarName,BookerName,
				Domain,Technician4,Technician3,Technician2,Technician1,Posture,
				MedicineUsage,ReportGuid,CONVERT(VARCHAR(19), CreateDt, 120) as createdt,BookingTimeAlias,
				QueueNo,Optional3,Optional2,Optional1,RemoteRPID,cast(IsCharge as varchar) as ischarge,
				Booker,CONVERT(VARCHAR(19), BookingEndDt,120) as bookingenddt,CONVERT(VARCHAR(19), BookingBeginDt, 120) as bookingbegindt,Comments,cast(Status as varchar) as status,cast(IsExistImage as varchar) as isexistimage,
				cast(IsPost as varchar) as ispost,CONVERT(VARCHAR(19), ModifyDt, 120) as modifydt,Mender,CONVERT(VARCHAR(19), ExamineDt, 120) as examinedt,OperationStep,TechNurse,
				TechDoctor,Technician,cast(Priority as varchar) as priority,CONVERT(VARCHAR(19), RegisterDt, 120) as registerdt,Registrar,Modality,
				ModalityType,cast(Charge as varchar) as charge,cast(Deposit as varchar) as deposit,cast(ExposalCount as varchar) as exposalcount,cast(ImageCount as varchar) as imagecount,ContrastDose,
				ContrastName,cast(FilmCount as varchar) as filmcount,FilmSpec,cast(WarningTime as varchar) warningtime,ExamSystem,
				ProcedureCode,OrderGuid,ProcedureGuid,
				(select loginname from tbUser where tbUser.UserGuid=tbRegProcedure.Booker) as bookerlname,
				(select loginname from tbUser where tbUser.UserGuid=tbRegProcedure.Registrar) as registrarlname,
				(select loginname from tbUser where tbUser.UserGuid=tbRegProcedure.TechDoctor) as techdoctorlname,
				(select loginname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician) as technicianlname,
				(select loginname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician1) as technician1lname,
				(select loginname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician2) as technician2lname,
				(select loginname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician3) as technician3lname,
				(select loginname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician1) as technician4lname,
				(select loginname from tbUser where tbUser.UserGuid=tbRegProcedure.TechNurse) as technurselname,
				(select localname from tbUser where tbUser.UserGuid=tbRegProcedure.Booker) as bookername,
				(select localname from tbUser where tbUser.UserGuid=tbRegProcedure.Registrar) as registrarname,
				(select localname from tbUser where tbUser.UserGuid=tbRegProcedure.TechDoctor) as techdoctorname,
				(select localname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician) as technicianname,
				(select localname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician1) as technician1name,
				(select localname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician2) as technician2name,
				(select localname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician3) as technician3name,
				(select localname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician1) as technician4name,
				(select localname from tbUser where tbUser.UserGuid=tbRegProcedure.TechNurse) as technursename
				 from tbRegProcedure where OrderGuid=@orderguid FOR XML PATH('Procedure'))
				
	      end       
        else
        begin
        print 'if others'
        ---others tbRegProcedure.ProcedureGuid=tbGwOrder.orderno
			   set @xmlprocedure=(select TechnicianName,RegistrarName,BookerName,
				Domain,Technician4,Technician3,Technician2,Technician1,Posture,
				MedicineUsage,ReportGuid,CONVERT(VARCHAR(19), CreateDt, 120) as createdt,BookingTimeAlias,
				QueueNo,Optional3,Optional2,Optional1,RemoteRPID,cast(IsCharge as varchar) as ischarge,
				Booker,CONVERT(VARCHAR(19), BookingEndDt,120) as bookingenddt,CONVERT(VARCHAR(19), BookingBeginDt, 120) as bookingbegindt,Comments,cast(Status as varchar) as status,cast(IsExistImage as varchar) as isexistimage,
				cast(IsPost as varchar) as ispost,CONVERT(VARCHAR(19), ModifyDt, 120) as modifydt,Mender,CONVERT(VARCHAR(19), ExamineDt, 120) as examinedt,OperationStep,TechNurse,
				TechDoctor,Technician,cast(Priority as varchar) as priority,CONVERT(VARCHAR(19), RegisterDt, 120) as registerdt,Registrar,Modality,
				ModalityType,cast(Charge as varchar) as charge,cast(Deposit as varchar) as deposit,cast(ExposalCount as varchar) as exposalcount,cast(ImageCount as varchar) as imagecount,ContrastDose,
				ContrastName,cast(FilmCount as varchar) as filmcount,FilmSpec,cast(WarningTime as varchar) warningtime,ExamSystem,
				ProcedureCode,OrderGuid,ProcedureGuid,
				(select loginname from tbUser where tbUser.UserGuid=tbRegProcedure.Booker) as bookerlname,
				(select loginname from tbUser where tbUser.UserGuid=tbRegProcedure.Registrar) as registrarlname,
				(select loginname from tbUser where tbUser.UserGuid=tbRegProcedure.TechDoctor) as techdoctorlname,
				(select loginname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician) as technicianlname,
				(select loginname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician1) as technician1lname,
				(select loginname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician2) as technician2lname,
				(select loginname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician3) as technician3lname,
				(select loginname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician1) as technician4lname,
				(select loginname from tbUser where tbUser.UserGuid=tbRegProcedure.TechNurse) as technurselname,
				(select localname from tbUser where tbUser.UserGuid=tbRegProcedure.Booker) as bookername,
				(select localname from tbUser where tbUser.UserGuid=tbRegProcedure.Registrar) as registrarname,
				(select localname from tbUser where tbUser.UserGuid=tbRegProcedure.TechDoctor) as techdoctorname,
				(select localname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician) as technicianname,
				(select localname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician1) as technician1name,
				(select localname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician2) as technician2name,
				(select localname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician3) as technician3name,
				(select localname from tbUser where tbUser.UserGuid=tbRegProcedure.Technician1) as technician4name,
				(select localname from tbUser where tbUser.UserGuid=tbRegProcedure.TechNurse) as technursename
				 from tbRegProcedure where OrderGuid=@orderguid and ProcedureGuid=@orderno FOR XML PATH('Procedure'))	      
				 		
	      end
        
        
        if @eventtype='33' ---delete a report
       begin
				set @xmlreport =(select TechInfo,MenderName,CreaterName,ReportQualityComments,SecondApproverName,
				FirstApproverName,SubmitterName,ReportQuality2,cast(RebuildMark as varchar) as rebuildmark,
				SecondApproveSite,FirstApproveSite,SubmitSite,RejectSite,SecondApproveDomain ,
				FirstApproveDomain,RejectDomain,SubmitDomain,cast(ReadOnly as varchar) as readonly,Domain,PrintTemplateGuid,
				cast(PrintCopies as varchar) as printcopies,TakeFilmComment,TakeFilmRegion,TakeFilmDept,cast(IsLeaveSound as varchar) as isleavesound,CONVERT(VARCHAR(19), DrawTime, 120) as drawtime,   
				cast(IsDraw as varchar) as isdraw,WYGText,WYSText,cast(IsLeaveWord as varchar) as isleaveword,Optional3,
				Optional2,Optional1,CheckItemName,cast(IsPrint as varchar) as isprint,CONVERT(VARCHAR(19), ModifyDt, 120) as modifydt,Mender,
				CONVERT(VARCHAR(19), ReconvertDt, 120) as reconverdt,Recuperator,CONVERT(VARCHAR(19), DeleteDt, 120) as deletedt,Deleter,Comments,
				cast(Status as varchar) as status,CONVERT(VARCHAR(19), RejectDt, 120) as rejectdt,Rejecter,RejectToObject,ReportQuality,KeyWord,
				cast(IsDiagnosisRight as varchar) as isdiagnosisright,CONVERT(VARCHAR(19), SecondApproveDt, 120) as secondapprovedt,SecondApprover,CONVERT(VARCHAR(19), FirstApproveDt, 120) as firstapproverdt,FirstApprover,
				CONVERT(VARCHAR(19), SubmitDt, 120) as submitdt,Submitter,CONVERT(VARCHAR(19), CreateDt, 120) as createdt,Creater,AcrPathologic,AcrAnatomic,
				AcrCode,cast(IsPositive as varchar) as IsPositive,DoctorAdvice,ReportText,ReportName,
				ReportGuid,
				(select loginname from tbUser where tbUser.UserGuid=tbReport.Creater) as createrlname,
				(select localname from tbUser where tbUser.UserGuid=tbReport.Creater) as creatername,
				(select loginname from tbUser where tbUser.UserGuid=tbReport.Submitter) as submitterlname,
				(select localname from tbUser where tbUser.UserGuid=tbReport.Submitter) as submittername,
				(select loginname from tbUser where tbUser.UserGuid=tbReport.FirstApprover) as firstapproverlname,	
				(select localname from tbUser where tbUser.UserGuid=tbReport.FirstApprover) as firstapprovername,	
				(select loginname from tbUser where tbUser.UserGuid=tbReport.Deleter) as Deleterlname,
				(select localname from tbUser where tbUser.UserGuid=tbReport.Deleter) as Deletername, 
				CONVERT(VARCHAR(19), tbReport.DeleteDt, 120) DeleteDt,
			    (select loginname from tbUser where tbUser.UserGuid=tbReport.SecondApprover) as SecondApproverlname,	
				(select localname from tbUser where tbUser.UserGuid=tbReport.SecondApprover) as SecondApprovername 
				FROM tbReportDelPool tbReport where ReportGuid=@ReportGuid FOR XML PATH(''))		  
				
       end
       else
       begin
		 set @xmlreport =(select TechInfo,MenderName,CreaterName,ReportQualityComments,SecondApproverName,
				FirstApproverName,SubmitterName,ReportQuality2,cast(RebuildMark as varchar) as rebuildmark,
				SecondApproveSite,FirstApproveSite,SubmitSite,RejectSite,SecondApproveDomain ,
				FirstApproveDomain,RejectDomain,SubmitDomain,cast(ReadOnly as varchar) as readonly,Domain,PrintTemplateGuid,
				cast(PrintCopies as varchar) as printcopies,TakeFilmComment,TakeFilmRegion,TakeFilmDept,cast(IsLeaveSound as varchar) as isleavesound,CONVERT(VARCHAR(19), DrawTime, 120) as drawtime,   
				cast(IsDraw as varchar) as isdraw,WYGText,WYSText,cast(IsLeaveWord as varchar) as isleaveword,Optional3,
				Optional2,Optional1,CheckItemName,cast(IsPrint as varchar) as isprint,CONVERT(VARCHAR(19), ModifyDt, 120) as modifydt,Mender,
				CONVERT(VARCHAR(19), ReconvertDt, 120) as reconverdt,Recuperator,CONVERT(VARCHAR(19), DeleteDt, 120) as deletedt,Deleter,Comments,
				cast(Status as varchar) as status,CONVERT(VARCHAR(19), RejectDt, 120) as rejectdt,Rejecter,RejectToObject,ReportQuality,KeyWord,
				cast(IsDiagnosisRight as varchar) as isdiagnosisright,CONVERT(VARCHAR(19), SecondApproveDt, 120) as secondapprovedt,SecondApprover,CONVERT(VARCHAR(19), FirstApproveDt, 120) as firstapproverdt,FirstApprover,
				CONVERT(VARCHAR(19), SubmitDt, 120) as submitdt,Submitter,CONVERT(VARCHAR(19), CreateDt, 120) as createdt,Creater,AcrPathologic,AcrAnatomic,
				AcrCode,cast(IsPositive as varchar) as IsPositive,DoctorAdvice,ReportText,ReportName,
				ReportGuid,
				(select loginname from tbUser where tbUser.UserGuid=tbReport.Creater) as createrlname,
				(select localname from tbUser where tbUser.UserGuid=tbReport.Creater) as creatername,
				(select loginname from tbUser where tbUser.UserGuid=tbReport.Submitter) as submitterlname,
				(select localname from tbUser where tbUser.UserGuid=tbReport.Submitter) as submittername,
				(select loginname from tbUser where tbUser.UserGuid=tbReport.FirstApprover) as firstapproverlname,	
				(select localname from tbUser where tbUser.UserGuid=tbReport.FirstApprover) as firstapprovername,
			    (select loginname from tbUser where tbUser.UserGuid=tbReport.SecondApprover) as SecondApproverlname,	
				(select localname from tbUser where tbUser.UserGuid=tbReport.SecondApprover) as SecondApprovername 	
				 FROM tbReport where ReportGuid=@ReportGuid FOR XML PATH(''))
				  

		 end

	
	declare @xml1 nvarchar(max) 
	declare @xml2 nvarchar(max) 
	declare @xml3 nvarchar(max) 
	declare @xml4 nvarchar(max) 
	declare @xml5 nvarchar(max) 

	set @xml1=REPLACE(@xmlpatient,'><','*&*')
	 set @xml2 = REPLACE(@xml1,'>','><![CDATA[') 
	 set @xml3 = REPLACE(@xml2,'</',']]></')
	 set @xml4=LEFT(@xml3,len(@xml3)-9)
	 set @xmlpatient='<Patient>'+ REPLACE(@xml4,'*&*','><')+'</Patient>' 
	 
	 
	 set @xml1=REPLACE(@xmlorder,'><','*&*')
	 set @xml2 = REPLACE(@xml1,'>','><![CDATA[') 
	 set @xml3 = REPLACE(@xml2,'</',']]></')
	 set @xml4=LEFT(@xml3,len(@xml3)-9)
	 set @xmlorder='<Order>'+REPLACE(@xml4,'*&*','><')+'</Order>'
	 
	 set @xml1=REPLACE(@xmlprocedure,'><','*&*')
	 set @xml2 = REPLACE(@xml1,'>','><![CDATA[') 
	 set @xml3 = REPLACE(@xml2,'</',']]></')
	 set @xml4=LEFT(@xml3,len(@xml3)-9)
	 set @xmlprocedure=REPLACE(@xml4,'*&*','><')
			 
	 set @Xml2Broker='<ExamInfo>' +CAST(@xmlpatient AS nvarchar(max)) +CAST(@xmlorder AS nvarchar(max))
	 if(LEN(@xmlprocedure)>0)
		set  @Xml2Broker=@Xml2Broker+CAST(@xmlprocedure AS nvarchar(max))
		
	 if(LEN(@reportguid)>0)
		begin
		 set @xml1=REPLACE(@xmlreport,'><','*&*')
		 set @xml2 = REPLACE(@xml1,'>','><![CDATA[') 
		 set @xml3 = REPLACE(@xml2,'</',']]></')
		 set @xml4=LEFT(@xml3,len(@xml3)-9)
		 set @xmlreport='<Report>'+REPLACE(@xml4,'*&*','><') +'</Report>'
		 
		  set @Xml2Broker=@Xml2Broker+CAST(@xmlreport AS nvarchar(max)) 
	 end
	 set @Xml2Broker=@Xml2Broker+'</ExamInfo>'

	if @eventtype='33'
	begin
		declare @deleteguid nvarchar(64)
		select @deleteguid=deleter from tbReportDelPool where ReportGuid=@reportguid
		select @deleter=loginname+'|'+localname from tbUser where UserGuid=@deleteguid
		update tbGwOrder set REF_ORGANIZATION=@Xml2Broker,FILLER_CONTACT=@deleter where DATA_ID=@dataid
				
	end
	else	 
     update tbGwOrder set REF_ORGANIZATION=@Xml2Broker where DATA_ID=@dataid
  
	
END


GO
/****** Object:  StoredProcedure [dbo].[procSetFirstVisitMark]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<bruce deng>
-- Create date: <2105-07-23>
-- Description:	<Set first visit mark for patient, only available for the first time of modality type>
-- =============================================
CREATE PROCEDURE [dbo].[procSetFirstVisitMark]
(
	-- Add the parameters for the function here
	@OrderGuid nvarchar(64),
	@ModalityType nvarchar(64),	
	@Site nvarchar(64)
)
AS
BEGIN
	DECLARE @AutoSetFirstVisitMark nvarchar(8)	
	DECLARE @AccNo nvarchar(64)
	DECLARE @PatientGuid nvarchar(64)
	
	DECLARE @CreateDt datetime
	DECLARE @ErrorMessage nvarchar(256)
	 if exists (select 1 from tbSiteProfile where Name ='ReportEditor_AutoSetFirstVisitMark' and  ModuleID = '0400' and Site =@Site)
		select @AutoSetFirstVisitMark=Value from tbSiteProfile where Name ='ReportEditor_AutoSetFirstVisitMark' and  ModuleID = '0400' and Site =@Site
	else 
		select @AutoSetFirstVisitMark=Value from tbSystemProfile where Name ='ReportEditor_AutoSetFirstVisitMark' and  ModuleID = '0400'
		
	if(@AutoSetFirstVisitMark is null or len(@AutoSetFirstVisitMark)=0 or @AutoSetFirstVisitMark=0)
		return 1
	
	select @PatientGuid=PatientGuid,@AccNo=AccNo,@CreateDt=CreateDt from tbRegOrder where OrderGuid=@OrderGuid
	
	if  exists(select 1 from tbRegProcedure where OrderGuid in (select OrderGuid from tbRegOrder where PatientGuid=@PatientGuid and OrderGuid!=@OrderGuid and CreateDt<@CreateDt ) and ModalityType=@ModalityType)
		return 2
	
	--set first visit mark
	EXEC [dbo].[procInsertOrderMessage]
			@AccNo = @AccNo,
			@Type = N'j',
			@UserGuid = N'',
			@UserName = N'',
			@Subject = N'初诊',
			@Context = N'',
			@ErrorMessage = @ErrorMessage OUTPUT
	return 0
		
END


GO
/****** Object:  StoredProcedure [dbo].[procSetPrintEfilmNumber]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procSetPrintEfilmNumber]
	@AccNo nvarchar(64),
	@EFilmNumber int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	update tbRegOrder set EFilmNumber=@EFilmNumber, IsFilmSent = 1, FilmSentDt = GETDATE(), FilmSentOperator = 'CSBroker' where AccNo=@AccNo
END


GO
/****** Object:  StoredProcedure [dbo].[procStaffMonthForRadiologist]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[procStaffMonthForRadiologist]
 -- Add the parameters for the stored procedure here
    @Role varchar(32),
    @DateField varchar(64),
    @DateTime varchar(512),
          @ModalityType varchar(1024),
          @BodyPart varchar(8000),
     @strSQL varchar(8000)
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;

    -- Insert statements for procedure here
DECLARE @szSQL varchar(8000)
DECLARE @szReqDt varchar(128)
  set @szReqDt = substring(@DateTime,charindex('.',@DateTime)+1,(charindex(')',@DateTime) - charindex('.',@DateTime)-1) )

  set @szSQL='SELECT   '+@Role
      +'pc.ModalityType,pc.BodyPart,pc.Description ProcedureCode,'+@DateField+',DATEPART(YYYY, tbReport.'+@szReqDt+') as Year,DATEPART(MM, tbReport.'+@szReqDt+') as Month, DATEPART(DD, tbReport.'+@szReqDt
   +') AS Day '
         +' FROM   '
   +' tbReport INNER JOIN '
   +' tbRegProcedure AS rp INNER JOIN '
   +' tbProcedureCode AS pc ON rp.ProcedureCode  = pc.ProcedureCode ON tbReport.ReportGuid = rp.ReportGuid WHERE 1=1 and  '
 if (@DateTime<>'')
  set @szSQL=@szSQL+@DateTime

 EXEC(@szSQL+' '+@ModalityType+' '+@BodyPart+' '+@strSQL)
END


GO
/****** Object:  StoredProcedure [dbo].[procStaffMonthForRegistrar]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procStaffMonthForRegistrar]
 -- Add the parameters for the stored procedure here
   @Year varchar(16),
   @Month varchar(16),
   @Role varchar(32),
   @ModalityType varchar(1024),
   @BodyPart varchar(8000),
    @strSQL varchar(8000)
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;

    -- Insert statements for procedure here
  DECLARE @szSQL varchar(8000)
  set @szSQL='SELECT   '+@Role+
    ' ro.OrderGuid,pc.ModalityType,pc.BodyPart,pc.Description ProcedureCode,pc.TechnicianWeight,pc.RadiologistWeight,ro.CreateDt as RegDate,DATEPART(YYYY,ro.CreateDt) AS Year,DATEPART(MM,ro.CreateDt) AS Month,DATEPART(DD,ro.CreateDt) AS Day 
     FROM  tbRegOrder as Ro INNER JOIN 
                   tbRegProcedure AS rp ON ro.OrderGuid = rp.OrderGuid INNER JOIN 
                   tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode
                    WHERE  (rp.Status>=20) and   (DATEPART(YY, Ro.CreateDt) = '+@Year+') AND (DATEPART(MM, Ro.CreateDt) = '+@Month+') '

      EXEC(@szSQL+@ModalityType+@BodyPart+@strSQL)
END


GO
/****** Object:  StoredProcedure [dbo].[procStaffMonthForTechnician]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procStaffMonthForTechnician]
 -- Add the parameters for the stored procedure here
   @Year varchar(16),
   @Month varchar(16),
   @Role varchar(32),
   @BodyPart varchar(8000),
    @strSQL varchar(8000)
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;

    -- Insert statements for procedure here
  DECLARE @szSQL varchar(8000)
     Set @szSQL= 'SELECT '+@Role + ' pc.ModalityType,pc.Description ProcedureCode,rp.ExamineDt as RegDate,pc.BodyPart,pc.TechnicianWeight,pc.RadiologistWeight,DATEPART(YYYY,rp.ExamineDt) AS Year,DATEPART(MM,rp.ExamineDt) AS Month,DATEPART(DD,rp.ExamineDt) AS Day
                   ,rp.Technician,rp.Technician1,rp.Technician2,rp.Technician3,rp.Technician4 FROM tbRegProcedure AS rp INNER JOIN
                     tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode
                  WHERE (rp.Status>=50) and (DATEPART(YY, rp.ExamineDt) = '+@Year+') AND (DATEPART(MM, rp.ExamineDt) = '+@Month+') '
       
      EXEC(@szSQL+@BodyPart+' '+@strSQL)
END


GO
/****** Object:  StoredProcedure [dbo].[procStaffTimeSliceForRadiologist]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procStaffTimeSliceForRadiologist]
-- Add the parameters for the stored procedure here
		  @DateTime varchar(512),
		  @DateField varchar(64),
          @ModalityType varchar(1024),
          @Role varchar(32),
	      @BodyPart varchar(8000),
	 	  @Staff varchar(8000)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	 DECLARE @szSQL varchar(8000)

     set @szSQL='SELECT   pc.ModalityType,'+@DateField+',pc.BodyPart, pc.Description ProcedureCode '+@Role+
         +' FROM    '
		 +' tbReport INNER JOIN '
		 +' tbRegProcedure AS rp INNER JOIN '
		 +' tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode ON tbReport.ReportGuid = rp.ReportGuid WHERE  1=1 and  '
		 +@DateTime

	EXEC(@szSQL+' '+@ModalityType+' '+@BodyPart+' '+@Staff)
END


GO
/****** Object:  StoredProcedure [dbo].[procStaffTimeSliceForRegistrar]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procStaffTimeSliceForRegistrar]
	@DateTime varchar(1024),
	@Role varchar(32),
	@Staff varchar(8000),
	@ModalityType varchar(1024),
	@BodyPart varchar(8000)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @szSQL varchar(8000)
	set @szSQL='SELECT '+@Role+'   Ro.CreateDt as RegDate, ro.OrderGuid,pc.ModalityType,pc.BodyPart, pc.Description ProcedureCode, pc.TechnicianWeight,pc.RadiologistWeight 
				FROM tbRegOrder AS Ro INNER JOIN 
                tbRegProcedure AS rp ON Ro.OrderGuid = rp.OrderGuid INNER JOIN 
                tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode 
				WHERE (rp.Status>=20) and   '+@DateTime


		EXEC(@szSQL+' '+@ModalityType+' '+@BodyPart+@Staff)
END


GO
/****** Object:  StoredProcedure [dbo].[procStaffTimeSliceForTechnician]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procStaffTimeSliceForTechnician]
	@DateTime varchar(1024),
	@ModalityType varchar(1024),
	@Role varchar(32),
	@BodyPart varchar(8000),
	@Staff varchar(8000)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	 DECLARE @szSQL varchar(8000)
      Set @szSQL= 'SELECT pc.ModalityType,rp.ExamineDt as RegDate,pc.BodyPart, pc.Description ProcedureCode,pc.TechnicianWeight,pc.RadiologistWeight '+@Role+
		' ,rp.Technician,rp.Technician1,rp.Technician2,rp.Technician3,rp.Technician4 FROM tbRegProcedure AS rp INNER JOIN 
                  		 tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode 
				WHERE (rp.Status>=50) and '+@DateTime

	EXEC(@szSQL+' '+@ModalityType+' '+@BodyPart+' '+@Staff)
END


GO
/****** Object:  StoredProcedure [dbo].[procStaffYearForRadiologist]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE  [dbo].[procStaffYearForRadiologist]
 -- Add the parameters for the stored procedure here
    @Role varchar(32),
    @DateField varchar(64),
    @DateTime varchar(512),
          @ModalityType varchar(1024),
          @BodyPart varchar (8000),
     @strSQL varchar(8000)
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;

    -- Insert statements for procedure here
     DECLARE @szSQL varchar(8000)
  DECLARE @szReqDt varchar(128)
  set @szReqDt = substring(@DateTime,charindex('.',@DateTime)+1,(charindex(')',@DateTime) - charindex('.',@DateTime)-1) )
  
     set @szSQL='SELECT   '+' '+@Role+'pc.ModalityType,pc.BodyPart,pc.Description ProcedureCode, '+@DateField+', DATEPART(YYYY, tbReport.'+@szReqDt
   +') AS Year, '+ 'DATEPART(MM, tbReport.'+@szReqDt
   +') AS Month '
         +' FROM  '
   +' tbReport INNER JOIN '
   +' tbRegProcedure AS rp INNER JOIN '
   +' tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode ON tbReport.ReportGuid = rp.ReportGuid WHERE  1=1 and '
 if (@DateTime<>'')
  set @szSQL=@szSQL+@DateTime

--     if (@ModalityType<>0)
--  set @szSQL=@szSQL+@ModalityType
  --   if (@strSQL<>0)
 -- set @szSQL=@szSQL+@strSQL

   EXEC(@szSQL+' '+@ModalityType+' '+@BodyPart+' '+@strSQL)
END


GO
/****** Object:  StoredProcedure [dbo].[procStaffYearForRegistrar]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procStaffYearForRegistrar]
 -- Add the parameters for the stored procedure here
   @Year varchar(16),
   @Modality varchar(1024),
   @Role varchar (32),
   @BodyPart varchar(8000),
    @strSQL varchar(8000)
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;

    -- Insert statements for procedure here
  DECLARE @szSQL varchar(8000)
      Set @szSQL= 'SELECT '+@Role+'ro.OrderGuid,pc.ModalityType,pc.bodypart,pc.Description ProcedureCode,pc.TechnicianWeight,pc.RadiologistWeight,ro.CreateDt as RegDate,DATEPART(YYYY,ro.CreateDt) AS Year,DATEPART(MM,ro.CreateDt) AS Month 
     FROM  tbRegOrder as Ro INNER JOIN 
                   tbRegProcedure AS rp ON ro.OrderGuid = rp.OrderGuid INNER JOIN 
                   tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode
                    WHERE (rp.Status>=20) and  (DATEPART(YY, ro.CreateDt) = ' + @Year+') '

      EXEC(@szSQL+@Modality+@BodyPart+@strSQL)
END


GO
/****** Object:  StoredProcedure [dbo].[procStaffYearForTechnician]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procStaffYearForTechnician]
 -- Add the parameters for the stored procedure here
   @Year varchar(16),
   @Role varchar(32),
   @BodyPart varchar(8000),
    @strSQL varchar(8000)
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;
 print @bodypart
 print len(@bodypart)
    -- Insert statements for procedure here
  DECLARE @szSQL varchar(8000)
     Set @szSQL= 'SELECT '+@Role + ' pc.ModalityType,pc.BodyPart,pc.Description ProcedureCode,pc.TechnicianWeight,pc.RadiologistWeight,rp.ExamineDt as RegDate,DATEPART(YYYY,rp.ExamineDt) AS Year,DATEPART(MM,rp.ExamineDt) AS Month
                  ,rp.Technician,rp.Technician1,rp.Technician2,rp.Technician3,rp.Technician4 FROM tbRegProcedure AS rp INNER JOIN
                     tbProcedureCode AS pc ON rp.ProcedureCode = pc.ProcedureCode
                  WHERE (rp.Status>=50) and (DATEPART(YY, rp.ExamineDt) = ' + @Year+') '
       

      EXEC(@szSQL+' '+@BodyPart+' '+@strSQL)
END


GO
/****** Object:  StoredProcedure [dbo].[procStatisticCustomizeStat]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[procStatisticCustomizeStat]
	@ConditionStr nvarchar(4000)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	  DECLARE @szSQL  nvarchar(4000)
      Set @szSQL= 'select DISTINCT '
      +' tbRegPatient.Localname as PatientName, '
      +' (select DISTINCT [Text] from tbDictionaryValue where tbRegPatient.Gender=tbDictionaryValue.[Value] and tbDictionaryValue.tag=1) as Gender, '
      +' tbRegPatient.PatientID,ro.Accno,'
      +' (select DISTINCT [Text] from tbDictionaryValue where tbDictionaryValue.[Value]=ro.ApplyDept and tbDictionaryValue.tag=2) as ApplyDept,'
      +' (select DISTINCT [Text] from tbDictionaryValue where tbDictionaryValue.tag=3 and tbDictionaryValue.[Value]=ro.InhospitalRegion) as InHospitalRegion,'
      +' (select DISTINCT [Text] from tbDictionaryValue where tbDictionaryValue.tag=5 and tbDictionaryValue.[Value]=ro.PatientType) as PatientType,'
      +' rp.ModalityType,tbProcedureCode.BodyPart ,rp.ExamSystem, '
      +' (select DISTINCT  [Text] from tbDictionaryValue where tbDictionaryValue.tag=8 and ro.ApplyDoctor=tbDictionaryValue.[Value]) as ApplyDoctor, '
      +' (Select DISTINCT  tbUser.LocalName from tbUser where tbReport.Creater = tbUser.Userguid) as ReportDoctor, '
      +' (Select DISTINCT  tbUser.LocalName from tbUser where tbUser.Userguid =tbReport.FirstApprover) as AporoveDoctor, '
      +' tbReport.ACRCode,rp.ExamineDt,tbReport.CreateDt,tbReport.FirstApproveDt,'
      +' (select DISTINCT [Text] from tbDictionaryValue where tbDictionaryValue.tag=21 and tbDictionaryValue.[Value]=tbReport.IsPositive) as IsPositive  '
      + ' from  tbRegOrder as ro,tbProcedureCode,tbRegPatient,tbRegProcedure as rp,tbReport,tbUser  '
      +' where (tbRegPatient.PatientGuid = ro.PatientGuid) and (ro.OrderGuid = rp.OrderGuid) and (tbReport.reportguid = rp.reportguid) '
      +' and (tbProcedureCode.Procedurecode = rp.Procedurecode) '
      +@ConditionStr

	print @szSQL
	exec sp_executesql 	@szSQL
END


GO
/****** Object:  StoredProcedure [dbo].[procTechGetPatInfo]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/*=======================================================================================================================    
存储过程：rsp_TechGetPatInfo    
界面调用：    
传入参数：@PatType VARCHAR(10)  病员类别 （WardOrReg）    
   @HospNo VARCHAR(20)=''  门诊住院号    
   @CardNo  VARCHAR(30)=''  病人磁卡号    
传出参数：无    
  返回值：病人基本信息数据集    
    说明：根据传入条件（病员类别、门诊住院号或病人磁卡号），从HIS数据库调出该病人的基本信息。    
    备注：    
修改纪录：2001/04/29    
作者：BurningSoft    
      Modify  By  Wayne  2003-07-22    
        修改内容： @PatType与@WardOrReg相同   
		2004-03-15	wwr	modify	如果传入的是病人唯一号（patid），不论住院还是门诊都要可以取到病人信息   
========================================================================================================================*/    
CREATE PROCEDURE [dbo].[procTechGetPatInfo]    
    @PatType           VARCHAR(10),              --病人类别    
    @HospNo            VARCHAR(20) = '',         --住院、门诊号    
    @CardNo            VARCHAR(30) = '',         --卡号    
    @ApplyNo           VARCHAR(20) = '',         --预留    
    @IDInHosp          VARCHAR(30) = ''          --病人唯一ID    
AS    
BEGIN    
    
  DECLARE         @WardOrReg            INT    
    
  if LTRIM(RTRIM(@PatType)) = '1'    
    select @WardOrReg = 1    
  else    
    select @WardOrReg = 0    
    
  IF IsNull(LTRIM(RTRIM(@HospNo)),'') <> ''  /*********** 根据住院或门诊号查找 ***********/    
  BEGIN    
    if @WardOrReg = 1    
    begin    
	    select PatName = A.hzxm , Sex = CASE A.sex WHEN '男' THEN '1' WHEN  '女' THEN  '2' ELSE  '3' END ,    

		Age = 	case 
			when substring(A.birth,1,4) = substring(convert(varchar,getdate(),111),1,4) then '1' 
      			when substring(A.birth,1,4) between '1753' and '9999' then convert(varchar,datediff(year,substring(A.birth,1,4)+'0101',getdate())) 
			else ' ' 
			end,
	        AgeUnit = '岁', WardOrReg = (case when F.pzlx in ('10','11') and F.bjqkdm = 1 then 2 else @WardOrReg end),  
        	HospNo = A.blh,  ChargeType = A.ybdm ,CureNo = A.syxh, PatientId = B.patid, CardNo = A.cardno ,ApplyDept = A.ksdm ,    
            	Ward = A.bqdm , BedNo = A.cwdm,  ToDoc = A.ysdm, ClincDesc = A.zddm, IDNum = B.sfzh,   
	        Phone = B.lxdh, Address = B.lxdz, Zip = B.lxyb, Career = D.name, Nation = M.name       
    	    FROM  ZY_BRSYK A left join YY_YBFLK F on  A.ybdm = F.ybdm  , ZY_BRXXK B left join  YY_ZYDMK D on B.zybm = D.id   left join YY_MZDMK M on B.mzbm = M.id       
            WHERE A.blh = @HospNo    
		     and  A.patid = B.patid         
			 and  A.brzt not in (0,3,8,9) -- modify by wang yi
    end    
    else    
    begin    
	    set rowcount 1  
	    select  PatName = b.hzxm , Sex = CASE b.sex WHEN '男' THEN '1' WHEN  '女' THEN  '2' ELSE  '3' END ,    

		Age = 	case 
			when substring(b.birth,1,4) = substring(convert(varchar,getdate(),111),1,4) then '1' 
      			when substring(b.birth,1,4) between '1753' and '9999' then convert(varchar,datediff(year,substring(b.birth,1,4)+'0101',getdate())) 
			else ' ' 
			end,
	      AgeUnit = '岁', WardOrReg = (case when F.pzlx in ('10','11') and F.bjqkdm = 1 then 2 else @WardOrReg end),  
              ChargeType = b.ybdm , HospNo = b.blh, Ward = space(1) , BedNo = space(1), IDNum = b.sfzh,   

			CureNo = (select top 1 ghxh from SF_BRJSK a where a.patid = b.patid and ghsfbz = 0 order by sfrq desc),
			PatientId = b.patid, CardNo = b.cardno , 
	      ApplyDept = (select top 1 a.ksdm from SF_BRJSK a where a.patid=b.patid order by a.sfrq desc),   
              Phone = b.lxdh, Address = b.lxdz, Zip = b.yzbm, Career = Space(1), Nation = Space(1)          
            from  SF_BRXXK b left join YY_YBFLK F  on b.ybdm = F.ybdm
            WHERE b.blh = @HospNo
	    set rowcount 0  
    end    
  END    
  ELSE    
  IF IsNull(LTRIM(RTRIM(@CardNo)),'') <> ''  /*********** 根据卡号查找 ***********/    
  BEGIN    
    /* 将来可能要修改为：首先查找住院类的病人，然后再查找门诊类的病人，再比较登记的时间，取得最近的一条返回 */    
    if @WardOrReg = 1    
    begin    
	    select PatName = A.hzxm , Sex = CASE A.sex WHEN '男' THEN '1' WHEN  '女' THEN  '2' ELSE  '3' END ,    

		Age = 	case 
			when substring(A.birth,1,4) = substring(convert(varchar,getdate(),111),1,4) then '1' 
      			when substring(A.birth,1,4) between '1753' and '9999' then convert(varchar,datediff(year,substring(A.birth,1,4)+'0101',getdate())) 
			else ' ' 
			end,
	        AgeUnit = '岁', WardOrReg = (case when F.pzlx in ('10','11') and F.bjqkdm = 1 then 2 else @WardOrReg end),  
        	HospNo = A.blh,  ChargeType = A.ybdm ,CureNo = A.syxh, PatientId = B.patid, CardNo = A.cardno ,ApplyDept = A.ksdm ,    
            	Ward = A.bqdm , BedNo = A.cwdm,  ToDoc = A.ysdm, ClincDesc = A.zddm, IDNum = B.sfzh,   
	        Phone = B.lxdh, Address = B.lxdz, Zip = B.lxyb, Career = D.name, Nation = M.name       
    	    FROM  ZY_BRSYK A left join YY_YBFLK F on   A.ybdm = F.ybdm , ZY_BRXXK B left join YY_ZYDMK D on B.zybm = D.id left join YY_MZDMK M on  B.mzbm = M.id      
            WHERE A.cardno = @CardNo     
		     and  A.patid = B.patid         
			 and  A.brzt not in (0,3,8,9) -- modify by wang yi
    end    
    else    
    begin    
	    set rowcount 1  
	    select  PatName = b.hzxm , Sex = CASE b.sex WHEN '男' THEN '1' WHEN  '女' THEN  '2' ELSE  '3' END ,    

		Age = 	case 
			when substring(b.birth,1,4) = substring(convert(varchar,getdate(),111),1,4) then '1' 
      			when substring(b.birth,1,4) between '1753' and '9999' then convert(varchar,datediff(year,substring(b.birth,1,4)+'0101',getdate())) 
			else ' ' 
			end,
	      AgeUnit = '岁', WardOrReg = (case when F.pzlx in ('10','11') and F.bjqkdm = 1 then 2 else @WardOrReg end),  
              ChargeType = b.ybdm , HospNo = b.blh, Ward = space(1) , BedNo = space(1), IDNum = b.sfzh,   

			CureNo = (select top 1 ghxh from SF_BRJSK a where a.patid = b.patid and ghsfbz = 0 order by sfrq desc),
			PatientId = b.patid, CardNo = b.cardno ,      
	      ApplyDept = (select top 1 a.ksdm from SF_BRJSK a where a.patid=b.patid order by a.sfrq desc),   
              Phone = b.lxdh, Address = b.lxdz, Zip = b.yzbm, Career = Space(1), Nation = Space(1)          
            from  SF_BRXXK b left join YY_YBFLK F on b.ybdm = F.ybdm
            WHERE b.cardno = @CardNo 
	    set rowcount 0  
    end    
  END    
  ELSE    
  IF IsNull(LTRIM(RTRIM(@IDInHosp)),'') <> ''  /*********** 根据病人唯一号查找（只查找住院病人） ***********/    
  BEGIN    
	if @WardOrReg = 1      
	    select PatName = A.hzxm , Sex = CASE A.sex WHEN '男' THEN '1' WHEN  '女' THEN  '2' ELSE  '3' END ,    

		Age = 	case 
			when substring(A.birth,1,4) = substring(convert(varchar,getdate(),111),1,4) then '1' 
      			when substring(A.birth,1,4) between '1753' and '9999' then convert(varchar,datediff(year,substring(A.birth,1,4)+'0101',getdate())) 
			else ' ' 
			end,
	        AgeUnit = '岁', WardOrReg = (case when F.pzlx in ('10','11') and F.bjqkdm = 1 then 2 else @WardOrReg end),  
        	HospNo = A.blh,  ChargeType = A.ybdm ,CureNo = A.syxh, PatientId = B.patid, CardNo = A.cardno ,ApplyDept = A.ksdm ,    
            	Ward = A.bqdm , BedNo = A.cwdm,  ToDoc = A.ysdm, ClincDesc = A.zddm, IDNum = B.sfzh,   
	        Phone = B.lxdh, Address = B.lxdz, Zip = B.lxyb, Career = D.name, Nation = M.name       
    	    FROM  ZY_BRSYK A left join YY_YBFLK F on  A.ybdm = F.ybdm, ZY_BRXXK B left join YY_ZYDMK D on B.zybm = D.id left join YY_MZDMK M on B.mzbm = M.id 
        	WHERE A.syxh = convert(int, @IDInHosp)    
		         and  A.patid = B.patid         
	else  
	begin  
	    set rowcount 1  
	    select  PatName = b.hzxm , Sex = CASE b.sex WHEN '男' THEN '1' WHEN  '女' THEN  '2' ELSE  '3' END ,    

		Age = 	case 
			when substring(b.birth,1,4) = substring(convert(varchar,getdate(),111),1,4) then '1' 
      			when substring(b.birth,1,4) between '1753' and '9999' then convert(varchar,datediff(year,substring(b.birth,1,4)+'0101',getdate())) 
			else ' ' 
			end,
	      AgeUnit = '岁', WardOrReg = (case when F.pzlx in ('10','11') and F.bjqkdm = 1 then 2 else @WardOrReg end),  
              ChargeType = b.ybdm , HospNo = b.blh, Ward = space(1) , BedNo = space(1), IDNum = b.sfzh,   

			CureNo = (select top 1 ghxh from SF_BRJSK a where a.patid = b.patid and ghsfbz = 0 order by sfrq desc),
			PatientId = b.patid, CardNo = b.cardno ,      
	      ApplyDept = (select top 1 a.ksdm from SF_BRJSK a where a.patid=b.patid order by a.sfrq desc ),   
              Phone = b.lxdh, Address = b.lxdz, Zip = b.yzbm, Career = Space(1), Nation = Space(1)          
            from  SF_BRXXK b left join YY_YBFLK F on b.ybdm = F.ybdm
            WHERE b.patid = convert(int, @IDInHosp)   
	    set rowcount 0  
	end  
    return    
  END    
END



GO
/****** Object:  StoredProcedure [dbo].[procWhoLock]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE procedure [dbo].[procWhoLock]    
as      
begin      
   declare @spid int      
   declare @blk int      
   declare @count int      
   declare @index int      
   declare @lock tinyint       
   set @lock=0       
   create table #temp_who_lock       
 (       
  id int identity(1,1),       
  spid int,       
  blk int      
 )       
 if @@error<>0 return @@error       
 insert into #temp_who_lock(spid,blk)       
 select 0 ,blocked        
 from (select * from master..sysprocesses where blocked>0)a       
 where not exists(select * from  master..sysprocesses where a.blocked =spid and blocked>0)       
 union select spid,blocked from  master..sysprocesses where blocked>0       
 if @@error<>0 return @@error       
 select @count=count(*),@index=1 from #temp_who_lock       
 if @@error<>0 return @@error       
 if @count=0       
 begin      
  select '没有阻塞和死锁信息'      
  return 0       
 end      
 while @index<=@count       
 begin      
  if exists(select 1 from #temp_who_lock a where id>@index and exists(select 1 from #temp_who_lock where id<=@index and a.blk=spid))       
  begin      
   set @lock=1       
   select @spid=spid,@blk=blk from #temp_who_lock where id=@index      
   select '引起数据库死锁的是: '+ CAST(@spid AS VARCHAR(10)) + '进程号,其执行的SQL语法如下'      
   select  @spid, @blk     
   dbcc inputbuffer(@spid)       
   dbcc inputbuffer(@blk)       
  end      
  set @index=@index+1       
 end      
 if @lock=0        
 begin      
  set @index=1       
  while @index<=@count       
  begin      
   select @spid=spid,@blk=blk from #temp_who_lock where id=@index      
   if @spid=0       
    select '引起阻塞的是:'+cast(@blk as varchar(10))+ '进程号,其执行的SQL语法如下'      
   else       
    select '进程号SPID：'+ CAST(@spid AS VARCHAR(10))+ '被' + '进程号SPID：'+ CAST(@blk AS VARCHAR(10)) +'阻塞,其当前进程执行的SQL语法如下'      
   dbcc inputbuffer(@spid)     
   dbcc inputbuffer(@blk)       
   set @index=@index+1       
  end      
 end      
 drop table #temp_who_lock       
 return 0       
end            
  
  



GO
/****** Object:  UserDefinedFunction [dbo].[fnGetAllModalityTypes]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create FUNCTION [dbo].[fnGetAllModalityTypes] ()

RETURNS NVARCHAR(MAX) AS BEGIN

        DECLARE @result NVARCHAR(MAX)
		set @result =''
		select @result+= ModalityType+',' from
			(select distinct ModalityType from tbModalityType) as t
		if Len(@result) > 0
		set @result =Left(@result,len(@result)-1)
		
RETURN @result ;

END 



GO
/****** Object:  UserDefinedFunction [dbo].[fnGetChargeStatus]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create FUNCTION [dbo].[fnGetChargeStatus] ( @orderGuid nvarchar(128))

RETURNS VARCHAR(8000) AS BEGIN

        DECLARE @result VARCHAR(8000)
		set @result =''		
		select @result += text +',' from  (select distinct tbDictionaryValue.text from tbOrderCharge,tbDictionaryValue 
		where tbDictionaryValue.value = tbOrderCharge.LastStatus and tbDictionaryValue.Tag =87 and OrderGuid =@orderGuid and LastStatus not in(0,10,20,30)) as t
		if Len(@result)<> 0
		set @result =Left(@result,len(@result)-1)	
		
RETURN @result ;

END 


GO
/****** Object:  UserDefinedFunction [dbo].[fnGetColumnIndexes]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

    create function [dbo].[fnGetColumnIndexes](@TableName NVARCHAR(128), @ColumnName NVARCHAR(128))
    	returns @ret table
    	(
    		id int,
    		name NVARCHAR(128)
    	)
    as
    begin
    	declare @tid int, @colid int

    	-- 先查询出表id和列id
    	select @tid=OBJECT_ID(@tablename)
    	select @colid=colid from sys.syscolumns where id=@tid and name=@columnname

    	-- 查询出索引名称
    	insert into @ret select ROW_NUMBER() OVER(ORDER BY cols.index_id) as id, inds.name idxname from sys.index_columns cols
    		left join sys.indexes inds on cols.object_id=inds.object_id and cols.index_id=inds.index_id 
    		where cols.object_id=@tid and column_id=@colid
    		
    	return
    end



GO
/****** Object:  UserDefinedFunction [dbo].[fnGetDescriptions]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [dbo].[fnGetDescriptions] ( @orderGuid nvarchar(128))

RETURNS VARCHAR(8000) AS BEGIN

        DECLARE @result VARCHAR(8000)
		set @result =''
		select @result+=pc.description+',' from tbRegProcedure rp,tbProcedureCode pc 
		where rp.OrderGuid =@orderGuid and rp.ProcedureCode =pc.ProcedureCode				
		if Len(@result)<> 0
		set @result =Left(@result,len(@result)-1)
		
RETURN @result ;

END 


GO
/****** Object:  UserDefinedFunction [dbo].[fnGetDictionaryValues]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create FUNCTION [dbo].[fnGetDictionaryValues] (@tag int)

RETURNS NVARCHAR(MAX) AS BEGIN

        DECLARE @result NVARCHAR(MAX)
		set @result =''
		select @result+= Value+',' from
			(select distinct Value from tbDictionaryValue where TAG=@tag) as t
		if Len(@result) > 0
		set @result =Left(@result,len(@result)-1)
		
RETURN @result ;

END 



GO
/****** Object:  UserDefinedFunction [dbo].[fnGetFirstPinYins]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnGetFirstPinYins](@a varchar(1000)='')
returns varchar(1000)
as
begin
declare @b varchar(40),@i int,@c varchar(10)
declare @d varchar(10),@e varchar(10),@pinyin nvarchar(2000)
set @i=1
set @pinyin=''
while @i<=len(@a)
	begin
	set @c=substring(@a,@i,1)
	set @e=cast(@c as varbinary)
	begin
	set @pinyin = @pinyin +	case 
	when  @c  >=  '帀'  then  'Z'
		 when  @c  >=  '丫'  then  'Y' 
			 when  @c  >=  '夕'  then  'X'
				  when  @c  >=  '屲'  then  'W' 
					  when  @c  >=  '他'  then  'T' 
						  when  @c  >=  '仨'  then  'S' 
							  when  @c  >=  '呥'  then  'R' 
								  when  @c  >=  '七'  then  'Q'  
									 when  @c  >=  '妑'  then  'P'  
										when  @c  >=  '噢'  then  'O'   
										  when  @c  >=  '拏'  then  'N'   
											when  @c  >=  '嘸'  then  'M'  
											   when  @c  >=  '垃'  then  'L'  
												  when  @c  >=  '咔'  then  'K'  
													 when  @c  >=  '丌'  then    'J' 
														 when  @c  >=  '铪'  then  'H' 
															 when  @c  >=  '旮'  then  'G'
																  when  @c  >=  '发'  then  'F' 
																	  when  @c  >=  '妸'  then  'E'  
																		 when  @c  >=  '咑'  then  'D'
																			  when  @c  >=  '嚓'  then  'C' 
																				  when  @c  >=  '八'  then  'B'
																					   when  @c  >=  '吖'  then  'A' 
																					   else  rtrim(ltrim(@c))
																					   end
																					   set @i=@i+1
	   end                                                                                    
end
return @pinyin
end


GO
/****** Object:  UserDefinedFunction [dbo].[fnGetModalityTypes]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [dbo].[fnGetModalityTypes] ( @orderGuid nvarchar(128))

RETURNS VARCHAR(8000) AS BEGIN

        DECLARE @result VARCHAR(8000)
		set @result =''
		select @result+= ModalityType+',' from
			(select distinct ModalityType from tbRegProcedure where OrderGuid =@orderGuid) as t
		if Len(@result)<> 0
		set @result =Left(@result,len(@result)-1)
		
RETURN @result ;

END 


GO
/****** Object:  UserDefinedFunction [dbo].[fnGetMonth]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnGetMonth](
@dtBegin datetime,  --计算的开始时间
@dtEnd   datetime     --计算的结束时间
)RETURNS int
AS
BEGIN
	declare @nMonth int
	declare @nBeginYear int
	declare @nBeginMonth int
	declare @nBeginDay int
	declare @nEndYear int
	declare @nEndMonth int
	declare @nEndDay int
	declare @nMonthDiff int
	
	select @nBeginYear=datepart(yy,@dtBegin)
	select @nBeginMonth=datepart(mm,@dtBegin)
	select @nBeginDay=datepart(dd,@dtBegin)
	select @nEndYear=datepart(yy,@dtEnd)
	select @nEndMonth=datepart(mm,@dtEnd)
	select @nEndDay=datepart(dd,@dtEnd)
	set @nMonth=(@nEndYear-@nBeginYear)*12
	set @nMonthDiff=@nEndMonth-@nBeginMonth
	set @nMonth=@nMonth+@nMonthDiff
	
	
	if(@nEndDay<@nBeginDay)
	begin
		set @nMonth=@nMonth-1
	end
	
	if(@nMonth<0)
		set @nMonth=0



	RETURN(@nMonth)
END




GO
/****** Object:  UserDefinedFunction [dbo].[fnGetprofilevalue]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnGetprofilevalue]
 (
  @name nvarchar(128),
  @site nvarchar(128)
 )RETURNS nvarchar(128)
AS
BEGIN
declare @value nvarchar(128)

if not exists(select 1 from tbSiteProfile with(nolock) where Name = @name and Site = @site)
begin
select @value = value from tbSystemProfile with(nolock) where Name = @name;
end
else
begin
select @value = value from tbSiteProfile with(nolock) where Name = @name and Site = @site;
end
return ISNULL(@value,'');
END  


GO
/****** Object:  UserDefinedFunction [dbo].[fnGetRPDescriptions]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create FUNCTION [dbo].[fnGetRPDescriptions] ( @orderGuid nvarchar(128))

RETURNS NVARCHAR(MAX) AS BEGIN

        DECLARE @result NVARCHAR(MAX)
		set @result =''
		select @result+=RPDesc+',' from tbRegProcedure
		where OrderGuid =@orderGuid			
		if Len(@result)<> 0
		set @result =Left(@result,len(@result)-1)
		
RETURN @result ;

END 



GO
/****** Object:  UserDefinedFunction [dbo].[fnGetYear]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnGetYear](
@dtBegin datetime,  --计算的开始时间
@dtEnd   datetime     --计算的结束时间
)RETURNS int
AS
BEGIN
	declare @nYear int
	declare @nBeginYear int
	declare @nBeginMonth int
	declare @nBeginDay int
	declare @nEndYear int
	declare @nEndMonth int
	declare @nEndDay int
	
	select @nBeginYear=datepart(yy,@dtBegin)
	select @nBeginMonth=datepart(mm,@dtBegin)
	select @nBeginDay=datepart(dd,@dtBegin)
	select @nEndYear=datepart(yy,@dtEnd)
	select @nEndMonth=datepart(mm,@dtEnd)
	select @nEndDay=datepart(dd,@dtEnd)
	set @nYear=@nEndYear-@nBeginYear
	
	if(@nEndMonth<@nBeginMonth)
	begin
		set @nYear=@nYear-1
	end
	else if(@nEndMonth=@nBeginMonth)	
	begin
		if(@nEndDay<@nBeginDay)
		begin
			set @nYear=@nYear-1
		end
	end
	if(@nYear<0)
		set @nYear=0



	RETURN(@nYear)
END



GO
/****** Object:  UserDefinedFunction [dbo].[fnIsColumnExists]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

    create function [dbo].[fnIsColumnExists](@TableName NVARCHAR(128), @ColumnName NVARCHAR(128))
    	returns bit
    as
    begin
    	declare @rt bit
    	set @rt=0
    	if (select name from sys.syscolumns where name=@ColumnName and id=OBJECT_ID(@TableName)) is not null
    		set @rt=1
    	return @rt
    end



GO
/****** Object:  UserDefinedFunction [dbo].[fnStrSplit]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--字符分割函数
CREATE FUNCTION [dbo].[fnStrSplit] 
  (@origStr varchar(max),   --待拆分的字符串
   @markStr varchar(100))    --拆分标记，如','
  RETURNS @splittable table
  (
  str_id    varchar(4000) NOT NULL, --编号ID
  string    varchar(2000) NOT NULL --拆分后的字符串
  )
  AS 
 BEGIN
 declare @strlen int,@postion int,@start int,@sublen int,@TEMPstr varchar(200),@TEMPid int
 SELECT @strlen=LEN(@origStr),@start=1,@sublen=0,@postion=1,@TEMPstr='',@TEMPid=0
 
 if(RIGHT(@origStr,1)<>@markStr )
 begin
    set @origStr = @origStr + @markStr
 end
 WHILE((@postion<=@strlen) and (@postion !=0))
 BEGIN
    IF(CHARINDEX(@markStr,@origStr,@postion)!=0)
    BEGIN
     SET @sublen=CHARINDEX(@markStr,@origStr,@postion)-@postion; 
    END
    ELSE
    BEGIN
     SET @sublen=@strlen-@postion+1;
 
    END
    IF(@postion<=@strlen)
    BEGIN
     SET @TEMPid=@TEMPid+1;
     SET @TEMPstr=SUBSTRING(@origStr,@postion,@sublen);
     INSERT INTO @splittable(str_id,string) values(@TEMPid,@TEMPstr)
     IF(CHARINDEX(@markStr,@origStr,@postion)!=0)
     BEGIN
      SET @postion=CHARINDEX(@markStr,@origStr,@postion)+1
    END
     ELSE
     BEGIN
      SET @postion=@postion+1
     END
    END
 END
 RETURN
 END



GO
/****** Object:  UserDefinedFunction [dbo].[fnTimePartDiff]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnTimePartDiff](
@dateTime1 datetime,  --@dateTime2 - @dateTime1
@dateTime2  datetime     
)RETURNS int--(the difference of (hours*60 + minutes), unit is minutes)
AS
BEGIN
	declare @nDiffer int

    set @nDiffer = (DatePart(Hour,@dateTime2)*60 + DatePart(Minute,@dateTime2))-
    (DatePart(Hour,@dateTime1)*60 + DatePart(Minute,@dateTime1))

	RETURN(@nDiffer)
END


GO
/****** Object:  UserDefinedFunction [dbo].[fnTranslateCurrentAge]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnTranslateCurrentAge] (@src nvarchar(256))
RETURNS nvarchar(256)
WITH EXECUTE AS CALLER
AS
BEGIN
 RETURN replace(replace(replace(replace(replace(replace(@src, 'Hour', '小时'), 'Day', '天'), 'Week', '周'), 'Month', '月'), 'Year', '岁'), ' ', '')
END;


GO
/****** Object:  UserDefinedFunction [dbo].[fnTranslateDictionaryValue]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnTranslateDictionaryValue] (@tag int, @src nvarchar(256))
RETURNS nvarchar(256)
WITH EXECUTE AS CALLER
AS
BEGIN
     DECLARE @ret nvarchar(256);
     select top 1 @ret = Text from tbDictionaryValue where TAG=@tag AND Value=@src
     RETURN(@ret);
END;


GO
/****** Object:  UserDefinedFunction [dbo].[fnTranslateIntern]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create FUNCTION [dbo].[fnTranslateIntern] (@InternName nvarchar(32),@userGuid nvarchar(256))
RETURNS nvarchar(256)
WITH EXECUTE AS CALLER
AS
BEGIN
     DECLARE @ret nvarchar(256);
	 if(@InternName <>'')
	 begin
		 select top 1 @ret = LocalName from tbUser where UserGuid=@userGuid
		 set @ret = @ret + '(' + @InternName + ')'
	 end
	 else 
	 begin
		set @ret=@InternName 
	 end
	 RETURN(@ret);
END;


GO
/****** Object:  UserDefinedFunction [dbo].[fnTranslateSite]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnTranslateSite] (@site nvarchar(256))
RETURNS nvarchar(256)
WITH EXECUTE AS CALLER
AS
BEGIN
     DECLARE @alias nvarchar(256);
     select top 1 @alias = alias from tbSiteList where Site=@site
     RETURN(@alias);
END;


GO
/****** Object:  UserDefinedFunction [dbo].[fnTranslateUser]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnTranslateUser] (@userGuid nvarchar(256))
RETURNS nvarchar(256)
WITH EXECUTE AS CALLER
AS
BEGIN
     DECLARE @ret nvarchar(256);
     select top 1 @ret = LocalName from tbUser where UserGuid=@userGuid
     RETURN(@ret);
END;


GO
/****** Object:  UserDefinedFunction [dbo].[fnTranslateYesNo]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnTranslateYesNo] (@yesno int)
RETURNS nvarchar(16)
WITH EXECUTE AS CALLER
AS
BEGIN
 if(@yesno >= 1)
     RETURN '是';

RETURN '否'
END;


GO
/****** Object:  UserDefinedFunction [dbo].[fnTranslateYesNoEmpty]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnTranslateYesNoEmpty] (@value int)
RETURNS nvarchar(16)
WITH EXECUTE AS CALLER
AS
BEGIN
 if(@value = 1)
     RETURN '是';
 else if(@value = 0)
     RETURN '否';

RETURN ''
END;


GO
/****** Object:  Table [dbo].[tbAccessionNumberList]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbAccessionNumberList](
	[ANLGuid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[AccNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[OrderGuid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[PatientGuid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[HisID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDt] [datetime] NULL,
 CONSTRAINT [PK_tAccessionNumberList] PRIMARY KEY CLUSTERED 
(
	[ANLGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbACRCodeAnatomical]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbACRCodeAnatomical](
	[AID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Description] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[DescriptionEn] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UniqueID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK__tACRCodeAnatomic] PRIMARY KEY NONCLUSTERED 
(
	[UniqueID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbAcrCodePathological]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbAcrCodePathological](
	[AID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Description] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[DescriptionEn] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UniqueID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK__tACRCodePatholog] PRIMARY KEY NONCLUSTERED 
(
	[UniqueID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbAcrCodeSubAnatomical]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbAcrCodeSubAnatomical](
	[AID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[SID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Description] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[DescriptionEn] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[IsUserAdd] [int] NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UniqueID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_ACRCodeSubAnatomical] PRIMARY KEY NONCLUSTERED 
(
	[UniqueID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbAcrCodeSubPathological]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbAcrCodeSubPathological](
	[AID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[SID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Description] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[DescriptionEn] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[IsUserAdd] [int] NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UniqueID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_ACRCodeSubPathological] PRIMARY KEY CLUSTERED 
(
	[UniqueID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbActivityLog]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbActivityLog](
	[ALGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[EventID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[EventActionCode] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[EventDt] [datetime] NULL,
	[EventOutComeIndicator] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[EventTypeCode] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[UserGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[UserName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[UserIsRequestor] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[RoleName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PartObjectTypeCode] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PartObjectTypeCodeRole] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PartObjectIDTypeCode] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PartObjectID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PartObjectName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PartObjectDetail] [nvarchar](1024) COLLATE Chinese_PRC_CI_AS NULL,
	[Comments] [nvarchar](1024) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbAllergy]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbAllergy](
	[UID] [uniqueidentifier] NOT NULL,
	[PatientGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ContrastAgent] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Treatment] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[TreatmentResult] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Creator] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDt] [datetime] NULL,
 CONSTRAINT [PK_tAllergy] PRIMARY KEY CLUSTERED 
(
	[UID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbApplyDept]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbApplyDept](
	[ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ApplyDept] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Telephone] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional1] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional2] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional3] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[ShortCutCode] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_tApplyDept] PRIMARY KEY CLUSTERED 
(
	[ID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbApplyDoctor]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbApplyDoctor](
	[ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ApplyDeptID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ApplyDoctor] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Gender] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Mobile] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Telephone] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[StaffID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[EMail] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional1] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional2] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional3] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ShortCutCode] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_tApplyDoctor] PRIMARY KEY CLUSTERED 
(
	[ID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbArchiveErrorLog]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbArchiveErrorLog](
	[KeyID] [int] IDENTITY(1,1) NOT NULL,
	[PatientGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[SQLSentence] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDt] [datetime] NULL,
 CONSTRAINT [pk_ tbArchiveErrorLog] PRIMARY KEY CLUSTERED 
(
	[KeyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbArchiveEvent]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbArchiveEvent](
	[AEGuid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Type] [int] NULL,
	[ObjectGuid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[CreateDt] [datetime] NULL,
 CONSTRAINT [pk_tArchiveCmd] PRIMARY KEY NONCLUSTERED 
(
	[AEGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbAssignmentLog]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbAssignmentLog](
	[OperationType] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[Assigner] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Assignee] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[AccNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PatientName] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[PatientID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ModalityType] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[ExamSystem] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[PatientType] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[ProcedureCode] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[OperationDate] [datetime] NULL,
	[ReportType] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[Operator] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Weight] [int] NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ProcedureGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbBadImageNotifIp]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbBadImageNotifIp](
	[ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ModalityType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[NotifyIP] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_tBadImageNotifIP] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbBaseList]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbBaseList](
	[ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ViewName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[CountViewName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ViewNameWithArchive] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[CountViewNameWithArchive] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[IsView] [int] NULL,
	[Paging] [int] NULL,
	[PageSize] [int] NULL,
	[OrderBy] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[AdditionalCondition] [nvarchar](1024) COLLATE Chinese_PRC_CI_AS NULL,
	[CalculatePageCount] [int] NULL,
	[GridAutoRefresh] [int] NULL,
	[GridMultipleSelection] [int] NULL,
	[Desc] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[ModuleID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[RequiredFields] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_tBaseList] PRIMARY KEY CLUSTERED 
(
	[ID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbBillBoard]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbBillBoard](
	[Guid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Title] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[GroupId] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Type] [int] NULL,
	[BeginDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Intervals] [float] NULL,
	[ShowTime] [float] NULL,
	[AttachmentURL] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Body] [varbinary](max) NULL,
	[Creator] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDate] [datetime] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[GroupType] [int] NULL,
 CONSTRAINT [PK_tbillboard] PRIMARY KEY NONCLUSTERED 
(
	[Guid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbBillBoardOperation]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbBillBoardOperation](
	[Guid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Submitter] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[SubmitDate] [datetime] NULL,
	[SubmitTo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Approver] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ApproveDate] [datetime] NULL,
	[Rejector] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[RejectDate] [datetime] NULL,
	[RejectCause] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[State] [int] NULL,
	[OperationHistory] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Counts] [int] NULL,
	[Publisher] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PublishDate] [datetime] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [pk_Billboardoperation] PRIMARY KEY CLUSTERED 
(
	[Guid] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbBodyPartList]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbBodyPartList](
	[BodyPartNo] [int] NOT NULL,
	[BodyPartName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[LocalName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_tBodyPartList] PRIMARY KEY NONCLUSTERED 
(
	[BodyPartNo] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbBodySystemMap]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbBodySystemMap](
	[ModalityType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Bodypart] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ExamSystem] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UniqueID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [pk_Bodysystemmap] PRIMARY KEY NONCLUSTERED 
(
	[UniqueID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbBookingNoticeTemplate]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbBookingNoticeTemplate](
	[Guid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ModalityType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[TemplateName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[BookingNotice] [varbinary](max) NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_tBookingNoticeTemplate] PRIMARY KEY NONCLUSTERED 
(
	[Guid] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbBookingPool]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbBookingPool](
	[BookingPoolID] [uniqueidentifier] NOT NULL,
	[PatientID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[PatientName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Gender] [nvarchar](8) COLLATE Chinese_PRC_CI_AS NULL,
	[Birthday] [date] NULL,
	[AccNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[RemoteAccNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[IdentityNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[MedicalNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[SocialSecurityNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[HisID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[RemotePID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Modality] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Facility] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ProcedureCode] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[CheckingItem] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ScheduledStartTime] [datetime] NOT NULL,
	[ScheduledEndTime] [datetime] NULL,
 CONSTRAINT [PK_BookingPool] PRIMARY KEY CLUSTERED 
(
	[BookingPoolID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbBookingTimeSync]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbBookingTimeSync](
	[RPGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ModalityType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Modality] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[BeginDt] [datetime] NULL,
	[EndDt] [datetime] NULL,
	[Status] [int] NULL,
	[Owner] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[IsOrg] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbCharge]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbCharge](
	[ChargeGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ProcedureCode] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ChargeType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Charge] [decimal](10, 2) NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK__tCharge] PRIMARY KEY NONCLUSTERED 
(
	[ChargeGuid] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbChargeItem]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbChargeItem](
	[Code] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Description] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Type] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Unit] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Price] [decimal](10, 2) NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ShortcutCode] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbClientConfig]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbClientConfig](
	[UniqueID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ScanQualityLevel] [int] NOT NULL,
	[StationName] [nvarchar](200) COLLATE Chinese_PRC_CI_AS NULL,
	[Location] [nvarchar](200) COLLATE Chinese_PRC_CI_AS NULL,
	[DefaultPrinter] [nvarchar](500) COLLATE Chinese_PRC_CI_AS NULL,
	[BarcodePrinter] [nvarchar](500) COLLATE Chinese_PRC_CI_AS NULL,
	[NoticePrinter] [nvarchar](500) COLLATE Chinese_PRC_CI_AS NULL,
	[DisabledModalities] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[DisabledModalityTypes] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[AutoPrintBarcode] [bit] NOT NULL,
	[AutoPrintNotice] [bit] NOT NULL,
	[IntegrationType] [int] NOT NULL,
	[AppointmentDisabledModalities] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[AppointmentDisabledModalityTypes] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[AppointmentAutoPrintBarcode] [bit] NULL,
	[AppointmentAutoPrintNotice] [bit] NULL,
 CONSTRAINT [PK_dbo.tbClientConfig] PRIMARY KEY CLUSTERED 
(
	[UniqueID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbClientProfile]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbClientProfile](
	[ClientProfileGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ModuleID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ConfigName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ClientID] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Value] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_tClientProfile] PRIMARY KEY CLUSTERED 
(
	[ClientProfileGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbConditionColumn]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbConditionColumn](
	[ConditionName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ItemID] [int] NOT NULL,
	[TableName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ColumnName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Type] [int] NULL,
	[ComparisonOperator] [int] NULL,
	[OrderID] [int] NULL,
	[ShortCutRequired] [int] NULL,
	[Label] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Expression] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[DataType] [int] NULL,
	[DataSource] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[IsHidden] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[OrderIDQuick] [int] NULL,
	[IsHiddenQuick] [int] NULL,
	[Group] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK__tConditition] PRIMARY KEY CLUSTERED 
(
	[ConditionName] ASC,
	[ItemID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbConfigDic]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbConfigDic](
	[ConfigName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ModuleID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Value] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Exportable] [int] NOT NULL,
	[PropertyDesc] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[PropertyOptions] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Inheritance] [int] NOT NULL,
	[PropertyType] [int] NOT NULL,
	[IsHidden] [int] NOT NULL,
	[OrderingPos] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Type] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ShowInWeb] [int] NOT NULL,
 CONSTRAINT [PK__tConfigDic] PRIMARY KEY NONCLUSTERED 
(
	[ConfigName] ASC,
	[ModuleID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbConsultation]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbConsultation](
	[cstGuid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[cstUserGuid] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[cstSite] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[cstOrderGuid] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[cstStatus] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[cstConsultHospital] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[cstType] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[cstApplyTime] [datetime] NULL,
	[cstStartTime] [datetime] NULL,
	[cstEndTime] [datetime] NULL,
	[cstExpert] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[cstRequestUserId] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[cstDiagnosisRequestId] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[cstImpression] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[cstInterpretation] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[cstKeywords] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[cstIsPositive] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[cstReportComment] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_tConsultation] PRIMARY KEY CLUSTERED 
(
	[cstGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbDicFormStructure]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbDicFormStructure](
	[FSGUID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[FSCONTROLTYPE] [int] NOT NULL,
	[FSTABLENAME] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FSCOLUMNNAME] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FSALLOWMULTIPLEROWS] [int] NULL,
	[FSDATAFILTER] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[FSNEEDSAVE] [int] NULL,
	[FSSAVETYPE] [int] NULL,
	[FSNAME] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FSLABEL] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[FSVISIBILITY] [int] NULL,
	[FSSHOWREPEATER] [int] NULL,
	[FSORDER] [int] NULL,
	[FSPARENTGUID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FSPARENTVALUE] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FSEXPRESSION] [nvarchar](1024) COLLATE Chinese_PRC_CI_AS NULL,
	[FSDATASOURCETYPE] [int] NULL,
	[FSDATASOURCE] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[FSPROPERTIES] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[FSNOTSAVEASSHORTCUT] [int] NULL,
	[FSVALUE] [nvarchar](1024) COLLATE Chinese_PRC_CI_AS NULL,
	[FSALLOWNULL] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbDicFormType]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbDicFormType](
	[FTGUID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[FTTYPE] [int] NOT NULL,
	[FTNAME] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[FSGUID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbDictionary]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbDictionary](
	[Tag] [int] NOT NULL,
	[Name] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[IsHidden] [int] NULL,
	[Description] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Length] [int] NOT NULL,
	[ValueRange] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[IsExport] [int] NULL,
	[DescLength] [int] NULL,
	[PropertyOptions] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK__tDictionary] PRIMARY KEY NONCLUSTERED 
(
	[Tag] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbDictionaryValue]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbDictionaryValue](
	[Tag] [int] NOT NULL,
	[Value] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Text] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[IsDefault] [int] NULL,
	[ShortcutCode] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[OrderID] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UniqueID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[mapTag] [int] NULL,
	[MapValue] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [pk_Dictionaryvalue] PRIMARY KEY CLUSTERED 
(
	[UniqueID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbDischargedSummary]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbDischargedSummary](
	[SummaryID] [uniqueidentifier] NOT NULL,
	[PatientID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Summary] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[GenerateDt] [datetime] NULL,
 CONSTRAINT [PK_TDISCHARGESUMMARY] PRIMARY KEY CLUSTERED 
(
	[SummaryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbDomainList]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbDomainList](
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[DomainPrefix] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Connstring] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[FtpServer] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[FtpPort] [int] NULL,
	[FtpUser] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[FtpPassword] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[PacsAETitle] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Telephone] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Address] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[PacsServer] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PacsWebServer] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Tab] [int] NOT NULL,
	[Alias] [nvarchar](16) COLLATE Chinese_PRC_CI_AS NULL,
	[IISUrl] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK__tDomainList] PRIMARY KEY CLUSTERED 
(
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbEmergencyTemplate]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbEmergencyTemplate](
	[TemplateGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[TemplateName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[NamePrefix] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Birthday] [datetime] NULL,
	[Gender] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Telephone] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[InhospitalNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ClinicNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[BedNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PatientType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ApplyDept] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ApplyDoctor] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ProcedureCode] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Description] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[TemplateType] [int] NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_tEmergencyTemplate] PRIMARY KEY NONCLUSTERED 
(
	[TemplateGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbEmployeePlan]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbEmployeePlan](
	[PlanGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UserGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[StartDt] [datetime] NULL,
	[EndDt] [datetime] NULL,
	[TemplateName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[TemplateMark] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_tEmployeePlan] PRIMARY KEY NONCLUSTERED 
(
	[PlanGuid] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbERequisition]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbERequisition](
	[Guid] [varchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ERNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PatientID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PatientName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[InHospitalNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ClinicNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[BedNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ModalityType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ApplyDoctor] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ApplyDept] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[WorkedDate] [datetime] NULL,
	[Status] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[IsBooking] [nvarchar](8) COLLATE Chinese_PRC_CI_AS NULL,
	[ApplyDate] [datetime] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReferralID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PatientType] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[IsCharge] [int] NULL,
	[EAcquisition] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[InhospitalRegion] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[RejectReason] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[ExamAppInfo] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[ExecuteDepartment] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK__tERequisition] PRIMARY KEY NONCLUSTERED 
(
	[Guid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbErrorTable]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbErrorTable](
	[errormessage] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDt] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbEventLog]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbEventLog](
	[Guid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[EventCode] [int] NOT NULL,
	[ModalityType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Modality] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CostTime] [int] NULL,
	[CreateDt] [datetime] NULL,
	[Operator] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReportGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [pk_EventLog] PRIMARY KEY NONCLUSTERED 
(
	[Guid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbExamineTemplate]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbExamineTemplate](
	[TemplateGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ModalityType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[TemplateName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[TemplateInfo] [nvarchar](1024) COLLATE Chinese_PRC_CI_AS NULL,
	[ShortcutCode] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Type] [int] NOT NULL,
	[UserGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_tExamineTemplate] PRIMARY KEY NONCLUSTERED 
(
	[TemplateGuid] ASC,
	[Domain] ASC,
	[Site] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbExamName]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbExamName](
	[ExamNameGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ExamName] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[ParentExamNameGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Site] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbExclusionCondition]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbExclusionCondition](
	[ConditionName] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[ExclusionConditionSql] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[IsDefault] [int] NULL,
	[Alias] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbExportTemplate]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbExportTemplate](
	[TemplateGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Type] [int] NOT NULL,
	[ChildType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[TemplateName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[TemplateInfo] [varbinary](max) NULL,
	[Descriptions] [nvarchar](1024) COLLATE Chinese_PRC_CI_AS NULL,
	[IsDefaultByType] [int] NULL,
	[IsDefaultByChildType] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK__tExportTemplate] PRIMARY KEY CLUSTERED 
(
	[TemplateGuid] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbFilmLoan]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbFilmLoan](
	[LoanGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PatientID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[LocalName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[AccNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ExamineDt] [datetime] NULL,
	[Loanee] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[LoanQuantity] [int] NULL,
	[LoanDt] [datetime] NULL,
	[ReturnQuantity] [int] NULL,
	[ReturnDt] [datetime] NULL,
	[Remaining] [int] NULL,
	[Comment] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Operator] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[OperateDt] [datetime] NULL,
	[Telephone] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ClinicCode] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Zone] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Organization] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_tFilmLoan] PRIMARY KEY CLUSTERED 
(
	[LoanGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbFilmPrintLog]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbFilmPrintLog](
	[Guid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[AccNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[SeriesID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PrintTimes] [int] NULL,
	[Operator] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[OperateDt] [datetime] NULL,
	[hFilmSize] [nvarchar](16) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_tFilmPrintLog] PRIMARY KEY NONCLUSTERED 
(
	[Guid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbFilmReserved]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbFilmReserved](
	[ReservedID] [uniqueidentifier] NOT NULL,
	[FilmSpec] [nvarchar](16) COLLATE Chinese_PRC_CI_AS NULL,
	[ReservedCount] [int] NULL,
	[OperateDt] [datetime] NULL,
 CONSTRAINT [PK_tFilmResverved] PRIMARY KEY CLUSTERED 
(
	[ReservedID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbFilmScoring]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbFilmScoring](
	[AccNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[SeriesID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[CommandType] [int] NULL,
	[eFilmSize] [nvarchar](16) COLLATE Chinese_PRC_CI_AS NULL,
	[hFilmsCount] [int] NULL,
	[Grade] [int] NULL,
	[QAName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[QADt] [datetime] NULL,
	[Generater] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[GenerateDt] [datetime] NULL,
	[ModalityType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[StudyDt] [datetime] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_tFilmScoring] PRIMARY KEY NONCLUSTERED 
(
	[AccNo] ASC,
	[SeriesID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbFilmStore]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbFilmStore](
	[FilmID] [uniqueidentifier] NOT NULL,
	[FilmSpec] [nvarchar](16) COLLATE Chinese_PRC_CI_AS NULL,
	[FilmCount] [int] NULL,
	[Supplier] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Manufacturer] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Mfd] [date] NULL,
	[Exp] [date] NULL,
	[LotNumber] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[OperatorID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[OperatorName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDt] [datetime] NULL,
 CONSTRAINT [PK_tFilmStore] PRIMARY KEY CLUSTERED 
(
	[FilmID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbGridColumn]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbGridColumn](
	[Guid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ColumnWidth] [int] NULL,
	[OrderID] [int] NULL,
	[UserGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Sorting] [int] NULL,
	[IsHidden] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_GridColumn] PRIMARY KEY NONCLUSTERED 
(
	[Guid] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbGridColumnOption]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbGridColumnOption](
	[Guid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ListName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ColumnID] [int] NULL,
	[TableName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ColumnName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ColumnWidth] [int] NULL,
	[OrderID] [int] NULL,
	[Expression] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Sorting] [int] NULL,
	[IsHidden] [int] NULL,
	[ModuleID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[isImageColumn] [int] NULL,
	[ImagePath] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [pk_tGridColumnOption] PRIMARY KEY NONCLUSTERED 
(
	[Guid] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbGwDataIndex]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbGwDataIndex](
	[DATA_ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[DATA_DT] [datetime] NOT NULL,
	[EVENT_TYPE] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[RECORD_INDEX_1] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[RECORD_INDEX_2] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[RECORD_INDEX_3] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[RECORD_INDEX_4] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[DATA_SOURCE] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PROCESS_FLAG] [nvarchar](8) COLLATE Chinese_PRC_CI_AS NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbGwOrder]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbGwOrder](
	[DATA_ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[DATA_DT] [datetime] NOT NULL,
	[ORDER_NO] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PLACER_NO] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FILLER_NO] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[SERIES_NO] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PATIENT_ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[EXAM_STATUS] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PLACER_DEPARTMENT] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PLACER] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PLACER_CONTACT] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FILLER_DEPARTMENT] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FILLER] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FILLER_CONTACT] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[REF_ORGANIZATION] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[REF_PHYSICIAN] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[REF_CONTACT] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[REQUEST_REASON] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[REUQEST_COMMENTS] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[EXAM_REQUIREMENT] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[SCHEDULED_DT] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[MODALITY] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[STATION_NAME] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[STATION_AETITLE] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[EXAM_LOCATION] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[EXAM_VOLUME] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[EXAM_DT] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[DURATION] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[TRANSPORT_ARRANGE] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[TECHNICIAN] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[BODY_PART] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[PROCEDURE_NAME] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PROCEDURE_CODE] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PROCEDURE_DESC] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[STUDY_INSTANCE_UID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[STUDY_ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[REF_CLASS_UID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[EXAM_COMMENT] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CNT_AGENT] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CHARGE_STATUS] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CHARGE_AMOUNT] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CUSTOMER_1] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CUSTOMER_2] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CUSTOMER_3] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CUSTOMER_4] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbGwPatient]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbGwPatient](
	[DATA_ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[DATA_DT] [datetime] NOT NULL,
	[PATIENTID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PRIOR_PATIENT_ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[OTHER_PID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PATIENT_NAME] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[PATIENT_LOCAL_NAME] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[MOTHER_MAIDEN_NAME] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[BIRTHDATE] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[SEX] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PATIENT_ALIAS] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[RACE] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ADDRESS] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[COUNTRY_CODE] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PHONENUMBER_HOME] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PHONENUMBER_BUSINESS] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PRIMARY_LANGUAGE] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[MARITAL_STATUS] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[RELIGION] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ACCOUNT_NUMBER] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[SSN_NUMBER] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[DRIVERLIC_NUMBER] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ETHNIC_GROUP] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[BIRTH_PLACE] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CITIZENSHIP] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[VETERANS_MIL_STATUS] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[NATIONALITY] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PATIENT_TYPE] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PATIENT_LOCATION] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PATIENT_STATUS] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[VISIT_NUMBER] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[BED_NUMBER] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CUSTOMER_1] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CUSTOMER_2] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CUSTOMER_3] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CUSTOMER_4] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[PRIOR_PATIENT_NAME] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PRIOR_VISIT_NUMBER] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbGwReport]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbGwReport](
	[DATA_ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[DATA_DT] [datetime] NOT NULL,
	[REPORT_NO] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ACCESSION_NUMBER] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PATIENT_ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[REPORT_STATUS] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[MODALITY] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[REPORT_TYPE] [int] NOT NULL,
	[REPORT_FILE] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[DIAGNOSE] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[COMMENTS] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[REPORT_WRITER] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[REPORT_INTEPRETER] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[REPORT_APPROVER] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[REPORTDT] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[OBSERVATIONMETHOD] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CUSTOMER_1] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CUSTOMER_2] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CUSTOMER_3] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CUSTOMER_4] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbHippaEventType]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbHippaEventType](
	[EventID] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[EventTypeCode] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Priority] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[Category] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbHotKey]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbHotKey](
	[Guid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[FunctionName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[HotKey] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbIcd10]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbIcd10](
	[ID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[INAME] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[PY] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[WB] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[TJM] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[BZLB] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ZLBM] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[JLZT] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[MEMO] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UniqueID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_ICD10] PRIMARY KEY NONCLUSTERED 
(
	[UniqueID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbIdMaxValue]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbIdMaxValue](
	[Tag] [int] NOT NULL,
	[Value] [int] NULL,
	[CreateDt] [datetime] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ModalityType] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[LocationAccNoPrefix] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbIdRecycleBin]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbIdRecycleBin](
	[Tag] [int] NOT NULL,
	[Value] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_tIDRecycleBin] PRIMARY KEY CLUSTERED 
(
	[Tag] ASC,
	[Value] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbInspectionScoreSettings]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbInspectionScoreSettings](
	[VersionNo] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Type] [int] NOT NULL,
	[IsCurrent] [int] NOT NULL,
	[Settings] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_tInspectionScoreSettings] PRIMARY KEY CLUSTERED 
(
	[VersionNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbKeyPerformanceRating]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbKeyPerformanceRating](
	[ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Name] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[AccNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Appraisee] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[AppraiseeSequenceId] [int] NOT NULL,
	[Appraiser] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[AppraiserSequenceId] [int] NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[Score] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Comment] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[CreateDate] [datetime] NOT NULL,
 CONSTRAINT [PK_tKeyPerformanceRating] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbKnowledge]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbKnowledge](
	[KnowledgeGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ParentID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Path] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Name] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[IsLeaf] [int] NULL,
	[Creator] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDt] [datetime] NULL,
	[Comments] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[NodeOrder] [int] NOT NULL,
	[IsLink] [int] NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_tKnowledgeNode] PRIMARY KEY CLUSTERED 
(
	[KnowledgeGuid] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbKnowledgeFiles]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbKnowledgeFiles](
	[Guid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[KnowledgeGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FileName] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[NodeOrder] [int] NOT NULL,
	[IsLink] [int] NOT NULL,
	[LinkToGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[CreateDt] [datetime] NULL,
 CONSTRAINT [PK_tKnowledgeNodeInfo] PRIMARY KEY CLUSTERED 
(
	[Guid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbLeaveSound]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbLeaveSound](
	[SoundGuid] [nchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReportGuid] [nchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Path] [nchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Status] [int] NULL,
	[LeaveTime] [datetime] NULL,
	[Owner] [nchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_tLeaveSound] PRIMARY KEY CLUSTERED 
(
	[SoundGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbMedicineStore]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbMedicineStore](
	[MedicineCode] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[MedicineName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Counts] [int] NULL,
	[CreateDt] [datetime] NULL,
 CONSTRAINT [PK_tMedicineStore] PRIMARY KEY CLUSTERED 
(
	[MedicineCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbMedicineStoreLog]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbMedicineStoreLog](
	[MedicineGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[MedicineCode] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[MedicineName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Spec] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Batch] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Manufacturer] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ManufaturingDt] [date] NULL,
	[Signature] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Remark] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Counts] [int] NULL,
	[Type] [int] NULL,
	[PatientID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[OrderGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[OperatorID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[OperatorName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDt] [datetime] NULL,
 CONSTRAINT [PK_tMedicineStore_Log] PRIMARY KEY CLUSTERED 
(
	[MedicineGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbMessageConfig]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbMessageConfig](
	[Guid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[EventType] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Template] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[TemplateSP] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[MessageType] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReceiveType] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReceiveObject] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Site] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Enabled] [int] NOT NULL,
	[RetryTimes] [int] NOT NULL,
	[RetryTimeInterval] [int] NOT NULL,
	[EventRelativeTimeStart] [int] NULL,
	[EventRelativeTimeEnd] [int] NULL,
	[EventProcessRecurrencePattern] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[TemplateSample] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbModality]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbModality](
	[ModalityGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ModalityType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Modality] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Room] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[IPAddress] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[MaxLoad] [int] NOT NULL,
	[Description] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[BookingShowMode] [int] NOT NULL,
	[StartDt] [datetime] NULL,
	[EndDt] [datetime] NULL,
	[ApplyHaltPeriod] [int] NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[WorkStationIP] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_modality] PRIMARY KEY CLUSTERED 
(
	[ModalityGuid] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbModalityPlan]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbModalityPlan](
	[MPGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ModalityGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[StartDt] [datetime] NULL,
	[EndDt] [datetime] NULL,
	[DoctorGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[TechnicianGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[NurseGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_tModalityPlan] PRIMARY KEY NONCLUSTERED 
(
	[MPGuid] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbModalityShare]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbModalityShare](
	[Guid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[TimeSliceGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ShareTarget] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[TargetType] [int] NOT NULL,
	[MaxCount] [int] NOT NULL,
	[AvailableCount] [int] NOT NULL,
	[GroupId] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Date] [datetime] NULL,
 CONSTRAINT [pk_tModalityShare] PRIMARY KEY CLUSTERED 
(
	[Guid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbModalityTimeSlice]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbModalityTimeSlice](
	[TimeSliceGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ModalityType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Modality] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[StartDt] [datetime] NULL,
	[EndDt] [datetime] NULL,
	[Description] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[MaxNumber] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[DateType] [int] NULL,
	[AvailableDate] [date] NULL,
 CONSTRAINT [pk_tModalityTimeSlice] PRIMARY KEY CLUSTERED 
(
	[TimeSliceGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[TimeSliceGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbModalityType]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbModalityType](
	[ModalityType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[SOPClass] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UniqueID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_ModalityType] PRIMARY KEY NONCLUSTERED 
(
	[UniqueID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbModule]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbModule](
	[ModuleID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Title] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Parameter] [int] NULL,
	[ImageIndex] [int] NOT NULL,
	[OrderNo] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK__tModule] PRIMARY KEY NONCLUSTERED 
(
	[ModuleID] ASC,
	[Title] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbNotMatching]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbNotMatching](
	[Guid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PatientID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PatientName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[EnglishName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Gender] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Birthday] [datetime] NULL,
	[AccNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[AETitle] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ProcedureCode] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ProcedureDescription] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[ExamineDt] [datetime] NULL,
	[NotMatchingReason] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ProcessStatus] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_tNotMatching] PRIMARY KEY CLUSTERED 
(
	[Guid] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbOnlineClient]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbOnlineClient](
	[UserGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[MachineIP] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[RoleName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[IISUrl] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[LoginTime] [datetime] NULL,
	[Comments] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[SessionID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[IsOnline] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[MachineName] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[MACAddress] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Location] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK__tOnlineClient] PRIMARY KEY CLUSTERED 
(
	[UserGuid] ASC,
	[MachineIP] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbOperatorMap]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbOperatorMap](
	[DataType] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[Operator] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[Keyword] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbOrderCharge]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbOrderCharge](
	[ChargeGuid] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[OrderGuid] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NULL,
	[Code] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Description] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Amount] [int] NULL,
	[Price] [decimal](10, 2) NULL,
	[Confirm] [int] NULL,
	[Confirmer] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NULL,
	[ConfirmDt] [datetime] NULL,
	[ConfirmReason] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[Deduct] [int] NULL,
	[Deducter] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NULL,
	[DeductDt] [datetime] NULL,
	[DeductReason] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[Refund] [int] NULL,
	[Refunder] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NULL,
	[RefundDt] [datetime] NULL,
	[RefundReason] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[Cancel] [int] NULL,
	[Canceler] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NULL,
	[CancelDt] [datetime] NULL,
	[CancelReason] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[LastAction] [int] NULL,
	[LastStatus] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[CreateDt] [datetime] NOT NULL,
	[Unit] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[ChargeGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[ChargeGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbPanel]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbPanel](
	[PanelID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ModuleID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Title] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[AssemblyQualifiedName] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[Parameter] [int] NULL,
	[Flag] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ImageIndex] [int] NULL,
	[Key] [int] NOT NULL,
	[OrderNo] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_tPanel] PRIMARY KEY NONCLUSTERED 
(
	[PanelID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbPathologyReport]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbPathologyReport](
	[PathReportID] [uniqueidentifier] NOT NULL,
	[PatientID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Report] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[GenerateDt] [datetime] NULL,
 CONSTRAINT [PK_TPATHOLOGYRESULT] PRIMARY KEY CLUSTERED 
(
	[PathReportID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbPathologyTrack]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbPathologyTrack](
	[PathologyID] [uniqueidentifier] NOT NULL,
	[PatientID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[PatientName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[AccNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ReportGuid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Gender] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Birthday] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Diagnose] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CreatorName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[CreatorGuid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Judge] [int] NULL,
	[CreateDt] [datetime] NULL,
	[ReportName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Teaching] [bit] NULL,
	[Research] [bit] NULL,
 CONSTRAINT [PK_tPathologyTrack] PRIMARY KEY CLUSTERED 
(
	[PathologyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbPatientList]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbPatientList](
	[PLGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PatientGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PatientID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[LocalName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[EnglishName] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[ReferenceNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Birthday] [datetime] NULL,
	[Gender] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Address] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[Telephone] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[IsVIP] [int] NULL,
	[CreateDt] [datetime] NULL,
	[Comments] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[RemotePID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional1] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional2] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional3] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Alias] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[Marriage] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[GlobalID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[MedicareNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ParentName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[RelatedID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Archive] [int] NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[SocialSecurityNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[UpdateTime] [datetime] NULL,
	[Uploaded] [int] NULL,
	[Allergic] [int] NULL,
 CONSTRAINT [PK_tRegpatientlist] PRIMARY KEY CLUSTERED 
(
	[PLGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbPeopleSchedule]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbPeopleSchedule](
	[Guid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UserGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[TemplateGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[BeginTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[WorkStationIP] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Site] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_tPeopleSchedule] PRIMARY KEY CLUSTERED 
(
	[Guid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbPhraseTemplate]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbPhraseTemplate](
	[TemplateGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ModalityType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[TemplateName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[TemplateInfo] [nvarchar](1024) COLLATE Chinese_PRC_CI_AS NULL,
	[ShortcutCode] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Type] [int] NOT NULL,
	[UserGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_tPhraseTemplate] PRIMARY KEY NONCLUSTERED 
(
	[TemplateGuid] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbPhysicalCompany]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbPhysicalCompany](
	[Guid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Group] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Service] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ClinicCode] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ClinicFullName] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Telephone] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Address] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Comment] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional1] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional2] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [pk_tPhysicalCompany] PRIMARY KEY CLUSTERED 
(
	[Guid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbPrintTemplate]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbPrintTemplate](
	[TemplateGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Type] [int] NULL,
	[TemplateName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[TemplateInfo] [varbinary](max) NULL,
	[IsDefaultByType] [int] NULL,
	[Version] [int] NULL,
	[ModalityType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[IsDefaultByModality] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PropertyTag] [nvarchar](1024) COLLATE Chinese_PRC_CI_AS NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_PrintTemplate] PRIMARY KEY NONCLUSTERED 
(
	[TemplateGuid] ASC,
	[Domain] ASC,
	[Site] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbPrintTemplateFields]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbPrintTemplateFields](
	[FieldName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Type] [int] NULL,
	[SubType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UniqueID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_PrintTemplateFields] PRIMARY KEY NONCLUSTERED 
(
	[UniqueID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbProcedureCode]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbProcedureCode](
	[ProcedureCode] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Description] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[EnglishDescription] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[ModalityType] [varchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[BodyPart] [varchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[CheckingItem] [varchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[Charge] [decimal](12, 2) NULL,
	[Preparation] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Frequency] [int] NULL,
	[BodyCategory] [varchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Duration] [int] NULL,
	[FilmSpec] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FilmCount] [int] NULL,
	[ContrastName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ContrastDose] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ImageCount] [int] NULL,
	[ExposalCount] [int] NULL,
	[BookingNotice] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[ShortcutCode] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Enhance] [int] NULL,
	[ApproveWarningTime] [int] NULL,
	[Effective] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Externals] [int] NULL,
	[BodypartFrequency] [int] NULL,
	[CheckingItemFrequency] [int] NULL,
	[UniqueID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[TechnicianWeight] [int] NOT NULL,
	[RadiologistWeight] [int] NOT NULL,
	[ApprovedRadiologistWeight] [int] NOT NULL,
	[DefaultModality] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ClinicalModality] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Puncture] [int] NOT NULL,
	[Radiography] [int] NOT NULL,
 CONSTRAINT [PK_procedure_code] PRIMARY KEY CLUSTERED 
(
	[UniqueID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbQualityScoring]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbQualityScoring](
	[Guid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[AppraiseObject] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[OrderGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ExaminateDt] [datetime] NULL,
	[Type] [int] NULL,
	[Result] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Appraisee] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Appraiser] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[AppraiseDate] [datetime] NULL,
	[Comment] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Result2] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[Result3] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_tQualityScoring] PRIMARY KEY CLUSTERED 
(
	[Guid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbQuery]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbQuery](
	[ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[QueryName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ProcedureName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[LinkStr] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[XColumnName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[YColumnName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_tQuery] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbQueryCondition]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbQueryCondition](
	[ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[QueryID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Name] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Field] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[CompareStrOptions] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ValueType] [int] NULL,
	[ValueOptions] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[IsSql] [bit] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_tQueryCondition] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC,
	[QueryID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbQueryConditionShortCut]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbQueryConditionShortCut](
	[ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ShortcutGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[QueryConditionID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[CompareStr] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Value] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[DirKey] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[IsSelected] [bit] NOT NULL,
	[IsNot] [bit] NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_tQueryConditionShortCut] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbQueryResultColumn]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbQueryResultColumn](
	[ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[QueryID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[FieldName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ColumnName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[AggregateEnum] [int] NOT NULL,
	[LevelNo] [int] NOT NULL,
	[SequenceNo] [int] NOT NULL,
	[AggregateOnIndex] [int] NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_tQueryResultColumn] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC,
	[QueryID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbRandomInspection]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbRandomInspection](
	[ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReportGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Name] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[AccNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Appraisee] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[AppraiseeSequenceId] [int] NOT NULL,
	[Appraiser] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[AppraiserSequenceId] [int] NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[Type] [int] NOT NULL,
	[Result] [xml] NULL,
	[Indexs] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[Score] [int] NULL,
	[Grade] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[AccordRate] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Comment] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[examStartDate] [smalldatetime] NULL,
	[examEndDate] [smalldatetime] NULL,
 CONSTRAINT [PK_tRandomInspection] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbReferralEvent]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbReferralEvent](
	[EventGuid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReferralID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[SourceDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[TargetDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Memo] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Event] [int] NULL,
	[Status] [int] NULL,
	[ExamDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ExamAccNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[OperatorGuid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[OperatorName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[OperateDt] [datetime] NULL,
	[Tag] [int] NULL,
	[Content] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Scope] [int] NULL,
	[SourceSite] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[TargetSite] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[EventGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbReferralList]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbReferralList](
	[ReferralID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PatientID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[LocalName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[EnglishName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Gender] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Birthday] [datetime] NULL,
	[TelePhone] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Address] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[AccNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ApplyDoctor] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ApplyDt] [datetime] NULL,
	[ModalityType] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ProcedureCode] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[CheckingItem] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[HealthHistory] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Observation] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Refpurpose] [int] NULL,
	[RefStatus] [int] NULL,
	[RPStatus] [int] NULL,
	[ExamDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ExamAccNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDt] [datetime] NULL,
	[InitialDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[SourceDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[TargetDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[TargetSite] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Direction] [int] NULL,
	[IsExistSnapshot] [int] NULL,
	[GetReportDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[BookingBeginDt] [datetime] NULL,
	[BookingEndDt] [datetime] NULL,
	[OriginalBizData] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[PackagedBizData] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Scope] [int] NULL,
	[SourceSite] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[RefApplication] [xml] NULL,
	[RefReport] [xml] NULL,
PRIMARY KEY CLUSTERED 
(
	[ReferralID] ASC,
	[TargetDomain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbReferralLog]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbReferralLog](
	[ReferralID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[SourceDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[TargetDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[OperatorGuid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[OperatorName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[OperateDt] [datetime] NULL,
	[Memo] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[EventDesc] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDt] [datetime] NULL,
	[RefPurpose] [int] NULL,
	[SourceSite] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[TargetSite] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbRefEventDone]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbRefEventDone](
	[eventGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbRefReportSnapshot]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbRefReportSnapshot](
	[FileGuid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReferralId] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[RelativePath] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FileName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[createDt] [datetime] NULL,
	[backupMark] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[backupComment] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[FileGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbRegOrder]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbRegOrder](
	[OrderGuid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[VisitGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[AccNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ApplyDept] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ApplyDoctor] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDt] [datetime] NULL,
	[IsScan] [int] NULL,
	[Comments] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[RemoteAccNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[TotalFee] [decimal](12, 2) NULL,
	[Optional1] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional2] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional3] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[StudyInstanceUID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[HisID] [nchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CardNo] [nchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PatientGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[InhospitalNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ClinicNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PatientType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Observation] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[HealthHistory] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[InhospitalRegion] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[IsEmergency] [int] NULL,
	[BedNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CurrentAge] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[AgeInDays] [int] NULL,
	[visitcomment] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[ChargeType] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[ErethismType] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[ErethismCode] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[ErethismGrade] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReferralID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[IsReferral] [int] NULL,
	[ExamAccNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ExamDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[MedicalAlert] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[EXAMALERT1] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[EXAMALERT2] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[LMP] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[InitialDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ERequisition] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CurPatientName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CurGender] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[Priority] [int] NULL,
	[IsCharge] [int] NULL,
	[Bedside] [int] NULL,
	[IsFilmSent] [int] NULL,
	[FilmSentOperator] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FilmSentDt] [datetime] NULL,
	[OrderMessage] [xml] NULL,
	[BookingSite] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[RegSite] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ExamSite] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[BodyWeight] [decimal](6, 2) NULL,
	[FilmFee] [int] NULL,
	[ThreeDRebuild] [int] NULL,
	[CurrentSite] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[AssignDt] [datetime] NULL,
	[Assign2Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[StudyID] [nvarchar](16) COLLATE Chinese_PRC_CI_AS NULL,
	[PathologicalFindings] [nvarchar](16) COLLATE Chinese_PRC_CI_AS NULL,
	[InternalOptional1] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[InternalOptional2] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ExternalOptional1] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ExternalOptional2] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ExternalOptional3] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[UpdateTime] [datetime] NULL,
	[Uploaded] [int] NULL,
	[TakeReportDate] [date] NULL,
	[InjectDose] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[InjectTime] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[BodyHeight] [nvarchar](16) COLLATE Chinese_PRC_CI_AS NULL,
	[BloodSugar] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[Insulin] [nvarchar](16) COLLATE Chinese_PRC_CI_AS NULL,
	[GoOnGoTime] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[InjectorRemnant] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[SubmitHospital] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[SubmitDept] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[SubmitDoctor] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[EFilmNumber] [int] NULL,
	[TerminalCheckinPrintNumber] [int] NULL,
	[LotNumber] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[PhysicalCompany] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[HeartDisease] [bit] NULL,
	[Hypertension] [bit] NULL,
	[Scoliosis] [bit] NULL,
	[ImagingExamSheets] [xml] NULL,
	[FilmDrawerSign] [varbinary](max) NULL,
	[FilmDrawDept] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FilmDrawRegion] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FilmDrawComment] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[EstimatedExamBeginTime] [smalldatetime] NULL,
	[EstimatedExamEndTime] [smalldatetime] NULL,
	[ExecuteDepartment] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_tRegOrder] PRIMARY KEY CLUSTERED 
(
	[OrderGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbRegPatient]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbRegPatient](
	[PatientGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PatientID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[LocalName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[EnglishName] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[ReferenceNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Birthday] [datetime] NULL,
	[Gender] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Address] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[Telephone] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[IsVIP] [int] NULL,
	[CreateDt] [datetime] NULL,
	[Comments] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[RemotePID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional1] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional2] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional3] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Alias] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[Marriage] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[GlobalID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[MedicareNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ParentName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[RelatedID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[SocialSecurityNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[UpdateTime] [datetime] NULL,
	[Uploaded] [int] NULL,
	[IsAllergic] [int] NULL,
 CONSTRAINT [PK_tRegpatient] PRIMARY KEY NONCLUSTERED 
(
	[PatientGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[PatientID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbRegProcedure]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbRegProcedure](
	[ProcedureGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[OrderGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ProcedureCode] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ExamSystem] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[WarningTime] [int] NOT NULL,
	[FilmSpec] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FilmCount] [int] NULL,
	[ContrastName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ContrastDose] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ImageCount] [int] NULL,
	[ExposalCount] [int] NULL,
	[Deposit] [decimal](12, 2) NULL,
	[Charge] [decimal](12, 2) NULL,
	[ModalityType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Modality] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Registrar] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[RegisterDt] [datetime] NULL,
	[Priority] [int] NULL,
	[Technician] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[TechDoctor] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[TechNurse] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[OperationStep] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[ExamineDt] [datetime] NULL,
	[Mender] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ModifyDt] [datetime] NULL,
	[IsPost] [int] NULL,
	[IsExistImage] [int] NULL,
	[Status] [int] NOT NULL,
	[Comments] [nvarchar](1024) COLLATE Chinese_PRC_CI_AS NULL,
	[BookingBeginDt] [datetime] NULL,
	[BookingEndDt] [datetime] NULL,
	[Booker] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[IsCharge] [int] NULL,
	[RemoteRPID] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional1] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional2] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional3] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[QueueNo] [nchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[BookingNotice] [varbinary](max) NULL,
	[BookingTimeAlias] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDt] [datetime] NULL,
	[ReportGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[MedicineUsage] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Posture] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Technician1] [nvarchar](62) COLLATE Chinese_PRC_CI_AS NULL,
	[Technician2] [nvarchar](62) COLLATE Chinese_PRC_CI_AS NULL,
	[Technician3] [nvarchar](62) COLLATE Chinese_PRC_CI_AS NULL,
	[Technician4] [nvarchar](62) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UnwrittenPreviousOwner] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[UnwrittenCurrentOwner] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[UnwrittenAssignDate] [datetime] NULL,
	[UnapprovedCurrentOwner] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[UnapprovedPreviousOwner] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[UnapprovedAssignDate] [datetime] NULL,
	[PreStatus] [int] NULL,
	[UpdateTime] [datetime] NULL,
	[Uploaded] [int] NULL,
	[BookerName] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[RegistrarName] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[TechnicianName] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[BodyCategory] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Bodypart] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[CheckingItem] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[RPDesc] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ScanDelayTime] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CheckItemName] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[PerformBegindt] [datetime] NULL,
 CONSTRAINT [pk_tRegProcedure] PRIMARY KEY NONCLUSTERED 
(
	[ProcedureGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbReport]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbReport](
	[ReportGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReportName] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[WYS] [varbinary](max) NULL,
	[WYG] [varbinary](max) NULL,
	[AppendInfo] [varbinary](max) NULL,
	[ReportText] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[DoctorAdvice] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[IsPositive] [int] NULL,
	[AcrCode] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[AcrAnatomic] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[AcrPathologic] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Creater] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDt] [datetime] NULL,
	[Submitter] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[SubmitDt] [datetime] NULL,
	[FirstApprover] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FirstApproveDt] [datetime] NULL,
	[SecondApprover] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[SecondApproveDt] [datetime] NULL,
	[IsDiagnosisRight] [int] NULL,
	[KeyWord] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ReportQuality] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[RejectToObject] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Rejecter] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[RejectDt] [datetime] NULL,
	[Status] [int] NULL,
	[Comments] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[DeleteMark] [int] NULL,
	[Deleter] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[DeleteDt] [datetime] NULL,
	[Recuperator] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ReconvertDt] [datetime] NULL,
	[Mender] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ModifyDt] [datetime] NULL,
	[IsPrint] [int] NULL,
	[CheckItemName] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional1] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional2] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional3] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[IsLeaveWord] [int] NULL,
	[WYSText] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[WYGText] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[IsDraw] [int] NULL,
	[DrawerSign] [varbinary](max) NULL,
	[DrawTime] [datetime] NULL,
	[IsLeaveSound] [int] NULL,
	[TakeFilmDept] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[TakeFilmRegion] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[TakeFilmComment] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[PrintCopies] [int] NOT NULL,
	[PrintTemplateGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReadOnly] [int] NULL,
	[SubmitDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[RejectDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[FirstApproveDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[SecondApproveDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ReportTextApprovedSign] [varbinary](max) NULL,
	[ReportTextSubmittedSign] [varbinary](max) NULL,
	[CombinedForCertification] [varbinary](max) NULL,
	[SignCombinedForCertification] [varbinary](max) NULL,
	[RejectSite] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[SubmitSite] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[FirstApproveSite] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[SecondApproveSite] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[RebuildMark] [int] NULL,
	[ReportQuality2] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[UpdateTime] [datetime] NULL,
	[Uploaded] [int] NULL,
	[SubmitterName] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[FirstApproverName] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[SecondApproverName] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[ReportQualityComments] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CreaterName] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[MenderName] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[TechInfo] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[TerminalReportPrintNumber] [int] NULL,
	[ScoringVersion] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[AccordRate] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[SubmitterSign] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[FirstApproverSign] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[SecondApproverSign] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[SubmitterSignTimeStamp] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[FirstApproverSignTimeStamp] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[SecondApproverSignTimeStamp] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[IsModified] [int] NULL,
 CONSTRAINT [PK_Reports] PRIMARY KEY NONCLUSTERED 
(
	[ReportGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbReportContent]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbReportContent](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[TemplateId] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[TemplateVersion] [int] NOT NULL,
	[ReportId] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReportVersion] [int] NOT NULL,
	[ContentHtml] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[AuthorName] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[AutherId] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifyDate] [datetime] NOT NULL,
	[Status] [int] NOT NULL,
	[Domain] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[NaturalContentHtml] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_dbo.tbReportContent] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbReportContentList]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbReportContentList](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ReportId] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReportVersion] [int] NOT NULL,
	[ContentHtml] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[AuthorName] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[AutherId] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDate] [datetime] NOT NULL,
	[Status] [int] NOT NULL,
	[Domain] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReportListId] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[NaturalContentHtml] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_dbo.tbReportContentList] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbReportDelPool]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbReportDelPool](
	[ReportGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReportName] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[WYS] [varbinary](max) NULL,
	[WYG] [varbinary](max) NULL,
	[AppendInfo] [varbinary](max) NULL,
	[ReportText] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[DoctorAdvice] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[IsPositive] [int] NULL,
	[AcrCode] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[AcrAnatomic] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[AcrPathologic] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Creater] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDt] [datetime] NULL,
	[Submitter] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[SubmitDt] [datetime] NULL,
	[FirstApprover] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FirstApproveDt] [datetime] NULL,
	[SecondApprover] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[SecondApproveDt] [datetime] NULL,
	[IsDiagnosisRight] [int] NULL,
	[KeyWord] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ReportQuality] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[RejectToObject] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Rejecter] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[RejectDt] [datetime] NULL,
	[Status] [int] NULL,
	[Comments] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[DeleteMark] [int] NULL,
	[Deleter] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[DeleteDt] [datetime] NULL,
	[Recuperator] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ReconvertDt] [datetime] NULL,
	[Mender] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ModifyDt] [datetime] NULL,
	[IsPrint] [int] NULL,
	[CheckItemName] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional1] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional2] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional3] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[IsLeaveWord] [int] NULL,
	[WYSText] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[WYGText] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[IsDraw] [int] NULL,
	[DrawerSign] [varbinary](max) NULL,
	[DrawTime] [datetime] NULL,
	[IsLeaveSound] [int] NULL,
	[TakeFilmDept] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[TakeFilmRegion] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[TakeFilmComment] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[PrintCopies] [int] NOT NULL,
	[PrintTemplateGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReadOnly] [int] NULL,
	[SubmitDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[RejectDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[FirstApproveDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[SecondApproveDomain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ReportTextApprovedSign] [varbinary](max) NULL,
	[ReportTextSubmittedSign] [varbinary](max) NULL,
	[CombinedForCertification] [varbinary](max) NULL,
	[SignCombinedForCertification] [varbinary](max) NULL,
	[RejectSite] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[SubmitSite] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FirstApproveSite] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[SecondApproveSite] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[RebuildMark] [int] NULL,
	[ReportQuality2] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[UpdateTime] [datetime] NULL,
	[Uploaded] [int] NULL,
	[SubmitterName] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[FirstApproverName] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[SecondApproverName] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[ReportQualityComments] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CreaterName] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[MenderName] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[TechInfo] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[TerminalReportPrintNumber] [int] NULL,
	[ScoringVersion] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[AccordRate] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[SubmitterSign] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[FirstApproverSign] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[SecondApproverSign] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[SubmitterSignTimeStamp] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[FirstApproverSignTimeStamp] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[SecondApproverSignTimeStamp] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[IsModified] [int] NULL,
 CONSTRAINT [pk_ReportDelPool] PRIMARY KEY CLUSTERED 
(
	[ReportGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbReportDoctor]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbReportDoctor](
	[DOCTOR_GUID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[DOCTOR_NAME] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PREFERRED_MODALITY_TYPE] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[PREFERRED_PHYSIOLOGICAL_SYSTEM] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[IS_RECEIVE_REPORT] [int] NULL,
	[DOMAIN] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[PREFERRED_PATIENT_TYPE] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[IM_STATUS] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[MaxHoldCount] [int] NULL,
	[Supervisor] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[ReportType] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[BeginDateTime] [datetime] NOT NULL,
	[EndDateTime] [datetime] NOT NULL,
	[Department] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[AverageWeight] [nvarchar](10) COLLATE Chinese_PRC_CI_AS NULL,
	[Preferred_site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[REPORT_DOCTOR_GROUP] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[MaxHoldCountToday] [int] NULL,
	[MaxAssignedPercentage] [int] NOT NULL,
	[MaxHoldWeightToday] [nvarchar](10) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PREFERRED_BODAYPART_CATEGORY] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_tReportDoctor] PRIMARY KEY CLUSTERED 
(
	[DOCTOR_GUID] ASC,
	[ReportType] ASC,
	[BeginDateTime] ASC,
	[EndDateTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbReportFile]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbReportFile](
	[FileGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReportGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[fileType] [int] NULL,
	[RelativePath] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[FileName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[BackupMark] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[BackupComment] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[ShowWidth] [int] NULL,
	[ShowHeight] [int] NULL,
	[ImagePosition] [int] NULL,
	[CreateDt] [datetime] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_tReportFile] PRIMARY KEY NONCLUSTERED 
(
	[FileGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbReportItem]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbReportItem](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ReportId] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ItemPosition] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[ItemId] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ItemName] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[ValueId] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Value] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[PatientId] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_dbo.tbReportItem] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbReportList]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbReportList](
	[ReportListGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReportGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReportName] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[WYS] [varbinary](max) NULL,
	[WYG] [varbinary](max) NULL,
	[AppendInfo] [varbinary](max) NULL,
	[ReportText] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[DoctorAdvice] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[IsPositive] [int] NULL,
	[AcrCode] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[AcrAnatomic] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[AcrPathologic] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Creater] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDt] [datetime] NULL,
	[Submitter] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[SubmitDt] [datetime] NULL,
	[FirstApprover] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[FirstApproveDt] [datetime] NULL,
	[SecondApprover] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[SecondApproveDt] [datetime] NULL,
	[IsDiagnosisRight] [int] NULL,
	[KeyWord] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ReportQuality] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[RejectToObject] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Rejecter] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[RejectDt] [datetime] NULL,
	[Status] [int] NULL,
	[Comments] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[DeleteMark] [int] NULL,
	[Deleter] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[DeleteDt] [datetime] NULL,
	[Recuperator] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ReconvertDt] [datetime] NULL,
	[Mender] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ModifyDt] [datetime] NULL,
	[IsPrint] [int] NULL,
	[OperationTime] [datetime] NULL,
	[WYSText] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[WYGText] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[MenderName] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[CreaterName] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[SubmitterName] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[TechInfo] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_Reportslist] PRIMARY KEY NONCLUSTERED 
(
	[ReportListGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbReportPrintLog]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbReportPrintLog](
	[FileGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReportGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Printer] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PrintDt] [datetime] NULL,
	[Counts] [int] NULL,
	[Comments] [nvarchar](1024) COLLATE Chinese_PRC_CI_AS NULL,
	[BackupMark] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[BackupComment] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[SnapShotSrvPath] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[Type] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PrintTemplateGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_tReportPrintLog] PRIMARY KEY NONCLUSTERED 
(
	[FileGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbReportTemplate]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbReportTemplate](
	[TemplateGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[TemplateName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ModalityType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[BodyPart] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[WYS] [varbinary](max) NULL,
	[WYG] [varbinary](max) NULL,
	[AppendInfo] [varbinary](max) NULL,
	[TechInfo] [varbinary](max) NULL,
	[CheckItemName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[DoctorAdvice] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[ShortcutCode] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ACRCode] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ACRAnatomicDesc] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[ACRPathologicDesc] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[BodyCategory] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Gender] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[Positive] [int] NULL,
 CONSTRAINT [PK_RepTemplate] PRIMARY KEY NONCLUSTERED 
(
	[TemplateGuid] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbReportTemplateDirec]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbReportTemplateDirec](
	[ItemGUID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ParentID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Depth] [int] NULL,
	[ItemName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ItemOrder] [int] NULL,
	[Type] [int] NULL,
	[UserGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[TemplateGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Leaf] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[DirectoryType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [pk_tReportTemplateDirec] PRIMARY KEY NONCLUSTERED 
(
	[ItemGUID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbRequest]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbRequest](
	[RequestID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ErNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[RequestType] [nvarchar](16) COLLATE Chinese_PRC_CI_AS NULL,
	[EventCode] [int] NULL,
	[PatientID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[LocalName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[EnglishName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Gender] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[InhospitalRegion] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[InhospitalNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ClinicNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[BedNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Birthday] [datetime] NULL,
	[Telephone] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Address] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[GlobalID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[MedicareNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ApplyDept] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ApplyDoctor] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[HealthHistory] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Observation] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[IdentityNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[SocialSecurityNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Hisid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[CardNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ChargeType] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[PatientType] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Priority] [int] NULL,
	[Reason] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[EAcquisition] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[WebAcquisitionUrl] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[RequestDt] [datetime] NULL,
	[Domain] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[Site] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[RISPatientID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_TREQUEST] PRIMARY KEY CLUSTERED 
(
	[RequestID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbRequestCharge]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbRequestCharge](
	[RequestChargeID] [varchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[RequestID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[RequestItemID] [varchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ItemCode] [varchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ItemName] [varchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Price] [float] NULL,
	[Amount] [int] NULL,
	[IsItemCharged] [int] NULL,
 CONSTRAINT [PK_TREQUESTCHARGE] PRIMARY KEY CLUSTERED 
(
	[RequestChargeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbRequestItem]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbRequestItem](
	[RequestItemID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[RequestID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[RequestItemUID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ModalityType] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Modality] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ProcedureCode] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[RPDesc] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[ExamSystem] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ScheduleTime] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Comment] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[TeethName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[TeethCode] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Teethcount] [int] NULL,
	[AccNo] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[Status] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_TREQUESTITEM] PRIMARY KEY CLUSTERED 
(
	[RequestItemID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbRequestList]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbRequestList](
	[tRequestListID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[RequestID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ErNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[RequestType] [nvarchar](16) COLLATE Chinese_PRC_CI_AS NULL,
	[EventCode] [int] NULL,
	[PatientID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[LocalName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[EnglishName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Gender] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[InhospitalRegion] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[InhospitalNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ClinicNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[BedNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Birthday] [datetime] NULL,
	[Telephone] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Address] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[GlobalID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[MedicareNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ApplyDept] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ApplyDoctor] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[HealthHistory] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Observation] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[IdentityNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[SocialSecurityNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Hisid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[CardNo] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ChargeType] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[PatientType] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Priority] [int] NULL,
	[Reason] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[EAcquisition] [xml] NULL,
	[WebAcquisitionUrl] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[RequestDt] [datetime] NULL,
	[RequestItem] [xml] NULL,
	[RequestCharge] [xml] NULL,
	[PutinDt] [datetime] NULL,
	[Domain] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
	[Site] [nvarchar](32) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_TREQUESTLIST] PRIMARY KEY CLUSTERED 
(
	[tRequestListID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbRequisition]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbRequisition](
	[RequisitionGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[AccNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[RelativePath] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[FileName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ScanDt] [datetime] NULL,
	[BackupMark] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[BackupComment] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UpdateTime] [datetime] NULL,
	[Uploaded] [int] NULL,
	[Createdt] [datetime] NULL,
	[Erno] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK__tRequisition] PRIMARY KEY NONCLUSTERED 
(
	[RequisitionGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbReShot]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbReShot](
	[ProcedureGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Technician] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[ShotDt] [datetime] NULL,
	[Reason] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[RejectDoctor] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[RejectDt] [datetime] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_ReShot] PRIMARY KEY CLUSTERED 
(
	[ProcedureGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbRole]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbRole](
	[RoleName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Description] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[IsSystem] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[RoleID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_tRole] PRIMARY KEY NONCLUSTERED 
(
	[RoleName] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbRole2User]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbRole2User](
	[RoleName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UserGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_Role2User] PRIMARY KEY CLUSTERED 
(
	[RoleName] ASC,
	[UserGuid] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbRoleDir]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbRoleDir](
	[UniqueID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Name] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ParentID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NULL,
	[RoleID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NULL,
	[Leaf] [int] NULL,
	[OrderID] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_TRoleDir_UniqueID] PRIMARY KEY NONCLUSTERED 
(
	[UniqueID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbRoleProfile]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbRoleProfile](
	[RoleName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Name] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ModuleID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Value] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Exportable] [int] NOT NULL,
	[PropertyDesc] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[PropertyOptions] [nvarchar](1024) COLLATE Chinese_PRC_CI_AS NULL,
	[Inheritance] [int] NOT NULL,
	[PropertyType] [int] NOT NULL,
	[IsHidden] [int] NOT NULL,
	[OrderingPos] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UniqueID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK__tRoleProfile] PRIMARY KEY NONCLUSTERED 
(
	[UniqueID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbRptData]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbRptData](
	[ID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReportGuid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[StructureID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Data] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_SPGTDData] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbRptStructure]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbRptStructure](
	[ID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[RID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[TID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Name] [nvarchar](255) COLLATE Chinese_PRC_CI_AS NULL,
	[XmlTag] [nvarchar](255) COLLATE Chinese_PRC_CI_AS NULL,
	[RadLexID] [nvarchar](255) COLLATE Chinese_PRC_CI_AS NULL,
	[RadLexMatch] [nvarchar](255) COLLATE Chinese_PRC_CI_AS NULL,
	[SnomedID] [nvarchar](255) COLLATE Chinese_PRC_CI_AS NULL,
	[Value] [nvarchar](255) COLLATE Chinese_PRC_CI_AS NULL,
	[GCRisCtrlType] [nvarchar](255) COLLATE Chinese_PRC_CI_AS NULL,
	[Type] [int] NULL,
	[SortID] [nvarchar](255) COLLATE Chinese_PRC_CI_AS NULL,
	[TreeLevel] [int] NULL,
 CONSTRAINT [PK_tRptStructure] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbRptTemplate]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbRptTemplate](
	[TID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[TName] [nvarchar](255) COLLATE Chinese_PRC_CI_AS NULL,
	[RID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Version] [int] NOT NULL,
	[XmlFilePath] [nvarchar](255) COLLATE Chinese_PRC_CI_AS NULL,
	[ModalityType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[BodyPart] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Gender] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[IsPositive] [int] NULL,
 CONSTRAINT [PK_tRptTemplate_1] PRIMARY KEY CLUSTERED 
(
	[TID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbScanningTech]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbScanningTech](
	[ScanningTechGuid] [nvarchar](128) NOT NULL,
	[ScanningTech] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[ParentScanningTechGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ModalityType] [nchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Site] [nchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	CONSTRAINT [PK_tbScanningTech] PRIMARY KEY CLUSTERED 
(
	[ScanningTechGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbScheduleExcelTempate]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbScheduleExcelTempate](
	[GUID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Level] [int] NOT NULL,
	[Type] [int] NOT NULL,
	[Name] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Value] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[OrderId] [int] NOT NULL,
	[Parent] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_tScheduleExcelTempate] PRIMARY KEY CLUSTERED 
(
	[GUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbScheduleTempate]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbScheduleTempate](
	[GUID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Level] [int] NOT NULL,
	[TemplateType] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[NodeType] [int] NOT NULL,
	[Name] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[BeginTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[WorkStationIP] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[OrderId] [int] NOT NULL,
	[Parent] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_tScheduleTempate] PRIMARY KEY CLUSTERED 
(
	[GUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbScheduleTimePeriod]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbScheduleTimePeriod](
	[UniqueID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[BeginTime] [datetime] NOT NULL,
	[EndTime] [datetime] NOT NULL,
	[IsEndTimeNextDay] [int] NOT NULL,
	[Alias] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbScoringResult]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbScoringResult](
	[Guid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ObjectGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Type] [int] NOT NULL,
	[Result] [xml] NOT NULL,
	[CreateDate] [datetime] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Result2] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Appraiser] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Comment] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[AccordRate] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[IsFinalVersion] [int] NOT NULL,
 CONSTRAINT [PK_tScoringResult] PRIMARY KEY CLUSTERED 
(
	[Guid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbScoringSettings]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbScoringSettings](
	[VersionNo] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Type] [int] NOT NULL,
	[IsCurrent] [int] NOT NULL,
	[Settings] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_tScoringSettings] PRIMARY KEY CLUSTERED 
(
	[VersionNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbScriptRunTrack]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbScriptRunTrack](
	[sessionid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[filename] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[begintime] [datetime] NULL,
	[endtime] [datetime] NULL,
	[runningtime] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[clientname] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[loginname] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbShortcut]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbShortcut](
	[ShortcutGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Type] [int] NOT NULL,
	[Category] [int] NOT NULL,
	[Name] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Value] [nvarchar](4000) COLLATE Chinese_PRC_CI_AS NULL,
	[Owner] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_tShortcut] PRIMARY KEY NONCLUSTERED 
(
	[ShortcutGuid] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbShowScreen]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbShowScreen](
	[ShowScreenGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PatientGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PatientName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[AccNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[QueueNo] [int] NULL,
	[Status] [int] NULL,
	[ActivityDate] [datetime] NULL,
	[RegDate] [datetime] NULL,
	[ModalityType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ClinicNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[InhospitalNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Comments] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_tShowScreen] PRIMARY KEY NONCLUSTERED 
(
	[ShowScreenGuid] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbSignedHistory]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbSignedHistory](
	[SignGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Action] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Creater] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[IsSigned] [int] NULL,
	[OrderGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ReportGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CertSN] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[RawData] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[SignedData] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[SignedTimeStamp] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDt] [datetime] NULL,
	[Comments] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PatientID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[LocalName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[ClinicNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[AccNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[CheckingItem] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[WYSText] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[WYGText] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[IsPositive] [int] NULL,
	[ExamDt] [datetime] NULL,
 CONSTRAINT [PK_tSignedHistory] PRIMARY KEY NONCLUSTERED 
(
	[SignGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbSiteList]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbSiteList](
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[DomainPrefix] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Connstring] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[FtpServer] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[FtpPort] [int] NULL,
	[FtpUser] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[FtpPassword] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[PacsAETitle] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Telephone] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Address] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[PacsServer] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[PacsWebServer] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Tab] [int] NOT NULL,
	[Alias] [nvarchar](16) COLLATE Chinese_PRC_CI_AS NULL,
	[IISUrl] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	CONSTRAINT [PK_tbSiteList] PRIMARY KEY CLUSTERED 
(
	[Site] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbSiteProfile]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbSiteProfile](
	[Name] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ModuleID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Value] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Exportable] [int] NOT NULL,
	[PropertyDesc] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[PropertyOptions] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[Inheritance] [int] NOT NULL,
	[PropertyType] [int] NOT NULL,
	[IsHidden] [int] NOT NULL,
	[OrderingPos] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UniqueID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK__tSiteProfile] PRIMARY KEY NONCLUSTERED 
(
	[UniqueID] ASC,
	[Domain] ASC,
	[Site] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbSync]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbSync](
	[SyncType] [int] NOT NULL,
	[Guid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Owner] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[OwnerIP] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDt] [datetime] NULL,
	[ModuleID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PatientID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[PatientName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[AccNo] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Counter] [int] NULL,
	[RPGuids] [nvarchar](1024) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_sync] PRIMARY KEY NONCLUSTERED 
(
	[SyncType] ASC,
	[Guid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbSyncErrorLog]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbSyncErrorLog](
	[KeyID] [int] IDENTITY(1,1) NOT NULL,
	[TableName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[KeyColumn] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[SyncType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[SyncValue] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDt] [datetime] NULL,
 CONSTRAINT [pk_tSyncErrorLog] PRIMARY KEY CLUSTERED 
(
	[KeyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbSystemProfile]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbSystemProfile](
	[Name] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ModuleID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Value] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Exportable] [int] NOT NULL,
	[PropertyDesc] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[PropertyOptions] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Inheritance] [int] NOT NULL,
	[PropertyType] [int] NOT NULL,
	[IsHidden] [int] NOT NULL,
	[OrderingPos] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UniqueID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK__tSystemProfile] PRIMARY KEY NONCLUSTERED 
(
	[UniqueID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbTeaching]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbTeaching](
	[TeachingGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ReportGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[FileType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[AcrCode] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[CodeType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Submitter] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[SubmitDt] [datetime] NOT NULL,
	[ACodeDetail] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PCodeDetail] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Creator] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional1] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional2] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional3] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional4] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional5] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Optional6] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[CreateDt] [datetime] NOT NULL,
	[Type] [int] NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[FollowUpEvaluation] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_teaching_files] PRIMARY KEY NONCLUSTERED 
(
	[TeachingGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbTeachingCategory]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbTeachingCategory](
	[UniqueID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[CategoryName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[CategoryLevel] [int] NULL,
	[ParentID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[OrderNo] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[OptionFieldSettingName] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbUser]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbUser](
	[UserGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[LoginName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[LocalName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[EnglishName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Password] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Title] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Address] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Comments] [nvarchar](512) COLLATE Chinese_PRC_CI_AS NULL,
	[DeleteMark] [int] NULL,
	[SignImage] [varbinary](max) NULL,
	[PrivateKey] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[PublicKey] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[IkeySn] [nchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[DisplayName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[InvalidLoginCount] [int] NULL,
	[IsLocked] [int] NULL,
 CONSTRAINT [PK_tuser] PRIMARY KEY CLUSTERED 
(
	[UserGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbUser2Domain]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbUser2Domain](
	[UserGuid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Department] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[DomainLoginName] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[Telephone] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
	[IsSetExpireDate] [int] NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Mobile] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Email] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK__tUser2Domain] PRIMARY KEY CLUSTERED 
(
	[UserGuid] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbUserCerts]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbUserCerts](
	[UserGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[CertSN] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[CertBasicInfo] [xml] NULL,
	[CertInfo] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[SignPic] [varbinary](max) NULL,
	[IsActive] [int] NULL,
	[Domain] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[CertID] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK_tUserCerts] PRIMARY KEY NONCLUSTERED 
(
	[UserGuid] ASC,
	[CertSN] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbUserProfile]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbUserProfile](
	[Name] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ModuleID] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[RoleName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UserGuid] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Value] [nvarchar](max) COLLATE Chinese_PRC_CI_AS NULL,
	[Exportable] [int] NOT NULL,
	[PropertyDesc] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[PropertyOptions] [nvarchar](256) COLLATE Chinese_PRC_CI_AS NULL,
	[Inheritance] [int] NOT NULL,
	[PropertyType] [int] NOT NULL,
	[IsHidden] [int] NOT NULL,
	[OrderingPos] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UniqueID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [PK__tUserProfile] PRIMARY KEY NONCLUSTERED 
(
	[UniqueID] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbWarningTime]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbWarningTime](
	[Type] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ModalityType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[PatientType] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[WarningTime] [int] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[UniqueID] [nvarchar](36) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [pk_tWarningTime] PRIMARY KEY CLUSTERED 
(
	[UniqueID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbWebAppFunc]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbWebAppFunc](
	[FuncID] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[FuncName] [nvarchar](255) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[FuncTitle] [nvarchar](255) COLLATE Chinese_PRC_CI_AS NULL,
	[FuncType] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[ParamNameValue] [nvarchar](255) COLLATE Chinese_PRC_CI_AS NULL,
	[RelatedFuncID] [nvarchar](255) COLLATE Chinese_PRC_CI_AS NULL,
	[Disabled] [int] NOT NULL,
	[SortID] [int] NULL,
	[Memo] [nvarchar](255) COLLATE Chinese_PRC_CI_AS NULL,
	[ParentID] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[CreateDate] [datetime] NULL,
	[CreateUserID] [nvarchar](12) COLLATE Chinese_PRC_CI_AS NULL,
	[UpdateDate] [datetime] NULL,
	[UpdateUserID] [nvarchar](12) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_SPGAppFunc] PRIMARY KEY CLUSTERED 
(
	[FuncID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbWebAppFuncPermission]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbWebAppFuncPermission](
	[RoleName] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[FuncID] [nvarchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[FlagStartup] [int] NULL,
	[Enabled] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbWorkingCalendar]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbWorkingCalendar](
	[Date] [date] NOT NULL,
	[DateType] [int] NULL,
	[DateDesp] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Domain] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Modality] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NULL,
	[Site] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tbWorkTime]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbWorkTime](
	[WTGuid] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[WorkTimeName] [nvarchar](128) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[StartDt] [datetime] NULL,
	[EndDt] [datetime] NULL,
	[Domain] [nvarchar](64) COLLATE Chinese_PRC_CI_AS NOT NULL,
 CONSTRAINT [pk_WorkTime] PRIMARY KEY NONCLUSTERED 
(
	[WTGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  View [dbo].[viConsultationList]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[viConsultationList]
AS
SELECT  
tbRegOrder.ACCNO AS tbRegOrder__ACCNO
, dbo.[fnGetRPDescriptions](cstOrderGuid) AS tbRegProcedure__RPDesc
, (select top 1 ModalityType from tbRegProcedure where OrderGuid=cstOrderGuid) AS tbRegProcedure__ModalityType
, (select top 1 Modality from tbRegProcedure where OrderGuid=cstOrderGuid) AS tbRegProcedure__Modality
, (select top 1 ExamineDT from tbRegProcedure where OrderGuid=cstOrderGuid) AS tbRegProcedure__ExamineDT
, dbo.fnTranslateUser(cstUserGuid) AS vConsultationList__cstUserGuid__DESC
, dbo.fnTranslateSite(cstSite) AS vConsultationList__cstSite__DESC
, dbo.fnTranslateDictionaryValue(160, cstStatus) AS vConsultationList__cstStatus__DESC
, cstGuid AS vConsultationList__cstGuid
, cstUserGuid AS vConsultationList__cstUserGuid
, cstSite AS vConsultationList__cstSite
, cstOrderGuid AS vConsultationList__cstOrderGuid
, cstStatus AS vConsultationList__cstStatus
, cstConsultHospital AS vConsultationList__cstConsultHospital
, dbo.fnTranslateDictionaryValue(161, cstType) AS vConsultationList__cstType
, cstApplyTime AS vConsultationList__cstApplyTime
, cstStartTime AS vConsultationList__cstStartTime
, cstEndTime AS vConsultationList__cstEndTime
, cstExpert AS vConsultationList__cstExpert
, cstDiagnosisRequestId AS vConsultationList__cstDiagnosisRequestId
, cstImpression AS vConsultationList__cstImpression
, cstInterpretation AS vConsultationList__cstInterpretation
, cstKeywords AS vConsultationList__cstKeywords
, dbo.fnTranslateDictionaryValue(162, cstIsPositive) AS vConsultationList__cstIsPositive
, cstReportComment AS vConsultationList__cstReportComment
, tbRegOrder.PatientGuid AS tbRegOrder__PatientGuid
FROM
 dbo.tbConsultation, tbRegOrder
 where cstOrderGuid=tbRegOrder.OrderGuid


GO
/****** Object:  View [dbo].[viGetDate]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[viGetDate]
as--集54391 2009-10-30 11:23:46 4.0标准版 201003 升级发布96
	select GetDate() as curdate



GO
/****** Object:  View [dbo].[viSignatureList]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===========================================================================
-- Description:US117705签名列表view增加字段
-- ===========================================================================
CREATE VIEW [dbo].[viSignatureList]
AS
SELECT 
SignGuid as tbSignedHistory__SignGuid,
dbo.fnTranslateDictionaryValue(170,Action) AS tbSignedHistory__Action__DESC,
Action as tbSignedHistory__Action,
Creater as tbSignedHistory__Creater,
dbo.fnTranslateUser(tbSignedHistory.Creater) AS tbSignedHistory__Creater__DESC,
IsSigned as tbSignedHistory__IsSigned,
dbo.fnTranslateYesNo(tbSignedHistory.IsSigned) AS tbSignedHistory__IsSigned__DESC,
OrderGuid as tbSignedHistory__OrderGuid,
CertSN as tbSignedHistory__CertSN,
RawData as tbSignedHistory__RawData,
SignedData as tbSignedHistory__SignedData,
SignedTimeStamp as tbSignedHistory__SignedTimeStamp,
CreateDt as tbSignedHistory__CreateDt,
Comments as tbSignedHistory__SignComments ,
ReportGuid as tbSignedHistory__ReportGuid ,
PatientID as tbRegPatient__PatientID ,
LocalName as tbRegPatient__LocalName ,
ClinicNo as tbRegOrder__ClinicNo ,
AccNo as tbRegOrder__AccNo ,
CheckingItem as tbRegProcedure__CheckingItem ,
WYSText as tbReport__WYSText ,
WYGText as tbReport__WYGText ,
IsPositive as tbReport__IsPositive ,
dbo.fnTranslateDictionaryValue(21, IsPositive) AS tbReport__IsPositive__DESC,
ExamDt as tbRegProcedure__ExamDt

from tbSignedHistory 


GO
/****** Object:  View [dbo].[viTableKeys]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE view [dbo].[viTableKeys] as 
select distinct Table_Name , Column_Name from
(
SELECT t_obj.name AS Table_Name, col.name AS Column_Name 
FROM sysobjects c_obj, sysobjects t_obj, syscolumns col, sysreferences ref
WHERE c_obj.xtype IN ('F ') AND t_obj.id = c_obj.parent_obj AND 
      t_obj.id = col.id AND col.colid IN (ref.fkey1, ref.fkey2, ref.fkey3, ref.fkey4, ref.fkey5, 
      ref.fkey6, ref.fkey7, ref.fkey8, ref.fkey9, ref.fkey10, ref.fkey11, ref.fkey12, ref.fkey13, 
      ref.fkey14, ref.fkey15, ref.fkey16) AND c_obj.id = ref.constid
UNION
SELECT t_obj.name AS Table_Name, col.name AS Column_Name 
FROM sysobjects c_obj, sysobjects t_obj, syscolumns col, master.dbo.spt_values v, 
      sysindexes i
WHERE c_obj.xtype IN ('UQ', 'PK') AND 
      t_obj.id = c_obj.parent_obj AND t_obj.xtype = 'U' AND t_obj.id = col.id AND 
      col.name = index_col(t_obj.name, i.indid, v.number) AND t_obj.id = i.id AND 
      c_obj.name = i.name AND v.number > 0 AND v.number <= i.keycnt AND v.type = 'P'
) A



GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tACRCodeAnatomical_aid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tACRCodeAnatomical_aid] ON [dbo].[tbACRCodeAnatomical]
(
	[AID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tACRCodePathological_ap]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tACRCodePathological_ap] ON [dbo].[tbAcrCodePathological]
(
	[AID] ASC,
	[PID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tACRCodeSubAnatomical_aid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tACRCodeSubAnatomical_aid] ON [dbo].[tbAcrCodeSubAnatomical]
(
	[AID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tActivityLog_eventdt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tActivityLog_eventdt] ON [dbo].[tbActivityLog]
(
	[EventDt] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tarchiveevent_createdt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tarchiveevent_createdt] ON [dbo].[tbArchiveEvent]
(
	[CreateDt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tbookingtimesync_begindt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tbookingtimesync_begindt] ON [dbo].[tbBookingTimeSync]
(
	[BeginDt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tcharge_over]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tcharge_over] ON [dbo].[tbCharge]
(
	[ProcedureCode] ASC,
	[ChargeType] ASC,
	[Charge] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tconfigdic_orderingpos]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tconfigdic_orderingpos] ON [dbo].[tbConfigDic]
(
	[OrderingPos] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tERequisition_applydate]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tERequisition_applydate] ON [dbo].[tbERequisition]
(
	[ApplyDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tGridColumn_sorting]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tGridColumn_sorting] ON [dbo].[tbGridColumn]
(
	[Sorting] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tgridcolumnoption_listname]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tgridcolumnoption_listname] ON [dbo].[tbGridColumnOption]
(
	[ListName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_gwdataindex_datadt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_gwdataindex_datadt] ON [dbo].[tbGwDataIndex]
(
	[DATA_DT] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_gworder_datadt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_gworder_datadt] ON [dbo].[tbGwOrder]
(
	[DATA_DT] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_gwpatient_datadt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_gwpatient_datadt] ON [dbo].[tbGwPatient]
(
	[DATA_DT] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_gwreport_datadt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_gwreport_datadt] ON [dbo].[tbGwReport]
(
	[DATA_DT] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_tMessageConfig_EventMessage]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [IX_tMessageConfig_EventMessage] ON [dbo].[tbMessageConfig]
(
	[EventType] ASC,
	[MessageType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tModalityPlan_startdt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tModalityPlan_startdt] ON [dbo].[tbModalityPlan]
(
	[MPGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tPhraseTemplate_modalitytype]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tPhraseTemplate_modalitytype] ON [dbo].[tbPhraseTemplate]
(
	[ModalityType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tprinttemplate_type]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tprinttemplate_type] ON [dbo].[tbPrintTemplate]
(
	[Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tregpatient_createdt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tregpatient_createdt] ON [dbo].[tbRegPatient]
(
	[CreateDt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tregprocedure_registerdt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tregprocedure_registerdt] ON [dbo].[tbRegProcedure]
(
	[RegisterDt] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_treport_createdt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_treport_createdt] ON [dbo].[tbReport]
(
	[CreateDt] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tReportFile_filetype]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tReportFile_filetype] ON [dbo].[tbReportFile]
(
	[fileType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tReportPrintLog_printdt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tReportPrintLog_printdt] ON [dbo].[tbReportPrintLog]
(
	[PrintDt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_treporttemplate_modalitytype]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_treporttemplate_modalitytype] ON [dbo].[tbReportTemplate]
(
	[ModalityType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tReportTemplateDirec_parentid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tReportTemplateDirec_parentid] ON [dbo].[tbReportTemplateDirec]
(
	[ParentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_trequisition_accno]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_trequisition_accno] ON [dbo].[tbRequisition]
(
	[AccNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tShortcut_category]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tShortcut_category] ON [dbo].[tbShortcut]
(
	[Category] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_tSignedHistory_CreateDt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [IX_tSignedHistory_CreateDt] ON [dbo].[tbSignedHistory]
(
	[CreateDt] ASC,
	[Creater] ASC,
	[IsSigned] ASC,
	[Action] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tteaching_submitdt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tteaching_submitdt] ON [dbo].[tbTeaching]
(
	[SubmitDt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_clu_workingCalendar]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_clu_workingCalendar] ON [dbo].[tbWorkingCalendar]
(
	[Date] ASC,
	[Modality] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tWorkTime_startdt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE CLUSTERED INDEX [ix_tWorkTime_startdt] ON [dbo].[tbWorkTime]
(
	[StartDt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tAccessionNumberList_accno]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tAccessionNumberList_accno] ON [dbo].[tbAccessionNumberList]
(
	[AccNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_taccessionnumberlist_hisid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_taccessionnumberlist_hisid] ON [dbo].[tbAccessionNumberList]
(
	[HisID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tAccessionNumberList_orderguid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tAccessionNumberList_orderguid] ON [dbo].[tbAccessionNumberList]
(
	[OrderGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tAccessionNumberList_patientguid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tAccessionNumberList_patientguid] ON [dbo].[tbAccessionNumberList]
(
	[PatientGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tACRCodeSubAnatomical_sid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tACRCodeSubAnatomical_sid] ON [dbo].[tbAcrCodeSubAnatomical]
(
	[SID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tACRCodeSubPathological_aid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tACRCodeSubPathological_aid] ON [dbo].[tbAcrCodeSubPathological]
(
	[AID] ASC,
	[PID] ASC,
	[SID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tactivitylog_alguid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tactivitylog_alguid] ON [dbo].[tbActivityLog]
(
	[ALGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tactivitylog_eventid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tactivitylog_eventid] ON [dbo].[tbActivityLog]
(
	[EventID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_username_eventid_eventcodetype]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_username_eventid_eventcodetype] ON [dbo].[tbActivityLog]
(
	[UserName] ASC,
	[EventID] ASC,
	[EventTypeCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [tAssignmentLog_index1]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [tAssignmentLog_index1] ON [dbo].[tbAssignmentLog]
(
	[OperationType] ASC,
	[AccNo] ASC,
	[OperationDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tbookingtimesync_mm]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tbookingtimesync_mm] ON [dbo].[tbBookingTimeSync]
(
	[ModalityType] ASC,
	[Modality] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tconfigdic_configname]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tconfigdic_configname] ON [dbo].[tbConfigDic]
(
	[ConfigName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tdictionary_tag]    Script Date: 2017/8/24 11:29:43 ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_tdictionary_tag] ON [dbo].[tbDictionary]
(
	[Tag] ASC,
	[Domain] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tdictionaryvalue_pk]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tdictionaryvalue_pk] ON [dbo].[tbDictionaryValue]
(
	[Tag] ASC,
	[Value] ASC
)
INCLUDE ( 	[Text]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tdischargedsummary_patientid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tdischargedsummary_patientid] ON [dbo].[tbDischargedSummary]
(
	[PatientID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tEmergencyTemplate_templateguid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_tEmergencyTemplate_templateguid] ON [dbo].[tbEmergencyTemplate]
(
	[TemplateGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tEmployeePlan_planguid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_tEmployeePlan_planguid] ON [dbo].[tbEmployeePlan]
(
	[PlanGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tEmployeePlan_startdt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tEmployeePlan_startdt] ON [dbo].[tbEmployeePlan]
(
	[StartDt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_teventlog_createdt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_teventlog_createdt] ON [dbo].[tbEventLog]
(
	[CreateDt] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_teventlog_eventcode]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_teventlog_eventcode] ON [dbo].[tbEventLog]
(
	[EventCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_tEventLog_ReportGuid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [IX_tEventLog_ReportGuid] ON [dbo].[tbEventLog]
(
	[ReportGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_gwdataindex_dataid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_gwdataindex_dataid] ON [dbo].[tbGwDataIndex]
(
	[DATA_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_gworder_dataid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_gworder_dataid] ON [dbo].[tbGwOrder]
(
	[DATA_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_gworder_patientid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_gworder_patientid] ON [dbo].[tbGwOrder]
(
	[PATIENT_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_gwpatient_dataid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_gwpatient_dataid] ON [dbo].[tbGwPatient]
(
	[DATA_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_gwreport_dataid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_gwreport_dataid] ON [dbo].[tbGwReport]
(
	[DATA_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_tMessageConfig_PK]    Script Date: 2017/8/24 11:29:43 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_tMessageConfig_PK] ON [dbo].[tbMessageConfig]
(
	[Guid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tmodality_modalityandtype]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tmodality_modalityandtype] ON [dbo].[tbModality]
(
	[ModalityType] ASC,
	[Modality] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tpathologyreport_patientid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tpathologyreport_patientid] ON [dbo].[tbPathologyReport]
(
	[PatientID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tpathologytrack_patientid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tpathologytrack_patientid] ON [dbo].[tbPathologyTrack]
(
	[PatientID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tPatientlist_relatedid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tPatientlist_relatedid] ON [dbo].[tbPatientList]
(
	[RelatedID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tregpatientlist_globalid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tregpatientlist_globalid] ON [dbo].[tbPatientList]
(
	[GlobalID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tregpatientlist_localname]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tregpatientlist_localname] ON [dbo].[tbPatientList]
(
	[LocalName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tregpatientlist_patientguid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_tregpatientlist_patientguid] ON [dbo].[tbPatientList]
(
	[PatientGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tregpatientlist_patientid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_tregpatientlist_patientid] ON [dbo].[tbPatientList]
(
	[PatientID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tprocedurecode_over]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tprocedurecode_over] ON [dbo].[tbProcedureCode]
(
	[ModalityType] ASC,
	[ProcedureCode] ASC
)
INCLUDE ( 	[Description],
	[BodyPart],
	[CheckingItem]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tregorder_accno]    Script Date: 2017/8/24 11:29:43 ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_tregorder_accno] ON [dbo].[tbRegOrder]
(
	[AccNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tregorder_createdt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tregorder_createdt] ON [dbo].[tbRegOrder]
(
	[CreateDt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tregorder_hisid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tregorder_hisid] ON [dbo].[tbRegOrder]
(
	[HisID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tregorder_patientguid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tregorder_patientguid] ON [dbo].[tbRegOrder]
(
	[PatientGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tregorder_referralid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tregorder_referralid] ON [dbo].[tbRegOrder]
(
	[ReferralID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tregorder_updatetime]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tregorder_updatetime] ON [dbo].[tbRegOrder]
(
	[UpdateTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tregorder_visitguid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tregorder_visitguid] ON [dbo].[tbRegOrder]
(
	[VisitGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [tRegOrder_RemoteAccNo]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [tRegOrder_RemoteAccNo] ON [dbo].[tbRegOrder]
(
	[RemoteAccNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tregpatient_localname]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tregpatient_localname] ON [dbo].[tbRegPatient]
(
	[LocalName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tregpatient_patientid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_tregpatient_patientid] ON [dbo].[tbRegPatient]
(
	[PatientID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tRegPatient_relatedid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tRegPatient_relatedid] ON [dbo].[tbRegPatient]
(
	[RelatedID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tregpatient_remotepid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tregpatient_remotepid] ON [dbo].[tbRegPatient]
(
	[RemotePID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tregpatient_updatetime]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tregpatient_updatetime] ON [dbo].[tbRegPatient]
(
	[UpdateTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IDX_regp_status]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [IDX_regp_status] ON [dbo].[tbRegProcedure]
(
	[Status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tregprocedure_bookingtime]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tregprocedure_bookingtime] ON [dbo].[tbRegProcedure]
(
	[BookingBeginDt] ASC,
	[ModalityType] ASC,
	[Modality] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_tRegProcedure_currentowner]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [IX_tRegProcedure_currentowner] ON [dbo].[tbRegProcedure]
(
	[UnwrittenCurrentOwner] ASC,
	[UnwrittenPreviousOwner] ASC,
	[ModalityType] ASC,
	[IsExistImage] ASC,
	[ExamineDt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tregprocedure_examinedt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tregprocedure_examinedt] ON [dbo].[tbRegProcedure]
(
	[ExamineDt] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tregprocedure_orderguid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tregprocedure_orderguid] ON [dbo].[tbRegProcedure]
(
	[OrderGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tregprocedure_reportguid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tregprocedure_reportguid] ON [dbo].[tbRegProcedure]
(
	[ReportGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_tregprocedure_updatetime]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tregprocedure_updatetime] ON [dbo].[tbRegProcedure]
(
	[UpdateTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_treport_creater]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_treport_creater] ON [dbo].[tbReport]
(
	[Creater] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_treport_firstapprovedt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_treport_firstapprovedt] ON [dbo].[tbReport]
(
	[FirstApproveDt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_treport_keyword]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_treport_keyword] ON [dbo].[tbReport]
(
	[KeyWord] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_treport_submitdt]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_treport_submitdt] ON [dbo].[tbReport]
(
	[SubmitDt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_treport_updatetime]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_treport_updatetime] ON [dbo].[tbReport]
(
	[UpdateTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_treportdelpool_reportguid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_treportdelpool_reportguid] ON [dbo].[tbReportDelPool]
(
	[ReportGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_treportlist_reportguid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_treportlist_reportguid] ON [dbo].[tbReportList]
(
	[ReportGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tReportPrintLog_reportguid]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tReportPrintLog_reportguid] ON [dbo].[tbReportPrintLog]
(
	[ReportGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_treporttemplate_templatename]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_treporttemplate_templatename] ON [dbo].[tbReportTemplate]
(
	[TemplateName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO

/****** Object:  Index [ix_trequisition_updatetime]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_trequisition_updatetime] ON [dbo].[tbRequisition]
(
	[UpdateTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tShortcut_owner]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tShortcut_owner] ON [dbo].[tbShortcut]
(
	[Owner] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_tSignedHistory_RptGuid_Act_CertSn]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [IX_tSignedHistory_RptGuid_Act_CertSn] ON [dbo].[tbSignedHistory]
(
	[ReportGuid] ASC,
	[Action] ASC,
	[CertSN] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tsystemprofile_over]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tsystemprofile_over] ON [dbo].[tbSystemProfile]
(
	[Name] ASC,
	[ModuleID] ASC
)
INCLUDE ( 	[Value]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tteaching_filetype]    Script Date: 2017/8/24 11:29:43 ******/
CREATE NONCLUSTERED INDEX [ix_tteaching_filetype] ON [dbo].[tbTeaching]
(
	[TeachingGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_tuserprofile_nmru]    Script Date: 2017/8/24 11:29:43 ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_tuserprofile_nmru] ON [dbo].[tbUserProfile]
(
	[Name] ASC,
	[ModuleID] ASC,
	[RoleName] ASC,
	[UserGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [PXML_tRegOrder_OrderMessage]    Script Date: 2017/8/24 11:29:43 ******/
CREATE PRIMARY XML INDEX [PXML_tRegOrder_OrderMessage] ON [dbo].[tbRegOrder]
(
	[OrderMessage]
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [IXML_tRegOrder_OrderMessage_Path]    Script Date: 2017/8/24 11:29:43 ******/
CREATE XML INDEX [IXML_tRegOrder_OrderMessage_Path] ON [dbo].[tbRegOrder]
(
	[OrderMessage]
)
USING XML INDEX [PXML_tRegOrder_OrderMessage] FOR PATH WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [IXML_tRegOrder_OrderMessage_Property]    Script Date: 2017/8/24 11:29:43 ******/
CREATE XML INDEX [IXML_tRegOrder_OrderMessage_Property] ON [dbo].[tbRegOrder]
(
	[OrderMessage]
)
USING XML INDEX [PXML_tRegOrder_OrderMessage] FOR PROPERTY WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [IXML_tRegOrder_OrderMessage_Value]    Script Date: 2017/8/24 11:29:43 ******/
CREATE XML INDEX [IXML_tRegOrder_OrderMessage_Value] ON [dbo].[tbRegOrder]
(
	[OrderMessage]
)
USING XML INDEX [PXML_tRegOrder_OrderMessage] FOR VALUE WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO
/****** Object:  FullTextIndex     Script Date: 2017/8/24 11:29:43 ******/
CREATE FULLTEXT INDEX ON [dbo].[tbReport](
[KeyWord] LANGUAGE [Simplified Chinese], 
[ReportText] LANGUAGE [Simplified Chinese], 
[WYGText] LANGUAGE [Simplified Chinese], 
[WYSText] LANGUAGE [Simplified Chinese])
KEY INDEX [PK_Reports]ON ([ReportFullText], FILEGROUP [PRIMARY])
WITH (CHANGE_TRACKING = AUTO, STOPLIST = SYSTEM)


GO
ALTER TABLE [dbo].[tbAccessionNumberList] ADD  DEFAULT (newid()) FOR [ANLGuid]
GO
ALTER TABLE [dbo].[tbACRCodeAnatomical] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbACRCodeAnatomical] ADD  DEFAULT (newid()) FOR [UniqueID]
GO
ALTER TABLE [dbo].[tbAcrCodePathological] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbAcrCodePathological] ADD  DEFAULT (newid()) FOR [UniqueID]
GO
ALTER TABLE [dbo].[tbAcrCodeSubAnatomical] ADD  DEFAULT ((0)) FOR [IsUserAdd]
GO
ALTER TABLE [dbo].[tbAcrCodeSubAnatomical] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbAcrCodeSubAnatomical] ADD  DEFAULT (newid()) FOR [UniqueID]
GO
ALTER TABLE [dbo].[tbAcrCodeSubPathological] ADD  DEFAULT ((0)) FOR [IsUserAdd]
GO
ALTER TABLE [dbo].[tbAcrCodeSubPathological] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbAcrCodeSubPathological] ADD  DEFAULT (newid()) FOR [UniqueID]
GO
ALTER TABLE [dbo].[tbActivityLog] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbApplyDept] ADD  DEFAULT (newid()) FOR [ID]
GO
ALTER TABLE [dbo].[tbApplyDoctor] ADD  DEFAULT (newid()) FOR [ID]
GO
ALTER TABLE [dbo].[tbArchiveErrorLog] ADD  DEFAULT (getdate()) FOR [CreateDt]
GO
ALTER TABLE [dbo].[tbArchiveEvent] ADD  DEFAULT (newid()) FOR [AEGuid]
GO
ALTER TABLE [dbo].[tbArchiveEvent] ADD  DEFAULT (getdate()) FOR [CreateDt]
GO
ALTER TABLE [dbo].[tbAssignmentLog] ADD  DEFAULT ((0)) FOR [Weight]
GO
ALTER TABLE [dbo].[tbAssignmentLog] ADD  DEFAULT ('') FOR [ProcedureGuid]
GO
ALTER TABLE [dbo].[tbBillBoard] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbBillBoardOperation] ADD  CONSTRAINT [DF_tBillBoardOperation_Count]  DEFAULT ((0)) FOR [Counts]
GO
ALTER TABLE [dbo].[tbBillBoardOperation] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbBodyPartList] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbBodySystemMap] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbBodySystemMap] ADD  DEFAULT (newid()) FOR [UniqueID]
GO
ALTER TABLE [dbo].[tbBodySystemMap] ADD  DEFAULT ('') FOR [Site]
GO
ALTER TABLE [dbo].[tbBookingNoticeTemplate] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbBookingTimeSync] ADD  DEFAULT ('') FOR [Owner]
GO
ALTER TABLE [dbo].[tbBookingTimeSync] ADD  DEFAULT ((0)) FOR [IsOrg]
GO
ALTER TABLE [dbo].[tbCharge] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbChargeItem] ADD  DEFAULT ((0)) FOR [Price]
GO
ALTER TABLE [dbo].[tbConditionColumn] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbConditionColumn] ADD  DEFAULT ('') FOR [Group]
GO
ALTER TABLE [dbo].[tbConfigDic] ADD  DEFAULT ((0)) FOR [Exportable]
GO
ALTER TABLE [dbo].[tbConfigDic] ADD  DEFAULT ((0)) FOR [Inheritance]
GO
ALTER TABLE [dbo].[tbConfigDic] ADD  DEFAULT ((0)) FOR [PropertyType]
GO
ALTER TABLE [dbo].[tbConfigDic] ADD  DEFAULT ((0)) FOR [IsHidden]
GO
ALTER TABLE [dbo].[tbConfigDic] ADD  DEFAULT ((0)) FOR [Type]
GO
ALTER TABLE [dbo].[tbConfigDic] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbConfigDic] ADD  DEFAULT ((0)) FOR [ShowInWeb]
GO
ALTER TABLE [dbo].[tbConsultation] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbConsultation] ADD  DEFAULT ('') FOR [cstRequestUserId]
GO
ALTER TABLE [dbo].[tbConsultation] ADD  DEFAULT ('') FOR [cstDiagnosisRequestId]
GO
ALTER TABLE [dbo].[tbConsultation] ADD  DEFAULT ('') FOR [cstImpression]
GO
ALTER TABLE [dbo].[tbConsultation] ADD  DEFAULT ('') FOR [cstInterpretation]
GO
ALTER TABLE [dbo].[tbConsultation] ADD  DEFAULT ('') FOR [cstKeywords]
GO
ALTER TABLE [dbo].[tbConsultation] ADD  DEFAULT ('') FOR [cstIsPositive]
GO
ALTER TABLE [dbo].[tbConsultation] ADD  DEFAULT ('') FOR [cstReportComment]
GO
ALTER TABLE [dbo].[tbDictionary] ADD  DEFAULT ((0)) FOR [IsHidden]
GO
ALTER TABLE [dbo].[tbDictionary] ADD  DEFAULT ((10)) FOR [Length]
GO
ALTER TABLE [dbo].[tbDictionary] ADD  DEFAULT ((1)) FOR [IsExport]
GO
ALTER TABLE [dbo].[tbDictionary] ADD  DEFAULT ((64)) FOR [DescLength]
GO
ALTER TABLE [dbo].[tbDictionary] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbDictionaryValue] ADD  DEFAULT ((0)) FOR [IsDefault]
GO
ALTER TABLE [dbo].[tbDictionaryValue] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbDictionaryValue] ADD  DEFAULT (newid()) FOR [UniqueID]
GO
ALTER TABLE [dbo].[tbDischargedSummary] ADD  DEFAULT (newsequentialid()) FOR [SummaryID]
GO
ALTER TABLE [dbo].[tbDischargedSummary] ADD  DEFAULT (getdate()) FOR [GenerateDt]
GO
ALTER TABLE [dbo].[tbDomainList] ADD  DEFAULT ((0)) FOR [Tab]
GO
ALTER TABLE [dbo].[tbEmergencyTemplate] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbEmergencyTemplate] ADD  DEFAULT ('') FOR [Site]
GO
ALTER TABLE [dbo].[tbEmployeePlan] ADD  DEFAULT ((0)) FOR [TemplateMark]
GO
ALTER TABLE [dbo].[tbEmployeePlan] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbERequisition] ADD  DEFAULT (newid()) FOR [Guid]
GO
ALTER TABLE [dbo].[tbERequisition] ADD  DEFAULT ('Pending') FOR [Status]
GO
ALTER TABLE [dbo].[tbERequisition] ADD  DEFAULT (getdate()) FOR [ApplyDate]
GO
ALTER TABLE [dbo].[tbERequisition] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbERequisition] ADD  DEFAULT ((0)) FOR [IsCharge]
GO
ALTER TABLE [dbo].[tbErrorTable] ADD  DEFAULT (getdate()) FOR [CreateDt]
GO
ALTER TABLE [dbo].[tbEventLog] ADD  DEFAULT (getdate()) FOR [CreateDt]
GO
ALTER TABLE [dbo].[tbEventLog] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbExamineTemplate] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbExamineTemplate] ADD  DEFAULT ('') FOR [Site]
GO
ALTER TABLE [dbo].[tbExportTemplate] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbFilmPrintLog] ADD  DEFAULT ((1)) FOR [PrintTimes]
GO
ALTER TABLE [dbo].[tbFilmPrintLog] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbFilmReserved] ADD  DEFAULT (newid()) FOR [ReservedID]
GO
ALTER TABLE [dbo].[tbFilmReserved] ADD  DEFAULT (getdate()) FOR [OperateDt]
GO
ALTER TABLE [dbo].[tbFilmScoring] ADD  DEFAULT ((0)) FOR [hFilmsCount]
GO
ALTER TABLE [dbo].[tbFilmScoring] ADD  DEFAULT ((-1)) FOR [Grade]
GO
ALTER TABLE [dbo].[tbFilmScoring] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbFilmStore] ADD  DEFAULT (newid()) FOR [FilmID]
GO
ALTER TABLE [dbo].[tbFilmStore] ADD  DEFAULT (getdate()) FOR [CreateDt]
GO
ALTER TABLE [dbo].[tbGridColumn] ADD  DEFAULT ('') FOR [UserGuid]
GO
ALTER TABLE [dbo].[tbGridColumn] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbGridColumnOption] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbGwDataIndex] ADD  DEFAULT ('RIS') FOR [RECORD_INDEX_3]
GO
ALTER TABLE [dbo].[tbGwDataIndex] ADD  DEFAULT ('') FOR [RECORD_INDEX_4]
GO
ALTER TABLE [dbo].[tbGwDataIndex] ADD  DEFAULT ('0') FOR [PROCESS_FLAG]
GO
ALTER TABLE [dbo].[tbIcd10] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbIcd10] ADD  DEFAULT (newid()) FOR [UniqueID]
GO
ALTER TABLE [dbo].[tbIdMaxValue] ADD  DEFAULT ((0)) FOR [Value]
GO
ALTER TABLE [dbo].[tbIdMaxValue] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbIdRecycleBin] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbInspectionScoreSettings] ADD  DEFAULT ((1)) FOR [Type]
GO
ALTER TABLE [dbo].[tbInspectionScoreSettings] ADD  DEFAULT ((0)) FOR [IsCurrent]
GO
ALTER TABLE [dbo].[tbInspectionScoreSettings] ADD  DEFAULT ('') FOR [Settings]
GO
ALTER TABLE [dbo].[tbInspectionScoreSettings] ADD  DEFAULT ('') FOR [Site]
GO
ALTER TABLE [dbo].[tbInspectionScoreSettings] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbKeyPerformanceRating] ADD  DEFAULT (newid()) FOR [ID]
GO
ALTER TABLE [dbo].[tbKnowledge] ADD  DEFAULT ((0)) FOR [NodeOrder]
GO
ALTER TABLE [dbo].[tbKnowledge] ADD  DEFAULT ((0)) FOR [IsLink]
GO
ALTER TABLE [dbo].[tbKnowledge] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbKnowledgeFiles] ADD  DEFAULT ((0)) FOR [NodeOrder]
GO
ALTER TABLE [dbo].[tbKnowledgeFiles] ADD  DEFAULT ((0)) FOR [IsLink]
GO
ALTER TABLE [dbo].[tbKnowledgeFiles] ADD  DEFAULT ('') FOR [LinkToGuid]
GO
ALTER TABLE [dbo].[tbKnowledgeFiles] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbKnowledgeFiles] ADD  DEFAULT (getdate()) FOR [CreateDt]
GO
ALTER TABLE [dbo].[tbLeaveSound] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbMedicineStoreLog] ADD  DEFAULT (newid()) FOR [MedicineGuid]
GO
ALTER TABLE [dbo].[tbMessageConfig] ADD  DEFAULT ('') FOR [ReceiveObject]
GO
ALTER TABLE [dbo].[tbMessageConfig] ADD  DEFAULT ((0)) FOR [RetryTimes]
GO
ALTER TABLE [dbo].[tbMessageConfig] ADD  DEFAULT ((60)) FOR [RetryTimeInterval]
GO
ALTER TABLE [dbo].[tbModality] ADD  DEFAULT ((1000)) FOR [MaxLoad]
GO
ALTER TABLE [dbo].[tbModality] ADD  DEFAULT ((0)) FOR [BookingShowMode]
GO
ALTER TABLE [dbo].[tbModality] ADD  DEFAULT ((0)) FOR [ApplyHaltPeriod]
GO
ALTER TABLE [dbo].[tbModality] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbModality] ADD  DEFAULT ('') FOR [WorkStationIP]
GO
ALTER TABLE [dbo].[tbModalityPlan] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbModalityShare] ADD  DEFAULT ((1)) FOR [TargetType]
GO
ALTER TABLE [dbo].[tbModalityTimeSlice] ADD  DEFAULT ((1000)) FOR [MaxNumber]
GO
ALTER TABLE [dbo].[tbModalityTimeSlice] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbModalityType] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbModalityType] ADD  DEFAULT (newid()) FOR [UniqueID]
GO
ALTER TABLE [dbo].[tbModalityType] ADD  DEFAULT ('') FOR [Site]
GO
ALTER TABLE [dbo].[tbModule] ADD  DEFAULT (' ') FOR [Title]
GO
ALTER TABLE [dbo].[tbModule] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbOnlineClient] ADD  DEFAULT ((0)) FOR [UserGuid]
GO
ALTER TABLE [dbo].[tbOnlineClient] ADD  DEFAULT ((0)) FOR [MachineIP]
GO
ALTER TABLE [dbo].[tbOnlineClient] ADD  DEFAULT ((0)) FOR [IsOnline]
GO
ALTER TABLE [dbo].[tbOnlineClient] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbOrderCharge] ADD  DEFAULT ((0)) FOR [Confirm]
GO
ALTER TABLE [dbo].[tbOrderCharge] ADD  DEFAULT ((10)) FOR [Deduct]
GO
ALTER TABLE [dbo].[tbOrderCharge] ADD  DEFAULT ((20)) FOR [Refund]
GO
ALTER TABLE [dbo].[tbOrderCharge] ADD  DEFAULT ((30)) FOR [Cancel]
GO
ALTER TABLE [dbo].[tbOrderCharge] ADD  DEFAULT (getdate()) FOR [CreateDt]
GO
ALTER TABLE [dbo].[tbPanel] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbPathologyReport] ADD  DEFAULT (newsequentialid()) FOR [PathReportID]
GO
ALTER TABLE [dbo].[tbPathologyReport] ADD  DEFAULT (getdate()) FOR [GenerateDt]
GO
ALTER TABLE [dbo].[tbPathologyTrack] ADD  DEFAULT (newsequentialid()) FOR [PathologyID]
GO
ALTER TABLE [dbo].[tbPathologyTrack] ADD  DEFAULT (getdate()) FOR [CreateDt]
GO
ALTER TABLE [dbo].[tbPathologyTrack] ADD  DEFAULT ((0)) FOR [Teaching]
GO
ALTER TABLE [dbo].[tbPathologyTrack] ADD  DEFAULT ((0)) FOR [Research]
GO
ALTER TABLE [dbo].[tbPatientList] ADD  DEFAULT (newid()) FOR [PLGuid]
GO
ALTER TABLE [dbo].[tbPatientList] ADD  DEFAULT ('') FOR [LocalName]
GO
ALTER TABLE [dbo].[tbPatientList] ADD  DEFAULT ('') FOR [EnglishName]
GO
ALTER TABLE [dbo].[tbPatientList] ADD  DEFAULT ('') FOR [ReferenceNo]
GO
ALTER TABLE [dbo].[tbPatientList] ADD  DEFAULT ('') FOR [Gender]
GO
ALTER TABLE [dbo].[tbPatientList] ADD  DEFAULT ('') FOR [Address]
GO
ALTER TABLE [dbo].[tbPatientList] ADD  DEFAULT ('') FOR [Telephone]
GO
ALTER TABLE [dbo].[tbPatientList] ADD  DEFAULT ((0)) FOR [IsVIP]
GO
ALTER TABLE [dbo].[tbPatientList] ADD  DEFAULT (getdate()) FOR [CreateDt]
GO
ALTER TABLE [dbo].[tbPatientList] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbPatientList] ADD  DEFAULT ((0)) FOR [Archive]
GO
ALTER TABLE [dbo].[tbPatientList] ADD  DEFAULT (getdate()) FOR [UpdateTime]
GO
ALTER TABLE [dbo].[tbPatientList] ADD  DEFAULT ((0)) FOR [Uploaded]
GO
ALTER TABLE [dbo].[tbPatientList] ADD  DEFAULT ((0)) FOR [Allergic]
GO
ALTER TABLE [dbo].[tbPeopleSchedule] ADD  DEFAULT ('') FOR [Site]
GO
ALTER TABLE [dbo].[tbPeopleSchedule] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbPhraseTemplate] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbPrintTemplate] ADD  DEFAULT ((0)) FOR [IsDefaultByType]
GO
ALTER TABLE [dbo].[tbPrintTemplate] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbPrintTemplate] ADD  DEFAULT ('') FOR [Site]
GO
ALTER TABLE [dbo].[tbPrintTemplateFields] ADD  DEFAULT ('') FOR [SubType]
GO
ALTER TABLE [dbo].[tbPrintTemplateFields] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbPrintTemplateFields] ADD  DEFAULT (newid()) FOR [UniqueID]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ((0.0)) FOR [Charge]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ((0)) FOR [Frequency]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ((10)) FOR [Duration]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ('') FOR [FilmSpec]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ((0)) FOR [FilmCount]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ('') FOR [ContrastName]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ('') FOR [ContrastDose]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ((0)) FOR [ImageCount]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ((0)) FOR [ExposalCount]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ('') FOR [BookingNotice]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ('') FOR [ShortcutCode]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ((1)) FOR [Effective]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ((0)) FOR [Externals]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT (newid()) FOR [UniqueID]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  CONSTRAINT [DF_tProcedureCode_Weight]  DEFAULT ((1)) FOR [TechnicianWeight]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ((1)) FOR [RadiologistWeight]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ((1)) FOR [ApprovedRadiologistWeight]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ('') FOR [Site]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ('') FOR [ClinicalModality]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ((0)) FOR [Puncture]
GO
ALTER TABLE [dbo].[tbProcedureCode] ADD  DEFAULT ((0)) FOR [Radiography]
GO
ALTER TABLE [dbo].[tbQualityScoring] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbQuery] ADD  DEFAULT ('') FOR [LinkStr]
GO
ALTER TABLE [dbo].[tbQuery] ADD  DEFAULT ('') FOR [XColumnName]
GO
ALTER TABLE [dbo].[tbQuery] ADD  DEFAULT ('') FOR [YColumnName]
GO
ALTER TABLE [dbo].[tbQuery] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbQuery] ADD  DEFAULT ('') FOR [Site]
GO
ALTER TABLE [dbo].[tbQueryCondition] ADD  DEFAULT ('') FOR [Name]
GO
ALTER TABLE [dbo].[tbQueryCondition] ADD  DEFAULT ('') FOR [Field]
GO
ALTER TABLE [dbo].[tbQueryCondition] ADD  DEFAULT ('') FOR [CompareStrOptions]
GO
ALTER TABLE [dbo].[tbQueryCondition] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbQueryConditionShortCut] ADD  DEFAULT ('') FOR [CompareStr]
GO
ALTER TABLE [dbo].[tbQueryConditionShortCut] ADD  DEFAULT ('') FOR [Value]
GO
ALTER TABLE [dbo].[tbQueryConditionShortCut] ADD  DEFAULT ('') FOR [DirKey]
GO
ALTER TABLE [dbo].[tbQueryConditionShortCut] ADD  DEFAULT ((1)) FOR [IsSelected]
GO
ALTER TABLE [dbo].[tbQueryConditionShortCut] ADD  DEFAULT ((0)) FOR [IsNot]
GO
ALTER TABLE [dbo].[tbQueryConditionShortCut] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbQueryResultColumn] ADD  DEFAULT ('') FOR [FieldName]
GO
ALTER TABLE [dbo].[tbQueryResultColumn] ADD  DEFAULT ('') FOR [ColumnName]
GO
ALTER TABLE [dbo].[tbQueryResultColumn] ADD  DEFAULT ((0)) FOR [AggregateEnum]
GO
ALTER TABLE [dbo].[tbQueryResultColumn] ADD  DEFAULT ((-1)) FOR [LevelNo]
GO
ALTER TABLE [dbo].[tbQueryResultColumn] ADD  DEFAULT ((0)) FOR [SequenceNo]
GO
ALTER TABLE [dbo].[tbQueryResultColumn] ADD  DEFAULT ((-1)) FOR [AggregateOnIndex]
GO
ALTER TABLE [dbo].[tbQueryResultColumn] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbRandomInspection] ADD  DEFAULT (newid()) FOR [ID]
GO
ALTER TABLE [dbo].[tbRegOrder] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbRegOrder] ADD  DEFAULT ((0)) FOR [IsReferral]
GO
ALTER TABLE [dbo].[tbRegOrder] ADD  DEFAULT ((10)) FOR [Priority]
GO
ALTER TABLE [dbo].[tbRegOrder] ADD  DEFAULT ((0)) FOR [IsCharge]
GO
ALTER TABLE [dbo].[tbRegOrder] ADD  DEFAULT ((0)) FOR [Bedside]
GO
ALTER TABLE [dbo].[tbRegOrder] ADD  DEFAULT ((0)) FOR [IsFilmSent]
GO
ALTER TABLE [dbo].[tbRegOrder] ADD  DEFAULT ((0)) FOR [FilmFee]
GO
ALTER TABLE [dbo].[tbRegOrder] ADD  DEFAULT ((0)) FOR [ThreeDRebuild]
GO
ALTER TABLE [dbo].[tbRegOrder] ADD  DEFAULT ('') FOR [CurrentSite]
GO
ALTER TABLE [dbo].[tbRegOrder] ADD  DEFAULT (getdate()) FOR [UpdateTime]
GO
ALTER TABLE [dbo].[tbRegOrder] ADD  DEFAULT ((0)) FOR [Uploaded]
GO
ALTER TABLE [dbo].[tbRegOrder] ADD  DEFAULT ((0)) FOR [EFilmNumber]
GO
ALTER TABLE [dbo].[tbRegOrder] ADD  DEFAULT ((0)) FOR [TerminalCheckinPrintNumber]
GO
ALTER TABLE [dbo].[tbRegPatient] ADD  DEFAULT ('') FOR [LocalName]
GO
ALTER TABLE [dbo].[tbRegPatient] ADD  DEFAULT ('') FOR [EnglishName]
GO
ALTER TABLE [dbo].[tbRegPatient] ADD  DEFAULT ('') FOR [ReferenceNo]
GO
ALTER TABLE [dbo].[tbRegPatient] ADD  DEFAULT ('') FOR [Gender]
GO
ALTER TABLE [dbo].[tbRegPatient] ADD  DEFAULT ('') FOR [Address]
GO
ALTER TABLE [dbo].[tbRegPatient] ADD  DEFAULT ('') FOR [Telephone]
GO
ALTER TABLE [dbo].[tbRegPatient] ADD  DEFAULT ((0)) FOR [IsVIP]
GO
ALTER TABLE [dbo].[tbRegPatient] ADD  DEFAULT (getdate()) FOR [CreateDt]
GO
ALTER TABLE [dbo].[tbRegPatient] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbRegPatient] ADD  DEFAULT ('') FOR [RelatedID]
GO
ALTER TABLE [dbo].[tbRegPatient] ADD  DEFAULT (getdate()) FOR [UpdateTime]
GO
ALTER TABLE [dbo].[tbRegPatient] ADD  DEFAULT ((0)) FOR [Uploaded]
GO
ALTER TABLE [dbo].[tbRegPatient] ADD  DEFAULT ((0)) FOR [IsAllergic]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  DEFAULT ((180)) FOR [WarningTime]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  DEFAULT ((0)) FOR [FilmCount]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  DEFAULT ((0)) FOR [ImageCount]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  DEFAULT ((0)) FOR [ExposalCount]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  DEFAULT ((0)) FOR [Charge]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  DEFAULT ((0)) FOR [Priority]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  DEFAULT ((0)) FOR [IsPost]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  DEFAULT ((0)) FOR [IsExistImage]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  DEFAULT ((0)) FOR [IsCharge]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  DEFAULT ('') FOR [RemoteRPID]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  CONSTRAINT [Relationship188]  DEFAULT ((0)) FOR [Optional1]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  DEFAULT (getdate()) FOR [CreateDt]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  DEFAULT (getdate()) FOR [UpdateTime]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  DEFAULT ((0)) FOR [Uploaded]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  DEFAULT ('') FOR [BodyCategory]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  DEFAULT ('') FOR [Bodypart]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  DEFAULT ('') FOR [CheckingItem]
GO
ALTER TABLE [dbo].[tbRegProcedure] ADD  DEFAULT ('') FOR [RPDesc]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ((0)) FOR [IsPositive]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT (getdate()) FOR [CreateDt]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ((0)) FOR [IsDiagnosisRight]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ((0)) FOR [DeleteMark]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ((0)) FOR [IsPrint]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ((0)) FOR [IsLeaveWord]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ((0)) FOR [IsDraw]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ((0)) FOR [IsLeaveSound]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ((0)) FOR [PrintCopies]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ((0)) FOR [ReadOnly]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT (getdate()) FOR [UpdateTime]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ((0)) FOR [Uploaded]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ((0)) FOR [TerminalReportPrintNumber]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ('') FOR [ScoringVersion]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ('') FOR [AccordRate]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ('') FOR [SubmitterSign]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ('') FOR [FirstApproverSign]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ('') FOR [SecondApproverSign]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ('') FOR [SubmitterSignTimeStamp]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ('') FOR [FirstApproverSignTimeStamp]
GO
ALTER TABLE [dbo].[tbReport] ADD  DEFAULT ('') FOR [SecondApproverSignTimeStamp]
GO
ALTER TABLE [dbo].[tbReportDelPool] ADD  DEFAULT ((0)) FOR [PrintCopies]
GO
ALTER TABLE [dbo].[tbReportDelPool] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbReportDelPool] ADD  DEFAULT ((0)) FOR [ReadOnly]
GO
ALTER TABLE [dbo].[tbReportDelPool] ADD  DEFAULT (getdate()) FOR [UpdateTime]
GO
ALTER TABLE [dbo].[tbReportDelPool] ADD  DEFAULT ((0)) FOR [Uploaded]
GO
ALTER TABLE [dbo].[tbReportDelPool] ADD  DEFAULT ((0)) FOR [TerminalReportPrintNumber]
GO
ALTER TABLE [dbo].[tbReportDelPool] ADD  DEFAULT ('') FOR [ScoringVersion]
GO
ALTER TABLE [dbo].[tbReportDelPool] ADD  DEFAULT ('') FOR [AccordRate]
GO
ALTER TABLE [dbo].[tbReportDelPool] ADD  DEFAULT ('') FOR [SubmitterSign]
GO
ALTER TABLE [dbo].[tbReportDelPool] ADD  DEFAULT ('') FOR [FirstApproverSign]
GO
ALTER TABLE [dbo].[tbReportDelPool] ADD  DEFAULT ('') FOR [SecondApproverSign]
GO
ALTER TABLE [dbo].[tbReportDelPool] ADD  DEFAULT ('') FOR [SubmitterSignTimeStamp]
GO
ALTER TABLE [dbo].[tbReportDelPool] ADD  DEFAULT ('') FOR [FirstApproverSignTimeStamp]
GO
ALTER TABLE [dbo].[tbReportDelPool] ADD  DEFAULT ('') FOR [SecondApproverSignTimeStamp]
GO
ALTER TABLE [dbo].[tbReportDoctor] ADD  DEFAULT ((100)) FOR [MaxAssignedPercentage]
GO
ALTER TABLE [dbo].[tbReportDoctor] ADD  DEFAULT ('-1') FOR [MaxHoldWeightToday]
GO
ALTER TABLE [dbo].[tbReportFile] ADD  DEFAULT (getdate()) FOR [CreateDt]
GO
ALTER TABLE [dbo].[tbReportFile] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbReportList] ADD  DEFAULT ((0)) FOR [IsPositive]
GO
ALTER TABLE [dbo].[tbReportList] ADD  DEFAULT (getdate()) FOR [CreateDt]
GO
ALTER TABLE [dbo].[tbReportList] ADD  DEFAULT ((0)) FOR [IsDiagnosisRight]
GO
ALTER TABLE [dbo].[tbReportList] ADD  DEFAULT ((0)) FOR [DeleteMark]
GO
ALTER TABLE [dbo].[tbReportList] ADD  DEFAULT ((0)) FOR [IsPrint]
GO
ALTER TABLE [dbo].[tbReportList] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbReportPrintLog] ADD  DEFAULT (getdate()) FOR [PrintDt]
GO
ALTER TABLE [dbo].[tbReportPrintLog] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbReportTemplate] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbReportTemplateDirec] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbRequisition] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbRequisition] ADD  DEFAULT (getdate()) FOR [UpdateTime]
GO
ALTER TABLE [dbo].[tbRequisition] ADD  DEFAULT ((0)) FOR [Uploaded]
GO
ALTER TABLE [dbo].[tbRequisition] ADD  DEFAULT (getdate()) FOR [Createdt]
GO
ALTER TABLE [dbo].[tbReShot] ADD  DEFAULT (getdate()) FOR [RejectDt]
GO
ALTER TABLE [dbo].[tbReShot] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbRole] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbRole] ADD  CONSTRAINT [DF_TRole_RoleID]  DEFAULT (newid()) FOR [RoleID]
GO
ALTER TABLE [dbo].[tbRole2User] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbRoleDir] ADD  CONSTRAINT [DF_TRoleDir_DirID]  DEFAULT (newid()) FOR [UniqueID]
GO
ALTER TABLE [dbo].[tbRoleProfile] ADD  CONSTRAINT [DF_tRoleProfile_Value_123]  DEFAULT ('') FOR [Value]
GO
ALTER TABLE [dbo].[tbRoleProfile] ADD  DEFAULT ((0)) FOR [Exportable]
GO
ALTER TABLE [dbo].[tbRoleProfile] ADD  DEFAULT ('') FOR [PropertyDesc]
GO
ALTER TABLE [dbo].[tbRoleProfile] ADD  DEFAULT ('') FOR [PropertyOptions]
GO
ALTER TABLE [dbo].[tbRoleProfile] ADD  DEFAULT ((0)) FOR [Inheritance]
GO
ALTER TABLE [dbo].[tbRoleProfile] ADD  DEFAULT ((0)) FOR [PropertyType]
GO
ALTER TABLE [dbo].[tbRoleProfile] ADD  DEFAULT ((0)) FOR [IsHidden]
GO
ALTER TABLE [dbo].[tbRoleProfile] ADD  DEFAULT ('0') FOR [OrderingPos]
GO
ALTER TABLE [dbo].[tbRoleProfile] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbRoleProfile] ADD  DEFAULT (newid()) FOR [UniqueID]
GO
ALTER TABLE [dbo].[tbScheduleExcelTempate] ADD  DEFAULT (newid()) FOR [GUID]
GO
ALTER TABLE [dbo].[tbScoringResult] ADD  DEFAULT ((1)) FOR [Type]
GO
ALTER TABLE [dbo].[tbScoringResult] ADD  DEFAULT ('') FOR [Result]
GO
ALTER TABLE [dbo].[tbScoringResult] ADD  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[tbScoringResult] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbScoringResult] ADD  DEFAULT ('') FOR [Result2]
GO
ALTER TABLE [dbo].[tbScoringResult] ADD  DEFAULT ('') FOR [Appraiser]
GO
ALTER TABLE [dbo].[tbScoringResult] ADD  DEFAULT ('') FOR [Comment]
GO
ALTER TABLE [dbo].[tbScoringResult] ADD  DEFAULT ('') FOR [AccordRate]
GO
ALTER TABLE [dbo].[tbScoringResult] ADD  DEFAULT ((1)) FOR [IsFinalVersion]
GO
ALTER TABLE [dbo].[tbScoringSettings] ADD  DEFAULT ((1)) FOR [Type]
GO
ALTER TABLE [dbo].[tbScoringSettings] ADD  DEFAULT ((0)) FOR [IsCurrent]
GO
ALTER TABLE [dbo].[tbScoringSettings] ADD  DEFAULT ('') FOR [Settings]
GO
ALTER TABLE [dbo].[tbScoringSettings] ADD  DEFAULT ('') FOR [Site]
GO
ALTER TABLE [dbo].[tbScoringSettings] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbShortcut] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbShowScreen] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbSignedHistory] ADD  DEFAULT ('') FOR [PatientID]
GO
ALTER TABLE [dbo].[tbSignedHistory] ADD  DEFAULT ('') FOR [AccNo]
GO
ALTER TABLE [dbo].[tbSiteList] ADD  DEFAULT ((0)) FOR [Tab]
GO
ALTER TABLE [dbo].[tbSiteProfile] ADD  DEFAULT ('') FOR [Value]
GO
ALTER TABLE [dbo].[tbSiteProfile] ADD  DEFAULT ((0)) FOR [Exportable]
GO
ALTER TABLE [dbo].[tbSiteProfile] ADD  DEFAULT ('') FOR [PropertyDesc]
GO
ALTER TABLE [dbo].[tbSiteProfile] ADD  DEFAULT ('') FOR [PropertyOptions]
GO
ALTER TABLE [dbo].[tbSiteProfile] ADD  DEFAULT ((0)) FOR [Inheritance]
GO
ALTER TABLE [dbo].[tbSiteProfile] ADD  DEFAULT ((0)) FOR [PropertyType]
GO
ALTER TABLE [dbo].[tbSiteProfile] ADD  DEFAULT ((1)) FOR [IsHidden]
GO
ALTER TABLE [dbo].[tbSiteProfile] ADD  DEFAULT ('0') FOR [OrderingPos]
GO
ALTER TABLE [dbo].[tbSiteProfile] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbSiteProfile] ADD  DEFAULT (newid()) FOR [UniqueID]
GO
ALTER TABLE [dbo].[tbSync] ADD  DEFAULT (getdate()) FOR [CreateDt]
GO
ALTER TABLE [dbo].[tbSync] ADD  DEFAULT ((1)) FOR [Counter]
GO
ALTER TABLE [dbo].[tbSync] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbSyncErrorLog] ADD  DEFAULT (getdate()) FOR [CreateDt]
GO
ALTER TABLE [dbo].[tbSystemProfile] ADD  DEFAULT ('') FOR [Value]
GO
ALTER TABLE [dbo].[tbSystemProfile] ADD  DEFAULT ((0)) FOR [Exportable]
GO
ALTER TABLE [dbo].[tbSystemProfile] ADD  DEFAULT ('') FOR [PropertyDesc]
GO
ALTER TABLE [dbo].[tbSystemProfile] ADD  DEFAULT ('') FOR [PropertyOptions]
GO
ALTER TABLE [dbo].[tbSystemProfile] ADD  DEFAULT ((0)) FOR [Inheritance]
GO
ALTER TABLE [dbo].[tbSystemProfile] ADD  DEFAULT ((0)) FOR [PropertyType]
GO
ALTER TABLE [dbo].[tbSystemProfile] ADD  DEFAULT ((1)) FOR [IsHidden]
GO
ALTER TABLE [dbo].[tbSystemProfile] ADD  DEFAULT ('0') FOR [OrderingPos]
GO
ALTER TABLE [dbo].[tbSystemProfile] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbSystemProfile] ADD  DEFAULT (newid()) FOR [UniqueID]
GO
ALTER TABLE [dbo].[tbTeaching] ADD  DEFAULT (getdate()) FOR [CreateDt]
GO
ALTER TABLE [dbo].[tbTeaching] ADD  DEFAULT ((1)) FOR [Type]
GO
ALTER TABLE [dbo].[tbTeaching] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbUser] ADD  DEFAULT ((0)) FOR [DeleteMark]
GO
ALTER TABLE [dbo].[tbUser] ADD  DEFAULT ('') FOR [DisplayName]
GO
ALTER TABLE [dbo].[tbUser] ADD  DEFAULT ((0)) FOR [InvalidLoginCount]
GO
ALTER TABLE [dbo].[tbUserCerts] ADD  DEFAULT ('') FOR [CertID]
GO
ALTER TABLE [dbo].[tbUserProfile] ADD  DEFAULT ('') FOR [Value]
GO
ALTER TABLE [dbo].[tbUserProfile] ADD  DEFAULT ((0)) FOR [Exportable]
GO
ALTER TABLE [dbo].[tbUserProfile] ADD  DEFAULT ('') FOR [PropertyDesc]
GO
ALTER TABLE [dbo].[tbUserProfile] ADD  DEFAULT ('') FOR [PropertyOptions]
GO
ALTER TABLE [dbo].[tbUserProfile] ADD  DEFAULT ((0)) FOR [Inheritance]
GO
ALTER TABLE [dbo].[tbUserProfile] ADD  DEFAULT ((0)) FOR [PropertyType]
GO
ALTER TABLE [dbo].[tbUserProfile] ADD  DEFAULT ((0)) FOR [IsHidden]
GO
ALTER TABLE [dbo].[tbUserProfile] ADD  DEFAULT ('0') FOR [OrderingPos]
GO
ALTER TABLE [dbo].[tbUserProfile] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbUserProfile] ADD  DEFAULT (newid()) FOR [UniqueID]
GO
ALTER TABLE [dbo].[tbWarningTime] ADD  DEFAULT ((180)) FOR [WarningTime]
GO
ALTER TABLE [dbo].[tbWarningTime] ADD  DEFAULT ('') FOR [Domain]
GO
ALTER TABLE [dbo].[tbWarningTime] ADD  DEFAULT (newid()) FOR [UniqueID]
GO
ALTER TABLE [dbo].[tbWebAppFunc] ADD  CONSTRAINT [DF_tablename_disabled]  DEFAULT ((0)) FOR [Disabled]
GO
ALTER TABLE [dbo].[tbWorkTime] ADD  DEFAULT ('') FOR [Domain]
GO
/****** Object:  Trigger [dbo].[DeleteBookingNoticeTemplate]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create TRIGGER [dbo].[DeleteBookingNoticeTemplate] 
   ON  [dbo].[tbBookingNoticeTemplate]
   for delete

AS 
BEGIN
	update tbProcedureCode set BookingNotice = '' where tbProcedureCode.BookingNotice in(select Guid from deleted)
END


GO
/****** Object:  Trigger [dbo].[UpdateDeleteChargeType]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE TRIGGER [dbo].[UpdateDeleteChargeType] 
   ON  [dbo].[tbDictionaryValue]
   for update,delete 
as
   set nocount on
   declare @ChargeTypeOld nvarchar(256)
   declare @ChargeType nvarchar(256)
   declare @Tag int
   select  @Tag=Tag ,@ChargeTypeOld= Value FROM deleted
   select  @ChargeType=Value FROM inserted   
	   if(@Tag <> 52)--not chargetype tag value
			return
   if update(Value) 
   BEGIN 
    update tbCharge set ChargeType = @ChargeType Where ChargeType = @ChargeTypeOld
   END
  else if(@ChargeType is null)--- only delete opreation
	BEGIN
	delete tbCharge Where ChargeType = @ChargeTypeOld
	END


GO
/****** Object:  Trigger [dbo].[triUpdateFilmReserved]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[triUpdateFilmReserved] ON [dbo].[tbFilmStore]  
for delete,update 
as 
declare @FilmID nvarchar(64)
declare @FilmSpec nvarchar(64)
declare @OperateTime datetime
declare @CreateTime datetime
declare @StoreCount int
declare @NewStoreCount int
declare @ReservedCount int
declare @NewReservedCount int
select @FilmID=FilmID,@FilmSpec=FilmSpec,@CreateTime=CreateDt,@StoreCount=FilmCount from deleted

BEGIN TRY
if not exists(select 0 from inserted)   --delete operation
begin
		
		select @OperateTime=OperateDt,@ReservedCount=ReservedCount from tbFilmReserved where FilmSpec=@FilmSpec
		if @OperateTime is null
			return; 

		if @CreateTime>@OperateTime
			return;
					

		set @NewReservedCount=@ReservedCount-@StoreCount
		
		update tbFilmReserved set ReservedCount=@NewReservedCount where FilmSpec=@FilmSpec

end
else  
begin --udpate operation	
	
		select @OperateTime=OperateDt,@ReservedCount=ReservedCount from tbFilmReserved where FilmSpec=@FilmSpec
		if @OperateTime is null
			return; 

		if @CreateTime>@OperateTime
			return;
		
		select @NewStoreCount=FilmCount from inserted	
		set @NewReservedCount=@ReservedCount-@StoreCount+@NewStoreCount
		
		update tbFilmReserved set ReservedCount=@NewReservedCount where FilmSpec=@FilmSpec

		if not exists(select 1 from tbFilmStore where FilmSpec=@FilmSpec)
			delete from tbFilmReserved where FilmSpec=@FilmSpec


end 
END TRY
BEGIN CATCH	
	rollback
	insert into tbErrorTable(errormessage) select ERROR_MESSAGE() as errormessage		
END CATCH



GO
/****** Object:  Trigger [dbo].[triBrokerXml1]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[triBrokerXml1]
   ON  [dbo].[tbGwOrder]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here

    declare @dataid nvarchar(64)
    declare @eventtype nvarchar(64)  
    declare @accessionnumber nvarchar(64)
    declare @orderno nvarchar(64)
    select @dataid=data_id,@accessionnumber =filler_no,@orderno=order_no from inserted
    if(len(@dataid)=0)
		return;
	
    select @eventtype=event_type from tbGwDataIndex where data_id=@dataid  
    
    if(len(@accessionnumber)>0)
		exec procSetBrokerXml @dataid,@eventtype,@accessionnumber,'',@orderno

END


GO
/****** Object:  Trigger [dbo].[triBrokerXml2]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[triBrokerXml2] 
   ON  [dbo].[tbGwReport]
   AFTER INSERT
AS 
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;


    -- Insert statements for trigger here
    
    declare @dataid nvarchar(64)
    declare @eventtype nvarchar(64)  
    declare @accessionnumber nvarchar(64)
    declare @reportguid nvarchar(64)
    select @dataid=data_id,@accessionnumber =ACCESSION_NUMBER,@reportguid=REPORT_NO from inserted
    if(len(@dataid)=0)
return;
    select @eventtype=event_type from tbGwDataIndex where data_id=@dataid
 
    if(len(@accessionnumber)>0)
exec procSetBrokerXml @dataid,@eventtype,@accessionnumber,@reportguid,''


END


GO
/****** Object:  Trigger [dbo].[ModifyModalityTypeName]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[ModifyModalityTypeName] 
   ON  [dbo].[tbProcedureCode]
   for update as
   if update(ModalityType) 
   BEGIN 
   declare @ModalityTypeOld nvarchar(128)
   declare @ModalityType nvarchar(128)
   declare @ProcedureCodeOld nvarchar(128)
   select  @ModalityTypeOld= ModalityType FROM deleted 
   select  @ProcedureCodeOld = ProcedureCode FROM deleted
   select  @ModalityType=ModalityType FROM inserted   
	   if(@ModalityTypeOld=@ModalityType)
			return
	   else

			BEGIN
				update tbRegProcedure set ModalityType = @ModalityType Where ModalityType = @ModalityTypeOld and ProcedureCode =@ProcedureCodeOld
			END
   END


GO
/****** Object:  Trigger [dbo].[tmpImageScore307002]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tmpImageScore307002] ON [dbo].[tbQualityScoring]
for insert,update 
as 
BEGIN TRY

	if not update(Result2)
		return
	
	declare @guid nvarchar(128)
	declare @CurStatus nvarchar(32)

	select @guid=Guid, @CurStatus=Result2 from inserted

	if @CurStatus = 'A'
		update tbQualityScoring set Result = '优质片' where Guid=@guid
	else if @CurStatus = 'B' OR @CurStatus = 'C' 
		update tbQualityScoring set Result = '合格片' where Guid=@guid
	else if @CurStatus = 'D'
		update tbQualityScoring set Result = '不合格片' where Guid=@guid
	else if @CurStatus = ''
		update tbQualityScoring set Result = '未评分' where Guid=@guid

END TRY
BEGIN CATCH
	rollback
END CATCH



GO
/****** Object:  Trigger [dbo].[triReferralNofitication]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create TRIGGER [dbo].[triReferralNofitication] ON [dbo].[tbReferralList]  
for insert,update 
as 
BEGIN TRY
  
 declare @RefStatus int
 declare @Direction int
 declare @TargetSite nvarchar(64)
 declare @CurStatus nvarchar(32)
 declare @ReferralID nvarchar(128)
 declare @SourceSite nvarchar(64)
 declare @Event xml
 
 select @RefStatus=RefStatus,@Direction = Direction,@TargetSite = TargetSite,@ReferralID = ReferralID from inserted
 if(@refStatus = null)
 return
 
 Set @Event='<Event><ReferralID>'+@ReferralID+'</ReferralID></Event>'

--@Direction:1是发起方，是接收方
--@RefStatus:5是转诊到达，是转诊完成
if(@Direction = 1 and @RefStatus = 30)
begin
	 select @SourceSite = ExamSite from tbRegOrder where referralId = @ReferralID
	 exec [procPostEvent] N'转诊通知_完成','',@Event,'3',@SourceSite
end
else if(@Direction = 0 and @RefStatus = 5)
begin
	select @SourceSite = ExamSite from tbRegOrder where referralId = @ReferralID
     exec [procPostEvent] N'转诊通知_创建','',@Event,'3',@TargetSite
end     
else 
return

END TRY
BEGIN CATCH
 rollback
 insert into tbErrorTable(errormessage) select ERROR_MESSAGE() as errormessage 
END CATCH


GO
/****** Object:  Trigger [dbo].[triApplyDept]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[triApplyDept] 
   ON [dbo].[tbRegOrder]
   AFTER UPDATE,INSERT
AS 
BEGIN
 
 SET NOCOUNT ON;
 declare @ApplyDept nvarchar(128)
 declare @ApplyDoctor nvarchar(128)
 declare @InhospitalRegion nvarchar(128)
 declare @ShortCutCode nvarchar(512)
 declare @CurrentSite nvarchar(64)
 declare @IsReferral int
 declare @IsMultipleDept int
  declare @IsMultipleDoct int
 if update(ApplyDept)
 begin
	select @ApplyDept = ApplyDept,@IsReferral=IsReferral,@CurrentSite=CurrentSite from inserted
	select @IsMultipleDept=CHARINDEX(';', @ApplyDept)
	if(@IsMultipleDept>-1) return;
	if(@CurrentSite is null) return;
	if(@IsReferral is not null and @IsReferral=1 )
		return;
	if(@ApplyDept is not null and len(@ApplyDept) >0)
    if exists(select 1 from tbApplyDept where Site = @CurrentSite)
	begin
	 if not exists(select 1 from tbApplyDept where ApplyDept =@ApplyDept and Site = @CurrentSite)
	 begin
			set @ShortCutCode = dbo.fnGetFirstPinYins(@ApplyDept)
			insert into tbApplyDept(ID,ApplyDept,Telephone,Optional1,Optional2,Optional3,ShortCutCode,Site,Domain) 
			values(newid(),@ApplyDept,'','','','',@ShortCutCode,@CurrentSite,(select value from tbSystemProfile where Name ='Domain'))
	 end
	end
	else
	begin
	 if not exists(select 1 from tbApplyDept where ApplyDept =@ApplyDept and (Site = '' or Site is null))
	 begin
			set @ShortCutCode = dbo.fnGetFirstPinYins(@ApplyDept)
			insert into tbApplyDept(ID,ApplyDept,Telephone,Optional1,Optional2,Optional3,ShortCutCode,Site,Domain) 
			values(newid(),@ApplyDept,'','','','',@ShortCutCode,'',(select value from tbSystemProfile where Name ='Domain'))
	 end
	end	 
 end
 
 if update(ApplyDoctor)
 begin
	select @ApplyDoctor = ApplyDoctor,@IsReferral=IsReferral,@CurrentSite=CurrentSite from inserted
	select @IsMultipleDoct=CHARINDEX(';', @ApplyDoctor)
	if(@IsMultipleDoct>-1) return;
	if(@CurrentSite is null) return;
	if(@IsReferral is not null and @IsReferral=1 )
		return;
	if(@ApplyDoctor is not null and len(@ApplyDoctor) >0)
	if exists(select 1 from tbApplyDoctor where Site = @CurrentSite)
	begin
	 if not exists(select 1 from tbApplyDoctor where ApplyDoctor =@ApplyDoctor and Site = @CurrentSite)
	 begin
			set @ShortCutCode = dbo.fnGetFirstPinYins(@ApplyDoctor)
			insert into tbApplyDoctor(ID,ApplyDeptID,ApplyDoctor,Gender,Mobile,Telephone,StaffID,EMail,Optional1,Optional2,Optional3,ShortCutCode,Site,Domain) 
			values(newid(),'',@ApplyDoctor,'','','','','','','','',@ShortCutCode,@CurrentSite,(select value from tbSystemProfile where Name ='Domain'))
	 end
	end
	else
	begin
	if not exists(select 1 from tbApplyDoctor where ApplyDoctor =@ApplyDoctor and (Site = '' or Site is null))
	 begin
			set @ShortCutCode = dbo.fnGetFirstPinYins(@ApplyDoctor)
			insert into tbApplyDoctor(ID,ApplyDeptID,ApplyDoctor,Gender,Mobile,Telephone,StaffID,EMail,Optional1,Optional2,Optional3,ShortCutCode,Site,Domain) 
			values(newid(),'',@ApplyDoctor,'','','','','','','','',@ShortCutCode,'',(select value from tbSystemProfile where Name ='Domain'))
	 end
	end
 end 
if update(InhospitalRegion)
 begin
	select @InhospitalRegion = InhospitalRegion,@IsReferral=IsReferral,@CurrentSite=CurrentSite from inserted
	if(@CurrentSite is null) return;
	if(@IsReferral is not null and @IsReferral=1 )
		return;
	set @InhospitalRegion=ltrim(RTRIM(@InhospitalRegion))
	if(@InhospitalRegion is not null and len(@InhospitalRegion) >0)
	if exists(select 1 from tbDictionaryValue where tag =3 and Site = @CurrentSite)
	begin
	 if not exists(select 1 from tbDictionaryValue where tag =3 and text =@InhospitalRegion and Site = @CurrentSite)
	 begin
		
			insert into tbDictionaryValue(tag,value,text,Site,Domain) 
			values(3,@InhospitalRegion,@InhospitalRegion,@CurrentSite,(select value from tbSystemProfile where Name ='Domain'))
	 end
	end
	else
	begin
	if not exists(select 1 from tbDictionaryValue where tag =3 and text =@InhospitalRegion and (Site = '' or Site is null))
	 begin
		
			insert into tbDictionaryValue(tag,value,text,Site,Domain) 
			values(3,@InhospitalRegion,@InhospitalRegion,'',(select value from tbSystemProfile where Name ='Domain'))
	 end
	end
 end 
END




GO
/****** Object:  Trigger [dbo].[triArchive2]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--插入:同步插入tAccessionNumberList, 如果tpatientlist表中不存在该hisid,则插入tpatientlist, 如何该病人已归档，
-------则发送预取指令,且把病人从tpatientlist取回tregpatient
--更新:同步更新到tAccessionNumberList表中
----------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TRIGGER [dbo].[triArchive2] ON [dbo].[tbRegOrder]  
for insert,update 
as 
BEGIN TRY
if not exists(select 0 from deleted) --insert
begin
		
	begin	
		MERGE tbAccessionNumberList A  
		USING inserted B on A.OrderGuid=B.OrderGuid 
		WHEN MATCHED THEN
			UPDATE SET A.PatientGuid=B.PatientGuid,A.AccNo=B.AccNo
		WHEN NOT MATCHED THEN
			INSERT(Accno,OrderGuid,PatientGuid,HisID,CreateDt) VALUES(B.Accno,B.OrderGuid,B.PatientGuid,B.HisID,B.CreateDt);
	end
	
	begin	--给归档病人新建ORDER时， 发送预取命令
		MERGE tbArchiveEvent A  
		USING (select tbPatientList.PatientGuid from inserted,tbPatientList where inserted.PatientGuid=tbPatientList.PatientGuid and tbPatientList.archive=1) as B on A.ObjectGuid=B.PatientGuid
		WHEN NOT MATCHED THEN 
			INSERT(type,ObjectGuid) VALUES(1,B.PatientGuid);	
	end
end
else
begin	--update 
	update tbAccessionNumberList set tbAccessionNumberList.AccNo=inserted.AccNo,tbAccessionNumberList.PatientGuid= inserted.PatientGuid FROM tbAccessionNumberList inner join inserted on tbAccessionNumberList.OrderGuid=inserted.OrderGuid		
end
END TRY
BEGIN CATCH
	rollback
	insert into tbErrorTable(errormessage) select ERROR_MESSAGE() as errormessage	
END CATCH


GO
/****** Object:  Trigger [dbo].[triCriticalSign]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--*******************************************************************************************--
               --Trigger to notification for critical sign--
--*******************************************************************************************--

CREATE TRIGGER [dbo].[triCriticalSign] ON [dbo].[tbRegOrder]  
for update 
as 
BEGIN TRY
	if not update(OrderMessage)
		return
	declare @OrderGuid nvarchar(128)
	declare @EventXml nvarchar(MAX)
	declare @CurSite nvarchar(128)
	declare @OrderMessage xml
	declare @OrderMessageDel xml
	declare @i int
	declare @KeyGuid varchar(128)
	declare @receiver1 nvarchar(max)
	declare @receiver2 nvarchar(max)
	declare @AccNo nvarchar(128)
	declare @LocalName nvarchar(128)
	declare @CriticalSign nvarchar(max)
	select @OrderMessageDel = OrderMessage from deleted	
	select @CurSite= CurrentSite,@OrderGuid = OrderGuid,@OrderMessage = OrderMessage from inserted

	if(@OrderMessage.exist('/LeaveMessage/Message[@Type="b"]') = 0)--there is no new critical sign message in new OrderMessage
	return 
	
    set @receiver1 = ''
	set @receiver2 = ''
	select @LocalName=A.LocalName,@AccNo=B.AccNo from tbRegPatient A,tbRegOrder B where B.PatientGuid = A.PatientGuid and OrderGuid =@OrderGuid
	select @receiver1 = b.ApplyDoctor from tbRegOrder a,tbApplyDoctor b where a.OrderGuid = @OrderGuid and a.ApplyDoctor = b.ApplyDoctor
	set @i = 1
	set @KeyGuid = Convert(varchar(128),@OrderMessage.query('(/LeaveMessage/Message[@Type="b"]/KeyGuid/text())[sql:variable("@i")]'))
	
	while @KeyGuid <> ''
	begin	
	if @OrderMessageDel is null or @OrderMessageDel.exist('/LeaveMessage/Message[KeyGuid=sql:variable("@KeyGuid")]') = 0 --no this critical sign in old OrderMessage
	begin
	set @CriticalSign = @OrderMessage.value('(/LeaveMessage/Message[KeyGuid=sql:variable("@KeyGuid")]/Subject/text())[1]','nvarchar(max)') + ':' + @OrderMessage.value('(/LeaveMessage/Message[KeyGuid=sql:variable("@KeyGuid")]/Context/text())[1]','nvarchar(max)')
	
	set @EventXml = '<Event><Sender></Sender><Receivers>'+@receiver1+'</Receivers><Para Name="LocalName">'+@LocalName+'</Para><Para Name="AccNo">'+@AccNo+'</Para><Para Name="CriticalSign">'+@CriticalSign+'</Para><OrderGuid>'+@OrderGuid+'</OrderGuid><MessageKeyGuid>'+@KeyGuid+'</MessageKeyGuid><Site>'+@CurSite+'</Site></Event>'
	exec [procPostEvent] N'危急征象通知','',@EventXml,3,@CurSite
	
	set @EventXml = '<Event><Sender></Sender><Receivers>'+@receiver2+'</Receivers><Para Name="LocalName">'+@LocalName+'</Para><Para Name="AccNo">'+@AccNo+'</Para><Para Name="CriticalSign">'+@CriticalSign+'</Para><OrderGuid>'+@OrderGuid+'</OrderGuid><MessageKeyGuid>'+@KeyGuid+'</MessageKeyGuid><Site>'+@CurSite+'</Site></Event>'
	exec [procPostEvent] N'危急征象通知第三方','',@EventXml,3,@CurSite		
    
	end	
	set @i = @i + 1
    set @KeyGuid = Convert(varchar(128),@OrderMessage.query('(/LeaveMessage/Message[@Type="b"]/KeyGuid/text())[sql:variable("@i")]'))
	
	end
END TRY
BEGIN CATCH
	rollback
	insert into tbErrorTable(errormessage) select ERROR_MESSAGE() as errormessage	
END CATCH


GO
/****** Object:  Trigger [dbo].[triDataSync2]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[triDataSync2] ON [dbo].[tbRegOrder]  
for update 
as 
if UPDATE(uploaded) or UPDATE(updatetime)
	return
BEGIN TRY
	update tbRegOrder set UpdateTime=GETDATE() FROM tbRegOrder inner join inserted on tbRegOrder.OrderGuid=inserted.OrderGuid		
END TRY
BEGIN CATCH	
	rollback
	insert into tbErrorTable(errormessage) select ERROR_MESSAGE() as errormessage		
END CATCH


GO
/****** Object:  Trigger [dbo].[triArchive1]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE TRIGGER [dbo].[triArchive1] ON [dbo].[tbRegPatient]  
for insert,update 
as 
BEGIN TRY
if not exists(select 0 from deleted) --insert operation
begin
		
	begin	
		MERGE tbPatientList A  
		USING inserted B on A.PatientGuid=B.PatientGuid 
		WHEN MATCHED THEN
			UPDATE SET A.PatientID=B.PatientID,A.LocalName=B.LocalName, A.EnglishName= B.EnglishName, A.ReferenceNo=B.ReferenceNo, A.Birthday=B.Birthday, A.Gender=B.Gender, A.Address=B.Address, A.Telephone=B.Telephone, A.IsVIP=B.IsVIP, A.CreateDt=B.CreateDt, A.Comments=B.Comments, A.RemotePID=B.RemotePID, A.Optional1=B.Optional1, A.Optional2=B.Optional2, A.Optional3=B.Optional3, A.Alias= B.Alias, A.Marriage=B.Marriage, A.[Domain]=B.[Domain], A.GlobalID=B.GlobalID, A.MedicareNo=B.MedicareNo, A.ParentName=B.ParentName, A.Site=B.Site  
		WHEN NOT MATCHED THEN
			INSERT(PatientGuid, PatientID, LocalName, EnglishName, ReferenceNo, Birthday, Gender, Address, Telephone, IsVIP, CreateDt, Comments, RemotePID, Optional1, Optional2, Optional3, Alias, Marriage, [Domain], GlobalID, MedicareNo, ParentName, RelatedID,Site,SocialSecurityNo,UpdateTime,Uploaded) VALUES(B.PatientGuid, B.PatientID, B.LocalName, B.EnglishName, B.ReferenceNo, B.Birthday, B.Gender, B.Address, B.Telephone, B.IsVIP, B.CreateDt, B.Comments, B.RemotePID, B.Optional1, B.Optional2, B.Optional3, B.Alias, B.Marriage, B.[Domain], B.GlobalID, B.MedicareNo, B.ParentName, B.RelatedID,B.Site,B.SocialSecurityNo,B.UpdateTime,B.Uploaded);
	end
end
else 
begin --udpate operation	
	update tbPatientList set tbPatientList.PatientID=inserted.PatientID,tbPatientList.LocalName=inserted.LocalName, tbPatientList.EnglishName= inserted.EnglishName, tbPatientList.ReferenceNo=inserted.ReferenceNo, tbPatientList.Birthday=inserted.Birthday, tbPatientList.Gender=inserted.Gender, tbPatientList.Address=inserted.Address, tbPatientList.Telephone=inserted.Telephone, tbPatientList.IsVIP=inserted.IsVIP, tbPatientList.CreateDt=inserted.CreateDt, tbPatientList.Comments=inserted.Comments, tbPatientList.RemotePID=inserted.RemotePID, tbPatientList.Optional1=inserted.Optional1, tbPatientList.Optional2=inserted.Optional2, tbPatientList.Optional3=inserted.Optional3, tbPatientList.Alias= inserted.Alias, tbPatientList.Marriage=inserted.Marriage, tbPatientList.[Domain]=inserted.[Domain], tbPatientList.GlobalID=inserted.GlobalID, tbPatientList.MedicareNo=inserted.MedicareNo, tbPatientList.ParentName=inserted.ParentName, tbPatientList.RelatedID=inserted.RelatedID,tbPatientList.Site=inserted.Site,tbPatientList.SocialSecurityNo=inserted.SocialSecurityNo FROM tbPatientList,inserted where tbPatientList.PatientGuid=inserted.PatientGuid	
	
	begin	--关联归档病人时，发送预取命令
		MERGE tbArchiveEvent A  
		USING (select tbPatientList.PatientGuid from inserted,tbPatientList where inserted.RelatedID=tbPatientList.RelatedID and  tbPatientList.relatedid is not null and len(ltrim(rtrim(tbPatientList.relatedid)))>0 and tbPatientList.archive=1) as B on A.ObjectGuid=B.PatientGuid
		WHEN NOT MATCHED THEN 
			INSERT(type,ObjectGuid) VALUES(1,B.PatientGuid);	
	end
	
end 
END TRY
BEGIN CATCH	
	rollback
	insert into tbErrorTable(errormessage) select ERROR_MESSAGE() as errormessage		
END CATCH


GO
/****** Object:  Trigger [dbo].[triDataSync1]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[triDataSync1] ON [dbo].[tbRegPatient]  
for update 
as 
if UPDATE(uploaded)
	return
	
BEGIN TRY
	update tbRegPatient set UpdateTime=GETDATE() FROM tbRegPatient inner join inserted on tbRegPatient.PatientGuid=inserted.PatientGuid		
END TRY
BEGIN CATCH	
	rollback
	insert into tbErrorTable(errormessage) select ERROR_MESSAGE() as errormessage		
END CATCH


GO
/****** Object:  Trigger [dbo].[triUpdateBirthday]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create TRIGGER [dbo].[triUpdateBirthday]
ON [dbo].[tbRegPatient]
AFTER UPDATE AS
if update(Birthday)
begin
   DECLARE cursorOrderTable CURSOR FAST_FORWARD FOR SELECT VisitGuid,CreateDt FROM tbRegOrder  WHERE PatientGuid in(SELECT PatientGuid FROM inserted) FOR READ ONLY
  
   DECLARE @VisitGuid nvarchar(64)   
   DECLARE @CreateDt datetime
   DECLARE @Birthday datetime   
   DECLARE @MonthNumber nvarchar(16)
   DECLARE @YearNumber nvarchar(16)
   DECLARE @DayNumber nvarchar(16)
   DECLARE @AgeInDay int
   select  @Birthday=Birthday from tbRegPatient WHERE PatientGuid in(SELECT PatientGuid FROM inserted)   

 

   select  @MonthNumber = value from tbSystemProfile where name = 'MonthNumber'
   select @YearNumber = value from tbSystemProfile where name ='YearNumber'
   select @DayNumber = value from tbSystemProfile where name ='DayNumber'
   
   OPEN  cursorOrderTable
   FETCH NEXT FROM cursorOrderTable INTO @VisitGuid,@CreateDt
   WHILE (@@FETCH_STATUS) = 0   
   BEGIN 
   
    declare @nYear int
 declare @nMonth int
 declare @nDay int 
 declare @nHour int
 declare @nMinute int
    declare @strCurrentAge varchar(128)
 select @nYear=dbo.fnGetYear(@Birthday,@CreateDt)   
 select @nMonth=dbo.fnGetMonth(@Birthday,@CreateDt) 
 select @nHour=datediff(hh,@Birthday,@CreateDt)+1
 select @nDay= @nHour/24
 
 if(@nYear >= @YearNumber)
 begin
  set @strCurrentAge = cast(@nYear as varchar(12))+' '+'Year'
 end
 else if(@nMonth >= @MonthNumber)
 begin
  set @strCurrentAge = cast(@nMonth as varchar(12))+' '+'Month'
 end
 else
 begin
  set @nMinute = datediff(mi,@Birthday,@CreateDt)
  set @nHour = @nMinute/60
  set @nDay = @nHour/24
  
   if(@nDay >=@DayNumber)
  begin
   set @strCurrentAge = cast(@nDay as varchar(12))+' '+'Day'
  end
  else 
  begin   
   set @strCurrentAge = cast(@nHour as varchar(12))+' '+'Hour'
  end
 end
    --set @AgeInDay =abs(datediff(day,@Birthday,@CreateDt)) 
    declare @SQL2 varchar(512)
    set @SQL2='UPDATE tbRegOrder SET CurrentAge='''+@strCurrentAge+''''+',AgeInDays='+cast(@nDay as varchar)+' WHERE VisitGuid= '''+@VisitGuid+''''
 
    EXEC(@SQL2)  
    FETCH NEXT FROM cursorOrderTable INTO @VisitGuid,@CreateDt
   END
   DEALLOCATE cursorOrderTable 

end


GO
/****** Object:  Trigger [dbo].[triAutoAssign]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create TRIGGER [dbo].[triAutoAssign] ON [dbo].[tbRegProcedure]  
for insert,update 
as 
BEGIN TRY

 if not update(Status)
  return
  
 declare @AutoStatus nvarchar(32)
 declare @CurSite nvarchar(64) 
 declare @assignSite nvarchar(128)
 declare @CurStatus nvarchar(32)
 declare @RPGuid nvarchar(128)
 declare @Event xml
 
 select @CurStatus=Status,@RPGuid=ProcedureGuid from inserted
 
 if @CurStatus = 50
  begin
   /*** check whether all the rps of the same order are exam finished***/
   if not exists (select 1 from tbRegProcedure where OrderGuid = (select top 1 orderGuid from inserted) 
              and ProcedureGuid <> @RPGuid and Status <> 50)
   /***  use examsite as current site***/
    select @CurSite=ExamSite from tbRegOrder where orderGuid =(select top 1 orderGuid from inserted)
  end
 else if @CurStatus = 110
  begin
   /*** check whether all the reprots of the same order are submitted***/
   if not exists (select 1 from tbRegProcedure where OrderGuid = (select top 1 orderGuid from inserted) 
              and ProcedureGuid <> @RPGuid and Status <> 110)
   /***  use submitSite as current site***/
   select @CurSite=SubmitSite from tbReport where reportGuid =(select top 1 reportGuid from inserted)
  end
 else 
  return
   
 select @AutoStatus=value from tbSiteProfile where name='AutoAssignStatus' and site =@CurSite
  
 /*** AutoAssignStatus is configured ***/
 if @AutoStatus is null or len(@AutoStatus)=0
  return
  
 if not (@CurStatus = @AutoStatus)
  return  
 /*** Get assign site ***/
 if @AutoStatus = 50
  begin
   select @assignSite =value from tbSiteProfile where name ='Assign2SiteListAftExam' and site=@CurSite
  end
 else if @AutoStatus = 110
  begin
   select @assignSite =value from tbSiteProfile where name ='Assign2SiteListAftSubmit' and site=@CurSite
  end
 else 
  return
  
 /*** assignsite is only one site ***/ 
 if not (len(@assignSite)>0 and charindex('|',@assignSite,0) <1)
  return

 Set @Event='<Event><OrderGuid>'+(select top 1 orderGuid from inserted)+'</OrderGuid></Event>'
 
 if not exists(select 0 from deleted) --insert
 begin
	/***whether it is First inserted RP***/
  if (select count(1) as num from tbRegProcedure where OrderGuid = (select top 1 orderGuid from inserted)) < 2
	begin
	  update tbRegOrder set assign2site = @assignSite,CurrentSite=@assignSite,assignDt = getdate() where orderGuid =(select top 1 orderGuid from inserted)
	  exec [procPostEvent] N'转诊通知','',@Event,'3',@curSite
	end
 end
 else
 begin --update 
  /*** new status is larger than old status ***/
  if (select top 1 status from deleted)< @CurStatus
  begin
   update tbRegOrder set assign2site = @assignSite,CurrentSite=@assignSite,assignDt = getdate()  where orderGuid =(select top 1 orderGuid from inserted)
     exec [procPostEvent] N'转诊通知','',@Event,'3',@curSite
  end
 end

END TRY
BEGIN CATCH
 rollback
 insert into tbErrorTable(errormessage) select ERROR_MESSAGE() as errormessage 
END CATCH



GO
/****** Object:  Trigger [dbo].[triAutoReferral]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[triAutoReferral] 
   ON [dbo].[tbRegProcedure]
   AFTER UPDATE
AS 
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 Declare @orderId nvarchar(128)
 declare @Status int
 declare @IsReferral int
 declare @IsExistImage int
 declare @domain nvarchar(64)
 declare @ReferralId nvarchar(64)
 declare @ModalityType nvarchar(64)
 declare @examsite nvarchar(128)
 declare @cursite nvarchar(128)
 declare @oldStatus int 
 
 
 SET NOCOUNT ON;
 if update(Status) or update(IsExistImage)
 begin
  select @orderId=orderGuid,@Status=Status,@IsExistImage=IsExistImage,@ModalityType=ModalityType from inserted

  select @oldStatus = Status from deleted
  if(@oldStatus <0 or @Status <0 )
  return
  
  select  @cursite = currentsite, @ReferralId=ISNULL(referralId, ''),@domain=domain,@IsReferral= IsReferral,@examsite= ExamSite from tbRegOrder where orderGuid =@orderId
  
  if @IsReferral is null or @IsReferral = 0
  begin
   if @Status = 50 and @IsExistImage= 1
   begin
   if exists (select 1 from tbSiteProfile where name='AutoReferralFinishedExam' and value ='1' and Site =@examsite)   
  insert into tbReferralEvent([REFERRALID],[OPERATORGUID],[OPERATEDT],[SOURCEDOMAIN],[TARGETDOMAIN],[EVENT],[STATUS],[TAG],[Content],[EXAMDOMAIN],[EXAMACCNO],[EVENTGUID],[OPERATORNAME]) 
  values('','',getdate(),@domain,'',7,@Status,0,'ORDERID='+@orderId+'&MODALITYTYPE='+@ModalityType,'','',newid(),'')
   else 
   if exists (select 1 from tbSystemProfile where name='AutoReferralFinishedExam' and value ='1')   
  insert into tbReferralEvent([REFERRALID],[OPERATORGUID],[OPERATEDT],[SOURCEDOMAIN],[TARGETDOMAIN],[EVENT],[STATUS],[TAG],[Content],[EXAMDOMAIN],[EXAMACCNO],[EVENTGUID],[OPERATORNAME]) 
  values('','',getdate(),@domain,'',7,@Status,0,'ORDERID='+@orderId+'&MODALITYTYPE='+@ModalityType,'','',newid(),'')
   end
   else if (@Status = 105 and UPDATE(Status))
   begin
    insert into tbReferralEvent([REFERRALID],[OPERATORGUID],[OPERATEDT],[SOURCEDOMAIN],[TARGETDOMAIN],[EVENT],[STATUS],[TAG],[MEMO],[EXAMDOMAIN],[EXAMACCNO],[EVENTGUID],[OPERATORNAME]) 
    values(@ReferralId,'',getdate(),@domain,'',4,@Status,0,'','','',newid(),'') 
   end   
   else if @Status = 110
   begin
   if exists (select 1 from tbSiteProfile where name='AutoReferralSubmittedReport' and value ='1' and Site = @examsite)   
  insert into tbReferralEvent([REFERRALID],[OPERATORGUID],[OPERATEDT],[SOURCEDOMAIN],[TARGETDOMAIN],[EVENT],[STATUS],[TAG],[Content],[EXAMDOMAIN],[EXAMACCNO],[EVENTGUID],[OPERATORNAME]) 
  values('','',getdate(),@domain,'',7,@Status,0,'ORDERID='+@orderId+'&MODALITYTYPE='+@ModalityType,'','',newid(),'')
   else 
    if exists (select 1 from tbSystemProfile where name='AutoReferralSubmittedReport' and value ='1')   
  insert into tbReferralEvent([REFERRALID],[OPERATORGUID],[OPERATEDT],[SOURCEDOMAIN],[TARGETDOMAIN],[EVENT],[STATUS],[TAG],[Content],[EXAMDOMAIN],[EXAMACCNO],[EVENTGUID],[OPERATORNAME]) 
  values('','',getdate(),@domain,'',7,@Status,0,'ORDERID='+@orderId+'&MODALITYTYPE='+@ModalityType,'','',newid(),'')
   end
  end  
  else --ReferralId is not empty
  ---Event Type: =4,RPStatusFeedBack
   if update(Status)
	begin
    insert into tbReferralEvent([REFERRALID],[OPERATORGUID],[OPERATEDT],[SOURCEDOMAIN],[TARGETDOMAIN],[EVENT],[STATUS],[TAG],[MEMO],[EXAMDOMAIN],[EXAMACCNO],[EVENTGUID],[OPERATORNAME]) 
    values(@ReferralId,'',getdate(),@domain,'',4,@Status,0,'','','',newid(),'') 
    
    if( @Status >=120)
	   begin
	   if ((select 1 from tbSiteProfile where name = 'ReportEditor_DelayFinishReferralAfterApprove' )>0 or
			 (select 1 from tbSystemProfile where name = 'ReportEditor_DelayFinishReferralAfterApprove' )>0 )
	   begin
		   if exists (select 1 from tbSiteProfile where name='ReportEditor_FinishReferralAfterApprove' and value ='1' and Site = @cursite) 
		  insert into tbReferralEvent([REFERRALID],[OPERATORGUID],[OPERATEDT],[SOURCEDOMAIN],[TARGETDOMAIN],[EVENT],[STATUS],[TAG],[Content],[EXAMDOMAIN],[EXAMACCNO],[EVENTGUID],[OPERATORNAME]) 
		  values(@ReferralId,'',getdate(),@domain,'',16,@Status,0,'UPDATEDT='+CONVERT(varchar(100), GETDATE(), 20),'','',newid(),'')
		   else 
			if exists (select 1 from tbSystemProfile where name='ReportEditor_FinishReferralAfterApprove' and value ='1')   
		  insert into tbReferralEvent([REFERRALID],[OPERATORGUID],[OPERATEDT],[SOURCEDOMAIN],[TARGETDOMAIN],[EVENT],[STATUS],[TAG],[Content],[EXAMDOMAIN],[EXAMACCNO],[EVENTGUID],[OPERATORNAME]) 
		  values(@ReferralId,'',getdate(),@domain,'',16,@Status,0,'UPDATEDT='+CONVERT(varchar(100), GETDATE(), 20),'','',newid(),'')
		   end
	   end
    end
 end
    -- Insert statements for trigger here
END


GO
/****** Object:  Trigger [dbo].[triBookingSerialization]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[triBookingSerialization] 
   ON  [dbo].[tbRegProcedure]
   AFTER INSERT 
AS 
BEGIN TRY
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @Exceed int
	declare @Status int
	declare @MaxCount int
	declare @CurCount int
	declare @Modality nvarchar(128)
	declare @begindt datetime
	declare @enddt datetime	
	declare @dt1 nvarchar(16)
	declare @dt2 nvarchar(16)
	declare @dt3 nvarchar(32)
	declare @dt4 nvarchar(32)
	
	declare @sql nvarchar(512)
	declare @TakeCountMode int
	
	select @begindt=bookingbegindt,@enddt=bookingenddt, @dt1 =convert(varchar(8),bookingBeginDt,108),@dt2=convert(varchar(8),bookingenddt,108),@Exceed=IsPost,@Status=Status,@Modality=Modality from inserted
	if(@Status>10 or @Exceed=100)
		return
	--get the max number for booking
	
	
	set @dt3='2008-08-08 '+@dt1 
	set @dt4='2008-08-08 '+@dt2
	select @MaxCount=MaxNumber from tbModalityTimeSlice where Modality=@Modality and StartDt>=@dt3 and EndDt<=@dt4 and DateType=@Exceed and 
	 AvailableDate =(select Top 1 AvailableDate from tbModalityTimeSlice where AvailableDate <= @begindt order by AvailableDate desc)
	
	--set @sql='select @MaxCount=MaxNumber from tbModalityTimeSlice where Modality='+	@Modality+' and StartDt>='''+@dt3+''' and EndDt<='''+@dt4+'''' +' and DateType='--+cast(@Exceed as varchar(10))
	--insert into tbErrorTable(errormessage) select @sql
	select @TakeCountMode=Value from tbSystemProfile where name='BookingScheduleTakecountMode' and moduleid='0H00'
	
	if(@TakeCountMode=1)	
	begin
	--BY ORDER
		set transaction isolation level read uncommitted
		select @CurCount=COUNT(*) from (SELECT DISTINCT orderguid from tbRegProcedure where BookingBeginDt>=@Begindt and BookingEndDt<=@enddt and Modality=@Modality) as table1
	end 
	else
	begin
	--BY RP
		set transaction isolation level read committed
		select @CurCount=COUNT(*) from tbRegProcedure where BookingBeginDt>=@Begindt and BookingEndDt<=@enddt and Modality=@Modality
	end
	
	--set @sql='select @CurCount=COUNT(*) from tbRegProcedure where BookingBeginDt>='''+convert(char(19),@Begindt,20)+''' and BookingEndDt<='''+convert(char(19),@enddt,20)+''''
	--insert into tbErrorTable(errormessage) select @sql
	
	--insert into tbErrorTable(errormessage) select @CurCount
	--insert into tbErrorTable(errormessage) select @MaxCount
	if(@CurCount>@MaxCount)
		rollback
	

END TRY
BEGIN CATCH
 rollback
 insert into tbErrorTable(errormessage) select ERROR_MESSAGE() as errormessage 
END CATCH


GO
/****** Object:  Trigger [dbo].[triDataSync3]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[triDataSync3] ON [dbo].[tbRegProcedure]  
for update 
as 
 IF OBJECT_ID('tempdb..#Disable1')   IS NOT   NULL   
	RETURN
if UPDATE(uploaded) or UPDATE(updatetime)
	return
BEGIN TRY
	CREATE TABLE #Disable1(ID INT)
	update tbRegProcedure set UpdateTime=GETDATE() FROM tbRegProcedure inner join inserted on tbRegProcedure.ProcedureGuid=inserted.ProcedureGuid		
	drop TABLE #Disable1
END TRY
BEGIN CATCH		
	insert into tbErrorTable(errormessage) select ERROR_MESSAGE() as errormessage		
END CATCH


GO
/****** Object:  Trigger [dbo].[triDataSync4]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[triDataSync4] ON [dbo].[tbReport]  
for update 
as 
if UPDATE(uploaded) or UPDATE(updatetime)
	return
BEGIN TRY
	update tbReport set UpdateTime=GETDATE() FROM tbReport inner join inserted on tbReport.ReportGuid=inserted.ReportGuid		
END TRY
BEGIN CATCH	
	rollback
	insert into tbErrorTable(errormessage) select ERROR_MESSAGE() as errormessage		
END CATCH


GO
/****** Object:  Trigger [dbo].[triForPrintUnapproveReport]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[triForPrintUnapproveReport]
   ON  [dbo].[tbReport]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	declare @reportguid nvarchar(128)
	declare @status int
	SET NOCOUNT ON;
	if UPdate(IsPrint) or Update(PrintCopies)
	begin
		select @reportguid=reportguid from inserted
		if(len(@reportguid)=0)
			return;
		select top 1 @status=status from tbRegProcedure where reportguid=@reportguid
		if(@status<120)
			update tbReport set isprint=0,PrintCopies=0 where reportguid=@reportguid
		
	end
	

END


GO
/****** Object:  Trigger [dbo].[UpdateReportPrintCopies]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[UpdateReportPrintCopies] 
   ON  [dbo].[tbReportPrintLog]
   for insert as
   BEGIN 
	   SET NOCOUNT ON;
	   declare @PrintCounts int
	   declare @ReportGuid nvarchar(128)
	   declare @PrintType nvarchar(128)
	   select  @PrintCounts=Counts,@ReportGuid = ReportGuid, @PrintType=Type FROM inserted   
				BEGIN
					if(@PrintCounts > 0 AND @PrintType = 'Print')
					update tbReport set PrintCopies = (PrintCopies + @PrintCounts) Where  ReportGuid = @ReportGuid 
				END
   END



GO
/****** Object:  Trigger [dbo].[utriNewSite]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE TRIGGER [dbo].[utriNewSite] ON [dbo].[tbSiteList]  

for insert

as 

BEGIN TRY

 

declare @Site nvarchar(64)

declare @ThisDomain nvarchar(64)

declare @CurDomain nvarchar(64)

declare @IMSitePrefix nvarchar(8)

  set @IMSitePrefix = 'IM_'





select @ThisDomain=Value from tbSystemProfile where Name='Domain'

select @Site=Site,@CurDomain=Domain from inserted



--For Roledir
if(@CurDomain=@ThisDomain)
begin
if not exists(select * from tbRoleDir where Name =@Site)
 insert into tbRoleDir(Name,ParentID,RoleID,Leaf,OrderID,Domain) select @Site,(select uniqueid from tbRoleDir where name='RoleManagement'),'',0,0,(select value from tbSystemProfile where Name='domain')
end

if(@CurDomain!=@ThisDomain)
 return

 if not exists(select 1 from tbSystemProfile where name=@Site)
	INSERT INTO dbo.tbSystemProfile ( Name, ModuleID, [Value], Exportable, PropertyDesc, PropertyOptions, Inheritance, PropertyType, IsHidden, OrderingPos, [Domain], UniqueID ) 

  select tbSiteList.Site,'0000',tbSiteList.Site,1,'Access site data','select site as value,alias as text from tbSiteList where Domain in (select Value from tbSystemProfile where Name = ''Domain'')',1,5,2,'000015',(select value from tbSystemProfile where Name='Domain'),NEWID() from tbSiteList where Site=@Site





  if not exists(select 1 from tbRoleProfile where name=@Site)

  insert into tbRoleProfile( RoleName, Name, ModuleID, [Value], Exportable, PropertyDesc, PropertyOptions, Inheritance, PropertyType, IsHidden, OrderingPos, [Domain], UniqueID )

  select tbRole.RoleName,tbSiteList.Site,'0000',tbSiteList.Site,1,'Access site data','select site as value,alias as text from tbSiteList where Domain in (select Value from tbSystemProfile where Name = ''Domain'')',0,5,7,'0015',(select value from tbSystemProfile where Name='Domain'),NEWID() from tbRole,tbSiteList where tbSiteList.Site=@Site 

 

 if not exists(select 1 from tbSiteProfile where Site=@Site and Name = 'DefaultScheduleTable')

 insert into dbo.tbSiteProfile(Name,ModuleID,Value,Exportable,PropertyDesc,PropertyOptions,Inheritance,PropertyType,IsHidden,OrderingPos,Domain,Site) values('DefaultScheduleTable','0000','','0','','','0','0','0','0',(select top 1 value from tbSystemProfile where Name = 'Domain'),@Site)  

  

 -- for IM begin--

 if not exists(select 1 from tbSystemProfile where name= @IMSitePrefix + @Site)

 INSERT INTO dbo.tbSystemProfile ( Name, ModuleID, [Value], Exportable, PropertyDesc, PropertyOptions, Inheritance, PropertyType, IsHidden, OrderingPos, [Domain], UniqueID ) 

 select @IMSitePrefix + tbSiteList.Site,'0000','',1,'IM can access site','select site as value,alias as text from tbSiteList where Domain in (select Value from tbSystemProfile where Name = ''Domain'')',1,5,2,'000019',(select value from tbSystemProfile where Name='Domain'),NEWID() from tbSiteList where Site=@Site





 if not exists(select 1 from tbRoleProfile where name=@IMSitePrefix + @Site)

 insert into tbRoleProfile( RoleName, Name, ModuleID, [Value], Exportable, PropertyDesc, PropertyOptions, Inheritance, PropertyType, IsHidden, OrderingPos, [Domain], UniqueID )

 select tbRole.RoleName,@IMSitePrefix + tbSiteList.Site,'0000', '',1,'IM can access site','select site as value,alias as text from tbSiteList where Domain in (select Value from tbSystemProfile where Name = ''Domain'')',0,5,7,'0019',(select value from tbSystemProfile where Name='Domain'),NEWID() from tbRole,tbSiteList where tbSiteList.Site=@Site 

 -- for IM end--

END TRY

BEGIN CATCH

 rollback

 insert into tbErrorTable(errormessage) select ERROR_MESSAGE() as errormessage 

END CATCH


GO
/****** Object:  Trigger [dbo].[triAccNoPolicy4_2]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create TRIGGER [dbo].[triAccNoPolicy4_2] ON [dbo].[tbSiteProfile]
for insert,update,delete   
as 
declare @Name1 varchar(256)
declare @Value1 varchar(256)
declare @Name2 varchar(256)
declare @Value2 varchar(256)
declare @Site varchar(256)
declare @Domain varchar(256)
if exists(select 1 from inserted) and not exists(select 1 from deleted) --insert 
begin
	select @Name2=name,@Value2=Value,@Site=Site,@Domain=Domain from inserted where Name='AccNoPolicy'
	if(LEN(@Name2)=0 or @Name2 is null)
			return			
	if(@Value2='4')
		insert into tbIdMaxValue(Tag,Value,Domain,ModalityType,Site) select 3 as tag,0 as value,@Domain as domain, tbModalityType.ModalityType,@Site as Site from tbModalityType 
	
end
if exists(select 1 from inserted a join deleted b on a.Name=b.Name) --修改
begin

	select @Name1=name,@Value1=Value,@Site=Site,@Domain=Domain from deleted where Name='AccNoPolicy'
	select @Name2=name,@Value2=Value from inserted where Name='AccNoPolicy'
	
	if(LEN(@Name1)=0 or @Name1 is null or LEN(@Name2)=0 or @Name2 is null)
		return
		
	if(@Value1!='4' and @Value2='4')
	begin
		insert into tbIdMaxValue(Tag,Value,Domain,ModalityType,Site) select 3 as tag,0 as value,@Domain as domain, tbModalityType.ModalityType,@Site as Site from tbModalityType 
	end
	else if(@Value1='4' and @Value2!='4')
	begin
		delete from tbIdMaxValue where  Tag=3 and ModalityType  is not null and Site=@Site
	end
				

end
if exists(select 1 from deleted) and not exists(select 1 from inserted) --删除
begin
	select @Name1=name,@Value1=Value,@Site=Site,@Domain=Domain from deleted where Name='AccNoPolicy'	
	
	if(LEN(@Name1)=0 or @Name1 is null)
		return		
	if(@Value1='4')	
		delete from tbIdMaxValue where Tag=3 and ModalityType  is not null and Site=@Site
	
end


GO
/****** Object:  Trigger [dbo].[trigger_tSyncOnDeleted]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--TriggerOnDelete
CREATE TRIGGER [dbo].[trigger_tSyncOnDeleted] 
   ON  [dbo].[tbSync]
   AFTER delete
AS 
BEGIN

	SET NOCOUNT ON;

	declare @accNo nvarchar(128)

    declare queryDeletedCursor cursor for select AccNo from deleted
    open queryDeletedCursor
    fetch next from queryDeletedCursor into @accNo
    while @@fetch_status = 0
    begin
		update tbRegProcedure set Optional3 = '0' where OrderGuid = (select OrderGuid from tbRegOrder where AccNo = @accNo) 
		fetch next from queryDeletedCursor into @accNo
    end
	close queryDeletedCursor
	deallocate queryDeletedCursor
END


GO
/****** Object:  Trigger [dbo].[trigger_tSyncOnInserted]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--TriggerOnInsert
CREATE TRIGGER [dbo].[trigger_tSyncOnInserted] 
   ON  [dbo].[tbSync]
   AFTER insert
AS 
BEGIN

	SET NOCOUNT ON;

	declare @accNo nvarchar(128)
	declare @rpGuids nvarchar(1024)
	declare @formattedRPGuids nvarchar(1024)
	
	declare @rpGuidSplitString nvarchar(512)
	declare @rpGuid nvarchar(128)

    declare queryInsertedCursor cursor for select AccNo,RPGuids from inserted
    open queryInsertedCursor
    fetch next from queryInsertedCursor into @accNo,@rpGuids
    while @@fetch_status = 0
    begin
		if(len(@rpGuids)=0 or @rpGuids is null)
			begin
				update tbRegProcedure set Optional3 = '1' where OrderGuid = (select OrderGuid from tbRegOrder where AccNo = @accNo)
			end
		else
			begin
				declare queryRPGuids cursor for select string from fnStrSplit(@rpGuids,'|')
				open queryRPGuids
				fetch next from queryRPGuids into @rpGuidSplitString
				while @@fetch_status = 0
				begin
					select @rpGuid = string from fnStrSplit(@rpGuidSplitString,'&') where str_id = '1'
					update tbRegProcedure set Optional3 = '1' where ProcedureGuid = @rpGuid
					fetch next from queryRPGuids into @rpGuidSplitString
				end
				close queryRPGuids
				deallocate queryRPGuids
			end
		fetch next from queryInsertedCursor into @accNo,@rpGuids
    end
	close queryInsertedCursor
	deallocate queryInsertedCursor
END


GO
/****** Object:  Trigger [dbo].[trigger_tSyncOnUpdated]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--TriggerOnUpdate
CREATE TRIGGER [dbo].[trigger_tSyncOnUpdated] 
   ON  [dbo].[tbSync]
   AFTER update
AS 
BEGIN

	SET NOCOUNT ON;

	declare @accNo nvarchar(128)
	declare @rpGuids nvarchar(1024)
	declare @formattedRPGuids nvarchar(1024)
	
	declare @rpGuidSplitString nvarchar(512)
	declare @rpGuid nvarchar(128)
	
	declare queryDeletedCursor cursor for select AccNo,RPGuids from deleted
    open queryDeletedCursor
    fetch next from queryDeletedCursor into @accNo,@rpGuids
    while @@fetch_status = 0
    begin
		if(len(@rpGuids)=0 or @rpGuids is null)
			begin
				update tbRegProcedure set Optional3 = '0' where OrderGuid = (select OrderGuid from tbRegOrder where AccNo = @accNo)
			end
		else
			begin
				declare queryRPGuids cursor for select string from fnStrSplit(@rpGuids,'|')
				open queryRPGuids
				fetch next from queryRPGuids into @rpGuidSplitString
				while @@fetch_status = 0
				begin
					select @rpGuid = string from fnStrSplit(@rpGuidSplitString,'&') where str_id = '1'
					update tbRegProcedure set Optional3 = '0' where ProcedureGuid = @rpGuid
					fetch next from queryRPGuids into @rpGuidSplitString
				end
				close queryRPGuids
				deallocate queryRPGuids
			end
		fetch next from queryDeletedCursor into @accNo,@rpGuids
    end
	close queryDeletedCursor
	deallocate queryDeletedCursor
	
    declare queryInsertedCursor cursor for select AccNo,RPGuids from inserted
    open queryInsertedCursor
    fetch next from queryInsertedCursor into @accNo,@rpGuids
    while @@fetch_status = 0
    begin
		if(len(@rpGuids)=0 or @rpGuids is null)
			begin
				update tbRegProcedure set Optional3 = '1' where OrderGuid = (select OrderGuid from tbRegOrder where AccNo = @accNo)
			end
		else
			begin
				declare queryRPGuids cursor for select string from fnStrSplit(@rpGuids,'|')
				open queryRPGuids
				fetch next from queryRPGuids into @rpGuidSplitString
				while @@fetch_status = 0
				begin
					select @rpGuid = string from fnStrSplit(@rpGuidSplitString,'&') where str_id = '1'
					update tbRegProcedure set Optional3 = '1' where ProcedureGuid = @rpGuid
					fetch next from queryRPGuids into @rpGuidSplitString
				end
				close queryRPGuids
				deallocate queryRPGuids
			end
		fetch next from queryInsertedCursor into @accNo,@rpGuids
    end
	close queryInsertedCursor
	deallocate queryInsertedCursor
END


GO
/****** Object:  Trigger [dbo].[triAccNoPolicy4]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create TRIGGER [dbo].[triAccNoPolicy4] ON [dbo].[tbSystemProfile]  
for update 
as 
declare @Name1 varchar(256)
declare @Value1 varchar(256)
declare @Name2 varchar(256)
declare @Value2 varchar(256)
declare @Domain varchar(256)
if UPDATE(value) 
begin
	BEGIN TRY
		select @Name1=name,@Value1=Value,@Domain=Domain from deleted where Name='AccNoPolicy'
		select @Name2=name,@Value2=Value from inserted where Name='AccNoPolicy'
		
		if(LEN(@Name1)=0 or @Name1 is null or LEN(@Name2)=0 or @Name2 is null)
			return
			
		if(@Value1!='4' and @Value2='4')
		begin
			insert into tbIdMaxValue(Tag,Value,Domain,ModalityType) select 3 as tag,0 as value,@Domain as domain, tbModalityType.ModalityType from tbModalityType 
		end
		else if(@Value1='4' and @Value2!='4')
		begin
			delete from tbIdMaxValue where ModalityType  is not null and site is null
		end
				
	END TRY
	BEGIN CATCH	
		rollback
		insert into tbErrorTable(errormessage) select ERROR_MESSAGE() as errormessage		
	END CATCH
end


GO
/****** Object:  Trigger [dbo].[triUpdateTrackFlag]    Script Date: 2017/8/24 11:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[triUpdateTrackFlag] ON [dbo].[tbTeaching]  
for insert,delete 
as 
declare @ReportGuid nvarchar(64)
declare @FileType nvarchar(64)

BEGIN TRY
if not exists(select 0 from inserted)   --delete operation
begin
		select @reportguid=reportguid,@FileType=FileType from deleted
		if @FileType='教学'
			update tbPathologyTrack set Teaching=0 where ReportGuid=@ReportGuid
		else if @FileType='研究'
			update tbPathologyTrack set Research=0 where ReportGuid=@ReportGuid
end
else  
begin --insert operation	
	
		select @reportguid=reportguid,@FileType=FileType from inserted
		if @FileType='教学'
			update tbPathologyTrack set Teaching=1 where ReportGuid=@ReportGuid
		else if @FileType='研究'
			update tbPathologyTrack set Research=1 where ReportGuid=@ReportGuid

end 
END TRY
BEGIN CATCH	
	rollback
	insert into tbErrorTable(errormessage) select ERROR_MESSAGE() as errormessage		
END CATCH



GO
