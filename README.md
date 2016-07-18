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
