# R Practice Exams 4 and 5: Solutions (FEM11151)

The answers were worked out by hand from the reader and lecture notes. Running the code yourself is good practice. Answers for weekday and month names assume an English locale.

---
---

# Exam 4

## 1. New York Flights
| | Answer | Why |
|---|---|---|
| A | `10` | `length()` of a table = number of columns. |
| B | `"list"` | `flights` is a **data.table**, and `DT[, 4]` returns a data.table (Lecture 6). |
| C | `"integer"` | `[[ ]]` extracts the column as a vector. |
| D | `14 -3 2 -8` | A bare column name in `j` returns a vector. |
| E | `"PBI"` | Row 4, column `dest`. |
| F | `1` | `13 13 9 -26`: only `-26` is `< 0`. |
| G | `NULL` | `origin` is `chr`. data.table never converts characters to factors (Lecture 6). |

## 2. RMarkdown
```yaml
output:
  pdf_document:
    toc: true
    number_sections: true
    highlight: null
```
The default `toc_depth` is **3**, so level 1, 2 and 3 headers are included (Lecture 4 Reporting).

Mistakes:
1. **Wrong chunk order.** `delay-plot` uses `delays` before the `delay-table` chunk creates it.
2. **`eval = yes`** must be `eval = TRUE`. `yes` is not an R object.
3. **The `]` is missing** at the end of `flights[, .(mean_delay = ...), by = carrier`.
4. **Inline code `nrow(flight)`** must be `nrow(flights)`.
5. **The chunk label `delay-table` is used twice.**

## 3. draw_two()
```r
draw_two()                                                     # A
draw_two(both = FALSE, lty = 2)                                # B
draw_two(f1 = exp, f2 = function(x) x^2, from = 0, to = 2,
         col = c("blue", "darkgreen"))                         # C
draw_two(f1 = cos, f2 = sin, col = c("purple", "orange"), lty = 3)  # D
```
- b) `plot()` sets the y-axis using only `f1(x)`. For `exp(x)` on [0, 2], that is about 1 to 7.4. `lines()` only adds to the existing plot and **never extends the axes**, so `x^2 < 1` (for x < 1) falls outside and is cut off. You need `ylim`, for example `ylim = range(c(f1(x), f2(x)))` inside `plot()`.
- c) `legend("bottomleft", c("sin", "cos"), col = c("black", "red"), lty = 1, bty = "n")`

## 4. Mode and Prime Numbers
```r
my.mode <- function(x){
  tab <- table(x)
  as.numeric(names(tab)[which.max(tab)])
}

is.prime <- function(n){
  if(n < 2) return(FALSE)
  if(n == 2) return(TRUE)
  for(d in 2:(n - 1)){
    if(n %% d == 0) return(FALSE)
  }
  TRUE
}
```
`names(tab)` are **character** values (`"2" "3" "5"`), so you need `as.numeric()`.

- a) For `n = 2`, the sequence is `2:1`, which is `c(2, 1)`, counting **down**. Then `2 %% 2 == 0` would wrongly return `FALSE`.
- b) `2 3 5 7 11 13 17 19`. `sapply()` gives `TRUE`/`FALSE` for 1–20, and `which()` returns the positions that are `TRUE`.

| call | result | why |
|---|---|---|
| `foo(3)` | `4` | Only the **last** expression is returned. `x^2` is computed and thrown away (Lecture 5). |
| `bar(3)` | `9` | The default `y = x * 2 = 6`, so 3 + 6. |
| `bar(3, 1)` | `4` | `y` is given, so the default is ignored. |

## 5. Sales
`A` is filled **by row** (`byrow = TRUE`):
```
     [,1] [,2] [,3]
[1,]    1    2    3
[2,]    4    5    6
```
- **A.)** `4 5 6`
- **B.)** `2 3 / 5 6`: column 1 is dropped.
- **C.)** A 2 × 1 matrix: `4` (1 + 3) and `10` (4 + 6).
- **D.)** `3 3`: (3 × 2) times (2 × 3).
- **E.)** `4 5 3 6`. **Trap:** R stores a matrix **column by column** internally (1, 4, 2, 5, 3, 6), even if you filled it by row. Logical indexing returns the values in that internal order (Lecture 5).

```r
mad.mean <- function(x) {
  if (length(x) < 2) stop("x is not a vector!")
  sum(abs(x - mean(x))) / length(x)
}
rel.mad <- function(x) {
  mad.mean(x) / mean(x) * 100
}

apply(sales, 1, mad.mean)    # a)
apply(sales, 1, rel.mad)     # b)
colSums(sales)               # c)
```

| product | mean | absolute deviations | `mad.mean` | `rel.mad` |
|---|---|---|---|---|
| Lamp | 25 | 15 5 5 15 | **10** | 40 |
| Chair | 25 | 0 0 0 0 | **0** | 0 |
| Desk | 15 | 3 3 3 3 | 3 | 20 |
| Shelf | 20 | 15 30 15 0 | 15 | **75**, the most unstable |

