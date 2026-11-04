# Hospital Operations & Financial Intelligence Dashboard

**AnalystLab Africa | Data Analytics Internship | Week 3: Healthcare Operations & Financial Intelligence (Track A)**

An interactive Power BI dashboard that shows hospital managers how activity, cost and payer coverage have changed, where cost is concentrated and where to act.

## Business problem

The hospital records every encounter, what it cost, who paid and which procedures were done, but managers have no single view of where activity is changing, where cost is concentrated and how much of it payers actually cover. The data shows payers cover only 30.63% of the 101.51M in claim cost, and 48.71% of encounters have no payer coverage at all. Gaps like these decide how much cost the hospital must recover from patients or absorb.

## Dataset

- **Source:** the AnalystLab Africa Week 3 hospital dataset supplied with the assignment pack. The raw files are not redistributed in this repository because they hold patient-level records.
- **Size:** 27,891 encounters, 974 patients, 47,701 procedures, 10 payers and 1 organization, plus a data dictionary.
- **Coverage:** one hospital, 2 January 2011 to 5 February 2022; 6 encounter classes (ambulatory, outpatient, urgent care, emergency, wellness, inpatient), 163 procedure types, and an adult-only patient population.

## Tools

Microsoft Power BI Desktop (Power Query, DAX, report design) and Microsoft Excel (independent validation).

## Data preparation (Power Query)

1. Loaded the five CSV files (encounters, patients, procedures, payers, organizations). The data dictionary was used for reference only.
2. Checked keys and duplicates: no orphan patient, payer, organization or encounter keys, and no duplicate rows.
3. Converted `START` and `STOP` from UTC text timestamps to date-times and derived a `StartDate` column.
4. Set data types, with cost and coverage columns as decimals.
5. Added `DurationHours` (stop minus start) and the flags `Over24h`, `ZeroCoverage` and `CostIssueFlag`, plus a `DurationBand` column for charting.
6. In patients, kept only 10 non-identifying columns. Names, addresses and other identifiers were removed before loading.
7. In procedures, kept `ENCOUNTER`, `CODE`, `DESCRIPTION` and `BASE_COST`.
8. Checked missing values. `REASONCODE` is blank for 70.1% of encounters and was left blank because reasons are not analysed.
9. Flagged unusual records instead of deleting them: 89 encounters with a zero claim cost and 75 encounters longer than 24 hours. 2022 is a partial year (220 encounters).

Full details are in `Data_Quality_Assessment.pdf`.

## Data model and calculations

- A `DateTable` (2011 to 2022) with Year, Quarter, Month and YearQuarter columns, related one-to-many to `encounters[StartDate]`.
- `patients`, `payers` and `organizations` relate one-to-many to `encounters`, and `encounters` relates one-to-many to `procedures`.
- Measures:

```
Total Encounters           = COUNTROWS(encounters)
Unique Patients            = DISTINCTCOUNT(encounters[PATIENT])
Total Claim Cost           = SUM(encounters[TOTAL_CLAIM_COST])
Avg Claim Cost             = AVERAGE(encounters[TOTAL_CLAIM_COST])
Total Payer Coverage       = SUM(encounters[PAYER_COVERAGE])
Coverage Rate              = DIVIDE([Total Payer Coverage], [Total Claim Cost])
Zero Coverage Encounters   = SUM(encounters[ZeroCoverage])
Zero Coverage %            = DIVIDE([Zero Coverage Encounters], [Total Encounters])
Over 24h Encounters        = SUM(encounters[Over24h])
Over 24h %                 = DIVIDE([Over 24h Encounters], [Total Encounters])
Avg Duration Hours         = AVERAGE(encounters[DurationHours])
Median Duration Hours      = MEDIAN(encounters[DurationHours])
Zero Cost Encounters       = SUM(encounters[CostIssueFlag])
Procedure Count            = COUNTROWS(procedures)
Avg Procedure Base Cost    = AVERAGE(procedures[BASE_COST])
Avg Base Cost (min 20)     = IF([Procedure Count] >= 20, [Avg Procedure Base Cost])
```

`Unique Patients` counts distinct patients in the encounters being viewed. `Avg Base Cost (min 20)` hides procedures with fewer than 20 records, so rare procedures do not top the ranking. The mean duration is distorted by a few very long records, so the median is shown beside it. Every KPI is defined in `KPI_Definition_Sheet.pdf`.

## Dashboard pages

