# R Practice Exams: Solutions (FEM11151)

Every answer comes with a short explanation and a pointer to where it is covered in the course material. The answers were worked out by hand from the reader and lecture notes. Running the code yourself is good practice.

---
---

# The Original Practice Exam

## 1. Starwars
| | Code | Answer | Why |
|---|---|---|---|
| A | `length(starwars)` | `9` | A data frame is a list of columns, so `length()` = `ncol()` (Lecture 2). |
| B | `names(starwars)` | `"name" "height" "mass" "skin_color" "eye_color" "birth_year" "gender" "homeworld" "species"` | |
| C | `typeof(starwars[,2])` | `"list"` | `starwars` is a **data.table**, and `DT[, 2]` returns a data.table (Lecture 6: *"Position index → returns a data.table!"*). On a plain data.frame, the answer would be `"integer"`. |
| D | `levels(starwars$gender)` | `NULL` | `gender` is `chr`, not a factor (Lecture 3). |

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
Mistakes, covering both versions of the file:
- The **setup chunk is not closed**: the ```` ``` ```` is missing.
- **`echo = false`** must be `FALSE`, because R is case-sensitive (Reader). With `include = FALSE`, `echo` is not needed anyway.
- The **`str(airports_merged)` chunk is not closed**, so the following sentence would be run as R code.
- The **chunk label `airports` is used twice** (only in the longer version).
- **Wrong chunk order**: the `ggplot()` chunk runs before the chunk that loads the packages and data (only in the longer version).

## 3. draw_curve()
```r
draw_curve()                              # Plot A (defaults: sin, red, type "h")
draw_curve(type = "l")                    # Plot B
draw_curve(col = "blue", type = "both")   # Plot C
```
In Plot C, the line stays red because `lines(..., col = 'red')` is hard-coded.

## 4. Medians
```r
med <- function(x){
  x <- sort(x)
  if((length(x) %% 2) == 0){
    (x[length(x)/2] + x[length(x)/2 + 1]) / 2
  }
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
```

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

apply(citytemps, 1, my.cv)
```

## 6. Penguins
- **A.)** `mutate()` creates `b_length` and `f_length`, but the code uses `bill_length` and `flipper_length`.
- **B.)** The **`%>%` after `select()` is missing**, so `arrange(species)` runs on its own.
- **C.)** Use **`n()`** inside `summarize()`, not `count()` (Lecture 2).
- **D.)** Several responses need **`cbind()`**: `aggregate(cbind(bill_length_mm, flipper_length_mm) ~ species + island, ...)` (Lecture 2).

```r
boxplot(body_mass_g ~ species + sex, data = penguins, xlab = "")
boxplot(res$fitted.values ~ species + sex, data = na.omit(penguins),
        border = "red", outline = FALSE, add = TRUE)
legend("topleft", "model predictions", col = "red", lwd = 2)
```
`lm()` drops the rows with `NA`, so the fitted values match `na.omit(penguins)`, which has 333 rows.

## 7. Data Vectors
- **A.)** `"2023-06-18" "2023-06-18"`.
- **B.)** The ordered factor gets alphabetical levels, so the result is `[1] Monday Wednesday` with `Levels: Monday < Sunday < Thursday < Tuesday < Wednesday`.
- **C.)** With the given code, `directions` is `N E S S`, so `range()` is `[1] S N` (`Levels: W < S < E < N`). If you go by the printed `W E S S`, the answer is `W E`.

## 8. Coercion
A `"character"` · B `"double"` · C `"integer"` · D `"character"`. The factor is stored as its integer code, so `D[4]` becomes `"1"`, not `"A"`.

---
---

# Exam 1

