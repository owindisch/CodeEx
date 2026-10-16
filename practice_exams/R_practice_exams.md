# R Programming for Beginners: Practice Exams

There are three exams. Each one follows the 8-part structure of the practice exam:

| # | Part | What you do |
|---|------|-------------|
| 1 | Dataset | Predict the output of operations on a `str()` printout |
| 2 | RMarkdown | Complete the YAML header and spot the mistakes that stop rendering |
| 3 | Plotting function | Give the function calls that produce the plots shown |
| 4 | Writing functions | Fill in the blanks of small algorithms (`if`/`else`, indexing, `stop()`) |
| 5 | Statistics functions + `apply()` | Write a formula as a function and apply it to a data matrix |
| 6 | dplyr debugging + `lm()` | Find the bug behind each error message and use the model output |
| 7 | Data vectors | Use `range()`/`min()`/`max()` on dates, factors and ordered factors |
| 8 | Coercion | Predict the result of `typeof()` after a replacement |

Solutions with explanations are in `R_practice_exams_solutions.md`. That file also contains the solutions to **the original practice exam** (Starwars, airports, `draw_curve`, medians, city temperatures, penguins, data vectors, coercion).

---
---

# Practice Exam 1

## 1. Pokémon

The `pokemon` dataset contains all Pokémon of the first seven generations:

```
> str(pokemon)
Classes 'data.table' and 'data.frame':  800 obs. of  9 variables:
 $ name      : chr  "Bulbasaur" "Ivysaur" "Venusaur" "Charmander" ...
 $ type1     : chr  "Grass" "Grass" "Grass" "Fire" ...
 $ type2     : chr  "Poison" "Poison" "Poison" NA ...
 $ hp        : int  45 60 80 39 58 78 44 59 79 45 ...
 $ attack    : int  49 62 82 52 64 84 48 63 83 30 ...
 $ defense   : int  49 63 83 43 58 78 65 80 100 35 ...
 $ speed     : int  45 60 80 65 80 100 43 58 78 45 ...
 $ generation: int  1 1 1 1 1 1 1 1 1 1 ...
 $ legendary : logi  FALSE FALSE FALSE FALSE FALSE FALSE ...
```

What is the output of the following data operations?

```r
# A.)
nrow(pokemon)

# B.)
typeof(pokemon[, "hp"])

# C.)
typeof(pokemon[["hp"]])

# D.)
levels(pokemon$type1)

# E.)
head(pokemon$type2, 4)
```

## 2. RMarkdown

Complete the YAML header so that (1) the file is rendered into an **HTML** document, (2) a table of contents with all level 1 to level **3** headers is created automatically, and (3) the table of contents **floats** at the side of the page.

The RMarkdown file also contains several mistakes, so R won't render it and gives an error message instead. Spot the mistakes in the embedded code chunks so that the document can be rendered.

````markdown
---
title: "Pokémon Report"
author: "Eager Student"
---

```{r setup, include = FALSE}
knitr::opts_chunk$set(echo = TRUE)
library(data.table)
library(ggplot2)
pokemon <- fread("pokemon.csv")
```

# Attack vs. Defense

```{r scatter, fig.width = 6}
ggplot(pokemon, aes(x = attack, y = defense, colour = legendary) +
  geom_point()
```

```{r gen-table, eval = True}
pokemon[, .(mean_hp = mean(hp)), by = generation]
```

The dataset contains `r nrow(Pokemon)` Pokémon.

```{r summary, echo = FALSE, message = FALSE warning = FALSE}
summary(pokemon)
```
````

## 3. draw_curve()

The function `draw_curve()` below draws any single-variable mathematical function for a given sequence of values:

```r
draw_curve <- function(fun = cos, from = 0, to = 2 * pi, length.out = 50,
                       col = "blue", type = "l") {

  x <- seq(from = from, to = to, length.out = length.out)
  y <- fun(x)

  if (type == "dots") {
    plot(x, y, col = col, pch = 19)
  }
  else {
    plot(x, y, col = col, type = type)
  }
}
```

Provide the function calls that produce the following curves:

![Exam 1 plots](figures/exam1_q3.png)

Plot A has red vertical lines. Plot B has 50 open blue circles. Plot C has a dark-green line from 0 to 10. Plot D has 10 filled red points.

## 4. Means

The arithmetic mean is the sum of all elements divided by the number of elements. Complete the code below to write a function `my.mean()` that computes the mean **with a for-loop** (without `sum()` or `mean()`):

