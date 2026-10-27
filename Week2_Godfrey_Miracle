# Global Superstore Sales & Profitability Dashboard

**AnalystLab Africa | Data Analytics Internship | Week 2: Business Analytics Case Study**

An interactive Power BI dashboard that shows management where Global Superstore makes money, where it loses money, and what to change.

## Business problem

Global Superstore has years of order data but no single view of how the business is performing. Management wants to monitor sales, profitability, customer behaviour and regional performance in one place. Sales and profit are not the same thing: the company recorded $12.64M in sales but only $1.47M in profit (an 11.61% margin), and about a quarter of order lines lose money.

## Dataset

- **Source:** Global Superstore dataset on Kaggle (<https://www.kaggle.com/datasets/apoorvaappz/global-super-store-dataset>). The raw file is not redistributed in this repository, so download it from Kaggle to rebuild the report.
- **Size:** 51,290 order lines, 24 columns, January 2011 to December 2014.
- **Coverage:** 7 markets, 147 countries, 3 product categories and 17 sub-categories, 3 customer segments.

## Tools

Microsoft Power BI Desktop (Power Query, DAX, report design).

## Data preparation (Power Query)

1. Imported the CSV with Western European (Windows-1252) encoding.
2. Promoted headers and checked column quality across the full dataset, not just the first 1,000 rows.
3. Converted `Order Date` and `Ship Date` from text (DD-MM-YYYY) to dates using the English (United Kingdom) locale, so days and months were not swapped.
4. Corrected data types: `Postal Code` and `Row ID` as text, `Quantity` as whole number, `Sales`, `Profit`, `Shipping Cost` and `Discount` as numbers.
5. Trimmed and cleaned the text columns.
6. Checked for duplicates: none found (row count stayed at 51,290).
7. Checked for missing values: the only blanks are in `Postal Code` (about 80% of rows), because postal codes exist only for US rows. They were left as blanks and not used in any visual.
8. Added a `Ship Days` column (ship date minus order date). The minimum is 0, so there are no ship dates before order dates.

## Data model and calculations

- A `Date` table (2011 to 2014) with Year, Month Number, Month Name and Month Start columns, related one-to-many to `Order Date`. Month Name is sorted by Month Number.
- A `Discount Band` calculated column that groups each order line into None, Up to 10%, 10-20%, 20-30%, 30-50% or Over 50%.

```
Discount Band = SWITCH(TRUE(),
  Global_Superstore[Discount]=0,"1. None",
  Global_Superstore[Discount]<=0.1,"2. Up to 10%",
  Global_Superstore[Discount]<=0.2,"3. 10-20%",
  Global_Superstore[Discount]<=0.3,"4. 20-30%",
  Global_Superstore[Discount]<=0.5,"5. 30-50%",
  "6. Over 50%")
```

- Measures:

```
Total Sales   = SUM(Global_Superstore[Sales])
Total Profit  = SUM(Global_Superstore[Profit])
Total Orders  = DISTINCTCOUNT(Global_Superstore[Order ID])
Average Sales = DIVIDE([Total Sales], [Total Orders])
Profit Margin = DIVIDE([Total Profit], [Total Sales])
```

`Total Orders` counts distinct order IDs (25,035), not rows, because one order can have several lines. `Average Sales` is sales per order.

## Dashboard pages

| Page | What it shows |
|---|---|
| Executive Dashboard | 5 KPI cards, sales and profit by month, sales by segment, sales and profit by year, profit by market, year / market / segment slicers |
| Regional Performance | Sales by country map, profit by region, market and region matrix with margin highlighting |
| Product Performance | Sales and profit by category, profit by sub-category, top 10 products by profit |
| Insights | Profit by discount band, bottom 10 countries by profit, key insights, risks, opportunities and recommendations |

## Key findings

- Sales grew 90% from $2.26M (2011) to $4.30M (2014), but margin stayed flat at about 11 to 12%.
- Technology earns 45% of total profit (14.0% margin). Furniture is 33% of sales but 19% of profit (6.9% margin).
- 24.5% of order lines lose money. Their average discount is about 45%, against about 4% on profitable lines.
- Order lines discounted by more than 30% lost about $793K, roughly 54% of net profit.
- Tables lose $64K, and 29 of 147 countries lose money overall (Turkey and Nigeria are the largest losses).
- APAC earns the most profit ($436K). EMEA earns only a 5.45% margin on $806K of sales.
- November and December bring in about 25% of annual sales.

## Recommendations

1. Cap discounts, or require approval, above 30%.
2. Review pricing for Tables and the Furniture category.
3. Investigate loss-making countries before investing further.
4. Prioritise Technology and high-margin Office Supplies lines.
5. Address EMEA's low margin, pilot growth in Canada, and plan for the November to December peak.

## Assumptions and limitations

- The dataset does not state a currency. Figures use the `$` symbol shown in the dashboard.
- The estimate that recovering half of the losses on 30%+ discounts would add about $0.4M assumes sales volumes would not fall. It is an estimate, not a forecast.
- The data covers 2011 to 2014 only.
- The map visual needs Map and Filled Map visuals enabled in Power BI Desktop (File > Options > Security).

## Repository contents

```
.
├── Global_Superstore_Analysis.pbix      Power BI project file
├── Global_Superstore_Dashboard.pdf                 Dashboard export (all filters cleared)
├── Business_Intelligence_Overview_Report.docx              Part 1: Business Intelligence overview
├── Executive_Summary.docx        Insights, risks, opportunities, recommendations
├── screenshots/                         Dashboard page images
└── README.md
```

## Author

**Godfrey Miracle** | Data Analytics Intern, AnalystLab Africa
LinkedIn: <https://www.linkedin.com/in/miracle-godfrey-815b60225/>
GitHub: <https://github.com/godfreymiracle-cmd>

#AnalystLabAfrica