## 1. Ben & Jerry's
| | Answer | Why |
|---|---|---|
| A | `12` | `length()` of a data frame = number of columns (Lecture 2). |
| B | `NULL` | `$` returns a plain vector, which has no `dim` (Lecture 2). |
| C | `21974 2` | `subset(select = ...)` keeps a data frame. |
| D | `"integer"` | |
| E | `NULL` | Character columns have no levels. |
| F | `"tbl_df" "tbl" "data.frame"` | A **tibble** never drops `[, 6]` to a vector (like a data.table). |
| G | `4` | `2 1 1 NA NA NA NA 1 1 2` contains 4 `NA`s, and `sum()` counts the `TRUE`s from `is.na()`. |

## 2. RMarkdown
```yaml
output:
  pdf_document:
    number_sections: true
    fig_width: 6
    fig_height: 4
    df_print: kable
```
1. The inline code `` `r round(mean(BenAndJerry$total_spent), 2` `` is missing its closing `)`.
2. `fig.align = center` needs quotes: `fig.align = 'center'`.
3. `results = 'hide` is missing its closing quote.
4. `kable()`, `kable_styling()` and `%>%` are not available. Add `library(kableExtra)` to the setup chunk (Lecture 4 Reporting).

## 3. draw_curve()
```r
draw_curve(fun = sin, col = "red", type = "h")                      # A
draw_curve(type = "p")                                              # B
draw_curve(fun = sqrt, from = 0, to = 10, col = "darkgreen")        # C
draw_curve(fun = sin, length.out = 10, col = "red", type = "dots")  # D
```
b) Use `old.par <- par(mfrow = c(1, 4))` to arrange the plots, then `par(old.par)` to switch back (Lecture 4 Visualisation).

c) Add `...` to the argument list (`function(fun = cos, ..., type = "l", ...)`) and pass it on with `plot(x, y, col = col, type = type, ...)`. Then call `draw_curve(fun = sqrt, from = 0, to = 10, col = "darkgreen", main = "Square root", cex = 2)`.

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
| Call | Result |
|---|---|
| `trim.mean(k = 2, x = 1:10)` | `5.5`. Arguments are matched by name, so the order does not matter (Reader). |
| `trim.mean(1:10, 2)` | `5.5`, matched by position. |
| `trim.mean(2, 1:10)` | **Error**: `x = 2`, `k = 1:10`, and `if()` gets a condition of length 10, giving *"the condition has length > 1"*. |
| `foo(10)` | `0.4`. `return(2/5)` ends the function immediately, so `* x` is never evaluated (Lecture 5). |
| `sign(0)` | `"zero"` |
| `sign(c(-1, 1))` | **Error**: *the condition has length > 1*. `if` only takes a single value. |

## 5. Exam Scores
Matrices are filled column by column by default (Reader):
- **A.)**
  ```
       [,1] [,2]
  [1,]    1    4
  [2,]    2    5
  [3,]    3    6
  ```
- **B.)** `B` is filled by row (`1 2 / 3 4 / 5 6`), so `B[3, 1]` = **5**.
- **C.)** `2 3`
- **D.)** Warning: *data length [4] is not a sub-multiple or multiple of the number of columns [3]*. The data is recycled:
  ```
       [,1] [,2] [,3]
  [1,]    1    3    1
  [2,]    2    4    2
  ```

```r
my.sd <- function(x) {
  n <- length(x)
  if (n < 2) stop("x must have at least 2 elements!")
  sqrt(sum((x - mean(x))^2) / (n - 1))
}
my.se <- function(x) {
  my.sd(x) / sqrt(length(x))
}

apply(scores, 2, my.se)                       # a)
apply(scores, 2, mean); colMeans(scores)      # b)
apply(scores, 1, my.mean)                     # c)
```

## 6. Fuel Economy
- **A.)** The column is `cty_kml`, not `cty_kmpl`.
- **B.)** `filter()` needs `==`, not `=`.
- **C.)** `n` must be called: `n()`.
- **D.)** `FUN = mean()` calls `mean` without input. Pass the function itself: `FUN = mean`.

