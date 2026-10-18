# R Practice Exams 6 and 7: Solutions (FEM11151)

The answers were worked out by hand from the reader and lecture notes. Running the code yourself is good practice. Answers for weekday and month names assume an English locale.

---
---

# Exam 6

## 1. Student Results
| | Answer | Why |
|---|---|---|
| A | `7` | |
| B | `"list"` | `students` is a **data.table**, and `DT[, 5]` stays a data.table. |
| C | `"integer"` | Factors are stored as integer codes. |
| D | `1 2 1 3 2` | The codes from the `str()` output. |
| E | `"Date"` and `"double"` | A date is the number of days since 1970-01-01. |
| F | `6.775` | (7.5 + 6 + 8.2 + 5.4) / 4 = 27.1 / 4 |
| G | `1` | `!` turns `T T T F T` into `F F F T F`, and the sum counts the TRUEs. |
| H | `"Chloe" "Emma"` | Chaining: take rows 1–5 first, then keep grades > 8 (8.2 and 9.1). |

## 2. RMarkdown
```yaml
output:
  word_document:
    toc: true
    toc_depth: 1
    highlight: tango
```
- (4) A **TeX distribution**: MiKTeX on Windows or MacTeX on Mac (Lecture 4 Reporting).
- (5) **Ctrl/Cmd + Shift + K**

Mistakes:
1. `fig.height = four` must be `fig.height = 4`. `four` is not an R object.
2. `labs(... y = "Grade"` is missing its closing `)`.
3. The inline code `mean(student$grade)` must use `students`.
4. **The chunk label `grade-box` is used twice.**

## 3. draw_scatter()
```r
draw_scatter()                                          # A
draw_scatter(slope = -1, col = "blue", pch = 19)        # B
draw_scatter(noise = 3, line = TRUE)                    # C
draw_scatter(n = 10, slope = 2, col = "darkgreen", pch = 17)   # D
```
- b) `a` is the **intercept** and `b` is the **slope**. With `a = 0` and `b = slope = 1`, the line is y = 0 + 1·x = x. The points wiggle around it because `noise * sin(x)` is added.
- c) `par(mfrow = c(1, 4))`

## 4. Factorials and Counting
```r
my.factorial <- function(n){
  result <- 1
  for(i in seq_len(n)){
    result <- result * i
  }
  result
}

count.char <- function(s, ch){
  chars <- strsplit(s, "")[[1]]
  sum(chars == ch)
}
```
a) The result is `0`. `1:0` is `c(1, 0)`, so the loop multiplies by 1 and then by **0**. `seq_len(0)` is empty, so the loop doesn't run and the result stays 1.

| call | result | why |
|---|---|---|
| `f(5)` | `"positive"` | `return()` ends the function early. |
| `f(-1)` | `"not positive"` | The last expression is returned. |
| `g(y = 10, 3)` | `-7` | `y` is matched by name, so the unnamed `3` goes to `x`: 3 − 10. |

## 5. Weather Forecasts
`M` is `4 7 / 2 6` (filled by column).

- **A.)** `det(M)` is 4·6 − 7·2 = **10**.
- **B.)** `solve(M)` is 1/10 · `6 −7 / −2 4`, which gives `0.6 -0.7 / -0.2 0.4`.
- **C.)** A 2 × 1 matrix: `11` (4 + 7) and `8` (2 + 6).
- **D.)** `4 2 6`: column order, and only the even values.
- **E.)** A 3 × 2 matrix `4 7 / 2 6 / 0 0`. The single `0` is recycled into a full row.
- **F.)** `4 7 / 20 60`. `c(1, 10)` is recycled **down the columns**: 4·1, 2·10, 7·1, 6·10.

```r
rmse <- function(actual, predicted) {
  if (length(actual) != length(predicted)) stop("vectors must have the same length!")
  sqrt(mean((actual - predicted)^2))
}

apply(forecast, 2, rmse, actual = actual)    # a)
```

| model | errors | squared | mean | RMSE |
|---|---|---|---|---|
| M1 | 1 0 −1 0 | 1 0 1 0 | 0.5 | **0.71**, the best |
| M2 | 0 2 0 0 | 0 4 0 0 | 1 | 1.00 |
| M3 | 4 −2 4 −4 | 16 4 16 16 | 13 | 3.61 |

c) `actual = actual` is matched **by name** first. The column that `apply()` passes in is unnamed, so it goes to the next free argument, `predicted` (Lecture 5, "Multiple inputs").

