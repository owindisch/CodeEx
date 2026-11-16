# 1. Introduction

Since acquiring a new customer costs more than retaining an existing one, and customers become more profitable the longer they stay (Gupta et al., 2006), it is in a company's best interest to minimise churn, i.e. customers ending their contract and switching to a competitor. This report therefore investigates the churn behaviour of 4,000 customers of a telecom provider to gain insight into the factors that play a role in their decision to leave, addressing the question: **which customer characteristics are related to churn, and which customers should a telecom provider target to reduce it?**

# 2. Data

The data were provided by a telecom provider and contain 4,000 customers. For each customer, the data contain *Churn* (yes/no; 1,500 customers or 37.5% churned) and twelve predictors without missing values: the contract term (*Contract*; 59.7% month-to-month), months with the company (*tenure*; median 25.5), the monthly and total amount charged (*MonthlyCharges*, median \$73; *TotalCharges*), whether the customer has a partner, phone service or multiple lines, the internet provider (*InternetService*: DSL, fibre optic or none) and four add-ons (online security, online backup, device protection, tech support). Churn differs strongly between groups: 56.0% of month-to-month customers churned against 4.5% of two-year customers, and 54.6% of fibre customers against 27.7% of DSL customers. The data are randomly split into a training set of 2,800 (70%) and a test set of 1,200 customers (30%), stratified by *Churn* so that both sets have exactly the same churn rate of 37.5%. Always predicting "no churn" therefore gives a baseline accuracy of 62.5%.

# 3. Methods

A **classification tree** predicts a categorical outcome through a sequence of yes/no questions about the predictors (e.g. "is $X_1$ below 10?"). Each question splits the observations into two more homogeneous groups; the final groups (*leaves*) predict their most common class. The result is a set of easy-to-read if-then rules (James et al., 2013).

Technically, let the data contain $n$ observations of a categorical response $Y$ with $K$ classes and $p$ predictors $X_1, \dots, X_p$. The tree is grown with *recursive binary splitting* (CART; Breiman et al., 1984): at each node $m$, every predictor $X_j$ and cut-point $s$ is tried, splitting the node into $\{X_j < s\}$ and $\{X_j \geq s\}$, and the split with the lowest weighted Gini impurity of the two new nodes is chosen, where
$$G_m = 1 - \sum_{k=1}^{K} \hat p_{mk}^2$$
and $\hat p_{mk}$ is the proportion of training observations in node $m$ of class $k$ ($G_m = 0$ for a pure node). A leaf predicts its most common class, with $\hat p_{mk}$ as class probability. A fully grown tree fits noise (overfitting), so it is *pruned* to the subtree $T$ that minimises
$$R_{cp}(T) = R(T) + cp \cdot |T| \cdot R(T_0),$$
where $R(T)$ is the share of misclassified training observations, $|T|$ the number of leaves of $T$, $R(T_0)$ the misclassification rate of the tree without splits, and $cp \geq 0$ the **complexity parameter**. A split is kept only if it lowers the relative error by at least $cp$, so a larger $cp$ gives a smaller tree.

After a stratified split into a training and a test set, $cp$ is chosen on the training set by **10-fold cross-validation**: the tree is fitted on nine tenths of the data and tested on the remaining tenth, giving a *cross-validated error* and its standard error; lower is better. The **one-standard-error rule** picks the smallest tree within one standard error of the minimum (Hastie et al., 2009). On the test set, higher **accuracy** (share of correct predictions), **sensitivity** (share of actual positives predicted positive) and **specificity** (share of actual negatives predicted negative) are better, and accuracy should clearly exceed the **baseline** of always predicting the most common class. The **variable importance** of a predictor is its share of the total Gini reduction over all (including surrogate) splits; higher means more influential.

# 4. Results

The full tree has 94 splits; the cross-validated error is lowest (0.622) at 15 splits (Appendix A, Table A1). The one-standard-error rule selects $cp$ = 0.0076, a tree with 8 splits and 9 leaves (Figure 1).

[Figure 1: keep the `tree plot` chunk here]

The tree first splits on contract type, the most important variable (23.3% of importance), followed by *tenure* (17.6%) and *TotalCharges* (12.5%; Table A2). Customers with a one- or two-year contract (40% of customers) rarely leave: only 10% churn. A long contract creates commitment and switching costs. Among month-to-month customers, the type of internet matters most. **New fibre-optic customers** (month-to-month, less than 16 months with the company) are by far the riskiest group: 18% of customers, of whom 81% churn. Fibre is the most expensive service, and these customers have not yet built up loyalty. Fibre customers who stay longer churn less, but churn rises again with price: 62% of those paying at least \$95.55 per month leave. For month-to-month DSL customers and customers without internet, tenure is decisive: after six months only 28% churn, but new customers without online backup churn at 63%: customers who use more services seem more attached.

On the 1,200 test customers, the tree predicts 76.5% correctly, well above the 62.5% baseline. The training accuracy is similar (78.0%), and the unpruned tree reaches only 74.0%. The tree finds 65.1% of the churners (sensitivity) and correctly identifies 83.3% of the customers who stay (specificity).

# 5. Conclusions and Discussion

Churn mainly depends on how strongly customers are tied to the provider: their contract, tenure, and internet service and its price. The provider should target month-to-month customers in their first year, especially fibre customers, e.g. with discounts for a one- or two-year contract, review its most expensive fibre plans, and encourage new DSL customers to use extra services such as online backup.

The analysis could be improved: a lower probability cut-off would find more of the 34.9% missed churners, a random forest would be more stable, and data on satisfaction or competitor prices could reveal causes.

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
