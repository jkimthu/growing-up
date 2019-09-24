%% figure SIX - expected growth rates


% Output: plot of time-averaged growth rate (G) vs nutrient timescale

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



% Strategy: four parts A, B, C and D

%  A. Initialize 
%
%       0. input complete meta data
%       0. input fluctuating experiment data
%       0. input single shift experiment data
%       0. define period lengths for slow calculations of predicted G (12,24,48,96 hours)
%       0. define period lengths for fast calculations of predicted G (30 sec,5,15,60 min)



%  B. Assemble fluctuating data according to timescale or boundary conditions
%
%       1. for each experiment, collect time-averaged growth rates for each condition
%       2. calculate mean and standard dev G_low, G_ave, G_high and G_jensens across all data
%       3. calculate mean and standard dev G_fluc for each fluctuating timescale
%       4. plot G_data by timescale, with the following normalizations:
%               i. none
%              ii. normalized by G_monod
%             iii. normalized by G_jensens
%       5. display raw values of G_ave, G_jensens, G_fluc, G_high and G_low



%  C. Slow calculations of predicted G from single shift data
%
%       0. initialize time to stabilize for both shifts
%          note: these manually set values are calculated means from Figure 5
%                (response quantifications)
%       1. trim growth rate signals to times until stabilized
%       2. trim growth signals to times postshift
%       3. time-average transitions
%       4. calculate time-averaged growth rates during high nutrient phase
%       5. calculate time-averaged growth rates during low nutrient phase
%       6. calculate time-averaged growth rates from entire period



%  D. Add slow predictions to timescale plot



%  E. Fast calculations of predicted G from single shift data
%
%     Method 1: cumulative (upper bound)
%
%       version A. takes into account the experimental observation time into G_cumulative
%       version B. simulates G as if all observation times were 6 h
%
%       0. this method breaks the single shift dynamics into sections each
%          to each half period
%       0. if we extend the "time of observation" to 10 hours,
%          (5 h cumulative in each: C_high and C_low), then both G_low
%          and G_high rates are reached. this estimate will be an
%          upperbound as we assume we can reach G_steady-state and allow
%          for more time than observed in each experiment
%       0. thus, G_cumulative is equal for all timescales
%       1. G_cumulative = (G_up*ts_up + G_down*ts_down + ss_high((OT/2)-ts_up) + ss_low((OT/2)-ts_down))/ OT
%          where,
%          OT = observed time
%          G_up*ts_up = mean growth rate of single upshift transition weighted by time required to reach G_high
%          G_down*ts_down = mean growth rate of single downshift transition weighted by time required to reach G_low
%          ss_high(5-ts_up) = G_high weighted by remaining time in high after reaching steady-state
%          ss_low(5-ts_down) = G_low weigthed by remaining time in low after reaching steady-state


%     Method 2: total restart 
%       0. this method treats each shift as a new start such that longer
%          timescales are going to have higher mean growth rates
%       1. G_restart = (G_up(half period) + G_down(half period))/2
%          where,
%          G_up(half period) = mean growth rate between t = 0 (shift) and half the period length (30 min T = 60)
%          G_down(half period) = same as above but using single downshift data



%  F. Add fast and slow predictions to timescale plot


% Last edit: jen, 2019 September 24
% Commit: normalized by daily G_ave, adding predictions at fast timescales


% OK let's go!

%% A. Initialize


clear
clc


% 0. input complete meta data
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')
exptArray = [2:4,5:7,9,10,11,12,13,14,15]; % list experiments by index


% 0. input fluctuating experiment data
cd('/Users/jen/Documents/StockerLab/Writing/manuscript 1/figures re-worked/Figure 6')
load('growthRates_monod_curve.mat')
dataIndex = find(~cellfun(@isempty,growthRates_monod_curve));


% 0. input single shift experiment data
load('response_singleUpshift.mat')
load('response_singleDownshift.mat')



% 0. define period lengths for hypothetical calculations (period in hours)
periods_slow = [12,24,48,96]; % hours
periods_fast = [30,300,900,3600]; % sec


