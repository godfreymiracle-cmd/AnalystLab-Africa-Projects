# ShopSmart Retail Sales Analysis (Microsoft Excel)

**AnalystLab Africa Experience Lab Internship | Week 1 | Mission 01: Retail Sales Analysis with Microsoft Excel**

Prepared by **Godfrey Miracle**, Junior Data Analyst  
LinkedIn: https://www.linkedin.com/in/miracle-godfrey-815b60225/  
GitHub: https://github.com/godfreymiracle-cmd

---

## 1. Project overview

ShopSmart Retail Ltd operates stores across Nigeria and has noticed fluctuating sales, inventory shortages and rising product returns. This project cleans the company's data, analyses it in Microsoft Excel, builds an interactive executive dashboard and answers the management questions in the brief.

**Headline results (all 50,000 orders, 2025):**

| Measure | Value |
|---|---|
| Total revenue | ₦7,575,250,086 |
| Total orders | 50,000 |
| Total customers | 5,000 |
| Average order value | ₦151,505 |
| Return rate | 4.88% |
| Inventory value (at cost) | ₦3,169,020,818 |

The interactive dashboard (with six slicers) is on the `DASHBOARD` sheet of the workbook, and `Executive_Dashboard.pdf` is a one-page export of it.

## 2. Files in this submission

| File | Contents |
|---|---|
| `ShopSmart_Analysis.xlsx` | The full workbook: cleaned data tables, data quality log, KPI formulas, lookups, pivot tables, charts and dashboard |
| `Executive_Dashboard.pdf` | One-page export of the interactive dashboard |
| `Business_Report.pdf` | One-page business report: three findings, three recommendations, one risk, one opportunity |
| `Data_Understanding_and_Business_Answers.docx` | Part 1: one-page explanation of the datasets, keys and relationship diagram. Part 8: written answers to the ten business questions, with supporting figures |
| `README.md` | This file |

### Sheets in the workbook

| Sheet | Purpose |
|---|---|
| Nine data sheets (`ShopSmart_Customers`, `ShopSmart_Products`, `ShopSmart_Orders`, `ShopSmart_Stores`, `ShopSmart_Returns`, `ShopSmart_Employees`, `ShopSmart_Suppliers`, `ShopSmart_Inventory`, `ShopSmart_Order_Items`) | Source data, each stored as an Excel Table |
| `Data_Quality_Log` | Every cleaning check, its result and the action taken, plus issues noted but not changed |
| `KPI_Formulas` | The ten KPI formulas from Part 3 |
| `Pivots` | The 17 pivot tables: the ten required by Part 5, plus pivots for sales by region, return rate by category, sales by state (for the dashboard chart), the KPI cards, and the business questions (returns by product, products per supplier, inventory by store) |
| `DASHBOARD` | The executive dashboard from Part 7 |

## 3. Data understanding

Nine tables were provided. The assignment also lists a Data Dictionary workbook, but it was not included, so column meanings were taken from the column names and values.

| Table | Rows | Primary key | Foreign key(s) |
|---|---|---|---|
| Customers | 5,000 | Customer_ID | none |
| Products | 500 | Product_ID | none (Brand links to Suppliers) |
| Orders | 50,000 | Order_ID | Customer_ID, Product_ID, Store_ID |
| Order_Items | 50,000 | Order_Item_ID | Order_ID, Product_ID |
| Stores | 25 | Store_ID | none |
| Returns | 2,500 | Return_ID | Order_ID |
| Employees | 125 | Employee_ID | Store_ID |
| Suppliers | 489 | Supplier_ID | none |
| Inventory | 500 | Inventory_ID | Product_ID, Store_ID |

Every primary key is unique and every foreign key value exists in its parent table (no orphan records). Products has no supplier ID, so each product's Brand plus the word " Supplies" is matched to the supplier name. The relationship diagram for the nine tables is in `Data_Understanding_and_Business_Answers.docx` (Part 1).

## 4. Method

### Data cleaning (Part 2)
- Saved a raw copy of the workbook before making any change.
- Deleted an empty `Sheet1` and renamed the Customers sheet and table to match the other eight.
- Fixed the Suppliers table, whose header row was stored as the first data row (headers read "Column1" to "Column6").
- Checked all nine tables for fully duplicated rows: none found.
- Counted blank cells in every table: none found.
- Confirmed that date and money columns hold real dates and numbers using `COUNT` against the row count. The `Quantity` column in Order_Items was stored as text (a `SUM` returned 0) and was converted to numbers.
- Applied one consistent format to dates (`yyyy-mm-dd`) and to amounts (thousands separator).
- Recorded every check and its result in `Data_Quality_Log`.

