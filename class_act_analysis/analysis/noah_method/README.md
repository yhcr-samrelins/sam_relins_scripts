# noah_method

*Notebooks relating to "Noah method" of modeling difference in illness ratios between HEPA/Control schools with confidence intervals.*

Feedback on the intial drafts of the analysis/results highlighted a questionable statistic: a crude estimate of the difference in reported illness between HEPA and control schools. This difference was calculated by taking a simple percentage decrease in the estimated mean rate of illness between HEPA schools and control schools. This was not a robust figure, as it isn't possible to calculate a confidence interval for this difference given it is based on regression estimates of the mean illness ratios in the different "treatment" arms. The Noah method was developed as a means to robustly estimate this difference statistically, using a new regression model to estimate the mean/variace directly, allowing for the calcualtion of a confidence interval for the estimated difference. The method is so called, as it is developed from [this stats.stackexchange response authored by Noah Griefer](https://stats.stackexchange.com/questions/412558/determining-the-standard-error-of-a-ratio-of-means). 

## Table of Contents

* [ciaran_ci_example.Rmd](https://github.com/yhcr-samrelins/class_act_analysis/tree/main/analysis/noah_method/ciaran_ci_example.Rmd)
* [noah_method.ipynb](https://github.com/yhcr-samrelins/class_act_analysis/tree/main/analysis/noah_method/noah_method.ipynb)
##

