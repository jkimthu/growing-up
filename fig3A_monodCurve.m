%% figure 3A - monod curve


% Goal: Monod plot of growth rate vs nutrient concentration


% Strategy:
%
%       1. collect growth rates from all experiment data
%       2. eliminating timepoints before 3 hr
%       3. calculate mean, std, counts, and sem for each condition of each experiment
%       4. store stats into a structure, save
%       5. call data from structures for plotting


% Last edit: jen, 2019 Feb 5
% Commit: up-to-date figure 3A in growth reductions manuscript


% OK let's go!


%% initialize analysis

clear
clc

% 0. initialize complete meta data
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')
dataIndex = find(~cellfun(@isempty,storedMetaData));



% 0. define growth rate of interest
specificGrowthRate = 'log2'; % d(log volume)/dt measuured between each tpt
specificColumn = 3;          % in matrix of alternative growth rate calcuations


% 0. define experiments to include in analysis
exptArray = [2,3,4,5,6,7,9,10,11,12,13,14,15,17,18]; % use corresponding dataIndex values
experimentCount = length(exptArray);


%% for each experiment, move to folder and load data

for e = 11%1:experimentCount
    
    % 1. identify experiment by date and extract relevant parameters
    index = exptArray(e);
    date = storedMetaData{index}.date;
    timescale = storedMetaData{index}.timescale;
    expType = storedMetaData{index}.experimentType;
    bubbletime = storedMetaData{index}.bubbletime;

    
    % 2. move directory to experiment data
    experimentFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',date);
    cd(experimentFolder)
    
    
    % 3. load data
    if ischar(timescale) == 0
        filename = strcat('lb-fluc-',date,'-c123-width1p4-c4-1p7-jiggle-0p5.mat');
    elseif strcmp(date,'2017-09-26') == 1
        filename = 'lb-monod-2017-09-26-jiggle-c12-0p1-c3456-0p5-bigger1p8.mat';
    elseif strcmp(date, '2017-11-09') == 1
        filename = strcat('lb-control-',date,'-width1p4-jiggle-0p5.mat');
    end
    load(filename,'D5','T')
    
    

    
    % 4. build experiment data matrix
    display(strcat('Experiment (', num2str(e),') of (', num2str(length(dataIndex)),')'))
    xy_start = 1;
    xy_end = length(D5);
    exptData = buildDM(D5,T,xy_start,xy_end,index,expType);
    clear D5 T filename experimentFolder
   
    
    %%
    % 5. for each condition, calculate instantaneous growth rates
    xys = storedMetaData{index}.xys;
    xy_dimensions = size(xys);
    totalConditions = xy_dimensions(1);
    clear xys xy_dimensions
    
    for c = 1:totalConditions
        
        % 6. isolate all data from current condition
        conditionData = exptData(exptData(:,21) == c,:);  % col 21 = conditionData
        
        
        % 7. isolate volume (Va), timestamp, drop, curve, and trackNum data     
        volumes = getGrowthParameter(conditionData,'volume');             % col 11 = calculated va_vals (cubic um)
        timestamps_sec = getGrowthParameter(conditionData,'timestamp');   % col 2  = timestamp in seconds
        isDrop = getGrowthParameter(conditionData,'isDrop');              % col 4  = isDrop, 1 marks a birth event
        curveFinder = getGrowthParameter(conditionData,'curveFinder');    % col 5  = curve finder (ID of curve in condition)
        trackNum = getGrowthParameter(conditionData,'trackNum');          % col 20 = track number (not ID from particle tracking)
        
        
        % 8. calculate growth rate
        growthRates = calculateGrowthRate(volumes,timestamps_sec,isDrop,curveFinder,trackNum);
        growthRates_log2 = growthRates(:,specificColumn);
        clear volumes isDrop trackNum
        
        
        % 9. trim data to full curves only
        growthRates_fullCurves = growthRates_log2(curveFinder > 0);
        timestamps_fullCurves = timestamps_sec(curveFinder > 0);
        clear curveFinder
        
        
        % 10. truncate data to non-erroneous (e.g. bubbles) timestamps
        minTime = 3;  % hr
        maxTime = bubbletime(c);
        timestamps_hr = timestamps_fullCurves/3600;
        
        time_trim1 = timestamps_hr(timestamps_hr >= minTime);
        growthRates_trim1 = growthRates_fullCurves(timestamps_hr >= minTime,:);
        
        if maxTime > 0
            growthRates_final = growthRates_trim1(time_trim1 <= maxTime,:);
        else
            growthRates_final = growthRates_trim1;
        end
        clear time_trim1 growthRates_trim1 growthRates_fullCurves
        clear timestamps_hr timestamps_sec minTime maxTime
        
        
        % 10. calculate average and s.e.m. of stabilized data        
        mean_log2 = nanmean(growthRates_final);
        count_log2 = length(growthRates_final(~isnan(growthRates_final)));
        std_log2 = nanstd(growthRates_final);
        sem_log2 = std_log2./sqrt(count_log2);
        
        
        % 11. accumulate data for storage / plotting        
        compiled_growthRate_log2{c}.mean = mean_log2;
        compiled_growthRate_log2{c}.std = std_log2;
        compiled_growthRate_log2{c}.count = count_log2;
        compiled_growthRate_log2{c}.sem = sem_log2;
        
        clear mean_log2 count_log2 std_log2 sem_log2
        clear conditionData
    
    end
    
    % 10. store data from all conditions into measured data structure        
    growthRates_monod_curve{index} = compiled_growthRate_log2;

    
    clear compiled_growthRate_log2
