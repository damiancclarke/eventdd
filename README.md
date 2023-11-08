![Stata](https://img.shields.io/badge/stata-2013-green) 
![issues](https://img.shields.io/github/issues/damiancclarke/eventdd) 
![issues close](https://img.shields.io/github/issues-closed/damiancclarke/eventdd) 
![GitHub license](https://img.shields.io/github/license/damiancclarke/eventdd)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/damiancclarke/eventdd?label=last%20version)
![GitHub Release Date](https://img.shields.io/github/release-date/damiancclarke/eventdd)
![GitHub commits since latest release (by date)](https://img.shields.io/github/commits-since/damiancclarke/eventdd/latest)


# eventdd &ndash; Estimate panel event study models and generate event study plots

**eventdd** is a Stata program which estimates panel event study models and generates event-study plots.  **eventdd** additionally includes a number of post-estimation procedures such as joint tests of significance of event lages and leads.  

Panel event study models seek to estimtate the impact of some policy or event adopted in certain groups and time periods, by comparing evolution of outcomes in adoption groups to groups which do not adopt the event.  Specifically, the panel event study is estimated as: 

```math
y_{gt}= \alpha + \sum_{j=2}^J\beta_j(Lead_j)_{gt} + \sum_{k=0}^K (Lag_k)_{gt} + \mu_g + \lambda_t + X_{gt}^\prime+\varepsilon_{gt}
``` 

where $y_{gt}$ refers to outcomes for group $g$ and time period $t$, $\mu_g$ and $\lambda_t$ refer to group and time-fixed effects respectively, and, optionally, $X_{gt}$ refers to time-varying controls.  Lags and leads refer to indicators for periods pre- and post-event occurrence, and are defined as follows:
```math
(Lead\ J)_{gt}= \mathbb{1}[t\leq Event_g-J]                    
```
```math
(Lead\ j)_{gt}= \mathbb{1}[t = Event_g-j] \text{ for } j\in\{2,\ldots,J-1\} 
```
```math
(Lag\ k)_{gt}= \mathbb{1}[t = Event_g+k] \text{ for } k\in\{0,\ldots,K-1\} 
```
```math
(Lead\ K)_{gt}= \mathbb{1}[t\leq Event_g+K]
```
where $\mathbb{1}$ is the indicator function, indicating that observations take 1 if $\mathbb{1}(\cdot)$ is true, and zero otherwise.  Leads and lags are thus binary variables indicating that the given group was a given number of periods away from the event of interest in the respective time period. $J$ and $K$ leads and lags are included respectively leads and lags "accumulate" leads or lags beyond $J$ and $K$ periods. A single lead or lag variable is omitted to capture the baseline difference between groups where the event does and does not occur. In the specification above, as standard, this baseline omitted case is the first lead (one period prior to the reform), where $j = 1$.

**eventdd** permits a range of estimation procedures such as regression (`regress`) with fixed effects manually indicated, `xtreg`, and `reghdfe` [(Correia, 2017)](#3), as well as a range of inference procedures.  Standard errors should be clustered by group, but if a small number of groups is present, wild cluster bootstrap should be preferred.  This is available via the `boottest` command [(Roodman et al., 2019)](#5).  Event study models can also be estimated over some other variable, which presents two (or more) event studies on a single plot.  Examples of usage are provided below.

Further details can be found in the accompanying Stata Journal paper [(Clarke & Tapia-Schythe, 2021)](#2) [here](https://journals.sagepub.com/doi/full/10.1177/1536867X211063144), or a pre-print version, available [here](https://www.damianclarke.net/research/papers/panelEvent.pdf).  Full details of the command are documented in this paper and the help file available with this command.  An overview of syntax is available below, but please refer to the Stata Journal paper or the help file for full details including returned elements and supported post-estimation tests.

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

### [Stevenson & Wolfers (2006)](#4), No Fault Divorce and Suicides
```s
webuse set www.damianclarke.net/stata/
webuse bacon_example.dta, clear

gen timeToTreat = year - _nfd

eventdd asmrs pcinc asmrh cases i.year, timevar(timeToTreat) method(fe, cluster(stfips)) graph_op(ytitle("Suicides per 1m Women") xlabel(-20(5)25))
```

### [Bhalotra et al. (2023)](#1) Reserved Seat Quota Adoption and Maternal Mortality 
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

## Citation

If you use **eventdd** and would like to cite it, please cite either the paper and/or the command's [RePEc citation](https://ideas.repec.org/c/boc/bocode/s458737.html).  BiBTeX citations for the paper are 

```bibtex

@article{ClarkeTapiaSchythe2021,
  author = {Damian Clarke and Kathya Tapia-Schythe},
  title ={Implementing the panel event study},
  journal = {The Stata Journal},
  volume = {21},
  number = {4},
  pages = {853-884},
  year = {2021},
  doi = {10.1177/1536867X211063144},
entdd’s use and flexibility, as well as its interaction with various native Stata commands, and other relevant community-contributed commands such as reghdfe and boottest. }
}
```
> Clarke, D., & Tapia-Schythe, K. (2021). Implementing the panel event study. The Stata Journal, 21(4), 853-884. https://doi.org/10.1177/1536867X211063144



## References
<a id="1">Sonia Bhalotra, Damian Clarke, Joseph Gomes and Atheendar Venkataramani</a>, "*Maternal Mortality and Women's Political Power*", Journal of the European Economic Association 21(5):2172–2208 (2023).  
<a id="2">Damian Clarke and Kathya Tapia Schythe</a>, "*Implementing the Panel Event Study*", Stata Journal 21(4):853–884 (2021).  
<a id="3">Sergio Correia</a> "*Linear Models with High-Dimensional Fixed Effects: An Efficient and Feasible Estimator*" Working Paper. http://scorreia.com/research/hdfe.pdf (2017).  
<a id="4">Betsey Stevenson and Justin Wolfers</a>, "*Bargaining in the Shadow of the Law: Divorce Laws and Family Distress*", The Quarterly Journal of Economics, 121(1):267-288 (2006).  
<a id="5">David Roodman, Morten Nielsen, James MacKinnon and Matthew Webb</a> "*Fast and wild: Bootstrap inference in Stata using boottest*", The Stata Journal, 19(1),4-60 (2019).  
