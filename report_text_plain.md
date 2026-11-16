# 1. Introduction

Customer churn (customers ending their contract and leaving for a competitor) is costly for telecom providers: acquiring a new customer costs more than retaining one, and customers become more profitable the longer they stay (Gupta et al., 2006). This report analyses the churn behaviour of 4,000 customers of a telecom provider. Because the provider wants insight into *why* customers leave, not just a black-box prediction, a **classification tree** is used, which predicts churn with transparent if-then rules that managers can act on (James et al., 2013; Yildirim & Kübler, 2023).

# 2. Data

For each customer, the data contain *Churn* (yes/no; 1,500 customers or 37.5% churned) and twelve predictors without missing values: contract term (*Contract*; 59.7% month-to-month), *tenure* (1--72 months), *MonthlyCharges* (\$18--\$119), *TotalCharges*, *Partner*, *PhoneService*, *MultipleLines*, *InternetService* (DSL, fibre optic or none) and four add-ons (*OnlineSecurity*, *OnlineBackup*, *DeviceProtection*, *TechSupport*; "No internet service" for the 19.4% without internet). The data are split (seed 123) into a **training set of 2,800 (70%)** and a **test set of 1,200 customers (30%)**. The split is stratified by *Churn* (70% of churners and 70% of non-churners are drawn into the training set), so both sets have the same churn rate (37.5% and 37.5%). Always predicting "no churn" gives a baseline test accuracy of 62.5%.

# 3. Methods

**Decision trees.** A classification tree splits customers into groups by asking a sequence of yes/no questions about their attributes (e.g. "Is the contract month-to-month?"). Each final group (*leaf*) predicts its majority class, and its share of churners is an estimated churn probability (Tan et al., 2014). The tree is fitted with the CART algorithm (Breiman et al., 1984) in the R package `rpart` (Therneau & Atkinson, 2023). The tree is grown top-down by *recursive binary splitting*: at each node every predictor and cut-point (or grouping of categories) is tried, and the split that most reduces the Gini impurity $G = 1 - \sum_k \hat p_k^2$ is chosen (James et al., 2013).

**The complexity parameter.** A fully grown tree fits noise in the training data and generalises poorly (overfitting). CART therefore prunes the tree by minimising $R_{cp}(T) = R(T) + cp \cdot |T| \cdot R(T_{\text{root}})$, where $R(T)$ is the training misclassification error, $|T|$ the number of leaves and $R(T_{\text{root}})$ the error without splits. The **complexity parameter** $cp$ is the price of an extra leaf: a split is kept only if it lowers the relative error by at least $cp$. $cp = 0$ gives the full tree; larger values give smaller trees.

**Tuning.** First, the full tree is grown ($cp = 0$), and `rpart` estimates the out-of-sample error of every pruned subtree with **10-fold cross-validation** (*xerror*, with standard error *xstd*). The value of $cp$ is then chosen with the **one-standard-error (1-SE) rule**: the simplest tree whose xerror is within one standard error of the minimum (Hastie et al., 2009). This favours a simpler, more interpretable tree. Test customers are classified as churners if their leaf's churn probability exceeds 0.5.

# 4. Results

**Tuning.** The full tree has 94 splits and a cross-validated relative error of 0.720. The error is lowest (0.622) at 15 splits; larger trees fit noise (Appendix A, Table A1). The 1-SE rule selects $cp$ = 0.0076: a tree with **8 splits and 9 leaves** (xerror 0.637, Figure 1).

**Interpretation.** *Contract* is the root split and the most important variable (23.3% of importance), followed by *tenure* (17.6%), *TotalCharges* (12.5%), *TechSupport* (9.6%) and *OnlineSecurity* (9.2%). The main rules are:

1. **One- or two-year contracts:** 40% of customers, only 10% churn.
2. **Month-to-month, fibre optic, tenure under 16 months:** the highest-risk group (18% of customers, 81% churn).
3. **Month-to-month fibre customers with longer tenure** churn depending on price: 62% for those paying at least \$95.55 per month and 63% for those paying \$83.65--\$95.55 with total charges below \$3,643, against 30--42% for the others.
4. **Month-to-month DSL or no internet:** 28% churn after 6 months' tenure, but 63% for newer customers without online backup.

[Figure 1: keep the `tree plot` chunk here]

**Test-set performance.** The pruned tree classifies **76.5%** of the 1,200 test customers correctly, against the 62.5% baseline. Its training accuracy (78.0%) is similar, so it generalises well, while the unpruned tree reaches only 74.0%. It detects **65.1%** of churners (sensitivity; 293 of 450) and correctly clears **83.3%** of non-churners (specificity; 625 of 750).

# 5. Conclusions and Discussion

A pruned nine-leaf tree predicts churn of unseen customers with 76.5% accuracy (baseline 62.5%). Churn is driven mainly by **commitment** (contract), **customer lifetime** (tenure) and **price and service** (fibre internet, monthly charges and add-ons). Three actions follow: (1) encourage month-to-month customers (55% churn) to move to longer contracts (10%); (2) prioritise new fibre-optic customers (81% churn) with onboarding support; and (3) review pricing for long-standing fibre customers paying more than about \$84 per month and promote add-ons such as online backup to new DSL customers.

**Limitations.** The tree misses 34.9% of churners; a lower probability cut-off catches more, at the cost of false alarms. Single trees are unstable, so cut-points (e.g. 15.5 months) are approximate, and the rules show associations rather than causes, which a controlled retention campaign should test.

# References

Breiman, L., Friedman, J. H., Olshen, R. A., & Stone, C. J. (1984). *Classification and regression trees*. Wadsworth.

Gupta, S., Hanssens, D., Hardie, B., Kahn, W., Kumar, V., Lin, N., Ravishanker, N., & Sriram, S. (2006). Modeling customer lifetime value. *Journal of Service Research, 9*(2), 139--155. https://doi.org/10.1177/1094670506293810

Hastie, T., Tibshirani, R., & Friedman, J. (2009). *The elements of statistical learning: Data mining, inference, and prediction* (2nd ed.). Springer.

James, G., Witten, D., Hastie, T., & Tibshirani, R. (2013). *An introduction to statistical learning: With applications in R*. Springer. https://doi.org/10.1007/978-1-4614-7138-7

Milborrow, S. (2024). *rpart.plot: Plot 'rpart' models* (R package) [Computer software]. https://CRAN.R-project.org/package=rpart.plot

R Core Team. (2024). *R: A language and environment for statistical computing* [Computer software]. R Foundation for Statistical Computing. https://www.R-project.org/

Tan, P.-N., Steinbach, M., & Kumar, V. (2014). *Introduction to data mining* (Pearson new international ed.). Pearson.

Therneau, T., & Atkinson, B. (2023). *rpart: Recursive partitioning and regression trees* (R package version 4.1.23) [Computer software]. https://CRAN.R-project.org/package=rpart

Yildirim, G., & Kübler, R. V. (2023). *Applied marketing analytics using R*. SAGE.

# Appendix A

**Table A1.** Cost-complexity table of the full tree (selected rows, 10-fold cross-validation). Errors are relative to the root-node error; the 1-SE rule selects $cp$ = 0.0076 (8 splits).

**Table A2.** Relative variable importance in the pruned tree (percentage of total; includes surrogate splits).