end


%% 11. Save new data into stored data structure
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
save('growthRates_monod_curve.mat','growthRates_monod_curve')


%% 12. plot average biovolume production rate over time
clc
clear

cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')
load('growthRates_monod_curve.mat')
dataIndex = find(~cellfun(@isempty,storedMetaData));
experimentCount = length(dataIndex);


% initialize summary stats for fitting
counter = 0;
summaryMeans = zeros(1,(experimentCount-1)*3 + 6);
summaryConcentrations = zeros(1,(experimentCount-1)*3 + 6);

% initialize colors
palette = {'FireBrick','Chocolate','ForestGreen','Amethyst','MidnightBlue'};
shapes = {'o','x','square','*'};

for e = 1:experimentCount
    
    % identify experiment by date
    index = dataIndex(e);
    date = storedMetaData{index}.date;
    
    % exclude outlier from analysis
    if strcmp(date, '2017-10-31') == 1
        disp(strcat(date,': excluded from analysis'))
        continue
    end
    disp(strcat(date, ': analyze!'))
    
    
    % load timescale
    timescale = storedMetaData{index}.timescale;
    
    % isolate biomass prod data for current experiment
    experiment_dVdt_data = dVdtData_newdVdt{index};
    experiment_dVdt_norm = dVdtData_normalized_newdVdt{index};
    
    % isolate concentration data for current experiment
    concentration = storedMetaData{index}.concentrations;
    
    
    for c = 1:length(concentration)
        
       % if monod experiment
        if ischar(timescale)
            color = rgb(palette(5));
            xmark = shapes{1};

        % if fluc experiment
        elseif timescale == 30 && c == 1
            color = rgb(palette(1));
            xmark = shapes{1};
        elseif timescale == 300 && c == 1
            color = rgb(palette(2));
            xmark = shapes{2};
        elseif timescale == 900 && c == 1
            color = rgb(palette(3));
            xmark = shapes{3};
        elseif timescale == 3600 && c == 1
            color = rgb(palette(4));
            xmark = shapes{4};
        else
            color = rgb(palette(5));
            xmark = shapes{1};
        end
        
        % plot dV/dt data, labeled by stable vs fluc
        figure(1)
        errorbar(log(concentration(c)), experiment_dVdt_data{c}.mean, experiment_dVdt_data{c}.sem,'Color',color);
        hold on
        plot(log(concentration(c)), experiment_dVdt_data{c}.mean,'Marker',xmark,'MarkerSize',10,'Color',color)
        hold on
        ylabel('dV/dt (cubic um/hr)')
        xlabel('log fold LB dilution')
        title(strcat('Population-averaged dV/dt vs log LB dilution'))
        
        % plot normalized dV/dt data, labeled by stable vs fluc
        figure(2)
        errorbar(log(concentration(c)), experiment_dVdt_norm{c}.mean, experiment_dVdt_norm{c}.sem,'Color',color);
        hold on
        plot(log(concentration(c)), experiment_dVdt_norm{c}.mean,'Marker',xmark,'MarkerSize',10,'Color',color)
        hold on
        ylabel('(dV/dt)/V (1/hr)')
        xlabel('log fold LB dilution')
        title(strcat('Population-averaged volume-normalized dV/dt vs log LB dilution'))
        
    end
     
end