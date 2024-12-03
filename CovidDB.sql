Use CovidDB;


BACKUP DATABASE CovidDB
TO DISK = 'D:\SQL_Backups\CovidDB_FullBackup.bak'
WITH FORMAT, NAME = 'Full Backup of CovidDatabase';

CREATE DATABASE CovidDB_Snapshot ON 
(NAME = 'CovidDB', FILENAME = 'D:\SQL_Snapshots\CovidDB_Snapshot.ss')
AS SNAPSHOT OF CovidDB;

Drop table covid_19_india;

use master;

RESTORE DATABASE CovidDB 
FROM DATABASE_SNAPSHOT = 'CovidDB_Snapshot';

Select * from covid_19_india;

--1) Extract information about how many members from each state are cured, and dead
SELECT 
    State_UnionTerritory,
    SUM(Cured) AS Total_Cured,
    SUM(Deaths)  AS Total_Deaths
FROM 
    covid_19_india
GROUP BY 
    State_UnionTerritory;

--2) Find the state that has highest deathrate during covid19

SELECT Top 1
    State_UnionTerritory,
    SUM(Deaths) AS Total_Deaths,
    SUM(Confirmed) AS Total_Confirmed,
    SUM(Deaths)/ SUM(Confirmed) * 100 AS Death_Rate
FROM 
    covid_19_india
GROUP BY 
    State_UnionTerritory
ORDER BY 
    Death_Rate DESC;


--3)Find the count of people who got covaxine and covishield separately.
 
 Select * from covid_vaccine_statewise

 SELECT 
    SUM(Covaxin_Doses_Administered) AS Covaxin_Count,
    SUM(CoviShield_Doses_Administered) AS CoviShield_Count
FROM covid_vaccine_statewise;



--4) find the aggregation of male female and Transgenders who have got either of the vaccine.

SELECT 
    SUM(Male_Individuals_Vaccinated) AS Total_Males,
    SUM(Female_Individuals_Vaccinated) AS Total_Females,
    SUM(Transgender_Individuals_Vaccinated) AS Total_Transgenders
FROM covid_vaccine_statewise;


 
--5) find which vaccine is having highest count 
 
SELECT Top 1 
    Vaccine_Type,
    Total_Doses AS Highest_Count
FROM (
		SELECT 
			'Covaxin' as Vaccine_Type, SUM(Covaxin_Doses_Administered) AS Total_Doses
		FROM covid_vaccine_statewise
		UNION ALL
		SELECT 
			'CoviShield', SUM(CoviShield_Doses_Administered)
		FROM covid_vaccine_statewise
		UNION ALL
		SELECT 
			'Sputnik V', SUM(Sputnik_V_Doses_Administered)
		FROM covid_vaccine_statewise
	) AS Vaccine_Summary
ORDER BY Total_Doses DESC



--6)find the positive and negative test results for a particular state.
 Select * from StatewiseTestingDetails;
 SELECT 
    Date,
    State,
    TotalSamples,
    ISNULL(Negative, (TotalSamples - Positive)) AS Negative,
    Positive
FROM StatewiseTestingDetails
WHERE State = 'Andaman and Nicobar Islands'; 

--7) which states having maximum and minimum positive negative test results.

---Maximum +ve and -ve

WITH StatewiseSummary AS (
    SELECT 
        State,
        SUM(CAST(ISNULL(Negative, (TotalSamples - Positive))AS BIGINT)) AS Total_Negative,
		SUM(Positive) AS Total_Positive
    FROM StatewiseTestingDetails
    GROUP BY State
)
SELECT TOP 1 
    State,
    Total_Negative,
	Total_Positive
FROM StatewiseSummary
ORDER BY Total_Negative DESC;

--minimum +ve and -ve
WITH StatewiseSummary AS (
    SELECT 
        State,
        SUM(CAST(ISNULL(Negative, (TotalSamples - Positive))AS BIGINT)) AS Total_Negative,
		SUM(Positive) AS Total_Positive
    FROM StatewiseTestingDetails
    GROUP BY State
)
SELECT TOP 1 
    State,
    Total_Negative,
	Total_Positive
