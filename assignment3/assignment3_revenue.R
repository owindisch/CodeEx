## ============================================================
## Assignment 3: Revenue of US Intercollegiate Athletics Programs
## FEM11149 - Introduction to Data Science
##
## Structure (mirrors the minimum requirements):
##   PART 0  Setup
##   PART 1  Load and inspect the data (Q: what does NaN mean here?)
##   PART 2  Missing values and transformations (log revenue)
##   PART 3  Train / test split + preprocessing fitted on train only
##   PART 4  PCA: four simple criteria, permutation test,
##           bootstrap of Kaiser's rule and of VAF, interpretation
##   PART 5  Principal component regression (pls::pcr)
##   PART 6  Ridge regression (glmnet, alpha = 0)
##   PART 7  Evaluation on log scale AND on revenue scale
##   PART 8  Predictions for the 10 institutions in predictions.csv
##
## Run from the repository root:  Rscript assignment3/assignment3_revenue.R
## ============================================================


## ============================================================
## PART 0: SETUP
## ============================================================

library(dplyr)
library(tidyr)
library(ggplot2)
library(glmnet)
library(pls)
library(boot)

data_dir <- "assignment3"
fig_dir  <- file.path(data_dir, "figures")
dir.create(fig_dir, showWarnings = FALSE)

save_plot <- function(p, name, w = 7, h = 4.5) {
  ggsave(file.path(fig_dir, name), p, width = w, height = h, dpi = 150)
}


## ============================================================
## PART 1: LOAD AND INSPECT
## ============================================================
# Guiding questions:
# - How many institutions, how many variables, which are categorical?
# - Which variables contain NaN, and is the NaN "unknown" or "not applicable"?
# - How skewed is revenue? Which classifications have the largest programs?

athletics <- read.csv(file.path(data_dir, "data_783996yw.csv"))
prediction <- read.csv(file.path(data_dir, "predictions.csv"))

dim(athletics)
str(athletics)
summary(athletics$revenue)

# Missing values per variable
na_counts <- colSums(is.na(athletics))
na_counts[na_counts > 0]

# Is the missingness structural? An institution without men's teams
# cannot have men's head coaches, so hc_men = NaN there means "none".
table(no_men_teams = athletics$teams_men == 0, hc_men_missing = is.na(athletics$hc_men))
table(no_women_teams = athletics$teams_women == 0, hc_women_missing = is.na(athletics$hc_women))
# ac_men / ac_women are never 0 in the data (min = 1), so NaN most likely
# means "no assistant coaches". The salary is then not applicable.
min(athletics$ac_men, na.rm = TRUE)
# A few institutions DO report assistant coaches but no salary:
# these are genuinely missing values.
sum(!is.na(athletics$ac_men)   & is.na(athletics$ac_salary_men))
sum(!is.na(athletics$ac_women) & is.na(athletics$ac_salary_women))

# Categorical variables
table(athletics$classification)
table(athletics$sector)

# Revenue: raw vs log
p_rev <- ggplot(athletics, aes(revenue / 1e6)) +
  geom_histogram(bins = 50, fill = "steelblue", color = "white") +
  labs(title = "Revenue of athletics programs", x = "Revenue (million USD)", y = "Count") +
  theme_minimal()
p_logrev <- ggplot(athletics, aes(log(revenue))) +
  geom_histogram(bins = 50, fill = "steelblue", color = "white") +
  labs(title = "Log revenue", x = "log(revenue)", y = "Count") +
  theme_minimal()
save_plot(p_rev, "revenue_hist.png")
save_plot(p_logrev, "log_revenue_hist.png")

# Revenue by classification (helps the story: FBS schools are a world apart)
p_class <- ggplot(athletics, aes(x = reorder(classification, revenue, median), y = log(revenue))) +
  geom_boxplot(fill = "lightblue") + coord_flip() +
  labs(title = "Log revenue by classification", x = NULL, y = "log(revenue)") +
  theme_minimal()
save_plot(p_class, "log_revenue_by_class.png", h = 5.5)


## ============================================================
## PART 2: MISSING VALUES AND TRANSFORMATIONS
## ============================================================
# Guiding questions:
# - Which NaNs can be replaced by 0 based on their meaning?
# - Which NaNs are genuinely unknown, and how do you impute them without
#   using information from the test set?
# - Which predictors are as skewed as revenue? Would logs help PCA too?

