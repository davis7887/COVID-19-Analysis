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

-- incorporating usa outbound flight data to find correlations with covid cases and vaccinations

SELECT *
FROM `analyst-portfolio.COVID19.total_usa_outbound`;

-- create CTE extracting covid cases by month and combine with usa outbound int flights

WITH cases
AS
(
SELECT
EXTRACT(year FROM date) as year, EXTRACT(month from date) as month, SUM(new_cases) as total_cases
FROM `analyst-portfolio.COVID19.covid_deaths`
GROUP BY EXTRACT(year FROM date), EXTRACT(month FROM date)
)

SELECT totout.year, cases.month, cases.total_cases, 
FROM `analyst-portfolio.COVID19.total_usa_outbound` as totout
RIGHT OUTER JOIN cases 
ON cases.year = totout.year
ORDER BY year DESC, month DESC;


-- create temp table tracking covid cases by month

DROP VIEW IF EXISTS COVID19.monthly_cases;
DROP TABLE IF EXISTS analyst-portfolio.COVID19.monthly_cases;

CREATE TEMP TABLE monthly_cases
AS
SELECT
EXTRACT(year FROM date) as year, 
(sum(case when EXTRACT(month from date) = 1 then new_cases end)) Jan 
  ,(sum(case when EXTRACT(month from date) = 2 then new_cases end)) Feb 
  ,(sum(case when EXTRACT(month from date) = 3 then new_cases end)) Mar
  ,(sum(case when EXTRACT(month from date) = 4 then new_cases end)) Apr
  ,(sum(case when EXTRACT(month from date) = 5 then new_cases end)) May
  ,(sum(case when EXTRACT(month from date) = 6 then new_cases end)) Jun
  ,(sum(case when EXTRACT(month from date) = 7 then new_cases end)) Jul
  ,(sum(case when EXTRACT(month from date) = 8 then new_cases end)) Aug
  ,(sum(case when EXTRACT(month from date) = 9 then new_cases end)) Sep
  ,(sum(case when EXTRACT(month from date) = 10 then new_cases end)) Oct
  ,(sum(case when EXTRACT(month from date) = 11 then new_cases end)) Nov
  ,(sum(case when EXTRACT(month from date) = 12 then new_cases end)) Dec
FROM `analyst-portfolio.COVID19.covid_deaths`
GROUP BY EXTRACT(year from date);

SELECT *
FROM monthly_cases
ORDER BY year;

CREATE VIEW COVID19.monthly_cases AS
SELECT
EXTRACT(year FROM date) as year, 
(sum(case when EXTRACT(month from date) = 1 then new_cases end)) Jan 
  ,(sum(case when EXTRACT(month from date) = 2 then new_cases end)) Feb 
  ,(sum(case when EXTRACT(month from date) = 3 then new_cases end)) Mar
  ,(sum(case when EXTRACT(month from date) = 4 then new_cases end)) Apr
  ,(sum(case when EXTRACT(month from date) = 5 then new_cases end)) May
  ,(sum(case when EXTRACT(month from date) = 6 then new_cases end)) Jun
  ,(sum(case when EXTRACT(month from date) = 7 then new_cases end)) Jul
  ,(sum(case when EXTRACT(month from date) = 8 then new_cases end)) Aug
  ,(sum(case when EXTRACT(month from date) = 9 then new_cases end)) Sep
  ,(sum(case when EXTRACT(month from date) = 10 then new_cases end)) Oct
  ,(sum(case when EXTRACT(month from date) = 11 then new_cases end)) Nov
  ,(sum(case when EXTRACT(month from date) = 12 then new_cases end)) Dec
FROM `analyst-portfolio.COVID19.covid_deaths`
GROUP BY EXTRACT(year from date);

SELECT *
FROM monthly_cases
ORDER BY year;


-- create table and view tracking covid vaccinations by month


DROP VIEW IF EXISTS COVID19.monthly_vacc;
DROP TABLE IF EXISTS analyst-portfolio.COVID19.monthly_vacc;

CREATE TEMP TABLE monthly_vacc
AS
SELECT
EXTRACT(year FROM date) as year, 
(sum(case when EXTRACT(month from date) = 1 then new_vaccinations end)) Jan 
  ,(sum(case when EXTRACT(month from date) = 2 then new_vaccinations end)) Feb 
  ,(sum(case when EXTRACT(month from date) = 3 then new_vaccinations end)) Mar
  ,(sum(case when EXTRACT(month from date) = 4 then new_vaccinations end)) Apr
  ,(sum(case when EXTRACT(month from date) = 5 then new_vaccinations end)) May
  ,(sum(case when EXTRACT(month from date) = 6 then new_vaccinations end)) Jun
  ,(sum(case when EXTRACT(month from date) = 7 then new_vaccinations end)) Jul
  ,(sum(case when EXTRACT(month from date) = 8 then new_vaccinations end)) Aug
  ,(sum(case when EXTRACT(month from date) = 9 then new_vaccinations end)) Sep
  ,(sum(case when EXTRACT(month from date) = 10 then new_vaccinations end)) Oct
  ,(sum(case when EXTRACT(month from date) = 11 then new_vaccinations end)) Nov
  ,(sum(case when EXTRACT(month from date) = 12 then new_vaccinations end)) Dec
FROM `analyst-portfolio.COVID19.covid_vaccinations`
GROUP BY EXTRACT(year from date);

SELECT *
FROM monthly_vacc
ORDER BY year;

CREATE VIEW COVID19.monthly_vacc AS
SELECT
EXTRACT(year FROM date) as year, 
(sum(case when EXTRACT(month from date) = 1 then new_vaccinations end)) Jan 
  ,(sum(case when EXTRACT(month from date) = 2 then new_vaccinations end)) Feb 
  ,(sum(case when EXTRACT(month from date) = 3 then new_vaccinations end)) Mar
  ,(sum(case when EXTRACT(month from date) = 4 then new_vaccinations end)) Apr
  ,(sum(case when EXTRACT(month from date) = 5 then new_vaccinations end)) May
  ,(sum(case when EXTRACT(month from date) = 6 then new_vaccinations end)) Jun
  ,(sum(case when EXTRACT(month from date) = 7 then new_vaccinations end)) Jul
  ,(sum(case when EXTRACT(month from date) = 8 then new_vaccinations end)) Aug
  ,(sum(case when EXTRACT(month from date) = 9 then new_vaccinations end)) Sep
  ,(sum(case when EXTRACT(month from date) = 10 then new_vaccinations end)) Oct
  ,(sum(case when EXTRACT(month from date) = 11 then new_vaccinations end)) Nov
  ,(sum(case when EXTRACT(month from date) = 12 then new_vaccinations end)) Dec
FROM `analyst-portfolio.COVID19.covid_vaccinations`
GROUP BY EXTRACT(year from date);

SELECT *
FROM monthly_vacc
ORDER BY year;