lm:
- a) There are **3** coefficients (`(Intercept)`, `drvf`, `drvr`) and **234** residuals.
- b)
  ```r
  boxplot(hwy ~ drv, data = mpg, xlab = "drive train")
  boxplot(res$fitted.values ~ drv, data = mpg,
          border = "blue", outline = FALSE, add = TRUE)
  legend("topright", "model predictions", col = "blue", lwd = 2)
  ```
- c) With only `drv`, the model predicts one value (the group mean) per drive train.

## 7. Data Vectors
- **A.)**
  - `d` is `"2024-03-14" "2023-12-01"`, so `range(d)` is `"2023-12-01" "2024-03-14"`.
  - `quarters(d)` is `"Q1" "Q4"`.
  - `d[1] - d[2]` is `Time difference of 104 days`, because 2024 is a leap year.
- **B.)**
  - The levels are alphabetical (`"LIGHT" "REGULAR"`), so `as.numeric(fat)` is `2 1 2`.
  - After `relevel()`, `REGULAR` is the first level, so `as.numeric(relevel(fat, ref = "REGULAR"))` is `1 2 1`.
  - `range(fat)` gives **Error**: *'range' not meaningful for factors*, because `fat` is unordered (Lecture 3).
- **C.)** `[1] > 20% fat < 20% fat > 20% fat` with `Levels: < 20% fat > 20% fat`. The levels are renamed in order: LIGHT → "< 20% fat" and REGULAR → "> 20% fat".
- **D.)**
  - `range(sizes)` is `[1] S XL` with `Levels: S < M < L < XL`.
  - `sizes > "M"` is `FALSE TRUE FALSE FALSE`.
  - `table(sizes)` is `S 1, M 2, L 0, XL 1`.

## 8. Coercion
| | Answer |
|---|---|
| A | `"double"` (upwards) |
| B | `"double"` (upwards) |
| C | `"character"` (downwards) |
| D | `"integer"`, and `D` is `1 2 3 NA 10` |
| E | `"character"`: `"0.5" "0.6" "a" "b"` (downwards, as in the Reader's `c(dbl, chr)` example) |

## 9. Indexing and data.table
`x_vec` is `2 4 6 … 20`. `x_mat` has the columns (1,2,3), (4,5,6), (7,8,9) and (10,11,12).

| | Answer | Why |
|---|---|---|
| A | `4 6 8 10 12 14 16 18` | Negative indices drop elements. |
| B | `6 8 10` | |
| C | `FALSE TRUE FALSE TRUE FALSE FALSE FALSE FALSE FALSE FALSE` | |
| D | `8` | A single index treats the matrix as one long vector (column-wise). |
| E | `8` | Row 2, column 3. Here it happens to give the same as D. |
| F | `2 3` | Not the same as `x_mat[2, 3]`! (Lecture 5) |
| G | `2 4` | |
| H | `3` | |
| I | `2 4 5 1 3` | Positions from the smallest to the largest value. |

```r
# a) flights[, origin] gives a vector; flights[, "origin"] and flights[, .(origin)] give a data.table
# b)
flights[, .(delay_dep = dep_delay, delay_arr = arr_delay)]
# c)
flights[(.N - 2):.N]
# d)
flights[carrier == "DL", .N, by = origin][order(-N)]
# e)
flights[origin == "JFK", .(mean_arr = mean(arr_delay)), keyby = month]
```

## 10. Regex and Web Scraping
| | Answer |
|---|---|
| A | `FALSE TRUE TRUE TRUE FALSE` |
| B | `5` (only `"grep vs. grepl"` contains a g) |
| C | `"Room ###"` (each digit is replaced separately) |
| D | `"Room #, floor #"` (`+` matches the whole run of digits) |
| E | `sub()` gives `"f0o boo"` (first match only). `gsub()` gives `"f00 b00"` (all matches). |
| F | A list: `[[1]] "a" "b" "" "c"` |

G) `regmatches(tweet, gregexpr("#[[:alnum:]_]+", tweet))[[1]]`