count_vars  <- c("ugrad_men", "ugrad_women", "athletes_men", "athletes_women",
                 "teams_men", "teams_women",
                 grep("^partic_", names(athletics), value = TRUE),
                 "hc_men", "hc_women", "ac_men", "ac_women")
salary_vars <- c("hc_salary_men", "hc_salary_women", "ac_salary_men", "ac_salary_women")
share_vars  <- c("hc_fulltime_share", "hc_female_share")
num_vars    <- c(count_vars, salary_vars, share_vars)

# Step 1: structural NaNs -> 0 (no coaches, so no coach salary)
fix_structural <- function(d) {
  for (s in c("men", "women")) {
    hc <- paste0("hc_", s); ac <- paste0("ac_", s)
    hs <- paste0("hc_salary_", s); as <- paste0("ac_salary_", s)
    no_hc <- is.na(d[[hc]])
    no_ac <- is.na(d[[ac]])
    d[[hc]][no_hc] <- 0
    d[[ac]][no_ac] <- 0
    d[[hs]][no_hc & is.na(d[[hs]])] <- 0
    d[[as]][no_ac & is.na(d[[as]])] <- 0
  }
  d
}

# Step 2: log transform the skewed counts and salaries.
# log1p(x) = log(1 + x) so that zeros stay defined.
transform_vars <- function(d) {
  for (v in c(count_vars, salary_vars)) d[[v]] <- log1p(d[[v]])
  d
}

dat  <- athletics %>% fix_structural()
prediction <- prediction %>% fix_structural()

# Remaining (genuine) missing values: only salaries of existing coaches
colSums(is.na(dat[num_vars]))[colSums(is.na(dat[num_vars])) > 0]

dat$log_revenue <- log(dat$revenue)

# Factors with the same levels in the data and in predictions.csv
dat$classification  <- factor(dat$classification)
dat$sector          <- factor(dat$sector)
prediction$classification <- factor(prediction$classification, levels = levels(dat$classification))
prediction$sector         <- factor(prediction$sector, levels = levels(dat$sector))
stopifnot(!anyNA(prediction$classification), !anyNA(prediction$sector))

# Skewness before and after the log transform
skewness_fun <- function(x) {
  x <- x[is.finite(x)]
  mean((x - mean(x))^3) / sd(x)^3
}
skew_tab <- data.frame(
  Variable = c("revenue", count_vars, salary_vars),
  Raw = sapply(c("revenue", count_vars, salary_vars), function(v) skewness_fun(dat[[v]])),
  Log = c(skewness_fun(dat$log_revenue),
          sapply(c(count_vars, salary_vars), function(v) skewness_fun(log1p(dat[[v]]))))
)
print(skew_tab, digits = 2, row.names = FALSE)

dat  <- transform_vars(dat)
prediction <- transform_vars(prediction)


## ============================================================
## PART 3: TRAIN / TEST SPLIT + PREPROCESSING ON TRAIN ONLY
## ============================================================
# Guiding questions:
# - Why must imputation medians (and PCA centring/scaling) come from the
#   training data only?
# - Are all classification levels present in the training set?

set.seed(123)
train_index <- sample(seq_len(nrow(dat)), size = floor(0.8 * nrow(dat)))
train_data  <- dat[train_index, ]
test_data   <- dat[-train_index, ]
cat("Training:", nrow(train_data), " Test:", nrow(test_data), "\n")
table(train_data$classification)

# Median imputation of the genuinely missing salaries, using the
# training medians for train, test and predictions.csv
train_medians <- sapply(train_data[num_vars], median, na.rm = TRUE)
impute <- function(d) {
  for (v in num_vars) d[[v]][is.na(d[[v]])] <- train_medians[v]
  d
}
train_data <- impute(train_data)
test_data  <- impute(test_data)
prediction <- impute(prediction)
stopifnot(!anyNA(train_data[num_vars]), !anyNA(test_data[num_vars]), !anyNA(prediction[num_vars]))

# Correlations of the predictors with log revenue (exploration only)
cor_tab <- sort(sapply(train_data[num_vars], cor, y = train_data$log_revenue), decreasing = TRUE)
print(round(cor_tab, 2))


