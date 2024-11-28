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