```r
my.mean <- function(x){
  total <- 0
  for(___ in ___){
    total <- ___
  }
  ___
}

my.mean(c(2, 4, 9))
# 5
```

The **trimmed mean** discards the `k` smallest and the `k` largest values before computing the mean. Complete `trim.mean()`. If the vector has `2*k` elements or fewer, the function should stop with the error message `"k is too large!"`.

```r
trim.mean <- function(x, k = 1){
  ___(length(x) <= 2 * k) ___("k is too large!")
  x <- sort(x)
  my.mean(x[___])
}

trim.mean(c(100, 1, 2, 3, -50))
# 2
trim.mean(1:10, k = 3)
# 5.5
```

Finally, the **geometric mean** of positive numbers is `exp(mean(log(x)))`. Complete the code below so that `geo.mean()` uses your `my.mean()` and stops if any element is not positive:

```r
___ {
  if(___) stop("all values must be positive!")
  ___
}

geo.mean(c(1, 10, 100))
# 10
```

## 5. Exam Scores

The sample standard deviation is the square root of the sample variance:

`sd(x) = sqrt( sum((x - mean(x))^2) / (n - 1) )`

Complete the code below to write a function `my.sd()`:

```r
my.sd <- function(x) {
  n <- length(x)
  if (n < 2) stop("x must have at least 2 elements!")
  ___
}
```

The **standard error of the mean** is `se(x) = sd(x) / sqrt(n)`. Complete `my.se()` using `my.sd()`:

```r
my.se <- function(x) {
  ___
}
```

Consider the matrix `scores` with exam points of students (rows) in four subjects (columns):

```
> scores
       Math Stats Programming English
Ann      78    85          92      64
Ben      55    61          70      88
Carla    91    94          99      72
David    67    70          58      81
Eva      83    77          88      90
```

a) Apply `my.se()` to get the standard error for **every subject**.
b) Apply `my.mean()` from part 4 to get the average score of **every student**.
c) What is `dim(scores)`, and what is the length of your result in a)?

## 6. Fuel Economy (`mpg`)

You are writing a report on the `mpg` dataset (234 cars, from the `ggplot2` package):

```
> head(mpg)
# A tibble: 6 × 11
  manufacturer model displ  year   cyl trans      drv     cty   hwy fl    class
  <chr>        <chr> <dbl> <int> <int> <chr>      <chr> <int> <int> <chr> <chr>
1 audi         a4      1.8  1999     4 auto(l5)   f        18    29 p     compact
2 audi         a4      1.8  1999     4 manual(m5) f        21    29 p     compact
3 audi         a4      2    2008     4 manual(m6) f        20    31 p     compact
4 audi         a4      2    2008     4 auto(av)   f        21    30 p     compact
5 audi         a4      2.8  1999     6 auto(l5)   f        16    26 p     compact
6 audi         a4      2.8  1999     6 manual(m5) f        18    26 p     compact
```

A colleague's data-exploration code is not working. Spot the mistake in each snippet that causes the error message.

```r
# A.)
mpg %>%
  mutate(cty_kml = cty * 0.425,
         hwy_kml = hwy * 0.425) %>%
  summarize(M.city = mean(cty_kmpl),
            M.highway = mean(hwy_kml))

Error in `summarize()`:
  In argument: `M.city = mean(cty_kmpl)`.
Caused by error:
  object 'cty_kmpl' not found

# B.)
mpg %>%
  filter(year = 2008) %>%
  select(manufacturer, model, hwy)

Error in `filter()`:
  We detected a named input.
  This usually means that you've used `=` instead of `==`.

# C.)
mpg %>%
  group_by(class) %>%
  summarize(total = n, M.hwy = mean(hwy))

Error in `summarize()`:
  In argument: `total = n`.
Caused by error:
  `total` must be a vector, not a function.

# D.)
mpg %>%
  select(manufacturer, model, hwy) %>%
  arrange(desc(cty))

Error in `arrange()`:
  Caused by error:
  object 'cty' not found
```

Next, you look at how the drive train `drv` (`"4"`, `"f"`, `"r"`) influences highway mileage:

```r
res <- lm(hwy ~ drv, data = mpg)
```

a) What do `length(res$coefficients)` and `length(res$residuals)` return?

b) Fill in the blanks so that the plot shows boxplots of `hwy` per drive train in grey, the model predictions per drive train in **blue** on top of them, and a legend in the top right:

