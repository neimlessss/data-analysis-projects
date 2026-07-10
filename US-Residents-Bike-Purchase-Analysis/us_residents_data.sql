-- ============================================================
-- US RESIDENTS DATA — EXPLORATORY SQL
-- Tool: MySQL 8 / MySQL Workbench

-- A note on scope: this dataset contains 1,000 residents across three named cities.
-- Every finding below describes a pattern within this dataset.
-- It is NOT a claim about the actual populations of Chicago, Los Angeles, or New York City.
-- "192 residents in Los Angeles" means 192 rows tagged Los Angeles in this data, not the city's population.

-- This script is read-only exploration. Cleaning happens separately, in Power Query.
-- ============================================================


-- ============================================================
-- PART 1: GETTING ORIENTED.
-- ============================================================
-- First confirming if the data loaded completely.
SELECT COUNT(*) AS total_rows
FROM raw_residents_data;
-- 1,026 rows. First thing to check before trusting anything else.

-- Confirming data integrity.
SELECT COUNT(DISTINCT ID) AS unique_residents
FROM raw_residents_data;
-- 1,000 unique IDs against 1,026 rows — 26 more rows than residents.
-- Worth understanding before any aggregate number can be trusted.


-- ============================================================
-- PART 2: DATA QUALITY.
-- A few checks before anything gets aggregated:
-- Data types, duplicate rows, missing values, and whether Income has any values extreme enough to distort an average.
-- ============================================================

-- Checking the duplicate rows.
SELECT *
FROM raw_residents_data
WHERE ID IN (
    SELECT ID
    FROM raw_residents_data
    GROUP BY ID
    HAVING COUNT(ID) > 1
)
ORDER BY ID;
-- Every field is identical between a resident's duplicated rows except Tax.
-- Reads like two separate tax records per resident (e.g. two filing periods), not a data entry error.
-- Nothing else about each resident differs, which would be a strange coincidence for a genuine mistake.

-- Decision: keep both rows, count residents with COUNT(DISTINCT ID) from here on, never a plain row count.
-- Tax is left out of any per-resident calculation.
--  Collapsing to one row per ID would mean arbitrarily discarding one of two real tax values.

-- With the duplicate rows accounted for, checking how MySQL is actually reading each column before doing anything further.
DESCRIBE raw_residents_data;
-- Everything is correct except income.
-- Surmising it's because of the way it was formatted with symbols from Excel.
-- Will have to fix this in order to be able to perform any calculations on income.

-- Checking if there are any missing values, across every column.
-- Best to know if anything else needs correcting, in order to make all fixes once.
SELECT
    SUM(CASE WHEN ID IS NULL THEN 1 ELSE 0 END) AS nullrows_id,
    SUM(CASE WHEN `Marital Status` IS NULL THEN 1 ELSE 0 END) AS nullrows_marital_status,
    SUM(CASE WHEN Gender IS NULL THEN 1 ELSE 0 END) AS nullrows_gender,
    SUM(CASE WHEN Income IS NULL THEN 1 ELSE 0 END) AS nullrows_income,
    SUM(CASE WHEN Education IS NULL THEN 1 ELSE 0 END) AS nullrows_education,
    SUM(CASE WHEN Occupation IS NULL THEN 1 ELSE 0 END) AS nullrows_occupation,
    SUM(CASE WHEN Cars IS NULL THEN 1 ELSE 0 END) AS nullrows_cars,
    SUM(CASE WHEN `Commute Distance` IS NULL THEN 1 ELSE 0 END) AS nullrows_commute_distance,
    SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS nullrows_city,
    SUM(CASE WHEN `Purchased Bike` IS NULL THEN 1 ELSE 0 END) AS nullrows_purchased_bike,
    SUM(CASE WHEN Tax IS NULL THEN 1 ELSE 0 END) AS nullrows_tax
FROM raw_residents_data;
-- Zero missing values across every column checked. Nothing to clean or impute.
-- Better to confirm than assume, same as the duplicate check above.

-- The Income field came in form of string to SQL, as it has the '$' attached.
-- Therefore, view used to convert Income into a numeric field for aggregation.
-- Raw table is left untouched.
-- CREATE OR REPLACE means this can be rerun safely without dropping the view first.
CREATE OR REPLACE VIEW income_cleaned AS
SELECT
    *,
    CAST(REPLACE(REPLACE(Income, '$', ''), ',', '') AS DECIMAL(10,2)) AS Income_Number
