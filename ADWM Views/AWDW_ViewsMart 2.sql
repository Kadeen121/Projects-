use AWDWpt2
go 

/* the business requirement is as follows:
- Total Sales by Order
- total sales as order level
- line item count
- by country
- channel
- by date, by year, by month 
- by special offer
*/

Create or Alter View vw.fSalesbyOrder
as
select sal.SalesOrderID
      ,cal.[Date]
	  ,cal.[Year]
	  ,cal.[Quarter]
	  ,cal.[Month]
	  ,cal.[MonthName]
	  ,ter.SalesCountry as 'Country'
      ,cha.Channel
	  ,count(sal.LineItem) as LineCount 
	  --,max(sal.lineItem) as 'LineCount'
	  ,sum(sal.LineTotal) as TotalSales
From vw.fSales sal
     inner join vw.dSalesTerritory ter
	  on sal.TerritoryID = ter.TerritoryID
	 inner join vw.dChannel cha
	  on cha.OnlineOrderFlag = sal.OnlineOrderFlag
	 inner join vw.dCalendar cal
	  on cal.bkDateKey = sal.bkDateKey
group by  ter.SalesCountry 
         ,sal.SalesOrderID
         ,cha.Channel
	     ,cal.[Date]
	     ,cal.[Month]
	     ,cal.[Year]
		 ,cal.[Quarter]
	     ,cal.[MonthName]
---order by sal.SalesOrderID
; 
GO
---121,317at the atomic grain
/* Summary fact table to SalesOrder grain
*/
Go
Create or Alter view vw.fSalesSummary
as
Select SalesOrderID 
       ,bkDateKey
	   ,OnlineOrderFlag
	   ,CustomerID
	   ,SalesPersonID
	   ,TerritoryID
	   ,ShipMethodID
       ,max(LineItem) as LineItemCount
	   ,sum(SubTotal) as Total 
FRom vw.fSales
group by  SalesOrderID 
         ,bkDateKey
         ,OnlineOrderFlag
	     ,CustomerID
         ,SalesPersonID
	     ,TerritoryID
	     ,ShipMethodID
;
go 