-- First confirming the data loaded completely.
SELECT COUNT(*) AS total_rows
FROM financials;

-- Now confirming the different distinct values in each relevant field.
-- To help understand the shape of the data before measuring and calculating.
SELECT DISTINCT segment
FROM financials
ORDER BY segment;

SELECT DISTINCT country
FROM financials
ORDER BY country;

SELECT DISTINCT product
FROM financials
ORDER BY product;

SELECT DISTINCT year
FROM financials
ORDER BY year;

SELECT DISTINCT discount_band
FROM financials
ORDER BY discount_band;

-- Calculating the total values of all numerical fields.
SELECT
	TO_CHAR(SUM(gross_sales), 'FM$999,999,999.00') AS total_gross_sales,
	TO_CHAR(SUM(discounts), 'FM$999,999,999.00') AS total_discounts,
	TO_CHAR(SUM(sales), 'FM$999,999,999.00') AS total_net_sales,
	TO_CHAR(SUM(cogs), 'FM$999,999,999.00') AS total_cogs,
	TO_CHAR(SUM(profit), 'FM$999,999,999.00') AS total_profit,
	TO_CHAR(AVG(profit), 'FM$999,999,999.00') AS avg_profit_per_transaction
FROM financials;

-- Understanding how the business did by segment.
SELECT segment,
	COUNT(*) AS num_transactions,
	TO_CHAR(SUM(sales), 'FM$999,999,999.00') AS total_sales,
	TO_CHAR(SUM(profit), 'FM$999,999,999.00') AS total_profit,
	TO_CHAR(SUM(units_sold), 'FM999,999,999.00') AS total_units_sold,
	TO_CHAR(
			SUM(profit) / NULLIF(SUM(sales), 0) * 100, 'FM999.00%'
	) AS profit_margin_pct
FROM financials
GROUP BY segment
ORDER BY SUM(profit) DESC;
-- Enterprise was a loss, with profit margin at -3.13%.
-- Channel Partners had the highest profit margin by far at 73.13%, despite selling the 2nd least amount of units.
-- Worth noting for future reference.

-- Understanding how the business did by products.
SELECT product,
	COUNT(*) AS num_transactions,
	TO_CHAR(SUM(sales), 'FM$999,999,999.00') AS total_sales,
	-- ROUND(SUM(sales)::numeric, 2) AS total_sales,
	TO_CHAR(SUM(profit), 'FM$999,999,999.00') AS total_profit,
	TO_CHAR(SUM(units_sold), 'FM999,999,999.00') AS total_units_sold,
	TO_CHAR(
			SUM(profit) / NULLIF(SUM(sales), 0) * 100, 'FM999.00%'
	) AS profit_margin_pct
FROM financials
GROUP BY product
ORDER BY SUM(profit) DESC;
-- Profit margin from highest to lowest is just 3.22%.
-- Although, Amarilla, with the highest profit margin at 15.86%, had less units sold than Velo with the lowest at 12.64%.
-- And brought in more profit too.
-- Worth investigating.

-- Understanding how the business did by country.
SELECT country,
	COUNT(*) AS num_transactions,
	TO_CHAR(SUM(sales), 'FM$999,999,999.00') AS total_sales,
	TO_CHAR(SUM(profit), 'FM$999,999,999.00') AS total_profit,
	TO_CHAR(SUM(units_sold), 'FM999,999,999.00') AS total_units_sold,
	-- ROUND(SUM(profit)::numeric, 2) AS total_profit,
	TO_CHAR(
			SUM(profit) / NULLIF(SUM(sales), 0) * 100, 'FM999.00%'
	) AS profit_margin_pct
FROM financials
GROUP BY country
ORDER BY SUM(profit) DESC;
-- USA sold the 3rd most units, and also ammased the most revenue, but has the lowest profit margin.
-- Germany on the other hand, sold the least amount of units, but had the highest profit margin.
-- Difference of 3.69% between them, with all countries having the exact same no. of transactions.
-- Interesting stuff.

-- Understanding the impact of the discount bands.
SELECT discount_band,
	COUNT(*) AS num_transactions,
	TO_CHAR(SUM(sales), 'FM$999,999,999.00') AS total_sales,
	TO_CHAR(SUM(profit), 'FM$999,999,999.00') AS total_profit,
	TO_CHAR(SUM(units_sold), 'FM999,999,999.00') AS total_units_sold,
	TO_CHAR(
			SUM(profit) / NULLIF(SUM(sales), 0) * 100, 'FM999.00%'
	) AS profit_margin_pct
FROM financials
GROUP BY discount_band
ORDER BY SUM(profit) DESC;
-- The Medium and High discount bands have the least profit margin.
-- This is despite them selling the most units.
-- The lesser discount bands sold less units, yet were more profitable.

-- Now, understanding the discount bands in relation to the Enterprise segment specifically.
-- This is to investigate the earlier finding.
SELECT discount_band,
	COUNT(*) AS num_transactions,
	TO_CHAR(SUM(sales), 'FM$999,999,999.00') AS total_sales,
	TO_CHAR(SUM(profit), 'FM$999,999,999.00') AS total_profit,
	TO_CHAR(SUM(units_sold), 'FM999,999,999.00') AS total_units_sold,
	TO_CHAR(
			SUM(profit) / NULLIF(SUM(sales), 0) * 100, 'FM999.00%'
	) AS profit_margin_pct
FROM financials
WHERE segment='Enterprise'
GROUP BY discount_band
ORDER BY SUM(profit) DESC;
-- Turns out that, the higher the discount for Enterprise, the greater the loss.
-- The discount/pricing model may not be bad, but the Enterprise segment just can't take discounts.
-- Having no discount applied may lead to low revenue, but it's still profitable.
-- Higher discounts just bring in losses. It's bad for business.
-- This requires the model be immediately restructured to avoid even greater losses.
-- But, it's best to find out how this is affecting all segments, and not just Enterprise.

