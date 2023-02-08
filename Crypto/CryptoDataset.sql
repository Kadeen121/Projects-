Use CryptoCurrency
go
/*
Create schema vw
Create schema stg
*/
--First Step examine data for 
-- what dimension to build
-- how much cleaning is involved 
-- if there are NULLs. 
-- If NULLs, what to do with them 


/*
Select* 
from dbo.dataset --72,946

Select *
from dbo.dataset ds
where ds.[open]is Null or ds.[high] is Null or ds.[low] is Null or ds.[close] is Null  ---648


--There are three Coin which has no information 
--Dogecoin  for a few days in may 2015
--Terra Classic a few days in  June and August 2022
--Shiba Inu had no information
--Given that the majority of Null belong to one coin and there nulls are few days over for the other coin I will OMIT

--Therefore  to eliminate the following query is needed
Select ds.*
from dbo.dataset ds
where ds.[open] is not null and ds.[high] is not Null and ds.[low] is not Null and ds.[close] is not Null  
*/

Go 
Drop table if exists stg.DataSet

Select *
into stg.DataSet
from dbo.dataset cr
where cr.column1 in(Select ds.column1
                    from dbo.dataset ds
                    where ds.[open] is not null and ds.[high] is not Null and ds.[low] is not Null and ds.[close] is not Null) 
order by 1 --72,298
;
/*
select *
From stg.DataSet
;
*/

-- Crypto Name dimension
Go 
Drop table if exists stg.CryptoName

Select distinct crypto_name
into stg.CryptoName
from stg.DataSet cr
order by 1


go
Create or Alter view vw.dCryptoName
as 
Select ROW_NUMBER () over (order by crypto_name)+1000 as CryptoID
      ,crypto_name as 'Crypto'
From stg.CryptoName



---Time Dimension
go
Drop table if exists stg.Calendar;
Go

DECLARE @StartDate  date 
Set @StartDate = '20120101';

DECLARE @CutoffDate date 
Set @CutoffDate = DATEADD(DAY, -1, DATEADD(YEAR, 14, @StartDate));

---change nothing below
;WITH seq(n) AS 
(
  SELECT 0 UNION ALL SELECT n + 1 FROM seq
  WHERE n < DATEDIFF(DAY, @StartDate, @CutoffDate)
),
d(d) AS 
(
  SELECT DATEADD(DAY, n, @StartDate) FROM seq
),
src AS
(
  SELECT
   
    bkDateKey		 = CAST(REPLACE(CONVERT(varchar(10), d),'-','') as INT),
	Date         = CONVERT(date, d),
---	DateKeyAlt   = convert(bgint),
    DayofMonth   = DATEPART(DAY,       d),
    DayName      = DATENAME(WEEKDAY,   d),
    Week         = DATEPART(WEEK,      d),
    ISOWeek      = DATEPART(ISO_WEEK,  d),
    DayOfWeek    = DATEPART(WEEKDAY,   d),
    Month        = DATEPART(MONTH,     d),
    MonthName    = DATENAME(MONTH,     d),
    MonthAbbrev  = LEFT(DATENAME(MONTH, d),3),
    Quarter      = DATEPART(Quarter,   d),
	(Case
	     when Datepart(Quarter,   d)=1 then 'Q1'
		 when Datepart(Quarter,   d)=2 then 'Q2'
         when Datepart(Quarter,   d)=3 then 'Q3'
		 when Datepart(Quarter,   d)=4 then 'Q4'
		 else 'Err'
      END) as QTR,
    Year         = DATEPART(YEAR,      d),
    FirstOfMonth = DATEFROMPARTS(YEAR(d), MONTH(d), 1),
    LastOfYear   = DATEFROMPARTS(YEAR(d), 12, 31),
    DayOfYear    = DATEPART(DAYOFYEAR, d)
  FROM d
)
SELECT * 
INTO stg.Calendar
FROM src
  ORDER BY Date
  OPTION (MAXRECURSION 0);


go
Create or Alter view vw.dCalendar
as 
Select *
From stg.Calendar

--Building Facts Tables 

go
Drop table if exists stg.Facts;
Go

Select * 
into stg.Facts
From stg.DataSet sal




go 
Create or Alter view vw.fCrypto
as 

select cn.CryptoID
      ,cal.bkDateKey
	  ,fc.[open] as 'OpenPrice'
	  ,fc.[high] as 'HighPrice'
	  ,fc.[low] as 'LowPrice'
	  ,fc.[close] as 'ClosePrice'
	  ,fc.volume as  'Quantity'yhjio 445
	  ,fc.marketCap as 'MarketCap'
from stg.Facts fc --72,946
     inner join vw.dCalendar cal
	  on cal.Date = fc.date --72,946
     inner join vw.dCryptoName cn
	  on cn.Crypto = fc.crypto_name --72,946
