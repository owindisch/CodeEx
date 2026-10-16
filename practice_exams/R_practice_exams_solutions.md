# R Practice Exams: Solutions

Each answer has a short explanation, because the explanations are what you need to learn for the exam. The answers were worked out by hand. Running the code yourself is good practice.

---
---

# The Original Practice Exam

## 1. Starwars
| | Code | Answer | Why |
|---|---|---|---|
| A | `length(starwars)` | `9` | A data.frame/data.table is a **list of columns**, so `length()` counts columns, not rows. |
| B | `names(starwars)` | `"name" "height" "mass" "skin_color" "eye_color" "birth_year" "gender" "homeworld" "species"` | |
| C | `typeof(starwars[,2])` | `"list"` | **Trap!** On a `data.table`, `[,2]` returns a one-column data.table, which is a list. On a plain data.frame, `df[,2]` drops to the vector, and the answer would be `"integer"`. |
| D | `levels(starwars$gender)` | `NULL` | `gender` is `chr`, not a factor, so it has no levels. |

## 2. RMarkdown
```yaml
---
title: "Exam"
author: "Eager Student"
output:
  pdf_document:
    toc: true
    toc_depth: 2
    number_sections: true
---
```
Mistakes, covering both versions of the file you posted:
- **The setup chunk is not closed.** The ```` ``` ```` after `knitr::opts_chunk$set(echo = TRUE)` is missing.
- **`echo = false`** must be `FALSE`, because R is case-sensitive. Since `include = FALSE` already hides everything, `echo` could also simply be deleted.
- **The `str(airports_merged)` chunk is not closed.** Without the closing fence, the following text sentence would be run as R code.
- **Duplicate chunk label `airports`** (only in the longer version). knitr stops with *"Duplicate chunk label"*, so rename one of the chunks.
- **Wrong chunk order** (only in the longer version). The `ggplot()` chunk comes before the chunk that loads `ggplot2`/`maps` and creates `airports_merged_sub`.

## 3. draw_curve()
```r
draw_curve()                              # Plot A: defaults, sin, red, type "h"
draw_curve(type = "l")                    # Plot B: red line
draw_curve(col = "blue", type = "both")   # Plot C: blue "h" lines plus red line (lwd 2)
```
In plot C, the vertical lines are blue because `col = "blue"`. The thick line is still red because `lines(..., col = 'red')` is hard-coded.

## 4. Medians
```r
med <- function(x){
  x <- sort(x)
  # For even number of elements
  if((length(x) %% 2) == 0){
    (x[length(x)/2] + x[length(x)/2 + 1]) / 2
  }
  # For odd number of elements
  else{
    x[(length(x) + 1) / 2]
  }
}

trim.med <- function(x){
  if(length(x) <= 2){
    return(med(x))
  }
  med(sort(x)[-c(1, length(x))])
}

mad <- function(x) {
  if(length(x) < 2) stop("x is not a vector!")
  med(abs(x - med(x)))
}
mad(4:8)   # 1  (deviations 2 1 0 1 2, median 1)
```
Your own `mad()` masks `stats::mad()` in the workspace.

## 5. City Temperatures
```r
my.var <- function(x) {
  n <- length(x)
  if (n < 2) stop("x must have at least 2 elements!")
  sum((x - mean(x))^2) / (n - 1)
}

my.cv <- function(x) {
  if (length(x) < 2) stop("x is not a vector!")
  sqrt(my.var(x)) / mean(x) * 100
}

apply(citytemps, 1, my.cv)   # MARGIN = 1, so one CV per city (row)
```
The result is a named numeric vector with one value per city. Berlin and Vienna have the largest CVs, because their winter means are close to 0.

## 6. Penguins
- **A.)** `mutate()` creates `b_length` and `f_length`, but `summarize()` uses `bill_length` and `flipper_length`. Use `mean(b_length)` and `mean(f_length)`. Add `na.rm = TRUE`, because otherwise the result is `NA`.
- **B.)** The **`%>%` is missing after `select(...)`**. `arrange(species)` then runs on its own as a separate command, where `species` does not exist.
- **C.)** `count()` is a data-frame function. Inside `summarize()`, use **`n()`**: `total = n()`.
- **D.)** Several response variables must be combined with **`cbind()`**, not `c()`: `cbind(bill_length_mm, flipper_length_mm) ~ species + island`. `c()` glues the two columns into one vector that is twice as long, hence *"variable lengths differ"*.

Boxplot:
```r
boxplot(body_mass_g ~ species + sex, data = penguins, xlab = "")
boxplot(res$fitted.values ~ species + sex, data = na.omit(penguins),
        border = "red", outline = FALSE, add = TRUE)
