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

eventdd asmrs pcinc asmrh cases i.year, timevar(timeToTreat) method(fe, cluster(stfips)) graph_op(ytitle("Suicides per 1m Women") xlabel(-15(5)15) legend(order(2 "Point Estimate" 1 "95% CI") pos(6) rows(1)))  lags(15) leads(15) accum


. eventdd asmrs pcinc asmrh cases i.year, timevar(timeToTreat) method(fe, cluster(stfips)) graph_op(ytitle("Suicides per 1m Women") xlabel(-15(5)15) legend(order(2 "Point Estimate" 1 "95% CI") pos(6) rows(1))) lags(15) leads(15) accum


Fixed-effects (within) regression               Number of obs     =      1,617
Group variable: stfips                          Number of groups  =         49

R-squared:                                      Obs per group:
     Within  = 0.3846                                         min =         33
     Between = 0.0002                                         avg =       33.0
     Overall = 0.1151                                         max =         33

                                                F(48, 48)         =          .
corr(u_i, Xb) = -0.2138                         Prob > F          =          .

                                (Std. err. adjusted for 49 clusters in stfips)
------------------------------------------------------------------------------
             |               Robust
       asmrs | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
       pcinc |  -.0010834   .0004016    -2.70   0.010    -.0018908   -.0002759
       asmrh |   1.148921   .5916515     1.94   0.058    -.0406743    2.338516
       cases |  -194.0857   134.5432    -1.44   0.156    -464.6029    76.43154
             |
        year |
       1965  |   5.953814   1.997673     2.98   0.005     1.937224    9.970405
       1966  |   3.654006   2.323974     1.57   0.122    -1.018658     8.32667
       1967  |    5.17208   2.304469     2.24   0.029     .5386341    9.805525
       1968  |   6.133335   2.455151     2.50   0.016     1.196924    11.06975
       1969  |   9.226593   3.110661     2.97   0.005     2.972189      15.481
       1970  |   11.25014   3.736967     3.01   0.004     3.736465    18.76382
       1971  |   18.10162   3.500476     5.17   0.000     11.06344    25.13979
       1972  |   14.55401   4.063154     3.58   0.001     6.384495    22.72353
       1973  |   16.59578   4.637619     3.58   0.001     7.271226    25.92034
       1974  |   17.45827   4.471475     3.90   0.000      8.46777    26.44878
       1975  |   20.93109   4.572276     4.58   0.000     11.73791    30.12427
       1976  |   17.23318   5.158467     3.34   0.002     6.861382    27.60497
       1977  |   19.26182   4.751529     4.05   0.000     9.708227     28.8154
       1978  |   15.95673   5.233447     3.05   0.004     5.434177    26.47928
       1979  |   14.37324   5.869618     2.45   0.018     2.571583     26.1749
       1980  |   11.58301    5.18697     2.23   0.030     1.153912    22.01212
       1981  |   14.28482   5.707315     2.50   0.016     2.809492    25.76014
       1982  |   11.28251   4.998155     2.26   0.029     1.233043    21.33197
       1983  |   10.74783    5.47755     1.96   0.056    -.2655208    21.76118
       1984  |   13.66639   5.721671     2.39   0.021     2.162195    25.17058
       1985  |   9.867876   6.168195     1.60   0.116    -2.534111    22.26986
       1986  |   15.17414   6.102758     2.49   0.016     2.903725    27.44456
       1987  |   16.46542   5.954447     2.77   0.008     4.493206    28.43764
       1988  |   14.22775   6.457503     2.20   0.032     1.244072    27.21143
       1989  |   13.51503   7.118574     1.90   0.064    -.7978169    27.82789
       1990  |   14.33783   6.929579     2.07   0.044     .4049788    28.27068
       1991  |   13.33514   6.816121     1.96   0.056    -.3695851    27.03987
       1992  |   12.48164   7.135318     1.75   0.087    -1.864873    26.82816
       1993  |   15.18881   7.411584     2.05   0.046     .2868251     30.0908
       1994  |   14.51899   7.469569     1.94   0.058    -.4995817    29.53757
       1995  |   12.96002   7.679496     1.69   0.098    -2.480639    28.40068
       1996  |   13.29211   7.955388     1.67   0.101     -2.70327    29.28749
             |
      lead15 |  -2.635591    4.28278    -0.62   0.541     -11.2467    5.975515
      lead14 |   4.119924   5.294739     0.78   0.440    -6.525863    14.76571
      lead13 |  -1.219058   4.859393    -0.25   0.803    -10.98952    8.551405
      lead12 |  -.1276021   6.852116    -0.02   0.985    -13.90471     13.6495
      lead11 |  -9.485776   4.018745    -2.36   0.022      -17.566   -1.405548
      lead10 |  -1.133975   4.904681    -0.23   0.818     -10.9955    8.727548
       lead9 |  -4.792218   3.658702    -1.31   0.196    -12.14853    2.564096
       lead8 |   -2.81221   3.937852    -0.71   0.479    -10.72979    5.105373
       lead7 |  -1.248013   4.360872    -0.29   0.776    -10.01613    7.520109
       lead6 |  -.7797544   2.980252    -0.26   0.795    -6.771954    5.212445
       lead5 |  -2.814077   2.615867    -1.08   0.287     -8.07363    2.445477
       lead4 |   .1759406   2.393439     0.07   0.942    -4.636391    4.988273
       lead3 |  -2.355844   2.951173    -0.80   0.429    -8.289574    3.577887
       lead2 |  -.5340147   2.507715    -0.21   0.832    -5.576115    4.508085
        lag0 |    .276763    2.71115     0.10   0.919    -5.174369    5.727895
        lag1 |  -1.616236   2.923493    -0.55   0.583    -7.494312     4.26184
        lag2 |  -1.692049   3.877192    -0.44   0.664    -9.487667    6.103568
        lag3 |  -.7508698   2.841648    -0.26   0.793    -6.464387    4.962647
        lag4 |  -2.960066   2.824574    -1.05   0.300    -8.639253     2.71912
        lag5 |   -2.38612   2.754708    -0.87   0.391    -7.924831     3.15259
        lag6 |  -3.297617   3.565538    -0.92   0.360    -10.46661    3.871378
        lag7 |  -5.131507   3.416243    -1.50   0.140    -12.00032    1.737311
        lag8 |  -6.981646   3.095878    -2.26   0.029    -13.20633   -.7569651
        lag9 |  -4.833179    3.09219    -1.56   0.125    -11.05044    1.384086
       lag10 |  -8.824309   3.682567    -2.40   0.021    -16.22861   -1.420012
       lag11 |  -7.337769   3.631075    -2.02   0.049    -14.63853   -.0370029
       lag12 |  -6.305412   4.066619    -1.55   0.128     -14.4819    1.871073
       lag13 |  -8.520276   3.951522    -2.16   0.036    -16.46534   -.5752084
       lag14 |  -6.850119   3.860921    -1.77   0.082    -14.61302    .9127823
       lag15 |  -9.341169   4.086061    -2.29   0.027    -17.55675   -1.125592
       _cons |   72.02055   7.006356    10.28   0.000     57.93332    86.10777
