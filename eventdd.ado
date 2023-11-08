*! eventdd: Estimate panel event study models and generate plots
*! Version 4.0.0 October 08, 2023 @ 11:15:11 
*! Author: Damian Clarke & Kathya Tapia-Schythe 

cap program drop eventdd3
program eventdd3, eclass
vers 13.0

*-------------------------------------------------------------------------------
*--- (1) Syntax definition and set-up
*-------------------------------------------------------------------------------

#delimit ;
syntax varlist(min=1 fv ts numeric) [if] [in] [pw fw aw iw],
timevar(varname)        /*Standardized time variable*/
  [
  baseline(integer -1)  /*Reference period*/
  ci(string asis)       /*Type of CI, rarea, rcap or rline, and graphing options -> ci(type, ci_opts)*/
  noline	        	/*No line in t=-1*/
  accum                 /*Accumulate time in final leads and lags*/
  noend                 /*Don't plot end points with accum*/
  keepbal(varname)      /*Use only units balanced in all leads and lags*/
  lags(integer 0)       /*Number of lags to display with accum*/
  leads(integer 0)      /*Number of leads to display with accum*/
  method(string)        /*Type of estimation: OLS (default), FE or HDFE -> method(type, [absorb() *])*/
  wboot		        	/*Wild bootstrap standard errors*/
  wboot_op(string)      /*Options for boottest*/
  balanced              /*Use a balanced panel in all leads/lags selected*/
  inrange	        	/*Show periods between leads and lags*/
  graph_op(string asis) /*General graphing options: titles, subtitle, scheme, note, label */
  coef_op(string asis)  /*Coef (scatter) graphing options*/
  endpoints_op(string asis)  /*Endpoints (scatter) graphing options*/
  keepdummies           /*Generate dummies of leads and lags*/ 
  
  over(varlist max=1)   /*Create plots by categories*/
  jitter(real 0)        /*Jitter the groups' CIs*/
  
  *UNDOCUMENTED OPTIONS TO MAINTAIN BACKWARDS COMPATABILITY
  ci_op(string asis)    /*CI (rcap/rarea/line) graphing options*/
  ols fe hdfe           /*Type of FE estimation: FE, HDFE (default: OLS)*/
  absorb(passthru)      /*Only to be used where hdfe is specified*/
  *                     /*Other regression options*/
  ];
#delimit cr

preserve 

local wt [`weight' `exp']

if ("`over'"=="") {
local jitter
}

*UNDOCUMENTED OPTIONS TO MAINTAIN BACKWARDS COMPATABILITY
local ci_op_old `ci_op'
if ("`fe'"=="fe")== 1{ 
    local method_old fe  
}
else if ("`hdfe'"=="hdfe") == 1{
    local method_old hdfe 
}
else {
    local method_old ols 
}
local absorb_old  `absorb'
local options_old `options'


local changed=`c(changed)'
if ("`e(keepdummies)'"=="keepdummies")==1{
    qui use `c(filename)', clear
}

if strmatch("`varlist'", "*lead*")==0 { 
    capture drop lead*
}

if strmatch("`varlist'", "*lag*")==0 { 
    capture drop lag*
}

local varlist2
foreach var of local varlist{
    if strmatch("`var'", "lag*")+ strmatch("`var'", "lead*")>0 { 
        rename `var' _`var'
        local varlist2 `varlist2' _`var'
    }
    else{
        local varlist2 `varlist2' `var'
    } 
}
capture drop lag* 
capture drop lead*

rename `timevar' _Ptime
local tvar _Ptime

* "over" variable
if ("`over'"!="") {
 cap confirm string variable `over'
 if !_rc {
  local over_var `over'
  qui levelsof `over', local(str_groups)
  encode `over', gen(ov_num)
  drop `over'
  rename ov_num `over'
 }
 else {
  local over_var `over'
  qui levelsof `over', local(str_groups)
 }
}

*-------------------------------------------------------------------------------
*--- (2) General syntax consistency check
*-------------------------------------------------------------------------------
*OLD OPTIONS
if ("`ols'"!="") + ("`fe'"!="") + ("`hdfe'"!="") >1 { 
    di as err "choose only one of {bf:ols}, {bf:fe}, or {bf:hdfe}"
    exit 198 
}
if ("`hdfe'"!="") + ("`wboot'"!="")  >1 { 
    di as err "{bf:hdfe} may not be combined with {bf:wboot}"
    exit 198 
}

_WhIch_MetHOd `method'
local method  `s(meth)'
local absorb  `s(abs)'
local options `s(opts)'

if ("`method'"=="hdfe") + ("`wboot'"=="wboot") > 1 { 
    di as err "{bf:hdfe} may not be combined with {bf:wboot}"
    exit 198 
}
if ("`accum'"!="") + ("`balanced'"!="") > 1 { 
    di as err "choose only one of {bf:accum} or {bf:balanced}"
    exit 198 
}
if ("`accum'"=="") + ("`end'"!="") > 1 { 
    di as err "option {bf:end} requires {bf:accum}"
    exit 198 
}
if ("`accum'"!="") + ("`keepbal'"!="") > 1 { 
    di as err "choose only one of {bf:accum} or {bf:keepbal}" 
    exit 198 
}
if ("`balanced'"!="") + ("`keepbal'"!="") > 1 { 
    di as err "choose only one of {bf:balanced} or {bf:keepbal}" 
    exit 198 
}
if ("`inrange'"!="") + ("`keepbal'"!="") > 1 { 
    di as err "choose only one of {bf:inrange} or {bf:keepbal}" 
    exit 198 
}

if ("`balanced'"!="") + ("`inrange'"!="") > 1 { 
    di as err "choose only one of {bf:balanced} or {bf:inrange}" 
    exit 198 
}
if ("`accum'"!="") + ("`inrange'"!="") > 1 { 
    di as err "choose only one of {bf:accum} or {bf:inrange}"
    exit 198 
}
		
qui sum `tvar'
local min  = r(min)
local max  = r(max)
if `baseline' < `min' | `baseline' > `max' { 
    di as err "{bf:baseline} not found"
    exit 198 
}

local er1 "Options {bf:leads()} and {bf:lags()} require"
if ("`lags'"!= "0")&("`accum'"=="")&("`keepbal'"=="")&("`inrange'"=="")==1 {
    di as err "`er1' {bf:accum}, {bf:keepbal}  or {bf:inrange}"
    exit 198
}
if ("`leads'"!="0")&("`accum'"=="")&("`keepbal'"=="")&("`inrange'"=="")==1 {
    di as err "`er1' {bf:accum}, {bf:keepbal} or {bf:inrange}"
    exit 198
}
	
if ("`accum'" != "" ) + ("`keepbal'" != "") + ("`inrange'" != "") ==1 {
    if ("`lags'" == "0" ) ==  1 {
        di as err "options {bf:leads()} and {bf:lags()} required"
        exit 198
    }
    if ("`leads'" == "0" ) == 1 {
	di as err "options {bf:leads()} and {bf:lags()} required"
	exit 198
    }
    if  `min' > -`leads' { 
	di as err "{bf:lead} not found"
	exit 198 
    }
    if `max' < `lags' { 
	di as err "{bf:lag} not found"
	exit 198 
    }
    if `baseline' < -`leads' | `baseline' > `lags' { 
	di as err "{bf:baseline} is not between {bf:leads} and {bf:lags}"
	exit 198 
    }
}

if ("`endpoints_op'" != "" ) & ("`accum'" == "" )==1 {
    di as err "options {bf:endpoints_op} require {bf:accum}"
    exit 198
}

