* trackA_T400_scen6to9.do
* Track A (head-to-head, correctly-specified): T=100, scenarios 6-9.
* Run this file independently/in parallel with the other 7 runner files.
* Output is saved to a HARDCODED path so each parallel run is self-contained.

clear all
set more off

*--- fixed design elements -------------------------------------------------
local reps        2000
local intercept   .10
local cv          .05
local pretrend    0
local step1       0
local trtlist     "0 25 50 100"		// posttrend1 percentages
local baseseed    320000				// distinct block per file

local T           400
local trp = `T'/2

*--- scenario definitions (lag, rho1, rho2, rho3) ---------------------------
* scenario 6: AR2 high persistent
* scenario 7: AR3 mild positive
* scenario 8: AR3 oscillatory
* scenario 9: AR3 high persistent
local lag6 2
local rho1_6 0.7
local rho2_6 0.2
local lag7 3
local rho1_7 0.4
local rho2_7 0.2
local rho3_7 0.1
local lag8 3
local rho1_8 0.7
local rho2_8 -0.3
local rho3_8 0.15
local lag9 3
local rho1_9 0.6
local rho2_9 0.25
local rho3_9 0.1

*--- output (hardcoded path, not a local-only convenience) -----------------
tempname mc
postfile `mc' T scen lag trendpct rep b_post_true				///
              conv_betark b_betark se_betark					///
              conv_glm b_glm se_glm							///
              using "C:\Users\Ariel\Desktop\ITSA_stuff\Beta regression\trackA_T400_scen6to9.dta", replace

forvalues s = 6/9 {

	local lag = `lag`s''
	local rho1opt = "rho1(`rho1_`s'')"
	local rho2opt = ""
	local rho3opt = ""
	if `lag' >= 2 local rho2opt = "rho2(`rho2_`s'')"
	if `lag' >= 3 local rho3opt = "rho3(`rho3_`s'')"

	foreach trt of local trtlist {

		di as txt _newline "T=`T' scenario=`s' lag=`lag' trend=`trt'%: running `reps' reps"
		_dots 0 0

		forvalues r = 1/`reps' {

			local thisseed = `baseseed' + `s'*10000 + `trt'*100 + `r'

			quietly betarkdgp, ntime(`T') trperiod1(`trp') intercept(`intercept')	///
				pretrend(`pretrend') step1(`step1') posttrend1(`trt')				///
				cv(`cv') `rho1opt' `rho2opt' `rho3opt' seed(`thisseed')

			local b_post_true = r(b_post1) - r(b_pre)

			quietly tsset t

			betarksimfit, trperiod1(`trp') lagbetark(`lag') lagglm(`lag')

			local failed = (r(conv_betark) == 0 & r(conv_glm) == 0)
			_dots `r' `failed'

			post `mc' (`T') (`s') (`lag') (`trt') (`r') (`b_post_true')			///
			          (r(conv_betark)) (r(b_betark)) (r(se_betark))		///
			          (r(conv_glm)) (r(b_glm)) (r(se_glm))
		}
	}
}

postclose `mc'

di as txt _newline "Done. Saved to trackA_T400_scen6to9.dta"
