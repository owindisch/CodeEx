library(tidyverse); library(glmnet); library(boot); library(gridExtra); library(caret)

permtestPCA <- function(X, nTests = 100, alpha = 0.05, ...){ # permutation test function from lecture 5
  n <- nrow(X); m <- ncol(X); X <- scale(X)
  eigs.X <- prcomp(X)$sdev^2; eigs.Xperm <- matrix(0, m, nTests); Xperm <- X
  for (i in 1:nTests){
    for (j in 2:m) Xperm[, j] <- X[sample(n), j]                  # random permutation of the rows per column
    eigs.Xperm[, i] <- prcomp(Xperm)$sdev^2}
  perc.alpha <- t(apply(eigs.Xperm, 1, quantile, c(alpha/2, 1 - alpha/2)))
  plot(1:m, eigs.X, type = "b", col = "red", main = "Permutation test PCA", xlab = "Component", ylab = "Eigenvalue", ...)
  matlines(1:m, perc.alpha, type = "b", col = "blue", lty = 1)
  perc.alpha}
f2 <- function(x, d = 2) formatC(x, format = "f", digits = d)    # rounds numbers for the text and tables

# 1. Inspect data
athletics  <- read.csv("data_783996yw.csv"); prediction <- read.csv("predictions-2.csv")
dim(athletics); summary(athletics$revenue)                      # size and distribution of revenue
colSums(is.na(athletics))[colSums(is.na(athletics)) > 0]        # missing values only in the coach variables
table(no_men_teams = athletics$teams_men == 0, hc_missing = is.na(athletics$hc_men)) # no men's team -> no men's hc
min(athletics$ac_men, na.rm = TRUE)                             # ac never 0, so na = no acs
sum(!is.na(athletics$ac_men) & is.na(athletics$ac_salary_men))  # acs but no salary (volunteers?)
table(athletics$classification); table(athletics$sector)        # some levels are very small
revenue <- ggplot(athletics, aes(revenue / 1e6)) + geom_histogram(bins = 50, fill = "blue", color = "white") +
  labs(title = "Revenue of athletics programs", x = "Revenue (in million USD)", y = "Count") + theme_minimal()
logrevenue <- ggplot(athletics, aes(log(revenue))) + geom_histogram(bins = 50, fill = "purple", color = "white") +
  labs(title = "Log revenue", x = "log(revenue)", y = "Count") + theme_minimal()
grid.arrange(revenue, logrevenue, ncol = 2)                     # very skewed -> log revenue is roughly symmetric

# 2. Clean up the data
count_vars  <- c("ugrad_men", "ugrad_women", "athletes_men", "athletes_women", "teams_men", "teams_women",
                 grep("^partic_", names(athletics), value = TRUE), "hc_men", "hc_women", "ac_men", "ac_women") # logged
salary_vars <- c("hc_salary_men", "hc_salary_women", "ac_salary_men", "ac_salary_women")                    # logged
share_vars  <- c("hc_fulltime_share", "hc_female_share")                                                   # 0 to 1, not logged
num_vars    <- c(count_vars, salary_vars, share_vars)                                                      # 28 numerical predictors
fixed_coaches <- function(x) {                                  # runs once for men's and once for women's variables
  for (s in c("men", "women")) {
    hc <- paste0("hc_", s); ac <- paste0("ac_", s); hs <- paste0("hc_salary_", s); as <- paste0("ac_salary_", s)
    no_hc <- is.na(x[[hc]]); no_ac <- is.na(x[[ac]])             # institutions without hcs / acs
    x[[hc]][no_hc] <- 0; x[[ac]][no_ac] <- 0                     # no coaches -> 0
    x[[hs]][no_hc & is.na(x[[hs]])] <- 0; x[[as]][no_ac & is.na(x[[as]])] <- 0 # and salary 0; coaches without salary stay na
  }
  x}