if ("`over'"=="") + ("`jitter'"!="") > 1 { 
    di as err "option {bf:jitter()} requires {bf:over()}"
    exit 198 
}

if ("`over'"!="") {
if `jitter' < 0 | `jitter' >= 1 { 
	di as err "{bf:jitter} is not between {bf:[0,1)}"
	exit 198 
    }
}

local citest=0
foreach gopt in "*rarea*" "*rcap*" "*rline*" {
    if strmatch(`"`endpoints_op'"',"`gopt'")!=0 local ++citest
    if strmatch(`"`coef_op'"',"`gopt'")!=0      local ++citest    
    if strmatch(`"`graph_op'"',"`gopt'")!=0     local ++citest   
    if strmatch(`"`ci_op'"',"`gopt'")!=0        local ++citest 
}
if `citest'!=0 {
    local cit "(rarea, rcap or rline)"
    dis as err "Specify the type of graph for confidence intevals `cit' in {bf:ci()}"
    exit 198
}

local optest=0
foreach gopt in "*ti*" "*sch*" "*lab*" "*note*" "*leg*" {
    if strmatch(`"`endpoints_op'"',"`gopt'")!=0 local ++optest
    if strmatch(`"`coef_op'"',"`gopt'")!=0      local ++optest    
    if strmatch(`"`ci'"',"`gopt'")!=0           local ++optest   
    if strmatch(`"`ci_op'"',"`gopt'")!=0        local ++optest
}
if `optest'!=0 {
    local git "(eg titles, labels, legends, scheme)"
    dis as err "Specify the general options for graph `git' in {bf:graph_op()}"
    exit 198
}

if strmatch(`"`wboot'"', "*level*") + strmatch(`"`wboot'"', "l(*") >= 1 {
    di as err "{bf:level()} option should only be specified in the main command syntax" 
    exit 198 
}

if ("`keepdummies'"=="keepdummies")+("`e(keepdummies)'"=="")>1{
    local er2 "Must save the data before using {bf:keepdummies} option"
    if ("`changed'"=="1")==1{
        di as err "`er2'; data in memory would be lost"
        exit 4
    }
}

*-------------------------------------------------------------------------------
*--- (3) Define leads and lags
*-------------------------------------------------------------------------------     
_LaGs_LeAdS `tvar', baseline(`baseline') `accum' keepbal(`keepbal') lags(`lags') leads(`leads')
local tot_lags  `s(tot_lags)'
local tot_leads `s(tot_leads)'

*-------------------------------------------------------------------------------
*--- (4) Estimate models
*-------------------------------------------------------------------------------  
if ("`over'"=="") {

if ("`method'"=="hdfe")+("`method_old'"=="hdfe")>= 1{
    foreach ado in hdfe ftools {
        cap which `ado'
        if _rc!=0 ssc install `ado'
    }
    cap reghdfe, compile
    local reghdfeopts `absorb' `absorb_old' `options' `options_old'
    reghdfe `varlist2' `tot_leads' `tot_lags' `if' `in' `wt', `reghdfeopts'
    local estat_wboot=e(cmdline)
}
else if ("`method'"=="fe")+("`method_old'"=="fe")>= 1{
    xtreg `varlist2' `tot_leads' `tot_lags' `if' `in' `wt' , fe `options' `options_old'
    local estat_wboot=e(cmdline) 
}
else {
    reg `varlist2' `tot_leads' `tot_lags' `if' `in' `wt' , `options' `options_old'
    local estat_wboot=e(cmdline) 
}
qui estimates store est_
qui matrix v=e(V)
qui matrix b=e(b)
}

else if ("`over'"!="") {

 qui levelsof `over', local(groups)
 local G = r(r)
  
  if ("`if'"==""){
  local if "if `over'=="
 }
 
 else if ("`if'"!=""){
  local if "`if' & `over'=="
 }

_Na_Me_Gr `str_groups', over(`over')
local k = 1
foreach g of local groups{
 local name_g`g' "`s(name_g`k')'"
 local ++k
}
 
local j = 1
foreach g of local groups{

dis _newline
dis as result _skip(20) "Group `j': `over'=`name_g`g''"

if ("`method'"=="hdfe")+("`method_old'"=="hdfe")>= 1{
    foreach ado in hdfe ftools {
        cap which `ado'
        if _rc!=0 ssc install `ado'
    }
    cap reghdfe, compile
    local reghdfeopts `absorb' `absorb_old' `options' `options_old'
    reghdfe `varlist2' `tot_leads' `tot_lags' `if'`g' `in' `wt', `reghdfeopts'
    local estat_wboot_g`g'=e(cmdline)
}
else if ("`method'"=="fe")+("`method_old'"=="fe")>= 1{
    xtreg `varlist2' `tot_leads' `tot_lags' `if'`g' `in' `wt' , fe `options' `options_old'
    local estat_wboot_g`g'=e(cmdline) 
}
else {
    reg `varlist2' `tot_leads' `tot_lags' `if'`g' `in' `wt' , `options' `options_old'
    local estat_wboot_g`g'=e(cmdline) 
}

qui estimates store est_g`g'
qui matrix gv_g`g'=e(V)
qui matrix gb_g`g'=e(b)

local ++j
}

local i = 1
local old
local new
foreach g of local groups {
	if (`i'<`G') {
	 local old `old' `name_g`g''
	 local new `new' `i',
    }
	else if (`i'==`G') {
	 local old `old' `name_g`g''
	 local new `new' `i'
	}
	local ++i
 }
 
 mat group_id = [`new']'
 mat rownames group_id = `old'
 mat colnames group_id = "eventdd ID"
 
}

*-------------------------------------------------------------------------------
*--- (5) Generate point estimates and confidence intervals
*-------------------------------------------------------------------------------
local lev   = r(level)
local alp   = (100-r(level))/100
local critu = `alp'/2
local critl = 1-`critu'

