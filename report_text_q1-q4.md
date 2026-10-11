# Working from Home in Massachusetts Neighbourhoods
### Assignment 2 – Questions 1–4 (Group 18)

---

## Introduction

Since the COVID-19 pandemic, a substantial share of American workers has moved part or all of their working week from the office to the home. For an electricity company this matters directly: daytime demand that used to occur in office buildings now occurs in residential neighbourhoods. To plan grid investments and pricing, we therefore want to know how common working from home is in each neighbourhood, and which neighbourhood characteristics are associated with it.

We use the American Community Survey (ACS) 5-year estimates for 2020–2024, published by the U.S. Census Bureau [1]. The ACS is a continuous survey of US households. By pooling five years of responses, the 5-year estimates provide statistics for small geographic areas such as census tracts, at the cost of being less current than the 1-year estimates [2, 8]. Census tracts are small, relatively permanent statistical subdivisions of a county. They generally have between 1,200 and 8,000 inhabitants, with an optimum size of about 4,000 [7]. Our data set covers all tracts in Massachusetts. The dependent variable, `pct_wfh`, is the percentage of workers aged 16 and over who worked from home in the week before they were surveyed.

---

## Question 1 – Inspecting and cleaning the data

### What the data look like

The raw data set contains **1,620 census tracts** and **39 variables**: three identifiers (tract code, state and county), the dependent variable, and about 35 characteristics describing the population, education, occupations, labour market, income, commuting and housing of each tract. A first look at the summary statistics immediately reveals a problem. Several variables have a minimum of **−666,666,666**, which is obviously not a real value: a tract cannot have a negative median income, and certainly not a median age of minus 666 million years.

This value occurs **358 times** in total, and only in the eight variables that the variable description marks as "may contain special codes":

| Variable | Number of times −666,666,666 occurs |
|---|---|
| Median gross rent (`med_rent`) | 124 |
| Median home value (`med_value`) | 65 |
| Median household income (`med_hh_income`) | 35 |
| Gini index (`gini`) | 29 |
| Median number of rooms (`med_rooms`) | 29 |
| Median year built (`med_year_built`) | 29 |
| Average household size (`hh_size`) | 27 |
| Median age (`med_age`) | 20 |

No other special codes (such as −999,999,999 or −888,888,888) appear in our data.

### What the special values mean

The Census Bureau's API documentation explains that such numbers are **annotation values**: placeholders that the Bureau publishes when it cannot report a real estimate [3, 4]. Each code has a specific meaning. The value −666,666,666 indicates that *"the estimate could not be computed because there were an insufficient number of sample observations"* [3]. For a median this typically happens when the underlying distribution contains no or too few cases in a tract. A median rent cannot be computed in a tract where almost every household owns its home, and a median home value cannot be computed in a tract that consists almost entirely of rental apartments. The Bureau's documentation further states that whenever an annotation exists, it should be used *in place of* the estimate [4]. In other words, the number itself carries no quantitative information.

### How we treat them

We recode every occurrence of −666,666,666 as **missing (NA)**. There are three reasons for this choice:

1. **The values are labels, not measurements.** They indicate that the true value is unknown.
2. **Keeping them would distort every analysis.** In a sample of about 1,600 tracts, a single code lowers the mean of a variable by roughly 400,000 units and would completely dominate any correlation, plot or regression.
3. **Replacing them by zero or by the mean would invent information.** The true value is not zero, and imputing an average would make the data look more precise than they are.

Treating the values as missing is the honest choice: R automatically excludes them from correlations and regressions.

### Tracts with no or very few inhabitants

We then examined the population of each tract. **Eighteen tracts have no inhabitants at all**, and a further **nine tracts have between 3 and 202 inhabitants**. Almost all of these tracts have codes in the 9800 or 9900 range. The Census Bureau reserves these codes for *special land-use tracts*, areas with little or no residential population such as parks, airports or industrial zones, and for tracts that contain *only water* [7]. In our data they include the Boston Harbor islands, the Boston airport area and coastal water tracts. These are not neighbourhoods in which the electricity company serves households.

For tracts without inhabitants, the dependent variable simply cannot be computed. For the very small tracts it can be computed, but it is not meaningful. The ACS samples only a few percent of all addresses each year [8], so a tract with a few dozen inhabitants contributes only a handful of survey responses over five years. This is clearly visible in the data: in five of the nine small tracts, `pct_wfh` is exactly 0% or exactly 100%. Values like these reflect sampling noise rather than real differences between neighbourhoods, and the Census Bureau itself stresses that estimates for small areas carry large margins of error [8].

