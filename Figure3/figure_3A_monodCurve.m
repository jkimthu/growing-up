%% figure 3A - monod curve


% Output: Monod plot of time-averaged growth rate vs nutrient concentration.
%         two version: log (natural) x axis, and linear x axis

% Input: (1) data structures from particle tracking and quality control.
%        (2) meta data structure to inform correct placement of data

%        (1) experiment data
%        each experiment has trimmed data structure, D5, and timestamp data, T.

%        (2) meta data
%        psuedo-manually compiled structure, storedMetaData.mat

%        this code is written as if all experiment files (.mat, containing D5
%        and T) and meta data file were in the same folder


% Strategy:

%  Part 0. initialize analysis

%  Part 1. compile data from each experiment
%       1. for each experiment, identify experiment by date and extract relevant parameters
%       2. load experiment data
%       3. build experiment data matrix
%       4. for each condition, calculate instantaneous growth rates by...
%       5. isolating all data from current condition
%       6. isolate volume (Va), timestamp, drop, curve, and trackNum data
%       7. calculate growth rates  
%       8. truncate data to non-erroneous (e.g. bubbles) timestamps
%       9. calculate average and s.e.m. of stabilized data  
%      10. accumulate data for storage / plotting  
%      11. store data from all conditions into compiled data structure, growthRates_monod_curve.mat  


%  Part 2. save compiled data into stored data structure (PART B)
%  Part 3. access structure to plot time-averaged growth rate over time
%  Part 4. access structure to calculate mean G for all conditions



% Last edit: jen nguyen, 2020 Feb 25
% Commit: finalize for code sharing with source data


% OK let's go!


%% Part 0. Initialize analysis

clear
clc

% 0. initialize complete meta data
source_data = '/Users/jen/Documents/StockerLab/Source_data';
cd(source_data)
load('storedMetaData.mat')
dataIndex = find(~cellfun(@isempty,storedMetaData));


% 0. define growth rate of interest
specificGrowthRate = 'log2'; % d(log volume)/dt measuured between each tpt
specificColumn = 3;          % in matrix of alternative growth rate calcuations


% 0. define experiments to include in analysis
exptArray = [2,3,4,5,6,7,9,10,11,12,13,14,15,17,18]; % use corresponding dataIndex values
experimentCount = length(exptArray);


%% Part 1. Compile data from each experiment

for e = 1:experimentCount
    
    % 1. identify experiment by date and extract relevant parameters
    index = exptArray(e);
    date = storedMetaData{index}.date;
    timescale = storedMetaData{index}.timescale;
    expType = storedMetaData{index}.experimentType;
    bubbletime = storedMetaData{index}.bubbletime;

    
    % 2. load data
    if ischar(timescale) == 0
        filename = strcat('lb-fluc-',date,'-c123-width1p4-c4-1p7-jiggle-0p5.mat');
    elseif strcmp(date,'2017-09-26') == 1
        filename = 'lb-monod-2017-09-26-jiggle-c12-0p1-c3456-0p5-bigger1p8.mat';
    elseif strcmp(date, '2017-11-09') == 1
        filename = strcat('lb-control-',date,'-width1p4-jiggle-0p5.mat');
    end
    load(filename,'D5','T')
    
    
    % 3. build experiment data matrix
    display(strcat('Experiment (', num2str(e),') of (', num2str(length(dataIndex)),')'))
    xy_start = 1;
    xy_end = length(D5);
    exptData = buildDM(D5,T,xy_start,xy_end,index,expType);
    clear D5 T filename experimentFolder
   
    
    % 4. for each condition, calculate instantaneous growth rates
    xys = storedMetaData{index}.xys;
    xy_dimensions = size(xys);
    totalConditions = xy_dimensions(1);
    clear xys xy_dimensions
    
    for c = 1:totalConditions
        
        % 5. isolate all data from current condition
        conditionData = exptData(exptData(:,21) == c,:);  % col 21 = conditionData
        
        
        % 6. isolate volume (Va), timestamp, drop, curve, and trackNum data     
        volumes = getGrowthParameter(conditionData,'volume');             % col 11 = calculated va_vals (cubic um)
        timestamps_sec = getGrowthParameter(conditionData,'timestamp');   % col 2  = timestamp in seconds
        isDrop = getGrowthParameter(conditionData,'isDrop');              % col 4  = isDrop, 1 marks a birth event
        curveFinder = getGrowthParameter(conditionData,'curveFinder');    % col 5  = curve finder (ID of curve in condition)
        trackNum = getGrowthParameter(conditionData,'trackNum');          % col 20 = track number (not ID from particle tracking)
        
        
        % 7. calculate growth rates
        growthRates = calculateGrowthRate(volumes,timestamps_sec,isDrop,curveFinder,trackNum);
        growthRates_log2 = growthRates(:,specificColumn);
        clear volumes isDrop trackNum
        
        
        % 8. truncate data to non-erroneous (e.g. bubbles) timestamps
        minTime = 3;  % hr
        maxTime = bubbletime(c);
        timestamps_hr = timestamps_sec/3600;
        
        time_trim1 = timestamps_hr(timestamps_hr >= minTime);
        growthRates_trim1 = growthRates_log2(timestamps_hr >= minTime,:);
        
        if maxTime > 0
            growthRates_final = growthRates_trim1(time_trim1 <= maxTime,:);
        else
            growthRates_final = growthRates_trim1;
        end
        clear time_trim1 growthRates_trim1 growthRates_fullCurves
        clear timestamps_hr timestamps_sec minTime maxTime
        
        
        % 9. calculate average and s.e.m. of stabilized data        
        mean_log2 = nanmean(growthRates_final);
        count_log2 = length(growthRates_final(~isnan(growthRates_final)));
        std_log2 = nanstd(growthRates_final);
        sem_log2 = std_log2./sqrt(count_log2);
        
        
        % 10. accumulate data for storage / plotting        
        compiled_growthRate_log2{c}.mean = mean_log2;
        compiled_growthRate_log2{c}.std = std_log2;
        compiled_growthRate_log2{c}.count = count_log2;
        compiled_growthRate_log2{c}.sem = sem_log2;
        clear mean_log2 count_log2 std_log2 sem_log2 observedTime
        clear conditionData
    
    end
    
    % 11. store data from all conditions into measured data structure        
    growthRates_monod_curve{index} = compiled_growthRate_log2;
    clear compiled_growthRate_log2
    
