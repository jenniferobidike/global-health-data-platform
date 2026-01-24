CREATE DATABASE global_health;
GO
USE global_health;
GO
CREATE TABLE stg_life_expectancy (
    country VARCHAR(100),
    year INT,
    life_expectancy FLOAT
);
CREATE TABLE stg_maternal_mortality (
    country VARCHAR(100),
    year INT,
    maternal_mortality_ratio FLOAT
);

CREATE TABLE stg_uhc_index (
    country VARCHAR(100),
    year INT,
    uhc_index FLOAT
);

CREATE TABLE stg_doctors (
    country VARCHAR(100),
    year INT,
    doctors_per_10000 FLOAT
);

CREATE TABLE stg_water (
    country VARCHAR(100),
    year INT,
    basic_water_access_pct FLOAT
);

CREATE TABLE stg_ncd_30_70 (
    country VARCHAR(100),
    year INT,
    ncd_mortality_30_70 FLOAT
);
CREATE TABLE stg_pharmacists (
    country VARCHAR(100),
    year INT,
    pharmacists_per_10000 FLOAT
);
SELECT COUNT(*) FROM stg_life_expectancy AS LIFE;
SELECT COUNT(*) FROM stg_maternal_mortality;
SELECT COUNT(*) FROM stg_uhc_index;
SELECT COUNT(*) FROM stg_doctors;
SELECT COUNT(*) FROM stg_water;
SELECT COUNT(*) FROM stg_ncd_30_70;
SELECT COUNT(*) FROM stg_pharmacists;
SELECT TOP 10 * FROM stg_life_expectancy;

CREATE TABLE fact_global_health (
    country VARCHAR(100),
    year INT,
    life_expectancy FLOAT,
    maternal_mortality_ratio FLOAT,
    uhc_index FLOAT,
    doctors_per_10000 FLOAT,
    basic_water_access_pct FLOAT,
    ncd_mortality_30_70 FLOAT,
    pharmacists_per_1000 FLOAT
);
DROP TABLE fact_global_health;
CREATE TABLE fact_global_health (
    country VARCHAR(100),
    year INT,
    life_expectancy FLOAT,
    maternal_mortality_ratio FLOAT,
    uhc_index FLOAT,
    doctors_per_10000 FLOAT,
    basic_water_access_pct FLOAT,
    ncd_mortality_30_70 FLOAT,
    pharmacists_per_1000 FLOAT
);


SELECT 'stg_life_expectancy' AS table_name, COUNT(*) AS row_count FROM stg_life_expectancy
UNION ALL
SELECT 'stg_maternal_mortality', COUNT(*) FROM stg_maternal_mortality
UNION ALL
SELECT 'stg_uhc_index', COUNT(*) FROM stg_uhc_index
UNION ALL
SELECT 'stg_doctors', COUNT(*) FROM stg_doctors
UNION ALL
SELECT 'stg_pharmacists', COUNT(*) FROM stg_pharmacists
UNION ALL
SELECT 'stg_water', COUNT(*) FROM stg_water
UNION ALL
SELECT 'stg_ncd_30_70', COUNT(*) FROM stg_ncd_30_70;

SELECT COUNT(*) FROM fact_global_health;

INSERT INTO fact_global_health
SELECT
    le.country,
    le.year,
    le.life_expectancy,
    mm.maternal_mortality_ratio,
    uhc.uhc_index,
    doc.doctors_per_10000,
    ph.pharmacists_per_10000,
    wat.basic_water_access_pct,
    ncd.ncd_mortality_30_70
FROM stg_life_expectancy le
LEFT JOIN stg_maternal_mortality mm
    ON le.country = mm.country AND le.year = mm.year
LEFT JOIN stg_uhc_index uhc
    ON le.country = uhc.country AND le.year = uhc.year
LEFT JOIN stg_doctors doc
    ON le.country = doc.country AND le.year = doc.year
LEFT JOIN stg_pharmacists ph
    ON le.country = ph.country AND le.year = ph.year
LEFT JOIN stg_water wat
    ON le.country = wat.country AND le.year = wat.year
LEFT JOIN stg_ncd_30_70 ncd
    ON le.country = ncd.country AND le.year = ncd.year;

    SELECT COUNT(*) FROM fact_global_health;
    SELECT TOP 10 *
FROM fact_global_health
ORDER BY year DESC;

SELECT COUNT(*) AS rows_from_insert_select
FROM (
  SELECT le.country, le.year
  FROM stg_life_expectancy le
) x;

SELECT COUNT(*) AS fact_rows FROM fact_global_health;
.......  EDA STARTS

-- Total rows

SELECT COUNT(*) AS total_rows
FROM fact_global_health;

-- Country & year coverage

SELECT
    COUNT(DISTINCT country) AS total_countries,
    MIN(year) AS min_year,
    MAX(year) AS max_year
