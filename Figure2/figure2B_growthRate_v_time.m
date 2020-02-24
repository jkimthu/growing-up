%% figure 2B: growth rate vs time


%  Goals: plot growth rate over time

%  Strategy:
%
%       0. initialize directory and meta data
%       0. define time binning and growth rates of interest, see comments below for details 
%       1. initialize experiment meta data
%       2. load measured experiment data    
%       3. for each condition in current experiment, build data matrix from specified condition
%               4. isolate volume (Va), timestamp, drop, curve, and trackNum data
%               5. calculate growth rate
%               6. truncate data to non-erroneous (e.g. bubbles) timestamps
%               7. isolate selected specific growth rate and timestamp
%               8. remove nans from data analysis
%               9. bin growth rate into time bins based on timestamp
%              10. calculate mean, standard dev, counts, and standard error
%              11. plot growth rate over time
%      12. save plot with experiment #, specific growth rate definition, and binning          



%  last updated: jen, 2019 April 8

%  commit: plot figure 2B, trimmed x axis and edited comments


% OK let's go!

%% initialize

clear
clc

% 0. initialize complete meta data
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')
dataIndex = find(~cellfun(@isempty,storedMetaData));


% 0. define growth rates and bin size (time) of interest
specificGrowthRate = 'log2';
specificColumn = 3;

smallBin = 2;
bigBin = 60;
binsPerHour_small = 60/smallBin;
binsPerHour_big = 60/bigBin;


%% compiled data and plot


% 1. initialize experiment meta data
index = 13; % 2019-01-29 data
date = storedMetaData{index}.date;
expType = storedMetaData{index}.experimentType;
bubbletime = storedMetaData{index}.bubbletime;
timescale = storedMetaData{index}.timescale;
disp(strcat(date, ': analyze!'))



% 2. load measured experiment data
experimentFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',date);
cd(experimentFolder)

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
    clear timestamps_hr timestamps_sec
    
    
    
    
    % 7. isolate selected specific growth rate and timestamp
    growthRt = growthRates_bubbleTrimmed(:,specificColumn);
    timestamps_sec = getGrowthParameter(conditionData_bubbleTrimmed,'timestamp'); % ND2 file timestamp in seconds
    timeInHours = timestamps_sec./3600;
    clear conditionData timestamps_sec
    
    
    
    % 8. remove nans from data analysis
    growthRt_noNaNs = growthRt(~isnan(growthRt),:);
    timeInHours_noNans = timeInHours(~isnan(growthRt),:);
    clear growthRates growthRt growthRates_bubbleTrimmed
    
    
    
    
    % 9. bin growth rate into time bins based on timestamp
    bins_small = ceil(timeInHours_noNans*binsPerHour_small);
    bins_big = ceil(timeInHours_noNans*binsPerHour_big);
    
    
    
    
    % 10. calculate mean, standard dev, counts, and standard error
    bin_means_small = accumarray(bins_small,growthRt_noNaNs,[],@mean);
    bin_means_big = accumarray(bins_big,growthRt_noNaNs,[],@mean);
    
    
    
    % 11. plot growth rate over time
    palette = {'DodgerBlue','Indigo','GoldenRod','FireBrick','LimeGreen','MediumPurple'};
    
    color = rgb(palette(condition));
    xmark = '.';
    
    
    figure(1)
    plot((1:length(bin_means_small))/binsPerHour_small,bin_means_small,'Color',color,'Marker',xmark,'LineWidth',2)
    hold on
    plot((1:length(bin_means_big))/binsPerHour_big,bin_means_big,'Color',color,'Marker',xmark)
    hold on
    legend('high,untreated','high,treated','low,untreated','low,treated')
    axis([3,9,-1,4])
    xlabel('Time (hr)')
    ylabel('Growth rate')
    title(strcat(date,': (',specificGrowthRate,')'))
    
    
    
end


% 12. save plots in active folder
cd('/Users/jen/Documents/StockerLab/Data_analysis/currentPlots/')
plotName = strcat('figure2B-',specificGrowthRate,'-',date,'-','bothBins');
saveas(gcf,plotName,'epsc')






