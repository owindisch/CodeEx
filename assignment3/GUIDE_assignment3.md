# Assignment 3 – Revenue of US college athletics programs: step-by-step guide

There are two versions of the same code. Both give exactly the same results:

| File | Use it for |
|---|---|
| `assignment3/assignment3_code.Rmd` | **The report.** Code chunks with our own variable names (`athletics_new`, `prediction_new`, `fixed_coaches()`, …). Put the `.Rmd` in the same folder as `data_783996yw.csv` and `predictions-2.csv`; no `setwd()` is needed. Plots are stored as objects (`revenue`, `logrevenue`, `scree`, …) and printed. |
| `assignment3/assignment3_revenue.R` | A standalone script (run with `Rscript assignment3/assignment3_revenue.R`, about 25 s). It saves the figures to `assignment3/figures/`. It uses the older names (`dat`, `fix_structural()`, …). |

Both write the 10 predictions to `predictions_output.csv`.

**Names in the `.Rmd`**

| Object | What it is |
|---|---|
| `athletics` | The 1000 institutions, as loaded (never changed) |
| `prediction` | The 10 institutions from `predictions-2.csv`, as loaded |
| `athletics_new`, `prediction_new` | After `fixed_coaches()`, factors and `logged_vars()` |
| `fixed_coaches()` | No coaches (NaN) → count 0 and salary 0 |
| `logged_vars()` | `log1p()` of the counts and salaries |
| `train_data`, `test_data` | 80/20 split of `athletics_new`, after `impute()` |
| `full_data` | All of `athletics_new` after `impute()`, for the final predictions |
| `revenue`, `logrevenue`, `classifications`, `scree`, `permutation`, `kaiserboot`, `biplot_pca`, `observed_predicted` | The ggplot figures |

The parts below follow the code. Each part has **what the code does**, **guiding questions**
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

**What the code does:** it reads the data (1000 × 32) and `predictions.csv` (10 × 31), counts
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

**What the code does:** a seeded 80/20 split (800/200). It computes the imputation medians
on the training set only and applies them to `train_data`, `test_data` and `prediction_new`.
A `stopifnot()` check confirms that no NA is left. It then prints the correlations of each
predictor with log revenue.

**Where the NAs go**

| Step | Object | NAs left? |
|---|---|---|
| Load | `athletics` | Yes, all |
| `fixed_coaches()` + `logged_vars()` | `athletics_new` | Yes, the 16 salaries |
| Split | `train_data`, `test_data` | Yes, the 16 salaries |
| `impute()` | `train_data`, `test_data`, `prediction_new` | **No** |
| `impute(athletics_new)` | `full_data` (Part 8) | No |

`athletics_new` itself keeps the 16 NAs. For plots or correlations on all data, use
`full_data` or `na.rm = TRUE`.

**Guiding questions**
- Are all classification levels in the training set? (Yes with seed 123. Check yours.)
- Which predictors correlate most with log revenue? Here: athletes_women 0.81,
  hc_salary_men 0.78, and the coaching counts about 0.74. `hc_female_share` (0.13) is
  almost unrelated.
- Why are spending variables (salaries, coaches) so strongly correlated with revenue? Use the
  EADA rule that revenue must cover expenses.
- Many predictors correlate strongly with each other (size). Why does that motivate PCA
  and ridge regression rather than OLS? (Think back to Assignment 1.)

## Part 4 – PCA (the main extra requirement)

PCA runs on the **28 numerical predictors**, standardised (`scale. = TRUE`), on the training
data. Revenue and the dummies are left out: revenue because PCA must use the predictors only,
the dummies because PCA on 0/1 variables is hard to interpret.

### 4a. The four simple criteria

**Note:** check your lecture slides for the exact four criteria. The script uses the usual ones.

| Criterion | Number of PCs |
|---|---|
| Kaiser (eigenvalue > 1) | 6 |
| Jolliffe (eigenvalue > 0.7) | 9 |
| 80% cumulative VAF | 7 |
| Scree plot elbow (`scree`) | ≈ 2–3 (λ₁ = 13.8, λ₂ = 2.8, λ₃ = 1.6, then flat around 1) |

**Guiding questions:** Do the criteria agree? Why is Kaiser close to arbitrary here?
PCs 4–6 have eigenvalues of 1.2, 1.1 and 1.0, so they sit right at the threshold.

### 4b. Permutation test

**What the code does:** it permutes every column independently 1000 times. This destroys the
correlations but keeps each variable's distribution. It runs a PCA on each permuted dataset
and compares the observed VAF of each PC with the 95th percentile of the permuted VAFs.

**Guiding questions**
- What is H₀ for component *j*? (It explains no more variance than a component from
  uncorrelated data with the same marginal distributions.)
- Why is the test stricter than Kaiser? Even with zero correlation, the first eigenvalues of
  a sample are larger than 1 by chance. Kaiser ignores this.

**Result:** PCs 1–3 are significant (p < 0.001). PC4 is not: its VAF is 0.043, below the
null's 95th percentile of 0.045 (p = 0.93). **→ 3 PCs.**

