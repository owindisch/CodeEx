## =====================================================================
## Bagging & Random Forests: all R code behind the presentation
## Example: Pima Indian diabetes data (MASS::Pima.tr, MASS::Pima.te)
##   Pima.tr = 200 women (training), Pima.te = 332 women (test)
##   outcome type = diabetic Yes/No; 7 predictors:
##   npreg, glu, bp, skin, bmi, ped, age
## Every number on the slides comes out of this script.
## =====================================================================

# install.packages(c("MASS", "rpart", "randomForest"))   # once
library(MASS)          # data
library(rpart)         # single classification tree
library(randomForest)  # bagging and random forests

tr <- Pima.tr
te <- Pima.te
test_error <- function(pred) mean(pred != te$type)


## ---- Slide 2: the example data ---------------------------------------
str(tr)
table(tr$type)                          # 132 No, 68 Yes
mean(te$type == "No")                   # baseline "always No": 1 - 0.328
plot(tr$glu, tr$age, col = ifelse(tr$type == "Yes", "#C8602A", "#9DB4CB"),
     pch = 19, xlab = "Plasma glucose (glu)", ylab = "Age (years)")
abline(v = 123.5, lty = 2)               # first split of the tree


## ---- Slide 3: a single tree and Gini impurity ------------------------
set.seed(1)
tree <- rpart(type ~ ., data = tr)
print(tree)
plot(tree, uniform = TRUE); text(tree, use.n = TRUE, cex = 0.8)

gini <- function(y) { p <- mean(y == "Yes"); 2 * p * (1 - p) }
gini(tr$type)                                     # root node
left <- tr$glu < 123.5
c(gini(tr$type[left]), gini(tr$type[!left]))      # the two children
mean(left) * gini(tr$type[left]) + mean(!left) * gini(tr$type[!left])  # weighted


## ---- Slide 4: trees are unstable (four bootstrap trees) --------------
set.seed(2)
par(mfrow = c(2, 2))
for (b in 1:4) {
  i  <- sample(nrow(tr), replace = TRUE)          # bootstrap sample
  if (b == 1) idx1 <- i                           # keep sample 1 for slide 5
  tb <- rpart(type ~ ., data = tr[i, ])
  e  <- test_error(predict(tb, te, type = "class"))
  cat(sprintf("sample %d: test error %.1f%%\n", b, 100 * e))
  plot(tb, uniform = TRUE, main = sprintf("Bootstrap sample %d, test error %.1f%%", b, 100 * e))
  text(tb, cex = 0.7)
}
par(mfrow = c(1, 1))


## ---- Slide 5: the bootstrap ------------------------------------------
table(times_drawn = tabulate(idx1, nbins = 200))  # 0 = out-of-bag
mean(tabulate(idx1, nbins = 200) == 0)            # share never drawn
(1 - 1/200)^200                                   # theory: -> exp(-1) = 0.368


## ---- Slide 7: bagging works (50 single trees vs 50 bagged ensembles) -
set.seed(3)
P1 <- replicate(50, {                             # 50 single trees
  i  <- sample(nrow(tr), replace = TRUE)
  tb <- rpart(type ~ ., data = tr[i, ])
  predict(tb, te, type = "class") == "Yes"
})
P2 <- replicate(50, {                             # 50 bagged ensembles, 200 trees each
  b <- randomForest(type ~ ., data = tr, mtry = 7, ntree = 200)
  predict(b, te) == "Yes"
})
truth <- te$type == "Yes"
e1 <- colMeans(P1 != truth); e2 <- colMeans(P2 != truth)
round(100 * c(single_mean = mean(e1), single_sd = sd(e1),
              bagged_mean = mean(e2), bagged_sd = sd(e2)), 1)
# prediction variance: p_i = share of models voting Yes for test woman i
pvar <- function(P) mean(apply(P, 1, function(z) mean(z) * (1 - mean(z))))
round(c(single_trees = pvar(P1), bagged = pvar(P2)), 3)
stripchart(list(single = 100 * e1, bagged = 100 * e2), method = "stack",
           pch = 19, xlab = "Test error (%)")