%% B. Assemble fluctuating data according to timescale or boundary conditions

% 1. for each experiment, collect time-averaged growth rates for each condition
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
    
    flucRates(counter,fluc) = growthRates_monod_curve{index}{1,fluc}.mean;
    stableRates(counter,low) = growthRates_monod_curve{index}{1,low}.mean;
    stableRates(counter,ave) = growthRates_monod_curve{index}{1,ave}.mean;
    stableRates(counter,high) = growthRates_monod_curve{index}{1,high}.mean;
    
    timescales_perG(counter) = timescale;
    dates_perG{counter} = date;
    
end
clear timescale


% 2. calculate mean and standard dev G_low, G_ave, G_high and G_jensens across all data
stableRates_mean = nanmean(stableRates);
stableRates_std = nanstd(stableRates);
G_jensens = (stableRates_mean(high) + stableRates_mean(low))/2;
G_monod = stableRates_mean(ave);



% 3. normalize each G_fluc by it's corresponding G_ave
G_fluc_norm = flucRates./stableRates(:,ave);



% 4. calculate mean and standard dev G_fluc for each fluctuating timescale
t30 = 1;
t300 = 2;
t900 = 3;
t3600 = 4;

Gfluc_means(t30) = mean(G_fluc_norm(timescales_perG==30));
Gfluc_means(t300) = mean(G_fluc_norm(timescales_perG==300));
Gfluc_means(t900) = mean(G_fluc_norm(timescales_perG==900));
Gfluc_means(t3600) = mean(G_fluc_norm(timescales_perG==3600));

Gfluc_std(t30) = std(G_fluc_norm(timescales_perG==30));
Gfluc_std(t300) = std(G_fluc_norm(timescales_perG==300));
Gfluc_std(t900) = std(G_fluc_norm(timescales_perG==900));
Gfluc_std(t3600) = std(G_fluc_norm(timescales_perG==3600));



% 4. plot G_data by timescale

% growth rate normalized
figure(6)
plot([2 3 4 5],Gfluc_means,'o','Color',rgb('DarkTurquoise'),'MarkerSize',10,'LineWidth',2);
hold on
errorbar([2 3 4 5],Gfluc_means, Gfluc_std,'o','Color',rgb('DarkTurquoise'));
hold on
plot(1,G_monod./G_monod,'o','Color',rgb('DarkCyan'),'MarkerSize',10,'LineWidth',2);
hold on
errorbar(1,G_monod./G_monod,stableRates_std(ave)./G_monod,'o','Color',rgb('DarkCyan'),'LineWidth',2);
hold on
plot(10, G_jensens./G_monod,'o','Color',rgb('SlateGray'),'MarkerSize',10,'LineWidth',2)


axis([1 10 0.1 1.4])
title('growth, relative to average nutrient concentration')
xlabel('fluctuating timescale')
ylabel('mean growth rate, normalized by G_ave)') % growth rate = d(logV)/(dt*ln(2))


% 5. display raw values of G_ave, G_jensens, G_fluc, G_high and G_low
%G_monod
%G_jensens
%Gfluc_means
%Gfluc_std
G_high = stableRates_mean(high);
G_low = stableRates_mean(low);


clear counter index
clear e experimentCount t30 t300 t900 t3600
clear date 

%% C. Slow calculations of predicted G from single shift data


% 0. initialize time to stabilize for both shifts
ts_up = 116.3; % min, mean value from Figure 4 (response quantifications)
ts_down = 297.5;


% 0. initialize shorter names for data from both shifts
upshift_means = upshift_means_single;
upshift_times = upshift_times_single;
downshift_means = downshift_means_single;
downshift_times = downshift_times_single;
clear upshift_means_single upshift_times_single downshift_means_single downshift_times_single


% 1. trim growth rate signals to times until stabilized
trimmed_upshift_gr = upshift_means(upshift_times < ts_up);
trimmed_upshift_times = upshift_times(upshift_times < ts_up);

trimmed_downshift_gr = downshift_means(downshift_times < ts_down);
trimmed_downshift_times = downshift_times(downshift_times < ts_down);
clear upshift_means upshift_times downshift_means downshift_times


