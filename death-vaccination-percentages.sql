SELECT location, date, total_cases, new_cases, total_deaths, population
FROM `analyst-portfolio.COVID19.covid_deaths`
WHERE continent is not null
ORDER BY 1,2;

-- Looking at Total Cases vs Total Deaths
-- Showing likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, 
  (total_deaths/total_cases)*100 AS DeathPercentage
FROM `analyst-portfolio.COVID19.covid_deaths`
WHERE location = 'United States' AND continent is not null
ORDER BY 1,2;

-- Viewing Total Cases vs Population
-- Shows what percentage of the population contracted covid

SELECT location, date, population, total_cases,
  (total_cases/population)*100 AS percentpopulationinfected
FROM `analyst-portfolio.COVID19.covid_deaths`
WHERE location = 'United States' AND continent is not null
ORDER BY 1,2;

-- Looking at countries with highest Infection Rate compared to population

SELECT location, population, MAX(total_cases) AS highestinfectioncount,
  MAX((total_cases/population))*100 AS percentpopulationinfected
FROM `analyst-portfolio.COVID19.covid_deaths`
GROUP BY location, population
ORDER BY percentpopulationinfected DESC;

--Showing countries with highest death count per population

SELECT location, MAX(CAST (total_deaths AS int)) AS totaldeathcount
FROM `analyst-portfolio.COVID19.covid_deaths`
WHERE continent is not null
GROUP BY location
ORDER BY totaldeathcount DESC;

-- Death count by continent correct numbers

SELECT location, MAX(CAST (total_deaths AS int)) AS totaldeathcount
FROM `analyst-portfolio.COVID19.covid_deaths`
WHERE continent is null
GROUP BY location
ORDER BY totaldeathcount DESC;

-- incorporating continent column for visualation and drip down effect

SELECT continent, MAX(CAST (total_deaths AS int)) AS totaldeathcount
FROM `analyst-portfolio.COVID19.covid_deaths`
WHERE continent is not null
GROUP BY continent
ORDER BY totaldeathcount DESC;

-- Global Numbers

-- death percentage by date

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
FROM `analyst-portfolio.COVID19.covid_deaths`
WHERE continent is not null
GROUP BY date
ORDER BY 1,2;

--overall death percentage

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
FROM `analyst-portfolio.COVID19.covid_deaths`
WHERE continent is not null
ORDER BY 1,2;

--total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date)
AS rollingpeoplevaccinated
FROM `analyst-portfolio.COVID19.covid_deaths` as dea
JOIN `analyst-portfolio.COVID19.covid_vaccinations` as vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3;

-- USE CTE

WITH popvsvac
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date)
AS rollingpeoplevaccinated
FROM `analyst-portfolio.COVID19.covid_deaths` as dea
JOIN `analyst-portfolio.COVID19.covid_vaccinations` as vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (rollingpeoplevaccinated/population)*100 AS percentvaccinated
FROM popvsvac;

-- use temporary table
DROP VIEW IF EXISTS COVID19.percentpopulationvaccinated;
DROP TABLE IF EXISTS analyst-portfolio.COVID19.percentpopulationvaccinated;

CREATE TEMP TABLE percentpopulationvaccinated
AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date)
AS rollingpeoplevaccinated
FROM `analyst-portfolio.COVID19.covid_deaths` as dea
JOIN `analyst-portfolio.COVID19.covid_vaccinations` as vac
  ON dea.location = vac.location
  AND dea.date = vac.date;

SELECT *, (rollingpeoplevaccinated/population)*100
FROM `analyst-portfolio.COVID19.percentpopulatedvaccinated`;

-- create view to use for data visualization

CREATE VIEW COVID19.percentpopulationvaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date)
AS rollingpeoplevaccinated
FROM `analyst-portfolio.COVID19.covid_deaths` as dea
JOIN `analyst-portfolio.COVID19.covid_vaccinations` as vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent is not null;

SELECT *
FROM percentpopulationvaccinated;