The distribution of population shows a natural break: the largest of the tiny tracts has 202 inhabitants and the next tract has 453. We therefore **remove all tracts with fewer than 300 inhabitants**, together with any tract for which `pct_wfh` is missing. We deliberately do not use the Census guideline of 1,200 inhabitants as the cut-off [7]. That would also remove 13 regular residential tracts (for example on Nantucket and in central Boston) whose estimates are perfectly usable.

### Result

After cleaning, **1,593 tracts remain** (27 removed). A few independent variables still contain missing values, most notably median rent (98 tracts) and median home value (39 tracts). We keep these tracts in the data set for two reasons:

- **Their other variables are valid.** Removing every tract with at least one missing value would leave only 1,462 tracts and throw away a large amount of good information.
- **The missing values are not random.** Median rent is missing mainly in owner-occupied suburbs, where 87% of homes are owned compared with 59% elsewhere. Removing these tracts would make the sample unrepresentative.

Missing values are instead excluded per analysis: pairwise for correlations, and listwise per regression model, depending on which variables the model includes.

---

## Question 2 – Median home value and median household income

### What the histograms show

Figure 1 shows the histograms of median home value and median household income. Both distributions are strongly **right-skewed**: most tracts have a median household income between roughly \$50,000 and \$150,000 and a median home value between \$300,000 and \$800,000, while a long tail extends towards very wealthy areas. The most striking feature, however, is a **spike in the very last bin** of both histograms:

| Variable | Maximum value | Number of tracts at exactly this value |
|---|---|---|
| Median home value | \$2,000,001 | 11 |
| Median household income | \$250,001 | 30 |

A median is computed from the answers of hundreds of households, so it is practically impossible for thirty different neighbourhoods to have *exactly* the same median income by coincidence. The unusual "1" at the end of both numbers is a further hint that something systematic is going on.

### Why: top-coding in the ACS

The explanation is **top-coding**. The Census Bureau computes medians from grouped (interval) distributions, and the highest interval of such a distribution is open-ended: it has a lower bound but no upper bound. When a tract's median falls in that top interval, the Bureau does not publish an exact number. Instead it publishes the lower bound followed by a plus sign. According to the Census documentation, an entry such as "250,000+" means that *the median falls in the upper interval of an open-ended distribution* [3, 5]. The same convention applies to the lowest interval, which is indicated with a minus sign, and the margin of error of such a median is reported as "***" because *a statistical test is not appropriate* [3, 5]. In the machine-readable data these entries appear as 250,001 for household income ("250,000+") and 2,000,001 for home value ("2,000,000+").

For the 11 and 30 tracts at the maximum we therefore do not know the actual median. We only know that it is **at least** \$2,000,000 or \$250,000. The true value could be slightly above the cap or far above it. In statistical terms, both variables are **right-censored**. The same issue affects other variables in our data: median rent is top-coded at "3,500+" (22 tracts), and median year built is bottom-coded at "1939 or earlier" (389 tracts, reflecting the many historic town centres of Massachusetts).

### What this means when using them as predictors

Censoring has several consequences for using these variables as predictors of working from home:

- **Measurement error at the top.** For the wealthiest tracts the predictor is understated and constant, while the dependent variable keeps varying. These tracts are not a random group: working from home is much more common in them (32.8% in top-coded income tracts against 17.9% elsewhere).
- **A distorted slope.** A linear model will place all these high-WFH tracts at a single point on the horizontal axis. This bends the estimated relationship at the top of the distribution and biases the slope.
- **No extrapolation.** The model cannot distinguish a neighbourhood with a median income of \$260,000 from one with \$600,000, so it says nothing reliable about the very richest areas.
- **Artificial ties.** Methods based on ranks or exact values treat the top-coded tracts as identical, although they are not.

### Our decision

We **keep the top-coded tracts** in the analysis. They are real and highly relevant neighbourhoods: affluent, highly educated areas with a high share of home workers, and therefore precisely the areas where daytime residential electricity demand is likely to be highest. Removing them would cut off the most interesting part of the distribution and make the sample selective.

