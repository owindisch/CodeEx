# Assignment 2: Working from home in Massachusetts census tracts (group 18)

**Data:** `a2_data_group_18.csv`: ACS 5-year estimates 2020–2024, 1,620 census tracts, all in Massachusetts.
**Code:** `analysis_wfh.R` (tidyverse + ggplot2; install once with `install.packages("tidyverse")`). Every step has a beginner-level comment, including how the pipe `|>` and ggplot's `+` layers work. Run it in RStudio line by line (Ctrl+Enter).
All numbers below were produced by that script. The full console output is in `figures_log.txt`, and the figures are in `figures/`.

### Sources (U.S. Census Bureau)

| # | Document | Used for |
|---|---|---|
| [S1] | [ACS 5-Year Data API page](https://www.census.gov/data/developers/data-sets/acs-5year.html) | The data product, with links to the notes below |
| [S2] | [Notes on ACS Estimate and Annotation Values](https://www.census.gov/data/developers/data-sets/acs-1year/notes-on-acs-estimate-and-annotation-values.html) | Meaning of −666666666 etc., and of "250,000+" / "+" / "−" for medians |
| [S3] | [Notes on ACS API Variable Types](https://www.census.gov/data/developers/data-sets/acs-1year/notes-on-acs-api-variable-types.html) | Estimate (E) vs. estimate-annotation (EA) variables |
| [S4] | [Notes on ACS Data](https://www.census.gov/data/developers/data-sets/acs-1year/data-notes.html) | Medians in open-ended intervals |
| [S5] | [ACS Subject Definitions](https://www.census.gov/programs-surveys/acs/technical-documentation/subject-definitions.html) | Definitions of journey-to-work, travel time and income |
| [S6] | [Commuting – guidance for data users](https://www.census.gov/topics/employment/commuting/guidance/commuting.html) | Means of transportation, "worked from home" |
| [S7] | [Geography Program glossary (census tract)](https://www.census.gov/programs-surveys/geography/about/glossary.html) | Tract size 1,200–8,000, special land-use and water tracts |
| [S8] | [Understanding and Using ACS Data – General Handbook (2020)](https://www.census.gov/content/dam/Census/library/publications/2020/acs/acs_general_handbook_2020.pdf) | Sampling error, small areas, 5-year estimates |

> Note: census.gov was blocked from the computer this was prepared on. The quotes below come from the Census pages as indexed by a web search. Open the links once to check the wording before you hand in.

---

## Question 1: Load, inspect, special values and (almost) empty tracts

### 1.1 What the code does

| Step | R code | What it does |
|---|---|---|
| Load | `read_csv(data_file, col_types = cols(geoid = col_character()))` | Reads the table. `geoid` is kept as text (the description file asks for this). |
| Inspect | `dim()`, `glimpse()`, `summary()` | Size, variable names, types and ranges. |
| Find codes | `df \|> summarise(across(where(is.numeric), ~ sum(.x < -1e8, na.rm = TRUE)))` | Counts, per column, the values below −100 million. No real estimate can be that negative. |
| Replace | `df \|> mutate(across(where(is.numeric), ~ if_else(.x < -1e8, NA, .x)))` | Turns each code into `NA` (missing). |
| Small tracts | `df \|> arrange(pop) \|> head(30)` | Lists the smallest tracts. `str_sub(geoid, 6, 7)` shows the tract-code prefix (98/99). |
| Filter | `df \|> filter(pop >= 300, !is.na(pct_wfh))` | Keeps tracts with ≥ 300 inhabitants and a non-missing `pct_wfh`. |

### 1.2 What we found

- **1,620 tracts and 39 variables.** The description file also lists a variable `workers`, but this column is **not** in our data file, so we use `pop` for cleaning.
- The only special code that occurs is **−666666666**, **358 times**, and only in the variables the description file marks as "may contain special codes":

  | Variable | # codes | Variable | # codes |
  |---|---|---|---|
  | med_rent | 124 | gini | 29 |
  | med_value | 65 | med_year_built | 29 |
  | med_hh_income | 35 | med_rooms | 29 |
  | hh_size | 27 | med_age | 20 |

- The percentage variables have no codes. Instead they are already `NA` in 18–26 tracts, mainly the empty ones.

### 1.3 What −666666666 means, and why we set it to NA

The Census Bureau API returns special *annotation values* when it cannot publish a real estimate [S2, S3]:

| Value | Meaning according to the Census Bureau [S2] |
|---|---|
| **−666666666** | "The estimate could not be computed because there were an insufficient number of sample observations." In tables this is shown as "-". For a **median**, it also means the median could not be calculated, for example because there are no or too few cases in the distribution. |
| −999999999 | The estimate or margin of error cannot be displayed because there were too few sample cases in the area. |
| −888888888 | Estimate or margin of error not applicable or not available. |
| −555555555 | The estimate is controlled; a statistical test / margin of error is not appropriate. |
| −222222222 | The margin of error could not be computed (too few sample observations). |

[S3] adds that when an *estimate annotation* exists, it should be used **in place of** the estimate. In other words, the number itself is not a value.

**Our choice: set the codes to `NA`.** Three reasons:
1. **They are not measurements.** A median income of −\$666,666,666 or a median age of −666 million years is impossible. The code is a label meaning "unknown".
2. **Keeping them would destroy every statistic.** In a sample of 1,000 tracts, one code lowers the mean of `med_hh_income` by about \$670,000. It would dominate any correlation or regression, and the histograms would be useless.
3. **Replacing them by 0 or by the mean would also be wrong.** The true value is *unknown*, not zero. Inventing a value creates false precision. `NA` is honest: R leaves those tracts out of each correlation (`use = "complete.obs"`), and `lm()` drops them automatically.

Why the codes occur is itself informative. A median rent can only be computed when there are enough renting households in the sample, and a median house value only with enough owner-occupied homes. So the 98 codes left in `med_rent` after cleaning are mostly in tracts with very few renters (suburbs with almost only owners). This missingness is **not random**, which matters if we later put `med_rent` in a regression: we would lose ~6% of tracts, and not a random 6%. We decide on each variable when we build the model.

### 1.4 Tracts with no or very few inhabitants

| Population | # tracts |
|---|---|
| exactly 0 | 18 |
| < 100 | 26 |
| < 300 | 27 |
| < 1,200 | 40 |

The smallest tracts are clearly not normal neighbourhoods:
- Almost all have a tract code starting with **98** or **99**. The Census Bureau reserves **9800–9899** for *special land-use tracts* "that contained little or no population and represented a relatively large special land use area such as a National Park, military installation, or a business/industrial park", and **9900–9998** for tracts "that contained only water area, no land area" [S7].
- In our data these are mainly Suffolk County (Boston) 98xx tracts, such as the harbour islands and the airport area, and the coastal water tracts (99xx) of the coastal counties.

**Our choice: drop tracts with fewer than 300 inhabitants.** This removes **27 tracts** and leaves **1,593 tracts**.
- **0 inhabitants (18 tracts):** there are no workers, so `pct_wfh` is undefined (it is `NA` in all of them), and the company has no homes to serve there.
- **1–299 inhabitants (9 tracts):** `pct_wfh` rests on only a handful of survey responses. the ACS samples only a few percent of addresses per year, roughly 1 in 8 over five years [S8], so a tract of 30 people has maybe 3–5 respondents. This shows in the data: `pct_wfh` is exactly 0% or 100% in five of them, and 69% or 58% in others. These are sampling accidents, not neighbourhood characteristics. For the same reason most of their medians are −666666666.
- **Why 300:** the data has a clear gap. The largest of these tiny tracts has 202 inhabitants and the next tract has 453. Every tract below 300 is a 98xx or 99xx special-use or water tract, except three tracts with 0 inhabitants (one in Boston, two in Middlesex County). Above the gap, tracts look like real neighbourhoods, though small. The Census guideline for a tract is 1,200–8,000 inhabitants with an optimum of 4,000 [S7]. We do **not** use 1,200 as the cut-off: that would also drop 13 real residential tracts (e.g. on Nantucket or in Boston) with valid estimates.
- The one tract with 94 inhabitants also has a missing `pct_wfh`, so it would be dropped anyway.

**Result: 1,593 tracts remain.** Some independent variables still contain a few NA's (e.g. `med_rent` 98, `med_value` 39, `med_hh_income` 9). We keep these tracts now and only drop them in models that use those variables.

---

## Question 2: Median home value and median household income

### 2.1 What we see

`figures/hist_med_value_income.png` shows both variables: strongly right-skewed, with a spike in the very last bin.

| | Maximum | # tracts exactly at the maximum | Next most frequent value |
|---|---|---|---|
| `med_value` | **2,000,001** | **11** | 600,000 (4 tracts) |
| `med_hh_income` | **250,001** | **30** | 116,250 (3 tracts) |

Two medians, each computed from hundreds of households, are almost never exactly equal. Thirty tracts with *exactly* \$250,001 cannot be a coincidence. The "1" at the end gives it away.

### 2.2 Why: top-coding

The ACS publishes medians from **grouped (interval) distributions**, and the highest interval is **open-ended**. If a tract's median falls in that top interval, the Census Bureau does not publish a number. It publishes the lower bound followed by a "+" sign [S2, S4]:
- "250,000+" means "the median falls in the highest interval of an open-ended distribution" [S2]. In the API (and our file) this is returned as **250001**.
- Median home value is top-coded at "2,000,000+", returned as **2000001**.
- In the same way, a "−" after a median means the lowest interval (e.g. "2,499−" for income, "9,999−" for value). The margin of error then shows "***": "the median falls in the lowest interval or upper interval of an open-ended distribution. A statistical test is not appropriate" [S2, S4].

So the 30 tracts are not equally rich. We only know their median income is **at least** \$250,000. The real value could be \$260,000 or \$600,000. Statistically the variable is **right-censored**.

The same problem appears in other medians in our data (`for` loop in the script):

| Variable | Code | # tracts | Meaning |
|---|---|---|---|
| `med_rent` | 3501 | 22 | "3,500+" (top-coded) |
| `med_year_built` | 1938 | **389** | "1939 or earlier" (bottom-coded): about a quarter of Massachusetts tracts are old town centres |
| `med_rooms` | 10 | 13 | top category of rooms (the open-ended "9 or more rooms" interval) |

### 2.3 Consequences when used as predictors

1. **Measurement error at the top.** For the richest tracts the predictor is too low and is constant within the group, while `pct_wfh` keeps varying. These tracts have a much higher average WFH (32.8% for top-coded income vs. 17.9% for the rest; 29.1% vs. 18.1% for value).
2. **A biased slope.** The capped tracts pile up at one x-value with high y-values, so a linear model gets the wrong slope. It typically overstates the slope near the top, because the steep jump looks like a small change in x. It also gets the shape wrong: there is no information about how WFH changes above the cap.
3. **No extrapolation.** The model cannot say anything about tracts above \$250k or \$2m. It can only say they belong to the top group.
4. **Ties are not real.** Any method that relies on ranks or exact values (e.g. Spearman, quantiles) treats the 30 tracts as equal when they are not.

### 2.4 Our choice

We **keep** the top-coded tracts, keep the capped value, and add an **indicator (dummy) variable**:

```r
df <- df |>
  mutate(topcode_income = as.numeric(med_hh_income >= 250001),   # 1 if "250,000+"
         topcode_value  = as.numeric(med_value     >= 2000001))  # 1 if "2,000,000+"
```

Why:
- **Not dropping:** 30 + 11 tracts are the wealthiest, highest-WFH neighbourhoods, such as the suburbs west of Boston. Dropping them removes exactly the part of the distribution the company is most interested in (high daytime home electricity use). It would also make the sample non-random (selection on the predictor).
- **Dummy:** in a regression, the dummy gets its own coefficient. It captures how much higher WFH is in the "250,000+" group, and the slope of the continuous variable is then estimated mainly from the uncensored tracts. It is simple, transparent and easy to explain to a beginner audience.
- **Log transformation:** both variables are right-skewed, and the scatter plot shows that `pct_wfh` rises roughly linearly in log income. So we use `log_med_hh_income` and `log_med_value`.
- **Alternatives considered:** a censored-regression (Tobit-type) model for the predictor, or imputing a value above the cap (e.g. using a Pareto tail). These are more correct but much more complex, and the gain is small with only 2% of tracts affected.
- The same dummy approach is used for `med_rent` (`topcode_rent`) and `med_year_built` (`built_pre1939`).

---

## Question 3: Exploratory analysis

### 3.1 What the code does
- Histogram of `pct_wfh` (`figures/hist_pct_wfh.png`).
- Pearson (linear) and Spearman (rank) correlations of `pct_wfh` with **all** numeric predictors, sorted (`figures/correlations_with_pct_wfh.csv`), also shown as a bar chart (`figures/correlations_bar.png`).
- Six scatter plots for the main text (`figures/scatter_main.png`) and all variables, 9 per page, for the appendix (`figures/appendix_scatter_1.png` … `_5.png`). Red line = linear fit; blue curve = a flexible smooth curve (GAM, ggplot2's default smoother for large data), which reveals non-linearity.

### 3.2 The dependent variable
After cleaning, `pct_wfh` ranges from **0% to 52.4%**, with a median of **17.3%** and a mean of **18.2%**. The middle 50% of tracts lie between 10.2% and 25.0%. So on average about one in five workers worked from home in the survey week, and the differences between neighbourhoods are very large: the 5th percentile is 4.2% and the 95th is 35.3%.

### 3.3 Correlations with pct_wfh (n = 1,593, Massachusetts)

| Strongest positive | r (Pearson) | ρ (Spearman) | Strongest negative | r | ρ |
|---|---|---|---|---|---|
| pct_bachelor_plus | **0.81** | 0.82 | pct_hs | **−0.73** | −0.75 |
| occ_mgmt_sci | **0.80** | 0.81 | occ_production | −0.64 | −0.70 |
| log_med_value | 0.68 | 0.70 | occ_service | −0.60 | −0.65 |
| med_hh_income | 0.66 | 0.66 | pct_some_college | −0.58 | −0.57 |
| log_med_hh_income | 0.63 | 0.66 | pct_lt_hs | −0.56 | −0.62 |
| med_rent | 0.54 | 0.53 | pct_snap | −0.55 | −0.61 |
| pct_broadband | 0.41 | 0.44 | occ_constr_maint | −0.52 | −0.55 |
| pct_transit | 0.26 | 0.33 | pct_poverty | −0.35 | −0.41 |
| lfp_rate | 0.24 | 0.22 | occ_sales_office | −0.33 | −0.33 |

Weak (|r| < 0.15): age structure (`med_age`, `pct_65plus`), housing type (`pct_detached`, `pct_large_bldg`), `gini`, `pct_vacant`, `pct_foreign`, `pct_no_vehicle`, `pop`.

### 3.4 Discussion

1. **Education and occupation dominate.** Tracts where many adults hold a bachelor's degree and where many people work in management, business, science and arts occupations have far more home workers (r ≈ 0.8). This fits the idea of *teleworkable jobs*: office and knowledge work can be done remotely, while service, production, construction and transport work cannot (all strongly negative). The scatter plots show an almost **linear** relation for education and the management/science occupation share, which only flattens a little in the very highest-educated tracts (above ~85%).
2. **Income and wealth** (income, home value, rent) are also strongly positive. The relation with income is **convex**: the smooth curve is flat at low incomes and steep at high incomes, even in logs. Part of this is probably education/occupation again, since high-income tracts are highly educated. The top-coded tracts form a vertical stripe at the right edge of the income and value plots (see Q2).
3. **Poverty and SNAP** are negative, which is the mirror image of point 2.
4. **Production occupations** (r = −0.64) fall steeply from 0% to ~15% and then level off at around 7–9% WFH: the relation is clearly non-linear.
5. **Broadband** (r = 0.41) is positive and convex: WFH really only takes off when more than ~90% of households have broadband. The direction of causality is unclear. Broadband makes WFH possible, but home workers also buy broadband.
6. **Commuting variables are weak.** `pct_transit` is mildly positive, because Boston-area tracts with good transit also have many office workers. `mean_commute` is weak (0.16) and hump-shaped: tracts with very short and very long commutes both have less WFH. These variables are measured only among *commuters*, so they need care (see Q4).
7. **Demography and housing type matter little on their own.** Age, household size, detached houses and large buildings are only weakly correlated. They may still matter *after* controlling for education (partial effects); this needs the regression.
8. **Pearson vs. Spearman.** They are close for most variables. Spearman is clearly stronger for skewed variables (`pct_snap`, `pct_poverty`, `pct_no_vehicle`, `med_value`), which points to non-linear but monotone relations and suggests logs or other transformations.
9. **Strong correlation between predictors.** Education, occupation, income and home value are strongly correlated with each other (multicollinearity). Their individual regression coefficients will be imprecise, and the correlations above **must not be read as causal effects**. They show association only.
10. **Time caveat.** The 5-year estimates pool interviews from 2020 (peak of the pandemic) to 2024 [S1, S8]. A tract's `pct_wfh` is an average over this period, so differences in the timing of interviews add noise.

---

## Question 4: Commute shares as shares of commuters vs. of all workers

### 4.1 The accounting identity

The ACS asks every worker how they usually got to work in the reference week. *Worked from home* is one of the answer categories, next to car, public transport, walking and so on [S5, S6]. Every worker falls into **exactly one** category, so for every tract:

> drove alone + carpooled + public transport + walked + bicycle/taxi/other + **worked from home** = 100% of workers

If `pct_drive_alone` and `pct_transit` were percentages of **all workers**, then

> pct_drive_alone(all) = (100 − pct_wfh) × pct_drive_alone(commuters) / 100

and the commuting shares would **mechanically** go down when `pct_wfh` goes up.

### 4.2 Why that is a problem

1. **Circular regression.** Part of the dependent variable would sit inside the predictor. A regression of `pct_wfh` on "share of all workers who drive alone" would find a strong negative coefficient and a high R², but it would partly just recover the identity `100 − pct_wfh − …`. It would say nothing about *which neighbourhoods* have more home workers.
2. **Useless for prediction.** To forecast WFH in a new area, you would need to know the share of all workers who drive, and that already depends on how many work from home.
3. **Wrong interpretation.** The coefficient would mix "where people drive" with "how many people do not commute at all".

Using **commuters** (workers *not* working from home) as the denominator removes this identity. The variable then describes *how those who travel* get to work, which is a characteristic of the neighbourhood (car dependence, transit access).

**Our data shows the size of the problem** (script, Q4 part, `figures/q4_commuters_vs_allworkers.png`):

| `pct_drive_alone` measured as … | correlation with `pct_wfh` |
|---|---|
| % of commuters (as in our data) | **−0.19** |
| % of all workers (re-computed) | **−0.54** |

Almost three times as strong, and the extra part is purely mechanical.

### 4.3 Other variables that are (partly) mechanically related to `pct_wfh`

| Variable | Relation | Why |
|---|---|---|
| **mean_commute** | Mechanical selection | The Census Bureau computes mean travel time by dividing the total minutes of travel "by the number of workers 16 years old and over who did not work at home" [S5]. Home workers are excluded by definition. If people with long commutes are the most likely to switch to WFH, the remaining commuters have shorter trips. So `mean_commute` changes *because* of WFH, not the other way round. This is a likely reason for the hump in the scatter plot. |
| **pct_drive_alone, pct_transit** (even as shares of commuters) | Weaker selection effect | The *composition* of the remaining commuters changes with WFH. If office workers who used to take the train now work from home, the transit share among the remaining commuters falls. No identity, but not fully independent. |
| **workers** (in the description, not in our file) | Denominator of `pct_wfh` | The description file says so: "use for cleaning and weighting, not as predictor". |
| **occ_* (occupation shares)** | Strong conceptual overlap, not an identity | The shares are of all employed people, including home workers. "Management, business, science and arts" is close to the definition of teleworkable work, so it partly measures the *ability* to work from home. That is a legitimate predictor, but expect it to be by far the strongest one. |
| **lfp_rate, unemp_rate** | Not mechanical | Different universe (population 16+, labour force); people out of work are not in `pct_wfh` at all. |
| **pct_no_vehicle** | Not mechanical, but possible reverse causality | Households that work from home may give up a car. |
| **pct_broadband** | Not mechanical, but reverse causality | Home workers need broadband, so WFH raises the broadband share. |

**Conclusion for the modelling:** use the commuting variables only as shares of commuters (as provided). Be cautious with `mean_commute` and the commute-mode shares, because they are partly *outcomes* of WFH. In a model meant to explain WFH, we would leave them out or at least show results with and without them. Never use `workers` as a predictor.