SELECT segment,
	discount_band,
	TO_CHAR(SUM(sales), 'FM$999,999,999.00') AS total_sales,
	TO_CHAR(SUM(profit), 'FM$999,999,999.00') AS total_profit,
	TO_CHAR(SUM(units_sold), 'FM999,999,999.00'),
	TO_CHAR(
			SUM(profit) / NULLIF(SUM(sales), 0) * 100, 'FM999.00%'
	) AS profit_margin_pct
FROM financials
GROUP BY segment, discount_band
ORDER BY segment, SUM(profit) DESC;
-- Turns out that, the bigger the discount applied to a segment, the less profitable it becomes.
-- It's just terribly structured in Enterprise.
-- But it seems like Channel Partners isn't really affected by it.
-- Just 3.54% difference from None to High.
-- Although Medium and High still have the lowest profit margin, they bring in the most profit.
-- It looks like the pricing model is structurally resistant to discount pressure.

-- Now investigating product breakdown based on earlier observation.
SELECT product,
	COUNT(*) AS num_transactions,
	TO_CHAR(SUM(units_sold), 'FM999,999,999.00') AS total_units_sold,
	TO_CHAR(SUM(sales), 'FM$999,999,999.00') AS total_sales,
	TO_CHAR(SUM(profit), 'FM$999,999,999.00') AS total_profit,
	TO_CHAR(
			SUM(sales) / NULLIF(SUM(units_sold), 0), 'FM$999,999,999.00'
	) AS revenue_per_unit,
	TO_CHAR(
			SUM(profit) / NULLIF(SUM(units_sold), 0), 'FM$999,999,999.00'
	) AS profit_per_unit,
	TO_CHAR(
			SUM(cogs) / NULLIF(SUM(units_sold), 0), 'FM$999,999,999.00'
	) AS cogs_per_unit,
	TO_CHAR(
			SUM(profit) / NULLIF(SUM(sales), 0) * 100, 'FM999.00%'
	) AS profit_margin_pct
FROM financials
GROUP BY product
ORDER BY SUM(profit) DESC;
-- Amarilla has the highest profit margin and profit per unit.
-- Meaning it generates the most value per naira of revenue.
-- However, it has the second-lowest unit volume — a separate issue.
-- That may reflect a distribution or demand problem worth investigating.

SELECT country,
	COUNT(*) AS num_transactions,
	TO_CHAR(SUM(units_sold), 'FM999,999,999.00') AS total_units_sold,
	TO_CHAR(SUM(sales), 'FM$999,999,999.00') AS total_sales,
	TO_CHAR(SUM(profit), 'FM$999,999,999.00') AS total_profit,
	TO_CHAR(
			SUM(sales) / NULLIF(SUM(units_sold), 0), 'FM$999,999,999.00'
	) AS revenue_per_unit,
	TO_CHAR(
			SUM(profit) / NULLIF(SUM(units_sold), 0), 'FM$999,999,999.00'
	) AS profit_per_unit,
	TO_CHAR(
			SUM(cogs) / NULLIF(SUM(units_sold), 0), 'FM$999,999,999.00'
	) AS cogs_per_unit,
	TO_CHAR(
			SUM(profit) / NULLIF(SUM(sales), 0) * 100, 'FM999.00%'
	) AS profit_margin_pct
FROM financials
GROUP BY country
ORDER BY SUM(profit) DESC;
-- USA has the 2nd highest COGS and revenue per unit, as well as highest number of units.
-- But then having the 2nd lowest total profit and profit per unit.
-- The USA pricing structure may not be optimised for its cost base.
-- This warrants a review of product mix and discount authorisation in that market.

-- Now assessing YoY performance.
SELECT year,
	COUNT(*) AS num_transactions,
	TO_CHAR(SUM(gross_sales), 'FM$999,999,999.00') AS total_gross_sales,
	TO_CHAR(SUM(discounts), 'FM$999,999,999.00') AS total_discounts,
	TO_CHAR(SUM(cogs), 'FM$999,999,999.00') AS total_cogs,
	TO_CHAR(SUM(sales), 'FM$999,999,999.00') AS total_net_sales,
	TO_CHAR(SUM(profit), 'FM$999,999,999.00') AS total_profit,
	TO_CHAR(
			SUM(profit) / NULLIF(SUM(sales), 0) * 100, 'FM999.00%'
	) AS profit_margin_pct
FROM financials
GROUP BY year
ORDER BY year;
-- 2014 did a lot better than 2013, but was less profitable by .58%

-- Assessing MoM growth in order to get the full picture.
SELECT year,
	EXTRACT(MONTH from date) AS month_num,
	TO_CHAR(date, 'Month') AS month_name,
	TO_CHAR(SUM(sales), 'FM$999,999,999.00') AS total_sales,
	TO_CHAR(SUM(profit), 'FM$999,999,999.00') AS total_profit,
	TO_CHAR(
			SUM(profit) / NULLIF(SUM(sales), 0) * 100, 'FM999.00%'
	) AS profit_margin_pct
FROM financials
GROUP BY year, month_num, month_name
ORDER BY year, month_num;
-- Data starts from late Q3 2013.
-- October 2013 is the most profitable month. Then December 2014.
-- Also, there's a significant drop across almost every quarter.
-- Q4 2013 (November), Q1 2014 (March), Q3 2014 (July) and Q4 2014 (November again).
-- There being a drop every November doesn't look like a coincidence.