c) `Q1 52, Q2 113, Q3 72, Q4 103`

## 6. Iris
- **A.)** R is case-sensitive: the column is `Sepal.Length`.
- **B.)** Each side of `|` must be a complete comparison: `Species == "setosa" | Species == "virginica"`. Or use `Species %in% c("setosa", "virginica")`.
- **C.)** A comma is missing: `select(Species, Petal.Width)`.
- **D.)** `aggregate()` needs a **formula**: `aggregate(Sepal.Length ~ Species, data = iris, FUN = mean)` (Lecture 2).

lm:
- a) There are 3 coefficients: `"(Intercept)" "Speciesversicolor" "Speciesvirginica"`. There are 150 residuals.
- b) **setosa** is the reference level, because it is the first level (alphabetical order). The intercept is the **mean petal length of setosa**, about 1.46.
- c) `iris$Species <- relevel(iris$Species, ref = "virginica")` (Lecture 3)
- d)
  ```r
  boxplot(Petal.Length ~ Species, data = iris, col = "lightgrey")
  boxplot(res$fitted.values ~ Species, data = iris,
          border = "red", outline = FALSE, add = TRUE)
  legend("topleft", "model predictions", col = "red", lwd = 2)
  ```

## 7. Dates and Factors
- **A.)**
  - `d` is `"2025-02-27" "2025-02-28" "2025-03-01" "2025-03-02"`. 2025 is not a leap year.
  - `months(d)` is `"February" "February" "March" "March"`.
  - `quarters(d[4])` is `"Q1"`.
- **B.)** `Time difference of 0.4285714 weeks`: 3 days / 7.
- **C.)**
  - `format(...)` gives `"24 Dec 2025"`.
  - `as.Date("24.12.2025", format = "%d.%m.%Y")` gives `"2025-12-24"`.
  - `as.numeric(as.Date("1970-02-01"))` is `31` (days since 1 January 1970).
- **D.)**
  - `seq()` gives `"2025-01-31" "2025-03-03"`. "31 Feb" rolls over to 3 March.
  - `%m+%` gives `"2025-02-28"`. lubridate stays in February.
- **E.)**
  - `rating` is `[1] low high medium high` with `Levels: low medium high`. Only the label of level 2 changes.
  - `as.integer(rating)` is `1 3 2 3`.
  - `rating == "high"` is `FALSE TRUE FALSE TRUE`.
  - `max(rating)` gives **Error**: *'max' not meaningful for factors*, because `rating` is unordered.
- **F.)** `[1] L H medium H` with `Levels: L medium H`.

## 8. Coercion
| | Answer |
|---|---|
| A | `"integer"`, `1 1 3` (`TRUE` → `1L`) |
| B | `"double"`: a single double makes the whole matrix double |
| C | `n "integer"`, `s "character"`: each data-frame column keeps its own type |
| `typeof(NA)` | `"logical"` |
| `as.integer("3.9")` | `3`: truncated, not rounded |
| `as.numeric("abc")` | `NA`, with the warning *NAs introduced by coercion* |
| `as.logical(c("TRUE", "yes", "0"))` | `TRUE NA NA` |
| `as.logical(0:2)` | `FALSE TRUE TRUE`: 0 is FALSE, every other number is TRUE |

## 9. Indexing and data.table
| | Answer | Why |
|---|---|---|
| A | `c 30` | Named indexing keeps the name. |
| B | `a 10 c 30` | The logical index is **recycled**: T F T F. |
| C | `b 20 c 30` | |
| D | `d 4` | `which()` returns the position with its name. |
| E | `5` | |
| F | `"x"` | |
| G | `2` | |
| H | A data.table with 4 rows and 2 columns: `AA LAX`, `AA LAX`, `AA LAX`, `AA PBI` | |
| I | `dest N` / `LAX 3` / `PBI 1` | |

```r
# a)
flights[origin == "LGA" & month == 6L, .N]
# b)
flights[, .(mean_dep = mean(dep_delay), mean_arr = mean(arr_delay)), keyby = origin]
# c)
flights[dest %chin% c("LAX", "SFO"), .N, by = .(origin, dest)][order(-N)]
# d)
flights[, .(early = sum((dep_delay + arr_delay) < 0)), by = carrier]
```
e) For a data.frame, `df[1:2]` returns the **first two columns**, because single indexing treats it as a list (Lecture 5). In a data.table, `i` always means rows (Lecture 6).

