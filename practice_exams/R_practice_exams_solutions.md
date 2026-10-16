# R Practice Exams: Solutions

Each answer comes with a short explanation, because the explanation is what you need to learn for the exam.

---

# Warm-up: The Original Practice Exam

### 1. Starwars
| | Code | Answer | Why |
|---|---|---|---|
| A | `length(starwars)` | `9` | A data.frame/data.table is a **list of columns**, so `length()` counts columns, not rows. |
| B | `names(starwars)` | `"name" "height" "mass" "skin_color" "eye_color" "birth_year" "gender" "homeworld" "species"` | The column names. |
| C | `typeof(starwars[,2])` | `"list"` | **Trap!** On a `data.table`, `[,2]` returns a one-column *data.table*, which is a list. On a plain `data.frame` it would drop to a vector, and the answer would be `"integer"`. |
| D | `levels(starwars$gender)` | `NULL` | `gender` is `chr`, not a factor. Character vectors have no levels. |

### 2. RMarkdown (airports_merged)

**YAML header:**
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

**Mistakes in the chunks:**
1. **Wrong order.** The `ggplot()` chunk runs *before* the chunk that loads `ggplot2`/`maps` and creates `airports_merged_sub`, so you get `could not find function "ggplot"`. Move the loading chunk directly after `setup`.
2. **`echo = false`.** R is case-sensitive, and `false` is an undefined object. It must be `echo = FALSE`. (Since `include = FALSE` already hides everything, you could also just delete `echo`.)
3. **Duplicate chunk label `airports`.** knitr stops with *"Duplicate chunk label"*. Rename one of them, for example `{r structure}`, or leave it unnamed.
4. **Last chunk is never closed.** The closing ```` ``` ```` after `str(airports_merged)` is missing, so the following sentence would be run as R code.

(Not an error, but worth noting: `size = total` inside `aes()` is overridden by `geom_point(size = 3)`, and newer ggplot2 versions prefer `linewidth` over `size` in `borders()`.)

**Corrected file:**
````markdown
```{r setup, include = FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

```{r load, include = FALSE}
library(ggplot2)
library(maps)
airports_merged <- read.csv("airports_merged.csv")
airports_merged_sub <- subset(airports_merged, subset = lon > -140)
```

# Data Description
...
```{r airports}
ggplot(data = airports_merged_sub,
       aes(x = lon, y = lat, size = total, color = topcarrier)) +
  geom_point(size = 3) +
  borders(database = "state", size = 0.5) +
  labs(title = "Most frequent carrier per destination",
       y = "latitude", x = "longitude")
```

```{r structure}
str(airports_merged)
```

The data was collected into five different branches ...
````

---

# Exam 1

### 1. Pokémon
| | Answer | Explanation |
|---|---|---|
| A | `800` | Number of rows (obs.). |
| B | `"data.table" "data.frame"` | |
| C | `"logical"` | |
| D | A single integer: the **number of legendary Pokémon** | `TRUE` counts as 1 and `FALSE` as 0. |
| E | `"integer"` | `[[ ]]` extracts the column as a vector. |
| F | `"list"` | `[, "hp"]` on a data.table returns a data.table. |
| G | `"Poison" "Poison" "Poison" NA` | |

### 2. RMarkdown
```yaml
output:
  html_document:
    toc: true
    toc_depth: 3
    toc_float: true
```
Mistakes:
1. `aes(x = attack, y = defense, colour = legendary)`: the closing **`)` of `aes()` is missing**, so the `+` ends up inside `aes()`.
2. `eval = True`: it must be **`TRUE`**.
3. Inline code `` `r nrow(Pokemon)` ``: the object is **`pokemon`** (lowercase), so you get *object 'Pokemon' not found*.
4. `message = FALSE warning = FALSE`: a **comma is missing** between the chunk options.

### 3. summarise_vec()
| | Answer | Explanation |
|---|---|---|
| A | `mean 4, sd 2, n_missing 1` | `NA` is removed for mean/sd. The sd of 2, 4, 6 is 2. |
| B | `Error: x must be numeric` | `stop()` aborts the function. |
| C | `mean 2, sd 1, n_missing 0` | 1.5 rounds to 2, and 0.707 rounds to 1. |
| D | A **named numeric (double) vector** of length 3 with names `mean`, `sd`, `n_missing` | `c()` with names. |
| E | A **3 × 3 matrix**: rows `mean`/`sd`/`n_missing`, columns `hp`/`attack`/`speed` | `sapply` loops over the columns (a data.table is a list) and binds the results column-wise. |

F)
```r
summarise_vec <- function(x, digits = 2, max = FALSE) {
  if (!is.numeric(x)) stop("x must be numeric")
  res <- c(mean = mean(x, na.rm = TRUE),
           sd = sd(x, na.rm = TRUE),
           n_missing = sum(is.na(x)))
  if (max) res <- c(res, max = max(x, na.rm = TRUE))
  round(res, digits)
}
```
Calling `max(...)` still works even though there is an argument named `max`, because R skips non-function objects when it looks up a function call. A clearer name such as `add_max` would be better style.

