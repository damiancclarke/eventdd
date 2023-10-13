*! eventdd_estat: Estimate panel event study models and generate plots
*! Version 1.0.0 October 30, 2020 @ 18:24:55
*! Author: Damian Clarke & Kathya Tapia Schythe


cap program drop eventdd_estat
program eventdd_estat, eclass
vers 13.0


if ("`e(cmd)'"=="eventdd")+("`e(cmd)'"=="eventdd_estat")==0{
    error 321
}

local estat_wboot `e(estat_wboot)' 
local baseline = e(baseline)
mat nleads     = e(leads)
mat nlags      = e(lags)
gettoken subcmd rest : 0, parse(" ,")
local opts=subinword("`rest'","wboot","",.)
local opts=subinword("`opts'","dropdummies","",.)
local opts=subinword("`opts'",",","",.)

if strmatch(`"`rest'"', "*wboot*")==1 {
    qui `estat_wboot'
}

if "`subcmd'"=="leads" {
    
    mat n_leads = nleads[.,"Lead"]
    preserve
    svmat n_leads, names(n_leads)
    qui drop if -n_leads1==`baseline'
    qui levelsof n_leads, local(n_leads)
    restore
    
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
    preserve
    svmat n_lags, names(n_lags)
    qui drop if n_lags1==`baseline'
    qui levelsof n_lags, local(n_lags)
    restore
    
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
    preserve
    svmat n_leads, names(n_leads)
    qui drop if -n_leads1==`baseline'
    qui levelsof n_leads, local(n_leads)
    restore
    
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
    preserve
    svmat n_lags, names(n_lags)
    qui drop if n_lags1==`baseline'
    qui levelsof n_lags, local(n_lags)
    restore
    
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

ereturn local  cmd         "eventdd_estat"
ereturn local  estat_cmd   "eventdd_estat"
if strmatch(`"`rest'"', "*wboot*")==1 {
ereturn local  keepdummies "keepdummies"
}
ereturn local  estat_wboot "`estat_wboot'"
ereturn scalar baseline=`baseline'
ereturn matrix lags  nlags
ereturn matrix leads nleads

end
