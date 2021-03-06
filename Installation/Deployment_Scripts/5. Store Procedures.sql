USE [EDW]
GO
/****** Object:  StoredProcedure [dbo].[sp_LoadFactStoreSales]    Script Date: 12/12/2015 7:23:31 PM ******/
DROP PROCEDURE [dbo].[sp_LoadFactStoreSales]
GO
/****** Object:  StoredProcedure [dbo].[sp_LoadFactOnlineSales]    Script Date: 12/12/2015 7:23:31 PM ******/
DROP PROCEDURE [dbo].[sp_LoadFactOnlineSales]
GO
/****** Object:  StoredProcedure [dbo].[sp_LoadDimProduct]    Script Date: 12/12/2015 7:23:31 PM ******/
DROP PROCEDURE [dbo].[sp_LoadDimProduct]
GO
/****** Object:  StoredProcedure [dbo].[sp_LoadDimLocation]    Script Date: 12/12/2015 7:23:31 PM ******/
DROP PROCEDURE [dbo].[sp_LoadDimLocation]
GO
/****** Object:  StoredProcedure [dbo].[sp_LoadDimCustomer]    Script Date: 12/12/2015 7:23:31 PM ******/
DROP PROCEDURE [dbo].[sp_LoadDimCustomer]
GO
/****** Object:  StoredProcedure [dbo].[sp_LoadDimCountry]    Script Date: 12/12/2015 7:23:31 PM ******/
DROP PROCEDURE [dbo].[sp_LoadDimCountry]
GO
/****** Object:  StoredProcedure [dbo].[sp_LoadDimCountry]    Script Date: 12/12/2015 7:23:31 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_LoadDimCountry]
AS


DECLARE @DWDate AS Datetime=GetDate()
DECLARE @DWUser AS Varchar(50)=Cast(System_User AS Varchar(50))

--For first time load enter the Default Data.
IF NOT EXISTS (SELECT top 1 * FROM DimCountry)
BEGIN
    SET IDENTITY_INSERT DimCountry ON 
	
	INSERT INTO DimCountry
	(CountryKey,
	CountryName,
		Region,
		IsActive,
		[DWCreatedDate],
		[DWCreatedBy],
		[DWUpdatedDate],
		[DWUpdatedBy]
	)
	VALUES 
		(
		0,
		'UNKOWN',
		'UNKNOWN',
		1,
		@DWDate,
		@DWDate,
		@DWUser,
		@DWUser
		)
		Print ('Entered Default Row')
      SET IDENTITY_INSERT DimCountry OFF
END



IF OBJECT_ID('tempdb..#DimCountry') IS NOT NULL
    DROP TABLE #DimCountry

CREATE Table #DimCountry
(
CountryName	nvarchar(200) NOT NULL
,Region	nvarchar(50) NOT NULL
,IsActive	bit NOT NULL
)


--Bring Distinct Country-Regions from SOurce Table
SELECT DISTINCT CountryRegionCode,[Group] AS Region 
INTO #SalesTerritory
FROM Staging.SalesTerritory 


Insert into #DimCountry
SELECT A.Name AS CountryName,  B.Region, 1 AS IsActive
FROM Staging.CountryMaster A
INNER JOIN #SalesTerritory B ON A.CountryRegionCode=B.CountryRegionCode


	MERGE INTO [dbo].[DimCountry] WITH (TABLOCK) AS A -- Target
	USING #DimCountry AS B WITH (TABLOCK) -- Source
	ON A.CountryName = B.CountryName
	-- In Source and Target (Updated only if the values changed in some way)
	WHEN MATCHED AND
	A.IsActive<>B.IsActive
	OR A.Region<>B.Region
	THEN
	UPDATE SET
	    A.Region=B.Region,
	    A.IsActive = B.IsActive,
		A.DWUpdatedDate = @DWDate,
		A.DWUpdatedBy = @DWUser
	
	WHEN NOT MATCHED BY TARGET THEN -- In source, not in target (new value)
		INSERT
		(
		CountryName,
		Region,
		IsActive,
		[DWCreatedDate],
		[DWCreatedBy],
		[DWUpdatedDate],
		[DWUpdatedBy]
		)
		VALUES
		(
		B.[CountryName],
		B.Region,
		B.[IsActive], -- The record exists, therefor IsCurrent=1
		@DWDate, -- DWCreatedDate
		@DWUser,   -- DWCreatedBy
		@DWDate, -- DWUpdatedDate
		@DWUser    -- DWUpdatedBy
		)

	WHEN NOT MATCHED BY SOURCE AND A.IsActive = 1 THEN -- In target, not in source, do soft delete (hard deleted at source)
	UPDATE SET
		A.IsActive = CONVERT(BIT,0),
		A.DWUpdatedDate = @DWDate,
		A.DWUpdatedBy = @DWUser;


--------------------------------------------END-----------------------------------------------------------------

GO
/****** Object:  StoredProcedure [dbo].[sp_LoadDimCustomer]    Script Date: 12/12/2015 7:23:31 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*This procedure will load the Customer data from Staging to EDW Dimension*/