FROM raw_residents_data;

-- Does Income have any values extreme enough to distort an average?
SELECT
    CONCAT(
		'$', FORMAT(MIN(Income_Number), 2)
    ) AS min_income,
    CONCAT(
		'$', FORMAT(MAX(Income_Number), 2)
    ) AS max_income,
    CONCAT(
		'$', FORMAT(AVG(Income_Number), 2)
    ) AS avg_income,
    CONCAT(
		'$', FORMAT(STDDEV(Income_Number), 2)
    ) AS stddev_income
FROM income_cleaned;
-- Range: $10,000 to $170,000.
-- Highest values are roughly 3.6 standard deviations above the mean — using z-score measurement.
-- Worth a second look before trusting any average built on this column.

SELECT  DISTINCT ID, 
	CONCAT(
		'$', FORMAT(Income_Number, 2)
    ) AS Formatted_Income, 
	Occupation, 
	City
FROM (
    SELECT DISTINCT ID, Income_Number, Occupation, City
    FROM income_cleaned
    ORDER BY Income_Number DESC
    LIMIT 10
) AS top_incomes;
-- The top incomes ($150K-$170K) belong to 10 different residents, spread across different cities and occupations.
-- It doesn't look like a suspicious record repeated or an isolated typo.
-- No evidence of a data entry error.
-- Kept in as genuine values, even if high.


-- ============================================================
-- PART 3: THE OVERALL NUMBERS.
-- Before segmenting anything, what does the data look like as a whole?
-- These are the plain, un-sliced figures.
-- ============================================================

SELECT
    CONCAT(
		'$', FORMAT(AVG(Income_Number), 2)
	) AS avg_income,
    CONCAT(
		'$', FORMAT(SUM(Income_Number), 2)
	) AS total_income
FROM (
    SELECT DISTINCT ID, Income_Number
    FROM income_cleaned
) AS one_row_per_resident;
-- Average Income: $56,360.00 | Total Income: $56,360,000.00
-- Computed from one row per resident.
-- Using the raw 1,026-row table directly here would double-count the 26 duplicated residents and quietly shift both figures.

SELECT
	CONCAT(
		'$', FORMAT(SUM(Tax), 2)
    ) AS total_tax
FROM raw_residents_data;
-- Total Tax: $3,104,049.
-- Unlike Income, this intentionally uses every row, duplicates included.
-- The two Tax values per duplicated resident are genuinely different records (Part 2a), not repeats.


-- ============================================================
-- PART 4: WHAT ARE WE ACTUALLY EXPLAINING?
-- Before testing anything against it, check what "Purchased Bike" looks like on its own.
-- ============================================================

SELECT
    `Purchased Bike`,
    COUNT(DISTINCT ID) AS resident_count,
    CONCAT(
		FORMAT(COUNT(DISTINCT ID) / (SELECT COUNT(DISTINCT ID) FROM raw_residents_data) * 100, 1), '%'
	) AS pct
FROM raw_residents_data
GROUP BY `Purchased Bike`
ORDER BY resident_count DESC;
-- Close to even: 51.9% No / 48.1% Yes.
-- Worth knowing up front — a near-even split means any predictor found later is a real signal, not an artifact of one outcome already dominating the data.


-- ============================================================
-- PART 5: DOES GEOGRAPHY MATTER?
-- The most obvious first cut of the data.
-- ============================================================
-- Investigating average income by city.
SELECT
    City,
    CONCAT(
		'$', FORMAT(AVG(Income_Number), 2)
	) AS avg_income,
    COUNT(DISTINCT ID) AS resident_count
FROM income_cleaned
GROUP BY City
ORDER BY AVG(Income_Number) DESC;
-- Los Angeles:    $63,593.75 (192 residents in the data)
-- Chicago:        $62,755.91 (508 residents in the data)
-- New York City:  $40,900.00 (300 residents in the data)
-- Los Angeles edges out Chicago on income despite having the fewest residents recorded of the three.

-- Does purchase behavior follows the same pattern?
SELECT
    City,
    COUNT(DISTINCT ID) AS resident_count,
    CONCAT(
		FORMAT(COUNT(DISTINCT ID) / (SELECT COUNT(DISTINCT ID) FROM raw_residents_data) * 100, 1), '%'
    ) AS resident_count_pct,
    COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) AS buyers,
    CONCAT(
		FORMAT(COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) * 100, 1), '%'
	) AS purchase_rate
