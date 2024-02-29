Select * From DisneyPlusTitles

-- Remove duplicates
WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY show_id ORDER BY (SELECT NULL)) AS RowNum
    FROM DisneyPlusTitles
)
DELETE FROM CTE WHERE RowNum > 1;


-- Handle missing values

UPDATE DisneyPlusTitles
SET director = 'Unknown'
WHERE director = 'unknown'

UPDATE DisneyPlusTitles
SET cast = 'Unknown'
WHERE cast IS NULL;

UPDATE DisneyPlusTitles
SET country = 'Unknown'
WHERE country IS NULL;

UPDATE DisneyPlusTitles
SET director = 'Unknown'
WHERE director IS NULL;

-----------------------------------

USE DATA_ANALYSIS
IF OBJECT_ID('tempdb..#DirectorSplits') IS NOT NULL
    DROP TABLE #DirectorSplits;

CREATE TABLE #DirectorSplits (
    show_id VARCHAR(10),
    director1 VARCHAR(208),
    director2 VARCHAR(208)
);

INSERT INTO #DirectorSplits (show_id, director1, director2)
SELECT 
    show_id,
    CASE WHEN CHARINDEX(',', director) > 0 THEN SUBSTRING(director, 1, CHARINDEX(',', director) - 1) ELSE director END AS director1,
    CASE WHEN CHARINDEX(',', director) > 0 THEN SUBSTRING(director, CHARINDEX(',', director) + 1, LEN(director) - CHARINDEX(',', director)) ELSE NULL END AS director2
FROM DisneyPlusTitles;

Select * From #DirectorSplits

ALTER TABLE DisneyPlusTitles
DROP COLUMN director1, director2;

ALTER TABLE DisneyPlusTitles
Add director1 VARCHAR(100),
    director2 VARCHAR(100)

UPDATE dp
SET dp.director1 = ds.director1,
    dp.director2 = ds.director2
FROM DisneyPlusTitles dp
JOIN #DirectorSplits ds ON dp.show_id = ds.show_id;

Select * From DisneyPlusTitles

ALTER TABLE DisneyPlusTitles
DROP COLUMN director;

EXEC sp_rename 'DisneyPlusTitles.director1', 'director';
EXEC sp_rename 'DisneyPlusTitles.director2', 'director1';

UPDATE DisneyPlusTitles
SET director1 = 'NA'
WHERE director1 is null

UPDATE DisneyPlusTitles
SET director1 = 'Unknown'
WHERE director = 'Unknown'
----------------------------------------
-- Drop the temporary table if it exists
IF OBJECT_ID('tempdb..#CategorySplits') IS NOT NULL
    DROP TABLE #CategorySplits;

-- Create a temporary table for category splits
CREATE TABLE #CategorySplits (
    show_id VARCHAR(10),
    Listed_in_category1 VARCHAR(50),
    Listed_in_category2 VARCHAR(50),
    Listed_in_category3 VARCHAR(50)
);

Select * From #CategorySplits

INSERT INTO #CategorySplits (show_id, Listed_in_category1, Listed_in_category2, Listed_in_category3)
SELECT 
    show_id,
    PARSENAME(REPLACE(Listed_In, ', ', '.'), 3) AS Listed_in_category1,
    PARSENAME(REPLACE(Listed_In, ', ', '.'), 2) AS Listed_in_category2,
    PARSENAME(REPLACE(Listed_In, ', ', '.'), 1) AS Listed_in_category3
FROM DisneyPlusTitles;

UPDATE #CategorySplits
SET Listed_in_category1 = Listed_in_category2 
WHERE Listed_in_category1 IS NULL;

UPDATE #CategorySplits
SET Listed_in_category1 = Listed_in_category3 
WHERE Listed_in_category1 IS NULL and Listed_in_category2 IS NULL

UPDATE #CategorySplits
SET Listed_in_category2 = Listed_in_category3 
WHERE Listed_in_category2 IS NULL;