FROM StatewiseSummary
ORDER BY Total_Negative ASC;


-- **Joins:**
-- 1. Which country has the highest number of confirmed cases on a specific date?

SELECT TOP 1 s.State,s.Positive
FROM covid_19_india c
JOIN StatewiseTestingDetails s 
ON c.Date = s.Date
where s.Date='2020-04-24'
order BY s.Positive DESC;



 -- 2. Show the total number of deaths in each country, including provinces/states, for a given date.
 
 Select c.State_UnionTerritory,Sum(c.Deaths)
 from covid_19_india c
 join StatewiseTestingDetails s
 on c.Date=s.Date
 where c.Date='2020-04-17'
 Group by c.State_UnionTerritory




 --3. List the continents along with the total number of confirmed cases, deaths, and recoveries.

 Select c.State_UnionTerritory,
    CAST(SUM(CAST(ISNULL(s.Positive, 0) AS BIGINT)) AS BIGINT) AS Total_Confirmed_Cases,
    CAST(SUM(CAST(ISNULL(c.Deaths, 0) AS BIGINT)) AS BIGINT) AS Total_Deaths,
    CAST(SUM(CAST(ISNULL(s.TotalSamples, 0) AS BIGINT) - CAST(ISNULL(s.Positive, 0) AS BIGINT)) AS BIGINT) AS Total_Recoveries
 from covid_19_india c
 join StatewiseTestingDetails s
 on c.State_UnionTerritory=s.State
 Group by c.State_UnionTerritory
 


 --**Aggregate Functions:**
-- 4. Calculate the average number of new deaths per day across all countries.

Select (Sum(Deaths)/COUNT(Date)) as [Avgerage New Deaths]
From covid_19_india


 --5. Find the maximum number of active cases recorded in any country on a specific date.

 Select top 1 State_UnionTerritory,(Sum(Confirmed)-Sum(Deaths)-Sum(Cured)) as [Active Cases]
 from covid_19_india
 Where Date='2020-04-17'
 group by State_UnionTerritory
 Order by [Active Cases] DESC

 --**Stored Procedure:**
 --6. Create a stored procedure that returns the total number of recovered cases for a given country and date.

Create Proc TotRecoveredCases
@country nvarchar(50),
@date nvarchar(50),
@total int out
As
Begin
	Select @total= Sum(Cured) from  covid_19_india where Date=@date and State_UnionTerritory=@country;
end

Declare @total int
Exec TotRecoveredCases 'Kerala', '2020-03-03', @total out
Print @total


 --7. Design a stored procedure to update the number of deaths for a specific country and date.

 Create Proc UpdateDeathsByCountryAndDate
 @Deaths int,
@country nvarchar(50),
@date nvarchar(50)
As
Begin
	Update covid_19_india set Deaths=@Deaths where Date=@date and State_UnionTerritory=@country;
end

Exec UpdateDeathsByCountryAndDate 1,'Kerala', '2020-01-30'


 --**Views:**
-- 8. Create a view that displays the total number of cases (confirmed, deaths, and recovered) for each country on a specific date.
 
 Create View DisplayTotalConfirmedRecovered
 As
 Select c.Date,c.State_UnionTerritory,
    Confirmed,c.Deaths,
	c.Cured
 from covid_19_india c
 
 Select * from DisplayTotalConfirmedRecovered where Date='2020-01-30' and State_UnionTerritory='Kerala'


 -- 9. Implement a view to show the latest data (confirmed, deaths, recovered) for each country.

CREATE VIEW LatestCovidData 
AS
SELECT State_UnionTerritory,Max(Date) as LatestDate
FROM covid_19_india
GROUP BY State_UnionTerritory