CREATE PROC [dbo].[sp_LoadDimCustomer]
AS
DECLARE @DWDate AS Datetime=GetDate()
DECLARE @DWUser AS Varchar(50)=Cast(System_User AS Varchar(50))


--For first time load enter the Default Data.
IF NOT EXISTS (SELECT top 1 * FROM DimCustomer)
BEGIN
    SET IDENTITY_INSERT DimCustomer ON 
	
	INSERT INTO DimCustomer
	(CustomerKey
	,CustomerID
	,DataSourceKey
	,FullName
	,LocationKey
	,DateOfBirth
	,Age
	,Gender
	,MaritalStatus
	,IsActive
	,DWCreatedDate
	,DWUpdatedDate
	,DWCreatedBy
	,DWUpdatedBy
	)
	VALUES 
		(
		0,
		0,
		0,
		'UNKOWN',
		0,
		'1900-01-01 00:00:00.00',
		0 ,
		'UNKNOWN',
		'UNKNOWN',
		1,
		@DWDate,
		@DWDate,
		@DWUser,
		@DWUser
		)
		Print ('Entered Default Row')
      SET IDENTITY_INSERT DimCustomer OFF
END



IF OBJECT_ID('tempdb..#DimCustomer') IS NOT NULL
    DROP TABLE #DimCustomer

CREATE Table #DimCustomer
(
	CustomerID int NOT NULL,
	[DataSourceKey] [tinyint] NOT NULL,
	[FullName] [nvarchar](200) NULL,
	[AddressLine1] varchar(100) NULL,
	[AddressLine2] varchar(100) NULL,
	[PhoneNumber] varchar(100) NULL,
	[LocationKey] [int] NOT NULL,
	[DateOfBirth] [smalldatetime]  NULL,
	[Age] [smallint]  NULL,
	[Gender] [varchar](7)  NULL,
	[MaritalStatus] [varchar](10)  NULL,
	[IsActive] [bit] NOT NULL,
)

--Get cleaned info from Source 

Insert into #DimCustomer
SELECT 
 A.CustomerID
,1 AS DataSourceKey
,A.FirstName+' '+A.LastName AS FullName
,A.AddressLine1
,A.AddressLine2
,A.PhoneNumber
,ISNULL(B.LocationKey,0) AS LocationKey
,NULL AS DateOfBirth
,NULL AS Age
,NULL AS Gender
,NULL AS MaritalStatus
,1 AS IsActive
FROM Staging.CustomerMaster A
LEFT JOIN DimLocation B ON A.City=B.City AND A.StateProvince=B.StateProvince AND B.IsActive=1

Print ('Temp Table is created. Ready to Merge with Target')


MERGE INTO [dbo].[DimCustomer] WITH (TABLOCK) AS A -- Target
USING #DimCustomer AS B WITH (TABLOCK) -- Source
	ON A.CustomerID=B.CustomerID
	-- In Source and Target (Updated only if the values changed in some way)