-------------+----------------------------------------------------------------
     sigma_u |  15.758038
     sigma_e |  10.797527
         rho |   .6804992   (fraction of variance due to u_i)
------------------------------------------------------------------------------

```

<img src="https://github.com/damiancclarke/eventdd/blob/main/StevensonWolfers.png" width="600" height="400"> 

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
}
```
> Clarke, D., & Tapia-Schythe, K. (2021). Implementing the panel event study. The Stata Journal, 21(4), 853-884. https://doi.org/10.1177/1536867X211063144



## References
<a id="1">Sonia Bhalotra, Damian Clarke, Joseph Gomes and Atheendar Venkataramani</a>, "*Maternal Mortality and Women's Political Power*", Journal of the European Economic Association 21(5):2172–2208 (2023).  
<a id="2">Damian Clarke and Kathya Tapia Schythe</a>, "*Implementing the Panel Event Study*", Stata Journal 21(4):853–884 (2021).  
<a id="3">Sergio Correia</a> "*Linear Models with High-Dimensional Fixed Effects: An Efficient and Feasible Estimator*" Working Paper. http://scorreia.com/research/hdfe.pdf (2017).  
<a id="4">Betsey Stevenson and Justin Wolfers</a>, "*Bargaining in the Shadow of the Law: Divorce Laws and Family Distress*", The Quarterly Journal of Economics, 121(1):267-288 (2006).  
<a id="5">David Roodman, Morten Nielsen, James MacKinnon and Matthew Webb</a> "*Fast and wild: Bootstrap inference in Stata using boottest*", The Stata Journal, 19(1),4-60 (2019).  
