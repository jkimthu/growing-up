% figure S5b: Monod curve

%  Output: time-averaged growth rate vs nutrient concentration
%          overlays data from:
%               
%            1. 2017-09-26 monod experiment (6 concentrations)  (mean, s.e.m.) 
%            2. mean & st dev of replicates of steady high, ave, low   
%            3. mean & st dev of replicates of fluctuating nutrient


%  Input:   hard coded means and error,
%           measured and stored in fig3A_monodCurve.m as data matrix,
%           growthRates_monod_curve.mat 

%           1. monod data
%           only one replicate performed.
%           mean is calculated as time-averaged growth rate after 3 h
%           error reported is standard error of the mean.       

%           2. steady low, ave, high data
%           between 11-13 replicates per condition.
%           mean is the mean time-averaged growth rates across replicates.
%           error is standard deviation between replicates.

%           3. fluctuating data
%           between 3-4 replicates per condition.
%           mean is the mean time-averaged growth rates across replicates.
%           error is standard deviation between replicates.


% Last edit: jen, 2021 Mar 29
% Commit: final version for Supplementary Fig. 5b


% OK let's go!

%% 

monod_c = [1/10000; 1/1000; 1/100; 1/32; 1/8; 1];
monod_means = [0.1446; 1.2622; 2.3748; 3.1924; 3.6411; 3.8443];
monod_sems = [0.0057; 0.0042; 0.0057; 0.0086; 0.0170; 0.0960];

steady_c = [1/1000; 1/95; 1/50];
steady_means = [1.07; 2.31; 2.86];
steady_stds = [0.23; 0.18; 0.14];

fluc_c = [1/95; 1/95; 1/95; 1/95];
fluc_means = [1.93; 1.53; 1.15; 1.15]; % 30 sec, 5 min, 15 min, 60 min
fluc_stds = [0.16; 0.20; 0.28; 0.13];


figure(1) % plot monod
errorbar(monod_c, monod_means, monod_sems,'Marker','o','MarkerSize',10,'Color',rgb('SlateGray'));
hold on
ylabel('growth rate (1/hr)')
xlabel('fraction LB')
axis([-0.01,0.15,0,4])


figure(1) % overlay steady replicates
hold on
errorbar(steady_c, steady_means, steady_stds,'Marker','o','MarkerSize',10,'Color',rgb('Teal'));


figure(1) % over lay fluctuating replicates
colors_fluc = {'Crimson','GoldenRod','SeaGreen','BlueViolet'};
for f = 1:length(fluc_c)
    hold on
    errorbar(fluc_c(f), fluc_means(f), fluc_stds(f),'Marker','o','MarkerSize',10,'Color',rgb(colors_fluc{f}));  
end

legend('steady','steady low, ave, high','fluc30','fluc300','fluc900','fluc3600')