### 4c. Bootstrap of Kaiser's rule and of the VAF

**What the code does:** 1000 bootstrap samples of the training rows. It reruns the PCA on
each one, stores the eigenvalues, and builds percentile CIs.
- *Kaiser:* a PC counts as significant when the **lower** bound of its 95% CI is above 1.
- *VAF:* it builds a CI for the variance explained by the chosen number of PCs, and one for
  each PC.

**Results**
- Eigenvalue CIs: PC4 [1.14, 1.44] and PC5 [1.02, 1.22] are above 1. PC6 [0.92, 1.08]
  contains 1. **→ the bootstrapped Kaiser rule gives 5 PCs.**
- The VAF of 3 PCs is 65.0%, with a 95% CI of [63.8%, 67.0%]. PC1 alone explains 49.4%
  [47.9%, 51.1%].

**Guiding questions**
- Why do the permutation test (3) and the bootstrapped Kaiser rule (5) disagree? They test
  different nulls. Kaiser asks whether a PC is worth more than one variable. The permutation
  test asks whether a PC is more than chance structure. With 28 variables, a "variable's worth"
  is 1/28 = 3.6%, and that threshold is lower than the chance level.
- The bootstrap eigenvalues of the leading PCs are biased upward (resampling duplicates rows).
  Does that matter for a borderline PC like PC5?
- Which number do you choose, and why? The script uses **3** (`n_pc <- k_perm`). You can
  change that line.

### 4d. Naming the components

**What the code does:** it prints the loadings, the variable–PC correlations
(loading × sd of the PC) and the communalities (the share of each variable explained by the
chosen PCs). It also draws a biplot coloured by classification (`biplot_pca`).

**Suggested interpretation (check it against your own loadings and biplot):**

| PC | VAF | Loadings | Possible name |
|---|---|---|---|
| PC1 | 49% | All loadings positive. Correlations 0.85–0.94 with athletes, teams and coaches | **Program size / scale** |
| PC2 | 10% | + teams, men's soccer, head coaches. − enrollment, all salaries, full-time share | **Breadth of sports vs. professionalisation (pay per coach)** |
| PC3 | 6% | + enrollment, track, other sports, female head-coach share. − basketball, baseball, softball, assistant salaries | **Large-campus Olympic sports vs. small-college team sports** |

**Guiding questions**
- Which variables are badly explained by 3 PCs? `hc_female_share` has a communality of 0.13,
  `partic_football` 0.36 and `partic_baseball` 0.39. Is it a problem that football, the main
  revenue driver at FBS schools, is poorly represented?
- In the biplot, do the divisions (FBS, NCAA III, NJCAA) form visible clusters?

## Part 5 – Principal component regression

**What the code does**
- **Variant A:** `pls::pcr(log_revenue ~ ., scale = TRUE, validation = "CV")` on the 28
  numerical predictors, evaluated at `n_pc` and at the CV-optimal number of components.
- **Variant B:** `lm(log_revenue ~ PC1 + PC2 + PC3 + classification + sector)`. The PC scores
  come from the training PCA, and the test scores are projected with that same PCA.

**Guiding questions**
- CV is lowest at about 11–12 components, while the PCA criteria say 3. Why? PCA never looks
  at revenue: the directions with the most variance in X are not necessarily the directions
  that predict y. This is the classic weakness of PCR (and the motivation for PLS).
- Why should the dummies enter separately rather than through the PCA?
- Variant B has R² = 0.945 on the training data. Compare it with Variant A.

## Part 6 – Ridge regression

**What the code does:** `cv.glmnet(alpha = 0, nfolds = 10)` on all 28 numerical predictors
plus the classification and sector dummies. It plots the CV curve and the coefficient paths,
and prints a coefficient table at both λ values.

**Results:** λ_min = 0.126 and λ_1se = 0.612. The largest coefficients are the classification
dummies (FBS +1.40, D-I without football +0.80, FCS +0.68 relative to CCCAA; NCAA III and
NJCAA III negative), then `hc_fulltime_share` (+0.39), followed by the log salaries and the
coach counts.

**Guiding questions**
- Why standardise? (`glmnet` does it by default.) Remind the reader with your Assignment 1
  argument.
- The coefficients are on log scale. A dummy coefficient of 1.40 means about
  exp(1.40) ≈ 4× the revenue of the reference group, *holding the other variables fixed*.
  Ridge coefficients are shrunk and biased, so interpret them as relative importance, not
  exact effects.
- How much test accuracy do you lose with λ_1se? See Part 7.
- Ridge vs. PCR: both shrink, but in different ways. PCR sets the low-variance directions
  to exactly 0. Ridge shrinks them smoothly, and more strongly the smaller their variance is.

## Part 7 – Evaluation: log scale vs. revenue scale (required discussion)