Update #CategorySplits
Set Listed_in_category2 = 'NA'
where Listed_in_category1 = Listed_in_category2

Update #CategorySplits
Set Listed_in_category2 = Listed_in_category3
where Listed_in_category2 = 'NA'

Update #CategorySplits
Set Listed_in_category3 = 'NA'
where Listed_in_category2 = Listed_in_category3

Select * From #CategorySplits
Where Listed_in_category1 = Listed_in_category2 or Listed_in_category2 = Listed_in_category3

Update #CategorySplits
Set Listed_in_category2 = 'NA'
where Listed_in_category1 = Listed_in_category2

Select * From #CategorySplits

ALTER TABLE DisneyPlusTitles
ADD Listed_in_category1 VARCHAR(50),
    Listed_in_category2 VARCHAR(50),
    Listed_in_category3 VARCHAR(50);

UPDATE dp
SET dp.Listed_in_category1 = cs.Listed_in_category1,
    dp.Listed_in_category2 = cs.Listed_in_category2,
    dp.Listed_in_category3 = cs.Listed_in_category3
FROM DisneyPlusTitles dp
JOIN #CategorySplits cs ON dp.show_id = cs.show_id;

Select * From DisneyPlusTitles

ALTER TABLE DisneyPlusTitles
DROP COLUMN listed_in;
------------------------------------------------------------------

-- Drop the existing #CastSplits table if it exists
IF OBJECT_ID('tempdb..#CastSplits') IS NOT NULL
    DROP TABLE #CastSplits;

-- Recreate the #CastSplits table with the appropriate column lengths
CREATE TABLE #CastSplits (
    show_id VARCHAR(10),
    cast1 VARCHAR(208),
    cast2 VARCHAR(208),
    cast3 VARCHAR(1000)--,
    --cast4 VARCHAR(1000)
);

-- Insert split cast members into the temporary table
INSERT INTO #CastSplits (show_id, cast1, cast2, cast3)
SELECT 
    show_id,
    CASE WHEN CHARINDEX(',', cast) > 0 THEN 
             LEFT(cast, CHARINDEX(',', cast) - 1) 
         ELSE cast 
    END AS cast1,
    CASE WHEN CHARINDEX(',', cast, CHARINDEX(',', cast) + 1) > 0 THEN 
             SUBSTRING(cast, CHARINDEX(',', cast) + 1, CHARINDEX(',', cast, CHARINDEX(',', cast) + 1) - CHARINDEX(',', cast) - 1) 
         ELSE NULL 
    END AS cast2,
    CASE WHEN CHARINDEX(',', cast, CHARINDEX(',', cast, CHARINDEX(',', cast) + 1) + 1) > 0 THEN 
             SUBSTRING(cast, CHARINDEX(',', cast, CHARINDEX(',', cast, CHARINDEX(',', cast) + 1) + 1) + 1, LEN(cast) - CHARINDEX(',', REVERSE(cast))) 
         ELSE NULL 
    END AS cast3
FROM DisneyPlusTitles;

-- View the data in the temporary table
SELECT * FROM #CastSplits
order by show_id asc

Select * From DisneyPlusTitles

ALTER TABLE DisneyPlusTitles
ADD cast1 VARCHAR(208),
    cast2 VARCHAR(208);

Update #CastSplits
set cast2 = 'Unknown'
where cast1 = 'Unknown'

Select * From #CastSplits
where cast2 = 'Unknown'

Update #CastSplits
set cast3 = 'Unknown'
where cast2 = 'Unknown' and cast1 = 'Unknown'

Select * From #CastSplits
Where cast2 is null and cast3 is not null

update #CastSplits
set cast2 = cast3
Where cast2 is null and cast3 is not null

Select * From #CastSplits
Where cast2 = cast3 and cast2 <> 'Unknown'