WHEN MATCHED AND
	A.IsActive<>B.IsActive
	OR A.FullName<>B.FullName
	OR A.AddressLine1<>B.AddressLine1
	OR A.AddressLine2<>B.AddressLine2
	OR A.PhoneNumber<>B.PhoneNumber
	OR A.LocationKey<>B.LocationKey
THEN
UPDATE SET
	   
	     A.FullName=B.FullName
	    ,A.AddressLine1=B.AddressLine1
	    ,A.AddressLine2=B.AddressLine2
	    ,A.PhoneNumber=B.PhoneNumber
	    ,A.LocationKey=B.LocationKey
	    ,A.IsActive = B.IsActive
		,A.DWUpdatedDate = @DWDate
		, A.DWUpdatedBy = @DWUser
	
WHEN NOT MATCHED BY TARGET THEN -- In source, not in target (new value)
		INSERT
		(
		 CustomerID
		,DataSourceKey
		,FullName
		,AddressLine1
		,AddressLine2
		,PhoneNumber
		,LocationKey
		,DateOfBirth
		,Age
		,Gender
		,MaritalStatus
		,IsActive
		,[DWCreatedDate]
		,[DWCreatedBy]
		,[DWUpdatedDate]
		,[DWUpdatedBy]
		)
		VALUES
		(
		 B.CustomerID
		,B.DataSourceKey
		,B.FullName
		,B.AddressLine1
		,B.AddressLine2
		,B.PhoneNumber
		,B.LocationKey
		,B.DateOfBirth
		,B.Age
		,B.Gender
		,B.MaritalStatus
		,B.[IsActive], -- The record exists, therefor IsCurrent=1
		@DWDate, -- DWCreatedDate
		@DWUser,   -- DWCreatedBy
		@DWDate, -- DWUpdatedDate
		@DWUser    -- DWUpdatedBy
		)

	WHEN NOT MATCHED BY SOURCE AND A.IsActive = 1 THEN -- In target, not in source, do soft delete (hard deleted at source)
	UPDATE SET
		A.IsActive = CONVERT(BIT,0),
		A.DWUpdatedDate = @DWDate,
		A.DWUpdatedBy = @DWUser;

--------------------------------------------END-----------------------------------------------------------------
GO
/****** Object:  StoredProcedure [dbo].[sp_LoadDimLocation]    Script Date: 12/12/2015 7:23:31 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_LoadDimLocation]
AS
DECLARE @DWDate AS Datetime=GetDate()
DECLARE @DWUser AS Varchar(50)=Cast(System_User AS Varchar(50))


--For first time load enter the Default Data.

IF NOT EXISTS (SELECT top 1 * FROM DimLocation)
BEGIN
    SET IDENTITY_INSERT DimLocation ON 
	INSERT INTO DimLocation
	(LocationKey
	,City
	,StateProvince
	,CountryKey
	,IsActive
	,DWCreatedDate
	,DWUpdatedDate
	,DWCreatedBy
	,DWUpdatedBy
	)
	VALUES 
		(
		0,
		'UNKOWN' ,
		'UNKOWN',
		0,
		1,
		@DWDate,
		@DWDate,
		@DWUser,
		@DWUser
		)
Print ('Entered Default Row')
      SET IDENTITY_INSERT DimLocation OFF
END



IF OBJECT_ID('tempdb..#DimLocation') IS NOT NULL
    DROP TABLE #DimLocation

CREATE Table #DimLocation
(
City	nvarchar(200)  NOT NULL,
StateProvince	nvarchar(200) NOT NULL,
CountryKey	int NOT NULL
,IsActive	bit NOT NULL
)

--Get Location cleaned Location info Source 
SELECT DISTINCT City, StateProvince, Country into #City FROM Staging.CustomerMaster



Insert into #DimLocation
SELECT 
	A.City, 
	A.StateProvince,
	ISNULL(B.CountryKey,0) AS CountryKey,
	1 AS IsActive
FROM #City A
LEFT JOIN DimCountry B ON A.Country=B.CountryName

Print ('Temp Table is created. Ready to Merge with Target')



MERGE INTO [dbo].[DimLocation] WITH (TABLOCK) AS A -- Target
USING #DimLocation AS B WITH (TABLOCK) -- Source
	ON A.City = B.City AND
	   A.StateProvince=B.StateProvince
	-- In Source and Target (Updated only if the values changed in some way)
WHEN MATCHED AND
	A.IsActive<>B.IsActive
	OR A.CountryKey<>B.CountryKey
	THEN
UPDATE SET
	    A.CountryKey=B.CountryKey,
		A.IsActive = B.IsActive,
		A.DWUpdatedDate = @DWDate,
		A.DWUpdatedBy = @DWUser
	
WHEN NOT MATCHED BY TARGET THEN -- In source, not in target (new value)
		INSERT
		(
		City,
		StateProvince,
		CountryKey,
		IsActive,
		[DWCreatedDate],
		[DWCreatedBy],
		[DWUpdatedDate],
		[DWUpdatedBy]
		)
		VALUES
		(
		B.City,
		B.StateProvince,
		B.CountryKey,
		B.[IsActive], -- The record exists, therefor IsCurrent=1
		@DWDate, -- DWCreatedDate
		@DWUser,   -- DWCreatedBy
		@DWDate, -- DWUpdatedDate
		@DWUser    -- DWUpdatedBy
		)

	WHEN NOT MATCHED BY SOURCE AND A.IsActive = 1 THEN -- In target, not in source, do soft delete (hard deleted at source)
	UPDATE SET
		A.IsActive = CONVERT(BIT,0),
		A.DWUpdatedDate = @DWDate,
		A.DWUpdatedBy = @DWUser;


--------------------------------------------END-----------------------------------------------------------------

GO
/****** Object:  StoredProcedure [dbo].[sp_LoadDimProduct]    Script Date: 12/12/2015 7:23:31 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*This procedure will load the Product data from Staging to EDW Dimension*/