H) The four `rvest` functions:
1. `read_html()`
2. `html_table()`
3. `html_nodes(".price")`
4. `html_text()`

I) `as.numeric(gsub("[^0-9.]", "", "€ 1,299.00"))` gives `1299`.

---
---

# Exam 2

## 1. Bike Sharing Chicago
| | Answer | Why |
|---|---|---|
| A | `7` | |
| B | `"double"` | A plain **data.frame** drops `[, 5]` to a vector. Compare the data.table and tibble cases! |
| C | `"list"` | Single brackets treat the data frame as a list (Lecture 5). |
| D | `Length 12433  Class character  Mode character` | `summary()` of a character vector (Lecture 3). |
| E | `2 28 4` | |
| F | `-4 0` | |
| G | `"week" "no.customers"` | |

## 2. RMarkdown
```yaml
output:
  html_document:
    toc: true
    highlight: tango
```
You can leave out `toc_depth`, because it **defaults to 3** (Lecture 4 Reporting).

1. `fig.cap = Trip duration per weather event` needs quotes.
2. The plot chunk runs **before** `Chicago.agg` is loaded.
3. `read.csv("Chicago.agg.csv)` is missing its closing quote.
4. The **chunk label `load-data` is used twice.**

The inline sentence shows `NA`, because `temperature` now contains an `NA`. Use `` `r round(mean(Chicago.agg$temperature, na.rm = TRUE), 1)` ``. The LaTeX formula `$...$` is correct.

## 3. draw_points()
```r
draw_points()                                                           # A
draw_points(fun = exp, from = 0, to = 3, col = "darkorange", pch = 19)  # B
draw_points(by = 0.25, col = "purple", pch = 17, line = TRUE)           # C
```
- b) **6** points (0, 2, 4, 6, 8, 10).
- c) `legend("topleft", "x squared", lty = 2, bty = "n")`
- d) `"red"`, `rgb(1, 0, 0)` and `"#FF0000"` (Lecture 4 Visualisation).

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
- A `2` (the sd of 2, 4, 6)
- B `4`
- C `"list"`
- D `-2`
- E `2` (the arguments are matched by position, so they are swapped)
- F `-6` (`vec1` defaults to 0: `sum(0 - c(2, 4))`)

## 5. Step Counts
`M` is `2 1 / 1 3` (filled by column):
- **A.)** `M * M` is elementwise: `4 1 / 1 9`.
- **B.)** `M %*% M` is matrix multiplication: `5 5 / 5 10`.
- **C.)** `det(M)` is `5`.
- **D.)** `solve(M)` is `0.6 -0.2 / -0.2 0.4`.
- **E.)** **Error**: *number of rows of matrices must match (see arg 2)*. `M` has 2 rows, while `rbind(M, M)` has 4.

```r
my.zscore <- function(x) {
  if (length(x) < 2) stop("x is not a vector!")
  (x - mean(x)) / my.sd(x)
}
apply(steps, 1, my.sd)          # c)
t(apply(steps, 1, my.zscore))   # d)
```
- d) The result is **7 × 4**, because `apply()` stores each result as a **column**.
- e) **Dana**: her sd is 0, so all her z-scores are `NaN`.

## 6. Diamonds
- **A.)** The value needs quotes: `cut == "Ideal"`.
- **B.)** `price` no longer exists after `summarize()`. Use `arrange(desc(M.price))`.
- **C.)** Add layers with `+`, not `%>%`.
- **D.)** A comparison needs `==`: `subset = cut == "Ideal"`.

lm:
- a) There are **53940** fitted values and **6** coefficients: the intercept, `carat`, and 4 for `cut`.
- b)
  ```r
  plot(x = res$fitted.values, y = res$residuals, xlab = "fitted values", ylab = "residuals")
  abline(h = 0, col = "red", lwd = 2)
  ```
- c) `aggregate(price ~ cut, data = diamonds, FUN = mean)`