FROM fact_global_health;

-- Data completeness

SELECT
    COUNT(*) AS total_rows,
    COUNT(life_expectancy) AS life_expectancy_rows,
    COUNT(maternal_mortality_ratio) AS maternal_mortality_rows,
    COUNT(uhc_index) AS uhc_rows,
    COUNT(doctors_per_10000) AS doctors_rows,
    COUNT(pharmacists_per_1000) AS pharmacists_rows,
    COUNT(basic_water_access_pct) AS water_rows,
    COUNT(ncd_mortality_30_70) AS ncd_rows
FROM fact_global_health;

-- Global averages

DECLARE @latest_year INT;

SELECT @latest_year = MAX(year)
FROM fact_global_health;

SELECT
    @latest_year AS latest_year,
    AVG(life_expectancy) AS avg_life_expectancy,
    AVG(maternal_mortality_ratio) AS avg_maternal_mortality_ratio,
    AVG(uhc_index) AS avg_uhc_index,
    AVG(doctors_per_10000) AS avg_doctors_per_10000,
    AVG(pharmacists_per_1000) AS avg_pharmacists_per_1000,
    AVG(basic_water_access_pct) AS avg_basic_water_access_pct,
    AVG(ncd_mortality_30_70) AS avg_ncd_mortality_30_70
FROM fact_global_health
WHERE year = @latest_year;

-- Top 10 life expectancy

DECLARE @latest_year INT;

SELECT @latest_year = MAX(year)
FROM fact_global_health;

SELECT TOP 10
    country,
    life_expectancy
FROM fact_global_health
WHERE year = @latest_year
  AND life_expectancy IS NOT NULL
ORDER BY life_expectancy DESC;

-- Bottom 10 life expectancy
DECLARE @latest_year INT;

SELECT @latest_year = MAX(year)
FROM fact_global_health;

SELECT TOP 10
    country,
    life_expectancy
FROM fact_global_health
WHERE year = @latest_year
  AND life_expectancy IS NOT NULL
ORDER BY life_expectancy ASC;

-- Highest maternal mortality
DECLARE @latest_year INT;

SELECT @latest_year = MAX(year)
FROM fact_global_health;

SELECT TOP 10
    country,
    maternal_mortality_ratio
FROM fact_global_health
WHERE year = @latest_year
  AND maternal_mortality_ratio IS NOT NULL
ORDER BY maternal_mortality_ratio DESC;

-- Life expectancy trend

SELECT
    year,
    AVG(life_expectancy) AS avg_life_expectancy
FROM fact_global_health
WHERE life_expectancy IS NOT NULL
GROUP BY year
ORDER BY year;

-- Maternal mortality trend
SELECT
    year,
    AVG(maternal_mortality_ratio) AS avg_maternal_mortality_ratio
FROM fact_global_health
WHERE maternal_mortality_ratio IS NOT NULL
GROUP BY year
ORDER BY year;

-- Health system capacity trend
SELECT
    year,
    AVG(doctors_per_10000) AS avg_doctors_per_10000,
    AVG(pharmacists_per_1000) AS avg_pharmacists_per_1000
FROM fact_global_health
GROUP BY year
ORDER BY year;

-- Doctors vs life expectancy

DECLARE @latest_year INT;

SELECT @latest_year = MAX(year)
FROM fact_global_health;

SELECT
    country,
    doctors_per_10000,
    life_expectancy
FROM fact_global_health
WHERE year = @latest_year
  AND doctors_per_10000 IS NOT NULL
  AND life_expectancy IS NOT NULL;

  -- UHC vs maternal mortality

DECLARE @latest_year INT;

SELECT @latest_year = MAX(year)
FROM fact_global_health;

SELECT
    country,
    uhc_index,
    maternal_mortality_ratio
FROM fact_global_health
WHERE year = @latest_year
  AND uhc_index IS NOT NULL
  AND maternal_mortality_ratio IS NOT NULL;

  -- Improvement over time

  WITH bounds AS (
    SELECT
        country,
        MIN(year) AS start_year,
        MAX(year) AS end_year
    FROM fact_global_health
    WHERE life_expectancy IS NOT NULL
    GROUP BY country
),
values_cte AS (
    SELECT
        b.country,
        b.start_year,
        b.end_year,
        f1.life_expectancy AS start_life_expectancy,
        f2.life_expectancy AS end_life_expectancy
    FROM bounds b
    JOIN fact_global_health f1
        ON b.country = f1.country AND b.start_year = f1.year
    JOIN fact_global_health f2
        ON b.country = f2.country AND b.end_year = f2.year
)
SELECT TOP 20
    country,
    start_year,
    end_year,
    start_life_expectancy,
    end_life_expectancy,
    (end_life_expectancy - start_life_expectancy) AS life_expectancy_change
FROM values_cte
ORDER BY life_expectancy_change DESC;