% 2. trim growth signals to times postshift
transition_upshift = trimmed_upshift_gr(trimmed_upshift_times >= 0);
transition_upshift_times = trimmed_upshift_times(trimmed_upshift_times >= 0);

transition_downshift = trimmed_downshift_gr(trimmed_downshift_times > 0);
transition_downshift_times = trimmed_downshift_times(trimmed_downshift_times > 0);
clear trimmed_upshift_gr trimmed_upshift_times trimmed_downshift_gr trimmed_downshift_times


% 3. time-average transitions
G_transit_up = mean(transition_upshift);
G_transit_down = mean(transition_downshift);


% 4. calculate time-averaged growth rates during high nutrient phase
for p = 1:length(periods_slow)
    
    tau = periods_slow(p) * 60; % convert hr to min
    phase = tau/2;
    
    fractionTransition = ts_up/phase;
    weightedTransition = G_transit_up * fractionTransition;
    weightedStable = G_high * (1-fractionTransition);
    
    G_phase_high(p) = mean(weightedTransition+weightedStable);
    
end
clear fractionTransition weightedTransition weightedStable tau phase p 



% 5. calculate time-averaged growth rates during low nutrient phase
for p = 1:length(periods_slow)
    
    tau = periods_slow(p) * 60; % convert hr to min
    phase = tau/2;
    
    fractionTransition = ts_down/phase;
    weightedTransition = G_transit_down * fractionTransition;
    weightedStable = G_low * (1-fractionTransition);
    
    G_phase_low(p) = mean(weightedTransition+weightedStable);
    
end
clear fractionTransition weightedTransition weightedStable tau phase p
clear high ave low fluc


% 6. calculate time-averaged growth rates from entire period
G_periods = (G_phase_high + G_phase_low)./2;
G_periods_normalized = G_periods./G_monod;
clear G_phase* periods_slow


% 7. plot slow predictions to timescale plot
figure(6)
hold on
plot([6 7 8 9],G_periods_normalized,'o','Color',rgb('SlateGray'),'MarkerSize',10,'LineWidth',2);
hold on
axis([1,10,0.3,1.2])


%% D. Fast calculations of predicted G from single shift data
%
%  Method 1A: cumulative, taking observed time in fluc experiments into account (upper bound)

%  G_cumulative = (G_up*ts_up + G_down*ts_down + ss_high((OT/2)-ts_up) + ss_low((OT/2)-ts_down))/ OT
%          where,
%          OT = observed time

% 1. calculate observed time in data set
observedTime = zeros(length(exptArray),1);
for e = 1:length(exptArray)
    
    index = exptArray(e);
    bubbletime = storedMetaData{index}.bubbletime; 
    minTime = 3;  % hr
    maxTime = bubbletime(1);
    observedTime(e) = maxTime - minTime;
    
end
clear e bubbletime index minTime maxTime


% 2. calculate weighted components of cumulative mean growth rate
G_weighted_up = zeros(length(exptArray),1);
G_weighted_down = zeros(length(exptArray),1);
G_weighted_high = zeros(length(exptArray),1);
G_weighted_low = zeros(length(exptArray),1);