## ---- Slides 6, 8, 14, 15: the three models ---------------------------
set.seed(1)
tree <- rpart(type ~ ., data = tr)                                     # single tree
bag  <- randomForest(type ~ ., data = tr, mtry = 7, ntree = 500)       # bagging: m = p = 7
rf   <- randomForest(type ~ ., data = tr, ntree = 500,                 # forest: m = floor(sqrt(7)) = 2
                     importance = TRUE, keep.inbag = TRUE)
bag
rf                                                # OOB error + confusion matrix

round(100 * c(tree = test_error(predict(tree, te, type = "class")),
              bag  = test_error(predict(bag, te)),
              rf   = test_error(predict(rf, te))), 1)


## ---- Slide 8: random forests decorrelate the trees --------------------
root_var <- function(m) sapply(1:m$ntree, function(k)
  as.character(getTree(m, k, labelVar = TRUE)[1, "split var"]))
table(bagging = root_var(bag))                    # first split of each tree
table(forest  = root_var(rf))

tree_cor <- function(m) {                         # mean pairwise correlation of tree votes
  v  <- (predict(m, te, predict.all = TRUE)$individual == "Yes") * 1
  cm <- cor(v)
  mean(cm[upper.tri(cm)], na.rm = TRUE)
}
round(c(bagging = tree_cor(bag), forest = tree_cor(rf)), 2)


## ---- Slide 11: out-of-bag error step by step -------------------------
rf$inbag[1:8, 1:12]                               # draws per woman (rows) and tree (cols); 0 = OOB
sum(rf$inbag[1, ] == 0)                           # trees that never saw woman 1
rf$votes[1, ]                                     # OOB vote shares for woman 1
tr$type[1]                                        # her true class


## ---- Slide 12: OOB error and number of trees -------------------------
mean(rf$oob.times)                                # ~ 0.367 * 500 trees per woman
rf$err.rate[500, "OOB"]                           # OOB error of the forest
plot(rf$err.rate[, "OOB"], type = "l", col = "#2E6B4F",
     xlab = "Number of trees", ylab = "OOB error", ylim = c(0.2, 0.4))
lines(bag$err.rate[, "OOB"], col = "#6B8FB5")
legend("topright", c("Random forest (m = 2)", "Bagging (m = 7)"),
       col = c("#2E6B4F", "#6B8FB5"), lty = 1)


## ---- Slide 13: tuning m (mtry) with OOB error ------------------------
mt <- expand.grid(m = 1:7, seed = 1:5)
mt$err <- NA
for (r in seq_len(nrow(mt))) {
  set.seed(100 + mt$seed[r])
  mt$err[r] <- randomForest(type ~ ., data = tr, mtry = mt$m[r],
                            ntree = 500)$err.rate[500, "OOB"]
}
ms <- aggregate(err ~ m, mt, mean)
round(setNames(100 * ms$err, paste0("m=", ms$m)), 1)
plot(mt$m, 100 * mt$err, xlab = "m (7 = bagging)", ylab = "OOB error (%)")
lines(ms$m, 100 * ms$err, type = "b", pch = 18, col = "#2E6B4F")
# built-in alternative: tuneRF(tr[, -8], tr$type, ntreeTry = 500)


## ---- Slide 16: interpretation ----------------------------------------
round(importance(rf)[, c("MeanDecreaseAccuracy", "MeanDecreaseGini")], 1)
varImpPlot(rf)                                    # permutation vs Gini importance
round(predict(rf, te[1:4, ], type = "prob"), 2)   # vote shares as risk scores
partialPlot(rf, tr, glu, which.class = "Yes")     # optional: effect of glucose


## ---- Slide 17: limitation, class imbalance ---------------------------
table(predicted = predict(rf, te), actual = te$type)
set.seed(1)
rfb <- randomForest(type ~ ., data = tr, ntree = 500,
                    sampsize = c(68, 68))         # balanced bootstrap samples
table(predicted = predict(rfb, te), actual = te$type)
round(100 * test_error(predict(rfb, te)), 1)
