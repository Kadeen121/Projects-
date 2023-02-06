Use Mushrooms 
Go 

/* The data  set being examine is Mushrooms from https://www.bibalex.org/SCIplanet/en/Article/Details.aspx?id=13515

Select *
from dbo.primary_data-- 173 records
;


*********Four-Step Dimensional Design Process*******
1.Select the business process.
  In this dataset process was identifing characteristics of a mushroom sample set. 

2.Declare the grain.
  The grain is mushrooms by each of these attributes like  habitat, gill colour, cap size, etc. 

3.Identify the dimensions.
  The dimensions being used are 
  a. Habitats
  b. Seasons
  c. Familty
  d. Toxicity 

4.Identify the facts.
  The facts in this set is the individual Mushrooms. 


********** Create Schemas for Proper table  and views naming ********
 --Create Schema stg
 --Create Schema vw
*/ 

--CREATE Stage table from Mushroom Data Table

-- Create Mushroom Family Staging table 
Go 
Drop table if exists stg.Family;
go
Select distinct family
into stg.Family
From dbo.primary_data
;

go 
Create or Alter view  vw.dFamily 
as
Select ROW_NUMBER () Over (order by fam.family)+100 as 'FamilyID'
       ,fam.family as 'Family' 
From stg.Family fam
;

---Creating Staging stable for Habitats 
Go 
Drop table if exists stg.Habitats;
go
Select distinct 
        (Case
	        When pd.habitat in ('[d, h]','[h,d]')  Then 'Woods/Heaths'
			When pd.habitat ='[d]'  Then 'Woods'
			When pd.habitat in ('[g, d, h]','[g, h, d]')  Then 'Grass/Woods/Heaths'
			When pd.habitat ='[g, d]'  Then 'Grass/Woods'
			When pd.habitat ='[g, l, d]'  Then 'Grass/Leaves/Woods'
			When pd.habitat ='[g, l, m, d]'  Then 'Grass/Leaves/Meadows/Woods'
			When pd.habitat ='[g, m, d]'  Then 'Grass/Meadows/Woods'
			When pd.habitat = '[g, m]' Then 'Grass/Meadows'
			When pd.habitat ='[g]'  Then 'Grass'
			When pd.habitat ='[g, u, d]'  Then 'Grass/Urban/Woods'
			When pd.habitat ='[l, d, h]'  Then 'Leaves/Woods/Heaths'
			When pd.habitat = '[l, d]' Then 'Leaves/Woods'
            When pd.habitat = '[l, h]' Then 'Leaves/Heaths'
			When pd.habitat = '[l]' Then 'Leaves'
			When pd.habitat = '[m, d]' Then 'Meadows/Woods'
			When pd.habitat = '[m, h]' Then 'Meadows/Heaths'
			When pd.habitat = '[m]' Then 'Meadows'
			When pd.habitat = '[p, d]' Then 'Paths/Woods'
			When pd.habitat = '[w]' Then 'Waste'
            When pd.habitat = '[h, d]' Then 'Woods/Heaths'
			ELSE 'ERROR' 
	     END) as 'Habitats'
		---,pd.habitat as 'stghabitats'  for stop double counting
into stg.Habitats		
from primary_data pd
order by Habitats asc 
;
--- Creating Habitats view from staging table 
go 
Create or Alter view vw.dHabitats
as
 Select ROW_NUMBER () Over (order by hb.Habitats) +200 as 'HabitatID'
       ,(hb.Habitats)        
 From stg.Habitats hb

 ---Creating staging table for the seasons in which the mushrooms can be harvested. 
Go 
Drop table if exists stg.Season;
go
Select distinct
           (Case
		        when pd.season = '[a, w]' then 'Autumn/Winter'
				when pd.season = '[a]' then 'Autumn'
				when pd.season = '[s, a, w]' then 'Spring/Autumn/Winter'
				when pd.season = '[s, u, a, w]' then 'All Year'
				when pd.season = '[s, u, a]' then 'Spring/Summer/Autumn'
				when pd.season = '[s, u]' then 'Spring/Summer'
				when pd.season = '[s]' then 'Spring'
				when pd.season = '[u, a, w]' then 'Summer/Autumn/Winter'
				when pd.season = '[u, a]' then 'Summer/Autumn'
                when pd.season = '[u]' then 'Summer'
				ELSE 'ERROR' 
			END) as 'Seasons'
			,pd.season as 'stg.season'
into stg.Season
From dbo.primary_data pd
;

Go 
Create or Alter view vw.dSeason
as
Select ROW_NUMBER () Over (order by ss.Seasons)+300 as 'SeasonID'
      ,ss.Seasons 
From stg.Season ss
;

--- Creating staging Table for Class
Go 
Drop table if exists stg.Class;
go

Select  distinct class as 'stgclass'
        ,(Case
            When cl.class = 'p' then 'Poisonous/Unknown Toxicity'
			When cl.class = 'e' Then 'Edible' 
			Else 'Err'
		END) as 'Class'
into stg.Class
From primary_data cl
;

-- Creating the view for Class
/*Select ROW_NUMBER () Over (order by Classes) as 'ClassID'
     ,(Case
            When cl.class = 'p' then 'Poisonous/Unknown Toxicity'
			When cl.class = 'e' Then 'Edible' 
			Else 'Err'
		END) as 'Classes'
from stg.class cl 
*/