for ee = 1:length(exptArray)
    
    OT_phase = observedTime(ee)/2; % hours
    
    if OT_phase > ts_up/60 % min converted to hours
        
        % 2. calculate G_up*ts_up, the mean growth rate of single upshift transition weighted by time required to reach G_high
        G_weighted_up(ee) = G_transit_up * ts_up/60;
        
        % 3. calculate ss_high(OT_phase - ts_up), G_high weighted by remaining time in high after reaching steady-state
        G_weighted_high(ee) = G_high * (OT_phase - ts_up/60);
        
    else
        
        % 2. calculate G_up weighted to the incomplete adaptation between steady-states
        %    (incomplete because OT_phase < ts_up)
        cutoff = OT_phase * 60; % convert hours to minutes
        %ts_up_incomplete = transition_upshift_times(transition_upshift_times < cutoff);
        G_weighted_up(ee) = (mean(transition_upshift(transition_upshift_times < cutoff)) * cutoff)/60;
        
        % 3. define ss_high(OT_phase - ts_up) as zero, as no data exists
        %    after cutoff (OT_phase < ts_up/60)
        G_weighted_high(ee) = 0;
        
    end
    clear cutoff

    if OT_phase > ts_down/60
        
        % 4. calculate G_down*ts_down,the mean growth rate of single downshift transition weighted by time required to reach G_low
        G_weighted_down(ee) = G_transit_down * ts_down/60;
        
        % 5. calculate ss_low(5-ts_down) = G_low weighted by remaining time in low after reaching steady-state
        G_weighted_low(ee) = G_low * (OT_phase - ts_down/60);
    
    else
        
        % 4. calculate G_down weighted to the incomplete adaptation between steady-states
        cutoff = OT_phase * 60;
        G_weighted_down(ee) = (mean(transition_downshift(transition_downshift_times < cutoff)) * cutoff)/60;
        
        % 5. define ss_high(OT_phase - ts_up) as zero, as no data exists after cutoff (OT_phase < ts_up/60)
        G_weighted_low(ee) = 0;
        
    end
    clear cutoff
end
clear ee OT_phase


% 6. calculate cumulative G for all experiments
G_cumulatives = (G_weighted_up + G_weighted_down + G_weighted_high + G_weighted_low)./observedTime;
G_cumulatives_normalized = G_cumulatives./G_monod;



