* trackB_misspecification.do
* Track B (misspecification): betark only, lag() set away from the true AR
* order. "mild positive" scenario at each AR order, all 3 T-levels.

clear all
set more off

local reps        2000
local intercept   .10
local cv          .05
local pretrend    0
local step1       0
local trt         50				// medium trend; misspec affects power/SE most clearly away from the null
local baseseed     400000

local Tlist  "100 200 400"

*--- mild-positive scenarios at each true AR order --------------------------
local truelag1 1
local rho1_1   0.4

local truelag2 2
local rho1_2   0.4
local rho2_2   0.2

local truelag3 3
local rho1_3   0.4
local rho2_3   0.2
local rho3_3   0.1

tempname mc
postfile `mc' T truelag fitlag rep b_post_true				///
              conv_betark b_betark se_betark					///
              using "C:\Users\Ariel\Desktop\ITSA_stuff\Beta regression\trackB_misspecification.dta", replace

foreach T of local Tlist {

	local trp = `T'/2

	forvalues a = 1/3 {

		local truelag = `truelag`a''
		local rho1opt = "rho1(`rho1_`a'')"
		local rho2opt = ""
		local rho3opt = ""
		if `truelag' >= 2 local rho2opt = "rho2(`rho2_`a'')"
		if `truelag' >= 3 local rho3opt = "rho3(`rho3_`a'')"

		* fit lags to try: true order, one under (skipped if truelag=1, since
		* lag must be >=1), and one over
		local overlag = `truelag' + 1
		local fitlaglist "`truelag' `overlag'"
		if `truelag' > 1 {
			local underlag = `truelag' - 1
			local fitlaglist "`underlag' `fitlaglist'"
		}

		foreach fitlag of local fitlaglist {

			di as txt _newline "T=`T' true AR(`truelag') fit lag(`fitlag'): running `reps' reps"
			_dots 0 0

			forvalues r = 1/`reps' {

				local thisseed = `baseseed' + `T'*100 + `truelag'*1000 + `fitlag'*10 + `r'

				quietly betarkdgp, ntime(`T') trperiod1(`trp') intercept(`intercept')	///
					pretrend(`pretrend') step1(`step1') posttrend1(`trt')				///
					cv(`cv') `rho1opt' `rho2opt' `rho3opt' seed(`thisseed')

				local b_post_true = r(b_post1) - r(b_pre)

				quietly tsset t

				betarksimfit, trperiod1(`trp') lagbetark(`fitlag') noglm

				local failed = (r(conv_betark) == 0)
				_dots `r' `failed'

				post `mc' (`T') (`truelag') (`fitlag') (`r') (`b_post_true')	///
				          (r(conv_betark)) (r(b_betark)) (r(se_betark))
			}
		}
	}
}

postclose `mc'

di as txt _newline "Done. Saved to trackB_misspecification.dta"
