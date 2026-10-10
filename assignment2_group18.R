############################################################
## Assignment 2 - Working from home (ACS 2020-2024)
## Group 18 - Massachusetts
############################################################

## Setup ---------------------------------------------------

library(tidyverse) # loads dplyr (filter, mutate, %>%) and ggplot2 (plots)
# Note: ggplot gives warnings like "Removed 9 rows containing missing values".
# That is fine: it only means tracts with NA for that variable are not plotted.

setwd("C:/Users/Gebruiker/OneDrive - Erasmus University Rotterdam/R Data") # folder with the data files

acs  <- read.csv("a2_data_group_18.csv")             # the data: one row per census tract
desc <- read.csv("data_description_acs_fixed.csv")   # what each variable means (check the name with list.files())


## Question 1 ----------------------------------------------

dim(acs)     # how many observations and variables (rows and columns): 1620 x 39
names(acs)   # variable names
summary(acs) # summary stats, check where the "strange values" are
desc         # description of the variables

# Which "strange values" are there? Look at all values below -100 million
# (no real estimate can be that negative). We only look at the numeric columns.
num_acs <- acs %>% select(where(is.numeric))   # numeric columns only (not state/county names)
unique(na.omit(num_acs[num_acs < -100000000])) # which values: only -666666666
sum(num_acs < -100000000, na.rm = TRUE)        # how many: 358
colSums(num_acs == -666666666, na.rm = TRUE)   # in which variables? (the medians, gini, hh_size)

acs[acs == -666666666] <- NA                   # "strange value" = ACS code for "could not be computed" -> missing value
sum(acs < -100000000, na.rm = TRUE)            # check: should be 0 now

# Tracts without or with very few inhabitants
sum(acs$pop == 0, na.rm = TRUE)                # how many with no inhabitants: 18
sum(acs$pop < 300, na.rm = TRUE)               # how many with fewer than 300 inhabitants: 27
sum(acs$pop < 1200, na.rm = TRUE)              # how many below the Census guideline of 1200: 40

acs %>% arrange(pop) %>% select(geoid, county, pop, pct_wfh) %>% head(30) # look at the smallest tracts
# -> tracts with 3-202 inhabitants have pct_wfh of 0% or 100%: based on very few answers.
#    Next tract has 453 inhabitants, so we use 300 as cut-off.

ggplot(acs, aes(x = pop)) +                    # histogram of population
  geom_histogram(bins = 100, fill = "grey50") +
  geom_vline(xintercept = 300, colour = "red") + # red line = our cut-off
  labs(title = "Population per census tract", x = "Inhabitants", y = "Number of tracts")

acs_clean <- acs %>% filter(pop >= 300, !is.na(pct_wfh)) # remove (almost) empty tracts and tracts without valid outcome

nrow(acs_clean)                                # 1593 observations left after cleaning
colSums(is.na(acs_clean))                      # missing values that are still left per variable


## Question 2 ----------------------------------------------

ggplot(acs_clean, aes(x = med_value)) +        # histogram of median home value
  geom_histogram(bins = 100, fill = "lightpink") +
  labs(title = "Median Home Value", x = "Home value in USD", y = "Number of tracts")

ggplot(acs_clean, aes(x = med_hh_income)) +    # histogram of median household income
  geom_histogram(bins = 100, fill = "lightgreen") +
  labs(title = "Median Household Income", x = "Income in USD", y = "Number of tracts")

max(acs_clean$med_value, na.rm = TRUE)         # max home value: 2000001
sum(acs_clean$med_value == max(acs_clean$med_value, na.rm = TRUE), na.rm = TRUE)         # 11 tracts have this value

max(acs_clean$med_hh_income, na.rm = TRUE)     # max household income: 250001
sum(acs_clean$med_hh_income == max(acs_clean$med_hh_income, na.rm = TRUE), na.rm = TRUE) # 30 tracts have this value

# Why? The ACS top-codes medians: "2,000,000+" is stored as 2000001 and "250,000+" as 250001.
# The true value is unknown (at least the cap) -> the variable is censored.
# Decision: keep these tracts, add a 0/1 dummy for them and use the log (variables are skewed).
acs_clean <- acs_clean %>%
  mutate(topcode_value  = as.numeric(med_value == 2000001),  # 1 = home value is "2,000,000+"
         topcode_income = as.numeric(med_hh_income == 250001), # 1 = income is "250,000+"
         log_value      = log(med_value),                    # log home value
         log_income     = log(med_hh_income))                # log household income

table(acs_clean$topcode_value)                 # how many 0s and 1s
table(acs_clean$topcode_income)

acs_clean %>% group_by(topcode_income) %>% summarise(mean_wfh = mean(pct_wfh)) # top-coded tracts: much more WFH (32.8% vs 17.9%)


