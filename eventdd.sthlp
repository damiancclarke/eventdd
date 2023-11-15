{smcl}
{* *! version 4.0 November 15, 2023}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "eventdd##syntax"}{...}
{viewerjumpto "Description" "eventdd##description"}{...}
{viewerjumpto "Options" "eventdd##options"}{...}
{viewerjumpto "Remarks" "eventdd##remarks"}{...}
{viewerjumpto "Examples" "eventdd##examples"}{...}
{title:Title}
{phang}
{bf:eventdd} {hline 2} Estimate panel event study models and generate event study plots

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:eventdd}
{depvar} [{indepvars}]
{ifin}
{weight}{cmd:,}
{it:timevar(varname)}
[{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt timevar(varname)}}  Specifies the standardized time variable relative to the event of interest. This is required.
{p_end}
{synopt:{opt over(varname)}}  Indicates that multiple event studies should be estimated and plotted, where a separate event study is plotted over each level
of the variable indicated.  The indicated variable must be discrete, but can take greater than two levels. Resulting graphs will be combined in a single plot.
{p_end}
{synopt:{opt ci(type, ...)}}  Specifies the type of graph for confidence intervals: {cmd:rarea} (with area shading),
{cmd:rcap} (with capped spikes) or {cmd:rline} (with lines), and also the graphing options: {help twoway_rarea:twoway rarea} for {cmd:rarea} (eg area), {help twoway_rcap:twoway rcap} 
for {cmd:rcap} (eg line) or {help twoway_rline:twoway rline} for {cmd:rline} (eg connect) which should be passed to the resulting event study graph. {cmd:rcap} is the default graph type.
If multiple event studies are produced using the {cmd:over()} option, and separate options are desired
for each set of confidence intervals on each event study
this can be requested using g1(), g2(), and so forth to pass options, with values corresponding to orderd levels of the variable indicated in the {cmd:over()} option.  
{p_end}
{synopt:{opt jitter(#)}}  Only for use if {cmd:over()} is specified.  Allows for each event study to be slightly shifted on
graphical output to avoid super-imposition.  Scalar value indicated in jitter indicates the distance on the horizontal axis to shift each event study.
{p_end}
{synopt:{opt baseline(#)}}  Specifies the baseline period relative to the moment of the event of interest; the default is -1.
{p_end}
{synopt:{opt level(#)}} Set confidence {help level}; default is level(95).
{p_end}
{synopt:{opt accum}}  Accumulates periods beyond indicated leads and lags into a final coefficient/confidence interval.
{p_end}
{synopt:{opt leads(#)}}  Specifies the number of leads which should be included. This is required when specifying the {cmd:accum}, {cmd:keepbal} or {cmd:inrange} options, otherwise all possible lags will be plotted.
{p_end}
{synopt:{opt lags(#)}}  Specifies the number of lags which should be included. This is required when specifying the {cmd:accum}, {cmd:keepbal} or {cmd:inrange} options, otherwise all possible lags will be plotted.
{p_end}
{synopt:{opt noend}}  Requests that end points are suppressed from graphs. This is only available if specifying the {cmd:accum} option.
{p_end}
{synopt:{opt keepbal(varname)}}  Indicates that only units which are balanced in the panel should be kept, where {it:varname} indicates the panel variable (eg state).
{p_end}
{synopt:{opt method(type, [absorb(absvars)] * ...)}}  Specifies the estimation method: {cmd:ols} (with Stata's {help regress} command), {cmd:fe} (with Stata's {help xtreg}, fe command) or {cmd:hdfe} (with the user-written {help reghdfe} command), 
and also any additional {help estimation options} and {help vce_option:vce options} which should be passed to the event study model, (eg robust or clustered sandwich estimator of variance). The {cmd:absorb(absvars)} sub-option is only required when specifying the {cmd:hdfe} option. {opt ols} is the default estimation method. 
{p_end}
{synopt:{opt wboot}} Requests that confidence intervals be estimated by wild bootstrap. This requires the user-written {help boottest} command.  This may not be combined with the {cmd:hdfe} option.
{p_end}
{synopt:{opt wboot_op(string)}} Specifies any options for wild bootstrap estimation, (eg seed(), bootcluster()).  These will be passed to the {help boottest} command. In the case of using the {help level} option, this should only be specified in the main command syntax. {help nograph} option is already specified.
{p_end}
{synopt:{opt balanced}}  Requests that only balanced periods in which all units have data be shown in the plot.
{p_end}
{synopt:{opt inrange}}  Requests that only specified periods in leads and lags be shown in the plot.
{p_end}
{synopt:{opt noline}}  Requests that line at -1 on the x-axis is suppressed from graphs.
{p_end}
{synopt:{opt graph_op(string)}}  Specifies any general options in {help twoway_options:twoway options} which should be passed to the resulting event study graph, (eg title, axis, labels, legends).
{p_end}
{synopt:{opt coef_op(string)}}  Specifies any options for coefficients in {help scatter} which should be passed to the resulting event study graph, (eg marker).
If multiple event studies are produced using the {cmd:over()} option, and separate options are desired
for each set of coefficients on each event study
this can be requested using g1(), g2(), and so forth to pass options, with values corresponding to orderd levels of the variable indicated in the {cmd:over()} option.  
{p_end}
{synopt:{opt endpoints_op(string)}}  Specifies any options for end points coefficients in {help scatter} which should be passed to the resulting event study graph, (eg marker). This is only available if specifying the {cmd:accum} option.
{p_end}
{synopt:{opt keepdummies}}  Generate dummies of leads and lags. Required save the data before using or data in memory would be lost. This option is necessary to perform joint significance tests using wild or score bootstrap
with the postestimation commands.
{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}The regression variables specified as {indepvars} may contain
{help tsvarlist:time-series operators} and {help fvvarlist:factor variables}.{p_end}
{p 4 6 2}This command requires the user-written ado matsort available from the SSC.{p_end}

 

{marker description}{...}
{title:Description}
{pstd}

{pstd}
 {cmd:eventdd} estimates a panel event study corresponding to a difference-in-difference style model
 where a series of lag and lead coefficients and confidence intervals are estimated and plotted.
 These lag and lead coefficients are all relative to the passage of an event of interest, which can
 occur at different moments in different units of the panel.  The estimated model is of the general
 format:

{p 8 12 2}y_st = Alpha + {bind:Lead^K_st * BetaK} + ... + {bind:Lead^2_st * Beta2} + {bind:Lag^0_st * gamma0} + ... {bind:Lag^L_st * gammaL} + mu_s + lambda_t + u_st      (1)

{pstd}
 where {it: y_st} is an outcome of interest for state {it: s} and time {it: t}, and a series of K
 Leads and L Lags are considered relative to the event of interest.  Fixed effects for state and
 time are included as {it: mu_s} and {it: lambda_t} respectively. 
 
{pstd}
The command requires that the basic model be specified without leads and lags, and a variable
should be indicated in {cmd: timevar()} which defines the standardized version of the time until
the event, with missing values for units in which the event never occurs (pure control units).
 The command generates the estimation results and a graph documenting the coefficients and confidence
 intervals on all indicated leads and lags.  By default, the command uses as a baseline time period
 -1 (one year prior to the event of interest) and estimates event study models using Stata's
 {help regress} command.  However the command can also specify that estimation should proceed
 using {help xtreg} or {help reghdfe} (if installed).  Similarly, if specified, inference in
 eventdd can be based on wild bootstrapped confidence intervals using the {help boottest} command
 (if installed).

{pstd}
 {cmd:eventdd} provides a useful check of parallel {it: pre}-trends in the context of a
 difference-in-differences (DD) estimator.  Broader discussion of these models are provided in
 Angrist and Pischke (2009, section 5.2), Freyaldenhoven et al,. (2019), and Goodman-Bacon
 (2018) (among many other references).  The paper by Clarke and Tapia (2021) accompanies this
 command.  Examples of use are given in the "Examples" section below, as well as in Clarke
 and Tapia (2021).

{pstd}

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt timevar(varname)} is a required option. The time variable specified should contain a standardized
 value, where 0 corresponds to the time period in which the event of interest occurs for a given unit,
 -1 refers to one year prior to the event, 1 refers to one year following the event, and so forth.
 The timevar specified must increase sequentially from the longest lead (K) to the longest lag (L),
 with at least some observations covering each time period in between.  If this is not the case,
 the timevar can be restandardized so this is the case, or the {opt accum} option can be used to
 limit leads and lags beyond certain points.
 For any units in which the event does not occur (pure controls), this variable should contain missing
 values. 

{pstd}
{p_end}
{phang}
{opt over(varname)}  Allows for the estimation and plotting of multiple event studies on a
single plot. Event studies are estimated separately and plotted for each level of the variable
indicated in {cmd:over()}.  This variable must be categorical, but can take more than two levels,
and event studies will be plotted for each level.  Output for each model will be provided, and
graphical results are combined on a single plot.

{pstd}
{p_end}
{phang}
{opt ci(type, ...)}  Specifies the type of graph for the confidence intervals. The types available are {cmd:rarea} for an interval with area shading (see {help twoway_rarea:twoway rarea}), 
{cmd:rcap} for an interval with capped spikes (see {help twoway_rcap:twoway rcap}) and {cmd:rline} for an interval with lines (see {help twoway_rline:twoway rline}). Only one type can be specified and all intervals will be the same type. 
The appearance can be modified with the inclusion of any graphing option for the confidence intervals permitted in {help twoway_rarea:rarea}, 
{help twoway_rcap:rcap} or {help twoway_rline:rline} depending on the type of CI indicated; including {help area_options:area options}, 
{help line_options:line options} and {help connect_options:connect options}, respectively.  This does not allow the use of the general options such as titles and legends, which should be specified in the {cmd:graph_op()} option. If not specified, 
a standard {cmd:rcap} graphical output will be provided. 
If {cmd:over()} has been specified, options for separate confidence intervals for each graph can be
passed using {cmd:g1()}, {cmd:g2()} and so forth.  For example, if separate colours are desired for
two event studies over a variable specified in {cmd:over()} this can be achieve with: ci(rarea, g1(color(gs12%30)) g2(color(gs12%50)))

{pstd}
{p_end}
{phang}
{opt jitter(#)}  Allows for event studies to be slightly shifted on the horizontal axis when multiple
models are presented in a single plot.  All coefficients and confidence intervals will be shifted by
the units indicated.  This option should only be used in combination with {cmd:over()}.

{pstd}
{p_end}
{phang}
{opt baseline(#)}  Specifies the reference period for the event study, which is a baseline omitted category to which all other periods should be compared in the event study output.  By default this value is set at -1.

{pstd}
{p_end}
{phang}
{opt level(#)}  Specifies the confidence level, as a percentage, for confidence intervals.  The default is level(95) or as set by set level.  This sets the levels for confidence intervals in regression output, as well as the event study plot and returned matrices.  
This will also be passed to {help boottest} if wild clustered confidence intervals are requested.

{pstd}
{p_end}
{phang}
{opt accum} Specifies that all periods beyond some specified values should be accumulated into final points.  For example if {opt accum} is specified and {opt leads(#)} and {opt lags(#)} are both set equal to 10, 
a single coefficient will be displayed in regressions 
and graphical output capturing 10 or more periods prior/post reform.  If {opt accum} is not specified, all possible leads and lags will be included in models and graphical output.

{pstd}
{p_end}
{phang}
{opt leads(#)}  Indicates the maximum amount of post-event periods to consider in the event study.  This must be specified if either {cmd:accum}, {cmd:keepbal} or {cmd:inrange} are also specified.  Only integer values are permitted. 

{pstd}
{p_end}
{phang}
{opt lags(#)}  Indicates the maximum amount of pre-event periods to consider in the event study.  This must be specified if either {cmd:accum}, {cmd:keepbal} or {cmd:inrange} are also specified.  Only integer values are permitted.

{pstd}
{p_end}
{phang}
{opt noend}  Requests that accumulative end points are not shown on graphical output when the {opt accum} option is specified.

{pstd}
{p_end}
{phang}
{opt keepbal(varname)}  Specifies that only units which are balanced in the panel should be kept for estimation.  Here {it:varname} indicates the panel variable (eg state) which indicates units.
In this case "balance" refers to balance over calendar time.   An alternative option ({opt balanced}),
discussed below, allows for only balanced leads and lags {it:relative} to treatment to be considered in graphical output.

{pstd}
{p_end}
{phang}
{opt method(type, [absorb(absvars)] * ...)} Specifies the method of estimation for the event study model underlying graphical output. {opt ols} requests that the model should be estimated by OLS using Stata's {help regress} command, 
{opt fe} requests that the model should be estimated by fixed-effects (within) estimation, using Stata's {help xtreg}, fe command, and {opt hdfe} requests that the model should be estimated using the user-written {help reghdfe} command (if installed). 
{opt *} represents any other {help estimation options} included and permitted by {cmd:regress}, {cmd:xtreg}, or {cmd:reghdfe} that will be passed to the specified estimation command. This allows for the inclusion of clustered standard errors or other variance estimators (see {help vce_option:vce options}).
For {opt ols}, unit-specific fixed effects and time-specific fixed effects must be included in the {indepvars} indicated in the command syntax.  For {opt fe} unit-specific fixed effects {it: should not} be included in the {indepvars} indicated but time-specific fixed effects still need to be.  
Finally, for {opt hdfe} the {opt absorb(absvars)} option should also be specified to indicate which fixed effects should be controlled in the regression (refer to {help reghdfe} (if installed) for additional details) and any fixed effects
indicated in {opt absorb(absvars)} should not be included in 
the {indepvars} indicated. {opt hdfe} cannot be used in combination with the {opt wboot} option. {opt ols} is the default estimation method.

{pstd}
{p_end}
{phang}
{opt wboot}  Indicates that inference in the event study plot produced by the command should be
based on wild cluster bootstrapped confidence intervals.  This requires the user-written {help boottest}
command (if installed).  This option may not be combined with the {cmd:hdfe} estimation option.

{pstd}
{p_end}
{phang}
{opt wboot_op(string)}  Allows for the inclusion of any other wild bootstrap option permitted in {help boottest},
including {cmd:seed(}#{cmd:)} to set the seed for simulation based calculations and replicate the confidence intervals, 
and {opt bootclust(varname)} to specify which 
variable(s) to cluster the wild boostrap upon, among others. When setting the level (which is 95 by default), this
should be indicated in the {opt level} option of the command, and this will be passed to {opt wboot_op()}. {help nograph} option is already specified.

{pstd}
{p_end}
{phang}
{opt balanced}  Requests that only "balanced" leads and lags are plotted.  This will produce a
graph only showing leads and lags for which each treated unit has data, and as such, all
coefficients plotted will be based on all units in the data.  While only balanced leads and lags
will be plotted, all units and time periods will be included in the estimation of the event study.

{pstd}
{p_end}
{phang}
{opt inrange}  Requests that only the specified leads and lags are plotted.  While only leads and lags indicated
in {cmd: leads(#)} and {cmd:lags(#)} will be plotted, all units and time periods will be included in the estimation of the event study.

{pstd}
{p_end}
{phang}
{opt noline}  Requests that the line before the event on the x-axis is not shown on graphical output.

{pstd}
{p_end}
{phang}
{opt graph_op(string)}  Allows for the inclusion of any other general graphing option permitted in {help twoway_options}, 
including {help title_options}, {help added_lines_options}, {help axis_label_options}, among others.  This also allows 
for the use of alternative labels for graph axes. If not specified, a standard graphical output will be provided.

{pstd}
{p_end}
{phang}
{opt coef_op(string)}  Allows for the inclusion of any graphing option for the coefficients permitted in {help scatter} including 
{help marker_options}, {help marker_label_options}, among others. This does not allow the use of the general options of {cmd:graph_op()}. 
If not specified, a standard graphical output will be provided.
If {cmd:over()} has been specified, options for separate coefficients for each graph can be
passed using {cmd:g1()}, {cmd:g2()} and so forth.  For example, if separate symbols are desired for
two event studies over a variable specified in {cmd:over()} this can be achieve with: coef_op(g1(ms(Sh)) g2(ms(Oh)))

{pstd}
{p_end}
{phang}
{opt endpoints_op(string)}  Allows for the inclusion of any graphing option for the end points coefficients permitted in {help scatter} 
including {help marker_options}, {help marker_label_options}, among others. This is only available if specifying the {cmd:accum} option and 
does not allow the use of the general options of {cmd:graph_op()}. If not specified, a standard graphical output will be provided.

{pstd}
{p_end}
{phang}
{opt keepdummies}  Requests that the dummy variables of all leads and lags used in the estimation be included in the database.
Required save the data before using or data in memory would be lost. This option is necessary to perform joint significance tests using wild or score bootstrap with the postestimation commands. 


{pstd}
{p_end}

{marker examples}{...}
{title:Examples: single-event study}
{pstd}

{pstd}
Load data that replicates Stevenson and Wolfers' (2006) analysis of no-fault divorce reforms and female suicide, circulated with the {help bacondecomp} command.

{pstd}
 . {stata webuse set www.damianclarke.net/stata/}

{pstd}
 . {stata webuse bacon_example.dta, clear}

{pstd}
Estimate a baseline two-way fixed effect DD model of female suicide on no-fault divorce reforms.

{pstd}
 . {stata xtreg asmrs post pcinc asmrh cases i.year, fe cluster(stfips)}

{pstd}
Generate standarized event-time variable giving time until passage of event for each state

{pstd}
 . {stata gen timeToTreat = year - _nfd}

{pstd}
Generate the event study plot associated to DD model of female suicide on no-fault divorce reforms with all periods.

{pstd}
 . {stata eventdd asmrs pcinc asmrh cases i.year, timevar(timeToTreat) method(fe, cluster(stfips)) graph_op(ytitle("Suicides per 1m Women") xlabel(-20(5)25))}

{pstd}
Generate the event study plot associated to DD model of female suicide on no-fault divorce reforms with all periods but only showing balanced periods in plot.

{pstd}
 . {stata eventdd asmrs pcinc asmrh cases i.year, timevar(timeToTreat) method(fe, cluster(stfips)) balanced graph_op(ytitle("Suicides per 1m Women"))}

{pstd}
Generate the event study plot associated to DD model of female suicide on no-fault divorce reforms only using balanced observations in the specified period.

{pstd}
 . {stata eventdd asmrs pcinc asmrh cases i.year, timevar(timeToTreat) method(fe, cluster(stfips)) keepbal(stfips) leads(6) lags(14) graph_op(ytitle("Suicides per 1m Women"))}

{title:Examples: multiple event-studies}
{pstd}

{pstd}
Load data that replicates Bhalotra et al.'s (2023) analysis of the passage of parliamentary gender quotas on rates of maternal mortality.

{pstd}
 . {stata webuse set www.damianclarke.net/stata/}

{pstd}
 . {stata webuse quota_example.dta, clear}

{pstd}
Generate variables indicating GDP in bottom quartile, and year of quotar adoption.

{pstd}
 . {stata sum lngdp, d}

{pstd}
 . {stata gen GDPp25 = lngdp<r(p25)}

{pstd}
 . {stata gen timeToTreat = year-quotaYear}

{pstd}
Estimate event study stratifying by whether or not countries are in bottom quartile of GDP per capita.

{pstd}
 . {stata eventdd lnmmrt i.year, timevar(timeToTreat) method(hdfe, absorb(country) cluster(country)) lags(10) leads(10) accum over(GDPp25) jitter(0.2) graph_op(legend(pos(6) order(2 "GDP {&ge} 25p" 5 "GDP < 25p" 1 "95% CI") rows(1)))}
 



{title:Stored results}

{synoptset 15 tabbed}{...}

{cmd:eventdd} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars }{p_end}
{synopt:{cmd:e(baseline)}}baseline period specified{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}	  

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:eventdd}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(leads)}}all event leads, their lower bound, the point estimate, and their upper bound{p_end}
{synopt:{cmd:e(lags)}}all event lags, their lower bound, the point estimate, and their upper bound{p_end}
{synopt:{cmd:e(V_leads_lags)}}variance-covariance matrix of leads and lags estimators{p_end}

In the case that {cmd:over()} is specified and multiple event-studies are produced, instead of the matrices indicated above, a set of matrices named as below are returned, for each level # of the variable indicated on {cmd:over}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b_g#)}}coefficient vector{p_end}
{synopt:{cmd:e(V_g#)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(leads_g#)}}all event leads, their lower bound, the point estimate, and their upper bound{p_end}
{synopt:{cmd:e(lags_g#)}}all event lags, their lower bound, the point estimate, and their upper bound{p_end}
{synopt:{cmd:e(V_leads_lags_g#)}}variance-covariance matrix of leads and lags estimators{p_end}


{pstd}
{p_end}

{marker postestimation}{...}
{title:Postestimation commands}
{pstd}

The following postestimation commands are of special interest after {cmd:eventdd}: 

{synoptset 17}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
{synopt :estat leads}Joint significance test for leads{p_end}
{synopt :estat lags}Joint significance test for lags{p_end}
{synopt :estat eventdd}Joint significance test for leads and lags{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{pstd}
{p_end}

{synoptset 17}{...}
{p2coldent :Options}Description{p_end}
{synoptline}
{synopt :wboot}Joint significance test using {help boottest} command. Requires specifying the {cmd: keepdummies} option in {cmd: eventdd}. {cmd: nograph} option is already specified in {help boottest}.{p_end}
{synopt :*}Specifies any additional options which should be passed to the joint significance test. Options should be permitted by {help test} or {help boottest} (if specifying the {cmd: wboot} option).{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{pstd}
{p_end}

{title:Examples: post-estimation commands}

{pstd}
Load data and generate standarized event-time variable.

{pstd}
 . {stata webuse set www.damianclarke.net/stata/}
 
{pstd}
 . {stata webuse bacon_example.dta, clear}
 
{pstd}
 . {stata gen timeToTreat = year - _nfd}
 
{pstd}
 Save data in a temporary file before using {cmd: keepdummies} option (also can use {help save} command)
 
{pstd}
 . {stata tempfile example}

{pstd}
 . {stata save "`example'", replace}
 
{pstd}
 Generate the event study plot associated to DD model of female suicide on no-fault divorce reforms with all periods and {cmd: keepdummies} option.
 
{pstd}
 . {stata eventdd asmrs pcinc asmrh cases i.year, timevar(timeToTreat) method(fe, cluster(stfips)) keepdummies graph_op(ytitle("Suicides per 1m Women") xlabel(-20(5)25))}

{pstd}
 Test the joint significance for leads and lags.
 
{pstd}
 . {stata estat eventdd}

{pstd}
 Test the joint significance for leads and lags using wild bootstrap.
 
{pstd}
 . {stata estat eventdd, wboot seed(1303)}
 
{pstd}

{title:References}
{pstd}

{pstd}
Angrist, Joshua and Jörn-Steffen Pischke. 2009. "Mostly Harmless Econometrics: An Empiricist's Companion".
Princeton University Press.

{pstd}
Bhalotra, Sonia, Damian Clarke, Joseph Gomes and Atheendar Venkataramani. 2023. "Maternal Mortality and Women's Political Power".
Journal of the European Economic Association 21(5):2172–2208.

{pstd}
Clarke, Damian and Kathya Tapia. 2021. "Implementing the Panel Event Study".
Stata Journal 21(4):853–884.

{pstd}
Freyaldenhoven, Simon, Christian Hansen, and Jesse M. Shapiro. 2019. "Pre-event Trends in 
the Panel Event-Study Design". American Economic Review 109(9):3307-38.

{pstd}
Goodman-Bacon, Andrew. 2018. "Difference-in-Differences with Variation in Treatment Timing".
National Bureau of Economic Research Working Paper 25018.

{pstd}
Stevenson, Betsey and Justin Wolfers. 2006. "Bargaining in the Shadow of
the Law: Divorce Laws and Family Distress". The Quarterly Journal of
Economics 121(1):267-288.



{title:Author}
{p}

Damian Clarke, Universidad de Chile.
Email {browse "mailto:dclarke@fen.uchile.cl":dclarke@fen.uchile.cl}

Kathya Tapia, Universidad de Santiago de Chile.
Email {browse "mailto:kathya.tapia@usach.cl":kathya.tapia@usach.cl}



{title:See Also}
Related commands:

{help regress} 
{help xtset}
{help xtreg} 
{help reghdfe}  (if installed)   {stata ssc install reghdfe}  (to install this command)
{help boottest} (if installed)   {stata ssc install boottest} (to install this command)
{help matsort}  (if installed)   {stata ssc install matsort}  (to install this command)
{help twoway_options}