FROM raw_residents_data
GROUP BY City
ORDER BY COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) DESC;
-- Los Angeles:    58.9% (113 of 192) — the only city above 50%
-- New York City:  49.3% (148 of 300)
-- Chicago:        43.3% (220 of 508)
-- Confirms it: Los Angeles outperforms on both income and purchase rate, despite contributing the fewest residents to the dataset.
-- Chicago with the highest number of residents here, more than 2.5x of Los Angeles, has the lowest purchase rate.
-- The number of rows recorded for a city says nothing about how that city performs.
-- Worth flagging directly, since it would be easy to assume a smaller group in the data is a smaller opportunity.


-- ============================================================
-- PART 6: DOES BASIC DEMOGRAPHICS MATTER?
-- Testing the two obvious candidates — Gender and Marital Status — before anything more specific.
-- ============================================================

-- Gender first.
SELECT
    Gender,
    COUNT(DISTINCT ID) AS resident_count,
    CONCAT(
		FORMAT(COUNT(DISTINCT ID) / (SELECT COUNT(DISTINCT ID) FROM raw_residents_data) * 100, 1), '%'
    ) AS resident_count_pct,
    COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) AS buyers,
    CONCAT(
		FORMAT(COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) * 100, 1), '%'
	) AS purchase_rate
FROM raw_residents_data
GROUP BY Gender
ORDER BY COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) DESC;
-- Female (489): 48.9% | Male (511): 47.4%
-- Population is close to even and purchase rate barely differs.
-- Therefore, Gender doesn't predict anything on its own.

-- Then Marital Status.
SELECT
    `Marital Status`,
    COUNT(DISTINCT ID) AS resident_count,
    CONCAT(
		FORMAT(COUNT(DISTINCT ID) / (SELECT COUNT(DISTINCT ID) FROM raw_residents_data) * 100, 1), '%'
    ) AS resident_count_pct,
    COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) buyers,
    CONCAT(
		FORMAT(COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) * 100, 1), '%'
	) AS purchase_rate
FROM raw_residents_data
GROUP BY `Marital Status`
ORDER BY COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) DESC;
-- Single (462): 54.1% | Married (538): 42.9%
-- Unlike Gender, this one holds up — an 11.2% gap is a real, moderate signal.


-- ============================================================
-- PART 7: DOES OCCUPATION MATTER?
-- ============================================================

SELECT
    Occupation,
    COUNT(DISTINCT ID) AS resident_count,
    CONCAT(
		FORMAT(COUNT(DISTINCT ID) / (SELECT COUNT(DISTINCT ID) FROM raw_residents_data) * 100, 1), '%'
    ) AS resident_count_pct,
    COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) AS buyers,
    CONCAT(
		FORMAT(COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) * 100, 1), '%'
	) AS purchase_rate
FROM raw_residents_data
GROUP BY Occupation
ORDER BY COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) DESC;
-- Professional:     54.3% (highest)
-- Clerical:         49.7%
-- Manual:           46.2%
-- Skilled Manual:   45.1%
-- Management:       42.2% (lowest)
-- Management has the lowest purchase rate of any occupation.

-- Does income have a part to play in that?
SELECT
    Occupation,
    CONCAT(
		'$', FORMAT(AVG(Income_Number), 2)
    ) AS avg_income,
    COUNT(DISTINCT ID) AS resident_count
FROM income_cleaned
GROUP BY Occupation
ORDER BY AVG(Income_Number) DESC;
-- Management:   $86,647.40 (highest income, by a clear margin)
-- Professional: $75,072.46 (second-highest)
-- Management earns the most of any occupation but buys the least.
-- Professional is both the second-highest earner and the most likely to buy.
-- This is the more interesting version of the "geography doesn't predict performance" finding from earlier.
-- Here, it's income that doesn't predict performance.


-- ============================================================
-- PART 8: DOES EDUCATION MATTER?
-- Same two-part test as Occupation, to see if the same reversal shows up or if education behaves differently.
-- ============================================================

