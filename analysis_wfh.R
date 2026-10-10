###############################################################################
#  Working from home (WFH) in US census tracts – ACS 5-year 2020-2024
#  Assignment 2, questions 1-4
#
#  HOW TO USE THIS SCRIPT (for R beginners)
#  ----------------------------------------
#  * Run it line by line in RStudio: put the cursor on a line and press
#    Ctrl+Enter (Cmd+Enter on a Mac). The result appears in the Console.
#  * Everything after a "#" is a comment: R ignores it. Comments explain
#    what the code does and why.
#  * The script only uses "base R" (no extra packages), so nothing needs
#    to be installed.
#  * Figures for the main text / appendix are saved as .png files in a
#    folder called "figures".
###############################################################################


# =============================================================================
# 0. SET-UP
# =============================================================================

# Remove all objects from memory so we start with a clean slate.
rm(list = ls())

# Tell R in which folder your files are. Change the path to YOUR folder!
# (In RStudio you can also use: Session > Set Working Directory > To Source
#  File Location.)
# setwd("C:/Users/yourname/Documents/assignment2")

# The names of the two data files (group 18 = Massachusetts).
data_file        <- "a2_data_group_18.csv"
description_file <- "data_description_acs.csv"

# Create a folder for the figures. showWarnings = FALSE means: do not
# complain if the folder already exists.
dir.create("figures", showWarnings = FALSE)


# =============================================================================
# QUESTION 1 – Load and inspect the data, treat strange values, small tracts
# =============================================================================

# ---- 1a. Load the data ------------------------------------------------------

# read.csv() reads a comma-separated file into a "data frame" (a table:
# rows = census tracts, columns = variables). We store it under the name "df".
# colClasses = c(geoid = "character") tells R to read the tract code as TEXT,
# as the description file says. Otherwise R would treat it as a number
# (and, for states with a leading 0 such as Alabama "01", drop that 0).
df <- read.csv(data_file, colClasses = c(geoid = "character"))

# The description file tells us what each variable means.
desc <- read.csv(description_file)

# ---- 1b. First look at the data ---------------------------------------------

dim(df)        # number of rows (tracts) and columns (variables)
names(df)      # the names of all variables
head(df)       # the first 6 rows
str(df)        # the type of each column (num = number, chr = text, ...)
summary(df)    # min, quartiles, mean, max and number of NA's per column
print(desc)    # what each variable means

# Store the original number of tracts so we can report it later.
n_start <- nrow(df)

# ---- 1c. Look for "impossible" values ---------------------------------------

# The Census Bureau API uses special negative numbers ("annotation values")
# instead of a real estimate when no estimate can be published. See:
# https://www.census.gov/data/developers/data-sets/acs-1year/notes-on-acs-estimate-and-annotation-values.html
#
#   -666666666 : estimate could not be computed – too few sample observations
#                (e.g. a median in a tract where (almost) nobody owns a house)
#   -999999999 : too few sample cases to display the estimate / MOE
#   -888888888 : not applicable or not available
#   -555555555 : estimate is controlled; a margin of error is not appropriate
#   -333333333 : median falls in the lowest or highest open-ended interval
#   -222222222 : margin of error could not be computed (too few observations)
#
# These are CODES, not real numbers: a median income of -666 million dollars
# does not exist. If we leave them in, a single code value would completely
# dominate every mean, plot and regression. So we will set them to NA
# ("not available" = missing), which is how R represents missing data.

# Which columns are numeric? sapply() applies the function is.numeric() to
# every column and returns TRUE/FALSE for each column.
num_cols <- names(df)[sapply(df, is.numeric)]

# All codes are smaller than -100,000,000, and no real ACS estimate is that
# negative. For every numeric column, count how many values are below it.
# na.rm = TRUE tells sum() to ignore values that are already missing.
n_codes <- sapply(df[num_cols], function(x) sum(x < -100000000, na.rm = TRUE))
n_codes[n_codes > 0]          # only show the columns that contain codes

# Which code values occur exactly? unlist() puts all columns in one long
# vector, then table() counts how often each code occurs.
all_values <- unlist(df[num_cols])
table(all_values[all_values < -100000000])

# Replace every code by NA. We loop over the numeric columns: in each round
# of the loop, "col" is the name of one column.
for (col in num_cols) {
  is_code <- !is.na(df[[col]]) & df[[col]] < -100000000   # TRUE where a code is
  df[[col]][is_code] <- NA                               # overwrite with NA
}

# Check: there should be no codes left (the result should be 0).
sum(sapply(df[num_cols], function(x) sum(x < -100000000, na.rm = TRUE)))

