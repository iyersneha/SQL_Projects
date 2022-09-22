# Covid-19 Data Exploration
-- Skills Used: Joins, CTEs, Temp Tables, Window Functions, Aggregate Functions, Views, Converting Data Types

UPDATE DataProjects.covid_deaths SET date = str_to_date(date, '%Y-%m-%d');
UPDATE DataProjects.covid_vaccinations SET date= str_to_date(date, '%Y-%m-%d');

SELECT * FROM DataProjects.covid_deaths 
WHERE continent != ''
ORDER BY 3,4;


-- select Data to start with 

SELECT location, date, total_cases, new_cases, total_deaths, new_deaths, population 
FROM DataProjects.covid_deaths
WHERE continent != ''
ORDER BY 1,2;

-- Counting the total number of days we have the data for
SELECT COUNT(DISTINCT date) AS total_days FROM DataProjects.covid_deaths;

-- Number of unique countries in each continent
SELECT COALESCE(continent, 'UNKNOWN' ) AS continent,
		COUNT(DISTINCT location) AS number_of_unique_countires
FROM DataProjects.covid_deaths 
GROUP BY continent
ORDER BY continent;


-- Looking at Total Cases Vs Total Deaths
-- Shows the likelihood of dying if you contract Covid in your country 

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM DataProjects.covid_deaths
WHERE location = 'India'
AND continent != ''
ORDER BY 1,2;

-- Looking at Total Cases Vs Total Population
-- Shows the percentage of population infected with Covid

SELECT location, date, population, total_cases,(total_cases/population)*100 AS PercentPopulationInfected
FROM DataProjects.covid_deaths
-- WHERE location = 'United States'
ORDER BY 1, 2;

-- Countries with Highest Infection Rate compared to Population
-- Looking at the percentage of population infected with Covid

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PercentPopulationInfected
FROM DataProjects.covid_deaths
-- WHERE location = 'United States'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Countries with Highest Death Count per Population 

SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount 
FROM DataProjects.covid_deaths
-- WHERE location = 'United States'
WHERE continent  != ''
GROUP BY location
ORDER BY TotalDeathCount DESC; 


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing Continent with the Highest Death Count per Population 
SELECT continent, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount 
FROM DataProjects.covid_deaths
-- WHERE location = 'United States'
WHERE continent  != ''
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- GLOBAL NUMBERS

-- cases and deaths per day across the world

SELECT  date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS UNSIGNED)) AS total_deaths,
(SUM(CAST(new_deaths AS UNSIGNED))/ SUM(new_cases)) * 100 AS DeathPercentage
FROM DataProjects.covid_deaths
-- WHERE location = 'India'
WHERE continent != ''
GROUP BY date
ORDER BY 1,2;

-- Overall cases vs death across the world

SELECT   SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS UNSIGNED)) AS total_deaths,
(SUM(CAST(new_deaths AS UNSIGNED))/ SUM(new_cases)) * 100 AS DeathPercentage
FROM DataProjects.covid_deaths
-- WHERE location = 'India'
WHERE continent != ''
ORDER BY 1,2;	

    
-- Looking at Total Population Vs Total Vaccinations
-- Percentage of Population that has received atleast one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(vac.new_vaccinations, UNSIGNED)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
-- ,(RollingVaccinations/dea.population) * 100
FROM DataProjects.covid_deaths dea
JOIN DataProjects.covid_vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent != ''
ORDER BY 2,3;	


-- Using CTE to perform calculation on Partition By in the previous query 
-- Gives the rolling percentage of population that has received atleast one Covid Vaccine
 
WITH PopvsVac(Continent, Location, Date, Population, New_Vaccinations, RollingVaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(vac.new_vaccinations, UNSIGNED)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
-- ,(RollingVaccinations/dea.population) * 100
FROM DataProjects.covid_deaths dea
JOIN DataProjects.covid_vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent != ''
ORDER BY 2,3percentpopulationvaccinatedview
)
SELECT *, (RollingVaccinations/ Population) * 100 AS RollingPercentVacc FROM PopvsVac;


-- Using Temp Table to perform calculation on Partition By in the previous query 

USE DataProjects;
DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
Continent varchar(255),
Location varchar(255),
Date date,
Population numeric,
New_Vaccinations numeric,
RollingVaccinations numeric
);

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(IFNULL(CONVERT(vac.new_vaccinations,UNSIGNED),0)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM DataProjects.covid_deaths dea
JOIN DataProjects.covid_vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent != '';
-- ORDER BY 2,3;

Select *, (RollingVaccinations/Population)*100 AS RollingPercentVacc
From PercentPopulationVaccinated;



-- Creating view to store data for visualization 

CREATE VIEW PercentPopulationVaccinatedView AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(vac.new_vaccinations, UNSIGNED)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
-- ,(RollingVaccinations/dea.population) * 100
FROM DataProjects.covid_deaths dea
JOIN DataProjects.covid_vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent != ''
ORDER BY 2,3;

SELECT * FROM PercentPopulationVaccinatedView;