qui sum `tvar' 
local tot  = r(max)-r(min)+1             
local min  = r(min)                      
local max  = r(max)                 
local blpre  = `baseline'-1              
local blpost = `baseline'+1
local _baseline = abs(`baseline') 
local _blpre    = abs(`baseline')-1
local _blpost   = abs(`baseline')+1
local t0  = abs(`min')+1
local t_1 = abs(`min')
local t_2 = abs(`min')-1
local t_3 = `max'-1

if `baseline'<=0 {
    local base = abs(`min')-abs(`baseline')+1
}
else {
    local base = abs(`min')+1 +`baseline'
}

local prebase  =`base'-1
local postbase =`base'+1

tempvar times
qui gen `times'=.
                 
local j = 1
foreach ld of numlist `min'(1)`max' {
    qui replace `times'=`ld' in `j'
    local ++j
}

sort `times'

if ("`over'"=="") {

qui estimates restore est_

foreach var in point uCI lCI {
    tempvar `var'
    qui gen ``var''=.
}

if `baseline'<0 {
    if ("`wboot'"=="wboot") == 1{
        if `baseline'==`min' {
            local i = 2
            foreach t of numlist `t_2'(-1)1{
                qui replace `point'=_b[lead`t'] in `i'
                
                cap qui boottest lead`t', nograph `wboot_op' level(`lev')
                cap mat ci_lead`t'= r(CI)
                cap qui replace `lCI'  = ci_lead`t'[1,1] in `i'
                cap qui replace `uCI'  = ci_lead`t'[1,2] in `i'
                local ++i
            }
        }
        else if `baseline'==-1 {
            local i = 1
            foreach t of numlist `t_1'(-1)2{
                qui replace `point'=_b[lead`t'] in `i'
                
                cap qui boottest lead`t', nograph `wboot_op' level(`lev')
                cap mat ci_lead`t'= r(CI)
                cap qui replace `lCI'  = ci_lead`t'[1,1] in `i'
                cap qui replace `uCI'  = ci_lead`t'[1,2] in `i'
                local ++i
            }
            local ++i
        }
        else {
            local i = 1
            foreach t of numlist `t_1'(-1)`_blpost' `_blpre'(-1)1{
                qui replace `point'=_b[lead`t'] in `i'
                
                cap qui boottest lead`t', nograph `wboot_op' level(`lev')
                cap mat ci_lead`t'= r(CI)
                cap qui replace `lCI'  = ci_lead`t'[1,1] in `i'
                cap qui replace `uCI'  = ci_lead`t'[1,2] in `i'
                local ++i
                if `t'== `_blpost'{
                    local ++i
                }
            }
        }
        foreach t of numlist 0(1)`max'{
            qui replace `point'=_b[lag`t'] in `i'
            
            cap qui boottest lag`t', nograph `wboot_op' level(`lev')
            cap mat ci_lag`t'= r(CI)
            cap qui replace `lCI'  = ci_lag`t'[1,1] in `i'
            cap qui replace `uCI'  = ci_lag`t'[1,2] in `i'
            local ++i
        }
    }
    else {
        if `baseline'==`min' {
            local i = 2
            foreach t of numlist `t_2'(-1)1{
                qui replace `point'=_b[lead`t'] in `i'
                qui replace `lCI'  =_b[lead`t']+invttail(e(df_r),`critl')*_se[lead`t'] in `i'
                qui replace `uCI'  =_b[lead`t']+invttail(e(df_r),`critu')*_se[lead`t'] in `i'
                local ++i
            }
        }
        else if `baseline'==-1 {
            local i = 1
            foreach t of numlist `t_1'(-1)2{
                qui replace `point'=_b[lead`t'] in `i'
                qui replace `lCI'  =_b[lead`t']+invttail(e(df_r),`critl')*_se[lead`t'] in `i'
                qui replace `uCI'  =_b[lead`t']+invttail(e(df_r),`critu')*_se[lead`t'] in `i'
                local ++i
            }
            local ++i
        }
        else {
            local i = 1
            foreach t of numlist `t_1'(-1)`_blpost' `_blpre'(-1)1{
                qui replace `point'=_b[lead`t'] in `i'
                qui replace `lCI'  =_b[lead`t']+invttail(e(df_r),`critl')*_se[lead`t'] in `i'
                qui replace `uCI'  =_b[lead`t']+invttail(e(df_r),`critu')*_se[lead`t'] in `i'
                local ++i
                if `t'== `_blpost'{
                    local ++i
                }
            }
        }
        foreach t of numlist 0(1)`max'{
            qui replace `point'=_b[lag`t'] in `i'
            qui replace `lCI'  =_b[lag`t']+invttail(e(df_r),`critl')*_se[lag`t'] in `i'
            qui replace `uCI'  =_b[lag`t']+invttail(e(df_r),`critu')*_se[lag`t'] in `i'
            local ++i
        }
    } 
}

else if `baseline'>=0 {
    if ("`wboot'"=="wboot") == 1{
        local i = 1
        foreach t of numlist `t_1'(-1)1{
            qui replace `point'=_b[lead`t'] in `i'
            
            cap qui boottest lead`t', nograph `wboot_op' level(`lev')
            cap mat ci_lead`t'= r(CI)
            cap qui replace `lCI'  = ci_lead`t'[1,1] in `i'
            cap qui replace `uCI'  = ci_lead`t'[1,2] in `i'
            local ++i
        }
        if `baseline'==`max' {
            foreach t of numlist 0(1)`t_3'{
                qui replace `point'=_b[lag`t'] in `i'
                
                cap qui boottest lag`t', nograph `wboot_op' level(`lev')
                cap mat ci_lag`t'= r(CI)
                cap qui replace `lCI'  = ci_lag`t'[1,1] in `i'
                cap qui replace `uCI'  = ci_lag`t'[1,2] in `i'
                local ++i
            }
        }
        else if `baseline'==0 {
            local ++i
            foreach t of numlist 1(1)`max'{
                qui replace `point'=_b[lag`t'] in `i'
                
                cap qui boottest lag`t', nograph `wboot_op' level(`lev')
                cap mat ci_lag`t'= r(CI)
                cap qui replace `lCI'  = ci_lag`t'[1,1] in `i'
                cap qui replace `uCI'  = ci_lag`t'[1,2] in `i'
                local ++i
            }
        }
        else {
            foreach t of numlist 0(1)`_blpre' `_blpost'(1)`max'{
                qui replace `point'=_b[lag`t'] in `i'
                
                cap qui boottest lag`t', nograph `wboot_op' level(`lev')
                cap mat ci_lag`t'= r(CI)
                cap qui replace `lCI'  = ci_lag`t'[1,1] in `i'
                cap qui replace `uCI'  = ci_lag`t'[1,2] in `i'
                local ++i
                if `t'== `_blpre'{
                    local ++i
                }
            }
        }
    }
    else {
        local i=1
        foreach t of numlist `t_1'(-1)1{
            qui replace `point'=_b[lead`t'] in `i'
            qui replace `lCI'  =_b[lead`t']+invttail(e(df_r),`critl')*_se[lead`t'] in `i'
            qui replace `uCI'  =_b[lead`t']+invttail(e(df_r),`critu')*_se[lead`t'] in `i'
            local ++i
        }
        if `baseline'==`max' {
            foreach t of numlist 0(1)`t_3'{
                qui replace `point'=_b[lag`t'] in `i'
                qui replace `lCI'  =_b[lag`t']+invttail(e(df_r),`critl')*_se[lag`t'] in `i'
                qui replace `uCI'  =_b[lag`t']+invttail(e(df_r),`critu')*_se[lag`t'] in `i'
                local ++i
            }
        }
        else if `baseline'==0 {
            local ++i
            foreach t of numlist 1(1)`max'{
                qui replace `point'=_b[lag`t'] in `i'
                qui replace `lCI'  =_b[lag`t']+invttail(e(df_r),`critl')*_se[lag`t'] in `i'
                qui replace `uCI'  =_b[lag`t']+invttail(e(df_r),`critu')*_se[lag`t'] in `i'
                local ++i
            }
        }
        else {
            foreach t of numlist 0(1)`_blpre' `_blpost'(1)`max'{
                qui replace `point'=_b[lag`t'] in `i'
                qui replace `lCI'  =_b[lag`t']+invttail(e(df_r),`critl')*_se[lag`t'] in `i'
                qui replace `uCI'  =_b[lag`t']+invttail(e(df_r),`critu')*_se[lag`t'] in `i'
                local ++i
                if `t'== `_blpre'{
                    local ++i
                }
            }
        }
    }
}