legend("topleft", "model predictions", col = "red", lwd = 2)
```
`lm()` drops the 11 rows with missing values, so `res$fitted.values` has 333 elements. That is why the second boxplot needs `na.omit(penguins)`, which also has 333 rows. Each red box is a single line because the model predicts **one** value per species–sex group.

## 7. Data Vectors
- **A.)** Only the first date satisfies `<= "2023-06-18"`, so the result is `[1] "2023-06-18" "2023-06-18"`.
- **B.)** `factor(days, ordered = TRUE)` sorts the levels **alphabetically**: Monday < Sunday < Thursday < Tuesday < Wednesday. The result is `[1] Monday Wednesday` followed by `Levels: Monday < Sunday < Thursday < Tuesday < Wednesday`.
- **C.)** The order comes from `levels`, not from the alphabet: W < S < E < N.
  - With the given data, `c("North","East","South","South")` actually prints as `N E S S`, so `range()` is `[1] S N` (`Levels: W < S < E < N`).
  - If you take the printed `W E S S` from the exam at face value, the answer is `[1] W E`.

## 8. Coercion
(The example has a typo: `ec <- ...` should be `vec <- ...`.)

| | `typeof` | Why |
|---|---|---|
| A | `"character"` | Character + integer → character (`"2"`). |
| B | `"double"` | `TRUE` becomes `1`. |
| C | `"integer"` | Logical + integer → integer. |
| D | `"character"` | A factor is an integer code with labels. Assigning it into a character vector stores the **code** as text (`"1"`), not `"A"`. The type stays character. |

---
---

# Exam 1

## 1. Pokémon
| | Answer | Why |
|---|---|---|
| A | `800` | |
| B | `"list"` | `[, "hp"]` on a data.table returns a data.table. |
| C | `"integer"` | `[[ ]]` extracts the vector. |
| D | `NULL` | `type1` is character. |
| E | `"Poison" "Poison" "Poison" NA` | |

## 2. RMarkdown
```yaml
output:
  html_document:
    toc: true
    toc_depth: 3
    toc_float: true
```
1. `aes(x = attack, y = defense, colour = legendary)`: the closing **`)` of `aes()` is missing**.
2. `eval = True` must be `TRUE`.
3. `` `r nrow(Pokemon)` `` must be `pokemon`, because R is case-sensitive.
4. `message = FALSE warning = FALSE` is **missing a comma**.

## 3. draw_curve()
```r
draw_curve(fun = sin, col = "red", type = "h")                  # A
draw_curve(type = "p")                                          # B
draw_curve(fun = sqrt, from = 0, to = 10, col = "darkgreen")    # C
draw_curve(fun = sin, length.out = 10, col = "red", type = "dots")  # D
```

## 4. Means
```r
my.mean <- function(x){
  total <- 0
  for(v in x){
    total <- total + v
  }
  total / length(x)
}

trim.mean <- function(x, k = 1){
  if(length(x) <= 2 * k) stop("k is too large!")
  x <- sort(x)
  my.mean(x[(k + 1):(length(x) - k)])
}

geo.mean <- function(x) {
  if(any(x <= 0)) stop("all values must be positive!")
  exp(my.mean(log(x)))
}
```
Check: `trim.mean(c(100, 1, 2, 3, -50))` sorts to `-50 1 2 3 100`, keeps `1 2 3`, and returns `2`.

## 5. Exam Scores
```r
my.sd <- function(x) {
  n <- length(x)
  if (n < 2) stop("x must have at least 2 elements!")
  sqrt(sum((x - mean(x))^2) / (n - 1))
}

my.se <- function(x) {
  my.sd(x) / sqrt(length(x))
}

