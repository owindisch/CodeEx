## Assignment 3: Revenue of US Intercollegiate Athletics Programs
## Same code as assignment3_report.Rmd (generated with knitr::purl), for running without knitting.
## Run inside the assignment3 folder:  Rscript assignment3_revenue.R

knitr::opts_chunk$set(fig.pos = "H", fig.align = "center", fig.width = 6.5, fig.height = 4)

library(tidyverse)
library(glmnet)
library(boot)
library(gridExtra)
library(caret)

permtestPCA <- function (X, nTests = 100, alpha = 0.05, center.data = TRUE, scale.data = TRUE, ...){ # permutation test function from lecture 5
  n <- nrow(X)
  m <- ncol(X)
  X <- scale(X, center = center.data, scale = scale.data)
  res.X      <- prcomp(X)
  eigs.X     <- res.X$sdev^2
  eigs.Xperm <- matrix(0, m, nTests)
  Xperm      <- matrix(0, n, m)
  Xperm[, 1] <- X[, 1]
  for (i in 1:nTests){
    for (j in 2:m) {
      ind <- sort(runif(n), index.return = TRUE)$ix   # random permutation of the rows
      Xperm[, j] <- X[ind, j]
    }
    eigs.Xperm[, i] <- prcomp(Xperm)$sdev^2
  }
  perc.alpha <- matrix(0, m, 2)
  for (s in 1:m){
    perc.alpha[s, ] <- quantile(eigs.Xperm[s, ], c(alpha/2, 1 - alpha/2))
  }
  plot(1:m, eigs.X, type = "b", col = "red", main = "Permutation test PCA",
       xlab = "Component", ylab = "Eigenvalue", ...)
  lines(1:m, perc.alpha[, 1], type = "b", col = "blue")
  lines(1:m, perc.alpha[, 2], type = "b", col = "blue")
  legend("topright", inset = .05, c("Observed", "2.5% bound", "97.5% bound"),
         lty = 1, col = c("red", "blue", "blue"), pch = "o")
  return(perc.alpha)
}

athletics  <- read.csv("data_783996yw.csv")  # 1000 institutions with revenue
prediction <- read.csv("predictions-2.csv")  # 10 institutions, revenue has to be predicted

# 1. Inspect data

dim(athletics) # check size, variables and distribution of revenue, the variable of interest
str(athletics)
summary(athletics$revenue)

na_counts <- colSums(is.na(athletics)) # check missing values for each variable/column
na_counts[na_counts > 0] # show only cols with missing values. hc na counts match with hc salary na counts

table(no_men_teams = athletics$teams_men == 0, hc_men_missing = is.na(athletics$hc_men)) # institution with no men's team can't have men's hc!
table(no_women_teams = athletics$teams_women == 0, hc_women_missing = is.na(athletics$hc_women)) # same for women
min(athletics$ac_men, na.rm = TRUE) # ac counts are never 0 (min = 1), so na in ac_men means no acs at the institution

sum(!is.na(athletics$ac_men)   & is.na(athletics$ac_salary_men)) # how many institutions have acs but no salary reported?
sum(!is.na(athletics$ac_women) & is.na(athletics$ac_salary_women)) # probably volunteers (eada leaves them out of the average salary)

table(athletics$classification) # get an overview of categorical variables and their levels
table(athletics$sector) # some classifications and sectors have very small levels:
                        # NCCAA Division I, Private for-profit 4-year or above, Private nonprofit 2-year

revenue <- ggplot(athletics, aes(revenue / 1e6)) +  # inspect the revenue variable, divide by one million for easier reading
  geom_histogram(bins = 50, fill = "blue", color = "white") +
  labs(title = "Revenue of athletics programs", x = "Revenue (in million USD)", y = "Count") +
  theme_minimal()
revenue # a very skewed histogram...log it to combat skewness

logrevenue <- ggplot(athletics, aes(log(revenue))) +
  geom_histogram(bins = 50, fill = "purple", color = "white") +
  labs(title = "Log revenue", x = "log(revenue)", y = "Count") +
  theme_minimal()
logrevenue # roughly symmetric

grid.arrange(revenue, logrevenue, ncol = 2) # both histograms next to each other

# 2. Clean up the data