### 4. data.table
```r
# a)
pokemon[, speed_class := fcase(speed > 100, "fast",
                               speed >= 50, "average",
                               default = "slow")]
# b)
pokemon[, .(n = .N, mean_hp = mean(hp)), by = type1][order(-mean_hp)]
# c)
pokemon[legendary == TRUE, .N, by = generation]
# d)
pokemon[order(-attack)][1:3, name]
# e)
pokemon[is.na(type2), .N]
```

### 5. Drills
A `8 15 16` · B `8 15 16 23 42` · C `16 23 42` · D `4 5 6` (positions!) · E `4 0 15 0 23 0` (recycling) · F `"1" "2" "TRUE"` (character wins) · G `"double"` · H `3` · I `"large" "medium" "small"` (alphabetical) · J `3 1 2 3` · K `1 3 2 1` · L `small 2, medium 1, large 1`

---

# Exam 2

### 1. Titanic
| | Answer | Explanation |
|---|---|---|
| A | `891 8` | |
| B | `NA` | One `NA` makes the mean `NA`. Use `na.rm = TRUE`. |
| C | `FALSE FALSE FALSE FALSE FALSE TRUE` | |
| D | `3 1 2` | `unique()` keeps the order of **first appearance**. |
| E | `"data.table" "data.frame"` | |
| F | `0 1 1` | A bare column name in `j` returns a vector. |
| G | `"C" "S"` | Only values that occur become levels, sorted alphabetically. |

### 2. RMarkdown
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
Mistakes:
1. `fig.cap = Survival rate per class`: chunk options are R code, so text **needs quotes**: `fig.cap = "Survival rate per class"`.
2. **Wrong order.** The plot chunk uses `ggplot` and `rates` before the `load-data` chunk has run. Move `load-data` above it.
3. `fread("titanic.csv)`: the **closing quote is missing**.
4. **Duplicate chunk label `load-data`.** Rename the histogram chunk, for example `age-hist`.

Inline sentence: `age` contains `NA`s, so the sentence says *"was NA years"*. Fix it with `` `r round(mean(titanic$age, na.rm = TRUE), 1)` ``.

### 3. draw_curve()
| | Answer |
|---|---|
| A | One full period of the **sine wave** from 0 to 2π, drawn as a line. |
| B | `x = -5 -2.5 0 2.5 5`, so `res$y` is `25 6.25 0 6.25 25`. |
| C | `...` passes any extra arguments on to `plot()`. The line becomes red, and the title is "Exponential". |
| D | `invisible()` returns the data **without printing it** to the console. You still get it if you assign it (`res <- draw_curve(...)`). |
| E | Error: `could not find function "f"`. `"sqrt"` is a character string, not a function. Pass `sqrt` without quotes. |
| F | `sqrt()` of the negative x-values gives `NaN` with the warning *"NaNs produced"*. The curve is only drawn for x ≥ 0. |

G)
```r
library(ggplot2)
draw_curve_gg <- function(f, from = -5, to = 5, n = 100) {
  x <- seq(from, to, length.out = n)
  df <- data.frame(x = x, y = f(x))
  ggplot(df, aes(x = x, y = y)) +
    geom_line()
}
draw_curve_gg(cos, 0, 2 * pi)
```

### 4. data.table
```r
# a)
titanic[, .(survival_rate = mean(survived)), by = pclass][order(pclass)]
# b)
titanic[, .N, by = .(sex, pclass)]
# c) A missing age gives NA, because NA < 18 is NA
titanic[, age_group := fifelse(age < 18, "child", "adult")]
# d)
titanic[sex == "female" & pclass == 1 & fare > 100, .(name, fare)]
# e)
titanic[, .(mean_age = mean(age, na.rm = TRUE)), by = survived]
```