```r
boxplot(___, data = mpg, xlab = "drive train")
boxplot(___, data = mpg,
        border = "blue", outline = FALSE, add = TRUE)
legend(___, ___, col = "blue", lwd = 2)
```

c) Why does every blue "box" collapse to a single line?

## 7. Data Vectors

Give the results of the following operations on dates, a factor and an ordered factor.

```r
# A.)
dates <- as.Date(c("2024-03-01", "2024-02-28", "2024-03-03"))

range(dates)

diff(range(dates))

# B.)
mon <- months(dates)
mon
[1] "March"    "February" "March"

range(factor(mon))

# C.)
sizes <- factor(c("M", "XL", "S", "M"),
                levels = c("S", "M", "L", "XL"), ordered = TRUE)

range(sizes)

sizes > "M"

table(sizes)

# D.)
range(c("banana", "Apple", "cherry"))
```

## 8. Coercion

Remember that a vector can only hold one data type. What does `typeof()` return after each replacement: logical, integer, double or character?

```r
A <- c(1.5, 2, 3)
A[2] <- 7L
typeof(A)

B <- 1:5
B[6] <- 2.5
typeof(B)

C <- c(TRUE, FALSE)
C[2] <- "FALSE"
typeof(C)

D <- 1:3
D[5] <- 10L
typeof(D)
D            # also give the printed vector!

E <- c("x", "y")
E[1] <- NA
typeof(E)
```

---
---

# Practice Exam 2

## 1. Titanic Passengers

```
> str(titanic)
Classes 'data.table' and 'data.frame':  891 obs. of  8 variables:
 $ passenger_id: int  1 2 3 4 5 6 7 8 9 10 ...
 $ survived    : int  0 1 1 1 0 0 0 0 1 1 ...
 $ pclass      : int  3 1 3 1 3 3 1 3 3 2 ...
 $ name        : chr  "Braund, Mr. Owen Harris" "Cumings, Mrs. John Bradley" ...
 $ sex         : chr  "male" "female" "female" "female" ...
 $ age         : num  22 38 26 35 35 NA 54 2 27 14 ...
 $ fare        : num  7.25 71.28 7.92 53.1 8.05 ...
 $ embarked    : chr  "S" "C" "S" "S" ...
```

What is the output of the following data operations?

```r
# A.)
length(titanic)

# B.)
mean(titanic$age)

# C.)
unique(titanic$pclass)

# D.)
class(titanic[, survived])

# E.)
levels(factor(titanic$embarked[1:4]))
```

## 2. RMarkdown

Complete the YAML header so that (1) the file is rendered into a **pdf** document, (2) a table of contents with **only level 1** headers is created, and (3) the `date` field always shows **today's date** (use inline R code).

The file below contains several mistakes that stop it from rendering. Spot them. The inline sentence in the "Age" section would render, but it shows a useless value. Why, and how do you fix it?

````markdown
---
title: "Titanic Analysis"
author: "Eager Student"
---

```{r setup, include = FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

# Survival by Class

```{r survival-plot, fig.cap = Survival rate per class}
ggplot(rates, aes(x = factor(pclass), y = rate)) +
  geom_col()