update #CastSplits
set cast3 = 'NA'
Where cast2 = cast3 and cast2 <> 'Unknown'

Select * From #CastSplits
where cast2 is null and cast3 is null

update #CastSplits
set cast2 = 'NA'
where cast2 is null and cast3 is null

update #CastSplits
set cast3 = 'NA'
where cast2 = 'NA' and cast3 is null

Select * From DisneyPlusTitles

UPDATE dp
SET dp.cast1 = cs.cast1,
    dp.cast2 = cs.cast2
FROM DisneyPlusTitles dp
JOIN #CastSplits cs ON dp.show_id = cs.show_id;

SELECT cast2, COUNT(*) AS rating_count
FROM DisneyPlusTitles
where cast2 in ('NA', 'Unknown') or cast2 is null
GROUP BY cast2;


ALTER TABLE #CastSplits
Drop Column cast1,
    cast2 

ALTER TABLE #CastSplits
ADD cast4 VARCHAR(1000); -- Adjust the length as needed

Select * From #CastSplits
order by show_id

UPDATE #CastSplits
SET 
    cast4 = CASE WHEN CHARINDEX(',', cast3) > 0 THEN 
                 SUBSTRING(cast3, CHARINDEX(',', cast3) + 1, LEN(cast3) - CHARINDEX(',', cast3))
               ELSE NULL 
           END,
    cast3 = CASE WHEN CHARINDEX(',', cast3) > 0 THEN 
                 LEFT(cast3, CHARINDEX(',', cast3) - 1)
               ELSE cast3 
           END;

ALTER TABLE DisneyPlusTitles
ADD cast3 VARCHAR(208)

Select * From DisneyPlusTitles

Alter table #Castsplits
drop column cast4

UPDATE dp
SET dp.cast3 = cs.cast3
FROM DisneyPlusTitles dp
JOIN #CastSplits cs ON dp.show_id = cs.show_id;

Select * From DisneyPlusTitles
where cast3 in ('NA', 'Unknown') or cast3 is null and cast2 not in ('NA' , 'Unknown')

select cast1, cast2, cast3
from DisneyPlusTitles 
where cast3 is null

Update DisneyPlusTitles
set cast3 = 'NA'
where cast3 is null

SELECT cast3, COUNT(*) AS rating_count
FROM DisneyPlusTitles
GROUP BY cast3;

Select * From DisneyPlusTitles
where director is null

UPDATE DisneyPlusTitles
SET date_added = 
    CASE 
        WHEN release_year = 2014 THEN '2014-01-01' -- Assuming January 1st of the year
        WHEN release_year = 2016 THEN '2016-01-01'
        WHEN release_year = 2008 THEN '2008-01-01'
        END
WHERE date_added IS NULL;

update DisneyPlusTitles
set rating = 'Unknown'
where rating is null

SELECT rating, COUNT(*) AS rating_count
FROM DisneyPlusTitles
GROUP BY rating;

Alter table DisneyPlusTitles
drop column cast

Select * From DisneyPlusTitles

Select country
from DisneyPlusTitles

SELECT country, COUNT(*) AS rating_count
FROM DisneyPlusTitles
GROUP BY country;

Select * From DisneyPlusTitles

ALTER TABLE DisneyPlusTitles
ADD country1 VARCHAR(208)

UPDATE dp
SET dp.country1 = cs.country1
FROM DisneyPlusTitles dp
JOIN #CountrySplits cs ON nt.show_id = cs.show_id;

-- Drop the existing #CountrySplits table if it exists
IF OBJECT_ID('tempdb..#CountrySplits') IS NOT NULL
    DROP TABLE #CountrySplits;

-- Recreate the #CountrySplits table with the appropriate column lengths
CREATE TABLE #CountrySplits (
    show_id VARCHAR(10),
    country1 VARCHAR(100),
    country2 VARCHAR(100),
    country3 VARCHAR(100),
    country4 VARCHAR(100) -- Add more columns as needed
);