apply(scores, 2, my.se)     # a) MARGIN = 2, columns (subjects)
apply(scores, 1, my.mean)   # b) MARGIN = 1, rows (students)
```
c) `dim(scores)` is `5 4`. The result in a) has length **4**, named `Math Stats Programming English`.

## 6. Fuel Economy
- **A.)** The column is called `cty_kml`, not `cty_kmpl`.
- **B.)** `filter(year = 2008)` uses an assignment. A comparison needs `==`.
- **C.)** `n` is a function. Call it: `total = n()`.
- **D.)** `select()` dropped `cty`, so `arrange()` cannot sort by it. Add `cty` to `select()`, or arrange before selecting.

lm:
- a) `length(res$coefficients)` is **3**: `(Intercept)`, `drvf` and `drvr`. The level `"4"` is the reference. `length(res$residuals)` is **234**, because there are no NAs.
- b)
  ```r
  boxplot(hwy ~ drv, data = mpg, xlab = "drive train")
  boxplot(res$fitted.values ~ drv, data = mpg,
          border = "blue", outline = FALSE, add = TRUE)
  legend("topright", "model predictions", col = "blue", lwd = 2)
  ```
- c) With only `drv` as predictor, the model predicts the **same value (the group mean)** for every car in a group, so each blue "box" has zero width.

## 7. Data Vectors
- **A.)** `range(dates)` is `"2024-02-28" "2024-03-03"`. `diff(range(dates))` is `Time difference of 4 days`, because 2024 is a leap year and Feb 29 counts.
- **B.)** **Error:** `'range' not meaningful for factors`. Unordered factors have no order.
- **C.)**
  - `range(sizes)` gives `[1] S XL` with `Levels: S < M < L < XL`.
  - `sizes > "M"` gives `FALSE TRUE FALSE FALSE`.
  - `table(sizes)` gives `S 1, M 2, L 0, XL 1`. Unused levels still appear.
- **D.)** `"Apple" "cherry"`. Character vectors are compared alphabetically.

## 8. Coercion
| | Answer |
|---|---|
| A | `"double"` (the integer is converted to double) |
| B | `"double"` |
| C | `"character"` |
| D | `"integer"`, and `D` is `1 2 3 NA 10`. Assigning beyond the end fills the gap with `NA`. |
| E | `"character"` (`NA` adapts to the vector type) |

---
---

# Exam 2

## 1. Titanic
| | Answer | Why |
|---|---|---|
| A | `8` | Number of columns. |
| B | `NA` | `age` contains `NA`. Use `na.rm = TRUE`. |
| C | `3 1 2` | Order of first appearance. |
| D | `"integer"` | A bare column name in `j` returns a vector. |
| E | `"C" "S"` | Only values that occur become levels, sorted alphabetically. |

## 2. RMarkdown
```yaml
---
title: "Titanic Analysis"
author: "Eager Student"
date: "`r Sys.Date()`"
output:
  pdf_document:
    toc: true
    toc_depth: 1
---
```
1. `fig.cap = Survival rate per class` needs quotes.
2. **Wrong order**: the plot chunk uses `ggplot` and `rates` before `load-data` has run.
3. `fread("titanic.csv)` is missing its closing quote.
4. **Duplicate chunk label `load-data`.**

The inline sentence shows `NA` because `age` contains missing values. Use `` `r round(mean(titanic$age, na.rm = TRUE), 1)` ``.

## 3. draw_points()
```r
draw_points()                                                          # A
draw_points(fun = exp, from = 0, to = 3, col = "darkorange", pch = 19)   # B
draw_points(by = 0.25, col = "purple", pch = 17, line = TRUE)          # C
```
`seq(0, 10, by = 2)` gives `0 2 4 6 8 10`, which is **6 points**.

## 4. Cumulative Sums and Maxima
```r
my.cumsum <- function(x){
  out <- numeric(length(x))
  out[1] <- x[1]
  for(i in 2:length(x)){
    out[i] <- out[i - 1] + x[i]
  }
  out
}

my.which.max <- function(x){
  pos <- 1
  for(i in seq_along(x)){
    if(x[i] > x[pos]){
      pos <- i
    }
  }
  pos
}

normalize <- function(x){
  if(max(x) == min(x)) stop("all values are equal!")
  (x - min(x)) / (max(x) - min(x))
}
```
- `my.cumsum()` breaks for a vector of length 1, because `2:1` is `c(2, 1)`. `seq_len(length(x))[-1]` is safer.
- `my.which.max()` uses `>` rather than `>=`, so it keeps the **first** maximum.

## 5. Step Counts
```r
my.sd <- function(x) {
  n <- length(x)
  if (n < 2) stop("x must have at least 2 elements!")
  sqrt(sum((x - mean(x))^2) / (n - 1))
}

my.zscore <- function(x) {
  if (length(x) < 2) stop("x is not a vector!")
  (x - mean(x)) / my.sd(x)
}

apply(steps, 1, my.sd)          # c)
t(apply(steps, 1, my.zscore))   # d)
```
- d) `apply(steps, 1, my.zscore)` returns a **7 × 4** matrix. `apply()` always puts each function result (one vector of 7 values per person) **in a column**, so rows are days and columns are persons. `t()` turns it back into 4 × 7.
- e) **Dana** has the same number of steps every day, so `my.sd()` is 0. The z-scores are `0/0`, which is `NaN`. There is no error message, just `NaN`s.