count_vars  <- c("ugrad_men", "ugrad_women", "athletes_men", "athletes_women", "teams_men", "teams_women", # the predictors are grouped by variable type
                 grep("^partic_", names(athletics), value = TRUE), # add all the partic_ variables more quickly
                 "hc_men", "hc_women", "ac_men", "ac_women") # logged
salary_vars <- c("hc_salary_men", "hc_salary_women", "ac_salary_men", "ac_salary_women") # logged
share_vars  <- c("hc_fulltime_share", "hc_female_share") # 0 to 1, not logged
num_vars    <- c(count_vars, salary_vars, share_vars)   # all 28 numerical predictors

fixed_coaches <- function(x) {
  for (s in c("men", "women")) { # loop runs once for men's and once for women's variables (hc, ac, salaries)
    hc <- paste0("hc_", s); ac <- paste0("ac_", s) # becomes hc_men and ac_men, then hc_women and ac_women
    hs <- paste0("hc_salary_", s); as <- paste0("ac_salary_", s) # same for the salary columns
    no_hc <- is.na(x[[hc]])          # institutions without hcs
    no_ac <- is.na(x[[ac]])          # institutions without acs
    x[[hc]][no_hc] <- 0              # missing coaches become 0 (no men's team -> no men's hc)
    x[[ac]][no_ac] <- 0
    x[[hs]][no_hc & is.na(x[[hs]])] <- 0 # no coaches -> salary also becomes 0
    x[[as]][no_ac & is.na(x[[as]])] <- 0 # coaches present but no salary (volunteers?) stay na for now, imputed after the split
  }
  x
}

logged_vars <- function(x) { # skewed variables, we log them
  for (v in c(count_vars, salary_vars)) x[[v]] <- log1p(x[[v]]) # log(x + 1) in case x is 0
  x
}

athletics_new  <- athletics %>% fixed_coaches() # the function fixed_coaches is applied to both datasets
prediction_new <- prediction %>% fixed_coaches()

colSums(is.na(athletics_new[num_vars]))[colSums(is.na(athletics_new[num_vars])) > 0] # only some ac salaries are still missing (the potential volunteers)

athletics_new$log_revenue <- log(athletics_new$revenue) # this is the target variable

athletics_new$classification  <- factor(athletics_new$classification) # categorical variables transformed to factors, for both datasets
athletics_new$sector          <- factor(athletics_new$sector)
prediction_new$classification <- factor(prediction_new$classification, levels = levels(athletics_new$classification)) # same levels -> same dummies
prediction_new$sector         <- factor(prediction_new$sector, levels = levels(athletics_new$sector))
stopifnot(!anyNA(prediction_new$classification), !anyNA(prediction_new$sector)) # check: every level in prediction exists in the data

athletics_new  <- logged_vars(athletics_new) # log the skewed predictors in both datasets
prediction_new <- logged_vars(prediction_new)

# 3. Split the data

set.seed(123)
trainRowNumbers <- createDataPartition(athletics_new$log_revenue, p = 0.8, list = FALSE) # step 1: row numbers for the training data (80%)
train_data <- athletics_new[trainRowNumbers, ]  # step 2: training dataset
test_data  <- athletics_new[-trainRowNumbers, ] # step 3: test dataset
table(train_data$classification) # are all levels in the training set?

train_medians <- sapply(train_data[num_vars], median, na.rm = TRUE) # medians from the training data only (no leakage)
impute <- function(x) { # remaining na (salaries of potential volunteers) -> training median
  for (v in num_vars) x[[v]][is.na(x[[v]])] <- train_medians[v]
  x
}
train_data     <- impute(train_data)
test_data      <- impute(test_data)
prediction_new <- impute(prediction_new)
stopifnot(!anyNA(train_data[num_vars]), !anyNA(test_data[num_vars]), !anyNA(prediction_new[num_vars])) # check if no na is left

cor_tab <- sort(sapply(train_data[num_vars], cor, y = train_data$log_revenue), decreasing = TRUE) # correlation with log revenue
round(cor_tab, 2) # salaries and coaches correlate strongly with log revenue (in eada revenue must cover expenses)

# 4. PCA on the 28 numerical predictors (training data)
# dummies are left out for now, they return in the pcr (pca on 0/1 variables is hard to interpret)

X_pca      <- train_data[, num_vars] # predictors of the training set
X_pca_test <- test_data[, num_vars]  # predictors of the test set
p          <- ncol(X_pca)            # 28 variables

