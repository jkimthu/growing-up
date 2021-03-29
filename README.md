# growing-up

For the manuscript titled:

## A distinct growth physiology enhances bacterial growth under rapid nutrient fluctuations


## TABLE OF CONTENTS
1. Image analysis & processing pipeline
2. Main figures
3. Calculations reported in manuscript
4. Supplementary figures




## 1. IMAGE ANALYSIS & PROCESSING PIPELINE

To extract a functional dataset from raw .nd2 files: 

1. ND2Proc_XY.m
	- identifies and tracks particles from raw .nd2 image files 
	- folder: Image_analysis&processing
2. dataTrimmer_revised.m
	- removes erroneous tracked particles to limit dataset to single cells
	- folder: Image_analysis&processing

Visualize tracking parameters and/or growth rate folder titled "visualized_tracking":

3. dynamicOutlines_width.m  
	- overlays an ellipse (from particle tracking) with dif colors based on parameter of interest
	- folder: visualized_tracking
4. calculateGrowthRate.m
	- calculate growth rate in a variety of methods, we used log2 in this study
	- folder: functions
5. visualizeGrowthRate.m
	- plots growth rate over time   
	- folder: main        




## 2. MAIN FIGURES

Scripts used to generate each Figure are organized within Figure specific folder:

## Figure 1
1. 1C  normalized fluorescein signal from cell imaging position
2. 1D  tiff files of raw images
 

## Figure 2
1. 2B  example of instantaneous growth rate over time (one replicate)
2. 2C  mean growth rate as a function of the nutrient period (each replicate fluctuating timescale plotted)
3. 2XY testing the alternative hypothesis that fluctuations in average growth rate are from mixed populations of growing and non-growing cells, rather than changes in growth at the single cell level


## Figure 3
1. 3A  monod curve of mean growth rate vs. nutrient concentration (each replicate of each condition)
2. processed data file: 3A script outputs and plots from .mat file titled growthRates_monod_curve.mat
3. 3C  percent change in mean growth rate from expected (fluc vs control)


## Figure 4
1. 4C  comparing growth rate responses of steady vs fluc grown cells to identical nutrient upshift
2. processed data file: 4C outputs response_flucUpshift.mat and response_singleUpshift.mat
3. 4D  comparing growth rate responses of steady vs fluc grown cells to identical nutrient downshift
4. processed data file: 4C outputs response_flucDownshift.mat and response_singleDownshift.mat


## Figure 5
1. 5   single script for both A & B. responses to successive nutrient periods to visualize adaptation


## Figure 6
1. 6   measured and expected mean growth rates as a function of timescale
	   uses data structure from 3A and growth rate signals from 5A to plot measured and hypothetical time-averaged growth rates as a function of nutrient timescale





## CALCULATIONS REPORTED IN MANUSCRIPT

1. calculations of yield (estimateYield.m)
2. calculations regarding response of growth rate to nutrient shifts (timescale and magnitude of change)
3. calculations quantifying noise in single-cell instantaneous growth rate (quantifyNoise.m)




## SUPPLEMENTARY FIGURES

S3. Characterization of generated nutrient signal with fluorescent indicator.
	See script in "Source_code" folder titled "calculateFluoresceinSignal.m"

S7. Noise in single-cell growth rate.
	See script in "calculations" folder titled "quantifyNoise.m"

S8. Cell division in fluctuations.
	See script in folder titled Supplementary_figures "v23_S8_alt_hypothesis"

S9. Percent of timesteps with a nutrient shift

S10. A) Quantify time between shift and growth rate stabilization 
	 B) Quantify value of stabilized growth rate after shift
	 Note: A&B are analyzed by two scripts, one for upshift responses, one for downshift responses
	 D) Quantify change in growth rate from upshift responses (formerly part of Figure 4)






## SOURCE SCRIPTS FROM THE INTERWEB

Not everything was written in house. Here the Mathworks links to functions used in these scripts (primarily for plotting) that were contributed by others.

1. Shaded Error Bars by Rob Campbell
https://www.mathworks.com/matlabcentral/fileexchange/26311-raacampbell-shadederrorbar

2. RBG Color Picker by Kristjan Jonasson
https://www.mathworks.com/matlabcentral/fileexchange/24497-rgb-triple-of-color-name-version-2?focused=5124709&tab=function