## 6. Palmer Penguins
- **A.)** `select()` dropped `sex`. Filter first, or keep `sex` in `select()`.
- **B.)** `count()` creates a column called **`n`**, not `N` (`.N` is data.table). Use `arrange(desc(n))`.
- **C.)** `labs(...)` is missing its closing `)`, so `"Mass" + theme_minimal()` is evaluated as arithmetic.
- **D.)** `subset()` has no argument called `species`. That argument goes into `...` and is ignored silently. Use `subset(penguins, subset = species == "Adelie")`, with the argument name **and** `==`.

lm:
- a) **342** (344 − 2)
- b) For every additional **mm** of flipper length, penguins are on average about **50 g heavier**.
- c)
  ```r
  plot(body_mass_g ~ flipper_length_mm, data = penguins, pch = 19,
       col = as.integer(penguins$species))
  abline(res, lwd = 2)
  ```

## 7. Dates and Factors
- **A.)**
  - `d` is `"2025-03-01" "2025-08-15"`.
  - `d[2] - d[1]` is `Time difference of 167 days`.
  - `quarters(d)` is `"Q1" "Q3"`.
  - `format(d, "%Y")` is `"2025" "2025"`.
- **B.)**
  - `seq()` gives `"2025-03-01" "2025-03-08" "2025-03-15"`.
  - `weekdays()` gives `"Saturday"`.
- **C.)** `Time difference of 1440 mins` (24 × 60)
- **D.)**
  - `month()` gives `8`.
  - `wday()` gives `[1] Fri` with `Levels: Sun < Mon < Tue < Wed < Thu < Fri < Sat`.
- **E.)**
  - `as.integer(f)` is `2 3 1 3`, because the levels are `c, b, a` in that order.
  - `table(f)` is `c 1, b 1, a 2`.
  - After renaming, `f` is `[1] b A c A` with `Levels: c b A`.
- **F.)**
  - `o > "b"` is `FALSE TRUE FALSE TRUE`. The order is `c < b < A`, so only `A` is larger than `b`.
  - `revalue()` gives `[1] B A c A` with `Levels: c B A`.

## 8. Coercion
| | Answer |
|---|---|
| `x` | `"character"`: `a "1"`, `b "two"` |
| `y + 1L` | `2 1`. `typeof(y + 1L)` is `"integer"` and `typeof(y + 1)` is `"double"`. |
| `z` | `1 2 3 NA 1`: the gap becomes `NA`, and `TRUE` becomes 1 |
| `m` | `"integer"`: `1 1 / 2 0` |
| `unlist(l)` | `"double"` |
| `TRUE` + `"3"` | `4` |
| `as.integer(...)` | `7 7 NA`, with a warning |

## 9. Indexing and data.table
`x_mat` has the columns (1,2,3), (4,5,6), (7,8,9) and (10,11,12).

| | Answer |
|---|---|
| A | `2 5 8 11` |
| B | a 3 × 2 matrix: `1 10 / 2 11 / 3 12` |
| C | `10` |
| D | `5 10` |
| E | `11 12` |
| F | `"list"` |
| G | `TRUE` |
| H | `Rotterdam 2`, `Utrecht 2`, `Delft 1` (in order of first appearance) |
| I | `12`: (12 + 10 + 14) / 3 |
| J | `Delft 14`, `Rotterdam 12`, `Utrecht 15` (sorted by `keyby`) |
| K | `"Utrecht"`: the last row after sorting by temperature, so the warmest |
| L | `42`: 15 + 14 + 13 |

```r
# a)
students[, .N, keyby = .(program, year)]
# b)
students[program == "BSc" & passed == TRUE, mean(grade)]
# c)
students[order(-grade)][1:3, name]
# d)
students[, grade_rounded := round(grade)]
# e)
students[grade %between% c(5.5, 6.5), .N]
```

## 10. Regex and Web Scraping
| | Answer |
|---|---|
| A | `TRUE FALSE TRUE FALSE` |
| B | `2` |
| C | `"#R" "#exam"` |
| D | `"@prof thanks  #exam"` (only the **first** hashtag is removed, which leaves two spaces) |
| E | `"Exam on 20250120 "` (`-`, `:` and `(` are removed) |
| F | `"a b c"` |
| G | `1` (`"01"` becomes `1`) |
| H | `1 0 2 0` |

I) Web scraping:
1. `\\s` matches **every** whitespace character, including the spaces between words, so you get `"UnitedArabEmirates"`. Remove only runs of 2 or more whitespace characters instead: `gsub("\\s{2,}", "", x)` gives `"United Arab Emirates"`.
2. `length(html_table(page))`. `html_table()` returns a **list** with one data frame per table.

