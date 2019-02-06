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

Figure

1. 3A monodCurve
generates a data structure of summary stats of each experimental condition for monod curve. this structure, growthRates_monod_curve.mat, contains the values for all numbers in Supplementary table with all the means, standard deviations, etc.
