Use portfolioproject;

Select * From CovidDeaths;

Select * From CovidVaccinations;
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Where continent is not null 
order by 1,2;
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths
Where location like '%states%'
and continent is not null 
order by 1,2;
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths
Where location like '%states%'
order by 1,2;
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc;
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Countries with Highest Death Count per Population

Select Location, MAX(Total_deaths) as TotalDeathCount
From CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc;
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population

Select continent, MAX(Total_deaths) as TotalDeathCount
From CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc;
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
where continent is not null 
order by 1,2;
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT sub.continent, sub.location, sub.date, sub.population, sub.new_vaccinations,
       sub.RollingPeopleVaccinated,
       (sub.RollingPeopleVaccinated / sub.population) * 100 AS VaccinationRate
FROM (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM CovidDeaths dea
    JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
) AS sub
ORDER BY sub.location, sub.date;
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM CovidDeaths dea
    JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *,
       (RollingPeopleVaccinated / population) * 100 AS VaccinationRate
FROM PopvsVac
ORDER BY location, date;
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TABLE PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date;

SELECT *,
       (RollingPeopleVaccinated / Population) * 100 AS VaccinationRate
FROM PercentPopulationVaccinated
ORDER BY Location, Date;
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Creating View to store data for later visualizations
-- Drop the table if it already exists

DROP TABLE IF EXISTS PercentPopulationVaccinated;

-- Create the new table
CREATE TABLE PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);
percentpopulationvaccinated
-- Insert data into the table
INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Select from the table and calculate the VaccinationRate
SELECT *,
       (RollingPeopleVaccinated / Population) * 100 AS VaccinationRate
FROM PercentPopulationVaccinated
ORDER BY Location, Date;
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------