## 6. Diamonds
- **A.)** `Ideal` is a value, not an object, so it needs quotes: `cut == "Ideal"`.
- **B.)** After `summarize()`, only `cut` and `M.price` exist. Use `arrange(desc(M.price))`.
- **C.)** Layers are added with **`+`**, not `%>%`: `ggplot(aes(...)) + geom_point()`.
- **D.)** `select()` dropped `cut`. Use `select(carat, price, cut)`.

lm:
- a) `res$fitted.values` has **53940** elements. `res$coefficients` has **6**: the intercept, `carat`, and 4 for `cut` (5 levels − 1). Because `cut` is *ordered*, they are named `cut.L`, `cut.Q`, `cut.C` and `cut^4` (polynomial contrasts).
- b)
  ```r
  plot(x = res$fitted.values, y = res$residuals, xlab = "fitted values", ylab = "residuals")
  abline(h = 0, col = "red", lwd = 2)
  ```

## 7. Data Vectors
These answers assume an English locale for `weekdays()`.
- **A.)** `dates` is `"2024-12-30" "2024-12-31" "2025-01-01" "2025-01-02"`, so the range is `"2025-01-01" "2025-01-02"`.
- **B.)**
  - `range(f)` gives `[1] Monday Thursday` with `Levels: Monday < Tuesday < Wednesday < Thursday < Friday`.
  - `max(f[f < "Wednesday"])` is `Tuesday`.
- **C.)**
  - `grades` prints as `[1] good excellent fair good` with `Levels: fair < good < excellent`.
  - `range(grades)` is `fair excellent`.
  - `as.integer(grades)` is `2 3 1 2`.
- **D.)** `range(c(10, 2, 33))` is `2 33`. `range(c("10", "2", "33"))` is **`"10" "33"`**, because strings are compared character by character and `"10" < "2" < "33"`.

## 8. Coercion
| | Answer |
|---|---|
| A | `"double"`: `1.0 3.5 1.0` |
| B | `"character"`: `"a" "TRUE" "c"` |
| C | `"integer"` (`NA` is logical and adapts) |
| D | `"double"`: **trap!** `2` without an `L` is a double. |
| E | `"list"`: lists can hold mixed types, so there is no coercion. |
| sum | `sum(x)` gives **Error**: `invalid 'type' (character) of argument`. `sum(as.numeric(x))` gives `6`. |

---
---

# Exam 3

## 1. Spotify
| | Answer | Why |
|---|---|---|
| A | `2000 8` | |
| B | `"factor"` | |
| C | `"integer"` | **Trap!** Factors are stored as integer codes. |
| D | `2019 2017` | Column 3 is `year`. |
| E | A number in [0, 1]: the **share of explicit songs** | The mean of a logical vector is the share of `TRUE`. |

## 2. RMarkdown
```yaml
output:
  word_document:
    toc: true
    toc_depth: 2
```
```r
knitr::opts_chunk$set(echo = FALSE, message = FALSE)
```
1. `library(data.table)` is missing, so `fread()` is not found.
2. `Spotify` must be `spotify`.
3. `geom_boxplot` must be `geom_boxplot()`.
4. `results = hide` must be `results = "hide"`.
5. The `counts` chunk is closed with only two backticks.

## 3. draw_curve()
```r
draw_curve()                                                    # A
draw_curve(col = "red", type = "p", zero = TRUE)                # B
draw_curve(fun = abs, col = "darkgreen", type = "s")            # C
draw_curve(fun = exp, from = 0, to = 1, length.out = 6,
           col = "blue", type = "b")                            # D
```