## 10. Regex and Web Scraping
| | Answer |
|---|---|
| A | `FALSE TRUE FALSE FALSE` |
| B | `1 3 4` |
| C | `"apple" "Banana" "cherry_" "date -10-18"` (only the **first** run of digits) |
| D | `"apple" "Banana" "cherry_" "date --"` |
| E | `"cherry 7"` (`_` is punctuation) |
| F | `"2024"` |
| G | `"2024" "10" "18"` (`{2,4}` takes as many digits as possible, up to 4) |
| H | a list: `[[1]] "date" "2024" "10" "18"` |

I) `"[[:alnum:].]+@[[:alnum:].]+"`

J) Shop page:
1. `page %>% html_nodes(".name") %>% html_text()`
2. ```r
   p <- page %>% html_nodes(".price") %>% html_text()
   as.numeric(sub(",", ".", gsub("[^0-9,]", "", p)))   # 24.99 89.50
   ```

---
---

# Exam 5

## 1. Motor Trend Cars
| | Answer | Why |
|---|---|---|
| A | `32 11` | |
| B | `"double"` | `cyl` is `num`, not `int`. Whole numbers are not automatically integers. |
| C | `4: 3`, `6: 5`, `8: 2` | First ten values: `6 6 4 6 8 6 8 4 4 6`. |
| D | `0.3` | `1 1 1 0 0 0 0 0 0 0` |
| E | `14.3` | The first car with hp > 200 is car 7 (hp 245). |
| F | `"3" "4" "5"` | Levels are always **character**. |
| G | `"numeric"` | A data.frame drops a single column to a vector. |

## 2. RMarkdown
```yaml
output:
  html_document:
    toc: true
    toc_depth: 2
    toc_float: true
    number_sections: true
    fig_width: 8
    fig_height: 5
```
1. `out.width = 80%` is not valid R. Use `out.width = '80%'`.
2. `plot(...)` is missing its closing `)`.
3. `include = False` must be `include = FALSE`.
4. `kable()`, `kable_styling()` and `%>%` are not available. Add `library(kableExtra)` to the setup chunk.

The LaTeX formula is correct. The `hidden` chunk still runs with `include = FALSE`; only its output is hidden.

## 3. draw_poly()
```r
draw_poly()                                                     # A
draw_poly(degree = 3, col = "red", pch = 19)                    # B
draw_poly(degree = 1, from = 0, to = 5, by = 1, col = "blue", pch = 2)  # C
draw_poly(degree = 4, col = "darkgreen")                        # D
```
- b) `seq(-2, 2, by = 0.25)` gives **17** points.
- c) Add `...` to the argument list and pass it to **both** `plot()` calls. Then call `draw_poly(main = "Parabola", ylim = c(0, 5))`.
- d)
  ```r
  x <- seq(-2, 2, by = 0.25)
  df <- data.frame(x = x, y = x^4)
  ggplot(df, aes(x = x, y = y)) + geom_line(colour = "darkgreen") + theme_light()
  ```

## 4. Loops and Grades
```r
my.rev <- function(x){
  out <- x
  for(i in seq_along(x)){
    out[i] <- x[length(x) - i + 1]
  }
  out
}

grade <- function(score){
  if(score >= 90){
    "A"
  } else if(score >= 75){
    "B"
  } else if(score >= 55){
    "C"
  } else {
    "F"
  }
}

count.above <- function(x) sum(x > mean(x))
```
- a) Both `grade(75)` and `grade(89.9)` return `"B"`. Only the **first** TRUE branch runs (Lecture 5).
- b) `if` needs a **single** TRUE/FALSE value, and a vector of 2 gives the error *the condition has length > 1*. `sapply(c(95, 40, 60), grade)` returns `"A" "F" "C"`.
- c) The mean of `1 2 3 10` is 4, and only 10 is above it, so the result is `1`.

## 5. Weighted Grades
- **A.)** `matrix(x, 2)` is `1 3 / 2 4`. Multiplying it by itself gives `7 15 / 10 22`:
  - (1·1 + 3·2 = 7)
  - (1·3 + 3·4 = 15)
  - (2·1 + 4·2 = 10)
  - (2·3 + 4·4 = 22)
- **B.)** Row 2 is `2 4 6 8`, so the answer is **6**.
- **C.)** `"character"`: a matrix has one type, so the numbers are coerced to text.
- **D.)** `3 4`
- **E.)** `1.5 3.5 5.5`

```r
wmean <- function(x, w) {
  if (length(x) != length(w)) stop("x and w must have the same length!")
  sum(x * w) / sum(w)
}

apply(grades, 1, wmean, w = c(0.2, 0.3, 0.5))    # a)
```
- b) The final grades are:
  - Ann: 1.2 + 2.1 + 4.0 = **7.3**
  - Ben: 1.8 + 1.5 + 3.0 = **6.3**
  - Carla: 0.8 + 2.4 + 4.5 = **7.7**
- c) It gives the **ordinary mean of every exam** (the columns), because all weights are equal: `Exam1 6.33, Exam2 6.67, Exam3 7.67`.

