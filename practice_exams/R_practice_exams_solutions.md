# R Practice Exams: Solutions

Each answer comes with a short explanation, because the explanation is what you need to learn for the exam.

---

## Warm-up: Star Wars

| | Code | Answer | Why |
|---|---|---|---|
| A | `length(starwars)` | `9` | A data.frame/data.table is a **list of columns**, so `length()` counts columns, not rows. |
| B | `names(starwars)` | `"name" "height" "mass" "skin_color" "eye_color" "birth_year" "gender" "homeworld" "species"` | The column names. |
| C | `typeof(starwars[,2])` | `"list"` | **Trap!** On a `data.table`, `starwars[,2]` returns a one-column *data.table*, which is a list. On a plain `data.frame` it would drop to a vector, and the answer would be `"integer"`. Use `starwars[[2]]` or `starwars$height` to get the vector. |
| D | `levels(starwars$gender)` | `NULL` | `gender` is `chr`, not a factor. Character vectors have no levels. |

---

# Exam 1

### 1. Pokémon
| | Answer | Explanation |
|---|---|---|
| A | `800` | Number of rows (obs.). |
| B | `"data.table" "data.frame"` | A data.table also inherits from data.frame. |
| C | `"logical"` | `logi` in `str()`. |
| D | A single integer: the **number of legendary Pokémon** | `TRUE` counts as 1 and `FALSE` as 0. |
| E | `"integer"` | `[[ ]]` extracts the column as a vector. |
| F | `"list"` | `[, "hp"]` on a data.table returns a data.table. |
| G | `"Poison" "Poison" "Poison" NA` | `NA` is printed without quotes. |

### 2. Vectors and Coercion
| | Answer | Explanation |
|---|---|---|
| A | `8 15 16` | Positions 2, 3 and 4. |
| B | `8 15 16 23 42` | A negative index **drops** that element. |
| C | `16 23 42` | Logical indexing returns the values. |
| D | `4 5 6` | `which()` returns **positions**, not values. |
| E | `4 0 15 0 23 0` | Recycling: `c(1,0)` repeats to length 6. |
| F | `"1" "2" "TRUE"` | A vector has one type, and character wins (logical < integer < double < character). |
| G | `"double"` | Integer + double → double. |
| H | `3` | Three `TRUE`s. |

### 3. Factors
| | Answer | Explanation |
|---|---|---|
| A | `"large" "medium" "small"` | Default levels are sorted **alphabetically**. |
| B | `3 1 2 3` | The internal codes refer to that alphabetical order. |
| C | `1 3 2 1` | The levels are now in the order you specified. |
| D | `3` | |
| E | `small 2, medium 1, large 1` | `table()` follows level order. |

### 4. data.table Syntax
| | Result |
|---|---|
| A | A **data.table** with all columns and only the rows where `hp > 100` (`i` filters rows). |
| B | A **single number**: the mean attack over all rows. |
| C | A **data.table** with columns `generation` and `avg_speed`, one row per generation. |
| D | A **character vector** with the names of the 3 Pokémon that have the highest attack (`-` sorts descending). |
| E | A **single integer**: the number of Pokémon with no second type. |
| F | Returns nothing visible, but `pokemon` now has a new logical column `strong`. `:=` modifies the table **by reference**, so no `<-` is needed. |

### 5. Code
```r
# a)
classify_speed <- function(s) {
  if (s > 100) {
    "fast"
  } else if (s >= 50) {
    "average"
  } else {
    "slow"
  }
}

# b) vectorised (fcase is from data.table; nested ifelse/fifelse also works)
pokemon[, speed_class := fcase(speed > 100, "fast",
                               speed >= 50, "average",
                               default = "slow")]
# alternative:
pokemon[, speed_class := ifelse(speed > 100, "fast",
                         ifelse(speed >= 50, "average", "slow"))]

# c)
pokemon[, .(n = .N, mean_hp = mean(hp)), by = type1][order(-mean_hp)]

# d)
pokemon[legendary == TRUE, .N, by = generation]
# or: pokemon[, .(n_legendary = sum(legendary)), by = generation]
```
Note that `if` only works on **one** value and gives an error if `s` has length > 1. That is why b) needs `ifelse`/`fcase`.

---

# Exam 2

### 1. Titanic
| | Answer | Explanation |
|---|---|---|
| A | `891 8` | rows, columns |
| B | `NA` | One `NA` makes the whole mean `NA`. Use `na.rm = TRUE`. |
| C | `FALSE FALSE FALSE FALSE FALSE TRUE` | |
| D | `3 1 2` | `unique()` keeps the order of **first appearance**, not sorted order. |
| E | `TRUE` | |
| F | `"data.table" "data.frame"` | A row of a data.table is still a data.table. |
| G | `0 1 1` | In data.table, `j` can use bare column names, so this returns an integer vector. |

