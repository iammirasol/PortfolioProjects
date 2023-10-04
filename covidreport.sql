

select * from miraport..CovidDeaths;

select * from miraport..CovidVaccinations;


select * from miraport..CovidDeaths
order by 3,4;

select * from miraport..CovidVaccinations
order by 3,4;


-- Show data to use
select location, date, total_cases, new_cases, total_deaths, population
from miraport..CovidDeaths
where continent is not null
order by 1,2;


-- Total Cases vs Total Deaths
select location, date, round(total_cases,0) as total_cases, round(new_cases,0) as new_cases, round(total_deaths,0) as total_deaths, round((cast(total_deaths as float) / cast(total_cases as float))*100,2) as DeathPercentage
from miraport..CovidDeaths
where continent is not null
order by 1,2;


-- Total Cases vs Total Deaths
-- Show likelihood of dying if a person contracted covid
select location, date, round(total_cases,0) as total_cases, round(new_cases,0) as new_cases, round(total_deaths,0) as total_deaths, round((cast(total_deaths as float) / cast(total_cases as float))*100,2) as DeathPercentage
from miraport..CovidDeaths
where continent is not null
and location like '%Philip%' -- comment out to check all locations
order by 1,2;


-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
select location, date, round(population,0) as total_population, round(total_cases,0) as total_cases, round(new_cases,0) as new_cases, round((cast(total_cases as float) / cast(population as float))*100,2) as PercentPopulationInfected
from miraport..CovidDeaths
where continent is not null
and location like '%Philip%' -- comment out to check all locations
order by 1,2;


-- Looking at countries with highest infection rate compared to population
select location, round(population,0) as total_population, max(round(total_cases,0)) as HighestInfectionCount,  max(round((cast(total_cases as float) / cast(population as float))*100,2)) as PercentPopulationInfected
from miraport..CovidDeaths
where continent is not null
--and location like '%Philip%' -- uncomment to check a specific location
group by location, round(population,0)
order by PercentPopulationInfected desc;


-- Showing highest death count per location
select location, max(round(cast(total_deaths as float),2)) as HighestDeathCount
from miraport..CovidDeaths
where continent is not null
--and location like '%Philip%' -- uncomment to check a specific location
group by location
order by HighestDeathCount desc;


-- Showing highest death count per continent 
select location, max(round(cast(total_deaths as float),2)) as HighestDeathCount
from miraport..CovidDeaths
where continent is null
and location not in ('World','High income','Upper middle income','Lower middle income','Low income', 'European Union')
group by location
order by HighestDeathCount desc;


-- by writing sql query this is ideally correct but counts are not realistic if we compare to what is reported worldwide
select continent, max(round(cast(total_deaths as float),2)) as HighestDeathCount
from miraport..CovidDeaths
where continent is not null
group by continent
order by HighestDeathCount desc;


-- Global Numbers
select date, sum(round(new_deaths,0)) as new_deaths, sum(round(new_cases,0)) as new_cases, round((sum(cast(new_deaths as float)) / sum(cast(new_cases as float)))*100,2) as DeathPercentage
from miraport..CovidDeaths
where continent is not null
and new_cases <> 0 -- added to avoid dividing by 0 which results to Math error
group by date
order by 1,2;


-- Total Population vs Vaccinations
select distinct dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
, 
from miraport..CovidDeaths dea, miraport..CovidVaccinations vac
where dea.location = vac.location
and dea.continent is not null
and dea.date =  vac.date
order by 2,3;
-- encountered error: ORDER BY list of RANGE window frame has total size of 1020 bytes. Largest size supported is 900 bytes.

-- initially location and date are both nvarchar(255) and as per my research 255 actually uses 510 bytes which totals to 1020 as mentioned in the error message.
-- so converted the date column to date data type to lessen the bytes used and be able to use the above query "order by dea.location, dea.date" 
ALTER TABLE miraport..CovidDeaths
ALTER COLUMN date date;

-- use of cte to get percentage of RollingPeopleVaccinated
With popvsvac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as (
select distinct dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from miraport..CovidDeaths dea, miraport..CovidVaccinations vac
where dea.location = vac.location
and dea.continent is not null
and dea.date =  vac.date
)
select continent, location, date, population, new_vaccinations, RollingPeopleVaccinated, round((RollingPeopleVaccinated/population) * 100, 2) as PercRollingPeopleVaccinated
from popvsvac
where new_vaccinations is not null
order by 2, 3;


-- People Vaccinated by Location
select dea.Continent, dea.Location, dea.Population, max(vac.people_vaccinated) as "Total of People Vaccinated", round((max(vac.people_vaccinated)/dea.population) * 100,2) as "Percentage of Population Vaccinated"
from miraport..CovidDeaths dea, miraport..CovidVaccinations vac
where dea.location = vac.location
and dea.continent is not null
and vac.people_vaccinated is not null
group by dea.continent, dea.location, dea.population;


-- max(people_vaccinated) -- 82,684,774 Philippines
-- needed to alter the column data type to a numeric data type to get accurate result for the max aggregate function
ALTER TABLE miraport..CovidVaccinations
ALTER COLUMN people_vaccinated BIGINT;


-- use of Temp table to get percentage of RollingPeopleVaccinated

drop table if exists #PercentPopulationVaccinated -- if there are changes with how we want our temp table to look like, we need to drop it first
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);


insert into #PercentPopulationVaccinated
select distinct dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from miraport..CovidDeaths dea, miraport..CovidVaccinations vac
where dea.location = vac.location
and dea.continent is not null
and dea.date =  vac.date;

--(325099 rows affected)

select continent, location, date, population, new_vaccinations, RollingPeopleVaccinated, round((RollingPeopleVaccinated/population) * 100, 2) as PercRollingPeopleVaccinated
from #PercentPopulationVaccinated
where new_vaccinations is not null
order by 2, 3;


-- creating view to store data for visualization
create view PercentPopulationVaccinated as
select distinct dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from miraport..CovidDeaths dea, miraport..CovidVaccinations vac
where dea.location = vac.location
and dea.continent is not null
and dea.date =  vac.date;

commit;

select continent, location, date, population, new_vaccinations, RollingPeopleVaccinated, round((RollingPeopleVaccinated/population) * 100, 2) as PercRollingPeopleVaccinated
from PercentPopulationVaccinated
where new_vaccinations is not null
order by 2, 3;