SELECT
    Education,
    COUNT(DISTINCT ID) AS resident_count,
    CONCAT(
		FORMAT(COUNT(DISTINCT ID) / (SELECT COUNT(DISTINCT ID) FROM raw_residents_data) * 100, 1), '%'
    ) AS resident_count_pct,
    COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) AS buyers,
    CONCAT(
		FORMAT(COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) * 100, 1), '%'
	) AS purchase_rate
FROM raw_residents_data
GROUP BY Education
ORDER BY COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) DESC;
-- Bachelors:            55.2% (highest)
-- Graduate Degree:      54.0%
-- Partial College:      44.9%
-- High School:          44.1%
-- Partial High School:  26.3% (lowest, and the steepest drop of any single-variable cut in the dataset).

SELECT
    Education,
    CONCAT(
    '$', FORMAT(AVG(Income_Number), 2)
    ) AS avg_income,
    COUNT(DISTINCT ID) AS resident_count
FROM income_cleaned
GROUP BY Education
ORDER BY AVG(Income_Number) DESC;
-- Graduate Degree:      $65,942.86 (highest)
-- Bachelors:            $63,054.66
-- Partial College:      $54,604.32
-- High School:          $47,173.91
-- Partial High School:  $34,102.56 (lowest)
-- Unlike Occupation, income and purchase rate move together here
-- Both rise with education level, no reversal.
-- Worth reporting alongside Occupation specifically because they contrast.
-- One variable where income and behavior agree, one where they don't.


-- ============================================================
-- PART 9: WHAT ABOUT BEHAVIOR, NOT JUST DEMOGRAPHICS?
-- Geography and demographics gave one strong-ish signal (Marital Status) and one genuine reversal (Occupation).
-- Testing two behavioral variables next.
-- Since those 2 weren't an obvious first guess but turned out to matter more than anything above.
-- ============================================================

-- Commute Distance first.
SELECT
    `Commute Distance`,
    COUNT(DISTINCT ID) AS resident_count,
    CONCAT(
		FORMAT(COUNT(DISTINCT ID) / (SELECT COUNT(DISTINCT ID) FROM raw_residents_data) * 100, 1), '%'
    ) AS resident_count_pct,
    COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) AS buyers,
    CONCAT(
		FORMAT(COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) * 100, 1), '%'
	) AS purchase_rate
FROM raw_residents_data
GROUP BY `Commute Distance`
ORDER BY COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) DESC;
-- 2-5 Miles:   58.6% (highest)
-- 0-1 Miles:   54.6%
-- 1-2 Miles:   45.6%
-- 5-10 Miles:  39.6%
-- 10+ Miles:   29.7% (lowest)
-- The clearest pattern found so far — a genuine decline as commute distance increases.
-- Wider than anything before this.

-- Now, checking cars.
SELECT
    Cars,
    COUNT(DISTINCT ID) AS resident_count,
    CONCAT(
		FORMAT(COUNT(DISTINCT ID) / (SELECT COUNT(DISTINCT ID) FROM raw_residents_data) * 100, 1), '%'
    ) AS resident_count_pct,
    COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) AS buyers,
    CONCAT(
		FORMAT(COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) * 100, 1), '%'
    ) AS purchase_rate
FROM raw_residents_data
GROUP BY Cars
ORDER BY COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) DESC;
-- 0 cars: 61.1% | 1 car: 56.9% | 2 cars: 36.3%
-- 3 cars: 38.8% | 4 cars: 35.6%
-- Same shape as Commute Distance — purchase rate falls sharply once a resident owns 2 or more cars.
-- Between these two, this is the strongest, most consistent signal in the whole dataset.

-- ============================================================
-- PART 10: LIFE STAGE — AGE, CHILDREN AND HOME OWNERSHIP.
-- Three variables outside the standard demographic/behavioral categories tested above.
-- ============================================================

-- Age first — checking the range before bucketing.
SELECT MIN(Age), MAX(Age)
FROM raw_residents_data;
-- Youngest resident in the data is 25, oldest is 89.

-- Bucketed into three groups.
-- Senior and Elderly were originally split at age 75, but the resulting Elderly
-- bucket held only 4 residents — too small a group to report a reliable rate from.
-- Merged into a single Senior/Elderly bucket here instead.
SELECT
    CASE
        WHEN Age >= 25 AND Age < 40 THEN 'Adult'
        WHEN Age >= 40 AND Age < 60 THEN 'Middle Age'
        ELSE 'Senior/Elderly'
    END AS age_group,
    COUNT(DISTINCT ID) AS resident_count,
    CONCAT(
		FORMAT(COUNT(DISTINCT ID) / (SELECT COUNT(DISTINCT ID) FROM raw_residents_data) * 100, 1), '%'
    ) AS resident_count_pct,
    COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) AS buyers,
    CONCAT(
		FORMAT(COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) * 100, 1), '%'
	) AS purchase_rate
