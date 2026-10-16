# R Programming for Beginners: Practice Exams

There are three exams, each modelled on the structure of the practice exam:

1. **Dataset outputs**: predict what a line of code returns, given a `str()` printout.
2. **RMarkdown**: complete the YAML header and find the mistakes that stop the document from rendering.
3. **Functions**: read a given function and predict, fix or extend it.
4. **data.table: write the code** for a task.
5. **Base R drills**: vectors, factors, lists, strings, NA, matrices and scope.

All datasets are `data.table`s. Try every question without running R first, then check your answers in `R_practice_exams_solutions.md`.

---

# Warm-up: The Original Practice Exam

### 1. Starwars Movie Characters
```r
# A.) length(starwars)
# B.) names(starwars)
# C.) typeof(starwars[,2])
# D.) levels(starwars$gender)
```

### 2. RMarkdown
Complete the YAML header so that (1) the file is rendered into a pdf document, (2) a table of contents with all level 1 and level 2 headers is created automatically, and (3) the sections are numbered. Then find the mistakes in the code chunks of the `airports_merged` file from the practice exam. (The solutions file lists every mistake.)

---

# Practice Exam 1

## 1. Pokémon

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
class(pokemon)

# C.)
typeof(pokemon$legendary)

# D.)
sum(pokemon$legendary)

# E.)
typeof(pokemon[["hp"]])

# F.)
typeof(pokemon[, "hp"])

# G.)
head(pokemon$type2, 4)
```

## 2. RMarkdown

Complete the YAML header so that (1) the file is rendered into an **HTML** document, (2) a table of contents with headers up to **level 3** is created, and (3) the table of contents **floats** at the side of the page.

The file below also contains several mistakes that stop it from rendering. Find all of them.

````markdown
---
title: "Pokémon Report"
author: "Eager Student"
---

```{r setup, include = FALSE}
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

## 3. Functions: summarise_vec()

```r
summarise_vec <- function(x, digits = 2) {
  if (!is.numeric(x)) {
    stop("x must be numeric")
  }
  res <- c(mean      = mean(x, na.rm = TRUE),
           sd        = sd(x, na.rm = TRUE),
           n_missing = sum(is.na(x)))
  round(res, digits)
}
```

```r
# A.)  What does this return?
summarise_vec(c(2, 4, NA, 6))

# B.)  What does this return?
summarise_vec(c("a", "b"))

# C.)  What does this return?
summarise_vec(c(1, 2), digits = 0)

# D.)  What kind of object does the function return (type, length, names)?

# E.)  What does this return? Describe the shape of the result.
sapply(pokemon[, .(hp, attack, speed)], summarise_vec)
```

F.) Extend the function with an argument `max` that, if `TRUE` (the default should be `FALSE`), also adds the maximum to the result.

## 4. data.table: Write the Code

a) Add a column `speed_class` that is `"fast"` if `speed > 100`, `"average"` if `speed` is between 50 and 100 (inclusive), and `"slow"` otherwise.

b) For each `type1`, compute the number of Pokémon and their mean `hp`. Sort the result by mean `hp`, highest first.

c) How many legendary Pokémon are there in each generation?

d) Return the names of the 3 Pokémon with the highest `attack`.

e) How many Pokémon have no second type?

## 5. Base R Drills

```r
x <- c(4, 8, 15, 16, 23, 42)
# A.) x[2:4]        B.) x[-1]          C.) x[x > 15]       D.) which(x > 15)
# E.) x * c(1, 0)   F.) c(1, "2", TRUE)  G.) typeof(c(1L, 2.5))
# H.) sum(c(TRUE, FALSE, TRUE, TRUE))

sizes <- c("small", "large", "medium", "small")
f  <- factor(sizes)
f2 <- factor(sizes, levels = c("small", "medium", "large"))
# I.) levels(f)     J.) as.integer(f)    K.) as.integer(f2)   L.) table(f2)
```

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
dim(titanic)

# B.)
mean(titanic$age)

# C.)
is.na(titanic$age[1:6])

# D.)
unique(titanic$pclass)

# E.)
class(titanic[2, ])

# F.)
titanic[1:3, survived]

# G.)
levels(factor(titanic$embarked[1:4]))
```

## 2. RMarkdown

Complete the YAML header so that (1) the file is rendered into a **pdf** document, (2) a table of contents with **level 1 headers only** is created, and (3) the **date** field always shows the current date, using inline R code.

The file below contains several mistakes that stop it from rendering. Find all of them. Also, the inline sentence would render, but it shows a useless number. Why, and how do you fix it?

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

## 3. Functions: draw_curve()

The function `draw_curve()` draws any single-variable mathematical function over a sequence of values:

```r
draw_curve <- function(f, from = -5, to = 5, n = 100, ...) {
  x <- seq(from, to, length.out = n)
  y <- f(x)
  plot(x, y, type = "l", ...)
  invisible(data.frame(x = x, y = y))
}
```

```r
# A.)  What does this draw?
draw_curve(sin, from = 0, to = 2 * pi)