Instead, we keep the capped value and add a **dummy variable** that equals 1 for top-coded tracts and 0 otherwise. In a regression, this dummy absorbs the average difference between the censored group and the other tracts, so the slope of the continuous variable is estimated mainly from the tracts whose value is actually observed. In addition, because both variables are strongly right-skewed and their relation with working from home is closer to linear on a logarithmic scale, we use the **logarithm** of median household income and median home value. We considered more advanced alternatives, such as a censored (Tobit-type) model or imputing values above the cap with an assumed income distribution. Since only 1–2% of the tracts are affected, the extra complexity is not justified at this stage.

---

## Question 3 – Exploratory analysis

### The dependent variable

After cleaning, the share of workers working from home ranges from **0% to 52.4%** across Massachusetts tracts. The median is **17.3%** and the mean **18.2%**, so in a typical neighbourhood almost one in five workers worked from home in the survey week. The differences between neighbourhoods are substantial: the middle half of the tracts lies between 10.2% and 25.0%, and the 5% of tracts with the most home workers exceed 35%. This variation is what we aim to explain.

### Relations with the independent variables

We plotted `pct_wfh` against a selection of independent variables chosen on theoretical grounds (Figures X–Y; scatter plots for all variables are in the appendix), and computed the correlation of `pct_wfh` with every independent variable (Table A1 in the appendix). Table 1 summarises the strongest relations.

**Table 1 – Strongest correlations with `pct_wfh` (n = 1,593)**

| Positive | r | Negative | r |
|---|---|---|---|
| Bachelor's degree or higher | 0.81 | High school as highest degree | −0.73 |
| Management, business, science & arts occupations | 0.80 | Production & transport occupations | −0.64 |
| Median household income | 0.66 | Service occupations | −0.60 |
| Median home value | 0.64 | Households receiving SNAP | −0.55 |
| Median gross rent | 0.54 | Construction & maintenance occupations | −0.52 |
| Broadband subscription | 0.41 | Population below poverty level | −0.35 |

**Education and occupation dominate.** The strongest relations by far are with the share of adults holding at least a bachelor's degree (r = 0.81) and the share of workers in management, business, science and arts occupations (r = 0.80). Both scatter plots show a strong and almost linear pattern. This is consistent with the idea that working from home depends primarily on whether a job *can* be done remotely. Office and knowledge work lends itself to remote work, whereas jobs in services, production, transport and construction require physical presence. Accordingly, these occupations show strong negative correlations (between −0.52 and −0.64), as does the share of adults whose highest degree is a high school diploma (−0.73).

**Income and wealth matter too.** Median household income (r = 0.66), median home value (r = 0.64) and median rent (r = 0.54) are all clearly positively related to working from home, while poverty and SNAP receipt are negatively related. The relation with income is **convex**: the share of home workers rises only slowly across low- and middle-income tracts and much more steeply among high-income tracts, even when income is measured in logs. Part of this association probably reflects education and occupation, because high-income neighbourhoods are also highly educated neighbourhoods.

**Broadband access** is moderately positively related (r = 0.41), and this relation is also non-linear. Working from home increases markedly only once more than about 90% of households have a broadband subscription. Note that the direction of causality is unclear: broadband enables remote work, but households that work from home are also more likely to subscribe.

**Weak relations.** Commuting characteristics, age structure (median age, share of elderly or children), household size and housing type (detached houses, large apartment buildings, mobile homes) are only weakly correlated with working from home (|r| < 0.3). They may still matter once we control for education and occupation, which can only be assessed in a regression.

### Caveats

Three caveats should be kept in mind when interpreting these findings:

- **Correlation does not imply causation.** Education, occupation, income and home value are strongly correlated with each other, so the bivariate correlations cannot tell us which characteristic actually drives working from home. This multicollinearity will make individual regression coefficients less precise.
- **Several relations are non-linear,** as the curved smoothers in the scatter plots show. This suggests using transformations, such as logarithms, in the regression analysis.
- **The 5-year estimates average over a changing period.** They pool responses from 2020 to 2024, a period in which working from home first rose sharply and then partly declined [1, 2]. A tract's value is therefore an average over very different phases of the pandemic and its aftermath. Differences in when households were interviewed add noise to the data.

---

## Question 4 – Commuting shares and mechanical relations

### Why commuting shares must be shares of commuters

In the ACS, every worker reports the principal means of transportation they usually used to get to work in the reference week. *Worked from home* is one of the answer categories, alongside driving alone, carpooling, public transportation, walking, cycling and other means [6, 9]. Because every worker falls into exactly one category, the categories always add up to 100% of all workers:

