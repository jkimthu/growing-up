%% figure 2XY - testing alternative explanation of fluctuating growth rate 


%  Goal: testing alternative hypothesis that observed fluctuations in
%        average growth rate are division-dependent, rather than changes in
%        single-cell growth rate

%  Strategy:
%
%        X. division events and total cells over time
%        Y. box plot with scatter of growth rate of pre- and post- division in Chigh and Clow


%  last updated: jen, 2021 Mar 29
%  commit: retired, see S8_alt_hypothesis.m in Supplementary_figures
%          folder

% OK let's go!


%% Part X. division events over time

clear
clc

% 0. initialize complete meta data
source_data = '/Users/jen/Documents/StockerLab/Source_data';
cd(source_data)
load('storedMetaData.mat')


% 0. define bin size (time) of interest
bin = 2; % min
binsPerHour = 60/bin;


% 1. initialize experiment meta data
index = 13; % 2019-01-29 data
date = storedMetaData{index}.date;
expType = storedMetaData{index}.experimentType;
bubbletime = storedMetaData{index}.bubbletime;
disp(strcat(date, ': analyze!'))


% 2. load measured experiment data
filename = strcat('lb-fluc-',date,'-c123-width1p4-c4-1p7-jiggle-0p5.mat');
load(filename,'D5','T');


% 3. build data matrix from specified condition
for condition = 1:length(bubbletime)
    
    
    xy_start = storedMetaData{index}.xys(condition,1);
    xy_end = storedMetaData{index}.xys(condition,end);
    conditionData = buildDM(D5, T, xy_start, xy_end,index,expType);
    
    
    
    % 4. isolate volume (Va), timestamp, drop, curve, and trackNum data
    volumes = getGrowthParameter(conditionData,'volume');             % volume = calculated va_vals (cubic um)
    timestamps_sec = getGrowthParameter(conditionData,'timestamp');   % ND2 file timestamp in seconds
    isDrop = getGrowthParameter(conditionData,'isDrop');              % isDrop == 1 marks a birth event
    curveFinder = getGrowthParameter(conditionData,'curveFinder');    % col 5  = curve finder (ID of curve in condition)
    trackNum = getGrowthParameter(conditionData,'trackNum');          % track number, not ID from particle tracking
    
    
    
    % 5. truncate data to non-erroneous (e.g. bubbles) timestamps
    maxTime = bubbletime(condition);
    timestamps_hr = conditionData(:,2)/3600; % time in seconds converted to hours
    
    if maxTime > 0
        conditionData_bubbleTrimmed = conditionData(timestamps_hr <= maxTime,:);
    else
        conditionData_bubbleTrimmed = conditionData;
    end
    clear timestamps_hr timestamps_sec
    
    
    
    % 6. isolate division events and when they occur
    isEvent = getGrowthParameter(conditionData_bubbleTrimmed,'isDrop');
    times_s = getGrowthParameter(conditionData_bubbleTrimmed,'timestamp');
    divisions = isEvent(isEvent==1);
    div_t = times_s(isEvent==1)./3600; % coverted from seconds to hours
    
    
    % 7. bin division events into time bins based on timestamp
    bins_small = ceil(div_t*binsPerHour);
    bin_counts = accumarray(bins_small,divisions,[],@sum);
    
    
    % 8. generate time vector for bins
    time_vec = (1:length(bin_counts))*bin;
    time_vec = time_vec/60; % converted from min to hours
    
    
    % 9. plot division events over time
    palette = {'DodgerBlue','Indigo','GoldenRod','FireBrick','LimeGreen','MediumPurple'};
    color = rgb(palette(condition));
    
    
    figure(condition)
    bar(time_vec,bin_counts,'FaceColor',color,'EdgeColor',color)
    hold on
    xlim([3,maxTime])
    xlabel('Time (h)')
    ylabel('Division events')
    title(strcat(date))
    
    % 12. save plots in active folder
    cd('/Users/jen/Documents/StockerLab/Data_analysis/currentPlots/')
    plotName = strcat('figure2X-',date,'-cond-',num2str(condition));
    saveas(gcf,plotName,'epsc')
    close(gcf)
    
end


%% Part Y. box plot with scatter of growth rate of pre- and post- division in Chigh and Clow


clear
clc

% 0. initialize complete meta data
source_data = '/Users/jen/Documents/StockerLab/Source_data';
cd(source_data)
load('storedMetaData.mat')
dataIndex = find(~cellfun(@isempty,storedMetaData));


% 0. define growth rates and bin size (time) of interest
specificGrowthRate = 'log2';
specificColumn = 3;


% 1. initialize experiment meta data
t60 = 13:15; % indeces of T=60 experiments in stored meta data
stats = cell(length(t60),2);
high_i = [];
low_i = [];