fitpca <- princomp(X_pca, cor = TRUE, scores = TRUE) # pca on the correlation matrix (variables have different units)
summary(fitpca)                                      # sd, vaf and cumulative vaf per component
eigenvalues <- fitpca$sdev^2                         # variance of each component
vaf         <- eigenvalues / p                       # proportion vaf (eigenvalues of a correlation matrix sum to p)
cum_vaf     <- cumsum(vaf)

screeplot(fitpca, npcs = p, type = "lines", main = "Scree plot", las = 1) # elbow plot
abline(h = 1, col = "red", lty = 2)                                       # red line = kaiser
k_kaiser <- sum(eigenvalues > 1)      # kaiser: a pc has to explain more than one original variable
k_vaf80  <- which(cum_vaf >= 0.80)[1] # first pc where 80% of the variance is reached

set.seed(123) # conduct a permutation test
perm_range <- permtestPCA(X_pca, nTests = 1000) # plot and matrix with the 2.5% and 97.5% quantiles per eigenvalue
round(cbind(Eigenvalue = eigenvalues, Lower = perm_range[, 1], Upper = perm_range[, 2])[1:8, ], 3)
k_perm <- which(eigenvalues <= perm_range[, 2])[1] - 1 # keep pcs up to the first one that is not above chance

my_boot_pca <- function(x, ind){ # run pca on the resampled rows and return the eigenvalues
  res <- princomp(x[ind, ], cor = TRUE)
  return(res$sdev^2)
}

set.seed(123) # run the bootstrap
fit.boot  <- boot(data = X_pca, statistic = my_boot_pca, R = 1000)
eigs.boot <- fit.boot$t # store the bootstrapped eigenvalues (1000 x 28 matrix)

kaiser_boot <- data.frame(PC = 1:p, Eigenvalue = eigenvalues, # is the eigenvalue sig. > 1? yes if the whole 95% confidence interval is above 1
                          Lower = apply(eigs.boot, 2, quantile, 0.025),
                          Upper = apply(eigs.boot, 2, quantile, 0.975))
kaiser_boot$Significant <- kaiser_boot$Lower > 1
round(kaiser_boot[1:8, 1:4], 3)
k_kaiser_boot <- which(!kaiser_boot$Significant)[1] - 1

par(mar = c(5, 4, 4, 1) + 0.1) # boxplot of the bootstrapped eigenvalues, red line = kaiser
boxplot(eigs.boot[, 1:10], las = 1, xlab = "Dimension", ylab = "Eigenvalue", col = "beige",
        main = "Bootstrapped eigenvalues")
abline(h = 1, col = "red", lty = 2)

pc_selection <- data.frame( # overview of the methods
  Method = c("Kaiser (eigenvalue > 1)", "80% cumulative VAF", "Permutation test", "Bootstrapped Kaiser"),
  PCs = c(k_kaiser, k_vaf80, k_perm, k_kaiser_boot))
pc_selection

n_pc <- k_perm # chosen number of pcs (permutation test)

vaf.boot   <- rowSums(eigs.boot[, 1:n_pc, drop = FALSE]) / p # bootstrapped proportion of variance explained by the chosen n_pc components
perc.alpha <- quantile(vaf.boot, c(0.025, 1 - 0.025)) # 95% percentile interval
round(100 * c(VAF = cum_vaf[n_pc], perc.alpha), 1)
hist(vaf.boot, xlab = paste("Proportion of variance explained by", n_pc, "PCs"), las = 1, col = "blue",
     main = "Bootstrap Confidence Interval", breaks = 20, border = "white")
abline(v = perc.alpha, col = "green", lwd = 2) # green: 95% interval
abline(v = cum_vaf[n_pc], col = "red", lwd = 2) # red: estimate on the training data

print(fitpca$loadings[, 1:n_pc], digits = 2) # weights of the variables in each pc

corpca  <- cor(X_pca, fitpca$scores)[, 1:n_pc] # diagnostics: fit per variable = squared correlations between variables and scores
fit_var <- cbind(corpca, Fit = rowSums(corpca^2))
round(fit_var, 2)