## 4. Maxima and Top-k
```r
my.max <- function(x){
  current <- x[1]
  for(v in x[-1]){
    if(v > current) current <- v
  }
  current
}

top.k <- function(x, k = 3){
  x <- sort(x, decreasing = TRUE)
  if(k > length(x)){
    return(x)
  }
  x[1:k]
}

my.range.width <- function(x) {
  if(length(x) < 2) stop("x is not a vector!")
  my.max(x) + my.max(-x)     # max(x) - min(x), since min(x) = -max(-x)
}
```

## 5. Stock Prices
```r
pct.change <- function(x) {
  if (length(x) < 2) stop("x must have at least 2 elements!")
  diff(x) / head(x, -1) * 100
}

volatility <- function(x) {
  sd(pct.change(x))
}

apply(stocks, 1, volatility)
```
- c) **Initech** is the most volatile. Its daily moves are about −10 %, +17 %, −7 % and +5 %, compared with about ±2–3 % for the others.
- d) The result is a **4 × 3** matrix. Each row gives 4 changes, and `apply()` puts each result in a column. Row names are `Tue Wed Thu Fri` (from `diff()`), and column names are `ACME Globex Initech`.
- e) `(102 - 100) / 100 * 100` = **2**.

## 6. Star Wars (dplyr)
- **A.)** The column is called `avg`: `pull(avg)`.
- **B.)** A comma is missing after `n()`.
- **C.)** `select()` dropped `homeworld`, which the join needs. Keep it in `select()`.
- **D.)** The first line **overwrites** `height` with the group mean, so `sd()` sees only one value per group, and the sd of a single value is `NA`. Compute `sd` first, or give the mean a different name, for example `M.height`.

lm:
- a) Rows with `NA` in `mass` or `height` are dropped: 87 − 28 = **59** residuals.
- b)
  ```r
  plot(mass ~ height, data = starwars)
  abline(res, col = "red", lwd = 2)
  ```
- c) Use `res$residuals` with `which.max(res$residuals)`. The name of the returned element is the row number in the original data.

## 7. Data Vectors
- **A.)**
  - `range(dates)` is `"2023-11-02" "2024-07-30"`.
  - `diff(range(dates))` is `Time difference of 271 days`.
  - `format(range(dates), "%B")` is `"November" "July"`.
- **B.)** **Error:** `'range' not meaningful for factors`.
- **C.)**
  - `min(level)` gives `[1] low` with `Levels: low < medium < high`.
  - `range(level[level != "low"])` is `medium high`.
- **D.)**
  - `range(c(TRUE, FALSE, TRUE))` is `0 1`, because logicals become integers.
  - `range(numeric(0))` is `Inf -Inf`, with two warnings: *no non-missing arguments to min/max*.

## 8. Coercion
| | Answer |
|---|---|
| A | `"character"` |
| B | `"integer"`, and `B` is `a b c` / `1 2 3`. A new name adds an element. |
| C | First `"logical"`, then `"integer"`. |
| D | `typeof` is `"double"` and `class` is `"Date"`. A date is the number of days since 1970-01-01. |
| E | `as.numeric(E)` is `1 2 1` (the level codes!). `as.numeric(as.character(E))` is `10 20 10`. |

---

## The Most Common Traps

1. `length(df)` counts **columns**. `DT[, 2]` returns a data.table (a list), while `DT[[2]]` returns a vector.
2. `typeof(factor)` is `"integer"`. `levels()` on a character vector is `NULL`. `as.numeric(factor)` gives the codes.
3. Unordered factors have no `range()`/`min()`/`max()`. Ordered factors follow the `levels` order, and `factor()` sorts levels **alphabetically** by default.
4. RMarkdown:
   - `TRUE`/`FALSE` must be in capitals, and string options need quotes.
   - Chunk labels must be unique, and every chunk needs a closing ```` ``` ````.
   - Chunks run top to bottom.
   - YAML options are indented under the output format.
5. dplyr:
   - Column names change after `mutate()`, `summarize()` and `select()`.
   - Use `==` in `filter()`, `n()` (not `n` or `count()`), and `cbind()` for several responses in a formula.
   - Use `+` in ggplot, not `%>%`.
6. `apply(m, 1, f)` works on rows and `apply(m, 2, f)` on columns. If `f` returns a vector, the results become **columns**, so you may need `t()`.
7. Coercion: logical < integer < double < character. `2` is a double, while `2L` is an integer.
8. `lm()` silently drops rows with `NA`, so `fitted.values` and `residuals` can be shorter than the data.