**What the code does:** it computes test-set metrics on the log scale (RMSE, MAE, R²) and on
the revenue scale. It back-transforms in two ways:
- **naive:** `exp(pred)`, which estimates the *median* revenue given x;
- **smearing:** `exp(pred) × mean(exp(training residuals))` (Duan, 1983), which estimates
  the *mean* revenue given x.

It also breaks down the revenue-scale error by classification.

| Model | RMSE log | R² log | RMSE rev (naive, M$) | RMSE rev (smearing, M$) | MdAPE |
|---|---|---|---|---|---|
| PCR, 3 PCs | 0.665 | 0.835 | 19.7 | 16.7 | 44% |
| PCR, CV-optimal ncomp | 0.581 | 0.874 | 17.8 | 15.3 | 35% |
| **PCR (3 PCs) + dummies** | 0.462 | 0.920 | **10.2** | **9.3** | **23%** |
| **Ridge λ_min** | **0.458** | **0.922** | 10.9 | 9.7 | 26% |
| Ridge λ_1se | 0.487 | 0.911 | 15.4 | 13.9 | 29% |
| Null (mean) | 1.641 | 0 | 34.4 | 32.9 | 87% |

**Discussion points**
1. **Jensen's inequality:** E[revenue] = E[exp(log revenue)] > exp(E[log revenue]). Plain
   `exp()` therefore underestimates the mean revenue. The smearing factor is about 1.07–1.22
   here. Larger residual variance means a larger correction.
2. **The scale changes what you optimise.** An error of 0.1 on the log scale is about a 10%
   error, whatever the size of the program. On the revenue scale, squared errors are dominated
   by the largest programs: **13 FBS schools (6.5% of the test set) cause 59% of the total
   absolute error.**
3. **The model ranking changes:** Ridge λ_min is best on the log scale, while PCR + dummies
   is best on the revenue scale. The models were fitted to minimise log errors, so they are
   not optimal for dollar errors.
4. Which metric fits the client? An association with programs of every size probably cares
   about *relative* errors, so the log RMSE or a median absolute percentage error makes sense.
   For budget totals, the dollar error (with the smearing correction) matters.
5. Optional: plot the error by revenue decile, as in Assignment 2 Q14.

## Part 8 – Predictions for the 10 institutions

**What the code does:** it refits both final models on all 1000 institutions, keeping the
tuning choices from the training stage (`n_pc` = 3 and λ_min). It applies the same
preprocessing to `predictions.csv` and reports log predictions, a *median-type* revenue
(`exp`) and a *mean-type* revenue (smearing).

| id | Classification | PCR + dummies (median / mean, M$) | Ridge (median / mean, M$) |
|---|---|---|---|
| 1 | NCAA D-I FBS | 113.8 / 122.9 | 116.6 / 125.4 |
| 2 | NCAA D-I FCS | 18.0 / 19.4 | 18.3 / 19.7 |
| 3 | NCAA D-I without football | 11.5 / 12.4 | 10.5 / 11.3 |
| 4 | NCAA D-II with football | 10.4 / 11.2 | 9.4 / 10.1 |
| 5 | NCAA D-II without football | 4.8 / 5.2 | 3.6 / 3.9 |
| 6 | NCAA D-III with football | 3.5 / 3.8 | 3.4 / 3.6 |
| 7 | NCAA D-III without football | 3.7 / 4.0 | 4.1 / 4.4 |
| 8 | NAIA D-I | 1.6 / 1.7 | 1.6 / 1.7 |
| 9 | NJCAA D-I | 2.1 / 2.3 | 2.9 / 3.1 |
| 10 | CCCAA | 4.6 / 4.9 | 5.5 / 5.9 |

**Guiding questions**
- Are the predictions plausible? Institution 10 is a CCCAA school with a 57-player football
  team and 50+49 assistant coaches, far above the CCCAA median revenue of 1.5M. Institution 5
  has very low coach salaries for D-II. A sanity check like this is worth one sentence in the
  report.
- Refit on all data, or keep the training-only model? Defend your choice.
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
- **`biplot_pca`, not `biplot`:** `biplot` is already a base R function.
- **Bugs fixed in our first draft of the cleanup chunk:**
  - `logged_vars()` wrote to `d[[v]]` instead of `x[[v]]`, which gives the error "object 'd'
    not found".
  - The factor lines changed `prediction` instead of `prediction_new`.
  - `logged_vars()` was defined but never applied.
  - `setwd()` inside a chunk is reset after that chunk, so it was removed.

## Things you may want to change or add
- **Number of PCs:** the line `n_pc <- k_perm` in the PCA chunk (Part 4c). With 5 PCs (the bootstrapped
  Kaiser rule), rerun and compare.
- **Rare levels:** merge NCCAA Division I (2 schools) and Independent (7) into "Other", and
  the two small sectors as well, if you think their dummies are unstable.
- **OLS benchmark:** add `lm(log_revenue ~ ., ...)` as a reference, as in Assignment 2.
- **Report structure** (as in Assignment 1): Introduction → Data (NaN treatment, log
  transformation) → Methods (PCA plus criteria, permutation test, bootstrap; PCR; ridge;
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