```

```{r load-data, include = FALSE}
library(data.table)
library(ggplot2)
titanic <- fread("titanic.csv)
rates <- titanic[, .(rate = mean(survived)), by = pclass]
```

# Age

The average passenger age was `r mean(titanic$age)` years.

```{r load-data}
hist(titanic$age)
```
````

## 3. draw_points()

The function `draw_points()` draws any single-variable function as points, optionally connected with a dashed line:

```r
draw_points <- function(fun = function(x) x^2, from = -2, to = 2, by = 0.5,
                        col = "black", pch = 1, line = FALSE) {

  x <- seq(from = from, to = to, by = by)
  y <- fun(x)

  plot(x, y, col = col, pch = pch)
  if (line) {
    lines(x, y, col = col, lty = 2)
  }
}
```

Provide the function calls that produce the following plots. (`pch = 1`: open circle, `pch = 17`: filled triangle, `pch = 19`: filled circle.)

![Exam 2 plots](figures/exam2_q3.png)

Plot A has 9 open black circles. Plot B has filled dark-orange circles from 0 to 3. Plot C has purple triangles with a dashed line, 17 points.

How many points does `draw_points(from = 0, to = 10, by = 2)` draw?

## 4. Cumulative Sums and Maxima

The cumulative sum of a vector is a vector of the same length whose i-th element is the sum of the first i elements. For example, `c(3, 1, 4, 1)` gives `c(3, 4, 8, 9)`. Complete the code below so that `my.cumsum()` works **without** `cumsum()` or `sum()`:

```r
my.cumsum <- function(x){
  out <- numeric(length(x))
  out[1] <- ___
  for(i in ___){
    out[i] <- ___
  }
  out
}
```

Complete `my.which.max()`, which returns the **position** of the (first) maximum of `x` without using `which.max()` or `max()`:

```r
my.which.max <- function(x){
  pos <- 1
  for(i in seq_along(x)){
    if(___){
      ___
    }
  }
  ___
}

my.which.max(c(4, 9, 2, 9))
# 2
```

Min-max **normalisation** rescales a vector to the interval [0, 1]: `(x - min(x)) / (max(x) - min(x))`. Complete the function so that it stops with the message `"all values are equal!"` if the denominator would be 0:

```r
normalize <- function(x){
  ___
  ___
}

normalize(c(2, 4, 6, 10))
# 0.00 0.25 0.50 1.00
```

## 5. Step Counts

The **z-score** standardises a vector: `z(x) = (x - mean(x)) / sd(x)`.

a) Write `my.sd()` (sample standard deviation, see the formula in Exam 1, Part 5) from scratch.

b) Complete `my.zscore()` using `my.sd()`:

```r
my.zscore <- function(x) {
  if (length(x) < 2) stop("x is not a vector!")
  ___
}
```

Consider the matrix `steps` with daily step counts for four persons:

```
> steps
       Mon   Tue   Wed   Thu   Fri   Sat   Sun
Anna  8200  7500  9100  8800  7900 12000  4300
Bilal 4100  5200  3900  6100  4500  9800 11000
Chen 10500 11200  9800 10100 12300  6400  7000
Dana  6000  6000  6000  6000  6000  6000  6000
```

c) Apply `my.sd()` to every **person**.
d) Apply `my.zscore()` to every person. What are the dimensions of the result, and why do you need `t()` to get one person per row back?
e) Which person causes a problem in d), and what happens?

## 6. Diamonds

You analyse the `diamonds` dataset (53,940 diamonds, from `ggplot2`):

```
> head(diamonds, 3)
# A tibble: 3 × 10
  carat cut     color clarity depth table price     x     y     z
  <dbl> <ord>   <ord> <ord>   <dbl> <dbl> <int> <dbl> <dbl> <dbl>
1  0.23 Ideal   E     SI2      61.5    55   326  3.95  3.98  2.43
2  0.21 Premium E     SI1      59.8    61   326  3.89  3.84  2.31
3  0.23 Good    E     VS1      56.9    65   327  4.05  4.07  2.31
```

Spot the mistake in each snippet:

```r
# A.)
diamonds %>%
  filter(cut == Ideal) %>%
  summarize(M.price = mean(price))

Error in `filter()`:
  In argument: `cut == Ideal`.
Caused by error:
  object 'Ideal' not found

# B.)
diamonds %>%
  group_by(cut) %>%
  summarize(M.price = mean(price)) %>%
  arrange(desc(price))

Error in `arrange()`:
  Caused by error:
  object 'price' not found

# C.)
diamonds %>%
  mutate(price_eur = price * 0.92) %>%
  ggplot(aes(x = carat, y = price_eur)) %>%
  geom_point()

Error in `geom_point()`:
  `mapping` must be created by `aes()`.
  Did you use `%>%` or `|>` instead of `+`?

# D.)
diamonds %>%
  select(carat, price) %>%
  group_by(cut) %>%
  summarize(M.ppc = mean(price / carat))

Error in `group_by()`:
  Must group by variables found in `.data`.
  Column `cut` is not found.
```

Next, you fit a model for the price:

```r
res <- lm(price ~ carat + cut, data = diamonds)
```

a) How many elements do `res$fitted.values` and `res$coefficients` have? (`cut` has 5 levels.)

b) Fill in the blanks to draw a **residual plot**: the model predictions on the x-axis, the residuals on the y-axis, and a red horizontal reference line at 0:

```r
plot(x = ___, y = ___, xlab = "fitted values", ylab = "residuals")
abline(___ = 0, col = "red", lwd = 2)
```

## 7. Data Vectors

```r
# A.)
dates <- as.Date("2024-12-30") + 0:3
dates

range(dates[format(dates, "%Y") == "2025"])

# B.)
wd <- weekdays(dates)
wd
[1] "Monday"    "Tuesday"   "Wednesday" "Thursday"

f <- factor(wd, levels = c("Monday", "Tuesday", "Wednesday",
                           "Thursday", "Friday"), ordered = TRUE)
range(f)

max(f[f < "Wednesday"])

# C.)
grades <- factor(c("B", "A", "C", "B"),
                 levels = c("C", "B", "A"),
                 labels = c("fair", "good", "excellent"), ordered = TRUE)
grades

range(grades)

as.integer(grades)

# D.)
range(c(10, 2, 33))

range(c("10", "2", "33"))
```

## 8. Coercion

What does `typeof()` return, and what does the vector look like?

```r
A <- c(TRUE, FALSE, TRUE)
A[2] <- 3.5
typeof(A); A

B <- letters[1:3]
B[2] <- TRUE
typeof(B); B

C <- 1:4
C[2] <- NA
typeof(C)

D <- c(1L, 2L)
D[2] <- 2
typeof(D)

E <- list(1, "a")
E[[2]] <- TRUE
typeof(E)

x <- c(1, "2", 3)
sum(x)
sum(as.numeric(x))
```

---
---

# Practice Exam 3

## 1. Spotify Songs

```
> str(spotify)
Classes 'data.table' and 'data.frame':  2000 obs. of  8 variables:
 $ track       : chr  "Blinding Lights" "Shape of You" "Someone You Loved" ...
 $ artist      : chr  "The Weeknd" "Ed Sheeran" "Lewis Capaldi" ...
 $ year        : int  2019 2017 2018 2019 2016 ...
 $ duration_ms : int  200040 233712 182160 174000 ...
 $ popularity  : int  91 87 84 80 77 ...
 $ explicit    : logi  FALSE FALSE FALSE TRUE FALSE ...
 $ genre       : Factor w/ 6 levels "hip hop","latin",..: 4 4 4 1 3 ...
 $ danceability: num  0.514 0.825 0.501 0.733 0.648 ...
```

What is the output of the following data operations?

```r
# A.)
dim(spotify)

# B.)
class(spotify$genre)

# C.)
typeof(spotify$genre)

# D.)
spotify[[3]][1:2]

# E.)
mean(spotify$explicit)    # describe what the number means
```

## 2. RMarkdown

Complete the YAML header so that (1) the file is rendered into a **Word** document, and (2) a table of contents with headers up to **level 2** is created. In addition, (3) change the setup chunk so that, for the **whole document**, no code and no messages appear in the output.

Spot the mistakes that stop the file from rendering:

````markdown
---
title: "Spotify Trends"
author: "Eager Student"
---

```{r setup, include = FALSE}
knitr::opts_chunk$set(echo = TRUE)
library(ggplot2)
spotify <- fread("spotify.csv")
```

# Popularity by Genre

```{r boxplot}
ggplot(Spotify, aes(x = genre, y = popularity)) +
  geom_boxplot
```

```{r counts, results = hide}
spotify[, .N, by = genre]
``

# Conclusion

Pop is the most popular genre.
````

## 3. draw_curve()

```r
draw_curve <- function(fun = function(x) x^3, from = -2, to = 2,
                       length.out = 41, col = "black", type = "l",
                       zero = FALSE) {

  x <- seq(from = from, to = to, length.out = length.out)
  y <- fun(x)

  plot(x, y, col = col, type = type)
  if (zero) {
    abline(h = 0, col = "grey", lty = 2)
  }
}
```

Provide the function calls that produce the following plots. (`type = "s"` draws steps, and `type = "b"` draws both points and lines.)

![Exam 3 plots](figures/exam3_q3.png)

Plot B has red open circles with a dashed grey line at y = 0. Plot C is a dark-green step curve of |x|. Plot D is blue, has 6 points, and covers 0 ≤ x ≤ 1.

## 4. Maxima and Top-k

Complete `my.max()`, which returns the largest element of `x` using a loop (without `max()`, `sort()` or `range()`):

```r
my.max <- function(x){
  current <- ___
  for(v in ___){
    if(___) current <- v
  }
  current
}

my.max(c(3, 8, 1, 8, 5))
# 8
```

Complete `top.k()`, which returns the `k` largest values in decreasing order. If `k` is larger than the length of `x`, the whole sorted vector is returned:

```r
top.k <- function(x, k = 3){
  x <- sort(___, decreasing = ___)
  ___(k > length(x)){
    return(___)
  }
  x[___]
}

top.k(c(5, 1, 9, 7, 3))
# 9 7 5
top.k(c(2, 4), k = 5)
# 4 2
```

Write `my.range.width()`, which returns `max(x) - min(x)` using **only** `my.max()`. (Hint: the minimum of `x` is minus the maximum of `-x`.)

```r
___ {
  if(length(x) < 2) stop("x is not a vector!")
  ___
}
my.range.width(c(4, -2, 7))
# 9
```

## 5. Stock Prices

The daily **percent change** of a price series is

`pct(x) = (x[t] - x[t-1]) / x[t-1] * 100` for t = 2, …, n

a) Complete `pct.change()` with **vector operations** (no loop). Hint: `diff()` and `head(x, -1)`.