qui replace `point'=0 if `times'==`baseline'
qui replace `uCI'  =0 if `times'==`baseline'
qui replace `lCI'  =0 if `times'==`baseline'

qui replace `uCI'  =0 if `times'!=. & `uCI'==.
qui replace `lCI'  =0 if `times'!=. & `lCI'==.


sort `times'

tempvar lds
qui gen `lds'= abs(`times')
qui mkmat `lds' `lCI' `point' `uCI' if `times'<0 & `times'!=., matrix(leads)
qui matrix colnames leads = Lead LB Est UB
qui matsort leads 1 "up"

tempvar lgs
qui gen `lgs'=`times'
qui mkmat `lgs' `lCI' `point' `uCI' if `times'>=0 & `times'!=., matrix(lags)
qui matrix colnames lags = Lag LB Est UB
qui matsort lags 1 "up"


if `baseline'==`min'{
    qui sum `times'
    local minlead  = (-r(min))-1
    local maxlag   = r(max)
    qui matrix vll = v["lead`minlead'".."lag`maxlag'", "lead`minlead'".."lag`maxlag'"]
}

else if `baseline'==`max'{
    qui sum `times'
    local minlead  = -r(min)
    local maxlag   = r(max)-1
    qui matrix vll = v["lead`minlead'".."lag`maxlag'", "lead`minlead'".."lag`maxlag'"]
}
else{
    qui sum `times'
    local minlead  = -r(min)
    local maxlag   = r(max)
    qui matrix vll = v["lead`minlead'".."lag`maxlag'", "lead`minlead'".."lag`maxlag'"]
}

*qui estimates drop est_
}

else if ("`over'"!="") {

local j=1
foreach g of local groups {

foreach var in point_g`g' uCI_g`g' lCI_g`g' {
    tempvar `var'
    qui gen ``var''=.
}

qui estimates restore est_g`g'

if `baseline'<0 {
    if ("`wboot'"=="wboot") == 1{
        if `baseline'==`min' {
            local i = 2
            foreach t of numlist `t_2'(-1)1{
                qui replace `point_g`g''=_b[lead`t'] in `i'
                
                cap qui boottest lead`t', nograph `wboot_op' level(`lev')
                cap mat ci_lead`t'= r(CI)
                cap qui replace `lCI_g`g''  = ci_lead`t'[1,1] in `i'
                cap qui replace `uCI_g`g''  = ci_lead`t'[1,2] in `i'
                local ++i
            }
        }
        else if `baseline'==-1 {
            local i = 1
            foreach t of numlist `t_1'(-1)2{
                qui replace `point_g`g''=_b[lead`t'] in `i'
                
                cap qui boottest lead`t', nograph `wboot_op' level(`lev')
                cap mat ci_lead`t'= r(CI)
                cap qui replace `lCI_g`g''  = ci_lead`t'[1,1] in `i'
                cap qui replace `uCI_g`g''  = ci_lead`t'[1,2] in `i'
                local ++i
            }
            local ++i
        }
        else {
            local i = 1
            foreach t of numlist `t_1'(-1)`_blpost' `_blpre'(-1)1{
                qui replace `point_g`g''=_b[lead`t'] in `i'
                
                cap qui boottest lead`t', nograph `wboot_op' level(`lev')
                cap mat ci_lead`t'= r(CI)
                cap qui replace `lCI_g`g''  = ci_lead`t'[1,1] in `i'
                cap qui replace `uCI_g`g''  = ci_lead`t'[1,2] in `i'
                local ++i
                if `t'== `_blpost'{
                    local ++i
                }
            }
        }
        foreach t of numlist 0(1)`max'{
            qui replace `point_g`g''=_b[lag`t'] in `i'
            
            cap qui boottest lag`t', nograph `wboot_op' level(`lev')
            cap mat ci_lag`t'= r(CI)
            cap qui replace `lCI_g`g''  = ci_lag`t'[1,1] in `i'
            cap qui replace `uCI_g`g''  = ci_lag`t'[1,2] in `i'
            local ++i
        }
    }
    else {
        if `baseline'==`min' {
            local i = 2
            foreach t of numlist `t_2'(-1)1{
                qui replace `point_g`g''=_b[lead`t'] in `i'
                qui replace `lCI_g`g''  =_b[lead`t']+invttail(e(df_r),`critl')*_se[lead`t'] in `i'
                qui replace `uCI_g`g''  =_b[lead`t']+invttail(e(df_r),`critu')*_se[lead`t'] in `i'
                local ++i
            }
        }
        else if `baseline'==-1 {
            local i = 1
            foreach t of numlist `t_1'(-1)2{
                qui replace `point_g`g''=_b[lead`t'] in `i'
                qui replace `lCI_g`g''  =_b[lead`t']+invttail(e(df_r),`critl')*_se[lead`t'] in `i'
                qui replace `uCI_g`g''  =_b[lead`t']+invttail(e(df_r),`critu')*_se[lead`t'] in `i'
                local ++i
            }
            local ++i
        }
        else {
            local i = 1
            foreach t of numlist `t_1'(-1)`_blpost' `_blpre'(-1)1{
                qui replace `point_g`g''=_b[lead`t'] in `i'
                qui replace `lCI_g`g''  =_b[lead`t']+invttail(e(df_r),`critl')*_se[lead`t'] in `i'
                qui replace `uCI_g`g''  =_b[lead`t']+invttail(e(df_r),`critu')*_se[lead`t'] in `i'
                local ++i
                if `t'== `_blpost'{
                    local ++i
                }
            }
        }
        foreach t of numlist 0(1)`max'{
            qui replace `point_g`g''=_b[lag`t'] in `i'
            qui replace `lCI_g`g''  =_b[lag`t']+invttail(e(df_r),`critl')*_se[lag`t'] in `i'
            qui replace `uCI_g`g''  =_b[lag`t']+invttail(e(df_r),`critu')*_se[lag`t'] in `i'
            local ++i
        }
    } 
}

