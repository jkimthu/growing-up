%% figure S7a. single cell growth rate from different conditions


%  Goals: plot single-cell tracks of growth rate over time

%  Strategy:
%
%       0. initialize complete meta data
%       0. define growth rates and bin size (time) of interest
%       0. initialize number of tracks to plot per condition
%       1. initialize meta data for experiment 2019-01-29
%       2. load measured experiment data
%       3. build data matrix from specified experiment
%       4. loop through conditions to plot data
%               5. isolate volume (Va), timestamp, drop, curve, and trackNum data
%               6. calculate growth rate
%               7. truncate data to non-erroneous (e.g. bubbles) timestamps
%               8. remove data with timestamps earlier than 3 h
%               9. isolate selected specific growth rate
%              10. remove nans from data analysis. 
%              11. sort growth rate and timestamp data by track
%              12. select tracks for plotting
%              13. plot growth rate of each single cell over time
%      14. save plots


%  last updated: jen, 2021 March 29
%  commit: final revision for Supplementary Fig. 7a,b

% OK let's go!

%% Part 0. initialize

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


% 0. initialize number of tracks to plot per condition
tracksPerCondition = 20;


% 0. initialize binning parameters
%binSize = 2;
%binsPerHour = 60/binSize;


%% Part 1. collect single cell data from 10 cells per conditions

% 1. initialize experiment meta data
index = 13; % 2019-01-29 data
date = storedMetaData{index}.date;
expType = storedMetaData{index}.experimentType;
bubbletime = storedMetaData{index}.bubbletime;
timescale = storedMetaData{index}.timescale;
xys = storedMetaData{index}.xys;
disp(strcat(date, ': analyze!'))


% 2. load measured experiment data
filename = strcat('lb-fluc-',date,'-c123-width1p4-c4-1p7-jiggle-0p5.mat');
load(filename,'D5','T');


% 3. build data matrix from specified experiment
xy_start = xys(1);
xy_end = xys(end);
expData = buildDM(D5, T, xy_start, xy_end,index,expType);
clear xy_start xy_end


% 4. loop through conditions to plot data   
conditions = getGrowthParameter(expData,'condition');
for condition = 1:length(bubbletime)
    
    conditionData = expData(conditions == condition,:);
    
    
    % 5. isolate volume (Va), timestamp, drop, curve, and trackNum data
    volumes = getGrowthParameter(conditionData,'volume');             % volume = calculated va_vals (cubic um)
    timestamps_sec = getGrowthParameter(conditionData,'timestamp');   % ND2 file timestamp in seconds
    isDrop = getGrowthParameter(conditionData,'isDrop');              % isDrop == 1 marks a birth event
    curveFinder = getGrowthParameter(conditionData,'curveFinder');    % col 5  = curve finder (ID of curve in condition)
    trackNum = getGrowthParameter(conditionData,'trackNum');          % track number, not ID from particle tracking
    
    
    % 6. calculate growth rate
    growthRates = calculateGrowthRate(volumes,timestamps_sec,isDrop,curveFinder,trackNum);
    clear volumes isDrop curveFinder trackNum
    
    
    % 7. truncate data to non-erroneous (e.g. bubbles) timestamps
    maxTime = bubbletime(condition);
    timestamps_hr = conditionData(:,2)/3600; % time in seconds converted to hours
    
    if maxTime > 0
        conditionData_bubbleTrimmed = conditionData(timestamps_hr <= maxTime,:);
        growthRates_bubbleTrimmed = growthRates(timestamps_hr <= maxTime,:);
        timestamps_bubbleTrimmed = timestamps_hr(timestamps_hr <= maxTime,:);
    else
        conditionData_bubbleTrimmed = conditionData;
        growthRates_bubbleTrimmed = growthRates;
        timestamps_bubbleTrimmed = timestamps_hr;
    end
    clear timestamps_hr timestamps_sec 
        
    
    % 8. remove data with timestamps earlier than 3 h
    minTime = 3;
    conditionData_final = conditionData_bubbleTrimmed(timestamps_bubbleTrimmed >= minTime,:);
    growthRates_final = growthRates_bubbleTrimmed(timestamps_bubbleTrimmed >= minTime,:);
    timestamps_final = timestamps_bubbleTrimmed(timestamps_bubbleTrimmed >= minTime,:);
    clear timestamps_bubbleTrimmed conditionData_bubbleTrimmed growthRates_bubbleTrimmed
    clear minTime maxTime
    
    
    % 9. isolate selected specific growth rate
    growthRt = growthRates_final(:,specificColumn);
    trackNum = getGrowthParameter(conditionData_final,'trackNum');
    clear conditionData
    
    
    % 10. remove nans from data analysis
    growthRt_noNaNs = growthRt(~isnan(growthRt),:);
    timestamps_noNans = timestamps_final(~isnan(growthRt),:);
    trackNum_noNans = trackNum(~isnan(growthRt),:);
    clear growthRates growthRt growthRates_bubbleTrimmed timestamps_final trackNum
    
    
    % 11. sort growth rate and timestamp data by track
    uniqueTracks = unique(trackNum_noNans);
    track_starttimes = nan(length(uniqueTracks),1);
    track_endtimes = nan(length(uniqueTracks),1);
    track_mus = cell(length(uniqueTracks),1);
    track_timestamps = cell(length(uniqueTracks),1);
    for ut = 1:length(uniqueTracks)
        
        % i. store growth rates
        currentTrack = uniqueTracks(ut);
        currentMus = growthRt_noNaNs(trackNum_noNans == currentTrack,1);
        track_mus{ut,1} = currentMus;
        
        % ii. store associated times
        currentTimes = timestamps_noNans(trackNum_noNans == currentTrack,1);
        track_timestamps{ut,1} = currentTimes;
        
        track_starttimes(ut,1) = currentTimes(1);
        track_endtimes(ut,1) = currentTimes(end);
        
    end
    clear ut currentTrack currentMus currentTimes
    
    
    % 12. select tracks for plotting
    track_lengths = cellfun(@length,track_timestamps);
    selection = find(track_lengths >= 155);
    if length(selection) > tracksPerCondition
       selection = randsample(selection,tracksPerCondition);
    end
    
    tr_mus = track_mus(selection);
    tr_ts = track_timestamps(selection);
    

    % 13. plot growth rate of each single cell over time
    palette = {'DodgerBlue','Indigo','GoldenRod','FireBrick'};
    color = rgb(palette(condition));
    xmark = '.';
    
    
    figure(condition)
    counter = 0;
    for sc = 1:length(selection)
        
        
        counter = counter + 1;
        
        xx = tr_ts{sc};
        yy = tr_mus{sc};
        %bins = ceil(xx*binsPerHour);
        %bins_unique = unique(bins);
        %timeVector = (bins_unique*binSize)./60; % time in hours
    
        % i. calculate mean, standard dev, counts, and standard error
        %bin_mean = accumarray(bins,yy,[],@mean);
        %bin_std = accumarray(bins,yy,[],@std);
        
        if selection < tracksPerCondition
            rr = ceil(selection/2);
        else
            rr = 10;
        end
        subplot(rr,2,counter)
        plot(xx,yy,'Color',color,'Marker',xmark,'LineWidth',2)
        %plot(timeVector,bin_mean(bins_unique),'Color',color,'Marker',xmark,'LineWidth',2)
        axis([3,9,-1,6])
        
    end
    clear sc
    
    xlabel('Time (h)')
    ylabel('Growth rate')   
    
    
end
clear color condition 