```r
pct.change <- function(x) {
  if (length(x) < 2) stop("x must have at least 2 elements!")
  ___
}
```

b) The **volatility** of a stock is the standard deviation of its percent changes. Complete `volatility()` using `pct.change()` and `sd()`:

```r
volatility <- function(x) {
  ___
}
```

Consider the matrix `stocks` with closing prices for one week:

```
> stocks
        Mon   Tue   Wed   Thu   Fri
ACME  100.0 102.0  99.0 101.5 104.0
Globex 50.0  50.5  51.0  50.0  52.0
Initech 20.0 18.0  21.0  19.5  20.5
```

c) Apply `volatility()` to every stock (row). Which stock do you expect to be the most volatile?
d) What are the dimensions of `apply(stocks, 1, pct.change)`? What are its row names and column names?
e) What is the first value of `pct.change(stocks["ACME", ])`?

## 6. Star Wars (dplyr)

This time you use the tibble version `dplyr::starwars` (87 characters, with columns `name`, `height`, `mass`, `hair_color`, `gender`, `homeworld`, `species`, …). Spot the mistakes:

```r
# A.)
starwars %>%
  filter(species == "Human") %>%
  summarize(avg = mean(height, na.rm = TRUE)) %>%
  pull(avg_height)

Error in `pull()`:
  Can't extract columns that don't exist.
  Column `avg_height` doesn't exist.

# B.)
starwars %>%
  group_by(species) %>%
  summarize(n = n() M.height = mean(height, na.rm = TRUE))

Error: unexpected symbol in:
"  group_by(species) %>%
  summarize(n = n() M.height"

# C.)
starwars %>%
  select(name, height, mass) %>%
  left_join(planets, by = "homeworld")

Error in `left_join()`:
  Join columns in `x` must be present in the data.
  Problem with `homeworld`.

# D.)  No error, but the sd column contains only NA. Why?
starwars %>%
  group_by(gender) %>%
  summarize(height = mean(height, na.rm = TRUE),
            sd     = sd(height, na.rm = TRUE))
```