-- Insert split country values into the temporary table
INSERT INTO #CountrySplits (show_id, country1, country2, country3, country4)
SELECT 
    show_id,
    CASE WHEN CHARINDEX(',', country) > 0 THEN 
             LEFT(country, CHARINDEX(',', country) - 1) 
         ELSE country 
    END AS country1,
    CASE WHEN CHARINDEX(',', country, CHARINDEX(',', country) + 1) > 0 THEN 
             SUBSTRING(country, CHARINDEX(',', country) + 1, CHARINDEX(',', country, CHARINDEX(',', country) + 1) - CHARINDEX(',', country) - 1) 
         ELSE NULL 
    END AS country2,
    CASE WHEN CHARINDEX(',', country, CHARINDEX(',', country, CHARINDEX(',', country) + 1) + 1) > 0 THEN 
             SUBSTRING(country, CHARINDEX(',', country, CHARINDEX(',', country, CHARINDEX(',', country) + 1) + 1) + 1, LEN(country) - CHARINDEX(',', REVERSE(country))) 
         ELSE NULL 
    END AS country3,
    NULL AS country4 -- Initialize country4 column to NULL
FROM DisneyPlusTitles;

Select * From #CountrySplits
where country2 is  null

Alter table #CountrySplits
drop column country4

Select * From #CountrySplits
where country1 is  null

update #CountrySplits
set country2 = 'NA'
where country2 is  null and country3 is null

update #CountrySplits
set country2 = country3
where country2 is  null

Alter table #CountrySplits
drop column country3

Select country1, COUNT(*) as country_count
from #CountrySplits
group by country1

Select * From #CountrySplits
where country1 = 'Unknown' or country1 = 'NA' or country1 is null

Alter table #CountrySplits
drop column country2

select * From DisneyPlusTitles

UPDATE dp
SET dp.country1 = cs.country1
FROM DisneyPlusTitles dp
JOIN #CountrySplits cs ON dp.show_id = cs.show_id;

Alter table DisneyPlusTitles
drop column country

EXEC sp_rename 'DisneyPlusTitles.country1', 'country';
------------------------------------------------------------
Select * From DisneyPlusTitles
where type = 'Movie'

ALTER TABLE DisneyPlusTitles
ADD [duration_in_min] VARCHAR(10) NULL;

ALTER TABLE DisneyPlusTitles
ADD [Total_Seasons] VARCHAR(10) NULL;

Select * From DisneyPlusTitles

update DisneyPlusTitles
set Total_Seasons = duration
where  type <> 'Movie'

update DisneyPlusTitles
set duration_in_min = duration
where  type = 'Movie'

update DisneyPlusTitles
set Total_Seasons = 'NA'
where Total_Seasons is null

Select * From DisneyPlusTitles
where duration_in_min is null

Alter table DisneyPlusTitles
drop column duration
--------------------------------------------------
Select LEN(duration_in_min), duration_in_min
from DisneyPlusTitles
where duration_in_min <> 'NA'

SELECT LEN(REPLACE(duration_in_min, ' min', '')) AS duration_length, REPLACE(duration_in_min, ' min', '') AS duration
FROM DisneyPlusTitles
WHERE duration_in_min <> 'NA';

UPDATE DisneyPlusTitles
SET duration_in_min = REPLACE(duration_in_min, ' min', '')
WHERE duration_in_min <> 'NA';

Select * From DisneyPlusTitles
----------------------------------------------------
---------------------------------------------------------------
CREATE TABLE [dbo].[DisneyPlusTitles_Movies](
	[show_id] [varchar](10) NOT NULL,
	[type] [varchar](10) NOT NULL,
	[title] [varchar](104) NOT NULL,
	[date_added] [date] NULL,
	[release_year] [int] NOT NULL,
	[rating] [varchar](8) NULL,
	[director] [varchar](100) NULL,
	[director1] [varchar](100) NULL,
	[Listed_in_category1] [varchar](50) NULL,
	[Listed_in_category2] [varchar](50) NULL,
	[Listed_in_category3] [varchar](50) NULL,
	[cast1] [varchar](208) NULL,
	[cast2] [varchar](208) NULL,
	[cast3] [varchar](208) NULL,
	[country] [varchar](208) NULL,
	[duration_in_min] [int] NULL,
	)

