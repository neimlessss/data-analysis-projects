# Customer Churn Case Study In Excel.

**Tool:** Microsoft Excel.

**Type:** DataCamp Course Project.

An interactive Excel dashboard analysing churn drivers across 6,687 telecom customers, segmenting by contract type, tenure, age, data usage, and international plan status — paired with a written finding and recommendation, and a data-integrity investigation that shaped the final calculations.

---

## Dashboard Preview.

![Customer Churn Dashboard](Overview.png)

---

## Key Finding

Churn is concentrated in new, month-to-month customers: subscribers on month-to-month contracts within their first 12 months churn at **53.8%**, versus under **1%** for 2-year contracts at the same tenure.

Contract type and tenure are the strongest churn predictors in this dataset — a larger effect than age or data usage.

This lines up with the churn-reason data: competitor offers and devices, not service dissatisfaction, are the leading stated reasons for leaving — suggesting this segment is price/offer-sensitive rather than dissatisfied with service.

**Recommendation:** Prioritize retention offers — e.g., a discounted incentive to convert to a 1-year contract — for month-to-month customers within their first year.
This segment shows the highest concentration of churn risk, and is more likely to respond to pricing incentives than service-quality fixes.

---

## Data Integrity.

The source data included two tables: an individual-level customer table (`Databel – Customer`) and a pre-aggregated rollup (`Databel – Aggregate`).

Investigation into a row-count mismatch between the two revealed the rollup silently blanked several fields — Contract Type, Payment Method, Group, Churn Category, and Churn Reason — for every non-Senior customer before grouping.

- This meant any pivot table built on the rollup for those fields was unknowingly reflecting only the Senior subset (~18% of customers), not the full population.
- The affected calculation — churn rate by tenure and contract type — was identified via a `#DIV/0!` error traced back to this root cause, then rebuilt directly from the individual-level table (using `AVERAGE` on a binary churn flag) to reflect all 6,687 customers.
- Every other breakdown on the dashboard was audited field-by-field to confirm it didn't rely on the same blanked columns before being left on the original source.

---

## What's Inside.

| File | Description |
|------|-------------|
| [`Customer Churn_Case_Study.xlsx`](Customer_Churn_Case_Study.xlsx) | Full workbook. |
| [`Overview.png`](Overview.png) | Overview tab screenshot |

---

## Features.

- KPI summary cards (Total Customers, Churned Customers, Churn Rate %) alongside 5 pivot-driven charts — Churn Reasons, Demographics, Age Group Analysis, Consumption Churn, and Competitor Churn Analysis
- Cross-referenced pivot tables across tenure, contract type, age bracket, data usage tier, and state (filtered to International Plan subscribers)
- Native Excel grouping applied to tenure into 12-month bands for readable trend comparison
- A written Key Finding & Recommendation panel translating the pivot data into a stated conclusion and action, not just a set of tables
- A documented data-integrity fix, tracing a `#DIV/0!` error back to a source-data limitation rather than treating it as a formatting issue

---

## How to View.

Download `Customer Churn Case Study.xlsx` and open it in Microsoft Excel (2016 or later recommended, for full PivotTable and grouping support). Start on the **Overview** tab; use the **Intl Plan** filter on the State breakdown to toggle between subscriber groups.

---

*Dataset is purely for analytical and educational purposes.*