---
---

# Exam 7

## 1. Daily Weather
| | Answer | Why |
|---|---|---|
| A | `6` | |
| B | `"double"` | A plain **data.frame** drops a single column to a vector. |
| C | `"data.frame"` | Single brackets without a comma give list-style selection. |
| D | `"autumn" "spring" "summer" "winter"` | Alphabetical, and code 4 is winter (January). |
| E | `NA`, then `2.375` | (0 + 2.4 + 0 + 7.1) / 4 |
| F | `"2024-02-01"` | Dates are numbers, so adding 31 days works. |
| G | `3` | `F T F T T` |
| H | `"Monday"` | 1 January 2024 was a Monday. |

## 2. RMarkdown
```yaml
output:
  pdf_document:
    toc: true
    toc_depth: 2
    df_print: kable
    fontsize: 11pt
```
(5) Use `ioslides_presentation`. xaringan and reveal.js are other options from the lecture.

Mistakes:
1. `col = "steel blue"` is not a valid colour name. Use `"steelblue"`, which you can check with `colors()`.
2. `Mean()` doesn't exist. R is case-sensitive, so use `mean()`.
3. `eval = TRUE echo = FALSE` is missing a comma.
4. **The last chunk is not closed** with ```` ``` ````.

## 3. draw_wave()
```r
draw_wave()                                     # A
draw_wave(freq = 3, col = "red")                # B
draw_wave(amp = 2, type = "p", col = "blue")    # C
draw_wave(freq = 2, lwd = 3, grid = TRUE)       # D
```
- b) **50** (`n = 50`)
- c) Three **horizontal** lines at y = −1, 0 and 1 (`amp = 1`), and one **vertical** line at x = π. All are grey and dotted (`lty = 3`).
- d)
  ```r
  x <- seq(0, 2 * pi, length.out = 50)
  df <- data.frame(x = x, y = sin(3 * x))
  ggplot(df, aes(x = x, y = y)) + geom_line(colour = "red") + theme_bw()
  ```

## 4. Running Maximum and Palindromes
```r
my.cummax <- function(x){
  out <- numeric(length(x))
  out[1] <- x[1]
  for(i in 2:length(x)){
    out[i] <- max(out[i - 1], x[i])
  }
  out
}

is.pal <- function(s){
  chars <- strsplit(s, "")[[1]]
  all(chars == rev(chars))
}

