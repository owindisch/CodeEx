# Assignment 2: Working from home in US census tracts (questions 1–4)

The code is in `analysis_wfh.R`. Every step has a beginner-level comment. Run it line by line in RStudio with Ctrl+Enter.
The numbers to report (marked **[fill in]**) come from your own console output, because each group has a different state.

---

## Q1: Loading, strange values and empty tracts

**What the code does**
1. `read.csv()` loads the data. `dim()`, `str()` and `summary()` show its size, the variable types and the ranges.
2. It counts, for every column, the values below −100,000,000, and `table()` shows which codes occur.
3. It replaces those codes with `NA` (R's code for a missing value).
4. It checks the population variable and drops tracts with 0 or fewer than 100 inhabitants, plus tracts where `pct_wfh` is missing.

**Explanation for the report**
The Census Bureau API uses *annotation values* when it cannot publish an estimate
([documentation](https://www.census.gov/data/developers/data-sets/acs-1year/notes-on-acs-estimate-and-annotation-values.html)):

| Code | Meaning |
|---|---|
| −666666666 | Estimate could not be computed: too few sample observations (e.g. median house value in a tract with almost no owner-occupied homes) |
| −999999999 | Too few sample cases to display the estimate or margin of error |
| −888888888 | Not applicable / not available |
| −555555555 | Estimate is controlled; margin of error not appropriate |
| −333333333 | Median falls in the open-ended lowest or highest interval |
| −222222222 | Margin of error could not be computed |

These are labels, not measurements. A median income of −$666 million is impossible, and a single such value would dominate every mean, plot and regression. Treating it as 0 would be just as wrong, because the true value is unknown, not zero. So we set the codes to **missing (NA)**. Tracts with an NA in a variable will drop out of a regression that uses that variable.

**Uninhabited or tiny tracts.** Some tracts have 0 inhabitants (water, parks, airports, industrial land). There `pct_wfh` is undefined, and these areas are not residential customers. Tracts with only a few dozen inhabitants (prisons, military bases, dorms) rest on a handful of survey responses, so their percentages swing wildly: 1 home worker out of 3 workers is already 33%. We drop tracts with **fewer than 100 inhabitants**.
Report: start **[fill in]**, removed **[fill in]**, remaining **[fill in]**.

---

## Q2: Median home value and median household income

The histograms show a spike at the very top. Many tracts share exactly the same maximum:
`med_value = 2,000,001` and `med_hh_income = 250,001`.

**Why:** the ACS **top-codes** medians. A value above \$2,000,000 is published as "2,000,000+", which the API returns as 2000001. An income above \$250,000 is published as "250,000+" (250001). There are also bottom codes ("9,999−" for value and "2,499−" for income). So these tracts are not *equal*: we only know their value is *at least* the cap. The variable is **censored**.

**Consequences for prediction:** in the richest tracts the predictor is flat while the true value (and possibly `pct_wfh`) keeps rising. This adds measurement error at the top and can bias the estimated slope. The model cannot tell a \$2.1m neighbourhood from a \$6m one.

**Our choice:** we keep these tracts. Dropping them would remove the rich, high-WFH neighbourhoods, which matter for the company. We keep the capped value and add a **dummy** (`topcode_value`, `topcode_income` = 1 if top-coded). The dummy absorbs the average difference of the censored group, so the slope is driven by the uncensored tracts. We also use the **log** of both variables because they are strongly right-skewed.
(Alternatives you could mention: dropping the tracts, which loses information and adds selection bias; or a Tobit model, which is more complex.)

---

## Q3: Exploratory analysis

The code computes the Pearson and Spearman (rank) correlation of `pct_wfh` with every numeric variable. It saves them sorted to `figures/correlations_with_pct_wfh.csv`. It then makes:
- `figures/scatter_main.png` with four theory-driven variables for the main text (income, education, occupation, travel time),
- `figures/appendix_scatter_*.png` with all variables, 9 per page, for the appendix.

Each scatter plot has a red linear fit and a blue smooth (lowess) curve. Where the two differ, the relation is non-linear.

**What to discuss** (check it against your own output):
- Education (share with a bachelor's degree or more), income and office/management/professional occupations are expected to be the **strongest positive** correlates. These are jobs that can be done remotely.
- Shares in service, production, construction and transport occupations, and in lower-income tracts, are expected to be **negative**. These jobs require being on site.
- Look at the shape: income often shows a curved (log-like) relation, and the top-coded tracts show up as a vertical stripe at the right.
- Correlation is not causation. Many predictors are strongly correlated with *each other* (education, income, occupation, home value). This matters later for multicollinearity in the regression.
- Pearson and Spearman differ when there are outliers or skewed variables. Spearman is more robust there.

---

## Q4: Shares of commuters vs. shares of all workers

Every worker falls in exactly one "means of transportation to work" category:
drive alone + carpool + public transport + walk/bike/other + **work from home** = 100% of workers.

If `pct_drive_alone` and `pct_public_transport` were shares of **all workers**, they would be linked to `pct_wfh` by an **accounting identity**. Each extra point of WFH must remove a point from the commuting modes. A regression would then find a strong negative "effect" that is purely mechanical: it reflects how the variable is defined, not neighbourhood behaviour. The model would essentially be predicting WFH with the parts of 100 − WFH. That is circular, and it is useless for forecasting because the predictor is unknown unless you already know WFH. Expressing them as shares of **commuters** (workers who do *not* work from home) removes the identity. They then describe *how* the people who do commute travel.
The script shows this. It converts the share of commuters into a share of all workers (`× (100 − pct_wfh)/100`) and compares the correlations and plots (`figures/q4_commuters_vs_allworkers.png`).

**Other variables that may be mechanically related to `pct_wfh`** (check which ones are in your description file):
- **Mean travel time to work** and **departure-time** variables: they are only measured for commuters, so home workers are left out. This is not an identity, but the variable is computed on a different and selected group.
- **Place of work (e.g. % working in county/state of residence):** home workers are counted as working where they live, so more WFH mechanically raises this share.
- **Vehicles available / no-vehicle households**: not an identity, but it is closely tied to commuting choice, and it may be a consequence rather than a cause.
- **Number of workers / labour force variables** are the *denominator* of `pct_wfh`. They are not an identity, but sampling noise in the denominator affects both sides.
- Any variable that itself has "workers" as denominator and includes home workers in one of its categories.
