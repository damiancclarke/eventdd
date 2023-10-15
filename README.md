![Stata](https://img.shields.io/badge/stata-2013-green) ![issues](https://img.shields.io/github/issues/damiancclarke/eventdd) ![issues close](https://img.shields.io/github/issues-closed/damiancclarke/eventdd) ![GitHub license](https://img.shields.io/github/license/damiancclarke/eventdd)

# eventdd -- Estimate panel event study models and generate event study plots

**eventdd** is a Stata program which estimates panel event study models and generates event-study plots.  **eventdd** additionally includes a number of post-estimation procedures such as joint tests of significance of event lages and leads.  Panel event study models seek to estimtate the impact of some policy or event adopted in certain groups and time periods, by comparing evolution of outcomes in adoption groups to groups which do not adopt the event.  Specifically, the panel event study is estimated as:
$$y_{gt}= \alpha + \sum_{j=2}^J\beta_j(Lead_j)_{gt} + \sum_{k=0}^K (Lag_k)_gt + \mu_g + \lambda_t + X_{gt}^\prime+\varepsilon_{gt}$$
where $y_{gt}$ refers to outcomes for group $g$ and time period $t$... UNDER CONSTRUCTION


Some further details can be found in the accompanying Stata Journal paper [here](https://docs.iza.org/dp13524.pdf).

To install directly into Stata:
```s
ssc install eventdd, replace
```
or using ```net install``` command:
```s
net install sdid, from("https://raw.githubusercontent.com/damiancclarke/eventdd/master") replace
```


### References
Damian Clarke and Kathya Tapia Schythe, "Implementing the Panel Event Study", Stata Journal 21(4):853–884 (2021).