Select * From DisneyPlusTitles
where duration_in_min <> 'NA'

Select * From DisneyPlusTitles_Movies

INSERT INTO DisneyPlusTitles_Movies (show_id, type, title, date_added, release_year, rating, director, director1, Listed_in_category1, Listed_in_category2, Listed_in_category3, cast1, cast2, cast3, country, duration_in_min)
SELECT 
    show_id,
    type,
    title,
    date_added,
    release_year,
    rating,
    director,
    director1,
    Listed_in_category1,
    Listed_in_category2,
    Listed_in_category3,
    cast1,
    cast2,
    cast3,
    country,
    CAST(duration_in_min AS int) -- Convert duration_in_min to int
FROM DisneyPlusTitles
WHERE duration_in_min <> 'NA' 

----------------------------------------------------
CREATE TABLE [dbo].[DisneyPlusTitles_TV_Shows](
	[show_id] [varchar](10) NOT NULL,
	[type] [varchar](10) NOT NULL,
	[title] [varchar](104) NOT NULL,
	[date_added] [date] NULL,
	[release_year] [int] NOT NULL,
	[rating] [varchar](8) NULL,
	[director] [varchar](100) NULL,
	[director1] [varchar](100) NULL,
	[Listed_in_category1] [varchar](50) NULL,
	[Listed_in_category2] [varchar](50) NULL,
	[Listed_in_category3] [varchar](50) NULL,
	[cast1] [varchar](208) NULL,
	[cast2] [varchar](208) NULL,
	[cast3] [varchar](208) NULL,
	[country] [varchar](208) NULL,
	[Total_Seasons] [int] NULL,
	)

Select * From DisneyPlusTitles
where Total_Seasons <> 'NA'

Select LEN(Total_Seasons), Total_Seasons
From DisneyPlusTitles
where Total_Seasons <> 'NA'

SELECT LEFT(Total_Seasons, 1) AS first_letter, Total_Seasons
FROM DisneyPlusTitles
WHERE Total_Seasons <> 'NA';

UPDATE DisneyPlusTitles
SET Total_Seasons = LEFT(Total_Seasons, 1)
WHERE Total_Seasons <> 'NA';

Select * From DisneyPlusTitles

INSERT INTO DisneyPlusTitles_TV_Shows (show_id, type, title, date_added, release_year, rating, director, director1, Listed_in_category1, Listed_in_category2, Listed_in_category3, cast1, cast2, cast3, country, Total_Seasons)
SELECT 
    show_id,
    type,
    title,
    date_added,
    release_year,
    rating,
    director,
    director1,
    Listed_in_category1,
    Listed_in_category2,
    Listed_in_category3,
    cast1,
    cast2,
    cast3,
    country,
    CAST(Total_Seasons AS int) -- Convert Total_Seasons to int
FROM DisneyPlusTitles
WHERE Total_Seasons <> 'NA' 

Select * From DisneyPlusTitles_TV_Shows
where type = 'Movie'

Select * From DisneyPlusTitles_TV_Shows
where director1 <> 'Unknown' 
Select * From DisneyPlusTitles_Movies
----------------------------------------------------------------------
/* Data Analysis */

-- 1. Trends over time
SELECT 
    release_year,
    COUNT(*) AS num_shows
FROM 
    DisneyPlusTitles_TV_Shows
GROUP BY 
    release_year
ORDER BY 
    release_year desc;

--2. Popular Genre
SELECT 
    Listed_in_category1 AS genre,
    COUNT(*) AS num_shows