> drove alone + carpooled + public transport + walked + other means + **worked from home** = 100%

If the share of people who drive alone or take public transport were measured as a share of **all workers**, these variables would be **mechanically linked** to the dependent variable. Every additional percentage point of working from home would automatically remove a percentage point from the commuting categories, regardless of anything happening in the neighbourhood. This creates three problems:

1. **The regression becomes partly circular.** It would find a strong negative relation between commuting shares and working from home, but this relation would largely reflect an accounting identity rather than a characteristic of the neighbourhood. In effect, `pct_wfh` would be explained by a variable that already contains `pct_wfh`.
2. **The variable is useless for prediction.** To compute the share of all workers who drive, one must already know how many work from home, which is exactly what we want to predict.
3. **The coefficient is uninterpretable.** It would mix two different things: the travel behaviour of commuters, and the number of workers who do not commute at all.

When the shares are instead expressed as a share of **commuters** (workers who do not work from home), the identity disappears. The variables then describe *how* the people who do travel get to work, for example how car-dependent a neighbourhood is or how good its access to public transport is. These are genuine neighbourhood characteristics.

Our data illustrate how large this problem would be. The correlation between `pct_wfh` and the share driving alone is **−0.19** when measured, as in our data, as a share of commuters. When we convert the same variable into a share of all workers (multiplying by (100 − `pct_wfh`)/100), the correlation jumps to **−0.54**. Most of the apparent relation would then be purely mechanical.

### Other mechanically related variables

Several other independent variables are, at least partly, mechanically related to the dependent variable:

- **Mean travel time to work (`mean_commute`).** The Census Bureau computes this as the total travel time of all commuters divided by the number of workers aged 16 and over *who did not work from home* [6]. Home workers are thus excluded by definition. If workers with long commutes are the most likely to switch to working from home, as seems plausible, the average travel time of the remaining commuters falls *because* of working from home. The variable would then be partly an outcome rather than an explanation. The hump-shaped pattern in its scatter plot is consistent with this.
- **Commuting mode shares, even as shares of commuters.** Although the accounting identity is removed, a composition effect remains. If office workers who used to take the train now work from home, the share of public transport among the *remaining* commuters falls. These variables are therefore not completely independent of working from home.
- **The number of workers.** This is the denominator of `pct_wfh`. The variable description explicitly states that it should be used for cleaning and weighting, not as a predictor.
- **Broadband access and vehicle ownership.** These are not mechanically related, but they may partly be *consequences* of working from home: home workers need a broadband connection and may give up a car. This reverse causality must be kept in mind when interpreting their coefficients.

In the subsequent regression analysis we therefore use the commuting variables only as shares of commuters, as provided. We treat the commuting time and commuting shares with caution, and we report results both with and without them.

---

## References

[1] U.S. Census Bureau. *American Community Survey 5-Year Data (2009–2024)*. https://www.census.gov/data/developers/data-sets/acs-5year.html

[2] U.S. Census Bureau. *When to Use 1-year or 5-year Estimates*. https://www.census.gov/programs-surveys/acs/guidance/estimates.html

[3] U.S. Census Bureau. *Notes on ACS Estimate and Annotation Values*. https://www.census.gov/data/developers/data-sets/acs-1year/notes-on-acs-estimate-and-annotation-values.html

[4] U.S. Census Bureau. *Notes on ACS API Variable Types*. https://www.census.gov/data/developers/data-sets/acs-1year/notes-on-acs-api-variable-types.html

[5] U.S. Census Bureau. *Notes on ACS Data*. https://www.census.gov/data/developers/data-sets/acs-1year/data-notes.html

[6] U.S. Census Bureau. *American Community Survey Subject Definitions* (Journey to Work; Income; Housing). https://www.census.gov/programs-surveys/acs/technical-documentation/subject-definitions.html

[7] U.S. Census Bureau. *Geography Program – Glossary: Census Tract*. https://www.census.gov/programs-surveys/geography/about/glossary.html

[8] U.S. Census Bureau (2020). *Understanding and Using American Community Survey Data: What All Data Users Need to Know*. https://www.census.gov/content/dam/Census/library/publications/2020/acs/acs_general_handbook_2020.pdf

[9] U.S. Census Bureau. *Commuting – Guidance for Data Users*. https://www.census.gov/topics/employment/commuting/guidance/commuting.html