stats3 <- function(x) {
  list(min = min(x), max = max(x), width = max(x) - min(x))
}
```
- a) `FALSE`. The comparison is case-sensitive, and `"L"` is not equal to `"l"`.
- c) `y` is **`NULL`**. The last expression in the function is the `for` loop, and a `for` loop returns `NULL`. The values `i * 2` are computed but never stored or returned (Lecture 5: *"what happens in the for loop, stays in a for loop"*).

## 5. Test Scores
- **A.)** `3 2`
- **B.)** `"x1" "x2"`
- **C.)** `4 5 6`
- **D.)** A 2 × 2 matrix with rows and columns named `x1`, `x2`:
  - [1,1] is 1 + 4 + 9 = 14
  - [1,2] and [2,1] are 4 + 10 + 18 = 32
  - [2,2] is 16 + 25 + 36 = 77
- **E.)** `4 5 6`
- **F.)** `x1 2`, `x2 5`

```r
scale01 <- function(x) {
  (x - min(x)) / (max(x) - min(x))
}
S <- apply(scores, 2, scale01)
```
- a) `dim(S)` is **4 3**, the same shape as `scores`. The first column (T1: 50, 70, 90, 60, with min 50 and max 90) is `0 0.5 1 0.25`.
- b) The result is **3 × 4**. `apply()` always puts each function result into a **column**. With `MARGIN = 2`, a column result fits back as a column. With `MARGIN = 1`, each student's 3 values become a column, so the result is transposed.
- c) The scaled scores and averages are:

  | | T1 | T2 | T3 | `rowMeans` |
  |---|---|---|---|---|
  | Ann | 0 | 0.5 | 0.5 | 0.33 |
  | Ben | 0.5 | 0 | 1 | 0.50 |
  | Cem | 1 | 0.25 | 0 | 0.42 |
  | Dee | 0.25 | 1 | 0.5 | **0.58**, the best |

## 6. Bike Sharing Chicago
- **A.)** `filter()` needs `==`: `filter(events == "rain")`.
- **B.)** A column used as an aesthetic must go **inside** `aes()`: `geom_point(aes(colour = usertype))`.
- **C.)** R is case-sensitive: the object is `Chicago.agg`.
- **D.)** Text needs quotes: `main = "Trip duration"`.

lm:
- a) **12433**
- b) `lm()` turns the character column into a **factor** automatically. It creates one coefficient per category, except the reference category, which is the **first one alphabetically**.
- c)
  ```r
  plot(res$fitted.values, res$residuals, xlab = "fitted", ylab = "residuals")
  abline(h = 0, col = "blue", lty = 2)
  ```

## 7. Dates and Factors
- **A.)**
  - `as.Date("March 5, 2025", format = "%B %d, %Y")` gives `"2025-03-05"`.
  - `format(d, "%d/%m/%y")` gives `"05/03/25"`.
  - `weekdays(d)` gives `"Wednesday"`.
  - `as.numeric(d - as.Date("2025-01-01"))` is `63` (31 + 28 + 4).
- **B.)** `"2025-03-05" "2025-03-19" "2025-04-02"`
- **C.)**
  - `%m+% years(1)` gives `"2025-02-28"`, because 2025 has no 29 February.
  - The duration divided by `ddays(1)` is `14`.
- **D.)**
  - `sizes` is `[1] medium small large medium` with `Levels: small medium large`.
  - `as.integer(sizes)` is `2 1 3 2`.
  - After renaming, `table(sizes)` is `small 1, medium 2, big 1`.
  - The relevelled levels are `"big" "small" "medium"`.
- **E.)**
  - `o[o > "small"]` is `[1] medium big medium` with `Levels: small < medium < big`.
  - `range(o)` is `[1] small big`.

## 8. Coercion
| | Answer |
|---|---|
| `typeof(c(1.0, 2L))` | `"double"` |
| `v` | `"character"`; `is.na(v)` is `FALSE TRUE` |
| `as.logical(c(TRUE, "FALSE"))` | `TRUE FALSE`: the vector is first coerced to `"TRUE" "FALSE"` |
| `x` | `1 2 0 0 0`, `"double"`: `0` is a double |
| `sum(c("1", "2"))` | **Error**: `invalid 'type' (character) of argument` |
| `sum(as.integer(...))` | `3` |
| `as.numeric(f)` | `2 1 2`: the codes, because the levels are `"1" "3"` |
| `as.numeric(levels(f))[f]` | `3 1 3`: the real values |
| `Sys.Date()` | `"double"` and `"Date"` |

## 9. Indexing and data.table
| | Answer |
|---|---|
| A | `10 30 40` |
| B | `2 5` |
| C | `2` (30 and 40) |
| D | `30 40 NA` |
| E | `TRUE FALSE FALSE TRUE FALSE` |
| F | `"Ann"` |
| G | `8 9` |
| H | `"list"` |
| I | `tea 3`, `coffee 2`, `juice 1` |
| J | `tea 9`, `coffee 7.5`, `juice 12` |
| K | `"tea" "juice" "coffee"` |
| L | `coffee 3`, `juice 4`, `tea 6` (the column is called `V1`) |
| M | `6`: **every** product contains an `e` (t**e**a, coff**ee**, juic**e**) |

```r
# a)
wt[, .(mean_temp = mean(temp)), keyby = season]
# b)
wt[windy == TRUE & rain_mm > 5, .N]
# c)
wt[order(-temp)][1:3, .(date, temp)]
# d)
wt[season == "summer" & temp %between% c(15, 20), .N]
```
e) `wt[.N]` returns the **last row**, as a data.table. `nrow(wt)` returns the **number** of rows (366).

## 10. Regex and Web Scraping
| | Answer |
|---|---|
| A | `FALSE TRUE FALSE FALSE FALSE` (case-sensitive) |
| B | `FALSE TRUE TRUE FALSE FALSE` |
| C | `"report_2024" "data_final" "Data_v2.CSV" "notes" "image01"` (`.CSV` is uppercase, so it doesn't match) |
| D | `"report_.pdf" "data_final.csv" "Data_v.CSV" "notes.txt" "image.png"` |
| E | `"report_2024.pdf" "image01.png"` |
| F | `"report" "2024" "pdf"` |
| G | `1 0 1 0 1` |
| H | `"-.b"` and `"a-b"` |

In H, an unescaped `.` is a **metacharacter** that matches **any** character, so it replaces the first character, `a`. Only `\\.` matches a literal dot.

I) Web scraping:
1. `html_node()` returns the **first** matching node. `html_nodes()` returns **all** matching nodes.
2. `as.numeric(gsub(",", "", x))`
3. `xml()`, `xml_node()`, `xml_attr()`, `xml_attrs()`, `xml_text()` and `xml_name()`