## 7. Data Vectors
These answers assume an English locale for weekday and month names.
- **A.)**
  - `seq()` gives `"2024-01-31" "2024-03-02" "2024-03-31"`. "Feb 31" rolls over to Mar 2.
  - `lubridate` with `%m+%` gives `"2024-01-31" "2024-02-29" "2024-03-31"` (Lecture 3).
- **B.)**
  - `range(f)` is `[1] Monday Thursday` with `Levels: Monday < Tuesday < Wednesday < Thursday < Friday`.
  - `max(f[f < "Wednesday"])` is `Tuesday`.
- **C.)** `Time difference of 696 hours` (29 days × 24).
- **D.)**
  - `grades` is `[1] good excellent fair good` with `Levels: fair < good < excellent`.
  - `range(grades)` is `fair excellent`.
  - `as.integer(grades)` is `2 3 1 2`.

## 8. Coercion
| | Answer |
|---|---|
| A | `"double"`: `1.0 3.5 1.0` |
| B | `"character"`: `"a" "TRUE" "c"` |
| C | `"integer"` |
| D | `"double"`: `2` without `L` is a double |
| E | `"character"`: a matrix is atomic (Reader) |
| sum | `sum(x)` gives **Error**: `invalid 'type' (character)`. `sum(as.numeric(x))` gives `6`. |

## 9. Indexing and data.table
| | Answer | Why |
|---|---|---|
| A | `"list"` | `[ ]` returns a sublist. |
| B | `2` | The matrix is `1 3 / 2 4`. |
| C | `3 4 5` | |
| D | `2` | |
| E | `10 20 30` | Logical indexing on a data frame works like on a matrix. |
| F | `20` | |
| G | `"data.frame"` | `df[2]` is a list-style selection. |

```r
# a)
setDT(flights_df)
# b)
flights[dest %like% "SFO" & month == 3L, .N]
# c)
flights[carrier %chin% c("AA", "UA"), .(mean_dep = mean(dep_delay)), by = carrier]
# d)
flights[arr_delay %between% c(-10, 10), .N]
```
- e) Without `by`, `.N` is the number of rows (of the subset). With `by = origin`, it is the number of rows **per group**.
- f) `keyby` also **sorts** the result by the grouping columns and sets them as key.

## 10. Regex and Web Scraping
| | Answer |
|---|---|
| A | `"Hello World"` |
| B | `"Old New York" "new York"` (only the first match, and case-sensitive) |
| C | `"Old New York" "Old York"` |
| D | `"EUR 100"` (`$` must be escaped with `\\`) |
| E | `"bad cat"` |
| F | `TRUE FALSE TRUE` |
| G | `"East North Central" "West North Central"` |

H) Split on `"\\s+"` (or `"[[:space:]]+"`): `length(strsplit(s, "\\s+")[[1]])`.

I) Scrape This Site:
1. The values alternate: population, area, population, area, …
2. ```r
   pop <- info[seq(1, length(info), by = 2)]
   sum(as.numeric(pop))
   ```

---
---

# Exam 3

## 1. Air Quality
| | Answer | Why |
|---|---|---|
| A | `153 6` | |
| B | `NA` | |
| C | `2` | |
| D | `9 17` | Logical row index and a named column (Lecture 2). |
| E | `"integer"` | integer × integer stays integer. |
| F | `"data.frame"` | |
| G | `5 9` | |

## 2. RMarkdown
```yaml
output:
  word_document:
    toc: true
    toc_depth: 2
```
- Setup chunk: `knitr::opts_chunk$set(echo = FALSE, message = FALSE)`.
- For PowerPoint slides, use `output: powerpoint_presentation`.

1. `%>%` is not available, because only `ggplot2` is loaded. Add `library(dplyr)`, or use `ggplot(airquality, ...)` directly.
2. `geom_boxplot` must be `geom_boxplot()`.
3. `results = hide` must be `results = 'hide'`.
4. `Airquality` must be `airquality`, because R is case-sensitive.
5. The `counts` chunk is closed with only two backticks.