logged_vars <- function(x) { for (v in c(count_vars, salary_vars)) x[[v]] <- log1p(x[[v]]); x } # log(x + 1), as x can be 0
athletics_new  <- fixed_coaches(athletics); prediction_new <- fixed_coaches(prediction)
athletics_new$log_revenue <- log(athletics_new$revenue)         # dependent variable
athletics_new$classification <- factor(athletics_new$classification); athletics_new$sector <- factor(athletics_new$sector)
prediction_new$classification <- factor(prediction_new$classification, levels = levels(athletics_new$classification)) # same levels -> same dummies
prediction_new$sector <- factor(prediction_new$sector, levels = levels(athletics_new$sector))
athletics_new <- logged_vars(athletics_new); prediction_new <- logged_vars(prediction_new)

# 3. Split the data (80/20) and impute with training medians
set.seed(123)
trainRowNumbers <- createDataPartition(athletics_new$log_revenue, p = 0.8, list = FALSE)
train_data <- athletics_new[trainRowNumbers, ]; test_data <- athletics_new[-trainRowNumbers, ]
train_medians <- sapply(train_data[num_vars], median, na.rm = TRUE) # training data only (no leakage)
impute <- function(x) { for (v in num_vars) x[[v]][is.na(x[[v]])] <- train_medians[v]; x }
train_data <- impute(train_data); test_data <- impute(test_data); prediction_new <- impute(prediction_new)
round(sort(sapply(train_data[num_vars], cor, y = train_data$log_revenue), decreasing = TRUE), 2) # correlations with log revenue

# 4. PCA on the 28 numerical predictors (training data)
X_pca <- train_data[, num_vars]; X_pca_test <- test_data[, num_vars]; p <- ncol(X_pca)
fitpca <- princomp(X_pca, cor = TRUE, scores = TRUE)            # correlation matrix (different units)
eigenvalues <- fitpca$sdev^2; vaf <- eigenvalues / p; cum_vaf <- cumsum(vaf)
screeplot(fitpca, npcs = p, type = "lines", main = "Scree plot"); abline(h = 1, col = "red", lty = 2) # elbow + kaiser line
k_kaiser <- sum(eigenvalues > 1)                                # kaiser: eigenvalue > 1
k_vaf80  <- which(cum_vaf >= 0.80)[1]                           # 80% cumulative vaf
set.seed(123); perm_range <- permtestPCA(X_pca, nTests = 1000)  # permutation test
k_perm <- which(eigenvalues <= perm_range[, 2])[1] - 1          # keep pcs above the 97.5% bound
my_boot_pca <- function(x, ind) princomp(x[ind, ], cor = TRUE)$sdev^2 # pca on resampled rows -> eigenvalues
set.seed(123); eigs.boot <- boot(data = X_pca, statistic = my_boot_pca, R = 1000)$t
kaiser_boot <- data.frame(PC = 1:p, Eigenvalue = eigenvalues, Lower = apply(eigs.boot, 2, quantile, 0.025),
                          Upper = apply(eigs.boot, 2, quantile, 0.975))
k_kaiser_boot <- which(kaiser_boot$Lower <= 1)[1] - 1           # bootstrapped kaiser: whole ci above 1
data.frame(Method = c("Kaiser", "80% VAF", "Permutation test", "Bootstrapped Kaiser"),
           PCs = c(k_kaiser, k_vaf80, k_perm, k_kaiser_boot))
n_pc <- k_perm                                                  # chosen: permutation test
vaf.boot   <- rowSums(eigs.boot[, 1:n_pc, drop = FALSE]) / p    # bootstrapped vaf of the chosen pcs
perc.alpha <- quantile(vaf.boot, c(0.025, 0.975)); round(100 * c(cum_vaf[n_pc], perc.alpha), 1)
corpca  <- cor(X_pca, fitpca$scores)[, 1:n_pc]                  # loadings = correlations variables and scores
fit_var <- cbind(corpca, Fit = rowSums(corpca^2)); round(fit_var, 2) # fit per variable
biplot(fitpca, pc.biplot = TRUE, scale = 1, choices = 1:2, col = c("grey70", "red"), asp = 1,
       cex = c(0.4, 0.6), xlabs = rep("o", nrow(X_pca)))      # points = institutions, arrows = variables

# 5. Principal component regression: pc scores + classification and sector dummies
train_scores <- data.frame(fitpca$scores[, 1:n_pc], classification = train_data$classification,
                           sector = train_data$sector, log_revenue = train_data$log_revenue)