## ============================================================
## PART 4: PRINCIPAL COMPONENT ANALYSIS
## ============================================================
# PCA is run on the numerical predictors only (not on revenue and not on
# the dummies: PCA on 0/1 variables is hard to interpret). The
# classification dummies return later in PCR variant B.

X_train <- train_data[, num_vars]
X_test  <- test_data[, num_vars]
p       <- ncol(X_train)

pca_model   <- prcomp(X_train, center = TRUE, scale. = TRUE)
eigenvalues <- pca_model$sdev^2
vaf         <- eigenvalues / sum(eigenvalues)
cum_vaf     <- cumsum(vaf)
pca_summary <- data.frame(PC = seq_along(eigenvalues), Eigenvalue = eigenvalues,
                          VAF = vaf, CumulativeVAF = cum_vaf)
print(round(pca_summary, 3))

## ---- 4a. The four simple criteria ---------------------------
# Guiding questions:
# - Do the criteria agree? Which one is most/least conservative and why?
# Check your lecture slides for the exact four criteria; the usual ones are:
#   (1) Kaiser's rule: eigenvalue > 1 (PC explains more than one variable)
#   (2) Cumulative VAF above a threshold (here 80%)
#   (3) Scree plot: number of PCs before the "elbow"
#   (4) Each retained PC explains at least a minimum share (here 1/p, which
#       for standardised data is identical to Kaiser) or Jolliffe's 0.7 rule
k_kaiser   <- sum(eigenvalues > 1)
k_jolliffe <- sum(eigenvalues > 0.7)
k_vaf80    <- which(cum_vaf >= 0.80)[1]
cat("Kaiser:", k_kaiser, " Jolliffe (0.7):", k_jolliffe, " 80% VAF:", k_vaf80, "\n")

p_scree <- ggplot(pca_summary, aes(PC, Eigenvalue)) +
  geom_line(color = "steelblue") + geom_point(color = "steelblue") +
  geom_hline(yintercept = 1, linetype = "dashed", color = "red") +
  scale_x_continuous(breaks = seq_len(p)) +
  labs(title = "Scree plot", x = "Principal component", y = "Eigenvalue") +
  theme_minimal()
save_plot(p_scree, "scree.png")

## ---- 4b. Permutation test -----------------------------------
# Idea: permuting every column independently destroys the correlation
# between variables but keeps each variable's distribution. PCs of the
# permuted data only reflect chance. A component is "meaningful" if its
# observed VAF is larger than the 95th percentile of the permuted VAFs.
# Guiding questions:
# - What is the null hypothesis for each component?
# - Why is the permutation test usually less generous than Kaiser's rule?
n_perm <- 1000
set.seed(123)
perm_vaf <- t(replicate(n_perm, {
  X_perm <- apply(X_train, 2, sample)
  ev <- prcomp(X_perm, center = TRUE, scale. = TRUE)$sdev^2
  ev / sum(ev)
}))
perm_q95 <- apply(perm_vaf, 2, quantile, probs = 0.95)
perm_p   <- sapply(seq_len(p), function(j) mean(perm_vaf[, j] >= vaf[j]))
perm_tab <- data.frame(PC = seq_len(p), VAF = vaf, Perm95 = perm_q95, p_value = perm_p)
print(round(perm_tab, 3))
# Retain components up to the first one that is not significant
k_perm <- which(vaf <= perm_q95)[1] - 1
cat("Permutation test:", k_perm, "PCs\n")

p_perm <- ggplot(perm_tab, aes(PC)) +
  geom_line(aes(y = VAF, color = "Observed")) + geom_point(aes(y = VAF, color = "Observed")) +
  geom_line(aes(y = Perm95, color = "Permutation 95%")) +
  scale_color_manual(values = c("Observed" = "steelblue", "Permutation 95%" = "red")) +
  scale_x_continuous(breaks = seq_len(p)) +
  labs(title = "Permutation test for the number of PCs", x = "Principal component",
       y = "Variance accounted for", color = NULL) +
  theme_minimal()
save_plot(p_perm, "permutation_test.png")