| Page | What it shows |
|---|---|
| Overview | 6 KPI cards (encounters, unique patients, total and average claim cost, zero coverage %, over-24h %), encounters per year, encounter class mix, year and encounter class slicers |
| Encounter Patterns | Over-24h encounters and %, average and median duration, class share by year, long stays by encounter class, unique patients per quarter |
| Cost & Coverage | Payer coverage, coverage rate, zero coverage % and zero-cost encounters, average claim cost by payer, zero coverage by payer, total claim cost by encounter class |
| Procedures | Procedure count, procedure types, average base cost, encounters with procedures, top 10 procedures by frequency, top 10 by average base cost (minimum 20 records) |

## Dashboard preview

![Overview](Screenshots/1_overview.png)
![Encounter Patterns](Screenshots/2_encounter_patterns.png)
![Cost & Coverage](Screenshots/3_cost_and_coverage.png)
![Procedures](Screenshots/4_procedures.png)

## Key findings

- Yearly encounters held between 2,228 and 2,519 from 2015 to 2020, with surges of 3,885 in 2014 and 3,530 in 2021. The 220 encounters in 2022 cover only five weeks.
- Ambulatory (44.95%) and outpatient (22.59%) care make up about two thirds of encounters. Inpatient is only 4.07%.
- Payers cover 30.63% of total claim cost, leaving 70.4M (69.4%) uncovered.
- 48.71% of encounters have zero payer coverage: 8,807 are uninsured (49.3M, 48.5% of cost) and 4,779 belong to an insurer that recorded none (13.8M).
- Urgent care is 13.1% of encounters but 23.0% of cost, averaging 6,369 per encounter against 2,894 for ambulatory.
- The average encounter lasts 7.27 hours but the median is 15 minutes. 75 encounters exceed 24 hours, 58 of them inpatient (5.11% of inpatient encounters).
- Medicaid has the highest average claim cost (6,205) and Dual Eligible the lowest (1,696).
- The most frequent procedures are routine screenings and assessments. The most expensive, such as hemodialysis (average about 29,300), are rare.

## Recommendations

1. Audit the 4,779 insured encounters with zero coverage to separate denied claims from recording gaps.
2. Screen uninsured patients for eligibility for coverage programmes and financial assistance.
3. Review the drivers of urgent care cost, including charge patterns and procedure mix.
4. Validate the 75 long-duration records and report median duration beside the mean.
5. Make reason codes and claim cost mandatory at data entry.

Each recommendation, with its evidence and limits, is in `Executive_Summary.pdf`.

## Validation

Five headline figures (total encounters, total claim cost, zero-coverage count and percentage, and over-24h count) were recalculated from the raw CSV files in Excel and matched the Power BI values exactly. Seven slicer tests passed, including across pages. See `Validation_Evidence.pdf`.

## Assumptions and limitations

- The dataset does not state a currency, so costs are shown as plain numbers.
- The data covers one hospital and an adult-only population, so results should not be generalised.
- 2022 is a partial year and its figures are provisional.
- Zero coverage for an insured patient is unexplained in the data. It may reflect denials, pending claims or missing records.
- Uncovered cost is the claim amount payers did not pay. It is not the same as lost revenue.
- The 89 zero-cost and 75 long-duration encounters were kept and flagged, not removed.
- Only 52.6% of encounters have procedure records.
- The minimum of 20 records in the procedure cost ranking is a judgement. Hemodialysis clears it with 27 records and would drop out at 50.
- Readmissions were not analysed, because no field defines one.

## Folder contents

```
Week3_Godfrey_Miracle/
├── README.md                          This file
├── Hospital_Operations_Analysis.pbix  Power BI project file
├── Power BI dashboard.pdf             Dashboard export (all pages)
├── Project_Brief.pdf                  Business problem, success criteria, question analysis
├── Data_Quality_Assessment.pdf        Data quality findings and decisions
├── KPI_Definition_Sheet.pdf           KPI definitions and DAX measures
├── Executive_Summary.pdf              Findings, recommendations and limits
├── Validation_Evidence.pdf            Independent checks and filter tests
└── Screenshots/                       Dashboard page and validation images
```

Back to the [main projects page](../README.md).

## Author

**Godfrey Miracle** | Data Analytics Intern, AnalystLab Africa
LinkedIn: <https://www.linkedin.com/in/miracle-godfrey-815b60225/>
GitHub: <https://github.com/godfreymiracle-cmd>

#AnalystLabAfrica
