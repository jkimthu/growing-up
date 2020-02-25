%% figure 2C - growth rate vs nutrient period


%  Goal: plot growth rate vs nutrient phase,
%        binning rates by period fraction (20th of a period)


%  Strategy:
%
%  Part 0:
%     0. initialize analysis parameters
%     0. initialize complete meta data

%  Part 1:
%     1. for all experiments in dataset:
%           2. initialize experiment meta data
%           3. load measured data
%           4. gather specified condition data
%           5. isolate parameters for growth rate calculations
%           6. calculate growth rate
%           7. isolate data to stabilized regions of growth
%           8. isolate selected specific growth rate
%           9. bin growth rates by 20th of period
%          10. calculate average growth rate per timebin
%          11. plot
%    12. repeat for all experiments



%  Last edit: jen, 2020 Feb 24
%  commit: final plot for figure 2C, minor edits for sharing 


% Okie, go go let's go!

%% Part 0. initialize analysis

clc
clear

% 0. initialize complete meta data
source_data = '/Users/jen/Documents/StockerLab/Source_data';
cd(source_data)
load('storedMetaData.mat')
exptArray = [5,6,7,9,10,11,12,13,14,15]; % list experiments by index


% 0. initialize analysis parameters
condition = 1; % 1 = fluctuating; 3 = ave nutrient condition
binsPerPeriod = 20;


% 0. define growth rate of interest
specificGrowthRate = 'log2';
specificColumn = 3;



%% Part 1. bin growth rates into 20th of period timescale

% 1. for all experiments in dataset
exptCounter = 0;
for e = 1:length(exptArray)
       
    % 2. initialize experiment meta data
    index = exptArray(e);
    date = storedMetaData{index}.date;
    timescale = storedMetaData{index}.timescale;
    expType = storedMetaData{index}.experimentType;
    bubbletime = storedMetaData{index}.bubbletime;
    xys = storedMetaData{index}.xys;
    
    disp(strcat(date, ': analyze!'))
    
    exptCounter = exptCounter + 1;
    datesForLegend{exptCounter} = date;

    
    % 3. load measured data
    source_data = '/Users/jen/Documents/StockerLab/Source_data';
    cd(source_data)
    filename = strcat('lb-fluc-',date,'-c123-width1p4-c4-1p7-jiggle-0p5.mat');
    load(filename,'D5','T');
    
    
    % 4. gather specified condition data
    condition = 1; % 1 = fluctuating
    xy_start = storedMetaData{index}.xys(condition,1);
    xy_end = storedMetaData{index}.xys(condition,end);
    conditionData = buildDM(D5, T, xy_start, xy_end, index, expType);
    clear D5 T xy_start xy_end xys
     
    
    % 5. isolate parameters for growth rate calculations
    volumes = getGrowthParameter(conditionData,'volume');             % volume = calculated va_vals (cubic um)
    timestamps_sec = getGrowthParameter(conditionData,'timestamp');   % ND2 file timestamp in seconds
    isDrop = getGrowthParameter(conditionData,'isDrop');              % isDrop == 1 marks a birth event
    curveFinder = getGrowthParameter(conditionData,'curveFinder');    % col 5  = curve finder (ID of curve in condition)
    trackNum = getGrowthParameter(conditionData,'trackNum');          % track number, not ID from particle tracking
    
    
    % 6. calculate growth rate
    growthRates = calculateGrowthRate(volumes,timestamps_sec,isDrop,curveFinder,trackNum);
    clear trackNum curveFinder isDrop volumes
    
    
    % 7. isolate data to stabilized regions of growth
    %    NOTE: errors (excessive negative growth rates) occur at trimming
    %          point if growth rate calculation occurs AFTER time trim.
    minTime = 3;  % hr
    maxTime = bubbletime(condition); % limit analysis to whole integer # of periods
    timestamps_hr = timestamps_sec/3600; % time in seconds converted to hours
    
    % trim to minumum
    times_trim1 = timestamps_hr(timestamps_hr >= minTime);
    conditionData_trim1 = conditionData(timestamps_hr >= minTime,:);
    growthRates_trim1 = growthRates(timestamps_hr >= minTime,:);
    
    % trim to maximum
    if maxTime > 0
        conditionData_trim2 = conditionData_trim1(times_trim1 <= maxTime,:);
        growthRates_trim2 = growthRates_trim1(times_trim1 <= maxTime,:);
    else
        conditionData_trim2 = conditionData_trim1;
        growthRates_trim2 = growthRates_trim1;
    end
    clear times_trim1 timestamps_hr minTime maxTime timestamps_sec
    clear growthRates conditionData
   

    
    % 8. isolate selected specific growth rate
    growthRt = growthRates_trim2(:,specificColumn);
    
    
    
    % 9. bin growth rates by 20th of period, first assigning growth rate to
    %    time value of the middle of two timepoints (not end value)!
    timestep_sec = 60+57;
    timeInSeconds = conditionData_trim2(:,22);  % col 22 = signal corrected time
    if strcmp(date,'2017-10-10') == 1
        timeInSeconds = conditionData_trim2(:,2);
    end
    
    timeInSeconds_middle = timeInSeconds - (timestep_sec/2);
    timeInPeriods = timeInSeconds_middle/timescale;    % units = sec/sec
    timeInPeriods_floors = floor(timeInPeriods);
    timeInPeriodFraction = timeInPeriods - timeInPeriods_floors;
    assignedBin = timeInPeriodFraction * binsPerPeriod;
    assignedBin = ceil(assignedBin);
    
    growthRt_binned = accumarray(assignedBin,growthRt,[],@(x) {x});
    clear timeInSeconds timeInPeriods timeInPeriodFraction assignedBin
    
    
    % 10. calculate average growth rate per timebin
    growthRt_means = cellfun(@nanmean,growthRt_binned);
    growthRt_means_zeroed(exptCounter,:) = [growthRt_means(end); growthRt_means];
    
    
    % 11. plot
    if timescale == 30
        color = rgb('FireBrick');
    elseif timescale == 300
        color = rgb('Gold');
    elseif timescale == 900
        color = rgb('MediumSeaGreen');
    elseif timescale == 3600
        color = rgb('MediumSlateBlue');
    end
    
    shape = '.';

    figure(1)
    plot(growthRt_means_zeroed(exptCounter,:),'Color',color,'Marker',shape)
    hold on
    grid on
    title('growth rate: log2 mean')
    xlabel('period bin (1/20)')
    ylabel('growth rate (1/h)')
    axis([1,21,-1,4])
    legend(datesForLegend)
    

% 12. repeat for all experiments
end
