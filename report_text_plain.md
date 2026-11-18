# 1. Introduction

Since acquiring a new customer costs more than retaining an existing one, and customers become more profitable the longer they stay (Gupta et al., 2006), it is in a company's best interest to minimise churn, i.e. customers ending their contract and switching to a competitor. This report therefore investigates the churn behaviour of 4,000 customers of a telecom provider to gain insight into the factors that play a role in their decision to leave, addressing the question: **which customer characteristics are related to churn, and which customers should a telecom provider target to reduce it?**

# 2. Data

The data were provided by a telecom provider and contain 4,000 customers. For each customer, the data contain *Churn* (yes/no; 1,500 or 37.5% churned) and twelve predictors without missing values: the contract term (*Contract*; 59.7% month-to-month), months with the company (*tenure*; median 25.5), the monthly and total amount charged (*MonthlyCharges*, median \$73; *TotalCharges*), whether the customer has a partner, phone service or multiple lines, the internet provider (*InternetService*: DSL, fibre optic or none) and four add-ons (online security, online backup, device protection, tech support). Churn differs strongly between groups: 56.0% of month-to-month customers churned against 4.5% of two-year customers, and 54.6% of fibre customers against 27.7% of DSL customers. The data are randomly split into a training set of 2,800 (70%) and a test set of 1,200 customers (30%), stratified by *Churn* so both sets have the same churn rate of 37.5%. Always predicting "no churn" thus gives a baseline accuracy of 62.5%.

# 3. Methods

To identify which characteristics are related to churn, a decision tree is used. Since churn is categorical, CART (Classification And Regression Trees; Breiman et al., 1984) builds a *classification tree*, which predicts the outcome through a series of yes/no questions, such as "is $X_1$ below 10?". Each question splits the observations into two more homogeneous groups; the final groups (*leaves*) predict their most common class, giving easy-to-read if-then rules (Yildirim & Kübler, 2023). Formally, each observation has a response $Y$ in one of $K$ classes and $p$ predictors $X_1, \dots, X_p$. The tree is built in five steps.

*First*, the tree is grown on a training set by *recursive binary splitting* (James et al., 2013; Tan et al., 2014). At each node $m$, every predictor $X_j$ and cut-point $s$ is tried. Each candidate splits the node into $\{X_j < s\}$ and $\{X_j \geq s\}$. The split with the lowest weighted Gini impurity of the two new nodes is chosen, where
$$G_m = 1 - \sum_{k=1}^{K} \hat p_{mk}^2$$
and $\hat p_{mk}$ is the share of training observations in node $m$ that belong to class $k$. A pure node has $G_m = 0$. In a leaf, $\hat p_{mk}$ is the predicted probability of class $k$.

*Second*, because a fully grown tree also fits noise and this often leads to overfitting, it is *pruned* (Tan et al., 2014). In `rpart` (Therneau & Atkinson, 2023), the pruned tree is the subtree $T$ that minimises
$$R_{cp}(T) = R(T) + cp \cdot |T| \cdot R(T_0),$$
where $R(T)$ is the share of misclassified training observations, $|T|$ the number of leaves of $T$, $R(T_0)$ the misclassification rate of the tree without splits, and $cp \geq 0$ the **complexity parameter**. A split is only kept if it lowers the relative error by at least $cp$, so a larger $cp$ gives a smaller tree.

*Third*, $cp$ is chosen by **10-fold cross-validation** (James et al., 2013). The training set is divided into 10 parts and the tree is fitted on 9 parts. It is then tested on the remaining part, in turn. This gives a *cross-validated error* and its standard error; lower is better. The **one-standard-error rule** selects the smallest tree whose error is within one standard error of the minimum (Hastie et al., 2009).

*Fourth*, the selected tree is evaluated on a separate test set by its **accuracy** (share of correct predictions), **precision** $P$ (share of predicted positives that are correct), **recall** $R$ (share of actual positives detected) and **F1 score** $F_1 = 2PR/(P+R)$ (Tan et al., 2014). Higher is better; accuracy should clearly exceed the **baseline accuracy** of always predicting the majority class. *Finally*, a predictor's **variable importance** is its share of the total Gini reduction; higher is more important (de Oña et al., 2016).