## ---- 4c. Bootstrap of Kaiser's rule and of VAF --------------
# Resample institutions with replacement, redo the PCA, store eigenvalues.
# Kaiser: is eigenvalue j significantly > 1, i.e. is the lower bound of
# its 95% CI above 1?  VAF: CI for the variance explained by k PCs.
# Guiding questions:
# - Which components are borderline under Kaiser's rule (CI contains 1)?
# - How wide is the CI for the VAF? What does that say about stability?
my_boot_pca <- function(x, ind) {
  prcomp(x[ind, ], center = TRUE, scale. = TRUE)$sdev^2
}
set.seed(123)
fit_boot  <- boot(data = X_train, statistic = my_boot_pca, R = 1000)
eigs_boot <- fit_boot$t

kaiser_boot <- data.frame(
  PC = seq_len(p), Eigenvalue = eigenvalues,
  Lower = apply(eigs_boot, 2, quantile, 0.025),
  Upper = apply(eigs_boot, 2, quantile, 0.975)
)
kaiser_boot$Significant <- kaiser_boot$Lower > 1
print(head(kaiser_boot, 8), digits = 3)
k_kaiser_boot <- which(!kaiser_boot$Significant)[1] - 1
cat("Bootstrapped Kaiser:", k_kaiser_boot, "PCs\n")

p_kboot <- ggplot(head(kaiser_boot, 10), aes(PC, Eigenvalue)) +
  geom_errorbar(aes(ymin = Lower, ymax = Upper), width = 0.2) + geom_point(color = "steelblue") +
  geom_hline(yintercept = 1, linetype = "dashed", color = "red") +
  scale_x_continuous(breaks = 1:10) +
  labs(title = "Bootstrap 95% CIs of the eigenvalues (Kaiser's rule)",
       x = "Principal component", y = "Eigenvalue") +
  theme_minimal()
save_plot(p_kboot, "kaiser_bootstrap.png")

# Choose the number of PCs for the rest of the analysis.
# Default: the permutation test (the most formal criterion). Change this
# after comparing all criteria and motivate it in the report.
n_pc <- k_perm

vaf_boot <- rowSums(eigs_boot[, 1:n_pc, drop = FALSE]) / p
vaf_ci   <- quantile(vaf_boot, c(0.025, 0.975))
cat("VAF of", n_pc, "PCs:", round(100 * cum_vaf[n_pc], 1), "%  95% CI:",
    round(100 * vaf_ci, 1), "\n")

# Bootstrap CI for the VAF of each individual component
vaf_each_boot <- eigs_boot / p
vaf_each_ci <- data.frame(PC = 1:n_pc, VAF = vaf[1:n_pc],
                          Lower = apply(vaf_each_boot[, 1:n_pc, drop = FALSE], 2, quantile, 0.025),
                          Upper = apply(vaf_each_boot[, 1:n_pc, drop = FALSE], 2, quantile, 0.975))
print(round(vaf_each_ci, 3))

pc_selection <- data.frame(
  Method = c("Kaiser (eigenvalue > 1)", "Jolliffe (eigenvalue > 0.7)", "80% cumulative VAF",
             "Permutation test", "Bootstrapped Kaiser"),
  PCs = c(k_kaiser, k_jolliffe, k_vaf80, k_perm, k_kaiser_boot))
print(pc_selection)

## ---- 4d. Interpretation: loadings, correlations, biplot -----
# Guiding questions:
# - Which variables load strongly on each PC? Do signs make sense?
# - Can you give each PC a name (e.g. "size of the program",
#   "investment / money per coach", "gender composition")?
# - Which variables are badly represented by the selected PCs (low
#   communality)? Those carry information the PCR throws away.
loadings <- pca_model$rotation[, 1:n_pc, drop = FALSE]
print(round(loadings, 2))

# Correlation between variable and component = loading * sd of the PC
var_pc_cor  <- sweep(loadings, 2, pca_model$sdev[1:n_pc], "*")
communality <- rowSums(var_pc_cor^2)   # share of each variable explained by n_pc PCs
print(round(cbind(var_pc_cor, Communality = communality), 2))

# Biplot of PC1 and PC2, coloured by classification
score_plot   <- data.frame(PC1 = pca_model$x[, 1], PC2 = pca_model$x[, 2],
                           Division = train_data$classification)
loading_plot <- data.frame(Variable = rownames(pca_model$rotation),
                           PC1 = pca_model$rotation[, 1], PC2 = pca_model$rotation[, 2])
arrow_scale <- 0.8 * min(max(abs(score_plot$PC1)) / max(abs(loading_plot$PC1)),
                         max(abs(score_plot$PC2)) / max(abs(loading_plot$PC2)))
