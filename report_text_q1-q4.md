# Working from Home in Massachusetts Neighbourhoods
### Assignment 2 – Questions 1–4 (Group 18)

---

## Introduction

Since the COVID-19 pandemic, many American workers do part or all of their work from home. This shifts daytime electricity demand from offices to residential neighbourhoods. We use the American Community Survey (ACS) 5-year estimates for 2020–2024 [1]. By pooling five years of responses, they provide reliable statistics for small areas such as census tracts [2, 8]. Census tracts are small statistical subdivisions of a county with generally 1,200 to 8,000 inhabitants [7]. Our data cover all tracts in Massachusetts. The dependent variable, `pct_wfh`, is the percentage of workers aged 16+ who worked from home in the week before the survey.

---

## Question 1 – Inspecting and cleaning the data

The raw data contain **1,620 census tracts** and **39 variables**. The summary statistics show that several variables take the value **−666,666,666**, which cannot be a real value: no tract has a negative median income or median age. This value occurs **358 times**, only in the eight variables that the description marks as "may contain special codes": median rent (124), median home value (65), median household income (35), Gini index, median rooms and median year built (29 each), household size (27) and median age (20).

According to the Census Bureau, such numbers are **annotation values**, which are published instead of an estimate. The value −666,666,666 means that *"the estimate could not be computed because there were an insufficient number of sample observations"* [3]. For a median this happens when a tract has too few cases in the underlying distribution, for example no renters for median rent. The documentation also states that an annotation should be used *in place of* the estimate [4]. The number therefore carries no quantitative information. We recode it as **missing (NA)**. Keeping it would dominate every mean, correlation and regression, since a single code lowers the mean of a variable by about 400,000 in our sample. Replacing it by zero or the mean would invent information that does not exist.

Next, we examined tract populations. **Eighteen tracts have no inhabitants**, and **nine have only 3 to 202**. Almost all of them have codes in the 9800 range, which the Census Bureau uses for *special land-use tracts* with little or no population (parks, airports, industrial areas), or the 9900 range, used for *water-only* tracts [7]. In our data these include the Boston Harbor islands, the airport area and coastal waters. For empty tracts `pct_wfh` cannot be computed. For the tiny tracts it rests on only a handful of survey responses, as the ACS samples only a few percent of addresses per year [8]. This shows in the data: `pct_wfh` is exactly 0% or 100% in five of the nine small tracts, which is sampling noise rather than a real neighbourhood characteristic.

Because there is a clear gap in the population distribution between 202 and 453 inhabitants, we **remove all tracts with fewer than 300 inhabitants**, along with tracts with a missing `pct_wfh`. We do not use the 1,200-inhabitant guideline [7] as the cut-off, because that would also remove 13 regular residential tracts with valid estimates. **1,593 tracts remain.**

A few variables still contain missing values, mainly median rent (98 tracts) and median home value (39). We keep these tracts, because their other variables are valid. Deleting them would also make the sample selective, since median rent is mostly missing in owner-occupied suburbs (87% owner-occupied vs. 59% elsewhere). Missing values are instead excluded per analysis.

---

## Question 2 – Median home value and median household income

The histograms of median home value and median household income (Figure 1) are both strongly **right-skewed**, with a striking **spike in the highest bin**. **Eleven tracts** have exactly the same maximum home value of **\$2,000,001**, and **30 tracts** the same maximum income of **\$250,001**. Since each median is based on hundreds of households, identical values in so many tracts cannot be a coincidence.

The explanation is **top-coding**. The ACS computes medians from grouped distributions whose highest interval is open-ended. When a tract's median falls in that interval, the Census Bureau publishes only the lower bound with a plus sign, "250,000+" or "2,000,000+". This means that *the median falls in the upper interval of an open-ended distribution*, and *a statistical test is not appropriate* [3, 5]. In the data these entries appear as 250,001 and 2,000,001. For these tracts we only know that the true median is **at least** the cap, so the variables are **right-censored**. The same applies to median rent ("3,500+", 22 tracts) and median year built ("1939 or earlier", 389 tracts).

As predictors, censored variables are problematic. For the richest tracts the predictor is understated and constant, while working from home keeps varying, and is in fact much higher there (32.8% in top-coded income tracts vs. 17.9% elsewhere). A linear model places all these tracts at a single point on the horizontal axis. This biases the estimated slope and makes it impossible to distinguish a neighbourhood with a median income of \$260,000 from one with \$600,000.

We **keep the top-coded tracts**, because they are exactly the affluent, high-WFH neighbourhoods that matter most for daytime residential electricity demand, and removing them would make the sample selective. We keep the capped value and add a **dummy variable** equal to 1 for top-coded tracts. In a regression, this dummy captures the average difference of the censored group, so the slope is estimated mainly from tracts with an observed value. Because both variables are right-skewed, we also use their **logarithms**. More advanced methods, such as a Tobit-type model, are not worthwhile since only 1–2% of the tracts are affected.

---

## Question 3 – Exploratory analysis

After cleaning, `pct_wfh` ranges from **0% to 52.4%**, with a median of **17.3%** and a mean of **18.2%**. In a typical neighbourhood almost one in five workers worked from home, but the variation is large: the middle half of the tracts lies between 10.2% and 25.0%.