for ii = 1:length(t60)
    
    index = t60(ii);
    date = storedMetaData{index}.date;
    expType = storedMetaData{index}.experimentType;
    bubbletime = storedMetaData{index}.bubbletime;
    timescale = storedMetaData{index}.timescale;
    disp(strcat(date, ': analyze!'))
    
    
    % 2. load measured experiment data
    cd(source_data)
    filename = strcat('lb-fluc-',date,'-c123-width1p4-c4-1p7-jiggle-0p5.mat');
    load(filename,'D5','T');
    
    
    % 3. build data matrix from fluctuating condition only
    condition = 1;
    xy_start = storedMetaData{index}.xys(condition,1);
    xy_end = storedMetaData{index}.xys(condition,end);
    conditionData = buildDM(D5, T, xy_start, xy_end, index, expType);
    clear xy_start xy_end
    
    
    % 4. isolate volume (Va), timestamp, drop, curve, and trackNum data
    volumes = getGrowthParameter(conditionData,'volume');             % volume = calculated va_vals (cubic um)
    timestamps_sec = getGrowthParameter(conditionData,'timestamp');   % ND2 file timestamp in seconds
    isDrop = getGrowthParameter(conditionData,'isDrop');              % isDrop == 1 marks a birth event
    curveFinder = getGrowthParameter(conditionData,'curveFinder');    % col 5  = curve finder (ID of curve in condition)
    trackNum = getGrowthParameter(conditionData,'trackNum');          % track number, not ID from particle tracking
    
    
    % 5. calculate growth rate
    growthRates = calculateGrowthRate(volumes,timestamps_sec,isDrop,curveFinder,trackNum);
    clear volumes isDrop curveFinder trackNum
    
    
    % 6. truncate data to non-erroneous (e.g. bubbles) timestamps
    maxTime = bubbletime(condition);
    timestamps_hr = conditionData(:,2)/3600; % time in seconds converted to hours
    
    if maxTime > 0
        conditionData_bubbleTrimmed = conditionData(timestamps_hr <= maxTime,:);
        growthRates_bubbleTrimmed = growthRates(timestamps_hr <= maxTime,:);
    else
        conditionData_bubbleTrimmed = conditionData;
        growthRates_bubbleTrimmed = growthRates;
    end
    clear timestamps_hr timestamps_sec bubbletime
    
    
    
    % 7. isolate selected specific growth rate and timestamp
    growthRt = growthRates_bubbleTrimmed(:,specificColumn);
    clear conditionData growthRates_bubbleTrimmed growthRates
    
    
    
    % 8. determine which divisions are asscoiated with Chigh or Clow
    
    % i. gather division and corrected time ("corrected" for any lag in nutrient fluctuations)
    correctedTime = getGrowthParameter(conditionData_bubbleTrimmed,'correctedTime');
    isDiv = getGrowthParameter(conditionData_bubbleTrimmed,'isDrop');
    
    
    % ii. trim data to those after 3h
    isDiv_stable = isDiv(correctedTime >= 3*3600);
    correctedTime_stable = correctedTime(correctedTime >= 3*3600);
    growthRt_stable = growthRt(correctedTime >= 3*3600);
    clear isDiv correctedTime growthRt
    
    
    % iii. convert corrected time to a binary nutrient signal (high = 1; low = 0)
    correctedTime_inPeriods = correctedTime_stable/timescale; % unit = sec/sec
    correctedTime_inPeriodFraction = correctedTime_inPeriods - floor(correctedTime_inPeriods);
    correctedTime_inQuarters = ceil(correctedTime_inPeriodFraction * 4);
    
    binaryNutrient = zeros(length(correctedTime_inQuarters),1);
    binaryNutrient(correctedTime_inQuarters == 1) = 1;
    binaryNutrient(correctedTime_inQuarters == 4) = 1;
    clear correctedTime_inPeriods correctedTime_inPeriodFraction correctedTime_inQuarters
    
    
    % iv. identify time of division events in Chigh and Clow
    division_events = isDiv_stable(isDiv_stable == 1);
    event_timestamp = correctedTime_stable(isDiv_stable == 1);
    event_envir = binaryNutrient(isDiv_stable == 1);
    
    data_indeces = 1:length(isDiv_stable);
    event_index = data_indeces(isDiv_stable == 1);
    clear data_indeces correctedTime_stable isDiv_stable
    
    
    % 9. if cell does not experience a nutrient shift immediately
    %    before or after divison, collect growth rates 1 and 2 tpts before and after
    high_divs = [];
    low_divs = [];
    for ev = 1:sum(division_events)
        
        % i. determine nutrient condition across 5 timepoints, 2
        %    timepoints before and after each division event
        current_index = event_index(ev);
        current_window = current_index-2:current_index+2;
        current_envir = binaryNutrient(current_window);
        current_mu = growthRt_stable(current_window);
        
        
        % ii. accumulate growth rates according to timepoint relative to division
        if sum(current_envir) == 5       % if cell is in HIGH nutrient across all timepoints...
            
            high_divs = [high_divs; current_mu'];
            
        elseif sum(current_envir) == 0 % if cell is in LOW nutrient across all timepoints...
            
            low_divs = [low_divs; current_mu'];
            
        end
        clear current_index current_window current_envir current_mu 
    end
    clear ev division_events event_envir event_index event_timestamp binaryNutrient growthRt_stable
    
    
    % 10. calculate stats for each experiment
    expt_high.mean = nanmean(high_divs);
    expt_high.std = nanstd(high_divs);
    expt_high.n = length(high_divs);
    expt_high.sem = nanstd(high_divs)./length(high_divs);
    expt_high.date = date;
    
    expt_low.mean = nanmean(low_divs);
    expt_low.std = nanstd(low_divs);
    expt_low.n = length(low_divs);
    expt_low.sem = nanstd(low_divs)./length(low_divs);
    expt_low.date = date;
    
    % 11. store individual and average experiment data
    stats{ii,1} = expt_high;
    stats{ii,2} = expt_low;
    high_i = [high_i; high_divs];
    low_i = [low_i; low_divs];
    clear low_divs high_divs
    
end
clear ii index D5 T conditionData_bubbleTrimmed date filename


%% Bar plot for Part Y

% Goal:  plot growth rate before and after division

% 0. initialize columns in data
high = 1; low = 2;
color = rgb('DodgerBlue');


% 1. calculate replicate means and s.e.m.
means_high = nan(3,5);
sems_high = nan(3,5);
means_low = nan(3,5);
sems_low = nan(3,5);
for rep = 1:3
    
    means_high(rep,:) = stats{rep,high}.mean;
    means_low(rep,:) = stats{rep,low}.mean;
    
    sems_high(rep,:) = stats{rep,high}.sem;
    sems_low(rep,:) = stats{rep,low}.sem;
    
end

% 2. calculate mean and s.e.m. of compiled data
compiled_mean_high = nanmean(high_i);
compiled_mean_low = nanmean(low_i);
compiled_std_high = nanstd(high_i);
compiled_std_low = nanstd(low_i);
compiled_n_high = length(high_i);
compiled_n_low = length(low_i);
compiled_sem_high = compiled_std_high./sqrt(compiled_n_high);
compiled_sem_low = compiled_std_low./sqrt(compiled_n_low);

% 3. prepare to spread replicate points
spread_x = ones(size(means_high)).*(1+(rand(size(means_high))-0.4)/10);

% 4. plot
figure(2)
subplot(1,2,1)
bar(compiled_mean_high)
hold on
errorbar(compiled_mean_high,compiled_sem_high,'.')
ylim([0 3])
ylabel('growth rate (1/h)')
xlabel('timepoint relative to cell division')
title('cells dividing in Chigh')
hold on
for col = 1:5
    scatter(spread_x(:,col)+col-1,means_high(:,col),'MarkerFaceColor',color,'MarkerEdgeColor',color)
end

subplot(1,2,2)
bar(compiled_mean_low)
hold on
errorbar(compiled_mean_low,compiled_sem_low,'.')
ylim([0 3])
ylabel('growth rate (1/h)')
xlabel('timepoint relative to cell division')
title('cells dividing in Clow')
hold on
for col = 1:5
    scatter(spread_x(:,col)+col-1,means_low(:,col),'MarkerFaceColor',color,'MarkerEdgeColor',color)
end


%% Box plot for Part Y

% 11. plot growth rate before and after division
high = 1; low = 2;
color = rgb('DodgerBlue');

means_high = nan(3,5);
sems_high = nan(3,5);
means_low = nan(3,5);
sems_low = nan(3,5);
for rep = 1:3
    
    means_high(rep,:) = stats{rep,high}.mean;
    means_low(rep,:) = stats{rep,low}.mean;
    
    sems_high(rep,:) = stats{rep,high}.sem;
    sems_low(rep,:) = stats{rep,low}.sem;
    
end

spread_x = ones(size(means_high)).*(1+(rand(size(means_high))-0.4)/10);

figure(2)
subplot(1,2,1)
boxplot(high_i,'symbol','')
ylim([-3 6])
ylabel('growth rate (1/h)')
xlabel('timepoint relative to cell division')
title('cells dividing in Chigh')
hold on
for col = 1:5
    scatter(spread_x(:,col)+col-1,means_high(:,col),'MarkerFaceColor',color,'MarkerEdgeColor',color)
end

subplot(1,2,2)
boxplot(low_i,'symbol','')
ylim([-3 6])
ylabel('growth rate (1/h)')
xlabel('timepoint relative to cell division')
title('cells dividing in Clow')
hold on
for col = 1:5
    scatter(spread_x(:,col)+col-1,means_low(:,col),'MarkerFaceColor',color,'MarkerEdgeColor',color)
end