You model mass by height:

```r
res <- lm(mass ~ height, data = starwars)
```

a) `mass` has 28 missing values and `height` has 6. Every character with a missing height is also missing its mass. How long is `res$residuals`?

b) Fill in the blanks to draw a scatterplot of mass against height with the regression line in red:

```r
plot(___, data = starwars)
abline(___, col = "red", lwd = 2)
```

c) One character (Jabba, 1358 kg) has a huge residual. Which element of `res` would you use to find the largest residual, and which function returns its position?

## 7. Data Vectors

```r
# A.)
dates <- as.Date(c("2024-01-15", "2023-11-02", "2024-07-30"))

range(dates)

diff(range(dates))

format(range(dates), "%B")

# B.)
range(factor(months(dates)))

# C.)
level <- factor(c("high", "low", "medium", "high"),
                levels = c("low", "medium", "high"), ordered = TRUE)

min(level)

range(level[level != "low"])

# D.)
range(c(TRUE, FALSE, TRUE))

range(numeric(0))
```

## 8. Coercion

```r
A <- seq(0, 1, by = 0.25)
A[1] <- "zero"
typeof(A)

B <- c(a = 1L, b = 2L)
B["c"] <- 3L
typeof(B); B

C <- rep(NA, 3)
typeof(C)
C[1] <- 5L
typeof(C)

D <- as.Date("2024-01-01")
typeof(D); class(D)

E <- factor(c("10", "20", "10"))
as.numeric(E)
as.numeric(as.character(E))
```
