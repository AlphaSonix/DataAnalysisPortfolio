SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Looking at total cases compared to total deaths in UK
-- Shows likelihood of dying over time by covid in the UK
-- 16 April to 13 July - Date range covid deaths percentage peaked 
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM PortfolioProject..CovidDeaths
WHERE location like 'United Kingdom'
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of the UK public got covid 
-- About 6.5% of the UK population were confirmed to have contracted covid by 30/4/21
SELECT location, date, total_cases, population, (total_cases/population)*100 AS infected_percentage
FROM PortfolioProject..CovidDeaths
WHERE location like 'United Kingdom'
ORDER BY 2

-- looking at which countries have the highest infection rate compared to population

SELECT location, MAX(total_cases) as TotalInfectionCount, population, MAX((total_cases/population))*100 AS total_infected_percentage
FROM PortfolioProject..CovidDeaths
--WHERE location like 'United Kingdom'
GROUP BY location, population
ORDER BY 4 DESC

-- countries that have the highest death count per population

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like 'United Kingdom'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

-- INCORRECT WAY - Shows continents and total deaths 

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

SELECT location, total_cases, population, (total_cases/population)*100 AS infected_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY location, total_cases, population
ORDER BY infected_percentage



-- CORRECT WAY - shows continents and total deaths

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- average infection percentage per continent 
-- shows Europe did slightly better at controlling the spread of infection than North America despite a higher population.
SELECT location, population, AVG((total_cases/population))*100 AS infected_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY location, population
ORDER BY population DESC


-- GLOBAL NUMBERS

-- Total cases and deaths worldwide
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentage
FROM PortfolioProject..CovidDeaths
--WHERE location like 'United Kingdom'
WHERE continent is not null
ORDER BY 1,2

-- showing the death percentage on each date for the world as a whole 
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentage
FROM PortfolioProject..CovidDeaths
--WHERE location like 'United Kingdom'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


--Looking at total population compared with vaccinations over time
--Creating CTE to show the percentage of people in a country vaccinated
WITH PopvsVac (continent, location, date, population, new_vaccinations, VaccinatedOverTime)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
as VaccinatedOverTime
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null and dea.location like 'Albania'
--ORDER BY 2,3
)
SELECT *, (VaccinatedOverTime/population)*100
FROM PopvsVac

--Same thing as above but with a temp table

DROP Table if exists #PercentPeopleVaccinated
Create Table #PercentPeopleVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population int,
New_vaccinations int,
VaccinatedOverTime numeric
)

INSERT INTO #PercentPeopleVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
as VaccinatedOverTime
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null and dea.location like 'United Kingdom'
--ORDER BY 2,3

SELECT *, (VaccinatedOverTime/population)*100 as PopulationVaccinated
FROM #PercentPeopleVaccinated

--Looking the delay of deaths reducing following the introduction of the vaccine

DROP Table if exists #NewDeathsAfterVaccination
Create Table #NewDeathsAfterVaccination
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
new_deaths numeric,
VaccinatedOverTime numeric
)

INSERT INTO #NewDeathsAfterVaccination
SELECT dea.continent, dea.location, dea.date, dea.new_deaths,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
as VaccinatedOverTime
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 
--ORDER BY 2,3

SELECT *
FROM #NewDeathsAfterVaccination

-- Creating view to store data for visualisations

CREATE VIEW PercentPeopleVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
as VaccinatedOverTime
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT * 
FROM PercentPeopleVaccinated

--

CREATE VIEW DeathsComparedToVaccinations as
SELECT dea.continent, dea.location, dea.date, dea.new_deaths,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
as VaccinatedOverTime
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 

SELECT *
FROM DeathsComparedToVaccinations