else if `baseline'>=0 {
    if ("`wboot'"=="wboot") == 1{
        local i = 1
        foreach t of numlist `t_1'(-1)1{
            qui replace `point_g`g''=_b[lead`t'] in `i'
            
            cap qui boottest lead`t', nograph `wboot_op' level(`lev')
            cap mat ci_lead`t'= r(CI)
            cap qui replace `lCI_g`g''  = ci_lead`t'[1,1] in `i'
            cap qui replace `uCI_g`g''  = ci_lead`t'[1,2] in `i'
            local ++i
        }
        if `baseline'==`max' {
            foreach t of numlist 0(1)`t_3'{
                qui replace `point_g`g''=_b[lag`t'] in `i'
                
                cap qui boottest lag`t', nograph `wboot_op' level(`lev')
                cap mat ci_lag`t'= r(CI)
                cap qui replace `lCI_g`g''  = ci_lag`t'[1,1] in `i'
                cap qui replace `uCI_g`g''  = ci_lag`t'[1,2] in `i'
                local ++i
            }
        }
        else if `baseline'==0 {
            local ++i
            foreach t of numlist 1(1)`max'{
                qui replace `point_g`g''=_b[lag`t'] in `i'
                
                cap qui boottest lag`t', nograph `wboot_op' level(`lev')
                cap mat ci_lag`t'= r(CI)
                cap qui replace `lCI_g`g''  = ci_lag`t'[1,1] in `i'
                cap qui replace `uCI_g`g''  = ci_lag`t'[1,2] in `i'
                local ++i
            }
        }
        else {
            foreach t of numlist 0(1)`_blpre' `_blpost'(1)`max'{
                qui replace `point_g`g''=_b[lag`t'] in `i'
                
                cap qui boottest lag`t', nograph `wboot_op' level(`lev')
                cap mat ci_lag`t'= r(CI)
                cap qui replace `lCI_g`g''  = ci_lag`t'[1,1] in `i'
                cap qui replace `uCI_g`g''  = ci_lag`t'[1,2] in `i'
                local ++i
                if `t'== `_blpre'{
                    local ++i
                }
            }
        }
    }
    else {
        local i=1
        foreach t of numlist `t_1'(-1)1{
            qui replace `point_g`g''=_b[lead`t'] in `i'
            qui replace `lCI_g`g''  =_b[lead`t']+invttail(e(df_r),`critl')*_se[lead`t'] in `i'
            qui replace `uCI_g`g''  =_b[lead`t']+invttail(e(df_r),`critu')*_se[lead`t'] in `i'
            local ++i
        }
        if `baseline'==`max' {
            foreach t of numlist 0(1)`t_3'{
                qui replace `point_g`g''=_b[lag`t'] in `i'
                qui replace `lCI_g`g''  =_b[lag`t']+invttail(e(df_r),`critl')*_se[lag`t'] in `i'
                qui replace `uCI_g`g''  =_b[lag`t']+invttail(e(df_r),`critu')*_se[lag`t'] in `i'
                local ++i
            }
        }
        else if `baseline'==0 {
            local ++i
            foreach t of numlist 1(1)`max'{
                qui replace `point_g`g''=_b[lag`t'] in `i'
                qui replace `lCI_g`g''  =_b[lag`t']+invttail(e(df_r),`critl')*_se[lag`t'] in `i'
                qui replace `uCI_g`g''  =_b[lag`t']+invttail(e(df_r),`critu')*_se[lag`t'] in `i'
                local ++i
            }
        }
        else {
            foreach t of numlist 0(1)`_blpre' `_blpost'(1)`max'{
                qui replace `point_g`g''=_b[lag`t'] in `i'
                qui replace `lCI_g`g''  =_b[lag`t']+invttail(e(df_r),`critl')*_se[lag`t'] in `i'
                qui replace `uCI_g`g''  =_b[lag`t']+invttail(e(df_r),`critu')*_se[lag`t'] in `i'
                local ++i
                if `t'== `_blpre'{
                    local ++i
                }
            }
        }
    }
}

qui replace `point_g`g''=0 if `times'==`baseline'
qui replace `uCI_g`g''  =0 if `times'==`baseline'
qui replace `lCI_g`g''  =0 if `times'==`baseline'

qui replace `uCI_g`g''  =0 if `times'!=. & `uCI_g`g''==.
qui replace `lCI_g`g''  =0 if `times'!=. & `lCI_g`g''==.


sort `times'

tempvar lds
qui gen `lds'= abs(`times')
qui mkmat `lds' `lCI_g`g'' `point_g`g'' `uCI_g`g'' if `times'<0 & `times'!=., matrix(gleads_g`g')
qui matrix colnames gleads_g`g' = Lead LB Est UB
qui matsort gleads_g`g' 1 "up"

tempvar lgs
qui gen `lgs'=`times'
qui mkmat `lgs' `lCI_g`g'' `point_g`g'' `uCI_g`g'' if `times'>=0 & `times'!=., matrix(glags_g`g')
qui matrix colnames glags_g`g' = Lag LB Est UB
qui matsort glags_g`g' 1 "up"


if `baseline'==`min'{
    qui sum `times'
    local minlead  = (-r(min))-1
    local maxlag   = r(max)
    qui matrix gvll_g`g' = gv_g`g'["lead`minlead'".."lag`maxlag'", "lead`minlead'".."lag`maxlag'"]
}

else if `baseline'==`max'{
    qui sum `times'
    local minlead  = -r(min)
    local maxlag   = r(max)-1
    qui matrix gvll_g`g' = gv_g`g'["lead`minlead'".."lag`maxlag'", "lead`minlead'".."lag`maxlag'"]
}
else{
    qui sum `times'
    local minlead  = -r(min)
    local maxlag   = r(max)
    qui matrix gvll_g`g' = gv_g`g'["lead`minlead'".."lag`maxlag'", "lead`minlead'".."lag`maxlag'"]
}
*qui estimates drop est_g`g'

 mat rename gleads_g`g' leads_g`j'
 mat rename glags_g`g'  lags_g`j'
 mat rename gvll_g`g'   vll_g`j'
 mat rename gv_g`g'     v_g`j'
 mat rename gb_g`g'     b_g`j'
 local ++j
}
}

*-------------------------------------------------------------------------------
*--- (6) Graph
*-------------------------------------------------------------------------------     
sort `times'

if ("`over'"=="") {

foreach var in zero col {
    tempvar `var'
    qui gen ``var''=.
}

if (`lCI'==`point'==`uCI'==0) & (_n==1) & (`baseline'!=`min'){
    qui replace `zero'=1 if `lCI'==0 & `point'==0 & `uCI'==0  & `times'!=`baseline'
    qui replace `col' =1 if (`zero'[_n]==`zero'[_n+1]&`zero'!=.)|(`zero'[_n]==`zero'[_n-1]&`zero'!=.)
    
    qui replace `lCI'  =. if `col'==1 
    qui replace `point'=. if `col'==1 
    qui replace `uCI'  =. if `col'==1 
    qui replace `times'=. if `col'==1 
}

if (`lCI'==`point'==`uCI'==0) & (_n==`tot') & (`baseline'!=`max'){
    qui replace `zero'=1 if `lCI'==0 & `point'==0 & `uCI'==0 & `times'!=`baseline'
    qui replace `col' =1 if (`zero'[_n]==`zero'[_n-1]&`zero'!=.)|(`zero'[_n]==`zero'[_n+1]&`zero'!=.)
    
    qui replace `lCI'  =. if `col'==1 
    qui replace `point'=. if `col'==1 
    qui replace `uCI'  =. if `col'==1 
    qui replace `times'=. if `col'==1 
}

_Ci_Op_TS `ci'
local ci_type `s(type)'
local ci_op   `s(ci_op)'

if ("`line'"=="noline")==0{
    local graph_op `graph_op' xline(-1, lcolor(black) lpattern(solid))
}

if strmatch(`"`graph_op'"', "*leg*")==0 & strmatch(`"`graph_op'"', "*xti*")==1{
    local graph_op `graph_op' legend(order(2 "Point Estimate" 1 "`lev'% CI"))
}

if strmatch(`"`graph_op'"', "*leg*")==1 & strmatch(`"`graph_op'"', "*xti*")==0{
    local graph_op `graph_op' xtitle("Time")
}

if strmatch(`"`graph_op'"', "*leg*")==0 & strmatch(`"`graph_op'"', "*xti*")==0{
    local graph_op `graph_op' legend(order(2 "Point Estimate" 1 "`lev'% CI")) xtitle("Time")
}

