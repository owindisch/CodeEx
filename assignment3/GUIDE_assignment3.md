# Assignment 3 – Revenue of US college athletics programs: step-by-step guide

The code is in `assignment3/assignment3_code.Rmd`, with our own variable names (`athletics_new`,
`prediction_new`, `fixed_coaches()`, …). From Part 3 on it follows the **lecture code**:
- the train/test split uses `createDataPartition()`, as in the penalized regression code;
- PCA uses `princomp()`, `permtestPCA()` and the bootstrap of the eigenvalues, as in Week 5;
- ridge regression uses `model.matrix()`, z-scores and `glmnet()`/`cv.glmnet()` with a lambda
  grid and an RMSE plot, as in Week 3.

Put the `.Rmd` in the same folder as `permtestPCA.R` (the lecture function, included in the
repo), `data_783996yw.csv` and `predictions-2.csv`. No `setwd()` is needed.
`assignment3/assignment3_revenue.R` is the same code as a plain script (made with
`knitr::purl`), to run without knitting. Both write the 10 predictions to
`predictions_output.csv`.

The Week 6 code (MCA with `homals`, correspondence analysis) is for categorical data. The
assignment doesn't ask for it, so it isn't used.

**What the assignment requires, and where it is in the code**

| Requirement | Where |
|---|---|
| PCA regression model | PCA chunk (Part 4) + PCR chunk (Part 5) |
| Permutation test | Part 4b |
| Bootstrap of Kaiser's rule and of the VAF | Part 4c |
| Name and interpret the components | Part 4d (loadings + biplot) |
| Ridge regression | Part 6 |
| Log revenue vs revenue evaluation | Part 7 |
| Predictions for `predictions-2.csv` | Part 8 |

Everything else was left out, so that everything in the code can be explained in the report.

**Names in the `.Rmd`**

| Object | What it is |
|---|---|
| `athletics` | The 1000 institutions, as loaded (never changed) |
| `prediction` | The 10 institutions from `predictions-2.csv`, as loaded |
| `athletics_new`, `prediction_new` | After `fixed_coaches()`, factors and `logged_vars()` |
| `fixed_coaches()` | No coaches (NaN) → count 0 and salary 0 |
| `logged_vars()` | `log1p()` of the counts and salaries |
| `train_data`, `test_data` | 80/20 split of `athletics_new`, after `impute()` |
| `X_pca`, `X_pca_test` | The 28 numerical predictors of train and test, for the PCA |
| `fitpca` | The PCA (`princomp`) on the training data |
| `perm_range`, `eigs.boot` | Permutation-test bounds; bootstrapped eigenvalues |
| `n_pc` | Chosen number of components |
| `fit_pcr` | The PCR model (`lm` on the PC scores + dummies) |
| `X`, `y`, `X_test`, `X_new` | Ridge input: z-scored predictor matrices (train, test, the 10 schools) and log revenue |
| `result.ridge.cv`, `result.ridge.min`, `result.ridge.1se` | Ridge cross-validation and the final ridge models |
| `revenue`, `logrevenue`, `classifications` | The ggplot figures of Part 1; later plots are base R plots, as in the lectures |

The parts below follow the code chunks. Each part has **what the code does**, **guiding questions**
(like the questions in Assignments 1 and 2), and **what came out** when I ran it (seed 123,
80/20 split). All numbers depend on the seed and on your choices, so rerun the script before
you copy anything into the report.

---

## Background: what the data are (EADA)

