# initial_analysis

First round of descriptive analyses and modelling on the initial iterations of the Bradford attendance data. 

***Note:** Key issues are present in this analysis, and the results should not be reported. In particular:*
* *The data were later found to have errors and inconsistencies that were corrected, and so the descriptive statistics are not accurate*
* *Though visually appealing, the LOESS curves in Figure 3 are based on default settings for ggplot, and are a somewhat arbitrary smooth curve through the mean illness ratios by week. The curves are not based on an interpretable or statistically sound model, and so shouldn't be considered reliable when interpreting the effects of either of the ACTs, or the absence of ACTs.*
* *The logistic regression model uses weekly data and assumes all observations are independent of one another, which isn't the case. There are inter-school dependencies and autocorrelations between near-term observations that aren't accounted for and so the variance estimates from the model (CIs ect) are not accurate.*

*The scripts and reports are stored here for reference, should any code be required*

## Table of Contents

* [initial_analysis.pdf](https://github.com/yhcr-samrelins/class_act_analysis/blob/main/analysis/initial_analysis/initial_analysis.pdf) - script and documentation for the intial analysis of the effectiveness of ACTs in ClassAct schools
* [initial_analysis.Rmd](https://github.com/yhcr-samrelins/class_act_analysis/blob/main/analysis/initial_analysis/initial_analysis.Rmd) - pdf report of the initial analysis of the effectiveness of ACTs in ClassACT schools
##    
