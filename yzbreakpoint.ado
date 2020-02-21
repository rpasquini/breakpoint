*Author: Ricardo Pasquini 
*email: rpasquini@utdt.edu
*Date: 12/7/2017


program randomevector 
    capture drop randomevector
	
	qui gen randomevector=.	
	qui sum evector
	local N=r(N)
	forvalues i= 1/`N' {
	mata:   evector = st_data(., "evector",0)
	mata: 	randomsortedevector=jumble(evector)   /* jumble random reorders evector */
	mata: 	randome=randomsortedevector[1,1]
	mata: 	st_local("ev", strofreal(randome))  /* st_local for taking value from mata to local*/
		
	*di `ev'
	*ojo que aqui estoy guardando la observacion en el lugar en donde hay valores no missing
	qui: replace randomevector=`ev' if countersample==`i'
	}

end


/*Program randomystar generates Y*. It represents the complete step two in the algorithm*/
program randomystar
    capture drop ystar
	randomevector
	qui gen ystar=linearpred+randomevector
end




program define yzidentification , rclass
	syntax [varlist] [if] [, print nbins(real 20) name(string)]
	
	tokenize `varlist'
	local housingexp "`1'"
	local dformal "`2'"
	local income "`3'"
	
	local i = 4	
	macro drop YZCONTROLS
	while "``i''" != "" {
	global YZCONTROLS "$YZCONTROLS `i'"
	local i = `i' + 1
	}
	
	*di "Control: $YZCONTROLS"
	
	* option print sets quietly off in reg commands and other displays
	if "`print'"!="" {
	local silencio
	}
	else {
	local silencio "qui"
	}
	

	qui: sum `income', detail
	* define number of bins to consider
	*di "nbins "`nbins'
	*local nbins=20
	local nbinsm1=`nbins'-1

	local Nobs=r(N)
	local maxv=r(max)
	qui: di "max v"`maxv'  /*habilitar esta linea*/
	local minv=r(min)
	local range=`maxv'-`minv'
	local rangelength=`range'/`nbins'

	* candidate yzs will be stored in the variable binsincome
	capture drop binsincome
	qui: gen binsincome=.
	local bini=`minv'+`rangelength'
	forvalues i = 1/`nbinsm1'{

	qui: replace binsincome=`bini' in `i'
	local bini=`bini'+`rangelength'

	}


	qui: capture drop ftests
	qui: gen ftests=.

	* store number of observation above and below in obsabove obsbelow
	qui: capture drop obsabove obsbelow  pobsabove pobsbelow 
	qui: gen obsabove=.
	qui: gen obsbelow=.
	qui: gen pobsabove=.
	qui: gen pobsbelow=.

	forvalues i = 1/`nbinsm1'{
		qui: sum binsincome in `i'
		local dzvalue=r(mean)
		qui: sum  `income' if `income'>`dzvalue'
		qui: replace obsabove=r(N) in `i'
		qui: replace pobsabove=r(N)/`Nobs' in `i'

		qui: sum  `income' if `income'<`dzvalue'
		qui: replace obsbelow=r(N) in `i'
		qui: replace pobsbelow=r(N)/`Nobs' in `i'
	}




	* Identification Loop *****************
	qui: capture drop checkobs
	qui: gen checkobs=.
	label variable checkobs "observation included"
	qui: capture label define checkobs 1 "Yes"
	label values checkobs checkobs 
	
	forvalues i=1/`nbinsm1' {

	local dzvalue = binsincome[`i']
	local obsbelow = obsbelow[`i']
	local pobsbelow = pobsbelow[`i']
	local obsabove = obsabove[`i']
	local pobsabove = pobsabove[`i']

	* Solo correr el test si cumplo los requerimientos minimos
	if `obsbelow'>=20 & `obsabove'>=20 & `pobsbelow'>=0.15 & `pobsabove'>=0.15 {
	
	
	* HABILITAR PROXIMA LINEA PARA VER DETALLES
	`silencio' di "bin: "`i' " yz candidate: " `dzvalue'
	qui: replace checkobs=1 in `i'
	
	*di "now generating DZ"
	*di "income `income'"

	qui: gen DZ=0
	qui: replace DZ=1 if `income'>`dzvalue'
	qui: replace DZ=. if `income'==.
	
	qui: gen DZinteract=.
	qui: replace DZinteract=`income'*DZ

	 *sum DZ DZinteract
	
	****HERE COMES THE TEST
	`silencio' di "reg `housingexp' `dformal' DZ DZinteract"
	`silencio' reg `housingexp' `dformal' DZ DZinteract $YZCONTROLS `if'
	qui: test  (DZ=0) (DZinteract=0)
	*test  (DZ=0) (DZinteract=0), coef
	*return list
	qui: replace ftests=r(F) in `i'

	drop DZ DZinteract

	}
	}
	
	
	***Busco el maximo
	capture drop obsn
	qui: gen long obsn = _n 
	
	qui: sum ftest    /* analizo los tests en busca del maximo*/
	return scalar supF=r(max)
	
	qui: sum obsn if ftest==r(max) /*busco la obs que es maximo*/ 
	local maxposition=r(min)
	
	return scalar Yz=binsincome[`maxposition'] 
	
	*additional stats
	capture drop totalcandidatesconsidered
	qui: egen totalcandidatesconsidered=sum(checkobs)
	qui: sum totalcandidatesconsidered
	local totalcandidatesconsidered=r(mean)
	
	if "`print'"!="" {
		******PRINT RESULTS
		
		noisily: di "***************************************************************"
		noisily: di "Breakpoint identification Results"
		noisily: di "***************************************************************"
			
		noisily: di "Identified Yz: " binsincome[`maxposition']
		noisily: di "Note: values of candidates yz and ftests were stored in variables: binsincome and ftest"
		noisily: di "Position of maximum Yz in database: " `maxposition' 
		noisily: di "Number of candidates (bins) finally considered: " `totalcandidatesconsidered' 

		capture graph drop IdentificationYz
		twoway connected ftests binsincome , name(IdentificationYz) title("SupF distribution `name'")
	}
	
end
	
	
	***********************bootstrap
program yzbootstraptest

	syntax [varlist] [if] ,[  nbins(real 20) biterations(real 200)]
	
	tokenize `varlist'
	local housingexp "`1'"
	local dformal "`2'"
	local income "`3'"
	
	local i = 4	
	macro drop YZCONTROLS
	while "``i''" != "" {
	global YZCONTROLS "$YZCONTROLS `i'"
	local i = `i' + 1
	}
	di "Control: $YZCONTROLS"
	
	qui reg `housingexp' `dformal'  $YZCONTROLS `if'
	capture drop evector linearpred
	qui predict evector, residuals  /* evector contain residuals*/
	qui predict linearpred  if e(sample) /* ystar_hat contain predictions without noise*/
	*keep evector linearpred
	

	capture drop nullmodelsample countersample supB
	qui gen nullmodelsample=e(sample)  /* Need to identify and enumerate the observations that were used in the regression */
	qui gen countersample=sum(nullmodelsample) 
	qui replace countersample=. if evector==.

	qui gen supB=.

	forvalues i= 1/`biterations' {
	*di `i'
	di "." _cont
	randomystar
	yzidentification ystar `dformal' `income' , nbins(`nbins')
	qui replace supB=r(supF) in `i'
	*return list
	}



	****pvalue computation


	qui: sum identifiedSupF
	local identifiedSupF=r(mean)

	*qui: sum identifiedYz
	*local identifiedYz=r(mean)


	noisily: di "*********************"
	noisily: di "Boostrap Test Results"
	noisily: di "*********************"
	noisily: di "Supremum F of identified Yz: " `identifiedSupF'

	capture drop forpvalue
	qui gen forpvalue=0 if supB!=.
	qui replace forpvalue=1  if supB>`identifiedSupF' & supB!=.

	qui: sum forpvalue
	local pvalue=r(mean)

	noisily: di "p-value is: " `pvalue'

	****grafico de la distribucion de supB

	hist supB, addplot(pci 0 `identifiedSupF' .1 `identifiedSupF', legend(order(1 "SupB density" 2 "SupF of identified Yz"))) title("Bootstrap Test")

end



program yzbreakpoint

	syntax [varlist] [if],  [bootstraptest nbins(real 20) biterations(real 200) name(string)]
	
	tokenize `varlist'
	*cleaning locals
	*local controls
	*local housingexp
	*local dformal
	*local income 
	
	local housingexp "`1'"
	local dformal "`2'"
	local income "`3'"
	
	local i = 4	
	macro drop YZCONTROLS
	while "``i''" != "" {
	global YZCONTROLS "$YZCONTROLS `i'"
	local i = `i' + 1
	}
	di "Control: $YZCONTROLS"
	
	*macro shift 1
	*local controls "`*'"
	
	di "yzidentification `housingexp' `dformal' `income' $YZCONTROLS `if', print  nbins(`nbins') "

	yzidentification `housingexp' `dformal' `income' $YZCONTROLS  `if', print  nbins(`nbins') name(`name')
	
	
	if "`bootstraptest'"!="" {
	
	qui gen identifiedSupF=r(supF) in 1
	qui gen identifiedYz=r(Yz) in 1
	
	di "bootstrap iterations: "`biterations'
	yzbootstraptest `housingexp' `dformal' `income'  $YZCONTROLS  `if',   nbins(`nbins') biterations(`biterations')
	

	
	
	}
	
end