if ("`balanced'"=="balanced") == 1{
    tempvar obs
    qui gen `obs'=.
    
    local k = 1
    foreach t of numlist `min'(1)`max' {
        qui sum `tvar' if `tvar'==`t'
        qui replace `obs'=r(N)  in `k'
        local ++k
    }
    qui tab `tvar', matcell(x)
    foreach ado in matsort {
        cap which `ado'
        if _rc!=0 ssc install `ado'
    }
    matsort  x 1 "down"
    local max2=el(x,2,1) 
    qui tab `times' if `obs'>=`max2'
    local bal=r(r)
    
    #delimit ;
    twoway `ci_type' `lCI' `uCI' `times' if `obs'>=`max2', `ci_op' `ci_op_old' 
    || scatter `point' `times' if `obs'>=`max2', `coef_op' `graph_op'
    yline(0, lcolor(red));
    #delimit cr
}
else if ("`accum'"=="accum") == 1{
    if ("`end'"=="noend") == 1{
        local lpoint = `leads' -1 
        local upoint = `lags'  -1 
        
        #delimit ;
        twoway `ci_type' `lCI' `uCI' `times' if inrange(`times', -`lpoint', `upoint'),
        `ci_op' `ci_op_old'  yline(0, lcolor(red)) `graph_op'
        || scatter `point' `times' if inrange(`times', -`lpoint', `upoint'), `coef_op';
        #delimit cr
    }
    else {
        #delimit ;
        twoway `ci_type' `lCI' `uCI' `times', `ci_op' `ci_op_old' yline(0, lcolor(red))       
        || scatter `point' `times', `coef_op' `graph_op'
        || scatter `point' `times' if `times'==-`leads' | `times'==`lags', `endpoints_op';
        #delimit cr
    }
}
else if ("`keepbal'"!="") == 1 {
    #delimit ;
    twoway `ci_type' `lCI' `uCI' `times', `ci_op' `ci_op_old' 
    || scatter `point' `times', `coef_op' `graph_op' yline(0, lcolor(red));
    #delimit cr
}
else if ("`inrange'"!="") == 1 {
    #delimit ;
    twoway `ci_type' `lCI' `uCI' `times' if inrange(`times', -`leads', `lags'),
    `ci_op' `ci_op_old' yline(0, lcolor(red)) `graph_op'
    || scatter `point' `times' if inrange(`times', -`leads', `lags'), `coef_op';
    #delimit cr	
}
else {
    #delimit ;
    twoway `ci_type' `lCI' `uCI' `times' if inrange(`times', `min', `max'),
    `ci_op' `ci_op_old' yline(0, lcolor(red)) `graph_op'
    || scatter `point' `times' if inrange(`times', `min', `max'),  `coef_op';
    #delimit cr
}
}

else if ("`over'"!="") {

if (`jitter'==0) {
 foreach g of local groups {
  tempvar times_g`g'
  qui gen `times_g`g''=`times'
 }
}

else {
 local q=0
 foreach g of local groups {
  tempvar times_g`g'
  qui gen `times_g`g''=`times'+(`q'*`jitter')
  local ++q
 }
}

foreach g of local groups {

foreach var in zero_g`g' col_g`g' {
    tempvar `var'
    qui gen ``var''=.
}

if (`lCI_g`g''==`point_g`g''==`uCI_g`g''==0) & (_n==1) & (`baseline'!=`min'){
    qui replace `zero_g`g''=1 if `lCI_g`g''==0 & `point_g`g''==0 & `uCI_g`g''==0  & `times'!=`baseline'
    qui replace `col_g`g'' =1 if (`zero_g`g''[_n]==`zero_g`g''[_n+1]&`zero_g`g''!=.)|(`zero_g`g''[_n]==`zero_g`g''[_n-1]&`zero_g`g''!=.)
    
    qui replace `lCI_g`g''  =. if `col_g`g''==1 
    qui replace `point_g`g''=. if `col_g`g''==1 
    qui replace `uCI_g`g''  =. if `col_g`g''==1 
    qui replace `times_g`g''=. if `col_g`g''==1 
}

if (`lCI_g`g''==`point_g`g''==`uCI_g`g''==0) & (_n==`tot') & (`baseline'!=`max'){
    qui replace `zero_g`g''=1 if `lCI_g`g''==0 & `point_g`g''==0 & `uCI_g`g''==0 & `times'!=`baseline'
    qui replace `col_g`g'' =1 if (`zero_g`g''[_n]==`zero_g`g''[_n-1]&`zero_g`g''!=.)|(`zero_g`g''[_n]==`zero_g`g''[_n+1]&`zero_g`g''!=.)
    
    qui replace `lCI_g`g''  =. if `col_g`g''==1 
    qui replace `point_g`g''=. if `col_g`g''==1 
    qui replace `uCI_g`g''  =. if `col_g`g''==1 
    qui replace `times_g`g''=. if `col_g`g''==1 
}
}

