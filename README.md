# growing-up

For the manuscript titled:

## A distinct growth physiology enhances bacterial growth under rapid nutrient fluctuations




## TABLE OF CONTENTS
1. Image analysis & processing pipeline
2. Main figures
3. Supplementary figures & tables
4. Acknowledging open source code




## 1. IMAGE ANALYSIS & PROCESSING PIPELINE

To extract a functional dataset from raw .nd2 files: 

1. ND2Proc_XY.m
	- identifies and tracks particles from raw .nd2 image files 
	- acknowledgment: this script is largely the work of Vicente Fernandez and Jeff Guasto
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

Scripts used to generate each Main Text Figure are organized within Figure specific folder:

## Figure 1
1. 1c  normalized fluorescein signal from cell imaging position
2. 1d  tiff files of raw images
 

## Figure 2
1. 2b  example of instantaneous growth rate over time (one replicate)
2. 2c  mean growth rate as a function of the nutrient period (each replicate fluctuating timescale plotted)


## Figure 3
1. 3a  monod curve of mean growth rate vs. nutrient concentration (each replicate of each condition)
2. 3c  percent change in mean growth rate from expected (fluc vs control)


## Figure 4
1. 4a,c uses visualizeGrowthRate.m script on single upshift and downshift experiment
2. 4b   visualize growth rate responses of steady vs fluc grown cells to identical nutrient upshifts
		- upshift and downshift responses are visualized with different scripts as labeled
3. 4d,e quantify responses of steady vs fluc grown cells to identical nutrient upshifts
		- upshift and downshift responses are visualized with different scripts as labeled
4. 4f  compare change in growth rate within 7.5 min shift from steady vs fluc grown cells
		- upshift and downshift responses are visualized with different scripts as labeled


## Figure 5
1. 5a,b responses to successive nutrient periods to visualize adaptation


## Figure 6
1. 6b  measured and expected mean growth rates as a function of timescale
	   uses data structure from 3A and growth rate signals from 5A to plot measured and hypothetical time-averaged growth rates as a function of nutrient timescale
2. three .mat data files used to generate 6b, also available in Source_data





## SUPPLEMENTARY FIGURES & TABLES

Scripts used to generate Supplementary Figures are within folder titled "Supplementary_figures".
One exception are visualizations of growth rate vs time, which use visualizeGrowthRate.m (see above)
Other exceptions are noted below.


S2. Nutrient concentration is determinant of growth rate.
	c  v25_S2c_poly_lysine_challenge.m 

S3. Characterization of generated nutrient signal with fluorescent indicator.
	See script in "Source_code" folder titled "calculateFluoresceinSignal.m"

S4. Growth rate does not vary across length of channel.
	v25_S4_growthRate_across_channel.m

S5. Characterization of growth conditions.
	b   v25_S5b_monodCurve.m
	c,d v25_S5c_d_taheri_comparison.m

S6. Metabolomics analysis from batch samples.
	Acknowledgment: Sammy Pontrelli performed this data visualization.
	Raw data is in the main folder titled "TableS6_metabolomics_intensities.xlsx" as well as on massIVE under the accession code MSV000087096. 

S7. Noise in single-cell growth rate.
	a,b v25_S7_single_cell_growthrate.m
	c   See script in "calculations" folder titled "quantifyNoise.m"

S8. Cell division in fluctuations.
	a-d v25_S8_alt_hypothesis.m
	e   v25_S8_division_time_distributions.m

S9. Nutrient shift frequency and implications.
	a   v25_S9_percent_timesteps_with_shift.m



Values in most Supplementary Tables are from the above scripts. Those from other calculations are listed below:

T1. Lag time calculations
    Correct for lag between signal generation and arrival at cell position using script "calculateLag.m", found in the Source_code/growing-up folder

T3. Yield estimation
	Estimate difference between fluc and steady ave environment with "estimateYield.m" in "calculations" folder

T8. Correlations between experiments performed on the same day (different nutrient conditions)
	T8_correlations_between_same_day_G.m in Supplementary_figures folder





## SOURCE SCRIPTS FROM THE INTERWEB

We acknowledge the following open source functions, which are used in the above scripts:

1. Shaded Error Bars by Rob Campbell
https://www.mathworks.com/matlabcentral/fileexchange/26311-raacampbell-shadederrorbar

2. RBG Color Picker by Kristjan Jonasson
https://www.mathworks.com/matlabcentral/fileexchange/24497-rgb-triple-of-color-name-version-2?focused=5124709&tab=function


