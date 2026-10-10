###############################################################################
#  Working from home (WFH) in US census tracts – ACS 5-year 2020-2024
#  Assignment 2, questions 1-4  –  group 18 (Massachusetts)
#
#  HOW TO USE THIS SCRIPT (for R beginners)
#  ----------------------------------------
#  * Run it line by line in RStudio: put the cursor on a line and press
#    Ctrl+Enter (Cmd+Enter on a Mac). The result appears in the Console.
#  * Everything after a "#" is a comment: R ignores it. Comments explain
#    what the code does and why.
#  * We use the "tidyverse": a collection of packages (dplyr, readr, tidyr,
#    ggplot2, ...) that share the same style. Two ideas you see everywhere:
#
#      1. The PIPE  |>   "take the result on the left and give it to the
#         function on the right". So   df |> filter(pop > 0)   means
#         "take df, then keep the rows where pop > 0". Read |> as "and then".
#         (You may also see %>% in other code: it does the same thing.)
#
#      2. ggplot2 builds a plot in LAYERS that you add with "+":
#           ggplot(data, aes(x = ..., y = ...))   # data and which columns
#           + geom_point()                        # what to draw (points)
#           + labs(title = ...)                   # titles and axis labels
#
#  * Figures are saved as .png files in the folder "figures".
###############################################################################


# =============================================================================
# 0. SET-UP
# =============================================================================

# Install the tidyverse ONCE on your computer (remove the "#" to run it).
# install.packages("tidyverse")

# Load the packages. You must do this every time you start R.
library(tidyverse)

# Remove all objects from memory so we start with a clean slate.
rm(list = ls())

# Tell R in which folder your files are. Change the path to YOUR folder!
# (In RStudio: Session > Set Working Directory > To Source File Location.)
# setwd("C:/Users/yourname/Documents/assignment2")

# The names of the two data files (group 18 = Massachusetts).
data_file        <- "a2_data_group_18.csv"
description_file <- "data_description_acs.csv"

# Create a folder for the figures (no warning if it already exists).
dir.create("figures", showWarnings = FALSE)

# A clean, simple look for all ggplot figures in this script.
theme_set(theme_minimal(base_size = 13))


# =============================================================================
# QUESTION 1 – Load and inspect the data, treat strange values, small tracts
# =============================================================================

# ---- 1a. Load the data ------------------------------------------------------

# read_csv() (from the readr package) reads a comma-separated file into a
# "tibble" = the tidyverse version of a table (rows = tracts, columns =
# variables). col_types = cols(geoid = col_character()) tells R to read the
# tract code as TEXT, as the description file says. Otherwise R would treat
# it as a number (and for states like Alabama "01..." drop the leading 0).
df   <- read_csv(data_file, col_types = cols(geoid = col_character()))
desc <- read_csv(description_file)

# ---- 1b. First look at the data ---------------------------------------------

dim(df)          # number of rows (tracts) and columns (variables)
glimpse(df)      # every column: its name, type (dbl = number, chr = text)
                 # and the first values
summary(df)      # min, quartiles, mean, max and number of NA's per column
print(desc, n = Inf)   # what each variable means (n = Inf: show all rows)

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
#   -222222222 : margin of error could not be computed (too few observations)
#
# These are CODES, not real numbers. We will set them to NA (= missing).

# Count, for every numeric column, how many values are below -100,000,000.
# No real ACS estimate is that negative, so these are all codes.
#   summarise()           : compute one summary number per column
#   across(where(is.numeric), ...) : do it for every numeric column
#   ~ sum(.x < -1e8, ...) : the formula; ".x" stands for "the current column"
#   na.rm = TRUE          : ignore values that are already missing
#   1e8 is R's short way of writing 100,000,000.
code_counts <- df |>
  summarise(across(where(is.numeric), ~ sum(.x < -1e8, na.rm = TRUE))) |>
  pivot_longer(everything(), names_to = "variable", values_to = "n_codes") |>
  filter(n_codes > 0) |>              # only the columns that contain codes
  arrange(desc(n_codes))              # largest number first
code_counts

# Which code values occur exactly? We put all numeric columns below each
# other in one long column ("value") and count the different code values.
df |>
  select(where(is.numeric)) |>
  pivot_longer(everything(), values_to = "value") |>
  filter(value < -1e8) |>
  count(value)

# Replace every code by NA.
#   mutate() changes (or creates) columns.
#   if_else(condition, yes, no): where the value is a code -> NA, else keep it.
df <- df |>
  mutate(across(where(is.numeric), ~ if_else(.x < -1e8, NA, .x)))

# Check: no codes left (should print 0).
df |> select(where(is.numeric)) |> pivot_longer(everything()) |>
  filter(value < -1e8) |> nrow()