_Ci_Op_TS `ci'
local ci_type `s(type)'
local ci_op   `s(ci_op)'

_LiSt_G, over(`over')
_Op_TS_Ov, over(`over') `s(ci_op)'  
local j=1
foreach g of local groups {
 local ci_g`g' `s(opt_g`j')'
 local ++j
}

_LiSt_G, over(`over')
_Op_TS_Ov, over(`over') `coef_op'  
local j=1
foreach g of local groups {
 local coef_g`g' `s(opt_g`j')'
 local ++j
}

local glab
local m = 1
local h = 2

if ("`accum'"=="accum") == 1 {
 foreach g of local str_groups {
	local glab `glab' `h' "Point Estimate `over'=`g'" `m' "`lev'% CI `over'=`g'"
	local m=`m'+3
	local h=`h'+3
 }
}

else {
 foreach g of local str_groups {
	local glab `glab' `h' "Point Estimate `over'=`g'" `m' "`lev'% CI `over'=`g'"
	local m=`m'+2
	local h=`h'+2
 }
}

if ("`line'"=="noline")==0{
    local graph_op `graph_op' xline(-1, lcolor(black) lpattern(solid))
}

if strmatch(`"`graph_op'"', "*leg*")==0 & strmatch(`"`graph_op'"', "*xti*")==1{
    local graph_op `graph_op' legend(order(`"`glab'"'))
}

if strmatch(`"`graph_op'"', "*leg*")==1 & strmatch(`"`graph_op'"', "*xti*")==0{
    local graph_op `graph_op' xtitle("Time")
}

if strmatch(`"`graph_op'"', "*leg*")==0 & strmatch(`"`graph_op'"', "*xti*")==0{
    local graph_op `graph_op' legend(order(`"`glab'"')) xtitle("Time")
}

	local i = 1
	local graph twoway
  
 if ("`balanced'"=="balanced") == 1{
	tempvar obs
    qui gen `obs'=.
    
    local k = 1
    foreach t of numlist `min'(1)`max' {
        qui sum `tvar' if `tvar'==`t'
        qui replace `obs'=r(N)  in `k'
        local ++k
    }
    qui tab `tvar', matcell(x)
    foreach ado in matsort {
        cap which `ado'
        if _rc!=0 ssc install `ado'
    }
    matsort  x 1 "down"
    local max2=el(x,2,1) 
    qui tab `times' if `obs'>=`max2'
    local bal=r(r)
	
    foreach g of local groups {
	if (`i'<`G') {
	 local graph `graph' `ci_type' `lCI_g`g'' `uCI_g`g'' `times_g`g'' if `obs'>=`max2', `ci_g`g'' `ci_op_old' || scatter `point_g`g'' `times_g`g'' if `obs'>=`max2', `coef_g`g'' || 
    }
	else if (`i'==`G') {
	 local graph `graph' `ci_type' `lCI_g`g'' `uCI_g`g'' `times_g`g'' if `obs'>=`max2', `ci_g`g'' `ci_op_old' || scatter `point_g`g'' `times_g`g'' if `obs'>=`max2', `coef_g`g''
	}
	local ++i
	}
	local graph `graph' `graph_op' yline(0, lcolor(red))
 }
 
 else if ("`accum'"=="accum") == 1{
    if ("`end'"=="noend") == 1{
		local lpoint = `leads' -1 
        local upoint = `lags'  -1 
		
        foreach g of local groups {
		if (`i'<`G') {
         local graph `graph' `ci_type' `lCI_g`g'' `uCI_g`g'' `times_g`g'' if inrange(`times', -`lpoint', `upoint'), `ci_g`g'' `ci_op_old' || scatter `point_g`g'' `times_g`g'' if inrange(`times', -`lpoint', `upoint'), `coef_g`g'' || 
        }
		else if (`i'==`G') {
         local graph `graph' `ci_type' `lCI_g`g'' `uCI_g`g'' `times_g`g'' if inrange(`times', -`lpoint', `upoint'), `ci_g`g'' `ci_op_old' || scatter `point_g`g'' `times_g`g'' if inrange(`times', -`lpoint', `upoint'), `coef_g`g''
		}
		local ++i
		}
		local graph `graph' `graph_op' yline(0, lcolor(red))
    }
    else {
		foreach g of local groups {
        if (`i'<`G') {
         local graph `graph' `ci_type' `lCI_g`g'' `uCI_g`g'' `times_g`g'', `ci_g`g'' `ci_op_old' || scatter `point_g`g'' `times_g`g'', `coef_g`g'' || scatter `point_g`g'' `times_g`g'' if `times'==-`leads' | `times'==`lags', `endpoints_op' || 
		}
		else if (`i'==`G') {
		 local graph `graph' `ci_type' `lCI_g`g'' `uCI_g`g'' `times_g`g'', `ci_g`g'' `ci_op_old' || scatter `point_g`g'' `times_g`g'', `coef_g`g'' || scatter `point_g`g'' `times_g`g'' if `times'==-`leads' | `times'==`lags', `endpoints_op'
		}
		local ++i
		}
		local graph `graph' `graph_op' yline(0, lcolor(red))
    }
 }

 else if ("`keepbal'"!="") == 1 {
    foreach g of local groups {
	if (`i'<`G') {
     local graph `graph' `ci_type' `lCI_g`g'' `uCI_g`g'' `times_g`g'', `ci_g`g'' `ci_op_old' || scatter `point_g`g'' `times_g`g'', `coef_g`g'' || 
	}
	else if (`i'==`G') {
     local graph `graph' `ci_type' `lCI_g`g'' `uCI_g`g'' `times_g`g'', `ci_g`g'' `ci_op_old' || scatter `point_g`g'' `times_g`g'', `coef_g`g''
	}
	local ++i
	}
	local graph `graph' `graph_op' yline(0, lcolor(red))
 }

 else if ("`inrange'"!="") == 1 {
    foreach g of local groups {
	if (`i'<`G') {
     local graph `graph' `ci_type' `lCI_g`g'' `uCI_g`g'' `times_g`g'' if inrange(`times', -`leads', `lags'), `ci_g`g'' `ci_op_old' || scatter `point_g`g'' `times_g`g'' if inrange(`times', -`leads', `lags'), `coef_g`g'' || 
    }
	else if (`i'==`G') {
     local graph `graph' `ci_type' `lCI_g`g'' `uCI_g`g'' `times_g`g'' if inrange(`times', -`leads', `lags'), `ci_g`g'' `ci_op_old' || scatter `point_g`g'' `times_g`g'' if inrange(`times', -`leads', `lags'), `coef_g`g''
    }
	local ++i
	}
	local graph `graph' `graph_op' yline(0, lcolor(red))
 }

 else {
    foreach g of local groups {
	if (`i'<`G') {
    local graph `graph' `ci_type' `lCI_g`g'' `uCI_g`g'' `times_g`g'' if inrange(`times', `min', `max'), `ci_g`g'' `ci_op_old' || scatter `point_g`g'' `times_g`g'' if inrange(`times', `min', `max'), `coef_g`g'' || 
	}
	else if (`i'==`G') {
    local graph `graph' `ci_type' `lCI_g`g'' `uCI_g`g'' `times_g`g'' if inrange(`times', `min', `max'), `ci_g`g'' `ci_op_old' || scatter `point_g`g'' `times_g`g'' if inrange(`times', `min', `max'), `coef_g`g'' 
	}
	local ++i
	}
	local graph `graph' `graph_op' yline(0, lcolor(red))
 }

    `graph'
}

*-------------------------------------------------------------------------------
*--- (7) Return
*-------------------------------------------------------------------------------     
ereturn local cmdline `"`0'"'
ereturn local cmd "eventdd3"
ereturn local estat_cmd "eventdd3_estat"
ereturn local keepdummies "`keepdummies'"
ereturn scalar level=`lev'
ereturn scalar baseline=`baseline'

if ("`over'"=="") {
 ereturn local estat_wboot "`estat_wboot'"
 ereturn matrix lags  lags
 ereturn matrix leads leads
 ereturn matrix V_leads_lags vll
}

else if ("`over'"!="") {
ereturn local over "`over_var'"
ereturn matrix group_id group_id

 foreach g of local groups {
  ereturn local estat_wboot_g`g' "`estat_wboot_g`g''"
 }
 
 foreach n of numlist 1/`G' {
  ereturn matrix b_g`n' 	b_g`n'
  ereturn matrix lags_g`n'  lags_g`n'
  ereturn matrix leads_g`n' leads_g`n'
  ereturn matrix V_g`n'     v_g`n'
  ereturn matrix V_leads_lags_g`n' vll_g`n'
 }
}

restore

if ("`keepdummies'"=="keepdummies")==1{
    rename `timevar' _Ptime
    local tvar _Ptime
    _LaGs_LeAdS `tvar', baseline(`baseline') `accum' keepbal(`keepbal') lags(`lags') leads(`leads')
    rename _Ptime `timevar'
    cap drop _Tbal*
}

end

*-------------------------------------------------------------------------------
*--- (8) Subroutines
*------------------------------------------------------------------------------- 
cap program drop _WhIch_MetHOd
program define _WhIch_MetHOd, sclass
    vers 13.0

    syntax [anything] [, absorb(passthru) *]

    local valid_method=inlist("`anything'", "fe", "ols", "hdfe", "")
    if (`valid_method'==0) {
        di as err "only one of {bf:fe}, {bf:ols}, or {bf:hdfe} is allowed"
        exit 198
    }

    if ("`anything'"=="hdfe" & "`absorb'"=="") {
        dis as err "{bf:absorb()} is required with method {bf:hdfe}"
        exit 198
    }
   
    if ("`anything'"!="hdfe" & "`absorb'"!="") {
        dis as err "{bf:absorb()} is only allowed with method {bf:hdfe}"
        exit 198
    }
  
    if ("`anything'"=="") {
        local anything ols
    }

    sreturn local meth `anything'
    sreturn local abs    `absorb'
    sreturn local opts   `options'
end

cap program drop _LaGs_LeAdS
program define _LaGs_LeAdS, sclass
    vers 13.0

    #delimit ;
    syntax varlist(max=1 fv ts numeric)
    [,
     baseline(integer -1) accum keepbal(varname)
     lags(integer 0) leads(integer 0)
    ]
    ;
    #delimit cr

    local er3ai "for all leads and lags"
    local er3a "Ensure that the indicated {bf:timevar()} has full coverage `er3ai'"
    if ("`keepbal'"!="")==1 {
        local tbal=`lags'+`leads'+1
        qui tab `varlist' if `varlist'>=-`leads' & `varlist'<=`lags', gen(_Tbal)
        tempvar rbal
        qui egen `rbal'=rowtotal(_Tbal*)
        tempvar bal
        qui bysort `keepbal': egen `bal'=total(`rbal') if `rbal'!=0
        qui count if `bal'==`tbal'
        local un=r(N)
        if `un'==0{
            local er3b "Attempt using fewer leads or lags or"
            local er3c "without the units balanced option"
            dis as err "No unit meets the value criteria specified. `er3a'. `er3b' `er3c'."
            exit 198
        }
        else {
            qui keep if `bal'==`tbal' | `varlist'==.
        }
        qui recode `varlist' (.=`baseline')
        qui char `varlist'[omit] `baseline'
        qui xi i.`varlist', pref(_lf)
    }
    else if ("`accum'"=="accum")==1 {
        qui recode `varlist' (.=`baseline') (-1000/-`leads'=-`leads') (`lags'/1000=`lags')
        qui char `varlist'[omit] `baseline'
        qui xi i.`varlist', pref(_lf)
        
        qui tab `varlist'
        local row = r(r)
        qui sum `varlist'
        local tot  = r(max)-r(min)+1  
        
	if `row'!=`tot'{
            local er3b "or attempt using fewer leads or lags"
            dis as err "`er3a' `er3b'." 
            exit 198
        }
    }
    else {
        qui recode `varlist' (.=`baseline')
        qui char `varlist'[omit] `baseline'
        qui xi i.`varlist', pref(_lf)
        
        qui tab `varlist'
        local row = r(r)
        qui sum `varlist'
        local tot  = r(max)-r(min)+1  
		
	if `row'!=`tot'{
            local er3z "Lead or lag term not found in the range of the event study plot."
            local er3b "or attempt accumulating leads and lags using the {bf:accum} option"
            di as err  "`er3z' `er3a', `er3b'." 
            exit 198
        }
    }
    
    qui sum `varlist'
    local tot  = r(max)-r(min)+1             
    local min  = r(min)                      
    local max  = r(max)                 
    local blpre  = `baseline'-1              
    local blpost = `baseline'+1
    local _baseline = abs(`baseline') 
    local _blpre    = abs(`baseline')-1
    local _blpost   = abs(`baseline')+1
    local t0  = abs(`min')+1
    local t_1 = abs(`min')
    local t_2 = abs(`min')-1
    local t_3 = `max'-1
	  
    if `baseline'<=0 {
        local base = abs(`min')-abs(`baseline')+1
    }
    
    else {
        local base = abs(`min')+1 +`baseline'
    }
    
    local prebase  =`base'-1
    local postbase =`base'+1
    
    tempvar times
    qui gen `times'=.
    
    local j = 1
    foreach ld of numlist `min'(1)`max' {
        qui replace `times'=`ld' in `j'
    	local ++j
    }	
    sort `times'
    
    if `baseline'<0 {
        if `baseline'==`min' {
            local i = 1
            foreach n of numlist `t_1'(-1)2{
                qui rename  _lf_Ptime_`n' lead`i'
                qui lab var lead`i' "t=-`i'"
                local ++i
            }
        }
        else if `baseline'==-1 {
            local i = 2
            foreach n of numlist `prebase'(-1)1{
                qui rename  _lf_Ptime_`n' lead`i'
                qui lab var lead`i' "t=-`i'"
                local ++i
            }
        }
        else {
            local i = 1
            foreach n of numlist `t_1'(-1)`postbase' `prebase'(-1)1{
                qui rename  _lf_Ptime_`n' lead`i'
                qui lab var lead`i' "t=-`i'"
                local ++i
                if `n'== `postbase'{
                    local ++i
                }
            }
        }
        local k = 0
        foreach n of numlist `t0'(1)`tot'{
            qui rename  _lf_Ptime_`n' lag`k'
            qui lab var lag`k' "t=`k'"
            local ++k
        }        
        local tot_lags lag*
        local tot_leads lead*
    }
    else if `baseline'>=0 {
        if `baseline'==`max' {
            local k = 0
            foreach n of numlist `t0'(1)`prebase'{
                qui rename  _lf_Ptime_`n' lag`k'
                qui lab var lag`k' "t=`k'"
                local ++k
            }
        }
        else if `baseline'==0 {
            local k = 1
            foreach n of numlist `postbase'(1)`tot'{
                qui rename  _lf_Ptime_`n' lag`k'
                qui lab var lag`k' "t=`k'"
                local ++k
            }
        }
        else {
            local k = 0
            foreach n of numlist `t0'(1)`prebase' `postbase'(1)`tot'{
                qui rename  _lf_Ptime_`n' lag`k'
                qui lab var lag`k' "t=`k'"
                local ++k
                if `n'== `prebase'{
                    local ++k
                }
            }
        }
        local i = 1
        foreach n of numlist `t_1'(-1)1{
            qui rename  _lf_Ptime_`n' lead`i'
            qui lab var lead`i' "t=-`i'"
            local ++i
        }
        
        local tot_lags lag*
        local tot_leads lead*
    }
    sreturn local tot_lags  `tot_lags'
    sreturn local tot_leads `tot_leads'
