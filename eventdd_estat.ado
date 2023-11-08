*! eventdd_estat: Estimate panel event study models and generate plots
*! Version 2.0.0 October 08, 2023 @ 11:15:11 
*! Author: Damian Clarke & Kathya Tapia-Schythe


cap program drop eventdd3_estat
program eventdd3_estat, eclass
vers 13.0

preserve
if ("`e(cmd)'"=="eventdd3")+("`e(cmd)'"=="eventdd3_estat")==0{
    error 321
}

local over `e(over)'
local baseline = e(baseline)
gettoken subcmd rest : 0, parse(" ,")
local opts=subinword("`rest'","wboot","",.)
local opts=subinword("`opts'","dropdummies","",.)
local opts=subinword("`opts'",",","",.)

if ("`over'"=="") {
local jitter
}

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

if ("`over'"=="") {

local estat_wboot `e(estat_wboot)' 
mat nleads     = e(leads)
mat nlags      = e(lags)

if strmatch(`"`rest'"', "*wboot*")==1 {
    qui `estat_wboot'
}

if "`subcmd'"=="leads" {
    
    mat n_leads = nleads[.,"Lead"]
    *preserve
    svmat n_leads, names(n_leads)
    qui drop if -n_leads1==`baseline'
    qui levelsof n_leads, local(n_leads)
    *restore
    
    local list_leads
    foreach n of local n_leads {
	local list_leads `list_leads' lead`n' 
    }
    
    if strmatch(`"`rest'"', "*wboot*")==1{
        qui boottest `list_leads', `opts' 
    }
    
    else{
	qui test `list_leads', `opts' 	
    }
    
    local F_leads    = r(F)
    local p_leads    = r(p)
    local df_leads   = r(df)
    local df_r_leads = r(df_r)
    
    if strmatch(`"`rest'"', "*wboot*")==1{
        dis "{col 40}"
    }
    dis "{col 40}"
    dis _col(5)"Joint significance test for leads"
    dis "{hline 40}"
    dis "F-stat:{col 25}" %9.4f `F_leads'
    dis "P-value:{col 25}" %9.4f `p_leads'
    dis "{hline 40}"
    dis "Degrees of freedom" "{col 27}(`df_leads',`df_r_leads')"
    dis "{hline 40}"
} 

else if "`subcmd'"=="lags" {
    
    mat n_lags = nlags[.,"Lag"]
    *preserve
    svmat n_lags, names(n_lags)
    qui drop if n_lags1==`baseline'
    qui levelsof n_lags, local(n_lags)
    *restore
    
    local list_lags
    foreach n of local n_lags{
	local list_lags `list_lags' lag`n' 
    }
    
    if strmatch(`"`rest'"', "*wboot*")==1{
        qui boottest `list_lags', `opts' 
    }
    
    else{
        qui test `list_lags', `opts'
    }
    
    local F_lags    = r(F)
    local p_lags    = r(p)
    local df_lags   = r(df)
    local df_r_lags = r(df_r)	
    
    if strmatch(`"`rest'"', "*wboot*")==1{
        dis "{col 40}"
    }
    dis "{col 40}"
    dis _col(5)"Joint significance test for lags"
    dis "{hline 40}"
    dis "F-stat:{col 25}" %9.4f `F_lags'
    dis "P-value:{col 25}" %9.4f `p_lags'
    dis "{hline 40}"
    dis "Degrees of freedom" "{col 27}(`df_lags',`df_r_lags')"
    dis "{hline 40}"
} 

