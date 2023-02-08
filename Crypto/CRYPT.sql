select cn.Crypto
      ,cal.[Year]

	  ,cal.[Year]
	  ,(cry.ClosePrice)
from vw.fCrypto cry
     inner join vw.dCalendar cal 
	  on cry.bkDateKey = cal.bkDateKey 
	  and cal.DayOfYear =(Select max(dayofyear)
From vw.dCalendar
group by year)
	  inner join vw.dCryptoName cn
	  on cn.CryptoID = cry.CryptoID

Select max(dayofyear)
From vw.dCalendar
group by year