CREATE PROC [dbo].[sp_LoadDimProduct]
AS


DECLARE @DWDate AS Datetime=GetDate()
DECLARE @DWUser AS Varchar(50)=Cast(System_User AS Varchar(50))


IF OBJECT_ID('tempdb..#DimProduct') IS NOT NULL
    DROP TABLE #DimProduct

CREATE Table #DimProduct
(
ProductID int NOT NULL,
ProductName	nvarchar(200) NOT NULL
,ProductGroupName	nvarchar(50) NOT NULL
,IsActive	bit NOT NULL
)

Insert into #DimProduct
SELECT 
	A.ProductID, 
	A.Name AS ProductName,
	B.Name AS ProductGroupName,	
	1 AS IsActive
FROM Staging.ProductMaster A
INNER JOIN Staging.ProductCategory B ON A.ProductGroupID=B.ProductCategoryID


MERGE INTO [dbo].[DimProduct] WITH (TABLOCK) AS A -- Target
USING #DimProduct AS B WITH (TABLOCK) -- Source
	ON A.ProductID = B.ProductID
	-- In Source and Target (Updated only if the values changed in some way)
WHEN MATCHED AND
	A.IsActive<>B.IsActive
	OR A.ProductName<>B.ProductName
	OR A.ProductGroupName<>B.ProductGroupName
	THEN
UPDATE SET
	    A.ProductName=B.ProductName,
	    A.ProductGroupName=B.ProductGroupName,
		A.IsActive = B.IsActive,
		A.DWUpdatedDate = @DWDate,
		A.DWUpdatedBy = @DWUser
	
WHEN NOT MATCHED BY TARGET THEN -- In source, not in target (new value)
		INSERT
		(
		ProductID,
		ProductName,
		ProductGroupName,
		IsActive,
		[DWCreatedDate],
		[DWCreatedBy],
		[DWUpdatedDate],
		[DWUpdatedBy]
		)
		VALUES
		(
		B.ProductID,
		B.ProductName,
		B.ProductGroupName,
		B.[IsActive], -- The record exists, therefor IsCurrent=1
		@DWDate, -- DWCreatedDate
		@DWUser,   -- DWCreatedBy
		@DWDate, -- DWUpdatedDate
		@DWUser    -- DWUpdatedBy
		)

	WHEN NOT MATCHED BY SOURCE AND A.IsActive = 1 THEN -- In target, not in source, do soft delete (hard deleted at source)
	UPDATE SET
		A.IsActive = CONVERT(BIT,0),
		A.DWUpdatedDate = @DWDate,
		A.DWUpdatedBy = @DWUser;