### 5. Drills
A `3` · B `"Python"` · C `"Ada"` · D `"list"` (`[ ]` keeps it a list) · E `NULL` · F prints `1`, `9`, `25` · G `12` · H `2 5 8 11` · I `"a" "b" "a" "b"` · J `"a" "a" "b" "b"` · K `19` · L `"DATA"` · M `"Science"` · N `"x1 + x2 + x3"` · O `FALSE FALSE TRUE FALSE` (case-sensitive)

---

# Exam 3

### 1. Spotify
| | Answer | Explanation |
|---|---|---|
| A | `8` | |
| B | `6` | |
| C | `"factor"` | |
| D | `"integer"` | **Trap!** Factors are stored as integer codes. |
| E | `2019 2017` | Column 3 is `year`. |
| F | A value between 0 and 1: the **share of explicit songs** | |
| G | `2000` | `.N` is the number of rows. |

### 2. RMarkdown
```yaml
output:
  word_document:
    toc: true
    toc_depth: 2
```
```r
knitr::opts_chunk$set(echo = FALSE, message = FALSE)
```
Mistakes:
1. `fread()` is used, but **`library(data.table)` is never loaded**, so you get *could not find function "fread"*.
2. `ggplot(Spotify, ...)`: it must be `spotify`, because R is case-sensitive.
3. `+ geom_boxplot`: the **parentheses are missing**. It must be `geom_boxplot()`.
4. `results = hide`: it must be `results = "hide"`, a string.
5. The `counts` chunk is closed with only **two backticks** (` `` `). It needs three.

### 3. count_above()
| | Answer |
|---|---|
| A | A single number: **how many songs have popularity > 80**. |
| B | Error: *object 'popularity' not found*. The column name must be given as a string, `"popularity"`. |
| C | Error: *missing value where TRUE/FALSE needed*. `if (NA > 0.5)` cannot decide. |
| D | It should return `0`. But `1:nrow(dt)` is `1:0`, which is `c(1, 0)`, so the loop runs, `dt[["year"]][1]` is `NA`, and you get the same error as in C. Fix: `for (i in seq_len(nrow(dt)))`. |
| F | A numeric vector of 4 counts (for 60, 70, 80 and 90), which gets **smaller or stays equal** as the threshold rises. |

E)
```r
count_above <- function(dt, col, threshold) {
  sum(dt[[col]] > threshold, na.rm = TRUE)
}
```

### 4. data.table
```r
# a)
spotify[, duration_min := duration_ms / 60000]
# b)
spotify[, .(avg_pop = mean(popularity)), by = genre][order(-avg_pop)]
# c)
spotify[year >= 2015 & explicit == TRUE, .N, by = year][order(year)]
# d)
spotify[, .N, by = artist][order(-N)][1:5]
# e)
spotify[year >= 2010][, .(mean_dance = mean(danceability)), by = genre][order(-mean_dance)]
# f)
ggplot(spotify, aes(x = popularity, fill = explicit)) + geom_histogram(bins = 30)
```

### 5. Drills
A `TRUE NA TRUE FALSE` · B `NA` · C `2` · D `3 7 1` · E `NA` · F `1` and `0`
G (filled **column by column**):
```
     [,1] [,2] [,3]
[1,]    1    3    5
[2,]    2    4    6
```
H `6` · I `9 12` · J `2 4 6` · K `9` · L `5` · M `100 2 3`, then `1 2 3` (functions work on a copy) · N `20`, then `10` (local variable)

---

## The Most Common Traps

1. `length(df)` counts **columns**. Use `nrow()` for rows.
2. `DT[, 2]` / `DT[, "col"]` returns a data.table (a list). `DT[[2]]`, `DT$col` and `DT[, col]` return a vector.
3. `typeof(factor)` is `"integer"`. Calling `levels()` on a character vector gives `NULL`.
4. `NA` spreads through calculations. Add `na.rm = TRUE`, and remember that `if (NA)` is an error.
5. RMarkdown: `TRUE`/`FALSE` must be in capitals, string options need quotes, chunk labels must be unique, every chunk needs a closing ```` ``` ````, and chunks run **top to bottom**, so load packages and data first.
6. YAML indentation matters: options go *under* the output format (`pdf_document:` → `toc: true`).
7. In functions, use `seq_len(n)` instead of `1:n`, and pass column names as strings to `dt[[col]]`.
