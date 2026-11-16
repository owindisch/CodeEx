# 1. Introduction

Customer churn (customers leaving for a competitor) is costly for telecom providers: acquiring a new customer costs more than retaining one, and customers become more profitable the longer they stay (Gupta et al., 2006). This report analyses the churn behaviour of 4,000 customers of a telecom provider. Because the provider wants insight into *why* customers leave, not just a black-box prediction, a **classification tree** is used, which predicts churn with transparent if-then rules that managers can act on (James et al., 2013; Yildirim & Kübler, 2023).

# 2. Data

For each customer, the data contain *Churn* (yes/no; 1,500 customers or 37.5% churned) and twelve predictors without missing values: contract term (*Contract*; 59.7% month-to-month), *tenure* (1--72 months), *MonthlyCharges* (\$18--\$119), *TotalCharges*, *Partner*, *PhoneService*, *MultipleLines*, *InternetService* (DSL, fibre optic or none) and four add-ons (*OnlineSecurity*, *OnlineBackup*, *DeviceProtection*, *TechSupport*; "No internet service" for the 19.4% without internet). A stratified split (seed 123; Section 3) gives a **training set of 2,800** and a **test set of 1,200 customers**, both with a churn rate of 37.5%; always predicting "no churn" thus gives a baseline test accuracy of 62.5%.

# 3. Methods

Consider a data set of $n$ observations with a categorical response $Y$ with classes $k = 1, \dots, K$ and predictors $X_1, \dots, X_p$. The tree is fitted and evaluated in five steps (James et al., 2013; Tan et al., 2014).

1. **Train/test split.** The data are divided into a training set (70%) for fitting and tuning, and a test set (30%) used only to estimate out-of-sample performance. The split is *stratified*: 70% of each class is drawn at random, so both sets keep the class proportions.
2. **Growing the tree.** CART (Breiman et al., 1984), implemented in `rpart` (Therneau & Atkinson, 2023), grows the tree top-down by *recursive binary splitting*. For each node $m$, every predictor $X_j$ and cut-point $s$ (or grouping of categories) is tried, and the split into $\{X_j < s\}$ and $\{X_j \geq s\}$ that most reduces the weighted Gini impurity $G_m = 1 - \sum_k \hat p_{mk}^2$ of the two child nodes is chosen, where $\hat p_{mk}$ is the share of class $k$ in node $m$. Splitting continues until nodes are pure or too small; each leaf predicts its majority class, with $\hat p_{mk}$ as class probability.
3. **Cost-complexity pruning.** A fully grown tree fits noise in the training data (overfitting). It is therefore pruned by minimising $R_{cp}(T) = R(T) + cp \cdot |T| \cdot R(T_{\text{root}})$, where $R(T)$ is the training misclassification error of subtree $T$, $|T|$ its number of leaves and $R(T_{\text{root}})$ the error without splits. The **complexity parameter** $cp$ is the price of an extra leaf: a split is kept only if it lowers the relative error by at least $cp$. $cp = 0$ keeps the full tree; larger $cp$ gives smaller, nested subtrees.
4. **Tuning $cp$.** The training set is split into $K = 10$ folds. For every candidate $cp$, the tree is grown and pruned on nine folds and its error is measured on the tenth; averaging over folds gives the cross-validated error (*xerror*) and its standard error (*xstd*). The **one-standard-error (1-SE) rule** selects the simplest tree whose xerror is within one standard error of the minimum (Hastie et al., 2009), favouring a simpler, more interpretable tree.
5. **Prediction and evaluation.** Each test observation is passed down the pruned tree and assigned the majority class of its leaf (for two classes: predicted probability above 0.5). Performance is measured by accuracy, sensitivity and specificity, and compared with a majority-class baseline. Variable importance is a predictor's total impurity reduction, including as a surrogate split.

# 4. Results

**Tuning.** The full tree has 94 splits and a cross-validated relative error of 0.720. The error is lowest (0.622) at 15 splits; larger trees fit noise (Appendix A, Table A1). The 1-SE rule selects $cp$ = 0.0076: a tree with **8 splits and 9 leaves** (xerror 0.637, Figure 1).

**Interpretation.** *Contract* is the root split and the most important variable (23.3% of importance), followed by *tenure* (17.6%) and *TotalCharges* (12.5%; Table A2). The main rules are:

1. **One- or two-year contracts:** 40% of customers, only 10% churn.
2. **Month-to-month, fibre optic, tenure under 16 months:** the highest-risk group (18% of customers, 81% churn).
3. **Month-to-month fibre, longer tenure:** churn depends on price; 62% for monthly charges of at least \$95.55, and 30--63% below that, depending on charges.
4. **Month-to-month DSL or no internet:** 28% churn after 6 months' tenure, but 63% for newer customers without online backup.

[Figure 1: keep the `tree plot` chunk here]

**Test-set performance.** The pruned tree classifies **76.5%** of the 1,200 test customers correctly, against the 62.5% baseline. Training accuracy is similar (78.0%), and the unpruned tree reaches only 74.0%. It detects **65.1%** of churners (sensitivity; 293 of 450) and correctly clears **83.3%** of non-churners (specificity; 625 of 750).

# 5. Conclusions and Discussion

A pruned nine-leaf tree predicts churn of unseen customers with 76.5% accuracy (baseline 62.5%). Churn is driven mainly by **commitment** (contract), **customer lifetime** (tenure) and **price and service** (fibre internet, monthly charges and add-ons). Three actions follow: (1) encourage month-to-month customers (55% churn) to move to longer contracts (10%); (2) prioritise new fibre-optic customers (81% churn) with onboarding support; and (3) review prices for long-standing fibre customers and promote add-ons such as online backup to new DSL customers.

**Limitations.** The tree misses 34.9% of churners (a lower cut-off catches more, with more false alarms); single trees are unstable, so cut-points are approximate; and the rules show associations, not causes.

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
