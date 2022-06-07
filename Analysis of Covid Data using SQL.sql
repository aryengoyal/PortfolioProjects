use FirstProject_sql

select * 
from CovidDeaths
order by 5

SELECT * 
From CovidVaccinations
order by 3,4

Select location,date,total_cases,new_cases,total_deaths,population
From CovidDeaths
order by 1,2

-- Looking at Total _Cases Vs Total_Deaths
-- Shows likelihood of dying from covid in your country

Select location,date,total_cases,total_deaths,population,(total_deaths/total_cases)*100 as Death_Percentage
From CovidDeaths
where location = 'India'
order by 1,2

-- Total_Cases Vs Population

Select location,date,total_cases,total_deaths,population,(total_cases/population)*100 as Positivity_ratio
From CovidDeaths
where location = 'India'
order by 1,2

-- Highest Positive_Ratio Per Country

Select location,Max(total_cases) as Max_Case,population,Max((total_cases/population))*100 as Max_Positivity_ratio
From CovidDeaths
where continent is not null
group by location,population
order by Max_Positivity_ratio desc

--Showing Countries with highest Death Count in a day per Polulation

Select location,Max(cast(total_deaths as int)) as Highest_Deaths
From CovidDeaths
where continent is not null
group by location
order by Highest_Deaths desc

-- Max Death By Continent

Select continent,Max(cast(total_deaths as int)) as Highest_Deaths
From CovidDeaths
where continent is not null
group by continent
order by Highest_Deaths desc


-- GLOBAL NUMBERS

Select date,SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
--Where location = 'India'
where continent is not null 
Group By date
order by 1

-- Join CovidDeaths and CovidVaccinstions Tables

Select *
From CovidDeaths dea
Join CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
order by 3

-- Total Population Vs Vaccination

Select sum(distinct(population)) as Total_Population,sum(cast(new_vaccinations as bigint))/sum(distinct(population))*100 as Vaccination_Percent
From CovidDeaths dea
Join CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null

SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
Sum(cast(vac.new_vaccinations as int)) over (Partition by dea.location order by dea.location,dea.date) as rollingcount_vac
From CovidDeaths dea
Join CovidVaccinations vac
ON dea.location=vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

--USE CTE

with popvsvac (continent,location,date,population,new_vaccinations,rollingcount_vac)
as
(
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
Sum(cast(vac.new_vaccinations as int)) over (Partition by dea.location order by dea.location,dea.date) as rollingcount_vac
From CovidDeaths dea
Join CovidVaccinations vac
ON dea.location=vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)

SELECT * , (rollingcount_vac/population)*100
FROM popvsvac

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated
order by 2,3


-- Creating View for storing data for later visualizations

CREATE view PercentPopulationVaccinated
as
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
Sum(cast(vac.new_vaccinations as int)) over (Partition by dea.location order by dea.location,dea.date) as rollingcount_vac
From CovidDeaths dea
Join CovidVaccinations vac
ON dea.location=vac.location
and dea.date = vac.date
where dea.continent is not null