end

     
cap program drop _Ci_Op_TS
program define _Ci_Op_TS, sclass
    vers 13.0
  
    syntax [anything] [, *]
  
    local valid_ci=inlist("`anything'", "rcap", "rarea", "rline", "")
    if (`valid_ci'==0) {
        di as err "only one of {bf:rcap}, {bf:rarea}, or {bf:rline} is allowed"
        exit 198
    }
  
    if ("`anything'"=="") {
        local anything rcap
    }

    sreturn local type  `anything'
    sreturn local ci_op `options'
end


cap program drop _LiSt_G
program define _LiSt_G, sclass
    vers 13.0
  
    syntax, over(varlist max=1)
	  
   	qui levelsof `over', local(groups)
	local G = r(r)
	
	local _opt
    foreach g of numlist 1/`G'{
	local _opt `_opt' g`g'(string asis) 
	}
	
	sreturn local list_g `_opt'
end


cap program drop _Op_TS_Ov
program define _Op_TS_Ov, sclass
    vers 13.0
	local list_g `s(list_g)'
  
    syntax, over(varlist max=1) [`list_g']
	  
   	qui levelsof `over', local(groups)
	local G = r(r)

    foreach g of numlist 1/`G'{
	sreturn local opt_g`g' `g`g'' 
	}
end


cap program drop _Na_Me_Gr
program define _Na_Me_Gr, sclass
    vers 13.0
	
	syntax [anything], over(varlist max=1)
	
	qui levelsof `over', local(groups)
	local G = r(r)
    
	tokenize `"`anything'"'
	
	foreach g of numlist 1/`G'{
	sreturn local name_g`g' ``g'' 
	} 
end