# How many missing values per column do we have now?
colSums(is.na(df))

# ---- 1d. Tracts without (or with very few) inhabitants ----------------------

# The total population is in the column "pop" (see the description file).
# NOTE: the description file also lists "workers", but that column is NOT in
# our data file (check with: "workers" %in% names(df)). So we use "pop".
pop_var <- "pop"
"workers" %in% names(df)

summary(df[[pop_var]])

# How many tracts have 0 inhabitants, and how many fewer than 100 / 300 / 1200?
# (1,200 is the lower bound of the Census Bureau's guideline for tract size.)
sum(df[[pop_var]] == 0,    na.rm = TRUE)
sum(df[[pop_var]] < 100,   na.rm = TRUE)
sum(df[[pop_var]] < 300,   na.rm = TRUE)
sum(df[[pop_var]] < 1200,  na.rm = TRUE)

# Show the smallest tracts. order() gives the row numbers sorted from small
# to large population; we look at the 30 smallest.
small <- df[order(df[[pop_var]]), ]
head(small[, c("geoid", "county", "pop", "pct_wfh", "med_hh_income")], 30)

# The last 6 digits of geoid are the tract code. substr(text, 6, 7) takes
# characters 6 and 7 = the first two digits of the tract code. Codes 98xx are
# "special land-use" tracts (parks, airports, ...), codes 99xx are water-only.
df$tract_prefix <- substr(df$geoid, 6, 7)
table(df$tract_prefix[df[[pop_var]] < 300])

# Histogram of population, with a vertical line at our cut-off.
png("figures/hist_population.png", width = 800, height = 600)
hist(df[[pop_var]], breaks = 100,
     main = "Population per census tract",
     xlab = "Number of inhabitants", ylab = "Number of tracts")
abline(v = 300, col = "red", lwd = 2)     # red line at 300 inhabitants
invisible(dev.off())                       # close (= save) the png file

# Our decision (explain this in your report):
#  * Tracts with 0 inhabitants (water areas, parks, airports, ...) have no
#    workers, so pct_wfh cannot be computed: they are not neighbourhoods
#    the company serves with residential electricity.
#  * Tracts with very few inhabitants (here: Logan airport, harbour islands,
#    parks - all with tract codes 98xx/99xx) rest on only a handful of survey
#    responses, so their percentages are extremely noisy (pct_wfh is 0% or
#    100% in several of them). There is a clear gap in the data between 202
#    and 453 inhabitants, so we drop tracts with fewer than 300 inhabitants.
#  * Tracts where the dependent variable pct_wfh is missing cannot be used.
min_pop <- 300

# Keep only rows that satisfy all conditions. "&" means AND, "!" means NOT.
keep <- !is.na(df[[pop_var]]) & df[[pop_var]] >= min_pop & !is.na(df$pct_wfh)
df   <- df[keep, ]

# Report how many tracts were removed and how many remain.
n_after <- nrow(df)
cat("Tracts at the start:", n_start, "\n",
    "Tracts removed     :", n_start - n_after, "\n",
    "Tracts remaining   :", n_after, "\n")

# Missing values left in the independent variables (after the cleaning).
# Regressions later will drop rows with NA in any variable that is used.
na_left <- colSums(is.na(df))
na_left[na_left > 0]


# =============================================================================
# QUESTION 2 – Median home value and median household income
# =============================================================================

# ---- 2a. Histograms ---------------------------------------------------------

png("figures/hist_med_value_income.png", width = 1200, height = 500)
par(mfrow = c(1, 2))        # put two plots next to each other (1 row, 2 cols)

hist(df$med_value, breaks = 100,
     main = "Median home value", xlab = "US dollars", ylab = "Number of tracts")

hist(df$med_hh_income, breaks = 100,
     main = "Median household income", xlab = "US dollars",
     ylab = "Number of tracts")

par(mfrow = c(1, 1))        # back to one plot per figure
invisible(dev.off())   # close (= save) the png file

# ---- 2b. Do several tracts share exactly the same maximum value? ------------

max_value  <- max(df$med_value,     na.rm = TRUE)
max_income <- max(df$med_hh_income, na.rm = TRUE)
max_value
max_income

# Count how many tracts have exactly that maximum.
sum(df$med_value     == max_value,  na.rm = TRUE)
sum(df$med_hh_income == max_income, na.rm = TRUE)

# The 5 most frequent values: a "spike" at the top is clearly visible.
# sort(..., decreasing = TRUE) puts the largest counts first.
head(sort(table(df$med_value),     decreasing = TRUE), 5)
head(sort(table(df$med_hh_income), decreasing = TRUE), 5)