We plotted `pct_wfh` against a selection of independent variables (Figures X–Y; all variables in the appendix) and computed the correlations (Table 1; full table in the appendix).

**Table 1 – Strongest correlations with `pct_wfh` (n = 1,593)**

| Positive | r | Negative | r |
|---|---|---|---|
| Bachelor's degree or higher | 0.81 | High school as highest degree | −0.73 |
| Management, business, science & arts occupations | 0.80 | Production & transport occupations | −0.64 |
| Median household income | 0.66 | Service occupations | −0.60 |
| Median home value | 0.64 | Households receiving SNAP | −0.55 |
| Broadband subscription | 0.41 | Construction & maintenance occupations | −0.52 |

**Education and occupation dominate.** The strongest relations are with the share of adults holding at least a bachelor's degree (r = 0.81) and the share in management, business, science and arts occupations (r = 0.80), both nearly linear. This supports the idea that working from home depends mainly on whether a job *can* be done remotely. Office and knowledge work can, while service, production, transport and construction work requires physical presence; these occupations are strongly negatively correlated.

**Income and wealth** are also positively related (income r = 0.66, home value r = 0.64), while poverty and SNAP receipt are negatively related. The relation with income is **convex**: working from home rises slowly at low incomes and steeply at high incomes. **Broadband access** is moderately positive (r = 0.41), mainly above about 90% coverage, although causality may run both ways. Commuting characteristics, age structure and housing type are only weakly related (|r| < 0.3).

Three caveats apply:
- **Correlation is not causation.** Education, occupation, income and home value are strongly correlated with each other, so their separate effects cannot be identified here. This multicollinearity will also affect the regression.
- **Several relations are non-linear,** which suggests using transformations such as logarithms.
- **The data average over a changing period.** The 5-year estimates pool responses from 2020 to 2024, when working from home first rose sharply and then partly declined [1, 2], which adds noise.

---

## Question 4 – Commuting shares and mechanical relations

In the ACS, every worker reports one principal means of transportation to work, and *worked from home* is one of the categories [6, 9]. All categories together therefore add up to 100% of workers:

> drove alone + carpooled + public transport + walked + other + **worked from home** = 100%

If the shares of people who drive alone or take public transport were measured as a share of **all workers**, they would be **mechanically linked** to the dependent variable. Every extra percentage point of working from home would automatically reduce the commuting shares. A regression would then find a strong negative relation that reflects an accounting identity, not a neighbourhood characteristic, so `pct_wfh` would partly be explained by itself. The variable would also be useless for prediction, since it can only be computed once working from home is already known. As a share of **commuters**, the variables instead describe *how* those who travel get to work, such as car dependence or access to public transport. These are genuine neighbourhood characteristics.

Our data show the size of this effect. The correlation between `pct_wfh` and driving alone is **−0.19** as a share of commuters. Converted into a share of all workers, it becomes **−0.54**, so most of that relation would be purely mechanical.

Other variables are also partly mechanically related to the dependent variable:
- **Mean travel time to work** is computed only over workers *who did not work from home* [6]. If people with long commutes are the most likely to work from home, the average commute of the remaining workers changes *because* of working from home.
- **Commuting mode shares**, even as shares of commuters, are affected by a composition effect. If train commuters switch to working from home, the transit share among the remaining commuters falls.
- **The number of workers** is the denominator of `pct_wfh` and should not be used as a predictor.
- **Broadband access** and **vehicle ownership** are not mechanically related, but may partly be consequences of working from home (reverse causality).

We therefore use the commuting variables only as shares of commuters, and treat commuting time and mode shares with caution in the regression analysis.

---

## References

[1] U.S. Census Bureau. *American Community Survey 5-Year Data (2009–2024)*. https://www.census.gov/data/developers/data-sets/acs-5year.html

[2] U.S. Census Bureau. *When to Use 1-year or 5-year Estimates*. https://www.census.gov/programs-surveys/acs/guidance/estimates.html

[3] U.S. Census Bureau. *Notes on ACS Estimate and Annotation Values*. https://www.census.gov/data/developers/data-sets/acs-1year/notes-on-acs-estimate-and-annotation-values.html

[4] U.S. Census Bureau. *Notes on ACS API Variable Types*. https://www.census.gov/data/developers/data-sets/acs-1year/notes-on-acs-api-variable-types.html

[5] U.S. Census Bureau. *Notes on ACS Data*. https://www.census.gov/data/developers/data-sets/acs-1year/data-notes.html

[6] U.S. Census Bureau. *American Community Survey Subject Definitions*. https://www.census.gov/programs-surveys/acs/technical-documentation/subject-definitions.html

[7] U.S. Census Bureau. *Geography Program – Glossary: Census Tract*. https://www.census.gov/programs-surveys/geography/about/glossary.html

[8] U.S. Census Bureau (2020). *Understanding and Using American Community Survey Data: What All Data Users Need to Know*. https://www.census.gov/content/dam/Census/library/publications/2020/acs/acs_general_handbook_2020.pdf

[9] U.S. Census Bureau. *Commuting – Guidance for Data Users*. https://www.census.gov/topics/employment/commuting/guidance/commuting.html