op <- par(mfrow = c(1, 2)) # in the biplots points = institutions, arrows = variables
biplot(fitpca, pc.biplot = TRUE, scale = 1, choices = 1:2, col = c("blue", "red"),
       asp = 1, cex = c(0.4, 0.7), xlabs = rep("o", nrow(X_pca)), main = "Biplot components 1 and 2")
biplot(fitpca, pc.biplot = TRUE, scale = 1, choices = 2:3, col = c("blue", "red"),
       asp = 1, cex = c(0.4, 0.7), xlabs = rep("o", nrow(X_pca)), main = "Biplot components 2 and 3")
par(op)

# 5. Principal component regression: log revenue on the n_pc pc scores + classification and sector dummies
# the pcs summarise the 28 numerical predictors, the dummies add the categorical information

train_scores <- data.frame(fitpca$scores[, 1:n_pc, drop = FALSE], # pc scores of the training data
                           classification = train_data$classification,
                           sector = train_data$sector,
                           log_revenue = train_data$log_revenue)
test_scores  <- data.frame(predict(fitpca, newdata = X_pca_test)[, 1:n_pc, drop = FALSE], # test projected on the training pca
                           classification = test_data$classification,
                           sector = test_data$sector)
fit_pcr <- lm(log_revenue ~ ., data = train_scores) # ols on pcs and dummies (lm makes the dummies itself)
summary(fit_pcr)

# 6. Ridge regression on the 28 numerical predictors + dummies

form_x <- as.formula(paste("~", paste(c(num_vars, "classification", "sector"), collapse = " + ")))
y      <- train_data$log_revenue                     # dependent variable
X      <- model.matrix(form_x, data = train_data)    # predictor variables as a matrix, with dummies
X      <- X[, -1]                                    # remove intercept column (is fitted by glmnet)
X_test <- model.matrix(form_x, data = test_data)[, -1]
X_new  <- model.matrix(form_x, data = prediction_new)[, -1]
stopifnot(ncol(X_new) == ncol(X), ncol(X_test) == ncol(X)) # check: same 50 columns in all three matrices

x_mean <- colMeans(X[, num_vars]) # numerical columns turned into z-scores, with the means and sds of the training data
x_sd   <- apply(X[, num_vars], 2, sd)
X[, num_vars]      <- scale(X[, num_vars],      center = x_mean, scale = x_sd)
X_test[, num_vars] <- scale(X_test[, num_vars], center = x_mean, scale = x_sd)
X_new[, num_vars]  <- scale(X_new[, num_vars],  center = x_mean, scale = x_sd)

grid <- 10^seq(-5, 2, length.out = 100) # grid of lambdas (wide enough that lambda.min is not at the edge)
result.ridge <- glmnet(X, y, alpha = 0, lambda = grid, standardize = FALSE) # ridge regression (alpha = 0), already standardised
plot(result.ridge, xvar = "lambda", label = TRUE, las = 1) # coefficients shrink towards 0 but never become exactly 0

set.seed(123) # 10-fold cross validation
result.ridge.cv <- cv.glmnet(X, y, alpha = 0, lambda = grid, nfolds = 10, standardize = FALSE)
print(result.ridge.cv$lambda.min) # best cross validated lambda
print(result.ridge.cv$lambda.1se) # 1se rule: largest lambda within one standard error of the minimum

result.ridge.cv$cvm  <- result.ridge.cv$cvm^0.5 # mse -> rmse, on the same scale as y
result.ridge.cv$cvup <- result.ridge.cv$cvup^0.5
result.ridge.cv$cvlo <- result.ridge.cv$cvlo^0.5
plot(result.ridge.cv, ylab = "Root Mean-Squared Error")

result.ridge.min <- glmnet(X, y, alpha = 0, lambda = result.ridge.cv$lambda.min, standardize = FALSE) # final runs with lambda.min
result.ridge.1se <- glmnet(X, y, alpha = 0, lambda = result.ridge.cv$lambda.1se, standardize = FALSE) # and lambda.1se
Weights <- cbind(result.ridge.min$beta, result.ridge.1se$beta) # coefficients on log scale (per sd for the numerical predictors)
colnames(Weights) <- c("lambda.min", "lambda.1se")
round(Weights, digits = 3)

# 7. Evaluation on log scale and on revenue scale

rmse   <- function(y, yhat) sqrt(mean((y - yhat)^2))
y_test <- test_data$log_revenue

