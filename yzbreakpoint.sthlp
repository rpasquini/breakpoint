{smcl}
{* *! version 1.2.1  07mar2013}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "examplehelpfile##syntax"}{...}
{viewerjumpto "Description" "examplehelpfile##description"}{...}
{viewerjumpto "Options" "examplehelpfile##options"}{...}
{viewerjumpto "Remarks" "examplehelpfile##remarks"}{...}
{viewerjumpto "Examples" "examplehelpfile##examples"}{...}
{title:Title}

{phang}
{bf:yzbreakpoint} {hline 2} Identifies a unique breakpoint in the functional form and performs a test


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:yzbreak:point}
{depvar}
dformal
indepvar
[controlvars]
{if}
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt n:bins(#)}} define number of bins on which to identify ys;
	default is {cmd:nbins(20)}{p_end}
{synopt:{opt bootstrap:test}} performs a bootstrap test{p_end}
{synopt:{opth biter:ations(#)}} Number of bootstrap iterations; default is  {cmd:biterations(200)}{p_end}
{synoptline}
{p2colreset}{...}



{marker description}{...}
{title:Description}

{pstd}
{cmd:yzbreakpoint}  Identifies a unique breakpoint (yZ) in the support of {indepvar} for the following model: 

		depvar_i=β_0+β_1*dformal+e  if   if  indepvar<yZ 
		depvar_i=β_0+β_1*dformal+β_2+β_3*indepvar +e  if  indepvar≥yZ
		
		This model corresponds to the housing expenditure equation with land zoning in Heikkila (2016). 
		The algorithm proceeds by evaluating candidate values defined over the bins of {indepvar}.
		bootstrap option performs a test based on H0: β_2=β_3=0, H1: at least one different from 0.
		Notice that depvar, dformal (a dummy variable indefying the formal market in the original model),
		and indepvar (income in the original model) are required. 
		
		

{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt nbins} It allows defining the number of bins where to search for a breakpoint candidate. Default is 20
Bins.  Bins with less than 20 (or 15%) of observations falling below (above) are discarded. 

{phang}
{opt  bootstraptest} Performs a bootstrap test. Without this option the program does not compute the test.

{phang}
{opt biterations(#)} specifies the number of bootstrap iterations. Default is {cmd:biterations(200)}


{marker examples}{...}
{title:Examples}

{phang}{cmd:. yzbreakpoint alquiler bformal ingresohogar}{p_end}

{phang}{cmd:. yzbreakpoint alquiler bformal ingresohogar, bootstraptest nbins(20) biterations(50)}{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
Author: Ricardo Pasquini. Universidad Torcuato Di Tella. Support: email rpasquini@utdt.edu.