# ---- 1d. Tracts without (or with very few) inhabitants ----------------------

# NOTE: the description file lists a variable "workers", but it is NOT in
# our data file (this prints FALSE). So we use the total population "pop".
"workers" %in% names(df)

summary(df$pop)

# How many tracts have 0 inhabitants, or fewer than 100 / 300 / 1200?
# (1,200 is the lower bound of the Census Bureau guideline for tract size.)
df |>
  summarise(pop_0      = sum(pop == 0),
            pop_lt100  = sum(pop < 100),
            pop_lt300  = sum(pop < 300),
            pop_lt1200 = sum(pop < 1200))

# Look at the 30 smallest tracts.
#   str_sub(geoid, 6, 7): characters 6-7 of the code = first two digits of the
#   tract number. 98xx = "special land-use" tract (parks, airports, ...),
#   99xx = water-only tract.
df |>
  mutate(tract_prefix = str_sub(geoid, 6, 7)) |>
  arrange(pop) |>                       # sort from small to large population
  select(geoid, county, tract_prefix, pop, pct_wfh, med_hh_income) |>
  head(30)

# Histogram of population, with a red line at our cut-off of 300.
p_pop <- ggplot(df, aes(x = pop)) +
  geom_histogram(bins = 100, fill = "grey40") +
  geom_vline(xintercept = 300, colour = "red", linewidth = 1) +
  labs(title = "Population per census tract",
       x = "Number of inhabitants", y = "Number of tracts")
p_pop                                      # show the plot in RStudio
ggsave("figures/hist_population.png", p_pop, width = 8, height = 5, bg = "white")

# Our decision (explained in the answers):
#  * Tracts with 0 inhabitants have no workers: pct_wfh cannot be computed.
#  * Tracts with very few inhabitants (all special-use / water tracts here)
#    rest on a handful of survey answers: pct_wfh is often exactly 0 or 100%.
#  * There is a clear gap between 202 and 453 inhabitants -> cut-off 300.
#  * Tracts where pct_wfh is missing cannot be used.
min_pop <- 300

# filter() keeps only the rows for which ALL conditions are TRUE.
df <- df |>
  filter(pop >= min_pop,
         !is.na(pct_wfh))        # "!" means NOT: keep rows where pct_wfh is not NA

# Report how many tracts were removed and how many remain.
n_after <- nrow(df)
cat("Tracts at the start:", n_start, "\n",
    "Tracts removed     :", n_start - n_after, "\n",
    "Tracts remaining   :", n_after, "\n")

# Missing values left per variable (after the cleaning).
df |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  pivot_longer(everything(), names_to = "variable", values_to = "n_missing") |>
  filter(n_missing > 0) |>
  arrange(desc(n_missing))


# =============================================================================
# QUESTION 2 – Median home value and median household income
# =============================================================================

# ---- 2a. Histograms ---------------------------------------------------------

# To draw both histograms in ONE figure, we first make the data "long":
# pivot_longer() turns the two columns into two new columns:
#   "variable" (med_value or med_hh_income) and "value" (the number).
# Then facet_wrap(~ variable) draws one small panel per variable.
# scales = "free" lets each panel have its own axis ranges.
p_hist <- df |>
  select(med_value, med_hh_income) |>
  pivot_longer(everything(), names_to = "variable", values_to = "value") |>
  ggplot(aes(x = value)) +
  geom_histogram(bins = 100, fill = "grey40", na.rm = TRUE) +
  facet_wrap(~ variable, scales = "free") +
  scale_x_continuous(labels = scales::label_dollar()) +   # show $ on the axis
  labs(title = "Median home value and median household income per tract",
       x = "US dollars", y = "Number of tracts")
p_hist
ggsave("figures/hist_med_value_income.png", p_hist, width = 12, height = 5, bg = "white")

# ---- 2b. Do several tracts share exactly the same maximum value? ------------

# For each variable: the maximum, and how many tracts have exactly that value.
df |>
  summarise(max_value      = max(med_value, na.rm = TRUE),
            n_at_max_value = sum(med_value == max(med_value, na.rm = TRUE), na.rm = TRUE),
            max_income     = max(med_hh_income, na.rm = TRUE),
            n_at_max_inc   = sum(med_hh_income == max(med_hh_income, na.rm = TRUE), na.rm = TRUE))

# The 5 most frequent values: a "spike" at the top is clearly visible.
# count(..., sort = TRUE) counts each value and puts the most frequent first.
df |> count(med_value,     sort = TRUE) |> head(5)
df |> count(med_hh_income, sort = TRUE) |> head(5)