### 2. Lists
| | Answer | Explanation |
|---|---|---|
| A | `3` | Three elements. |
| B | `"Python"` | |
| C | `"Ada"` | `[[ ]]` returns the element itself. |
| D | `"list"` | `[ ]` on a list returns a **smaller list**. |
| E | `NULL` | Elements that do not exist return `NULL`, not an error. |
| F | `2` | |

### 3. Control Flow
| | Answer | Explanation |
|---|---|---|
| A | `[1] 1`, `[1] 9`, `[1] 25` | `next` skips the even numbers. |
| B | `12` | 0 → 3 → 6 → 9 → 12. The loop stops once `x >= 10`. |
| C | `10 20 30 40` | |
| D | `2 5 8 11` | |
| E | `"a" "b" "a" "b"` | |
| F | `"a" "a" "b" "b"` | |
| G | `"pos" "not pos" "not pos"` | 0 is not `> 0`. |

### 4. Strings
| | Answer | Explanation |
|---|---|---|
| A | `19` | Spaces count. |
| B | `"DATA"` | |
| C | `"Science"` | `strsplit` returns a **list**, hence the `[[1]]`. |
| D | `"R_1" "R_2" "R_3"` | |
| E | `"x1 + x2 + x3"` | `collapse` joins everything into **one** string. |
| F | `FALSE FALSE TRUE FALSE` | Matching is case-sensitive, so `"Ant"` does not contain `"an"`. |

### 5. Code
```r
# a)
titanic[, .(survival_rate = mean(survived)), by = pclass][order(pclass)]

# b)
titanic[, .N, by = .(sex, pclass)]

# c)
titanic[, age_group := fifelse(age < 18, "child", "adult")]
# Missing ages give NA, because NA < 18 is NA.

# d)
titanic[sex == "female" & pclass == 1 & fare > 100, .(name, fare)]

# e)
titanic[, .(mean_age = mean(age, na.rm = TRUE)), by = survived]
```

---

# Exam 3

### 1. Spotify
| | Answer | Explanation |
|---|---|---|
| A | `8` | |
| B | `6` | |
| C | `"factor"` | |
| D | `"integer"` | **Trap!** Factors are stored as integer codes with a levels attribute. |
| E | `2019 2017` | Column 3 is `year`. |
| F | A number between 0 and 1: the **proportion of explicit songs** | The mean of a logical vector is the share of `TRUE`. |
| G | Six numbers: Min, 1st Qu., Median, Mean, 3rd Qu., Max | |

### 2. Logicals and NA
| | Answer | Explanation |
|---|---|---|
| A | `TRUE NA TRUE FALSE` | Comparing with `NA` gives `NA`. |
| B | `NA` | |
| C | `2` | |
| D | `3 7 1` | |
| E | `NA` | R cannot know whether two unknowns are equal. Use `is.na()`. |
| F | `1` and `0` | `NA` is a value of length 1. `NULL` is "nothing". |
| G | `7` | |
| H | `TRUE` and `TRUE` | |

### 3. Matrices
| | Answer |
|---|---|
| A | <pre>     [,1] [,2] [,3]<br>[1,]    1    3    5<br>[2,]    2    4    6</pre> Matrices are filled **column by column**. |
| B | `2 3` |
| C | `6` |
| D | `3 4` |
| E | `9 12` (row sums, `MARGIN = 1`) |
| F | `2 4 6` (column maxima, `MARGIN = 2`) |
| G | `3 2` |

### 4. Functions and Scope
| | Answer | Explanation |
|---|---|---|
| A | `9` | The default `y = 2` is used. |
| B | `8` | |
| C | `5` | Named arguments can come in any order. |
| D | `100 2 3`, then `1 2 3` | R functions work on a **copy**, so `a` is unchanged. |
| E | `120` | Recursion: 5·4·3·2·1. |
| F | `20`, then `10` | The `z` inside the function is **local**. The global `z` is untouched. |

### 5. Code
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
hist(spotify$popularity, main = "Song popularity", xlab = "Popularity")
boxplot(popularity ~ genre, data = spotify)
```

---

## The Most Common Traps

1. `length(df)` counts **columns**. Use `nrow()` for rows.
2. `DT[, 2]` / `DT[, "col"]` returns a data.table (a list). `DT[[2]]`, `DT$col` and `DT[, col]` return a vector.
3. `typeof(factor)` is `"integer"`, while `class(factor)` is `"factor"`.
4. Calling `levels()` on a character vector gives `NULL`.
5. Any `NA` in `mean`/`sum`/`max` gives `NA` unless you add `na.rm = TRUE`.
6. `[ ]` on a list returns a list. `[[ ]]` returns the element.
7. Mixed vectors are coerced: logical < integer < double < character.
8. `unique()` keeps the order of first appearance. `factor()` levels are sorted alphabetically.