pred_log <- list( # test predictions of log revenue
  "PCR"              = as.numeric(predict(fit_pcr, newdata = test_scores)),
  "Ridge lambda.min" = as.numeric(predict(result.ridge.min, newx = X_test)),
  "Ridge lambda.1se" = as.numeric(predict(result.ridge.1se, newx = X_test)))
fit_log <- list( # fitted values on the training set, needed for the smearing factor
  "PCR"              = as.numeric(fitted(fit_pcr)),
  "Ridge lambda.min" = as.numeric(predict(result.ridge.min, newx = X)),
  "Ridge lambda.1se" = as.numeric(predict(result.ridge.1se, newx = X)))

# exp(log prediction) estimates the MEDIAN revenue and underestimates the mean (jensen's inequality)
# duan's smearing factor = mean(exp(training residuals)); exp(pred) * smear estimates the MEAN revenue
smear <- sapply(fit_log, function(f) mean(exp(y - f)))

rev_test <- test_data$revenue
eval_tab <- do.call(rbind, lapply(names(pred_log), function(m) { # one row per model
  pl <- pred_log[[m]]
  data.frame(Model = m,
             RMSE_log = rmse(y_test, pl),                                  # error on log scale (~ relative error)
             R2_log   = 1 - sum((y_test - pl)^2) / sum((y_test - mean(y_test))^2),
             RMSE_rev_naive_M = rmse(rev_test, exp(pl)) / 1e6,             # error in million usd, plain exp()
             RMSE_rev_smear_M = rmse(rev_test, exp(pl) * smear[m]) / 1e6,  # error in million usd, with smearing
             Smearing = smear[m])
}))
print(eval_tab, digits = 3, row.names = FALSE)

err_by_class <- data.frame(classification = test_data$classification, # where do the dollar errors come from?
                           abs_err_log = abs(y_test - pred_log[["Ridge lambda.min"]]),
                           abs_err_rev = abs(rev_test - exp(pred_log[["Ridge lambda.min"]]))) %>%
  group_by(classification) %>%
  summarise(n = n(), MAE_log = mean(abs_err_log), MAE_rev_M = mean(abs_err_rev) / 1e6,
            share_of_total_abs_err = sum(abs_err_rev)) %>%
  mutate(share_of_total_abs_err = share_of_total_abs_err / sum(share_of_total_abs_err)) %>%
  arrange(desc(MAE_rev_M))
print(err_by_class, n = Inf) # fbs schools cause most of the dollar error

op <- par(mfrow = c(1, 2)) # observed vs predicted log revenue, red line = perfect prediction
plot(pred_log[["PCR"]], y_test, pch = 20, col = "grey40", las = 1, main = "PCR",
     xlab = "Predicted log revenue", ylab = "Observed log revenue")
abline(0, 1, col = "red")
plot(pred_log[["Ridge lambda.min"]], y_test, pch = 20, col = "grey40", las = 1, main = "Ridge (lambda.min)",
     xlab = "Predicted log revenue", ylab = "Observed log revenue")
abline(0, 1, col = "red")
par(op)

# 8. Predictions for the 10 institutions, with the same models that were evaluated on the test set

new_scores <- data.frame(predict(fitpca, newdata = prediction_new[, num_vars])[, 1:n_pc, drop = FALSE], # projected on the training pca
                         classification = prediction_new$classification, sector = prediction_new$sector)
pl_pcr   <- as.numeric(predict(fit_pcr, newdata = new_scores))     # log revenue predictions
pl_ridge <- as.numeric(predict(result.ridge.min, newx = X_new))    # X_new was standardised with the training means/sds

pred_out <- data.frame(id = prediction_new$id, classification = prediction_new$classification, # in million usd
                       rev_PCR_median_M   = exp(pl_pcr) / 1e6,                                  # median-type: exp(pred)
                       rev_PCR_mean_M     = exp(pl_pcr) * smear["PCR"] / 1e6,                   # mean-type: exp(pred) * smearing
                       rev_Ridge_median_M = exp(pl_ridge) / 1e6,
                       rev_Ridge_mean_M   = exp(pl_ridge) * smear["Ridge lambda.min"] / 1e6)
print(pred_out, digits = 3, row.names = FALSE)
write.csv(pred_out, "predictions_output.csv", row.names = FALSE)

## NA