test_scores  <- data.frame(predict(fitpca, newdata = X_pca_test)[, 1:n_pc], # test projected on the training pca
                           classification = test_data$classification, sector = test_data$sector)
fit_pcr <- lm(log_revenue ~ ., data = train_scores); summary(fit_pcr)

# 6. Ridge regression on the 28 numerical predictors + dummies
form_x <- as.formula(paste("~", paste(c(num_vars, "classification", "sector"), collapse = " + ")))
y <- train_data$log_revenue
X <- model.matrix(form_x, train_data)[, -1]                     # dummies, intercept removed (glmnet fits it)
X_test <- model.matrix(form_x, test_data)[, -1]; X_new <- model.matrix(form_x, prediction_new)[, -1]
x_mean <- colMeans(X[, num_vars]); x_sd <- apply(X[, num_vars], 2, sd) # z-scores with training means and sds
X[, num_vars] <- scale(X[, num_vars], x_mean, x_sd); X_test[, num_vars] <- scale(X_test[, num_vars], x_mean, x_sd)
X_new[, num_vars] <- scale(X_new[, num_vars], x_mean, x_sd)
grid <- 10^seq(-5, 2, length.out = 100)                         # grid of lambdas
plot(glmnet(X, y, alpha = 0, lambda = grid, standardize = FALSE), xvar = "lambda") # coefficient paths
set.seed(123); result.ridge.cv <- cv.glmnet(X, y, alpha = 0, lambda = grid, nfolds = 10, standardize = FALSE)
c(result.ridge.cv$lambda.min, result.ridge.cv$lambda.1se)       # lambda.min and 1se rule
result.ridge.min <- glmnet(X, y, alpha = 0, lambda = result.ridge.cv$lambda.min, standardize = FALSE)
result.ridge.1se <- glmnet(X, y, alpha = 0, lambda = result.ridge.cv$lambda.1se, standardize = FALSE)
round(cbind(result.ridge.min$beta, result.ridge.1se$beta), 3)   # coefficients (per sd for numerical predictors)

# 7. Evaluation on the test set, log scale and revenue scale (exp() gives the median revenue)
rmse <- function(y, yhat) sqrt(mean((y - yhat)^2))
y_test <- test_data$log_revenue; rev_test <- test_data$revenue
pred_log <- list("PCR" = predict(fit_pcr, newdata = test_scores),
                 "Ridge lambda.min" = as.numeric(predict(result.ridge.min, newx = X_test)),
                 "Ridge lambda.1se" = as.numeric(predict(result.ridge.1se, newx = X_test)))
eval_tab <- do.call(rbind, lapply(names(pred_log), function(m) { pl <- pred_log[[m]]
  data.frame(Model = m, RMSE_log = rmse(y_test, pl), R2_log = 1 - sum((y_test - pl)^2) / sum((y_test - mean(y_test))^2),
             RMSE_rev_M = rmse(rev_test, exp(pl)) / 1e6) }))   # rmse in million usd after exp()
eval_tab
err_by_class <- data.frame(classification = test_data$classification,   # where do the usd errors come from?
                           sq_err_rev = (rev_test - exp(pred_log[["Ridge lambda.min"]]))^2) %>%
  group_by(classification) %>% summarise(n = n(), share_of_squared_err = sum(sq_err_rev)) %>%
  mutate(share_of_squared_err = share_of_squared_err / sum(share_of_squared_err)) %>% arrange(desc(share_of_squared_err))
err_by_class                                                    # fbs schools cause most of the usd error

# 8. Predictions for the 10 institutions
new_scores <- data.frame(predict(fitpca, newdata = prediction_new[, num_vars])[, 1:n_pc],
                         classification = prediction_new$classification, sector = prediction_new$sector)
pred_out <- data.frame(id = prediction_new$id, classification = prediction_new$classification,
                       rev_PCR_M = exp(predict(fit_pcr, newdata = new_scores)) / 1e6,          # back to usd with exp()
                       rev_Ridge_M = exp(as.numeric(predict(result.ridge.min, newx = X_new))) / 1e6)
pred_out