## 3. draw_curve()
```r
draw_curve()                                                 # A
draw_curve(col = "red", type = "p", zero = TRUE)             # B
draw_curve(fun = abs, col = "darkgreen", type = "s")         # C
draw_curve(fun = exp, from = 0, to = 1, length.out = 6,
           col = "blue", type = "b")                         # D
```
b) `par(mfcol = c(2, 2))`

c)
```r
library(ggplot2)
x <- seq(-2, 2, length.out = 41)
df <- data.frame(x = x, y = x^3)
ggplot(df, aes(x = x, y = y)) + geom_line() + theme_classic()
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
  my.max(x) + my.max(-x)
}
```
Loops:
- **A.)** `1 4 9 16`
- **B.)** `y <- x^2`
- **C.)** `1 2 3 / 2 4 6`
- **D.)** `30`. Only the value from the last iteration is kept, which is why you store results in a pre-made vector (Lecture 5).

## 5. Stock Prices
- **A.)** A 3 × 2 matrix with columns `x` (`1 2 3`) and `y` (`4 5 6`).
- **B.)** A 2 × 3 matrix with rows `x` (`1 2 3`) and `y` (`4 5 6`).
- **C.)** `2 6`
- **D.)** **Error**: *number of rows of matrices must match (see arg 2)*. The matrices have 3 and 2 rows.
- **E.)** `10 200 30`, with the warning *longer object length is not a multiple of shorter object length* (recycling, Reader).

```r
pct.change <- function(x) {
  if (length(x) < 2) stop("x must have at least 2 elements!")
  diff(x) / head(x, -1) * 100
}
volatility <- function(x) sd(pct.change(x))

apply(stocks, 1, volatility)
rowMeans(stocks)
```
- c) **Initech** moves about 5–17 % per day, so it is the most volatile.
- d) The result is **4 × 3**: rows `Tue Wed Thu Fri` and columns `ACME Globex Initech`.
- e) **2**
- f) `ACME 101.3`, `Globex 50.7`, `Initech 19.8`.

## 6. Star Wars (dplyr)
- **A.)** The column is called `avg`: `pull(avg)`.
- **B.)** A comma is missing after `n()`.
- **C.)** `select()` dropped `homeworld`, which the join needs.
- **D.)** `height` is overwritten by its mean, so `sd()` of a single value is `NA`.

lm:
- a) **59** residuals (87 − 28).
- b)
  ```r
  plot(mass ~ height, data = starwars, pch = 19, main = "Star Wars")
  abline(res, col = "red", lwd = 2)
  ```
- c) Use `which.max(res$residuals)`.

## 7. Data Vectors
- **A.)**
  - `as.numeric(...)` gives `9 -1`, the days since 1970-01-01 (Lecture 3).
  - `as.Date("17 March 2025", format = "%d %B %Y")` gives `"2025-03-17"`.
  - `diff(range(dates))` is `Time difference of 271 days`.
  - `format(range(dates), "%B")` is `"November" "July"`.
- **B.)**
  - `range(factor(months(dates)))` gives **Error**: *'range' not meaningful for factors*.
  - `wday()` gives `[1] Mon` with `Levels: Sun < Mon < Tue < Wed < Thu < Fri < Sat`.
- **C.)**
  - `min(level)` is `[1] low` with `Levels: low < medium < high`.
  - `range(level[level != "low"])` is `medium high`.
  - `relevel(level, ref = "high")` gives **Error**: `relevel()` only works for unordered factors (Lecture 3).
- **D.)** `[1] North S North` with `Levels: North S`.