FROM raw_residents_data
GROUP BY age_group
ORDER BY COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) DESC;
-- Adult: 55.7% | Middle Age: 45.9% | Senior/Elderly: 32.2%
-- A clean, consistent decline across all three groups.
-- An interesting find, comparable in reliability to Commute Distance and Cars.

-- Children next.
SELECT Children,
    COUNT(DISTINCT ID) AS resident_count,
    CONCAT(
		FORMAT(COUNT(DISTINCT ID) / (SELECT COUNT(DISTINCT ID) FROM raw_residents_data) * 100, 1), '%'
    ) AS resident_count_pct,
    COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) AS buyers,
    CONCAT(
		FORMAT(COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) * 100, 1), '%'
	) AS purchase_rate
FROM raw_residents_data
GROUP BY Children
ORDER BY Children;
-- 0: 50.5% | 1: 57.4% | 2: 46.4% | 3: 54.5% | 4: 42.9% | 5: 22.2%
-- No consistent direction — rises, falls, rises, falls again before a steep drop at 5.
-- The 5-children group is also a small subgroup, and having more children correlates with being older.
-- — A variable already confirmed above as a real predictor on its own.
-- Doesn't look like a relevant find.

-- Investigating home ownership status.
SELECT `Home Owner`,
	COUNT(DISTINCT ID) AS resident_count,
    CONCAT(
		FORMAT(COUNT(DISTINCT ID) / (SELECT COUNT(DISTINCT ID) FROM raw_residents_data) * 100, 1), '%'
    ) AS resident_count_pct,
    COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) AS buyers,
    CONCAT(
		FORMAT(COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) * 100, 1), '%'
    ) AS purchase_rate
FROM raw_residents_data
GROUP BY `Home Owner`
ORDER BY COUNT(DISTINCT CASE WHEN `Purchased Bike` = 'Yes' THEN ID END) / COUNT(DISTINCT ID) DESC;
-- The difference between these two categories is very little, just like gender.
-- More home owners, with just 683 residents in the data, but only 47.6% of them purchased bikes.
-- Those who don't own homes are 317, but only 49.2% of them purchased bikes.
-- Neither category is even approximately 50%.
-- Doesn't give much to work on.
    

-- ============================================================
-- SUMMARY: WHAT MADE THE CUT
-- Not every variable tested here turned into a headline finding.
-- Gender and Home Owner were tested and found not to predict anything on their own.
-- Children was tested and showed no consistent direction, with its one striking value
-- (5 children, 22.2%) resting on a small subgroup and likely reflecting Age rather than
-- an independent effect of its own.
-- Almost everything else held up as a genuine pattern.
-- ============================================================
-- 1. Commute distance and cars owned predict purchase behavior more than anything else tested.
--    A decline from 58.6%/61.1% down to 29.7%/roughly 36% as commute distance and car count rise.

-- 2. A city contributing fewer rows to this dataset doesn't mean weaker performance.
--    Los Angeles has the fewest residents in the data (192) but the highest income and purchase rate.
--    Chicago has the most (508) but underperforms both New York City and Los Angeles.

-- 3. Management earns the most in the data ($86,647.40) but has the lowest purchase rate (42.2%).
--    Professional earns second-most ($75,072.46) and has the highest purchase rate (54.3%).
--    Income and behavior move in opposite directions here.

-- 4. Marital Status is a real, moderate predictor (Single 54.1% vs Married 42.9%), while Gender is not (47.4% vs 48.9%).
--    Reported specifically because it's a false lead worth naming.

-- 5. Education shows the same rising pattern in both income and purchase rate — unlike Occupation, there's no reversal here.
--    Partial High School is lowest on both; Bachelors and Graduate Degree
--    are highest on both.

-- 6. Age shows a clean, monotonic decline in purchase rate.
--    Adult (55.7%) down to Middle Age (45.9%) down to Senior/Elderly (32.2%).
--    As reliable a pattern as Commute Distance or Cars.