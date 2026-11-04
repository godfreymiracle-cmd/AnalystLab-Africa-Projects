# Hospital Operations & Financial Intelligence Dashboard (Power BI)

**AnalystLab Africa Experience Lab Internship | Week 3 | Track A: Data Analytics**

Prepared by **Godfrey Miracle**, Junior Data Analyst

LinkedIn: https://www.linkedin.com/in/miracle-godfrey-815b60225/

A four-page Power BI dashboard built for the AnalystLab Africa Data Analytics track. It analyses one hospital's encounters, costs, payer coverage and procedures from January 2011 to early February 2022.

## Business questions

- How much activity does the hospital handle and how does it change over time?
- What mix of care does it provide and how long do encounters last?
- Who pays and how much of the cost is covered by payers?
- Which procedures are most frequent and which are most expensive?

## Dataset

The analysis used the AnalystLab Africa Week 3 hospital dataset: encounters (27,891 rows), patients (974), procedures (47,701), payers (10) and organizations (1), plus a data dictionary.

**The source files are not included in this repository**, because they hold patient-level records. Direct identifiers (names, addresses and similar fields) were removed in Power Query before loading, so they are not stored in the Power BI file either.

## Dashboard pages

| Page | What it shows |
|---|---|
| Overview | Total encounters, unique patients, claim cost, average claim cost, zero coverage %, over-24h %; encounters per year; encounter class mix |
| Encounter Patterns | Class share by year, long stays by encounter class, average and median duration, unique patients per quarter |
| Cost & Coverage | Payer coverage and coverage rate, zero coverage by payer, average claim cost by payer, total claim cost by encounter class |
| Procedures | Top 10 procedures by frequency and by average base cost (minimum 20 procedures) |

Screenshots are in the `Screenshots` folder.

## Key findings

- **Zero coverage:** 48.71% of encounters have no payer coverage. 8,807 are uninsured and a further 4,779 belong to an insurer that recorded none.
- **Payer share:** payers cover only 30.63% of total claim cost.
- **Duration:** the average encounter lasts 7.27 hours, but the median is 15 minutes. 75 encounters last over 24 hours, 58 of them inpatient.
- **Cost by class:** urgent care is 13.1% of encounters but 23.0% of claim cost.
- **Mix:** ambulatory care is 44.95% of encounters; inpatient is 4.07%.
- **Procedures:** the most frequent are routine screenings, while the most expensive are rare.

## Data quality

Questionable records were kept and flagged instead of deleted: 89 encounters with a zero claim cost, 75 very long stays, and 2022 being a partial year (220 encounters, 1 January to 5 February). Full details are in `Data_Quality_Assessment.pdf`.

## Validation

Five headline figures were recalculated from the raw CSV files in Excel and matched the Power BI values exactly, and seven slicer tests passed. See `Validation_Evidence.pdf`.

## Tools

Power BI, DAX, Power Query, Excel.

## Folder contents

```
README.md
Hospital_Operations_Analysis.pbix     Power BI dashboard (4 pages)
Project_Brief.pdf                     Business problem, success criteria, question analysis
Data_Quality_Assessment.pdf           Data quality findings and decisions
KPI_Definition_Sheet.pdf              KPI definitions and DAX measures
Executive_Summary.pdf                 Key findings and recommendations
Validation_Evidence.pdf               Independent checks and filter tests
screenshots/                          Dashboard pages and validation screenshots
```

## How to open

Download `Hospital_Operations_Analysis.pbix` from this folder and open it in Power BI Desktop.

Built as part of the AnalystLab Africa internship.
