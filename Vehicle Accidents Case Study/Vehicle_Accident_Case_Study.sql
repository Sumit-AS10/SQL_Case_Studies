CREATE DATABASE IF NOT EXISTS accident_analysis;


/*
Q1. How many accidents have occured in urban areas vs rural areas ?
*/

SELECT 
       *
     , No_of_accidents/(SELECT COUNT(*)
						FROM accident)*100 AS 'accident_percentage'
FROM (
		SELECT 
			   Area
			 , COUNT(*) AS 'No_of_accidents'
		FROM accident
			GROUP BY Area
			ORDER BY Area
	 ) areas
GROUP BY Area;

/*
Q2. Which day of the week has the highest number of accidents ?
*/

SELECT 
     *
FROM accident
LIMIT 10;

SELECT 
       Day
     , COUNT(*) AS 'Most_accident_of_the_day'
FROM accident
	GROUP BY Day
    ORDER BY Most_accident_of_the_day DESC;
    
/*
Q3 What is the average age of vehicles involved in accidents based on their type ?
*/
SELECT 
     *
FROM accident
LIMIT 10;

SELECT 
     *
FROM vehicle
LIMIT 10;

SELECT 
       VehicleType
     , COUNT(vehicle.AccidentIndex) AS 'Total_accident'  
     , ROUND(AVG(AgeVehicle),0) AS 'Avg_year_of_vehicle'
FROM accident
JOIN vehicle
	ON accident.AccidentIndex = vehicle.AccidentIndex
    WHERE AgeVehicle IS NOT NULL
    GROUP BY VehicleType
    ORDER BY Total_accident DESC
		   , Avg_year_of_vehicle DESC;
           
/*
Q4 Can we identify any trends in accidents based on the ages of vehichles involved ?
*/


ALTER TABLE accident
ADD COLUMN Dates DATE DEFAULT NULL;

UPDATE accident
SET Dates = str_to_date(Date, '%e/%c/%Y');

ALTER TABLE accident
MODIFY COLUMN Date date;

UPDATE accident
SET Date = Dates;

ALTER TABLE accident
DROP COLUMN Dates;

SELECT *
FROM accident
LIMIT 10;
SELECT *
FROM vehicle
LIMIT 10;

SELECT 
	  Age_group_of_vehicle
	, COUNT(*) AS 'No_Of_accident'
    , ROUND(AVG(AgeVehicle),0) AS 'Avg_year_vehicle'
FROM (SELECT AccidentIndex
			 , AgeVehicle
			 , CASE
				  WHEN AgeVehicle BETWEEN 0 AND 5 THEN 'New'
				  WHEN AgeVehicle BETWEEN 6 AND 10 THEN 'Regular'
				  ELSE 'Old'
				  END AS 'Age_group_of_vehicle'
		FROM vehicle ) subquery
GROUP BY 
        Age_group_of_vehicle
ORDER BY 
		No_of_accident DESC;
        
/*
Q5 Are there any specific weather conditions that contribute to servere accidents ?
*/

SELECT 
	  WeatherConditions
	, COUNT(*) AS 'No_of_accidents'
FROM accident
WHERE 
     Severity = 'Slight'
	GROUP BY 
			WeatherConditions
	ORDER BY
			No_of_accidents DESC;
            
/*
Q6 Do accidents often involve impacts on the left hand side of vehicles ?
*/

SELECT *
FROM vehicle
LIMIT 10;

SELECT LeftHand
     , accidents/ (SELECT COUNT(*)
				   FROM vehicle )*100 AS 'accident_Percentage'
FROM ( SELECT leftHand
			 , COUNT(*) AS 'accidents'
		FROM vehicle
			GROUP BY 
					LeftHand ) subquery
GROUP BY LeftHand;

/*
Q7 Are there any relationships between journey purposes and the severity of accidents ?
*/
SELECT *
FROM accident
JOIN vehicle
	ON accident.AccidentIndex = vehicle.AccidentIndex
LIMIT 10;


WITH relation AS (SELECT
						  JourneyPurpose
						 , COUNT(*) AS 'caution'
					FROM accident
					JOIN vehicle
						ON accident.AccidentIndex = vehicle.AccidentIndex
						GROUP BY 
								JourneyPurpose
					   ORDER BY caution DESC)
SELECT 
	  JourneyPurpose
     , caution
     , caution/(SELECT COUNT(vehicle.AccidentIndex)
                FROM vehicle
                JOIN accident
					ON vehicle.AccidentIndex = accident.AccidentIndex)*100 AS 'caution_percentage'
FROM relation;

/*
Q8 Calculate the average age of vehicles involved in accidents, Considering Day light
   and point of Impact ?
*/

SELECT *
FROM accident
LIMIT 10;

SELECT *
FROM vehicle
LIMIT 10;

WITH accident_impact AS (SELECT LightConditions
							 , PointImpact
							 , FLOOR(AVG(AgeVehicle)) AS 'Avg_vehicle_age'
							 , COUNT(*) AS 'accidents'
						FROM accident
						JOIN vehicle
							ON accident.AccidentIndex = vehicle.AccidentIndex
							GROUP BY LightConditions
								   , PointImpact
							ORDER BY accidents DESC)
SELECT LightConditions
     , PointImpact
     , Avg_vehicle_age
     , accidents/( SELECT COUNT(*)
				   FROM accident
				   JOIN vehicle
					 ON accident.AccidentIndex = vehicle.AccidentIndex )*100 AS 'Impact_Percent'
FROM accident_impact;