## 6. Tooth Growth
- **A.)** The column is called `M.len`: `arrange(desc(M.len))`.
- **B.)** `theme_bw` is a function and must be called: `theme_bw()`.
- **C.)** After `summarize()`, only `n` and `M.len` are left. Group **first**: `group_by(supp) %>% summarize(...)`.
- **D.)** `transform()` cannot use a column that it creates in the same call. Use two calls, or dplyr's `mutate()`, which can.

lm:
- a) The coefficients are named `"(Intercept)" "suppVC" "dose"`. There are **60** fitted values.
- b) At the same dose, guinea pigs given **VC** have **shorter** teeth than those given **OJ** (the reference level).
- c)
  ```r
  plot(len ~ dose, data = ToothGrowth, col = as.integer(ToothGrowth$supp), pch = 19)
  legend("topleft", legend = levels(ToothGrowth$supp), col = 1:2, pch = 19)
  ```
  `col = ToothGrowth$supp` also works, because a factor is stored as the integer codes 1 and 2.

## 7. Dates and Factors
- **A.)**
  - `seq()` gives `"2000-02-29" "2001-03-01"`. 29 Feb 2001 doesn't exist, so it rolls over.
  - `%m+%` gives `"2001-02-28"`.
- **B.)**
  - `as.numeric(...)` is `10957` (Lecture 3).
  - `weekdays(...)` is `"Saturday"`.
  - `quarters(...)` is `"Q1" "Q2"`.
- **C.)** `Time differences in days` / `[1]  59 299`
- **D.)**
  - `levels(size)` is `"large" "medium" "small"` (alphabetical).
  - `size[2] < size[1]` is `NA`, with the warning *'<' not meaningful for factors*.
  - The relevelled levels are `"small" "large" "medium"`.
- **E.)** `[1] S L S M` with `Levels: L M S`. The levels are renamed in order: large → L, medium → M, small → S.
- **F.)**
  - `sort(size2)` is `[1] S S M L` with `Levels: S < M < L`.
  - `max(size2)` is `[1] L`.

## 8. Coercion
| | Answer |
|---|---|
| `x` | `"logical"`. `sum(x)` is `NA`, and `sum(x, na.rm = TRUE)` is `1`. |
| `y` | `"1.5" "2" "TRUE"` |
| `z` | `"double"`: `2.0` is a double |
| `w` | `"list"`. `unlist(w)` is `"1" "2" "a"`, and coercion happens only at `unlist()`. |
| `as.numeric(...)` | `1.0 2.5 NA`, with a warning |
| `c(1, TRUE, FALSE)` | `1 1 0` |
| `as.integer(factor(...))` | `1 2 1`. The levels are sorted **as text**: `"10" < "5"`. |

## 9. Indexing and data.table
| | Answer |
|---|---|
| A | `"Ann" "Carla" "Eva"` |
| B | `team N` / `A 3` / `B 2` |
| C | `team avg` / `A 85` / `B 67.5` |
| D | `"Carla"` |
| E | `85` |
| F | `25` |
| G | `"Carla" "Dan" "Eva"` (case-sensitive: `"Ann"` has no lowercase `a`) |
| H | `3` (80, 70, 85) |
| I | `FALSE FALSE FALSE TRUE FALSE` |
| J | `9 8 5 3 3` |
| K | `5 3 8 3` |
| L | `3 3` (the matrix is `5 8 / 3 3`) |

```r
# a)
dt[, passed := score >= 75]
# b)
dt[, .(max_score = max(score)), keyby = team]
# c)
dt[team == "A", .(player = name, points = score)]
```

## 10. Regex and Web Scraping
| | Answer |
|---|---|
| A | `TRUE FALSE TRUE FALSE` |
| B | `"NL1234" "de567" "FR89" "BE 1000"` |
| C | `"1234" "567" "89" "1000"` |
| D | `TRUE TRUE FALSE TRUE` |
| E | `"de-567"` |
| F | `"NL-#4" "de-#" "FR-89" "BE #0"` |
| G | `"NL" "de" "FR" "BE"` |

H) Trace of the loop:
- **Iteration 1:**
  - There is no `++` at first.
  - `--` becomes `+`, giving `"8++-2"`.
  - `+-` becomes `-`, and the loop prints **`"8+-2"`**.
- **Iteration 2:**
  - `+-` becomes `-`, and the loop prints **`"8-2"`**.
  - Nothing is left to collapse, so the loop stops.

There are 3 minus signs, which is an odd number, so the result is `-`.

I) Web scraping:
1. `html_table(read_html(url))[[2]]`
2. `.price` is a **class** selector, which can match many elements. `#price` is an **id** selector, which matches one unique element (Lecture 7, CSS selectors).
3. HTML is plain text. You must clean the string (`gsub`) and convert it yourself with `as.numeric()`.