SELECT c.State_UnionTerritory,c.Confirmed,c.Deaths,c.Cured,l.LatestDate
FROM covid_19_india c
JOIN LatestCovidData l
ON c.State_UnionTerritory = l.State_UnionTerritory AND c.Date = l.LatestDate;
 

 -- **T-SQL:**
 --10. Write a T-SQL query to calculate the total number of cases (confirmed + deaths + recovered) for each country.
  
  Create or Alter Proc TotalCases
  @total bigint out
  As
  begin
  Set @total=0
 
	Select @total =( Cast(Cured as int) + Cast(Deaths as int) + Cast(Confirmed as int))
	from covid_19_india
	group by State_UnionTerritory
  end



  Declare @total bigint
  Exec TotalCases @total out
  Print @total

  
 
 
 --11. Use T-SQL to identify the country with the highest number of new cases reported on a specific date.

 
	CREATE VIEW HighestNewCasesByDate
	AS
	SELECT State_UnionTerritory,Sum(Confirmed) as [Highest New Cases],Date
	FROM covid_19_india
	GROUP BY State_UnionTerritory,Date
	

SELECT top 1 h.State_UnionTerritory,h.[Highest New Cases],h.Date
FROM HighestNewCasesByDate h
where h.Date='2020-03-30'
Order by h.[Highest New Cases] DESC




 --**CTE (Common Table Expressions):**
 --12. Create a CTE to calculate the percentage increase in confirmed cases for each country over the past week.
 
WITH WeeklyData AS (
    SELECT c.State_UnionTerritory AS Country,
		Sum(c.Confirmed) AS CurrentConfirmed,
        Sum(p.Confirmed) AS LastWeekConfirmed
    FROM covid_19_india c
    JOIN covid_19_india p
    ON c.State_UnionTerritory = p.State_UnionTerritory
        AND DATEADD(DAY, -7, c.Date) = p.Date
    Group By c.State_UnionTerritory
)
SELECT 
    Country,
    CAST((CurrentConfirmed - LastWeekConfirmed) * 100.0 / LastWeekConfirmed AS DECIMAL(10, 2)) as PercentageIncrease
FROM WeeklyData
WHERE LastWeekConfirmed IS NOT NULL and LastWeekConfirmed <> 0

 
 
 -- 13. Use a CTE to find the country with the highest number of active cases at the moment.
 With ActiveCases AS(
 Select State_UnionTerritory,(Sum(Confirmed)-Sum(Deaths)-Sum(Cured)) as [Active Cases]
 from covid_19_india
 group by State_UnionTerritory
 
 )
 Select Top 1 * from ActiveCases Order by [Active Cases] DESC 
 
 
 --**Indexes:**
 --14. Explain the importance of indexes in optimizing queries for this dataset.
 --15. Implement an index on the "Country/Region" column to speed up search operations.
 
CREATE INDEX idx_StateUnionTerritory 
ON covid_19_india (State_UnionTerritory);

 --**User-Defined Functions (UDF):**
 --16. Develop a UDF to calculate the mortality rate (deaths / confirmed cases * 100) for a given country.

CREATE FUNCTION CalculateMortalityRate( @Country NVARCHAR(50))
RETURNS FLOAT
AS
BEGIN
    DECLARE @MortalityRate FLOAT;
	SELECT @MortalityRate = CASE WHEN SUM(Confirmed) = 0 THEN 0
                            ELSE CAST(SUM(Deaths) AS FLOAT) * 100 / SUM(Confirmed)
                           END
    FROM covid_19_india
    WHERE State_UnionTerritory = @Country;

    RETURN @MortalityRate;
END;

SELECT dbo.CalculateMortalityRate('Kerala') AS MortalityRate;


 --17. Create a UDF to determine the recovery rate (recovered / confirmed cases * 100) for a specific date

CREATE FUNCTION CalculateRecoveryRate( @Date DATE)
RETURNS FLOAT
AS
BEGIN
    DECLARE @RecoveryRate FLOAT;
    SELECT @RecoveryRate = CASE WHEN SUM(Confirmed) = 0 THEN 0
                        ELSE CAST(SUM(Cured) AS FLOAT) * 100 / SUM(Confirmed)
                        END
    FROM covid_19_india
    WHERE Date = @Date;

    RETURN @RecoveryRate;