p_biplot <- ggplot(score_plot, aes(PC1, PC2)) +
  geom_point(aes(color = Division), alpha = 0.5, size = 1) +
  geom_segment(data = loading_plot, aes(x = 0, y = 0, xend = PC1 * arrow_scale, yend = PC2 * arrow_scale),
               inherit.aes = FALSE, color = "black", arrow = grid::arrow(length = grid::unit(0.15, "cm"))) +
  geom_text(data = loading_plot, aes(x = PC1 * arrow_scale, y = PC2 * arrow_scale, label = Variable),
            inherit.aes = FALSE, size = 2.6, check_overlap = TRUE) +
  labs(title = "PCA biplot",
       x = paste0("PC1 (", round(100 * vaf[1], 1), "%)"),
       y = paste0("PC2 (", round(100 * vaf[2], 1), "%)")) +
  theme_minimal() + theme(legend.text = element_text(size = 6))
save_plot(p_biplot, "biplot.png", w = 9, h = 6)


## ============================================================
## PART 5: PRINCIPAL COMPONENT REGRESSION
## ============================================================
# Variant A: pcr() on the numerical predictors with n_pc components.
# Variant B: lm() on the n_pc PC scores + classification and sector
#            dummies (the dummies carry information PCA did not use).
# Also: let 10-fold CV choose the number of components (best practice)
# and compare with the PCA-based choice.
# Guiding questions:
# - Does the CV-optimal number of components agree with the PCA criteria?
#   Why might it not? (PCA ignores y: high-variance directions need not be
#   the directions that predict revenue.)
# - How much does adding the dummies help?

pcr_data <- train_data[, c("log_revenue", num_vars)]
set.seed(123)
fit_pcr <- pcr(log_revenue ~ ., data = pcr_data, scale = TRUE, validation = "CV", segments = 10)
summary(fit_pcr)

cv_rmsep <- RMSEP(fit_pcr, estimate = "CV")$val[1, 1, -1]   # drop the intercept-only model
k_cv     <- which.min(cv_rmsep)
k_cv_1se <- selectNcomp(fit_pcr, method = "onesigma")
cat("PCR: CV-minimum", k_cv, "components, one-sigma rule", k_cv_1se, "components\n")

png(file.path(fig_dir, "pcr_cv.png"), width = 1000, height = 650, res = 150)
validationplot(fit_pcr, val.type = "RMSEP", main = "PCR: cross-validated RMSEP (log revenue)")
abline(v = n_pc, lty = 2, col = "red")
dev.off()

# Variant B: PC scores (from the training PCA) + dummies
train_scores <- data.frame(pca_model$x[, 1:n_pc, drop = FALSE],
                           classification = train_data$classification,
                           sector = train_data$sector,
                           log_revenue = train_data$log_revenue)
test_scores  <- data.frame(predict(pca_model, newdata = X_test)[, 1:n_pc, drop = FALSE],
                           classification = test_data$classification,
                           sector = test_data$sector)
fit_pcr_dum <- lm(log_revenue ~ ., data = train_scores)
summary(fit_pcr_dum)


## ============================================================
## PART 6: RIDGE REGRESSION
## ============================================================
# Guiding questions:
# - Why standardise (glmnet does this by default)?
# - Compare lambda.min and lambda.1se: how much CV error do you give up
#   for a more strongly shrunken model?
# - Which coefficients are largest? Do they match the PCA story?

form_x  <- as.formula(paste("~", paste(c(num_vars, "classification", "sector"), collapse = " + ")))
x_train <- model.matrix(form_x, data = train_data)[, -1]
x_test  <- model.matrix(form_x, data = test_data)[, -1]
y_train <- train_data$log_revenue
y_test  <- test_data$log_revenue

set.seed(123)
cv_ridge <- cv.glmnet(x_train, y_train, alpha = 0, nfolds = 10)
cat("Ridge lambda.min:", cv_ridge$lambda.min, " lambda.1se:", cv_ridge$lambda.1se, "\n")

png(file.path(fig_dir, "ridge_cv.png"), width = 1000, height = 650, res = 150)
plot(cv_ridge)
dev.off()
png(file.path(fig_dir, "ridge_paths.png"), width = 1000, height = 650, res = 150)
plot(cv_ridge$glmnet.fit, xvar = "lambda")
abline(v = log(c(cv_ridge$lambda.min, cv_ridge$lambda.1se)), lty = 2)
dev.off()