end


%% Part 2. Save compiled data into stored data structure

source_data = '/Users/jen/Documents/StockerLab/Source_data';
cd(source_data)
save('growthRates_monod_curve.mat','growthRates_monod_curve')


%% Part 3. Access structure to plot time-averaged growth rate over time

clc
clear

% 0. initialize meta data
source_data = '/Users/jen/Documents/StockerLab/Source_data';
cd(source_data)
load('storedMetaData.mat')
load('growthRates_monod_curve.mat')
dataIndex = find(~cellfun(@isempty,growthRates_monod_curve));
experimentCount = length(dataIndex);


% 0. initialize summary stats for fitting
counter = 0;
summaryMeans = zeros(1,(experimentCount-1)*3 + 6);
summaryConcentrations = zeros(1,(experimentCount-1)*3 + 6);

% 0. initialize colors
palette = {'FireBrick','Chocolate','ForestGreen','Amethyst','MidnightBlue'};
shapes = {'o','x','square','*'};

for e = 1:experimentCount
    
    % 1. identify experiment by date
    index = dataIndex(e);
    date = storedMetaData{index}.date;
    
    % exclude outlier from analysis
    if strcmp(date, '2017-10-31') == 1
        disp(strcat(date,': excluded from analysis'))
        continue
    end
    disp(strcat(date, ': analyze!'))
    
    
    % 2. load timescale
    timescale = storedMetaData{index}.timescale;
    
    % 3. isolate growth rate data for current experiment
    experiment_growthRates = growthRates_monod_curve{index};
    
    % 4. isolate concentration data for current experiment
    concentration = storedMetaData{index}.concentrations;
    
    % 5. color and symbol determination
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
            xmark = shapes{1};
        elseif timescale == 900 && c == 1
            color = rgb(palette(3));
            xmark = shapes{1};
        elseif timescale == 3600 && c == 1
            color = rgb(palette(4));
            xmark = shapes{1};
        else
            color = rgb(palette(5));
            xmark = shapes{1};
        end
        
        
        % 6. plot time-avereaged growth rates, labeled by stable vs fluc
        figure(1)
        errorbar(log(concentration(c)), experiment_growthRates{c}.mean, experiment_growthRates{c}.sem,'Color',color);
        hold on
        plot(log(concentration(c)), experiment_growthRates{c}.mean,'Marker',xmark,'MarkerSize',10,'Color',color)
        hold on
        ylabel('growth rate (1/h)')
        xlabel('log fold LB dilution')
        title(strcat('Population-averaged growth rate (log2) vs log(ln) LB dilution'))
               
        
    end
     
end


%% Part 4. Access structure to calculate mean G for all conditions

clc
clear


% 0. initialize meta data
source_data = '/Users/jen/Documents/StockerLab/Source_data';
cd(source_data)
load('storedMetaData.mat')
load('growthRates_monod_curve.mat')
dataIndex = find(~cellfun(@isempty,growthRates_monod_curve));
experimentCount = length(dataIndex);


% 1. compile all mean values of G
compiled_G = nan(12,4);
for ii = 1:13  % 13 fluctuating experiments, 4 conditions
    
    exp = dataIndex(ii);
    expData = growthRates_monod_curve{exp};
    
    for cond = 1:4   
        compiled_G(ii,cond) = expData{1,cond}.mean;  
    end
end
clear ii exp expData


% 2. calculate mean G and standard deviation, error, etc.

% i. for steady conditions, column#: low = 1; ave = 2; high = 3
steadies = compiled_G(:,2:4);
steadies_mean = nanmean(steadies);
steadies_std = nanstd(steadies);
steadies_counts = sum(~isnan(steadies));
steadies_sem = steadies_std./sqrt(steadies_counts);

% ii. for fluctuating conditions, column#:
%           30 s = 1; 5 min = 2; 15 min = 3; 60 min = 4
fluctuating = cell(1,4);
fluctuating{1} = compiled_G(1:3,1);
fluctuating{2} = compiled_G(4:6,1);
fluctuating{3} = compiled_G(7:10,1);
fluctuating{4} = compiled_G(11:13,1);

fluc_means = cellfun(@mean,fluctuating);
fluc_std = cellfun(@std,fluctuating);
fluc_counts = cellfun(@length, fluctuating);
fluc_sem = fluc_std./sqrt(fluc_counts);