## Question 3 ----------------------------------------------

ggplot(acs_clean, aes(x = pct_wfh)) +          # histogram of the dependent variable
  geom_histogram(bins = 60, fill = "lightblue") +
  labs(title = "Working from home", x = "Percentage working from home", y = "Number of tracts")

ggplot(acs_clean, aes(x = pct_bachelor_plus, y = pct_wfh)) +   # scatter plot
  geom_point(alpha = 0.3) +                                    # transparent dots
  geom_smooth(method = "lm", colour = "red", se = FALSE) +     # straight regression line
  labs(title = "WFH and Education",
       x = "Percentage with bachelor's degree or higher", y = "Percentage working from home")

ggplot(acs_clean, aes(x = log_income, y = pct_wfh)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm", colour = "red", se = FALSE) +
  labs(title = "WFH and Household Income",
       x = "Log median household income", y = "Percentage working from home")

ggplot(acs_clean, aes(x = occ_mgmt_sci, y = pct_wfh)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm", colour = "red", se = FALSE) +
  labs(title = "WFH and Occupation",
       x = "Management, business, science and arts occupations (%)", y = "Percentage working from home")

ggplot(acs_clean, aes(x = occ_production, y = pct_wfh)) +      # a negative relation
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm", colour = "red", se = FALSE) +
  labs(title = "WFH and Production Jobs",
       x = "Production, transportation and material moving occupations (%)", y = "Percentage working from home")

ggplot(acs_clean, aes(x = pct_broadband, y = pct_wfh)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm", colour = "red", se = FALSE) +
  labs(title = "WFH and Broadband Access",
       x = "Percentage with a broadband internet subscription", y = "Percentage working from home")

cor(acs_clean$pct_wfh, acs_clean$pct_bachelor_plus, use = "complete.obs") #  0.81
cor(acs_clean$pct_wfh, acs_clean$log_income,        use = "complete.obs") #  0.63
cor(acs_clean$pct_wfh, acs_clean$occ_mgmt_sci,      use = "complete.obs") #  0.80
cor(acs_clean$pct_wfh, acs_clean$occ_production,    use = "complete.obs") # -0.64
cor(acs_clean$pct_wfh, acs_clean$pct_broadband,     use = "complete.obs") #  0.41

# Correlation of pct_wfh with ALL numeric variables at once (for the appendix)
num  <- acs_clean %>% select(where(is.numeric), -geoid, -topcode_value, -topcode_income) # numeric columns, without ID and dummies
cors <- cor(num, use = "pairwise.complete.obs")[, "pct_wfh"]  # correlation of each column with pct_wfh
sort(round(cors, 2))                                          # sorted from negative to positive

# All scatter plots in one figure for the appendix (one small panel per variable)
acs_clean %>%
  select(pct_wfh, pct_bachelor_plus, pct_hs, occ_mgmt_sci, occ_service, occ_production,
         log_income, pct_poverty, pct_broadband, pct_transit, mean_commute, pct_owner, med_age) %>%
  pivot_longer(-pct_wfh, names_to = "variable", values_to = "value") %>% # long format: 1 row per tract x variable
  ggplot(aes(x = value, y = pct_wfh)) +
  geom_point(alpha = 0.2, size = 0.5) +
  geom_smooth(method = "lm", colour = "red", se = FALSE) +
  facet_wrap(~ variable, scales = "free_x") +                  # one panel per variable
  labs(title = "WFH against tract characteristics", x = NULL, y = "Percentage working from home")


## Question 4 ----------------------------------------------

# pct_drive_alone is a share of COMMUTERS (workers not working from home).
# As a share of ALL workers it would be: share * (100 - pct_wfh) / 100
acs_clean <- acs_clean %>%
  mutate(drive_all = pct_drive_alone * (100 - pct_wfh) / 100)

cor(acs_clean$pct_wfh, acs_clean$pct_drive_alone, use = "complete.obs") # -0.19 (share of commuters)
cor(acs_clean$pct_wfh, acs_clean$drive_all,       use = "complete.obs") # -0.54 (share of all workers)
# -> drive alone + carpool + transit + other + WFH = 100% of workers, so as a share of all
#    workers the commute shares fall automatically when WFH rises: a mechanical relation.

ggplot(acs_clean, aes(x = drive_all, y = pct_wfh)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm", colour = "red", se = FALSE) +
  labs(title = "Drive alone as share of ALL workers (mechanical relation)",
       x = "Drive alone (% of all workers)", y = "Percentage working from home")

# Other variables that are mechanically related to pct_wfh:
# - mean_commute: only measured for workers who do NOT work from home
# - pct_transit / pct_drive_alone: the group of remaining commuters changes when more people work from home