else if "`subcmd'"=="eventdd" {
    
    ***LEADS***
    mat n_leads = nleads[.,"Lead"]
    *preserve
    svmat n_leads, names(n_leads)
    qui drop if -n_leads1==`baseline'
    qui levelsof n_leads, local(n_leads)
    *restore
    
    local list_leads
    foreach n of local n_leads {
	local list_leads `list_leads' lead`n' 
    }
    
    if strmatch(`"`rest'"', "*wboot*")==1{
        qui boottest `list_leads', `opts' 
    }
    
    else{
	qui test `list_leads', `opts' 	
    }
    
    local F_leads    = r(F)
    local p_leads    = r(p)
    local df_leads   = r(df)
    local df_r_leads = r(df_r)
    
    ***LAGS***
    mat n_lags = nlags[.,"Lag"]
    *preserve
    svmat n_lags, names(n_lags)
    qui drop if n_lags1==`baseline'
    qui levelsof n_lags, local(n_lags)
    *restore
    
    local list_lags
    foreach n of local n_lags{
	local list_lags `list_lags' lag`n' 
    }
    
    if strmatch(`"`rest'"', "*wboot*")==1{
        qui boottest `list_lags', `opts' 
    }
    
    else{
        qui test `list_lags', `opts'
    }
    
    local F_lags    = r(F)
    local p_lags    = r(p)
    local df_lags   = r(df)
    local df_r_lags = r(df_r)
    
    if strmatch(`"`rest'"', "*wboot*")==1{
        dis "{col 40}"
    }
    dis "{col 40}"
    dis _col(7)"Joint significance test for"
    dis _col(12)"leads and lags"
    dis "{hline 40}"
	dis _col(17)"LEADS"
    dis "{hline 40}"
    dis "F-stat:{col 25}" %9.4f `F_leads'
    dis "P-value:{col 25}" %9.4f `p_leads'
    dis "Degrees of freedom" "{col 27}(`df_leads',`df_r_leads')"
    dis "{hline 40}"
    dis _col(18)"LAGS"
    dis "{hline 40}"
    dis "F-stat:{col 25}" %9.4f `F_lags'
    dis "P-value:{col 25}" %9.4f `p_lags'
    dis "Degrees of freedom" "{col 27}(`df_lags',`df_r_lags')"
    dis "{hline 40}"
    
}
}

else if ("`over'"!="") {

qui levelsof `over', local(groups)

local j = 1
foreach g of local groups{
local estat_wboot_g`g' `e(estat_wboot_g`g')' 
mat nleads_g`g'     = e(leads_g`j')
mat nlags_g`g'      = e(lags_g`j')
local ++j
}

_Na_Me_Gr `str_groups', over(`over')
local k = 1
foreach g of local groups{
 local name_g`g' "`s(name_g`k')'"
 local ++k
}

foreach g of local groups{

if "`subcmd'"=="leads" {
    
    mat n_leads_g`g' = nleads_g`g'[.,"Lead"]
    *preserve
    svmat n_leads_g`g', names(n_leads_g`g')
    qui drop if -n_leads_g`g'1==`baseline'
    qui levelsof n_leads_g`g', local(n_leads_g`g')
    *restore
    
    local list_leads_g`g'
    foreach n of local n_leads_g`g' {
	local list_leads_g`g' `list_leads_g`g'' lead`n' 
    }
    
    if strmatch(`"`rest'"', "*wboot*")==1{
	qui `estat_wboot_g`g''
    qui boottest `list_leads_g`g'', `opts' 
    }
    
    else{
	qui estimates restore est_g`g'
	qui test `list_leads_g`g'', `opts' 	
    }
    
    local F_leads_g`g'    = r(F)
    local p_leads_g`g'    = r(p)
    local df_leads_g`g'   = r(df)
    local df_r_leads_g`g' = r(df_r)
    
    if strmatch(`"`rest'"', "*wboot*")==1{
        dis "{col 40}"
    }
    dis "{col 40}"
    dis "Joint significance test for leads - `over_var'=`name_g`g''"
    dis "{hline 40}"
    dis "F-stat:{col 25}" %9.4f `F_leads_g`g''
    dis "P-value:{col 25}" %9.4f `p_leads_g`g''
    dis "{hline 40}"
    dis "Degrees of freedom" "{col 27}(`df_leads_g`g'',`df_r_leads_g`g'')"
    dis "{hline 40}"
} 

else if "`subcmd'"=="lags" {
    
    mat n_lags_g`g' = nlags_g`g'[.,"Lag"]
    *preserve
    svmat n_lags_g`g', names(n_lags_g`g')
    qui drop if n_lags_g`g'1==`baseline'
    qui levelsof n_lags_g`g', local(n_lags_g`g')
    *restore
    
    local list_lags_g`g'
    foreach n of local n_lags_g`g' {
	local list_lags_g`g' `list_lags_g`g'' lag`n' 
    }
    
    if strmatch(`"`rest'"', "*wboot*")==1{
	qui `estat_wboot_g`g''
    qui boottest `list_lags_g`g'', `opts' 
    }
    
    else{
	qui estimates restore est_g`g'
    qui test `list_lags_g`g'', `opts'
    }
    
    local F_lags_g`g'    = r(F)
    local p_lags_g`g'    = r(p)
    local df_lags_g`g'   = r(df)
    local df_r_lags_g`g' = r(df_r)	
    
    if strmatch(`"`rest'"', "*wboot*")==1{
        dis "{col 40}"
    }
    dis "{col 40}"
    dis "Joint significance test for lags - `over_var'=`name_g`g''"
    dis "{hline 40}"
    dis "F-stat:{col 25}" %9.4f `F_lags_g`g''
    dis "P-value:{col 25}" %9.4f `p_lags_g`g''
    dis "{hline 40}"
    dis "Degrees of freedom" "{col 27}(`df_lags_g`g'',`df_r_lags_g`g'')"
    dis "{hline 40}"
} 