ridge_coef <- data.frame(
  Variable   = rownames(coef(cv_ridge, s = "lambda.min")),
  lambda_min = as.numeric(coef(cv_ridge, s = "lambda.min")),
  lambda_1se = as.numeric(coef(cv_ridge, s = "lambda.1se")))
print(ridge_coef, digits = 3, row.names = FALSE)


## ============================================================
## PART 7: EVALUATION ON LOG SCALE AND ON REVENUE SCALE
## ============================================================
# Guiding questions:
# - On the log scale, an error of 0.1 is roughly a 10% error, whatever
#   the size of the school. On the revenue scale, the RMSE is driven by a
#   handful of FBS programs. Which metric fits the client's question?
# - exp(E[log y]) is NOT E[y]: exp(prediction) estimates the MEDIAN
#   revenue (if the log errors are symmetric), and systematically
#   underestimates the MEAN. Correct with Duan's smearing estimator
#   mean(exp(residuals)) or, under normal errors, exp(sigma^2 / 2).
# - Does the back-transformation change the ranking of the models?

rmse <- function(y, yhat) sqrt(mean((y - yhat)^2))
mae  <- function(y, yhat) mean(abs(y - yhat))
mdape <- function(y, yhat) median(abs(y - yhat) / y)

# Log-scale predictions (and training residuals for the smearing factor)
pred_log <- list(
  "PCR (numerical, n_pc)"     = as.numeric(predict(fit_pcr, newdata = test_data, ncomp = n_pc)),
  "PCR (numerical, CV ncomp)" = as.numeric(predict(fit_pcr, newdata = test_data, ncomp = k_cv)),
  "PCR + dummies"             = as.numeric(predict(fit_pcr_dum, newdata = test_scores)),
  "Ridge lambda.min"          = as.numeric(predict(cv_ridge, newx = x_test, s = "lambda.min")),
  "Ridge lambda.1se"          = as.numeric(predict(cv_ridge, newx = x_test, s = "lambda.1se"))
)
fit_log <- list(
  "PCR (numerical, n_pc)"     = as.numeric(predict(fit_pcr, ncomp = n_pc)),
  "PCR (numerical, CV ncomp)" = as.numeric(predict(fit_pcr, ncomp = k_cv)),
  "PCR + dummies"             = as.numeric(fitted(fit_pcr_dum)),
  "Ridge lambda.min"          = as.numeric(predict(cv_ridge, newx = x_train, s = "lambda.min")),
  "Ridge lambda.1se"          = as.numeric(predict(cv_ridge, newx = x_train, s = "lambda.1se"))
)
smear <- sapply(fit_log, function(f) mean(exp(y_train - f)))   # Duan's smearing factor

rev_test <- test_data$revenue
eval_tab <- do.call(rbind, lapply(names(pred_log), function(m) {
  pl <- pred_log[[m]]
  data.frame(Model = m,
             RMSE_log = rmse(y_test, pl),
             MAE_log  = mae(y_test, pl),
             R2_log   = 1 - sum((y_test - pl)^2) / sum((y_test - mean(y_test))^2),
             RMSE_rev_naive_M = rmse(rev_test, exp(pl)) / 1e6,
             RMSE_rev_smear_M = rmse(rev_test, exp(pl) * smear[m]) / 1e6,
             MAE_rev_naive_M  = mae(rev_test, exp(pl)) / 1e6,
             MdAPE_naive      = mdape(rev_test, exp(pl)),
             Smearing         = smear[m])
}))
# Benchmark: predict the training mean log revenue for everyone
eval_tab <- rbind(eval_tab, data.frame(
  Model = "Null (mean log revenue)",
  RMSE_log = rmse(y_test, mean(y_train)), MAE_log = mae(y_test, mean(y_train)), R2_log = 0,
  RMSE_rev_naive_M = rmse(rev_test, exp(mean(y_train))) / 1e6,
  RMSE_rev_smear_M = rmse(rev_test, mean(train_data$revenue)) / 1e6,
  MAE_rev_naive_M  = mae(rev_test, exp(mean(y_train))) / 1e6,
  MdAPE_naive      = mdape(rev_test, exp(mean(y_train))),
  Smearing = NA))
print(eval_tab, digits = 3, row.names = FALSE)