# Explanation (see the answers file): the ACS TOP-CODES medians. A median
# home value above $2,000,000 is published as "2,000,000+" (= 2000001 in the
# data), a median household income above $250,000 as "250,000+" (= 250001).
# The true value is unknown and may be much higher: the variable is CENSORED.

# The same problem for the other medians: how many tracts at the max / min?
# We write a small function and apply it to each "med_" variable.
#   map_dfr() runs the function for each name and stacks the results in a table.
at_extremes <- function(v) {
  x <- df[[v]]
  tibble(variable = v,
         max = max(x, na.rm = TRUE), n_at_max = sum(x == max(x, na.rm = TRUE), na.rm = TRUE),
         min = min(x, na.rm = TRUE), n_at_min = sum(x == min(x, na.rm = TRUE), na.rm = TRUE))
}
map_dfr(c("med_age", "med_rooms", "med_year_built", "med_rent",
          "med_value", "med_hh_income"), at_extremes)
# -> med_rent is top-coded at 3501 ("3,500+") and med_year_built is
#    bottom-coded at 1938 ("1939 or earlier"): 389 tracts!

# ---- 2c. Our choice: keep the tracts, add 0/1 flags and log versions -------

# as.numeric(TRUE/FALSE) gives 1/0. log() is the natural logarithm.
df <- df |>
  mutate(topcode_value     = as.numeric(med_value     >= 2000001),
         topcode_income    = as.numeric(med_hh_income >= 250001),
         topcode_rent      = as.numeric(med_rent      >= 3501),
         built_pre1939     = as.numeric(med_year_built <= 1938),
         log_med_value     = log(med_value),
         log_med_hh_income = log(med_hh_income))

# How many tracts have each flag (0, 1 or NA)?
df |> count(topcode_value)
df |> count(topcode_income)
df |> count(topcode_rent)
df |> count(built_pre1939)

# Average WFH in top-coded vs. other tracts.
df |> group_by(topcode_income) |> summarise(mean_wfh = mean(pct_wfh))
df |> group_by(topcode_value)  |> summarise(mean_wfh = mean(pct_wfh))


# =============================================================================
# QUESTION 3 – Exploratory analysis: scatter plots and correlations
# =============================================================================

# ---- 3a. The dependent variable ---------------------------------------------

summary(df$pct_wfh)
quantile(df$pct_wfh, c(0.05, 0.95))     # 5th and 95th percentile

p_wfh <- ggplot(df, aes(x = pct_wfh)) +
  geom_histogram(bins = 60, fill = "grey40") +
  labs(title = "Share of workers working from home",
       x = "pct_wfh (%)", y = "Number of tracts")
p_wfh
ggsave("figures/hist_pct_wfh.png", p_wfh, width = 8, height = 5, bg = "white")

# ---- 3b. Correlation of pct_wfh with ALL numeric variables ------------------

# Names of the independent variables: all numeric columns except pct_wfh
# and our own 0/1 flags (they are not real neighbourhood characteristics).
x_vars <- df |>
  select(where(is.numeric),
         -pct_wfh, -topcode_value, -topcode_income, -topcode_rent, -built_pre1939) |>
  names()

# Make the data long: one row per (tract, variable) combination.
# Then, per variable (group_by), compute two correlations with pct_wfh:
#   Pearson  = strength of the LINEAR relation
#   Spearman = based on ranks; robust to outliers and skewed variables
#   use = "complete.obs": only tracts where both values are not NA
df_long <- df |>
  select(pct_wfh, all_of(x_vars)) |>
  pivot_longer(-pct_wfh, names_to = "variable", values_to = "value")

cor_table <- df_long |>
  group_by(variable) |>
  summarise(pearson  = cor(pct_wfh, value, use = "complete.obs"),
            spearman = cor(pct_wfh, value, use = "complete.obs", method = "spearman"),
            n        = sum(!is.na(value))) |>
  mutate(across(c(pearson, spearman), ~ round(.x, 2))) |>
  arrange(desc(pearson))                 # most positive first

print(cor_table, n = Inf)
write_csv(cor_table, "figures/correlations_with_pct_wfh.csv")

# A bar chart of the correlations: easy to read in a report.
# reorder(variable, pearson) sorts the bars by the size of the correlation.
p_cor <- ggplot(cor_table, aes(x = pearson, y = reorder(variable, pearson),
                               fill = pearson > 0)) +
  geom_col() +
  scale_fill_manual(values = c("TRUE" = "steelblue", "FALSE" = "firebrick"),
                    guide = "none") +                 # no legend needed
  labs(title = "Correlation of each variable with pct_wfh",
       x = "Pearson correlation", y = NULL)
p_cor
ggsave("figures/correlations_bar.png", p_cor, width = 8, height = 9, bg = "white")