## 8. Coercion
| | Answer |
|---|---|
| A | `"character"` |
| B | `"integer"`, and `B` is `a b c` / `1 2 3` |
| C | `"logical"`, then `"integer"` |
| D | `"double"` and `"Date"` |
| E | `1 2 1`, then `10 20 10` |
| F | `"list"`, then `"integer"` (a list keeps each element's type) |

## 9. Indexing and data.table
| | Answer |
|---|---|
| A | `"Cadillac Fleetwood"` |
| B | `TRUE` (335 hp) |
| C | `52 62 65` |
| D | `FALSE FALSE TRUE FALSE TRUE` |
| E | `TRUE FALSE FALSE TRUE` |
| F | `2` |

```r
# a) the last row: 30 September (Month 9, Day 30)
aq[.N]
# b)
aq[, .(mean_temp = mean(Temp)), by = Month]
# c)
aq[!is.na(Ozone), .N, by = Month]
# d)
aq[Temp %between% c(80, 90), .N]
# e) 17 9: the highest wind is 20.7 on 17 June, then 20.1 on 9 May
aq[order(-Wind)][1:2, Day]
```
f) A data.table always returns a data.table for `j` given as a position or name. A data.frame drops a single selected column to a vector.

## 10. Regex and Web Scraping
| | Answer |
|---|---|
| A | `"_ __ _ ___"` |
| B | `"31010408"` |
| C | `"010" "1234" "06" "555"` |
| D | `"010-1234" "06-555"` |
| E | `"C-3PO" "K 2SO"` |

F) Trace:
- **Iteration 1:** `"--"` becomes `"+"`, giving `"5-++3"`. Then `"-+"` becomes `"-"`, and the loop prints **`"5-+3"`**.
- **Iteration 2:** `"-+"` becomes `"-"`, and the loop prints **`"5-3"`**. Nothing is left to collapse, so the loop stops.

There are 3 minus signs, which is an odd number, so the result is `-`.

G) The number of iterations is not known in advance. It depends on the input, so the loop repeats until `grepl()` finds no more pairs.

H) Wikipedia table:
1. `html_table()` returns a **list** of all tables on the page.
2. `gsub("[[:punct:]]", "", beer.table[[1]]$Country)`
3. To keep the table's order in the plot. Otherwise ggplot sorts the countries alphabetically.

---

## The Most Common Traps

1. `length(df)` = `ncol(df)`. What `df[, 2]` returns depends on the type:
   - **data.frame**: a vector
   - **tibble/data.table**: still a table
   - `df[2]`: always a list-like table
2. `x_mat[4, 3]` ≠ `x_mat[c(4, 3)]`. `lst[2]` is a list, while `lst[[2]]` is the element.
3. Factors:
   - Levels are alphabetical by default, and `as.numeric(factor)` gives the codes.
   - Unordered factors have no `min`/`max`/`range`.
   - `relevel()` only works on unordered factors.
4. Dates:
   - Dates are numbers (days since 1970-01-01).
   - `seq(by = "month")` rolls over invalid dates, while `lubridate`'s `%m+%` does not.
   - Subtracting dates gives a `difftime`.
5. RMarkdown:
   - `TRUE`/`FALSE` must be in capitals, and string options need quotes.
   - Chunk labels must be unique, and every chunk needs a closing ```` ``` ````.
   - Chunks run top to bottom, so load packages first.
   - `toc_depth` defaults to 3.
6. dplyr:
   - Column names change after `mutate()`, `summarize()` and `select()`.
   - Use `==` in `filter()`, `n()` (not `count()`), and `+` in ggplot.
   - `aggregate()` needs `cbind()` for several responses, and `FUN = mean` without `()`.
7. Functions:
   - `return(a) * b` ignores `* b`.
   - `if` needs a single TRUE/FALSE.
   - Arguments without names are matched by position.
8. Coercion: character ← logical ← integer ← double ("downwards" to character).
9. Regex:
   - Escape metacharacters with `\\`.
   - `sub()` replaces the first match, `gsub()` replaces all.
   - `+` matches whole runs.
   - `[^...]` negates a character class.