# Where do the revenue-scale errors come from? Errors by classification
err_by_class <- data.frame(
  classification = test_data$classification,
  abs_err_log = abs(y_test - pred_log[["Ridge lambda.min"]]),
  abs_err_rev = abs(rev_test - exp(pred_log[["Ridge lambda.min"]]))) %>%
  group_by(classification) %>%
  summarise(n = n(), MAE_log = mean(abs_err_log), MAE_rev_M = mean(abs_err_rev) / 1e6,
            share_of_total_abs_err = sum(abs_err_rev)) %>%
  mutate(share_of_total_abs_err = share_of_total_abs_err / sum(share_of_total_abs_err)) %>%
  arrange(desc(MAE_rev_M))
print(err_by_class, n = Inf)

# Observed vs predicted (log scale)
obs_pred <- data.frame(Observed = y_test,
                       PCR = pred_log[["PCR + dummies"]],
                       Ridge = pred_log[["Ridge lambda.min"]]) %>%
  pivot_longer(-Observed, names_to = "Model", values_to = "Predicted")
p_obs <- ggplot(obs_pred, aes(Predicted, Observed)) +
  geom_point(alpha = 0.5, size = 1) + geom_abline(color = "red") +
  facet_wrap(~ Model) +
  labs(title = "Test set: observed vs predicted log revenue") + theme_minimal()
save_plot(p_obs, "obs_vs_pred.png", w = 8)


## ============================================================
## PART 8: PREDICTIONS FOR THE 10 INSTITUTIONS
## ============================================================
# Guiding questions:
# - Refit on all 1000 institutions or keep the training fit? (Refitting
#   uses more data; the test set has already done its job.) Here: refit
#   with the tuning choices (n_pc, lambda) fixed from the training stage.
# - Report revenue predictions in USD: which back-transformation do you
#   use and why? Give both the median-type and the mean-type prediction.
# - Do the predictions look plausible given each institution's division?

full_data <- impute(dat)

# PCR + dummies on all data
pca_full    <- prcomp(full_data[, num_vars], center = TRUE, scale. = TRUE)
full_scores <- data.frame(pca_full$x[, 1:n_pc, drop = FALSE],
                          classification = full_data$classification,
                          sector = full_data$sector,
                          log_revenue = full_data$log_revenue)
new_scores  <- data.frame(predict(pca_full, newdata = prediction[, num_vars])[, 1:n_pc, drop = FALSE],
                          classification = prediction$classification, sector = prediction$sector)
fit_pcr_full <- lm(log_revenue ~ ., data = full_scores)

# Ridge on all data with the lambda chosen by CV on the training set
x_full <- model.matrix(form_x, data = full_data)[, -1]
x_new  <- model.matrix(form_x, data = prediction)[, -1]
ridge_full <- glmnet(x_full, full_data$log_revenue, alpha = 0, lambda = cv_ridge$lambda.min)

pl_pcr   <- as.numeric(predict(fit_pcr_full, newdata = new_scores))
pl_ridge <- as.numeric(predict(ridge_full, newx = x_new))
smear_pcr   <- mean(exp(residuals(fit_pcr_full)))
smear_ridge <- mean(exp(full_data$log_revenue - as.numeric(predict(ridge_full, newx = x_full))))

pred_out <- data.frame(
  id = prediction$id, classification = prediction$classification,
  log_rev_PCR = pl_pcr, log_rev_Ridge = pl_ridge,
  rev_PCR_median_M   = exp(pl_pcr) / 1e6,
  rev_PCR_mean_M     = exp(pl_pcr) * smear_pcr / 1e6,
  rev_Ridge_median_M = exp(pl_ridge) / 1e6,
  rev_Ridge_mean_M   = exp(pl_ridge) * smear_ridge / 1e6)
print(pred_out, digits = 3, row.names = FALSE)
write.csv(pred_out, file.path(data_dir, "predictions_output.csv"), row.names = FALSE)

cat("\n--- Summary ---\n")
print(pc_selection)
cat("Selected PCs:", n_pc, " VAF:", round(100 * cum_vaf[n_pc], 1), "%\n")
print(eval_tab[, c("Model", "RMSE_log", "R2_log", "RMSE_rev_naive_M", "RMSE_rev_smear_M")],
      digits = 3, row.names = FALSE)
