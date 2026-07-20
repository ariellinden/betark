* trackA_T100_scen1to5.do
* Track A (head-to-head, correctly-specified): T=100, scenarios 1-5.
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
local baseseed    110000				// distinct block per file

local T           100
local trp = `T'/2

*--- scenario definitions (lag, rho1, rho2, rho3) ---------------------------
* scenario 1: AR1 mild positive
* scenario 2: AR1 oscillatory
* scenario 3: AR1 high persistent
* scenario 4: AR2 mild positive
* scenario 5: AR2 oscillatory
local lag1 1
local rho1_1  0.4
local lag2 1
local rho1_2 -0.4
local lag3 1
local rho1_3  0.7
local lag4 2
local rho1_4 0.4
local rho2_4 0.2
local lag5 2
local rho1_5 0.5
local rho2_5 -0.4

*--- output (hardcoded path, not a local-only convenience) -----------------
tempname mc
postfile `mc' T scen lag trendpct rep b_post_true				///
              conv_betark b_betark se_betark					///
              conv_glm b_glm se_glm							///
              using "C:\Users\Ariel\Desktop\ITSA_stuff\Beta regression\trackA_T100_scen1to5.dta", replace

forvalues s = 1/5 {

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

di as txt _newline "Done. Saved to trackA_T100_scen1to5.dta"