END;

SELECT dbo.CalculateRecoveryRate('2020-03-03') AS RecoveryRate;


 --**Group By:**
--18. Group the data by continent and calculate the total number of confirmed cases for each continent.

SELECT State_UnionTerritory,SUM(Confirmed) AS TotalConfirmedCases
FROM covid_19_india
GROUP BY State_UnionTerritory
ORDER BY TotalConfirmedCases DESC;


-- 19. Group the data by date and compute the total number of deaths and recoveries for each date.

SELECT Date,SUM(Deaths) AS TotalDeaths,
    SUM(Cured) AS TotalRecoveries
FROM covid_19_india
GROUP BY Date
ORDER BY Date;

 --20. Group the data by country and calculate the average number of new cases reported daily for each country.
 
 WITH DailyNewCases AS (
    SELECT c.State_UnionTerritory AS Country,
        c.Date AS CurrentDate,
        ISNULL(c.Confirmed - p.Confirmed, 0) AS NewCases
    FROM covid_19_india c
    JOIN covid_19_india p
    ON c.State_UnionTerritory = p.State_UnionTerritory
        AND DATEADD(DAY, -1, c.Date) = p.Date
)
SELECT Country,AVG(NewCases) AS AverageDailyNewCases
FROM DailyNewCases
GROUP BY Country
ORDER BY AverageDailyNewCases DESC;



-------------------------------------------

-- 1. Death Percentage 
SELECT State_UnionTerritory,
    (SUM(Deaths) * 100.0) / SUM(Confirmed) AS LocalDeathPercentage
FROM covid_19_india
GROUP BY State_UnionTerritory
ORDER BY LocalDeathPercentage DESC;

--2. Infected Population Percentage :

SELECT State,
    (SUM(Positive) * 100.0) / Sum(TotalSamples) AS LocalInfectedPercentage
FROM dbo.StatewiseTestingDetails
GROUP BY State
ORDER BY LocalInfectedPercentage DESC;

-- 3. Countries with the Highest Infection Rates:


SELECT Top 1 State,
    (SUM(Positive) * 100.0) / Sum(TotalSamples) AS InfectionRate
FROM StatewiseTestingDetails
GROUP BY State, TotalSamples
ORDER BY InfectionRate DESC


--4. Countries with the Highest Death Counts:

SELECT State_UnionTerritory,
    SUM(Deaths) AS TotalDeaths
FROM covid_19_india
GROUP BY State_UnionTerritory
ORDER BY TotalDeaths DESC


--5. Average Number of Deaths by Day:

SELECT Date,State_UnionTerritory,
    AVG(Deaths) AS AvgDeathsPerDay
FROM covid_19_india
GROUP BY Date, State_UnionTerritory
ORDER BY State_UnionTerritory, Date;



--6. Average Cases per Population (Top 10):

SELECT Top 10 State,
    Avg(Positive) as [Average Cases],
	Sum(TotalSamples) AS Population
FROM StatewiseTestingDetails
GROUP BY State
ORDER BY Population DESC


--7. Countries with the Highest Rate of Infection (in Relation to Population):

SELECT c.State_UnionTerritory AS Country,
     CAST(SUM(CAST(c.Confirmed AS BIGINT)) * 100.0 / SUM(CAST(p.TotalSamples AS BIGINT)) AS DECIMAL(18, 2)) AS InfectionRate
FROM covid_19_india c
JOIN StatewiseTestingDetails p ON c.State_UnionTerritory = p.State
GROUP BY c.State_UnionTerritory, p.TotalSamples
ORDER BY InfectionRate DESC;

--8. Countries with the Highest Number of Deaths:

SELECT State_UnionTerritory,SUM(Deaths) AS TotalDeaths
FROM covid_19_india
GROUP BY State_UnionTerritory
ORDER BY TotalDeaths DESC

 --Queries on Vaccination:
 --1)Total vaccinated with at least 1 dose over time

 SELECT Updated_On AS Date,
    SUM(First_Dose_Administered) AS TotalFirstDoseVaccinated
