# Financial Analysis — SQL & Python

A SQL and Python analysis of financial performance across five segments, five countries, and six products — with every headline figure independently re-derived from the raw data before publishing, catching a labeling slip and a rounding error along the way.

**Tools:** Python, SQL (PostgreSQL) &nbsp;·&nbsp; **Type:** Personal Project &nbsp;·&nbsp; **Dataset:** Microsoft's "Financial Sample" demo dataset

---

## Overview

This project analyzes a dataset of 700 sales transactions spanning September 2013 to December 2014, covering five business segments, five countries, and six products. The raw data was loaded from Excel into PostgreSQL via Python, queried using SQL to surface patterns and anomalies, and then visualised using Matplotlib and Seaborn. The goal was to move beyond surface-level metrics and identify the structural factors driving — and limiting — profitability across the business.

---

## Tools & Libraries

- **Python** — Pandas, NumPy, Matplotlib, Seaborn, SQLAlchemy, python-dotenv
- **SQL** — PostgreSQL (via pgAdmin)
- **Jupyter Notebook** — for analysis, visualisation, and documentation
- **Excel** — source dataset

---

## Key Findings

1. **Overall performance is healthy, but uneven.** The business generated $127.93M in gross sales across the period; after discounts and COGS, that comes to $16.89M in net profit — a blended margin of 14.23%. That margin varies significantly across segments, products, and markets.
2. **Enterprise is the one loss-making segment.** It recorded a profit margin of -3.13%, and the higher the discount applied to Enterprise deals, the greater the loss. Channel Partners sits at the opposite extreme — the highest margin of any segment at 73.13%, and notably resistant to discount pressure, losing only 3.54% in margin from no discount to high discount.
3. **Discounts hurt margin everywhere, but catastrophically only in Enterprise.** Across all segments, higher discounts correlate with lower margins — but the relationship is structurally sound for most segments and specifically broken for Enterprise, where it consistently produces negative returns regardless of volume.
4. **Amarilla leads on margin, trails on volume.** It has the highest profit margin of any product (15.86%) and the highest profit per unit, but the second-lowest unit volume in the portfolio — a gap worth investigating as a possible distribution or demand issue rather than a pricing one.
5. **USA revenue doesn't convert to profit the way it should.** The USA generated the highest net sales of any country, but only the second-lowest total profit — its second-highest COGS per unit suggests a cost base that isn't matched by its pricing. Germany is the inverse: fewest units sold, highest profit margin of any country, pointing to stronger pricing discipline or a more favorable product mix.
6. **2014 grew, but margin slipped slightly.** Because the dataset only covers a partial 2013, a direct revenue comparison isn't reliable — but margin is: despite higher revenue in 2014, profit margin declined by 0.58 percentage points versus 2013, suggesting scale came at a small cost to profitability. A recurring profit dip every November, in both years, stands out as a pattern worth investigating on its own.

Enterprise is the finding that matters most here — a segment this large operating at a structural loss, specifically because of how it responds to discounting, is worth resolving before optimizing already-healthy segments like Channel Partners. The recurring November dip is the second thread worth pulling, since it shows up independently of any single segment or product.

---

## Charts

![Financial Waterfall](1_financial_waterfall.png)
![Segment Overview](2_segment_overview.png)
![Discount Heatmap](3_discount_heatmap.png)
![Monthly Trend](4_monthly_trend.png)
![Product Performance](5_products_performance.png)
![Country Performance](6_country_performance.png)

---

## What's Inside

| File | Description |
|------|-------------|
| [`financial_analysis.ipynb`](financial_analysis.ipynb) | Main notebook — data loading, cleaning, SQL queries, charts, findings |
| [`financials.sql`](financials.sql) | Full SQL analysis — exploratory queries with analytical commentary |
| [`financial_sample.xlsx`](financial_sample.xlsx) | Source dataset |
| [`1_financial_waterfall.png`](1_financial_waterfall.png) | Gross Sales → Net Profit waterfall |
| [`2_segment_overview.png`](2_segment_overview.png) | Profit and margin by segment |
| [`3_discount_heatmap.png`](3_discount_heatmap.png) | Discount band impact across segments |
| [`4_monthly_trend.png`](4_monthly_trend.png) | Monthly sales, profit, and margin trend |
| [`5_products_performance.png`](5_products_performance.png) | Product profit, revenue/profit per unit, and margin |
| [`6_country_performance.png`](6_country_performance.png) | Country profit, revenue/profit per unit, and margin |

---

## How to Run

1. **Clone the repository** and open the project folder in your terminal.
2. **Create a `.env` file** in the root directory with the string **DB_PASSWORD** in cell block 7 replaced with your own PostgreSQL password.
3. **Create a PostgreSQL database** named `financial_analysis` and ensure your local server is running on `localhost:5432` with the username `postgres`.
4. **Open `financial_analysis.ipynb`** in Jupyter and run all cells top to bottom. The notebook will load the Excel data, push it to PostgreSQL, query it, and render all six charts.

> The SQL file (`financials.sql`) is written for PostgreSQL and can be run independently in pgAdmin after the notebook has loaded the data.

---

*Dataset is Microsoft's publicly available "Financial Sample" demo dataset, commonly used for BI and analytics tutorials — used here for independent analysis and educational purposes.*