FROM 
    DisneyPlusTitles_TV_Shows
GROUP BY 
    Listed_in_category1
ORDER BY 
    num_shows DESC;

--3. Regional Preference
SELECT 
    country,
    COUNT(*) AS num_shows
FROM 
    DisneyPlusTitles_TV_Shows
GROUP BY 
    country
ORDER BY 
    num_shows DESC;

--4. Season Analysis

SELECT 
    Total_Seasons,
    COUNT(*) AS num_shows
FROM 
    DisneyPlusTitles_TV_Shows
GROUP BY 
    Total_Seasons
ORDER BY 
    Total_Seasons;

--5. Date Added Trends
SELECT 
    YEAR(date_added) AS year_added,
    MONTH(date_added) AS month_added,
    COUNT(*) AS num_shows
FROM 
    DisneyPlusTitles_TV_Shows
GROUP BY 
    YEAR(date_added), MONTH(date_added)
ORDER BY 
    year_added, month_added;

--6. Rating Distributions

SELECT 
    rating,
    COUNT(*) AS num_shows
FROM 
    DisneyPlusTitles_TV_Shows
GROUP BY 
    rating
ORDER BY 
    num_shows DESC;

--7. Cast Analysis
SELECT 
    cast_member,
    COUNT(*) AS num_shows
FROM (
    SELECT CAST(cast1 AS VARCHAR(MAX)) AS cast_member FROM DisneyPlusTitles_TV_Shows WHERE cast1 IS NOT NULL
    UNION ALL
    SELECT CAST(cast2 AS VARCHAR(MAX)) AS cast_member FROM DisneyPlusTitles_TV_Shows WHERE cast2 IS NOT NULL
    UNION ALL
    SELECT CAST(cast3 AS VARCHAR(MAX)) AS cast_member FROM DisneyPlusTitles_TV_Shows WHERE cast3 IS NOT NULL
) AS combined_cast
WHERE
    cast_member NOT IN ('NA','Unknown')
GROUP BY 
    cast_member
ORDER BY 
    num_shows DESC;

-----------------------------------------------------------------------
--1. Trends Over Time

SELECT 
    release_year,
    COUNT(*) AS num_movies
FROM 
    DisneyPlusTitles_Movies
GROUP BY 
    release_year
ORDER BY 
    release_year DESC;

--2. Popular Genre

SELECT 
    Listed_in_category1 AS genre,
    COUNT(*) AS num_movies
FROM 
    DisneyPlusTitles_Movies
GROUP BY 
    Listed_in_category1
ORDER BY 
    num_movies DESC;

--3. Top Directors and Movies

SELECT 
    director,
    COUNT(*) AS num_movies
FROM (
    SELECT director FROM DisneyPlusTitles_Movies WHERE director IS NOT NULL AND director <> 'Unknown'
    UNION ALL
    SELECT director1 FROM DisneyPlusTitles_Movies WHERE director1 IS NOT NULL AND director1 <> 'Unknown'
) AS combined_directors
WHERE
	director <> 'NA'
GROUP BY 
    director
ORDER BY 
    num_movies DESC;

--4. Regional Preferences

SELECT 
    country,
    COUNT(*) AS num_movies
FROM 
    DisneyPlusTitles_Movies
GROUP BY 
    country
ORDER BY 
    num_movies DESC;

--5. Duration Analysis

SELECT 
    duration_in_min,
    COUNT(*) AS num_movies
FROM 
    DisneyPlusTitles_Movies
GROUP BY 
    duration_in_min
ORDER BY 
    num_movies desc;
	
--6. Date Trends

SELECT 
    YEAR(date_added) AS year_added,
    MONTH(date_added) AS month_added,
    COUNT(*) AS num_movies
FROM 
    DisneyPlusTitles_Movies
GROUP BY 
    YEAR(date_added), MONTH(date_added)
ORDER BY 
    year_added, month_added;
s