# 4. Results

The full tree has 94 splits; the cross-validated error is lowest (0.622) at 15 splits. The one-standard-error rule selects $cp$ = 0.0076, a tree with 8 splits and 9 leaves (Figure 1).

[Figure 1: keep the `tree plot` chunk here]

The tree first splits on contract type, the most important variable (23.3% of importance), followed by tenure (17.6%) and total charges (12.5%; Appendix A, Table A1). Customers with a contract of at least one year (40% of all customers) are fairly safe: only 10% of them churn. Month-to-month customers (60% of all customers) are much more likely to leave: 55% of them churn. Within this group, the type of internet matters most. Month-to-month fibre-optic customers (35% of all customers) churn at 67%. Those with less than 16 months' tenure are the riskiest group (18% of all customers): 81% of them churn. Among fibre customers who stay longer, price matters: 62% of those paying at least \$96 a month churn. Month-to-month customers with DSL or no internet (25% of all customers) churn at 38%, and tenure matters most: after six months, only 28% churn. Of newer customers without online backup, 63% churn.

On the 1,200 test customers, the tree predicts churn correctly in 76.5% of cases. This is well above the 62.5% baseline and close to the 78.0% on the training data, so the tree does not overfit; the unpruned tree only reaches 74.0%. Of the customers the tree flags as churners, 70.1% actually leave (precision), and it finds 65.1% of all churners (recall), giving an F1 score of 0.68.

# 5. Conclusions and Discussion

This report asked which customer characteristics are related to churn and which customers to target. Churn mainly depends on how strongly customers are tied to the provider through contract length, tenure, internet service and price. Customers with a long contract rarely churn, as switching is harder. New fibre customers churn most often. They pay for the most expensive service but are not yet loyal. Customers with extra services, such as online backup, seem more attached. The provider should therefore target month-to-month customers in their first year, especially fibre customers, e.g. with discounts on longer contracts, and promote extra services to new DSL customers. To improve the analysis, a lower cut-off could catch more of the 34.9% missed churners, and satisfaction data could explain why customers leave.

# References

Breiman, L., Friedman, J. H., Olshen, R. A., & Stone, C. J. (1984). *Classification and regression trees*. Wadsworth.

de Oña, J., de Oña, R., & López, G. (2016). Transit service quality analysis using cluster analysis and decision trees: A step forward to personalized marketing in public transportation. *Transportation, 43*(5), 725--747. https://doi.org/10.1007/s11116-015-9615-0

Gupta, S., Hanssens, D., Hardie, B., Kahn, W., Kumar, V., Lin, N., Ravishanker, N., & Sriram, S. (2006). Modeling customer lifetime value. *Journal of Service Research, 9*(2), 139--155. https://doi.org/10.1177/1094670506293810

Hastie, T., Tibshirani, R., & Friedman, J. (2009). *The elements of statistical learning: Data mining, inference, and prediction* (2nd ed.). Springer.

James, G., Witten, D., Hastie, T., & Tibshirani, R. (2013). *An introduction to statistical learning: With applications in R*. Springer. https://doi.org/10.1007/978-1-4614-7138-7

Milborrow, S. (2024). *rpart.plot: Plot 'rpart' models* (R package) [Computer software]. https://CRAN.R-project.org/package=rpart.plot

R Core Team. (2024). *R: A language and environment for statistical computing* [Computer software]. R Foundation for Statistical Computing. https://www.R-project.org/

Tan, P.-N., Steinbach, M., & Kumar, V. (2014). *Introduction to data mining* (Pearson new international ed.). Pearson.

Therneau, T., & Atkinson, B. (2023). *rpart: Recursive partitioning and regression trees* (R package version 4.1.23) [Computer software]. https://CRAN.R-project.org/package=rpart

Yildirim, G., & Kübler, R. V. (2023). *Applied marketing analytics using R*. SAGE.

# Appendix A

**Table A1.** Relative variable importance in the pruned tree (percentage of total; includes surrogate splits).
