%% figure 4 - expected growth rates


% Output: plot of time-averaged growth rate vs nutrient timescale

% Input: (1) data structure from figure 3A, growthRates_monod_curve,
%        (2) meta data structure of all experiments
%        (3) growth rate vs time data from single up- and downshifts


%        (1) fluctuating experiment data
%        contains summary stats from each condition of each experiment
%
%        (2) meta data
%        psuedo-manually compiled structure, storedMetaData.mat
%        structure helps ensure corrent sorting of growthRates_monod_curve data
%
%        (3) single shift data
%        upshift data: average signal between two replicates
%        downshift data: only one replicate reaches G_low, uses this signal
%        uses signal until calculated stabililzation time from figure 5,
%        after this stabilization, use G_low or G_high to simulate growth
%        rate for the rest of the low or high nutrient phase



%        this code is written as if all experiment files (.mat, containing D5
%        and T) and meta data file were in the same folder



% Strategy: three parts A, B and C
%
%       0. initialize complete meta data
%       0. initialize experiment data
%       1. for each experiment, collect G_fluc, G_low, G_ave, and G_high
%       2. calculate mean G_low, G_ave, G_high and G_jensens across all data
%       3. calculate mean G_fluc for each fluctuating timescale
%       4. plot G_data by timescale, with the following normalizations:
%               i. none
%              ii. normalized by G_monod
%             iii. normalized by G_jensens
%       5. display raw values of G_ave, G_jensens, G_fluc, G_high and G_low



% Last edit: jen, 2019 Feb 6

% Commit: in progress, adding hypotheticals


% OK let's go!

%% initialize


clear
clc


% 0. initialize complete meta data
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')
exptArray = [2:4,5:7,9,10,11,12,13,14,15]; % list experiments by index


% 0. initialize experiment data
cd('/Users/jen/Documents/StockerLab/Writing/manuscript 1/figure3')
load('growthRates_monod_curve.mat')
dataIndex = find(~cellfun(@isempty,growthRates_monod_curve));
experimentCount = length(dataIndex);


%% B. Assemble measured data according to timescale or boundary conditions

% 1. for each experiment, collect values of G_low and G_high
counter = 0;
for e = 1:length(exptArray)
    
    % identify experiment by date
    index = exptArray(e);
    date = storedMetaData{index}.date;
    timescale = storedMetaData{index}.timescale;
    
    disp(strcat(date, ': collecting data!'))
    counter = counter + 1;
    
    % collect growth rate data
    fluc = 1;
    low = 2;
    ave = 3;
    high = 4;
    
    flucRates(counter,fluc) = growthRates_monod_curve{index}{1,fluc}.mean;%/log(2);
    stableRates(counter,low) = growthRates_monod_curve{index}{1,low}.mean;%/log(2);
    stableRates(counter,ave) = growthRates_monod_curve{index}{1,ave}.mean;%/log(2);
    stableRates(counter,high) = growthRates_monod_curve{index}{1,high}.mean;%/log(2);
    
    timescales_perG(counter) = timescale;
    dates_perG{counter} = date;
    

   
end



% 2. calculate mean G_low, G_ave, G_high and G_jensens across all data
stableRates_mean = nanmean(stableRates);
stableRates_std = nanstd(stableRates);
G_jensens = (stableRates_mean(high) + stableRates_mean(low))/2;
G_monod = stableRates_mean(ave);



% 3. calculate mean G_fluc for each fluctuating timescale
t30 = 1;
t300 = 2;
t900 = 3;
t3600 = 4;

Gfluc_means(t30) = mean(flucRates(timescales_perG==30));
Gfluc_means(t300) = mean(flucRates(timescales_perG==300));
Gfluc_means(t900) = mean(flucRates(timescales_perG==900));
Gfluc_means(t3600) = mean(flucRates(timescales_perG==3600));

Gfluc_std(t30) = std(flucRates(timescales_perG==30));
Gfluc_std(t300) = std(flucRates(timescales_perG==300));
Gfluc_std(t900) = std(flucRates(timescales_perG==900));
Gfluc_std(t3600) = std(flucRates(timescales_perG==3600));



% 4. plot G_data by timescale
% raw values
figure(2)
plot([1 2 3 4],Gfluc_means,'o','Color',rgb('DarkTurquoise'),'MarkerSize',10,'LineWidth',2);
hold on
errorbar([1 2 3 4],Gfluc_means,Gfluc_std,'Color',rgb('DarkTurquoise'));
hold on
plot(-1, G_monod,'o','Color',rgb('DarkCyan'),'MarkerSize',10,'LineWidth',2);
hold on
errorbar(-1,G_monod,stableRates_std(ave),'Color',rgb('DarkCyan'),'LineWidth',2);
hold on
plot(6, G_jensens,'o','Color',rgb('SlateGray'),'MarkerSize',10,'LineWidth',2)
hold on
axis([-1 6 0 4])
title('growth expectations')
xlabel('fluctuating timescale')
ylabel('mean growth rate (1/hr)') % growth rate = d(logV)/(dt*ln(2))



% normalized by G_jensens
figure(3)
plot([1 2 3 4],Gfluc_means./G_jensens,'o','Color',rgb('DarkTurquoise'),'MarkerSize',10,'LineWidth',2);
hold on
errorbar([1 2 3 4],Gfluc_means./G_jensens,Gfluc_std./G_jensens,'Color',rgb('DarkTurquoise'));
hold on
plot(-1, G_monod/G_jensens,'o','Color',rgb('DarkCyan'),'MarkerSize',10,'LineWidth',2);
hold on
errorbar(-1,G_monod/G_jensens,stableRates_std(ave)./G_jensens,'Color',rgb('DarkCyan'),'LineWidth',2);
hold on
plot(6, G_jensens/G_jensens,'o','Color',rgb('SlateGray'),'MarkerSize',10,'LineWidth',2)

axis([-1 6 0.3 1.5])
title('growth, relative to Jensens expectations')
xlabel('fluctuating timescale')
ylabel('mean growth rate, normalized by G_jensens') % growth rate = d(logV)/(dt*ln(2))



% growth rate normalized by initial vol, normalized by G_monod
figure(4)
plot([1 2 3 4],Gfluc_means./G_monod,'o','Color',rgb('DarkTurquoise'),'MarkerSize',10,'LineWidth',2);
hold on
errorbar([1 2 3 4],Gfluc_means./G_monod, Gfluc_std./G_monod,'Color',rgb('DarkTurquoise'));
hold on
plot(-1,G_monod./G_monod,'o','Color',rgb('DarkCyan'),'MarkerSize',10,'LineWidth',2);
hold on
errorbar(-1,G_monod./G_monod,stableRates_std(ave)./G_monod,'Color',rgb('DarkCyan'),'LineWidth',2);
hold on
plot(6, G_jensens./G_monod,'o','Color',rgb('SlateGray'),'MarkerSize',10,'LineWidth',2)

axis([-1 6 0.25 1.25])
title('growth, relative to average nutrient concentration')
xlabel('fluctuating timescale')
ylabel('mean growth rate, normalized by G_monod)') % growth rate = d(logV)/(dt*ln(2))


% 5. display raw values of G_ave, G_jensens, G_fluc, G_high and G_low
G_monod
G_jensens
Gfluc_means
Gfluc_std
G_high = stableRates_mean(high)
G_low = stableRates_mean(low)


clear fluc low ave high counter index
clear e experimentCount t30 t300 t900 t3600

%% C. Calculate hypothetical time-averaged growth rates from single shift data









%% D. Add hypothetical data to timescale plot