# R Programming for Beginners: Practice Exams

There are three exams. They follow the same format as the Star Wars practice exam: a dataset is described with `str()`, and you either **predict what a line of code returns** or **write the code** for a task. All datasets are `data.table`s unless stated otherwise.

Try every question without running R first, then check your answers in `R_practice_exams_solutions.md`.

---

## Warm-up: the original Star Wars question

```r
# A.) length(starwars)
# B.) names(starwars)
# C.) typeof(starwars[,2])
# D.) levels(starwars$gender)
```

(The solutions are in the solutions file. Look carefully at C and D!)

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

What does each line return? Give the value, or describe it precisely if the value cannot be known from the output above.

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

## 2. Vectors and Coercion

```r
x <- c(4, 8, 15, 16, 23, 42)

# A.)
x[2:4]

# B.)
x[-1]

# C.)
x[x > 15]

# D.)
which(x > 15)

# E.)
x * c(1, 0)

# F.)
c(1, "2", TRUE)

# G.)
typeof(c(1L, 2.5))

# H.)
sum(c(TRUE, FALSE, TRUE, TRUE))
```

## 3. Factors

```r
sizes <- c("small", "large", "medium", "small")
f  <- factor(sizes)
f2 <- factor(sizes, levels = c("small", "medium", "large"))

# A.)
levels(f)

# B.)
as.integer(f)

# C.)
as.integer(f2)

# D.)
nlevels(f2)

# E.)
table(f2)
```

## 4. data.table Syntax: What Happens?

For each line, describe **what kind of object** comes back (vector, single value, or data.table) and **what it contains**.

```r
# A.)
pokemon[hp > 100]

# B.)
pokemon[, mean(attack)]

# C.)
pokemon[, .(avg_speed = mean(speed)), by = generation]

# D.)
pokemon[order(-attack)][1:3, name]

# E.)
pokemon[is.na(type2), .N]

# F.)  (What happens to `pokemon`?)
pokemon[, strong := attack > 100]
```

## 5. Write the Code

a) Write a function `classify_speed(s)` that takes **one** number and returns `"fast"` if `s > 100`, `"average"` if `s` is between 50 and 100 (inclusive), and `"slow"` otherwise. Use `if` / `else if` / `else`.

b) Add a column `speed_class` to `pokemon` that holds the same classification for **every** row. Your solution must be vectorised, so you cannot call your function from a) in a loop.

c) For each `type1`, compute the number of Pokémon and their mean `hp`. Sort the result by mean `hp`, highest first.

d) How many legendary Pokémon are there in each generation?

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
titanic$sex[2] == "female"

# F.)
class(titanic[2, ])

# G.)
titanic[1:3, survived]
```

## 2. Lists

```r
person <- list(name = "Ada", age = 36, langs = c("R", "Python"))

# A.)
length(person)

# B.)
person$langs[2]

# C.)
person[[1]]

# D.)
class(person[1])

# E.)
person$email

# F.)
length(person$langs)
```

## 3. Control Flow and Sequences: Predict the Output

```r
# A.)
for (i in 1:5) {
  if (i %% 2 == 0) next
  print(i^2)
}

# B.)
x <- 0
while (x < 10) x <- x + 3
x

# C.)
sapply(1:4, function(k) k * 10)

# D.)
seq(2, 11, by = 3)

# E.)
rep(c("a", "b"), times = 2)

# F.)
rep(c("a", "b"), each = 2)

# G.)
ifelse(c(5, -2, 0) > 0, "pos", "not pos")
```

## 4. Strings

```r
s <- "Data Science with R"

# A.)
nchar(s)

# B.)
toupper(substr(s, 1, 4))

# C.)
strsplit(s, " ")[[1]][2]

# D.)
paste("R", 1:3, sep = "_")

# E.)
paste0("x", 1:3, collapse = " + ")

# F.)
grepl("an", c("cat", "dog", "banana", "Ant"))
```

## 5. Write the Code (titanic)

a) Compute the survival rate (the proportion who survived) for each passenger class, sorted by class.

b) Count the passengers for every combination of `sex` and `pclass`.

c) Add a column `age_group` that is `"child"` for passengers under 18 and `"adult"` otherwise. What value does a passenger with a missing age get with your code?

d) Select the **names and fares** of all female first-class passengers who paid a fare above 100.

e) What is the mean age of survivors versus non-survivors? Missing ages should be ignored.

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
summary(spotify$popularity)   # describe what is shown
```

## 2. Logicals and Missing Values

```r
v <- c(3, NA, 7, 1)

# A.)
v > 2

# B.)
sum(v > 2)

# C.)
sum(v > 2, na.rm = TRUE)

# D.)
v[!is.na(v)]

# E.)
NA == NA

# F.)
length(NA); length(NULL)

# G.)
max(v, na.rm = TRUE)

# H.)
any(v > 5, na.rm = TRUE); all(v > 0, na.rm = TRUE)
```

## 3. Matrices and apply

```r
m <- matrix(1:6, nrow = 2)

# A.)  Write down m as R would print it.
m

# B.)
dim(m)

# C.)
m[2, 3]

# D.)
m[, 2]

# E.)
apply(m, 1, sum)

# F.)
apply(m, 2, max)

# G.)
dim(t(m))
```

## 4. Functions and Scope

```r
f <- function(x, y = 2) x^y

# A.)
f(3)

# B.)
f(2, 3)

# C.)
f(y = 1, x = 5)

g <- function(v) { v[1] <- 100; v }
a <- c(1, 2, 3)
# D.)  What do g(a) and then a return?
g(a)
a

h <- function(n) if (n <= 1) 1 else n * h(n - 1)
# E.)
h(5)

z <- 10
k <- function() { z <- 20; z }
# F.)  What do k() and then z return?
k()
z
```

## 5. Write the Code (spotify)

a) Add a column `duration_min` containing the song length in minutes.

b) Compute the average popularity per genre and sort it from most to least popular.

c) How many explicit songs were released in each year from 2015 onward?

d) Which 5 artists have the most songs in the dataset?

e) Using **chaining**, keep songs from 2010 or later, compute the mean danceability per genre, and sort the result in descending order, all in one expression.

f) Use base R to draw (i) a histogram of `popularity` and (ii) boxplots of `popularity` by `genre`.
