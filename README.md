# growing-up
Peering into the mysterious nature of (bacterial) life




GENERAL PIPELINE

To extract a functiona dataset from raw .nd2 files:

1. Particle identification and tracking with...           ND2Proc_XY.m
2. Quality control with...                                dataTrimmer.m
3. Calculate elongation rates with...                     slidingFits.m
4. View growth rate over time with...                     seeingMus.m

The remaining scripts each strive to visualize the data (growth rate or other parameters) in unique ways.
Enjoy!




SOURCE SCRIPTS FROM THE INTERWEB

Not everything was written in house. Here the Mathworks links to functions used in these scripts (primarily for plotting) that were contributed by others.

1. Shaded Error Bars by Rob Campbell
https://www.mathworks.com/matlabcentral/fileexchange/26311-raacampbell-shadederrorbar

2. RBG Color Picker by Kristjan Jonasson
https://www.mathworks.com/matlabcentral/fileexchange/24497-rgb-triple-of-color-name-version-2?focused=5124709&tab=function




SCRIPTS OF FINALIZED PLOTS FOR PAPER

Fig

1. 1C fluoresceinSignal
plots normalized signal intensities from switching junction and cell imaging position, highlighting the sharpness of generated switches and effectively non-existent decay as the signal travels down the channel.
 

2. 3A monodCurve
generates a data structure of summary stats of each experimental condition for monod curve. this structure, growthRates_monod_curve.mat, contains the values for all numbers in Supplementary table with all the means, standard deviations, etc.


3. 4 expectedGrowth - normalized to mean G_ave of replicates
uses data structure from 3A and growth rate signals from 5A to plot measured and hypothetical time-averaged growth rates as a function of nutrient timescale

4. 4B expectedGrowth - normalized to daily G_ave
uses data structure from 3A and growth rate signals from 5A to plot measured and hypothetical time-averaged growth rates as a function of nutrient timescale

0. Discussion: calculations of yield are found in script estimateYield.m


S7. Growth rate measurements performed on the same day are correlated.
	Positive correlations lead us to normalize by daily Gs!

S10. Percent of timesteps with a nutrient shift


figure 3.
A
B
C relative change in G (between Gfluc and Gave or Gjensens)


figure 4. 
A
B
C

D1
D2
D3 upshift percent change in growth rate from t=0 to t=7.5 min postshift

E1
E2
E3 downshift percent change in growth rate from t=0 to t=7.5 min postshift

F
G  difference in fluc vs single shift growth rate over time
H  growth rate from successive periods, overlaid

