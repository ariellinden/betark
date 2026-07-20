* applied_example.do
* Illustrative example for the betark paper: prediabetes disease management
* program, single practice, proportion of patients with fasting glucose
* >= 100 mg/dL, daily, T=300, intervention at day 150.
*
* Three datasets generated from the SAME seed, differing only in AR order
* (high-persistent autocorrelation, matching Scenario 3 of the primary
* simulation). Both betark and glm+HAC(nwest) fit to each, with the lag/
* HAC bandwidth matched to the true AR order.
*
* Run this and paste the full output back - the results populate
* Table tab:applied (the slope-change coefficient by AR order and method)
* in the paper.

clear all
set more off

local ntime      300
local trperiod1  150
local intercept  .35
local pretrend   10
local step1      0
local posttrend1 -15
local cv         .05
local seed       77777

di as txt _newline(2) "{hline 70}"
di as txt "AR(1): rho = 0.7"
di as txt "{hline 70}"

quietly betarkdgp, ntime(`ntime') trperiod1(`trperiod1') intercept(`intercept')	///
	pretrend(`pretrend') step1(`step1') posttrend1(`posttrend1') cv(`cv')		///
	rho1(0.7) seed(`seed')
quietly tsset t

di as txt _newline "--- betark, lag(1) ---"
betark y t _x150 _x_t150, lag(1)

di as txt _newline "--- glm + HAC(nwest 1) ---"
glm y t _x150 _x_t150, family(binomial) link(logit) vce(hac nwest 1)


di as txt _newline(2) "{hline 70}"
di as txt "AR(2): rho = (0.7, 0.2)"
di as txt "{hline 70}"

quietly betarkdgp, ntime(`ntime') trperiod1(`trperiod1') intercept(`intercept')	///
	pretrend(`pretrend') step1(`step1') posttrend1(`posttrend1') cv(`cv')		///
	rho1(0.7) rho2(0.2) seed(`seed')
quietly tsset t

di as txt _newline "--- betark, lag(2) ---"
betark y t _x150 _x_t150, lag(2)

di as txt _newline "--- glm + HAC(nwest 2) ---"
glm y t _x150 _x_t150, family(binomial) link(logit) vce(hac nwest 2)


di as txt _newline(2) "{hline 70}"
di as txt "AR(3): rho = (0.6, 0.25, 0.1)"
di as txt "{hline 70}"

quietly betarkdgp, ntime(`ntime') trperiod1(`trperiod1') intercept(`intercept')	///
	pretrend(`pretrend') step1(`step1') posttrend1(`posttrend1') cv(`cv')		///
	rho1(0.6) rho2(0.25) rho3(0.1) seed(`seed')
quietly tsset t

di as txt _newline "--- betark, lag(3) ---"
betark y t _x150 _x_t150, lag(3)

di as txt _newline "--- glm + HAC(nwest 3) ---"
glm y t _x150 _x_t150, family(binomial) link(logit) vce(hac nwest 3)

di as txt _newline(2) "Done. The coefficient on _x_t150 in each model is the"
di as txt "slope-change (beta_3) estimate for Table tab:applied."
