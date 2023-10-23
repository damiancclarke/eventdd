![Stata](https://img.shields.io/badge/stata-2013-green) ![issues](https://img.shields.io/github/issues/damiancclarke/eventdd) ![issues close](https://img.shields.io/github/issues-closed/damiancclarke/eventdd) ![GitHub license](https://img.shields.io/github/license/damiancclarke/eventdd)

# eventdd &ndash; Estimate panel event study models and generate event study plots

**eventdd** is a Stata program which estimates panel event study models and generates event-study plots.  **eventdd** additionally includes a number of post-estimation procedures such as joint tests of significance of event lages and leads.  

Panel event study models seek to estimtate the impact of some policy or event adopted in certain groups and time periods, by comparing evolution of outcomes in adoption groups to groups which do not adopt the event.  Specifically, the panel event study is estimated as: 

```math
y_{gt}= \alpha + \sum_{j=2}^J\beta_j(Lead_j)_{gt} + \sum_{k=0}^K (Lag_k)_{gt} + \mu_g + \lambda_t + X_{gt}^\prime+\varepsilon_{gt}
``` 

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

## Syntax



## Examples

### Stevenson & Wolfers, No Fault Divorce and Suicides
```s
webuse set www.damianclarke.net/stata/
webuse bacon_example.dta, clear

gen timeToTreat = year - _nfd

eventdd asmrs pcinc asmrh cases i.year, timevar(timeToTreat) method(fe, cluster(stfips)) graph_op(ytitle("Suicides per 1m Women") xlabel(-20(5)25))
```

### Bhalotra et al., Reserved Seat Quota Adoption and Maternal Mortality 
```s
webuse set www.damianclarke.net/stata/
webuse quota_example.dta, clear

// Generate indicator for GDP in bottom quartile
sum lngdp, d
gen GDPp25 = lngdp<r(p25)

// Generate country-level register of year of quota adoption and time to adoption
bys country: egen minQ  = min(year) if quota==1
bys country: egen qyear = mean(minQ)
gen timeToTreat = year-qyear

// Event study examining impact of reserved seats on maternal mortality
eventdd lnmmrt i.year, timevar(timeToTreat) method(hdfe, absorb(country) cluster(country)) lags(10) leads(10) accum graph
```

<img src="https://github.com/damiancclarke/eventdd/blob/main/quotas.png" width="600" height="400"> 

```s
eventdd lnmmrt i.year, timevar(timeToTreat) method(hdfe, absorb(country) cluster(country)) lags(10) leads(10) accum over(GDPp25) jitter(0.2)  graph_op(legend(pos(6) order(2 "Point Estimate (GDP {&ge} 25 p)" 5 "Point Estimate (GDP < 25 p)" 1 "95% CI") rows(1))) coef_op(g1(ms(Sh)) g2(ms(Oh))) ci(rarea, g1(color(gs12%30)) g2(color(gs12%50))) 
```

<img src="https://github.com/damiancclarke/eventdd/blob/main/quotasByGDP.png" width="600" height="400"> 



### References
Damian Clarke and Kathya Tapia Schythe, "Implementing the Panel Event Study", Stata Journal 21(4):853–884 (2021).
