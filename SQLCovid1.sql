--Checking to see tables were loaded properly from Excel
SELECT * FROM SQLCovidPortfolioProject..CovidDeaths
ORDER BY 3,4  --ORDER BY COL 3,4 (Location, Date)

--SELECT * FROM SQLCovidPortfolioProject..CovidVaccinations
--ORDER BY 3,4

--NOTE: When location is a continent, the continent column will have a NULL value for some reason

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM SQLCovidPortfolioProject..CovidDeaths
ORDER BY 1,2 --order by location, date

--Examine total cases vs total deaths(likelihood of dying if you contract covid) in the location that has "states" in name(USA)
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM SQLCovidPortfolioProject..CovidDeaths
WHERE Location like '%states%'
ORDER BY 1,2 --order by location, date

--Looking at total cases vs population
--Show percentage of population in USA that got Covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS PopulationInfectionPercentage
FROM SQLCovidPortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

--Looking at countries that with the highest infection rate with respect to population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)*100) AS InfectionPercentage
FROM SQLCovidPortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY InfectionPercentage DESC

--Countries with the highest death count

--total_deaths has a data type as char so it has to be cast as an int to fix any issues
SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount 
FROM SQLCovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--Death count by continent
--in the file, they also listed the continent as location and made the corresponding continent col value NULL
-- so we get the locations(the continents) where the contintent value is NULL
SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount 
FROM SQLCovidPortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--use continent col
SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM SQLCovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--max percent of population in continent infected
SELECT location, MAX((total_cases/population)*100) AS PopulationInfectionPercentage
FROM SQLCovidPortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY PopulationInfectionPercentage DESC

--showing continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths AS int)) AS TotalDeathCount 
FROM SQLCovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Global Numbers

-- global cases and deaths by date
SELECT date, SUM(new_cases) as total_cases,SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage  
FROM SQLCovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

--total cases and deaths during entire time period
SELECT SUM(new_cases) as total_cases,SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage  
FROM SQLCovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--ORDER BY 1,2

-- TotalPeopleVaccinated in country at the end of time frame(adds new col with a final count per location)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY 
dea.location) AS TotalPeopleVaccinated
FROM SQLCovidPortfolioProject..CovidDeaths dea
JOIN SQLCovidPortfolioProject..CovidVaccinations vac
	ON dea.location=vac.location and dea.date=vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--RollingCountOverall(rolling count of number of people vaccinated based each day, per location)[not ideal query result](TEST)
--SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY 
--dea.date ORDER BY dea.date,dea.location) AS rollingPeopleVaccinated
--FROM SQLCovidPortfolioProject..CovidDeaths dea
--JOIN SQLCovidPortfolioProject..CovidVaccinations vac
--	ON dea.location=vac.location and dea.date=vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 3,2

--Rolling count per date by location (TEST)
--SELECT vac.date,vac.location,vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) 
--OVER (PARTITION BY vac.date ORDER BY vac.location) AS RollingCount
--FROM SQLCovidPortfolioProject..CovidVaccinations vac
--WHERE vac.continent IS NOT NULL
--ORDER BY 1,2

--Per date roll count(TEST)
--If following code used: 'SUM(SUM(cast(vac.new_vaccinations AS int))) OVER (PARTITION BY vac.date)' it would be same as total_vacc

--SELECT vac.date, SUM(cast(vac.new_vaccinations AS int)) AS total_vacc,
--SUM(SUM(cast(vac.new_vaccinations AS int))) OVER (ORDER BY vac.date) AS RollingCount 
--FROM SQLCovidPortfolioProject..CovidVaccinations vac
--WHERE vac.continent IS NOT NULL
--GROUP BY vac.date
--ORDER BY vac.date


--Looking at total population vs vaccination(Rolling count for each country)
--(technically only need order by dea.date in partition to do rolling cnt)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY 
dea.location ORDER BY dea.location, dea.date) AS rollingPeopleVaccinated
FROM SQLCovidPortfolioProject..CovidDeaths dea
JOIN SQLCovidPortfolioProject..CovidVaccinations vac
	ON dea.location=vac.location and dea.date=vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3



--Using CTE
WITH PopsVac (Continent, Location, Date, Population, NewVaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY 
dea.location ORDER BY dea.location, dea.date) AS rollingPeopleVaccinated
FROM SQLCovidPortfolioProject..CovidDeaths dea
JOIN SQLCovidPortfolioProject..CovidVaccinations vac
	ON dea.location=vac.location and dea.date=vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentPopVaccinated
FROM PopsVac 


--Temp Table
DROP TABLE IF EXISTS #PercentPopVaccinated  --Safety Measure in case script is run again and the table already exists
CREATE TABLE #PercentPopVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric
)


INSERT INTO #PercentPopVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY 
dea.location ORDER BY dea.location, dea.date) AS rollingPeopleVaccinated
FROM SQLCovidPortfolioProject..CovidDeaths dea
JOIN SQLCovidPortfolioProject..CovidVaccinations vac
	ON dea.location=vac.location and dea.date=vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentPopVaccinated
FROM #PercentPopVaccinated 


--Create View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingPeopleVaccinated
FROM SQLCovidPortfolioProject..CovidDeaths dea
JOIN SQLCovidPortfolioProject..CovidVaccinations vac
	ON dea.location=vac.location and dea.date=vac.date
WHERE dea.continent IS NOT NULL

SELECT * 
FROM PercentPopulationVaccinated