else if "`subcmd'"=="eventdd" {
    
    ***LEADS***
    mat n_leads_g`g' = nleads_g`g'[.,"Lead"]
    *preserve
    svmat n_leads_g`g', names(n_leads_g`g')
    qui drop if -n_leads_g`g'1==`baseline'
    qui levelsof n_leads_g`g', local(n_leads_g`g')
    *restore
    
    local list_leads_g`g'
    foreach n of local n_leads_g`g' {
	local list_leads_g`g' `list_leads_g`g'' lead`n' 
    }
    
    if strmatch(`"`rest'"', "*wboot*")==1{
	qui `estat_wboot_g`g''
    qui boottest `list_leads_g`g'', `opts' 
    }
    
    else{
	qui estimates restore est_g`g'
	qui test `list_leads_g`g'', `opts' 	
    }
    
    local F_leads_g`g'    = r(F)
    local p_leads_g`g'    = r(p)
    local df_leads_g`g'   = r(df)
    local df_r_leads_g`g' = r(df_r)
    
    ***LAGS***
    mat n_lags_g`g' = nlags_g`g'[.,"Lag"]
    *preserve
    svmat n_lags_g`g', names(n_lags_g`g')
    qui drop if n_lags_g`g'1==`baseline'
    qui levelsof n_lags_g`g', local(n_lags_g`g')
    *restore
    
    local list_lags_g`g'
    foreach n of local n_lags_g`g' {
	local list_lags_g`g' `list_lags_g`g'' lag`n' 
    }
    
    if strmatch(`"`rest'"', "*wboot*")==1{
	qui `estat_wboot_g`g''
    qui boottest `list_lags_g`g'', `opts' 
    }
    
    else{
	qui estimates restore est_g`g'
    qui test `list_lags_g`g'', `opts'
    }
    
    local F_lags_g`g'    = r(F)
    local p_lags_g`g'    = r(p)
    local df_lags_g`g'   = r(df)
    local df_r_lags_g`g' = r(df_r)
    
    if strmatch(`"`rest'"', "*wboot*")==1{
        dis "{col 40}"
    }
    dis "{col 40}"
    dis _col(7)"Joint significance test for"
    dis _col(7)"leads and lags  - `over_var'=`name_g`g''"
    dis "{hline 40}"
	dis _col(17)"LEADS"
    dis "{hline 40}"
    dis "F-stat:{col 25}" %9.4f `F_leads_g`g''
    dis "P-value:{col 25}" %9.4f `p_leads_g`g''
    dis "Degrees of freedom" "{col 27}(`df_leads_g`g'',`df_r_leads_g`g'')"
    dis "{hline 40}"
    dis _col(18)"LAGS"
    dis "{hline 40}"
    dis "F-stat:{col 25}" %9.4f `F_lags_g`g''
    dis "P-value:{col 25}" %9.4f `p_lags_g`g''
    dis "Degrees of freedom" "{col 27}(`df_lags_g`g'',`df_r_lags_g`g'')"
    dis "{hline 40}"
    
}
}
}

ereturn local  cmd         "eventdd3_estat"
ereturn local  estat_cmd   "eventdd3_estat"

if strmatch(`"`rest'"', "*wboot*")==1 {
ereturn local  keepdummies "keepdummies"
}

ereturn scalar baseline=`baseline'

if ("`over'"=="") {
ereturn local  estat_wboot "`estat_wboot'"
ereturn matrix lags  nlags
ereturn matrix leads nleads
}

else if ("`over'"!="") {
ereturn local over "`over_var'"

local i = 1
foreach g of local groups{
ereturn local  estat_wboot_g`g' "`estat_wboot_g`g''"
ereturn matrix lags_g`i'  nlags_g`g'
ereturn matrix leads_g`i' nleads_g`g'
local ++i
 }
}

restore

end

*-------------------------------------------------------------------------------
*--- Subroutines
*------------------------------------------------------------------------------- 

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