# Explanation (see the same Census page as above, and the table notes):
# The ACS TOP-CODES medians. A median home value above $2,000,000 is
# published as "2,000,000+" and returned by the API as 2000001; a median
# household income above $250,000 is published as "250,000+" = 250001.
# (Similarly, there are bottom codes: "9,999-" for value, "2,499-" for
# income.) So all tracts at the maximum have "at least" that value; their
# true value is unknown and may be much higher. The variable is CENSORED.
#
# Consequence for prediction: for the richest tracts the predictor is
# measured with error and is flat at the top, while pct_wfh may still rise.
# A linear slope estimated on these data would be biased (usually too flat)
# at the top, and we cannot tell apart a $2.1m and a $5m neighbourhood.
#
# The same problem exists for other medians in the data. Let us check every
# "med_" variable: how many tracts sit exactly at the max and at the min?
for (v in c("med_age", "med_rooms", "med_year_built", "med_rent",
            "med_value", "med_hh_income")) {
  cat(v, ": max =", max(df[[v]], na.rm = TRUE),
      "(", sum(df[[v]] == max(df[[v]], na.rm = TRUE), na.rm = TRUE), "tracts )",
      " min =", min(df[[v]], na.rm = TRUE),
      "(", sum(df[[v]] == min(df[[v]], na.rm = TRUE), na.rm = TRUE), "tracts )\n")
}
# -> med_rent is top-coded at 3501 ("3,500+") and med_year_built is
#    bottom-coded at 1938 / "1939 or earlier": a huge group in old
#    Massachusetts towns. We flag those too.

# Our choice: KEEP the tracts (they are real, often high-WFH neighbourhoods;
# dropping them would remove exactly the interesting tail), keep the
# top-coded value, and ADD a dummy (0/1) variable that equals 1 for
# top-coded tracts. In a regression this dummy absorbs the average
# difference of the top-coded group, so the slope of the continuous
# variable is estimated on the uncensored tracts. We also create log
# versions, because both variables are strongly right-skewed.

df$topcode_value  <- as.numeric(df$med_value     >= 2000001)  # TRUE/FALSE -> 1/0
df$topcode_income <- as.numeric(df$med_hh_income >= 250001)

table(df$topcode_value,  useNA = "ifany")   # how many 0's, 1's and NA's
table(df$topcode_income, useNA = "ifany")

df$topcode_rent     <- as.numeric(df$med_rent >= 3501)
df$built_pre1939    <- as.numeric(df$med_year_built <= 1938)
table(df$topcode_rent,  useNA = "ifany")
table(df$built_pre1939, useNA = "ifany")

df$log_med_value     <- log(df$med_value)
df$log_med_hh_income <- log(df$med_hh_income)


# =============================================================================
# QUESTION 3 – Exploratory analysis: scatter plots and correlations
# =============================================================================

# ---- 3a. Correlation of pct_wfh with ALL numeric variables ------------------

# Numeric columns of the cleaned data, without the dependent variable itself.
num_cols <- names(df)[sapply(df, is.numeric)]
x_vars   <- setdiff(num_cols, "pct_wfh")
# If your data has ID columns (e.g. GEOID, state, county, tract), remove them,
# because a correlation with an ID number is meaningless:
# (geoid, state and county were read as text, so they are not in num_cols.)
# We also leave out our own 0/1 flags; they are not real neighbourhood
# characteristics.
x_vars   <- setdiff(x_vars, c("topcode_value", "topcode_income",
                              "topcode_rent", "built_pre1939"))

# For each variable compute the correlation with pct_wfh.
# use = "complete.obs": only use tracts where both values are not NA.
cor_pearson <- sapply(x_vars, function(v)
  cor(df$pct_wfh, df[[v]], use = "complete.obs"))

# Spearman (rank) correlation: robust to outliers and to non-linear but
# monotone relations – useful because many variables are skewed.
cor_spearman <- sapply(x_vars, function(v)
  cor(df$pct_wfh, df[[v]], use = "complete.obs", method = "spearman"))

# Put them in a table, sorted from most positive to most negative.
cor_table <- data.frame(variable = x_vars,
                        pearson  = round(cor_pearson, 2),
                        spearman = round(cor_spearman, 2))
cor_table <- cor_table[order(cor_table$pearson, decreasing = TRUE), ]
rownames(cor_table) <- NULL     # remove the row names for a clean print
print(cor_table)

# Save the table so you can put it in your report / appendix.
write.csv(cor_table, "figures/correlations_with_pct_wfh.csv", row.names = FALSE)