% 7. calculate mean G_cumulative for each timescale
binnedByTimescale = accumarray(timescales_perG',G_cumulatives_normalized,[],@(x) {x});
x = cellfun(@isempty,binnedByTimescale);
binned = binnedByTimescale(x == 0);
G_cumulative = cellfun(@mean,binned);
G_cumulative_std = cellfun(@std,binned);
clear binnedByTimescale x binned observedTime



%  Method 1B: cumulative, simulating a 6 hour observation (upper bound)

% 1. define simulated "observation" time
simulatedTime = 6; % in hours

% 2. calculate weighted components of cumulative mean growth rate
G_w_up = zeros(length(periods_fast),1);
G_w_down = zeros(length(periods_fast),1);
G_w_high = zeros(length(periods_fast),1);
G_w_low = zeros(length(periods_fast),1);

for ss = 1:length(periods_fast)
    
    OT_phase = simulatedTime/2; % hours
    
    if OT_phase > ts_up/60 % min converted to hours
        
        % 2. calculate G_up*ts_up, the mean growth rate of single upshift transition weighted by time required to reach G_high
        G_w_up(ss) = G_transit_up * ts_up/60;
        
        % 3. calculate ss_high(OT_phase - ts_up), G_high weighted by remaining time in high after reaching steady-state
        G_w_high(ss) = G_high * (OT_phase - ts_up/60);
        
    else
        
        % 2. calculate G_up weighted to the incomplete adaptation between steady-states
        %    (incomplete because OT_phase < ts_up)
        cutoff = OT_phase * 60; % convert hours to minutes
        G_w_up(ss) = (mean(transition_upshift(transition_upshift_times < cutoff)) * cutoff)/60;
        
        % 3. define ss_high(OT_phase - ts_up) as zero, as no data exists after cutoff (OT_phase < ts_up/60)
        G_w_high(ss) = 0;
        
    end
    clear cutoff

    if OT_phase > ts_down/60
        
        % 4. calculate G_down*ts_down,the mean growth rate of single downshift transition weighted by time required to reach G_low
        G_w_down(ss) = G_transit_down * ts_down/60;
        
        % 5. calculate ss_low(5-ts_down) = G_low weighted by remaining time in low after reaching steady-state
        G_w_low(ss) = G_low * (OT_phase - ts_down/60);
    
    else
        
        % 4. calculate G_down weighted to the incomplete adaptation between steady-states
        cutoff = OT_phase * 60;
        G_w_down(ss) = (mean(transition_downshift(transition_downshift_times < cutoff)) * cutoff)/60;
        
        % 5. define ss_high(OT_phase - ts_up) as zero, as no data exists after cutoff (OT_phase < ts_up/60)
        G_w_low(ss) = 0;
        
    end
    clear cutoff
end
clear ss OT_phase


% 6. calculate cumulative G for all experiments
G_cumulatives_B = (G_w_up + G_w_down + G_w_high + G_w_low)./simulatedTime;
G_cumulatives_normalized_B = G_cumulatives_B./G_monod;




%  Method 2: total restart 
%
%  1. for each timescale, initialize the value of 1/2 period
G_restart_up = zeros(length(periods_fast),1);
G_restart_down = zeros(length(periods_fast),1);

for tscale = 1:length(periods_fast)
    
    timescale = periods_fast(tscale);
    half_T = timescale/2;
    half_T_minutes = half_T/60; % convert sec to minutes
    
    if half_T_minutes < transition_upshift_times(1)
        
        % 2. assign mean growth rate as first data point from single upshift data
        G_restart_up(tscale) = transition_upshift(1);
    else        
        % 2. calculate mean growth rate across half_T from single upshift data
        G_restart_up(tscale) = mean(transition_upshift(transition_upshift_times < half_T_minutes));
        
    end
    
    
    if half_T_minutes < transition_downshift_times(1)
        
        % 3. assign mean growth rate as first data point from from single DOWNshift data
        G_restart_down(tscale) = transition_downshift(1);
    else
        % 3. calculate mean growth rate across half_T from single DOWNshift data
        G_restart_down(tscale) = mean(transition_downshift(transition_downshift_times < half_T_minutes));
        
    end
    
end
clear tscale

    
    
% 4. combine high and low phases to calculate G_restart
%    G_restart = ( G_up(half period) + G_down(half period) )/ 2
G_restart = (G_restart_up + G_restart_down)./2;
G_restart_normalized = G_restart./G_monod;
    


% 5. plot both fast prediction onto timescale plot
figure(6)
hold on

% Method 2. restart (plot like slow predictions)
plot([2 3 4 5],G_restart_normalized,'o','Color',rgb('SlateGray'),'MarkerSize',10,'LineWidth',2);
hold on

% Method 1. cumulative
plot([2 3 4 5],G_cumulative,'o','Color',rgb('SlateGray'),'MarkerSize',10,'LineWidth',2);
hold on
errorbar([2 3 4 5],G_cumulative, G_cumulative_std,'o','Color',rgb('SlateGray'));

% Method 1. cumulative _ B _ simulated time
plot([2 3 4 5],G_cumulatives_normalized_B,'o','Color',rgb('DarkSlateGray'),'MarkerSize',10,'LineWidth',2);
hold on

axis([1,10,0,1.2])

%% G. Caluclate difference from daily G_jensens and G_low

% note: these values represent the different in G_fluc from G_jensens and G_low

% 3. normalize each G_fluc by it's corresponding G_jensens
dailyGJ = (stableRates(:,high)+stableRates(:,low))/2;

G_fluc_norm_Gj = flucRates./dailyGJ;
byGJ_means = [nanmean(G_fluc_norm_Gj(1:3)), nanmean(G_fluc_norm_Gj(4:6)), nanmean(G_fluc_norm_Gj(7:10)), nanmean(G_fluc_norm_Gj(11:13))];
byGJ_stds = [nanstd(G_fluc_norm_Gj(1:3)), nanstd(G_fluc_norm_Gj(4:6)), nanstd(G_fluc_norm_Gj(7:10)), nanstd(G_fluc_norm_Gj(11:13))];

G_fluc_norm_Gl = flucRates./stableRates(:,low);
byGL_means = [nanmean(G_fluc_norm_Gl(1:3)), nanmean(G_fluc_norm_Gl(4:6)), nanmean(G_fluc_norm_Gl(7:10)), nanmean(G_fluc_norm_Gl(11:13))];
byGL_stds = [nanstd(G_fluc_norm_Gl(1:3)), nanstd(G_fluc_norm_Gl(4:6)), nanstd(G_fluc_norm_Gl(7:10)), nanstd(G_fluc_norm_Gl(11:13))];