FROM covid_vaccine_statewise
GROUP BY Updated_On
ORDER BY Date;



--2)Percentage of the population vaccinated with at least the first dose until 30/9/2021 (Top 3)

SELECT TOP 3 v.State,
    SUM(v.First_Dose_Administered) * 100.0 / Sum(p.TotalSamples) AS VaccinationPercentage
FROM covid_vaccine_statewise v
JOIN StatewiseTestingDetails p ON v.State = p.State
WHERE Updated_On <= '2021-09-30'
GROUP BY v.State, p.TotalSamples
ORDER BY VaccinationPercentage DESC;



-- Using JOINS to combine the covid_deaths and covid_vaccine tables :
 -- 1) To find out the population vs the number of people vaccinated

 SELECT d.State,Sum(d.TotalSamples) as Population,
	SUM(v.Second_Dose_Administered) AS TotalVaccinated
FROM StatewiseTestingDetails d
JOIN covid_vaccine_statewise v ON d.State = v.State
GROUP BY d.State
ORDER BY TotalVaccinated DESC;

--2) To find out the percentage of different vaccine taken by people in a country

SELECT v.State,
    SUM(v.Covaxin_Doses_Administered) * 100.0 / SUM(v.Total_Doses_Administered) AS CovaxinPercentage,
	SUM(v.CoviShield_Doses_Administered) * 100.0 / SUM(v.Total_Doses_Administered) AS CoviShieldPercentage,
	SUM(v.Sputnik_V_Doses_Administered) * 100.0 / SUM(v.Total_Doses_Administered) AS SputnicVPercentage
FROM 
    covid_vaccine_statewise v
GROUP BY 
    v.State;



-- 3) To find out percentage of people who took both the doses
SELECT d.State,SUM(d.Second_Dose_Administered) * 100.0 / Sum(s.TotalSamples) AS FullyVaccinatedPercentage
FROM covid_vaccine_statewise d
join StatewiseTestingDetails s on d.State=s.State
GROUP BY d.State
ORDER BY FullyVaccinatedPercentage DESC;

 -- Indian State Wise Analysis:
-- 1. Total State-wise Confirmed Cases

SELECT State_UnionTerritory AS State,
    SUM(Confirmed) AS TotalConfirmedCases
FROM covid_19_india
GROUP BY State_UnionTerritory
ORDER BY TotalConfirmedCases DESC;

 -- 2. Maximum Active cases State-wise till date
 SELECT State_UnionTerritory AS State,
    MAX(Confirmed - Deaths - Cured) AS MaxActiveCases
FROM covid_19_india
GROUP BY State_UnionTerritory;

 -- 3. Max Per Day Confirmed cases in States

 SELECT State_UnionTerritory AS State,
    MAX(Confirmed) AS MaxDailyConfirmedCases
FROM covid_19_india
GROUP BY State_UnionTerritory;

 -- 4. Max Per Day Death cases in States
 SELECT State_UnionTerritory AS State,
    MAX(Deaths) AS MaxDailyDeaths
FROM covid_19_india
GROUP BY State_UnionTerritory;

 -- 5. State-wise Mortality Rate
 SELECT State_UnionTerritory AS State,
    SUM(Deaths) * 100.0 / SUM(Confirmed) AS MortalityRate
FROM covid_19_india
GROUP BY State_UnionTerritory
ORDER BY MortalityRate DESC;

 --6. Covid Waves in ‘Mumbai'

 SELECT FORMAT([Date], 'yyyy-MM') AS Month,
	SUM(ISNULL(Positive, 0)) AS TotalPositiveCases,
    SUM(ISNULL(Negative, 0)) AS TotalNegativeCases
FROM StatewiseTestingDetails
where State ='Maharashtra'
GROUP BY FORMAT([Date], 'yyyy-MM')
ORDER BY Month;


Select * from covid_19_india;
Select * from covid_vaccine_statewise;
Select * from StatewiseTestingDetails;