The data come from the **Equity in Athletics Disclosure Act (EADA)** survey of the US
Department of Education ([ope.ed.gov/athletics](https://ope.ed.gov/athletics/#/)). Every
co-educational institution that receives federal student aid (Title IV) and runs
intercollegiate athletics must fill it in every year. These definitions matter for the analysis:

| Variable | EADA definition | Why it matters |
|---|---|---|
| `revenue` | Grand total revenue: all revenue attributable to intercollegiate athletics. That includes tickets, media rights, donations, conference distributions, student fees and **institutional support** (money from the school itself). | The instructions say grand total revenue **must cover grand total expenses**: a deficit is filled with institutional support, which counts as revenue. For most smaller programs, revenue therefore measures the **athletics budget**, not money earned. |
| `athletes_*` | Unduplicated head count: an athlete on several teams counts once. Participants are counted as of the day of the first scheduled contest. | `partic_*` counts per team, so the sum of the men's `partic_*` variables is larger than `athletes_men` at 57% of schools (e.g. track and cross country athletes). |
| `hc_*`, `ac_*` | Coaches reported per men's/women's team. | No teams → no coaches → NaN. |
| `*_salary_*` | Average salary per coaching position, coaching duties only (salary + bonuses, **no benefits**). Volunteers are left out of the average. | Very low averages (a few thousand USD) indicate part-time coaches. NaN with coaches present may mean "all volunteers". |

**Consequences for the report**
- Because revenue must cover expenses, revenue and spending (salaries, number of coaches)
  are close to two sides of the same budget. The strong correlations are partly mechanical
  (compare the Assignment 2 discussion on mechanically related variables). This supports a
  **prediction** framing, not a causal one.
- The extreme right tail is real: only the large NCAA Division I programs (mostly FBS) earn
  large media, ticket and donation income. These values are not data errors and should not
  be removed.
- Revenue is in nominal USD for a single reporting year, so no inflation correction is needed.

> **Note:** the ope.ed.gov site could not be reached from the environment where this guide
> was written. The definitions above come from the official EADA survey instructions as they
> are quoted in institutions' published EADA reports (sources at the end). Check the wording
> against the "User's Guide" on the EADA site before you cite it.

---

## Suggested research question

The assignment asks for prediction, not causation. A research question that fits the data
and the models:

> *To what extent can the revenue of an athletics program be predicted from its participation,
> coaching staff and classification, and which groups of related characteristics (components)
> carry this information?*

You may still talk about correlations ("programs with higher coach salaries tend to have
higher revenue"). Do not write "salaries determine revenue".

---

## Part 1 – Load and inspect

**What the code does:** it reads the data (1000 × 32) and `predictions-2.csv` (10 × 31), counts
the NaNs, tabulates the categorical variables, and plots revenue, log revenue, and log revenue
by classification.

**Guiding questions**
- Which variables are categorical? (`classification` has 19 levels, `sector` has 5.) Are some
  levels very rare? (NCCAA Division I has 2 institutions, Independent has 7, and two sectors
  have fewer than 10.) What does a rare level mean for the train/test split and for the dummies?
- Where are the NaNs, and what do they *mean*? Are they "unknown" or "not applicable"?
- How skewed is revenue? Compare the mean (14.3M) and the median (4.1M). The maximum is 290M.

**Findings**
- NaNs appear only in the coach variables: `hc_*`, `ac_*` and their salaries.
- Every institution with `teams_men == 0` has `hc_men = NaN`, and the same holds for women.
  So the NaN means *no coaches*, not *unknown*.
- `ac_men` and `ac_women` are never 0 in the data (the minimum is 1). So NaN most likely
  encodes 0 assistant coaches, and then the salary is not applicable.
- 9 (men) and 7 (women) institutions report assistant coaches but **no salary**. EADA leaves
  volunteers out of the average salary, so these could be institutions with only volunteer
  assistants. We cannot verify that, so the script treats them as genuinely missing and
  imputes them. Mention this in the report: setting them to 0 is a defensible alternative.
- Revenue skewness is 4.5 on the raw scale and 0.09 on the log scale. Median log revenue
  rises steeply with division: FBS programs earn about 118M, NJCAA III programs about 0.6M.

## Part 2 – Missing values and transformations

**What the code does**
1. `fixed_coaches()` sets coach counts with NaN to 0, and sets the matching salary to 0.
   It applies the same rule to `prediction`. The result is `athletics_new` and `prediction_new`.
2. The target is `log_revenue = log(revenue)`. There are no zeros, so a plain `log` works.
3. `classification` and `sector` become factors. `prediction_new` gets the **same levels** as
   `athletics_new`, so `model.matrix()` later creates identical dummy columns.
4. The skewness table is computed, and then `logged_vars()` applies `log1p(x) = log(1 + x)`
   to the skewed counts and salaries. The two share variables (between 0 and 1) stay as they
   are. The skewness table must come first, because it needs the unlogged values.

**How the `fixed_coaches()` loop works**
- `for (s in c("men", "women"))`: the loop runs twice, once for the men's and once for the
  women's columns.
- `paste0("hc_", s)` builds the column **name**, e.g. `"hc_men"`. `x[[hc]]` then fetches that
  column (`$` doesn't work with a name stored in a variable).
- `no_hc <- is.na(x[[hc]])` is TRUE/FALSE per institution: "no head coaches".
- `x[[hc]][no_hc] <- 0` sets the count to 0 for those rows.
- `x[[hs]][no_hc & is.na(x[[hs]])] <- 0`: the salary becomes 0 **only** if there are no coaches
  **and** the salary is missing.

**What happens to the (possible) volunteers.** EADA counts volunteer coaches, but leaves them
out of the average salary.

| Situation | Data | Treatment |
|---|---|---|
| Paid coaches + some volunteers | Count includes everyone; salary = average over paid coaches | Nothing to fix |
| No coaches | Count NaN, salary NaN | `fixed_coaches()`: both 0 |
| Coaches but no salary (all volunteers?) | Count present, salary NaN (9 men's, 7 women's assistant salaries) | `fixed_coaches()` leaves them; `impute()` in Part 3 gives the training median |

Nobody is deleted: all 1000 institutions stay in the data. Dropping them would remove mostly
small schools, bias the data towards big programs, and isn't possible for the 10 schools you
must predict. If you prefer "volunteers = salary 0", add
`x[[hs]][is.na(x[[hs]])] <- 0` and `x[[as]][is.na(x[[as]])] <- 0` at the end of the loop. You
could run it both ways and say whether the choice matters (only 16 of 1000 values).

**Guiding questions**
- Why is 0 the right value for "no coaches", while a median would be wrong there?
- For the 16 salaries with coaches present: are these volunteers (salary 0) or unreported
  values (impute)? Use the EADA salary definition in your argument.
- Why do the 16 genuinely missing salaries get the *training* median (Part 3) and not the
  full-data median? (Leakage: the test set must stay unseen.)
- Should you also log the predictors? PCA is based on correlations, which are linear and
  sensitive to outliers. Salaries have skewness of up to 5 on the raw scale. Check the
  skewness table: logs fix the right tail, but some counts become left-skewed because of
  the zeros. Discuss this trade-off.
- Optional: add an indicator such as `has_football = partic_football > 0`. Would it help?
  (The classification dummies partly capture it already.)

## Part 3 – Train/test split and preprocessing

**What the code does:** an 80/20 split with `createDataPartition(athletics_new$log_revenue,
p = 0.8)`, as in the lecture code. It splits within quantiles of log revenue, so train and test
have a similar spread of small and big programs. It gives 802 training and 198 test
institutions. It then computes the imputation medians on the training set only and applies
them to `train_data`, `test_data` and `prediction_new`. A `stopifnot()` check confirms that no
NA is left. Finally it prints the correlations of each predictor with log revenue.

**Where the NAs go**

| Step | Object | NAs left? |
|---|---|---|
| Load | `athletics` | Yes, all |
| `fixed_coaches()` + `logged_vars()` | `athletics_new` | Yes, the 16 salaries |
| Split | `train_data`, `test_data` | Yes, the 16 salaries |
| `impute()` | `train_data`, `test_data`, `prediction_new` | **No** |

`athletics_new` itself keeps the 16 NAs. For plots or correlations on all data, use
`na.rm = TRUE`.

**Guiding questions**
- Why split within quantiles of log revenue? (With only 66 FBS schools, a plain random split
  could put very few big programs in the test set.)
- Are all classification levels in the training set? (Yes with seed 123. Check yours.)
- Which predictors correlate most with log revenue? Here: athletes_women 0.80,
  hc_salary_men 0.78, and the coaching counts about 0.74.
- Why are spending variables (salaries, coaches) so strongly correlated with revenue? Use the
  EADA rule that revenue must cover expenses.
- Many predictors correlate strongly with each other (size). Why does that motivate PCA
  and ridge regression rather than OLS? (Think back to Assignment 1.)

## Part 4 – PCA (the main extra requirement)

`princomp(X_pca, cor = TRUE, scores = TRUE)` runs on the **28 numerical predictors** of the
training data, on the correlation matrix (`cor = TRUE`), because the variables have different
units. Revenue and the dummies are left out: revenue because PCA must use the predictors only,
the dummies because PCA on 0/1 variables is hard to interpret. `summary(fitpca)` gives the
standard deviation, the proportion of variance (VAF) and the cumulative VAF per component.

### 4a. Simple rules as a reference

Kaiser's rule and the VAF are the two rules the assignment asks us to bootstrap, so we first
apply them in their plain form, together with the scree plot (`screeplot()`):

| Rule | Number of PCs |
|---|---|
| Kaiser (eigenvalue > 1): a PC must explain more than one original variable | 6 |
| 80% cumulative VAF | 8 |
| Scree plot elbow | ≈ 2–3 (λ₁ = 13.8, λ₂ = 2.7, λ₃ = 1.5, then flat around 1) |

**Guiding questions:** Do the rules agree? Why is Kaiser close to arbitrary here?
PCs 4–6 have eigenvalues of 1.23, 1.12 and 1.02, so they sit right at the threshold. The 80%
cutoff is a convention, not a test (PC7 reaches 79.7%, so the rule asks for 8). This motivates
the permutation test and the bootstrap.

### 4b. Permutation test

**What the code does:** the lecture function `permtestPCA(X_pca, nTests = 1000)`. It shuffles
every column (except the first) independently, 1000 times. This destroys the correlations but
keeps each variable's distribution. It computes the eigenvalues of each shuffled dataset and
returns the 2.5% and 97.5% quantiles per component, plus a plot. A component is kept when its
observed eigenvalue lies above the upper (97.5%) bound.

**Guiding questions**
- What is H₀ for component *j*? (It explains no more variance than a component from
  uncorrelated data with the same marginal distributions.)
- Why is the test stricter than Kaiser? Even with zero correlation, the first eigenvalues of
  a sample are larger than 1 by chance (here the upper bounds are 1.42, 1.35, 1.31, …). Kaiser
  ignores this.

**Result:** PC3 has eigenvalue 1.50 > 1.31. PC4 has 1.23 < 1.27, so it is not above chance.
**→ 3 PCs.**

### 4c. Bootstrap of Kaiser's rule and of the VAF

**What the code does:** the lecture bootstrap. `my_boot_pca()` runs `princomp()` on a resampled
set of rows and returns the eigenvalues; `boot(..., R = 1000)` repeats this 1000 times;
`eigs.boot` stores the 1000 × 28 eigenvalues.
- *Kaiser:* a PC counts as significant when the **lower** bound of its 95% CI is above 1. A
  boxplot of the bootstrapped eigenvalues with a red line at 1 shows this.
- *VAF:* the bootstrapped VAF of the chosen PCs, with a histogram and its 95% interval (green)
  and the training estimate (red), as in Assignment 2.

**Results**
- Eigenvalue CIs: PC4 [1.14, 1.49] and PC5 [1.04, 1.23] are above 1. PC6 [0.94, 1.10]
  contains 1. **→ the bootstrapped Kaiser rule gives 5 PCs.**
- The VAF of 3 PCs is 64.4%, with a 95% CI of [63.1%, 66.5%].

| Method | PCs |
|---|---|
| Kaiser (eigenvalue > 1) | 6 |
| 80% cumulative VAF | 8 |
| Permutation test | **3** |
| Bootstrapped Kaiser | 5 |

**Guiding questions**
- Why do the permutation test (3) and the bootstrapped Kaiser rule (5) disagree? They test
  different nulls. Kaiser asks whether a PC is worth more than one variable. The permutation
  test asks whether a PC is more than chance structure. With 28 variables, chance alone gives
  eigenvalues up to about 1.3–1.4 for the first components, so the permutation test is stricter.
- The bootstrap eigenvalues of the leading PCs are biased upward (resampling duplicates rows).
  Does that matter for a borderline PC like PC5?
- Which number do you choose, and why? The code uses **3** (`n_pc <- k_perm`). You can
  change that line.

### 4d. Naming the components

**What the code does:** it prints the loadings of the chosen PCs and the **fit per variable**
(lecture Week 5): the squared correlations between each variable and the component scores,
summed over the chosen PCs. It also draws two biplots (components 1–2 and 2–3) with
`biplot(fitpca, pc.biplot = TRUE, ...)`, as in the lecture.

**Suggested interpretation (check it against your own loadings and biplots).** The sign of a
component is arbitrary: `princomp()` happened to flip PC2 compared with earlier versions of
this code, so read the signs from your own output.

| PC | VAF | Loadings (correlations with the PC) | Possible name |
|---|---|---|---|
| PC1 | 49% | All positive; 0.86–0.94 with athletes, teams and coaches | **Program size / scale** |
| PC2 | 10% | + enrollment (0.53–0.57), all salaries (0.41–0.52), full-time share (0.44). − men's soccer (−0.51), teams and head coaches (≈ −0.39) | **Professionalisation (pay per coach, big campus) vs. breadth of sports** |
| PC3 | 5% | + enrollment, track, other sports. − basketball, baseball, softball (−0.30 to −0.48), assistant salaries | **Large-campus Olympic sports vs. small-college team sports** |

**Guiding questions**
- Which variables are badly explained by 3 PCs (low fit)? `hc_female_share` (0.09),
  `partic_football` (0.36), `partic_baseball` (0.37) and `partic_softball` (0.39). Is it a
  problem that football, the main revenue driver at FBS schools, is poorly represented?
- In the biplots, which variables point in the same direction (correlated)?

## Part 5 – Principal component regression

**What the code does:** `lm(log_revenue ~ Comp.1 + Comp.2 + Comp.3 + classification + sector)`.
The PC scores come from the training PCA. The test data are projected with that **same**
training PCA (`predict(fitpca, newdata = X_pca_test)`), so train and test use identical
components.

**Results:** R² = 0.945 on the training data. Comp.1 (0.28 per unit) and Comp.2 (0.13) are
strongly significant. Comp.3 is not (p = 0.64). The division dummies are large: FBS +2.36 and
Division I without football +1.54 relative to CCCAA.

**Guiding questions**
- Why do the dummies enter separately instead of through the PCA? (PCA on 0/1 variables is
  hard to interpret, and the division is the strongest single predictor of revenue.)
- Comp.3 explains real variance in the predictors but doesn't help predict revenue. Why can
  that happen? (PCA never looks at revenue: the directions with the most variance in X are not
  necessarily the ones that predict revenue best.)

## Part 6 – Ridge regression

**What the code does:** this follows the Week 3 lecture code.
- `model.matrix()` builds the predictor matrix with dummies, and the intercept column is
  removed.
- The numerical columns become z-scores, using the **training** means and sds for train, test
  and the 10 new schools. The dummies stay 0/1. This is why `standardize = FALSE`.
- `glmnet(X, y, alpha = 0, lambda = grid)` gives the coefficient paths, with the grid
  `10^seq(-5, 2, length.out = 100)`.
- `cv.glmnet(..., nfolds = 10)` chooses λ. The CV error is plotted as RMSE (`cvm^0.5`), as in
  the lecture.
- Final runs at λ_min and λ_1se, with a coefficient table (`Weights`).

**Results:** λ_min = 0.0005 and λ_1se = 0.0093. Both are very small: cross-validation prefers
almost no shrinkage. With 802 institutions and 50 coefficients, there is enough data for nearly
unpenalised estimates, so ridge at λ_min is close to OLS. λ_1se shrinks more: for example, the
FBS dummy goes from +1.94 to +1.19. The largest effects are the division dummies (FBS +1.94,
D-I without football +1.33, FCS +1.21 at λ_min), then `hc_salary_men` (+0.24),
`athletes_women` (+0.16) and `hc_men` (+0.16) per standard deviation.

**Guiding questions**
- Why standardise before ridge? Why must the test set use the *training* means and sds?
- The coefficients are on log scale. A dummy coefficient of 1.94 means about
  exp(1.94) ≈ 7× the revenue of the reference group (CCCAA), *holding the other variables
  fixed*. Ridge coefficients are shrunk and biased, so interpret them as relative importance,
  not exact effects.
- What does a λ_min this close to 0 tell you about the need for regularisation here? How much
  test accuracy do you lose with λ_1se? (See Part 7.)
- The grid had to reach 10⁻⁵. With a grid starting at 10⁻³, λ_min would sit at the edge of
  the grid, which means the grid is too narrow. Always check this in the CV plot.
- Ridge vs. PCR: both shrink, but in different ways. PCR sets the low-variance directions
  to exactly 0. Ridge shrinks them smoothly, and more strongly the smaller their variance is.

## Part 7 – Evaluation: log scale vs. revenue scale (required discussion)

**What the code does:** it computes test-set metrics on the log scale (RMSE, R²) and on
the revenue scale. It back-transforms in two ways:
- **naive:** `exp(pred)`, which estimates the *median* revenue given x;
- **smearing:** `exp(pred) × mean(exp(training residuals))` (Duan, 1983), which estimates
  the *mean* revenue given x.

It also breaks down the revenue-scale error by classification, and plots observed against
predicted log revenue.

| Model | RMSE log | R² log | RMSE rev (naive, M$) | RMSE rev (smearing, M$) |
|---|---|---|---|---|
| PCR (3 PCs + dummies) | **0.425** | **0.916** | 9.06 | 8.68 |
| Ridge λ_min | 0.447 | 0.907 | **8.78** | **8.43** |
| Ridge λ_1se | 0.456 | 0.903 | 9.38 | 8.73 |

**Discussion points**
1. **Jensen's inequality:** E[revenue] = E[exp(log revenue)] > exp(E[log revenue]). Plain
   `exp()` therefore underestimates the mean revenue. The smearing factor is about 1.06–1.07
   here, and it lowers the dollar RMSE for every model.
2. **The scale changes what you optimise.** An error of 0.1 on the log scale is about a 10%
   error, whatever the size of the program. On the revenue scale, squared errors are dominated
   by the largest programs: **the 7 FBS schools in the test set (3.5%) cause 32% of the total
   absolute error**, and all NCAA Division I schools together cause 62%.
3. **The model ranking changes:** PCR is best on the log scale, while ridge λ_min is best on
   the revenue scale. The models were fitted to minimise log errors, so they are not optimal
   for dollar errors.
4. Which metric fits the client? An association with programs of every size probably cares
   about *relative* errors, so the log RMSE makes sense. For budget totals, the dollar error
   (with the smearing correction) matters.
5. The differences between the models are small compared with the error itself. Would another
   random split change the ranking?

## Part 8 – Predictions for the 10 institutions

**What the code does:** it predicts the 10 institutions with the **same models** that were
evaluated on the test set: the training PCA and PCR, and ridge at λ_min. The new schools are
projected on the training PCA and standardised with the training means and sds. It reports a
*median-type* revenue (`exp`) and a *mean-type* revenue (smearing), in million USD.

| id | Classification | PCR (median / mean, M$) | Ridge (median / mean, M$) |
|---|---|---|---|
| 1 | NCAA D-I FBS | 115.2 / 123.7 | 142.3 / 151.2 |
| 2 | NCAA D-I FCS | 17.7 / 19.0 | 18.5 / 19.7 |
| 3 | NCAA D-I without football | 11.6 / 12.5 | 10.1 / 10.8 |
| 4 | NCAA D-II with football | 10.5 / 11.2 | 9.3 / 9.9 |
| 5 | NCAA D-II without football | 4.7 / 5.0 | 3.6 / 3.8 |
| 6 | NCAA D-III with football | 3.5 / 3.7 | 3.2 / 3.4 |
| 7 | NCAA D-III without football | 3.7 / 4.0 | 4.1 / 4.3 |
| 8 | NAIA D-I | 1.7 / 1.8 | 1.7 / 1.8 |
| 9 | NJCAA D-I | 2.2 / 2.3 | 2.7 / 2.9 |
| 10 | CCCAA | 4.4 / 4.7 | 4.7 / 5.0 |

**Guiding questions**
- Are the predictions plausible? Institution 1 has a very high head-coach salary for men's
  teams (2.3M); ridge uses that variable directly (+0.24 per sd) and predicts more than PCR,
  where salaries are only part of the components. Institution 10 is a CCCAA school with a
  57-player football team and 50+49 assistant coaches, far above the CCCAA median revenue of
  1.5M. A sanity check like this is worth one sentence in the report.
- Use the training models (as here), or refit on all 1000 institutions? Here we keep the
  models whose test performance we reported. Refitting would use 20% more data, but its
  performance is not measured.
- Which number do you report: the median-type or the mean-type prediction? Say why.

---

## Common questions about the code

- **`revenue / 1e6`:** `1e6` = 1,000,000. Dividing by it puts the x-axis in million USD; the
  data stay unchanged.
- **`bins = 50`:** the histogram splits the range into 50 equal-width bars (about 5.8M USD each
  for revenue, about 0.2 for log revenue). `fill` is the bar colour, `color` the outline.
- **`grep("^partic_", names(athletics), value = TRUE)`:** returns all column names that start
  with `partic_` (`^` = "starts with"). `value = TRUE` returns the names, not their positions.
- **`model.matrix(...)[, -1]`:** turns the factors into dummy columns; `[, -1]` drops the
  intercept column, because glmnet adds its own.
- **`princomp(..., cor = TRUE)`:** PCA on the correlation matrix, as in the lecture. The
  components are called `Comp.1`, `Comp.2`, … in the output.
- **Bugs fixed in our first draft of the cleanup chunk:**
  - `logged_vars()` wrote to `d[[v]]` instead of `x[[v]]`, which gives the error "object 'd'
    not found".
  - The factor lines changed `prediction` instead of `prediction_new`.
  - `logged_vars()` was defined but never applied.
  - `setwd()` inside a chunk is reset after that chunk, so it was removed.

## Things you may want to change
- **Number of PCs:** the line `n_pc <- k_perm` in the PCA chunk (Part 4c). With 5 PCs (the
  bootstrapped Kaiser rule), rerun and compare.
- **Repeated CV for ridge:** the penalized regression lecture uses `caret::train` with
  repeated 10-fold CV (`trainControl(method = "repeatedcv", number = 10, repeats = 5)`). This
  is an option if the chosen λ changes a lot between seeds.
- **Rare levels:** merge NCCAA Division I (2 schools) and Independent (7) into "Other", and
  the two small sectors as well, if you think their dummies are unstable.
- **Report structure** (as in Assignment 1): Introduction → Data (NaN treatment, log
  transformation) → Methods (PCA with the permutation test and bootstrap; PCR; ridge;
  back-transformation) → Results → Discussion/Conclusion. Tables of loadings, coefficients and
  bootstrap CIs go in the appendix.

---

## Sources
- US Department of Education, EADA data: [ope.ed.gov/athletics](https://ope.ed.gov/athletics/#/)
- Official EADA instructions, Total Revenues screen: [surveys.ope.ed.gov (inst_1.pdf)](https://surveys.ope.ed.gov/athletics2025/wwwroot/documents/inst_1.pdf)
- Example EADA survey forms quoting the instructions (unduplicated count, first scheduled
  contest, salary definitions, volunteers): [Linfield University 2024](https://linfield.edu/assets/files/sports/2024-EADA-Survey.pdf),
  [DePauw University 2021](https://depauw.edu/files/resources/2021-eada-survey.pdf),
  [Rollins College 2021](https://rpublic.rollins.edu/sites/IR/Athletic%20Information/2021%20EADA%20Survey%20.pdf)
- Revenue structure (team revenue + "not allocated" revenue = grand total):
  [University of Oklahoma 2025 report](https://soonersports.com/documents/download/2026/2/16/EADA_FY25.pdf),
  [Harrisburg University 2024–25 report](https://www.harrisburgu.edu/wp-content/uploads/2024-2025-EADA-Report.pdf)