### Formulas and lookups (Parts 3 and 4)
- The ten KPIs use `SUM`, `AVERAGE`, `MAX`, `MIN` and `COUNTA` on the table columns.
- `XLOOKUP` brings customer name, store name, product name, category, brand, catalogue selling price and supplier name into the Orders table.
- Helper columns were added so pivots can group by them: sales amount, order year and month, region, state, customer gender, membership level, store label and a returned flag (1 if the order appears in Returns).
- In Inventory: cost price, inventory value (stock on hand x cost price), store label and a low-stock flag (stock on hand at or below reorder level).

### Pivots, charts and dashboard (Parts 5 to 7)
- Seventeen pivot tables on the `Pivots` sheet. Ten are the ones Part 5 asks for: sales by month, store, category, brand, state, customer gender and membership level, plus top 10 products, bottom 10 products and top 10 customers. The other seven feed the charts, KPI cards and business questions: sales by region, return rate by category, a second sales-by-state pivot for the dashboard chart, the KPI-card pivot, returns by product, products per supplier and inventory by store.
- Six charts: monthly sales trend, revenue by category, revenue by store, top products, sales by region and return rate by category. Four are on the dashboard, and the Sales by Region and Return Rate by Category charts sit on the `Pivots` sheet beside their pivots. The dashboard also has a Sales by State chart.
- The dashboard has six KPI cards, five charts and six interactive filters (Year, Month, Region, Store, Category and Membership Level), all built as slicers connected to every pivot.
- Total Customers and Inventory Value do not change with the filters, because customers are counted from the Customers table and inventory is a stock snapshot not tied to order dates.

## 5. Definitions and assumptions

| Item | Definition used |
|---|---|
| Revenue | Sum of `Line_Total` in Order_Items, for **all** orders (Completed, Pending and Cancelled), because the brief gives no rule for order status |
| Currency | Nigerian naira (the data contains no currency symbol) |
| Average order value | Total revenue divided by the number of orders |
| Average selling price | Simple average of `Unit_Price` across order lines |
| Return rate | Unique returned orders divided by total orders (2,442 / 50,000 = 4.88%) |
| Inventory value | Stock on hand multiplied by **cost price** |
| Low stock | Stock on hand at or below the reorder level |
| State and Region | Taken from the store where the order was placed |
| Membership level | The `Customer_Segment` field (Bronze, Silver, Gold) |
| Store comparisons | By Store_ID, because the 25 stores share only 10 names |

## 6. Data quality issues found (not changed)

1. **Discount** values (0 to 20) look like percentages, but `Line_Total` subtracts them as flat amounts. Line_Total was used as supplied.
2. **Returns:** 1,252 returns are dated before their order date, 58 orders appear twice, and 1,685 of the 2,500 returns belong to Cancelled or Pending orders.
3. **Order status** is split almost evenly: 33.7% Cancelled, 33.2% Pending and 33.1% Completed.
4. **Unit_Price** in Orders does not match `Selling_Price` in Products, so catalogue margins are only a rough guide.
5. **Region labels** do not match the cities (the same city appears under different regions), so regional results should be confirmed with the client.
6. **Customers:** gender often does not match first names, and 49 email addresses are duplicated.
7. **Order_Items** repeats Orders one-to-one (50,000 rows each), so there are no multi-product orders.
8. All orders fall in 2025, so the Year filter has one value.

## 7. Key findings

1. **Sales are steady and evenly spread.** Monthly revenue ranges from ₦567M (February) to ₦661M (December). The best store (STR015, Lagos) is only 6% ahead of the weakest (STR023, Abuja). The top 10 products and top 10 customers make up 2.7% and 0.5% of revenue.
2. **Beauty leads on size, Electronics on momentum.** Beauty is the largest category (₦1.76B, 23.3%) mainly because it has the most products. Electronics grew fastest, has the highest average order value and a lower return rate than Beauty or Home.
3. **Only a third of orders are completed.** Without cancelled orders, revenue is about ₦5.02B, and only ₦2.50B is from completed orders.

The written answers to the ten business questions are in `Data_Understanding_and_Business_Answers.docx`, and the recommendations are in `Business_Report.pdf`.

## 8. Tools

Microsoft Excel: Excel Tables, `XLOOKUP`, pivot tables and pivot charts, slicers, `GETPIVOTDATA`, `COUNTIF`, `SUMPRODUCT`.

## 9. How to use the workbook

1. Open `ShopSmart_Analysis.xlsx` in Microsoft Excel (365 or 2021 for `XLOOKUP`).
2. Go to the `DASHBOARD` sheet.
3. Click the buttons in the slicers on the right to filter. Click the funnel icon with a cross to clear a filter.
4. If the numbers do not refresh, choose **Data > Refresh All**.

---

*Prepared for the AnalystLab Africa Experience Lab Internship Programme, October 2026.*