Go 
Create or Alter view vw.dClass
as 

Select Case 
           When cl.Class = 'Edible' then 0
           When cl.Class = 'Poisonous/Unknown Toxicity' then 1
		   Else -99
	   End as 'MushroomClassID'
     ,Class as 'Class'
from stg.class cl 
; 

---MUSHROOM FACTS !!
/*Staging table for Mushroon facts as there are mushroom names being posulated twice as these are the one which the in fuction was used
This is beacuse in order join the Habitat view to the primary data table I had to reintroduce the orginal classification for habitats, 
which two habitats classifcations thats had the same same but in a diffrent order which I corrected in staging. However reintroduction has caused the data set increase
because I had changed the names two diffrent habitat groups had the same name so Mushrooms in those groups count twice under the same name but diffrent row number. 
Therefore I will be making a staging  primary table with  habitat case statement above and then join it to the primary table  to solve this set issue. 

Select distinct pd.[Name] as 'MushroomName' 
	  ,vh.HabitatID
from dbo.primary_data pd
     left outer join stg.Class sc
	  on sc.stgclass = pd.class
	left outer join vw.dClass vc
	  on sc.Class = vc.Class
	left outer join vw.dFamily vf
	  on pd.family = vf.Family
    left outer join stg.Habitats sh
	  on pd.habitat = sh.stghabitats
	inner join vw.dHabitats vh 
	  on sh.Habitats = vh.Habitats
	left join stg.Season ss
	  on ss.[stg.season] = pd.season 
	left join vw.dSeason vs
	  on ss.Seasons =vs.Seasons  */

--a CTE was done in order to remove duplicated from the base data table for the correct views to be done



Go 
Create or Alter view vw.fMushrooms
as
With Primdata
as
(
Select pd.[name] 
      ,pd.family
	  ,pd.class
	  ,pd.season
	  ,(Case
	        When pd.habitat in ('[d, h]','[h,d]')  Then 'Woods/Heaths'
			When pd.habitat ='[d]'  Then 'Woods'
			When pd.habitat in ('[g, d, h]','[g, h, d]')  Then 'Grass/Woods/Heaths'
			When pd.habitat ='[g, d]'  Then 'Grass/Woods'
			When pd.habitat ='[g, l, d]'  Then 'Grass/Leaves/Woods'
			When pd.habitat ='[g, l, m, d]'  Then 'Grass/Leaves/Meadows/Woods'
			When pd.habitat ='[g, m, d]'  Then 'Grass/Meadows/Woods'
			When pd.habitat = '[g, m]' Then 'Grass/Meadows'
			When pd.habitat ='[g]'  Then 'Grass'
			When pd.habitat ='[g, u, d]'  Then 'Grass/Urban/Woods'
			When pd.habitat ='[l, d, h]'  Then 'Leaves/Woods/Heaths'
			When pd.habitat = '[l, d]' Then 'Leaves/Woods'
            When pd.habitat = '[l, h]' Then 'Leaves/Heaths'
			When pd.habitat = '[l]' Then 'Leaves'
			When pd.habitat = '[m, d]' Then 'Meadows/Woods'
			When pd.habitat = '[m, h]' Then 'Meadows/Heaths'
			When pd.habitat = '[m]' Then 'Meadows'
			When pd.habitat = '[p, d]' Then 'Paths/Woods'
			When pd.habitat = '[w]' Then 'Waste'
            When pd.habitat = '[h, d]' Then 'Woods/Heaths'
			ELSE 'ERROR' 
	     END) as 'Habitats'
---into stg.Primdata 
from primary_data pd
)

Select distinct pd.[Name] as 'MushroomName' 
      ,vc.MushroomClassID
	  ,vs.SeasonID
	  ,vf.FamilyID
	  ,vh.HabitatID
from Primdata pd
     left outer join stg.Class sc
	  on sc.stgclass = pd.class
	left outer join vw.dClass vc
	  on sc.Class = vc.Class
	left outer join vw.dFamily vf
	  on pd.family = vf.Family
	left join stg.Season ss
	  on ss.[stg.season] = pd.season 
	left join vw.dSeason vs
	  on ss.Seasons =vs.Seasons 
	left outer join  vw.dHabitats vh
	  on pd.Habitats = vh.Habitats
;
--173

/*
---***************** VALIDATING THE DATA MART********************

**CLASS
Select mu.MushroomName 
      ,cl.Class
from vw.fMushrooms mu
     inner join vw.dClass cl
	  on mu.MushroomClassID = cl.MushroomClassID

*** FAMILY
Select mu.MushroomName 
      ,fm.Family
from vw.fMushrooms mu
     inner join vw.dFamily fm
	  on fm.FamilyID = mu.FamilyID

*****SEASON
Select mu.MushroomName 
      ,se.Seasons
from vw.fMushrooms mu
     inner join vw.dSeason se
	  on se.SeasonID = mu.SeasonID

***HABITAT
Select mu.MushroomName 
      ,hb.Habitats
from vw.fMushrooms mu
     inner join vw.dHabitats hb
	  on hb.HabitatID = mu.HabitatID
*/