--------------------------------------------END-----------------------------------------------------------------
GO
/****** Object:  StoredProcedure [dbo].[sp_LoadFactOnlineSales]    Script Date: 12/12/2015 7:23:31 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*This procedure will load the Online Sales data from Staging to EDW Dimension*/

CREATE PROC [dbo].[sp_LoadFactOnlineSales]
AS

DECLARE @DWDate AS Datetime=GetDate()
DECLARE @DWUser AS Varchar(50)=Cast(System_User AS Varchar(50))


INSERT INTO FactOnlineSales
SELECT 
A1.SalesOrderID	AS SalesOrderID
,A1.SalesOrderDetailID AS SalesOrderDetailID
,ISNULL(C.ProductKey,0) AS ProductKey
,ISNULL(D.DateKey,0) AS OrderDateKey
,ISNULL(B.CustomerKey,0) AS CustomerKey
,ISNULL(B.LocationKey,0) AS ShippingLocationKey
,ISNULL(E.CountryKey,0) AS CountryKey
,A1.UnitPrice AS UnitPrice
,A1.OrderQty AS Quantity
,A1.LineTotal AS SalesAmount
,GetDate() AS DWCreatedDate
,CAST(System_User AS Varchar(50)) AS DWCreatedBy
FROM Staging.OnlineSalesOrderDetail A1
INNER JOIN Staging.OnlineSalesOrderHeader A2 ON A1.SalesOrderID=A2.SalesOrderID
LEFT JOIN DimCustomer B ON A2.CustomerID=B.CustomerID AND B.IsActive=1
LEFT JOIN DimProduct C ON A1.ProductID=C.ProductID AND C.IsActive=1
LEFT JOIN DimDate D ON A1.ModifiedDate=D.CalendarDate
LEFT JOIN DimLocation E ON B.LocationKey=E.LocationKey AND E.IsActive=1
LEFT JOIN FactOnlineSales F ON A1.SalesOrderDetailID=F.SalesOrderDetailID
WHERE F.SalesOrderDetailID IS NULL

----------------------------------------------END-----------------------------------------------------------------

GO
/****** Object:  StoredProcedure [dbo].[sp_LoadFactStoreSales]    Script Date: 12/12/2015 7:23:31 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*This procedure will load the Country data from Staging to EDW Dimension*/

CREATE PROC [dbo].[sp_LoadFactStoreSales]
AS

DECLARE @DWDate AS Datetime=GetDate()
DECLARE @DWUser AS Varchar(50)=Cast(System_User AS Varchar(50))

INSERT INTO FactStoreSales
SELECT 
A.SalesOrderID	AS SalesOrderID
,A.SalesOrderDetailID AS SalesOrderDetailID
,B.CustomerKey AS StoreKey
,C.ProductKey AS ProductKey
,D.DateKey AS DateKey
,B.LocationKey AS LocationKey
,E.CountryKey AS CountryKey
,A.UnitPrice
,A.OrderQty
,A.SalesAmount
,GetDate() AS DWCreatedDate
,CAST(System_User AS Varchar(50)) AS DWCreatedBy
FROM Staging.StoreSales A
LEFT JOIN DimCustomer B ON A.CustomerID=B.CustomerID AND B.IsActive=1
LEFT JOIN DimProduct C ON A.ProductID=C.ProductID AND C.IsActive=1
LEFT JOIN DimDate D ON A.ModifiedDate=D.CalendarDate
LEFT JOIN DimLocation E ON B.LocationKey=E.LocationKey AND E.IsActive=1
LEFT JOIN FactStoreSales F ON A.SalesOrderDetailID=F.SalesOrderDetailID
WHERE F.SalesOrderDetailID IS NULL
	

--------------------------------------------END-----------------------------------------------------------------

GO
