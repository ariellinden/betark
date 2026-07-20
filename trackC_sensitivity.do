* trackC_sensitivity.do
* Track C (sensitivity): varies intercept, pretrend, and posttrend1, holding
* AR structure (AR(1), rho=0.4, "mild positive") and T (200) fixed, to check
* whether the main grid's findings (built around intercept=.10, flat
* pretrend) generalize. betark vs glm+HAC(nwest 1).

clear all
set more off

local reps        2000
local cv          .05
local step1       0
local baseseed    500000

local T    200
local trp = `T'/2
local lag  1
local rho1opt "rho1(0.4)"

local interceptlist "0.05 0.10 0.30 0.50"
local pretrendlist  "0 25 -25"
local trtlist       "0 50"		// null (Type I/coverage) and medium (power/bias)

tempname mc
postfile `mc' intercept pretrendpct trendpct rep b_post_true		///
              conv_betark b_betark se_betark						///
              conv_glm b_glm se_glm								///
              using "C:\Users\Ariel\Desktop\ITSA_stuff\Beta regression\trackC_sensitivity.dta", replace

foreach icpt of local interceptlist {
	foreach pretr of local pretrendlist {
		foreach trt of local trtlist {

			di as txt _newline "intercept=`icpt' pretrend=`pretr'% trend=`trt'%: running `reps' reps"
			_dots 0 0

			forvalues r = 1/`reps' {

				// scale seed components to integers (icpt has 2 decimals,
				// pretr can be negative) to keep seeds unique and positive
				local icpt100 = round(`icpt'*100)
				local thisseed = `baseseed' + `icpt100'*100000 + (`pretr'+25)*1000 + `trt'*10 + `r'

				quietly betarkdgp, ntime(`T') trperiod1(`trp') intercept(`icpt')	///
					pretrend(`pretr') step1(`step1') posttrend1(`trt')				///
					cv(`cv') `rho1opt' seed(`thisseed')

				local b_post_true = r(b_post1) - r(b_pre)

				quietly tsset t

				betarksimfit, trperiod1(`trp') lagbetark(`lag') lagglm(`lag')

				local failed = (r(conv_betark) == 0 & r(conv_glm) == 0)
				_dots `r' `failed'

				post `mc' (`icpt') (`pretr') (`trt') (`r') (`b_post_true')	///
				          (r(conv_betark)) (r(b_betark)) (r(se_betark))	///
				          (r(conv_glm)) (r(b_glm)) (r(se_glm))
			}
		}
	}
}

postclose `mc'

di as txt _newline "Done. Saved to trackC_sensitivity.dta"