# ---- 3b. Histogram of the dependent variable --------------------------------

png("figures/hist_pct_wfh.png", width = 800, height = 600)
hist(df$pct_wfh, breaks = 60, main = "Share of workers working from home",
     xlab = "pct_wfh (%)", ylab = "Number of tracts")
invisible(dev.off())   # close (= save) the png file

# ---- 3c. Scatter plots ------------------------------------------------------

# A function = a small reusable piece of code. This one draws a scatter
# plot of pct_wfh against variable v and adds a straight (linear) fit line
# and a smooth (lowess) curve that can show non-linear patterns.
scatter_wfh <- function(v) {
  ok <- !is.na(df[[v]]) & !is.na(df$pct_wfh)          # rows without NA
  plot(df[[v]][ok], df$pct_wfh[ok],
       pch = 16, cex = 0.4, col = rgb(0, 0, 0, 0.25),  # small transparent dots
       xlab = v, ylab = "pct_wfh (%)",
       main = paste0(v, "   (r = ", round(cor_pearson[v], 2), ")"))
  abline(lm(df$pct_wfh[ok] ~ df[[v]][ok]), col = "red", lwd = 2)   # linear fit
  lines(lowess(df[[v]][ok], df$pct_wfh[ok]), col = "blue", lwd = 2) # smooth
}

# Main text: a selection of 4 variables, chosen from the theory (education,
# income, occupation, commuting). !!! Replace them by the exact names in
# your data if they differ.
main_vars <- c("pct_bachelor_plus", "occ_mgmt_sci", "log_med_hh_income",
               "occ_production", "pct_broadband", "mean_commute")
main_vars <- intersect(main_vars, names(df))   # keep only names that exist

png("figures/scatter_main.png", width = 1500, height = 1000)
par(mfrow = c(2, 3))
for (v in main_vars) scatter_wfh(v)
par(mfrow = c(1, 1))
invisible(dev.off())   # close (= save) the png file

# Appendix: ALL independent variables, 9 plots (3 x 3) per figure.
# seq(1, n, by = 9) gives the start positions 1, 10, 19, ...
starts <- seq(1, length(x_vars), by = 9)
for (i in seq_along(starts)) {
  vars_page <- x_vars[starts[i]:min(starts[i] + 8, length(x_vars))]
  png(paste0("figures/appendix_scatter_", i, ".png"), width = 1500, height = 1500)
  par(mfrow = c(3, 3))
  for (v in vars_page) scatter_wfh(v)
  par(mfrow = c(1, 1))
  invisible(dev.off())   # close (= save) the png file
}


# =============================================================================
# QUESTION 4 – Shares of commuters vs. shares of all workers
# =============================================================================

# Small demonstration of the problem with made-up numbers.
# Take a tract with 1,000 workers of whom 300 work from home.
# All workers are in exactly one category:
#   drive alone + carpool + public transport + walk/bike/other + WFH = 1,000
# So if we divided "drive alone" by ALL workers, the shares would add up to
# 100% together with pct_wfh: every extra percentage point of WFH would
# mechanically remove a percentage point from the commuting modes.

# We can show this with the real data. Convert the commuter share into a
# share of all workers:  share_all = share_commuters * (100 - pct_wfh) / 100
drive_var <- "pct_drive_alone"

if (drive_var %in% names(df)) {
  drive_all <- df[[drive_var]] * (100 - df$pct_wfh) / 100

  # Correlation with pct_wfh: as share of commuters vs. as share of all workers
  cat("Correlation pct_wfh with", drive_var, "(share of commuters):",
      round(cor(df$pct_wfh, df[[drive_var]], use = "complete.obs"), 2), "\n")
  cat("Correlation pct_wfh with", drive_var, "(share of ALL workers):",
      round(cor(df$pct_wfh, drive_all, use = "complete.obs"), 2), "\n")

  png("figures/q4_commuters_vs_allworkers.png", width = 1200, height = 500)
  par(mfrow = c(1, 2))
  plot(df[[drive_var]], df$pct_wfh, pch = 16, cex = 0.4,
       xlab = "Drive alone (% of commuters)", ylab = "pct_wfh (%)",
       main = "As share of commuters (as in data)")
  plot(drive_all, df$pct_wfh, pch = 16, cex = 0.4,
       xlab = "Drive alone (% of all workers)", ylab = "pct_wfh (%)",
       main = "As share of all workers (mechanical)")
  par(mfrow = c(1, 1))
  invisible(dev.off())   # close (= save) the png file
}