# ---- 3c. Scatter plots ------------------------------------------------------

# Main text: six theory-driven variables (education, occupation, income,
# broadband, commuting). facet_wrap() makes one panel per variable.
#   geom_point(alpha = 0.2) : transparent dots, so dense areas look darker
#   geom_smooth(method = "lm")    : red straight line (linear fit)
#   geom_smooth(method = "gam")   : blue smooth curve, shows non-linearity
#                                   (a flexible curve; ggplot2's own default
#                                   for data sets with more than 1,000 rows)
main_vars <- c("pct_bachelor_plus", "occ_mgmt_sci", "log_med_hh_income",
               "occ_production", "pct_broadband", "mean_commute")

p_main <- df_long |>
  filter(variable %in% main_vars) |>
  mutate(variable = factor(variable, levels = main_vars)) |>  # keep our order
  ggplot(aes(x = value, y = pct_wfh)) +
  geom_point(alpha = 0.2, size = 0.7, na.rm = TRUE) +
  geom_smooth(method = "lm",    formula = y ~ x, colour = "red",  se = FALSE, na.rm = TRUE) +
  geom_smooth(method = "gam", formula = y ~ s(x, bs = "cs"), colour = "blue", se = FALSE, na.rm = TRUE) +
  facet_wrap(~ variable, scales = "free_x") +
  labs(title = "Share working from home vs. selected tract characteristics",
       subtitle = "Red: linear fit; blue: smooth (GAM) curve",
       x = NULL, y = "pct_wfh (%)")
p_main
ggsave("figures/scatter_main.png", p_main, width = 12, height = 8, bg = "white")

# Appendix: ALL independent variables, 9 panels (3 x 3) per page.
# We split the variable names into groups of 9 and make one figure per group.
#   split(x, ceiling(seq_along(x) / 9)) : list of groups of (at most) 9 names
var_pages <- split(x_vars, ceiling(seq_along(x_vars) / 9))

for (i in seq_along(var_pages)) {
  p_app <- df_long |>
    filter(variable %in% var_pages[[i]]) |>
    ggplot(aes(x = value, y = pct_wfh)) +
    geom_point(alpha = 0.2, size = 0.5, na.rm = TRUE) +
    geom_smooth(method = "lm",    formula = y ~ x, colour = "red",  se = FALSE, na.rm = TRUE) +
    geom_smooth(method = "gam", formula = y ~ s(x, bs = "cs"), colour = "blue", se = FALSE, na.rm = TRUE) +
    facet_wrap(~ variable, scales = "free_x", ncol = 3) +
    labs(title = paste("Appendix figure", i, ": pct_wfh vs. independent variables"),
         x = NULL, y = "pct_wfh (%)")
  ggsave(paste0("figures/appendix_scatter_", i, ".png"), p_app, width = 12, height = 11, bg = "white")
}


# =============================================================================
# QUESTION 4 – Shares of commuters vs. shares of all workers
# =============================================================================

# All workers are in exactly one category:
#   drive alone + carpool + public transport + walk/bike/other + WFH = 100%
# pct_drive_alone in our data is a share of COMMUTERS (workers not at home).
# Re-computed as a share of ALL workers it would be:
#   share_all = share_commuters * (100 - pct_wfh) / 100
# which falls automatically when pct_wfh rises. Let us show this.

df <- df |>
  mutate(drive_alone_allworkers = pct_drive_alone * (100 - pct_wfh) / 100)

# Correlation with pct_wfh for both versions.
df |>
  summarise(r_share_of_commuters   = cor(pct_wfh, pct_drive_alone,        use = "complete.obs"),
            r_share_of_all_workers = cor(pct_wfh, drive_alone_allworkers, use = "complete.obs"))

# Side-by-side scatter plots of the two versions.
p_q4 <- df |>
  select(pct_wfh,
         `Drive alone, % of commuters (as in data)`        = pct_drive_alone,
         `Drive alone, % of all workers (mechanical link)` = drive_alone_allworkers) |>
  pivot_longer(-pct_wfh, names_to = "version", values_to = "share") |>
  mutate(version = fct_inorder(version)) |>   # panels in this order, not A-Z
  ggplot(aes(x = share, y = pct_wfh)) +
  geom_point(alpha = 0.2, size = 0.7, na.rm = TRUE) +
  geom_smooth(method = "lm", formula = y ~ x, colour = "red", se = FALSE, na.rm = TRUE) +
  facet_wrap(~ version) +
  labs(title = "Why commute shares must be shares of commuters",
       x = "Share driving alone (%)", y = "pct_wfh (%)")
p_q4
ggsave("figures/q4_commuters_vs_allworkers.png", p_q4, width = 12, height = 5, bg = "white")
