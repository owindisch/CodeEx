# Working from Home in Massachusetts Neighbourhoods
### Assignment 2 – Questions 1–4 (Group 18)

---

## Introduction

Since the COVID-19 pandemic, many American workers do part or all of their work from home. This shifts daytime electricity demand from offices to residential neighbourhoods. We use the American Community Survey (ACS) 5-year estimates for 2020–2024 [1]. By pooling five years of responses, they provide reliable statistics for small areas such as census tracts [2, 8]. Census tracts are small statistical subdivisions of a county with generally 1,200 to 8,000 inhabitants [7]. Our data cover all tracts in Massachusetts. The dependent variable, `pct_wfh`, is the percentage of workers aged 16+ who worked from home in the week before the survey.

---

## Question 1 – Inspecting and cleaning the data

The raw data contain **1,620 census tracts** and **39 columns**: three identifiers (tract code, state and county), the dependent variable `pct_wfh`, and **35 independent variables** describing the population, education, occupations, labour market, income, commuting and housing of each tract. The variable description also lists the number of workers, but this variable is not included in our data file. The summary statistics show that several variables take the value **−666,666,666**, which cannot be a real value: no tract has a negative median income or median age. This value occurs **358 times**, only in the eight variables that the description marks as "may contain special codes": median rent (124), median home value (65), median household income (35), Gini index, median rooms and median year built (29 each), household size (27) and median age (20).

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

After cleaning, `pct_wfh` ranges from **0% to 52.4%**, with a median of **17.3%** and a mean of **18.2%**. In a typical Massachusetts neighbourhood almost one in five workers thus worked from home in the survey week. The differences between neighbourhoods are considerable: the middle half of the tracts lies between 10.2% and 25.0%, and in the 5% of tracts with the most home workers the share exceeds 35%. This variation is what we aim to explain. To explore it, we plotted `pct_wfh` against a selection of independent variables chosen on theoretical grounds (Figures X–Y; scatter plots for all variables are in the appendix), and computed the Pearson and Spearman correlations of `pct_wfh` with each of the 35 independent variables (Table A1 in the appendix). The log-transformed income and home value variables and the top-coding dummies created in Question 2 are transformations of existing variables and are therefore not counted as separate variables; where relevant, we mention the correlation with log income in the text.

The strongest relations are with **education and occupation**. The share of adults holding at least a bachelor's degree has a correlation of 0.81 with `pct_wfh`, and the share of workers in management, business, science and arts occupations a correlation of 0.80. Both scatter plots show a strong and almost linear pattern; only in the most highly educated tracts (above roughly 85% graduates) does the relation flatten slightly. The mirror image appears at the other end of the educational and occupational distribution. The share of adults whose highest degree is a high school diploma is strongly negatively correlated with working from home (r = −0.73), as are the shares with some college (−0.58) or no high school diploma (−0.56). Likewise, the shares of workers in production and transport (−0.64), service (−0.60), construction and maintenance (−0.52) and sales and office occupations (−0.33) are all negatively related. Together, these findings strongly suggest that working from home depends mainly on whether a job *can* be done remotely. Office and knowledge work lends itself to remote work, whereas jobs in services, manufacturing, transport and construction require physical presence. The relation with production occupations is also clearly non-linear: working from home falls steeply as the share rises from 0% to about 15%, after which it levels off at around 7–9%.

**Income and wealth** are also strongly related to working from home. Median household income (r = 0.66), median home value (r = 0.64) and median rent (r = 0.54) are all positively correlated with `pct_wfh`, while the share of households receiving food stamps (SNAP, r = −0.55) and the share of the population below the poverty line (r = −0.35) are negatively correlated. The scatter plot of income shows a **convex** pattern: working from home rises only slowly across low- and middle-income tracts and much more steeply among the richest tracts. This remains visible when income is measured in logarithms (r = 0.63). The top-coded tracts discussed in Question 2 form a visible vertical stripe at the right-hand edge of the income and home value plots, with high values of `pct_wfh`. It is likely that part of the income effect reflects education and occupation, since high-income neighbourhoods are also highly educated neighbourhoods with many professional jobs.

The **labour market** variables show a more modest pattern. Tracts with a higher labour force participation rate have somewhat more home workers (r = 0.24), whereas tracts with higher unemployment have fewer (r = −0.29). This is consistent with working from home being concentrated in economically strong neighbourhoods. **Broadband access** is moderately positively related to working from home (r = 0.41), but the relation is again non-linear: the share of home workers only increases markedly once more than about 90% of households have a broadband subscription. Here the direction of causality is unclear, because broadband makes remote work possible, but households that work from home also have a strong reason to subscribe.

Most **commuting, demographic and housing** variables are only weakly related to working from home. The share of commuters using public transport is mildly positive (r = 0.26), which mainly reflects the Boston area, where good transit coincides with many office jobs. Mean commuting time is weakly positive overall (r = 0.16), but the smoothed curve is hump-shaped, with the highest shares of home workers in tracts with average commutes of around 30–35 minutes. As discussed in Question 4, these commuting variables should be interpreted with care. Age structure (median age, shares of children and elderly), household size, the share of foreign-born residents and housing characteristics (detached houses, large apartment buildings, mobile homes, vacancy) all show correlations below 0.2 in absolute value. This does not mean that they are irrelevant: they may still matter once education and occupation are controlled for, which can only be assessed in a regression.

Comparing the Pearson and Spearman correlations provides additional information. For most variables both measures are very similar, but for skewed variables such as SNAP receipt (−0.55 vs. −0.61), poverty (−0.35 vs. −0.41) and median home value (0.64 vs. 0.70), the rank-based Spearman correlation is noticeably stronger. This indicates that these relations are monotonic but not linear, and that a few extreme tracts weaken the linear correlation. It is a further argument for transforming such variables, for example by taking logarithms, before using them in a regression.

Finally, three caveats should be kept in mind. First, correlation does not imply causation. Education, occupation, income and home value are strongly correlated with each other, so the bivariate correlations cannot tell us which of these characteristics actually drives working from home. In a regression this multicollinearity will make the individual coefficients less precise. Second, several of the relations are non-linear, as the curved smoothers in the scatter plots show, which a simple linear model would not capture. Third, the 5-year estimates pool responses from 2020 to 2024, a period in which working from home first rose sharply and then partly declined [1, 2]. A tract's value is therefore an average over very different phases of the pandemic and its aftermath, and differences in when households were interviewed add noise to the data.

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