# B.)  Which x and y values are computed here?
res <- draw_curve(function(x) x^2, n = 5)
res$y

# C.)  What is the purpose of `...` here? Where do col and main end up?
draw_curve(exp, from = 0, to = 2, col = "red", main = "Exponential")

# D.)  Why does the function end with invisible(...) instead of just the data.frame?

# E.)  What happens here, and why?
draw_curve("sqrt")

# F.)  What happens here? (Hint: look at the default `from`.)
draw_curve(sqrt)
```

G.) Rewrite `draw_curve()` so that it uses `ggplot2` (`geom_line()`) instead of base `plot()`, and returns the ggplot object.

## 4. data.table: Write the Code

a) Compute the survival rate (the proportion who survived) per passenger class, sorted by class.

b) Count the passengers for every combination of `sex` and `pclass`.

c) Add a column `age_group` that is `"child"` for passengers under 18 and `"adult"` otherwise. What value does a passenger with a missing age get?

d) Select the **names and fares** of all female first-class passengers who paid a fare above 100.

e) What is the mean age of survivors versus non-survivors? Missing ages should be ignored.

## 5. Base R Drills

```r
person <- list(name = "Ada", age = 36, langs = c("R", "Python"))
# A.) length(person)   B.) person$langs[2]   C.) person[[1]]
# D.) class(person[1]) E.) person$email

# F.)
for (i in 1:5) { if (i %% 2 == 0) next; print(i^2) }
# G.)
x <- 0; while (x < 10) x <- x + 3; x
# H.) seq(2, 11, by = 3)   I.) rep(c("a","b"), times = 2)   J.) rep(c("a","b"), each = 2)

s <- "Data Science with R"
# K.) nchar(s)   L.) toupper(substr(s, 1, 4))   M.) strsplit(s, " ")[[1]][2]
# N.) paste0("x", 1:3, collapse = " + ")   O.) grepl("an", c("cat","dog","banana","Ant"))
```

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
ncol(spotify)

# B.)
nlevels(spotify$genre)

# C.)
class(spotify$genre)

# D.)
typeof(spotify$genre)

# E.)
spotify[[3]][1:2]

# F.)
mean(spotify$explicit)

# G.)
spotify[, .N]
```

## 2. RMarkdown

Complete the YAML header so that (1) the file is rendered into a **Word** document, and (2) a table of contents with headers up to **level 2** is created. In addition, (3) change the setup chunk so that, for the **whole document**, no code and no messages are shown in the output.

The file below contains several mistakes that stop it from rendering. Find all of them.

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

## 3. Functions: count_above()

```r
count_above <- function(dt, col, threshold) {
  counter <- 0
  for (i in 1:nrow(dt)) {
    if (dt[[col]][i] > threshold) {
      counter <- counter + 1
    }
  }
  counter
}
```

```r
# A.)  What does this return (describe it)?
count_above(spotify, "popularity", 80)

# B.)  What happens here, and why?
count_above(spotify, popularity, 80)

# C.)  The column `danceability` contains one NA. What happens here?
count_above(spotify, "danceability", 0.5)

# D.)  `empty <- spotify[year > 3000]` has 0 rows. What should count_above(empty, "year", 0)
#      return, and what does it actually do? Which small change fixes it?
```

E.) Rewrite the whole function body as **one vectorised line** without a loop, so that it also handles `NA`s.

F.) What does `sapply(c(60, 70, 80, 90), function(t) count_above(spotify, "popularity", t))` return?

## 4. data.table: Write the Code

a) Add a column `duration_min` containing the song length in minutes.

b) Compute the average popularity per genre and sort it from most to least popular.

c) How many explicit songs were released in each year from 2015 onward?

d) Which 5 artists have the most songs in the dataset?

e) Using **chaining**, keep songs from 2010 or later, compute the mean danceability per genre, and sort in descending order, all in one expression.

f) Use `ggplot2` to draw a histogram of `popularity`, filled by `explicit`.

## 5. Base R Drills

```r
v <- c(3, NA, 7, 1)
# A.) v > 2   B.) sum(v > 2)   C.) sum(v > 2, na.rm = TRUE)   D.) v[!is.na(v)]
# E.) NA == NA   F.) length(NA); length(NULL)

m <- matrix(1:6, nrow = 2)
# G.) m (write it down as printed)   H.) m[2, 3]   I.) apply(m, 1, sum)   J.) apply(m, 2, max)

f <- function(x, y = 2) x^y
# K.) f(3)   L.) f(y = 1, x = 5)

g <- function(v) { v[1] <- 100; v }
a <- c(1, 2, 3)
# M.) g(a); a

z <- 10
k <- function() { z <- 20; z }
# N.) k(); z
```
