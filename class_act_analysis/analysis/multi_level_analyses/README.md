# multi_level_analyses

Analysis, notebooks and reports for heirachichal or multi-level modelling approach, which attempts to account for in-group variance of repeated measures from schools that was not addressed in the initial analyses.

***Note**: These analyses have since been deemed to be flawed and should not be reported. In particular: 
* The approach analyses time-series data from schools with the assumption that each observation is independent - this is not the case. Significant autocorrelation is present in the observations and not properly accounted for within these models. 
* Several model variants with interaction effects are also tested, that do not make sense/are not justified by known effects of air filtration/covid infections/co2 concentrations. They are stored here for posterity and as a reference should any historic code be required.*

## Table of Contents

* [autocor_tests.ipynb](https://github.com/yhcr-samrelins/class_act_analysis/blob/main/analysis/multi_level_analyses/autocor_tests.ipynb) - experiments estimating the amount of auto-correlation in the multi-level/heirarchical models
* [multi_level_illness_model_write_up.pdf](https://github.com/yhcr-samrelins/class_act_analysis/blob/main/analysis/multi_level_analyses/multi_level_illness_model_write_up.pdf) - pdf report of the multi-level/heirarchichal analyses
* [multi_level_illness_model_write_up.Rmd](https://github.com/yhcr-samrelins/class_act_analysis/blob/main/analysis/multi_level_analyses/multi_level_illness_model_write_up.Rmd) - R-markdown report of the multi-level/heirarchichal analyses used to generate markdown and pdf documents
* [multi_level_illness_models_experiments.ipynb](https://github.com/yhcr-samrelins/class_act_analysis/blob/main/analysis/multi_level_analyses/multi_level_illness_models_experiments.ipynb) - Experiments with heirachichal/multi-level modelling to account for in-group variance of repeated measures from schools
* [plots_for_multi_level_write_up.ipynb](https://github.com/yhcr-samrelins/class_act_analysis/blob/main/analysis/multi_level_analyses/plots_for_multi_level_write_up.ipynb) - Script producing plots and descriptive statistics for report
##

