%% Quantify noise in single cell growth rate from different conditions


%  Goals: quantify noise in single-cell growth rate

%  Strategy:
%
%       1. from mu(t) of each single cell (each instantaneous growth rate trajectory)
%          calculate noise as standard deviation divided by mean mu(t)
%
%               noise in single-cell growth rate = std( mu(t) )/ mean( mu(t) )
%
%       2. compare noise between steady and fluctuating conditions


%  last updated: jen, 2020 Oct 1
%  commit: quantify noise in single-cell growth rate


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


% 0. initialize experiments in analysis
indeces = dataIndex(2:14);

 
%% Part 1. calculate noise for all individuals in each nutrient condition

% 0. initialize matrix to store noise values
noise_compiled = zeros(13,4);

% 1. initialize experiment meta data

for expt = 1:length(indeces) 
    
    index = indeces(expt);
    date = storedMetaData{index}.date;
    expType = storedMetaData{index}.experimentType;
    bubbletime = storedMetaData{index}.bubbletime;
    xys = storedMetaData{index}.xys;
    disp(strcat(date, ': analyze!'))
    
    
    % 2. load measured experiment data
    cd(source_data)
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
        %track_starttimes = nan(length(uniqueTracks),1);
        %track_endtimes = nan(length(uniqueTracks),1);
        track_mus = cell(length(uniqueTracks),1);
        %track_timestamps = cell(length(uniqueTracks),1);
        for ut = 1:length(uniqueTracks)
            
            % i. store growth rates
            currentTrack = uniqueTracks(ut);
            currentMus = growthRt_noNaNs(trackNum_noNans == currentTrack,1);
            track_mus{ut,1} = currentMus;
            
            % ii. store associated times
%             currentTimes = timestamps_noNans(trackNum_noNans == currentTrack,1);
%             track_timestamps{ut,1} = currentTimes;
%             
%             track_starttimes(ut,1) = currentTimes(1);
%             track_endtimes(ut,1) = currentTimes(end);
            
        end
        clear ut currentTrack currentMus currentTimes
        
        
        
        
        % 12. remove tracks with two or less data points
        track_lengths = cellfun(@length,track_mus);
        selection = find(track_lengths >= 3);
        tr_mus = track_mus(selection);
        
        
        
        % 13. calculate noise for each single-cell growth rate trajectory
        tr_std = cellfun(@std,tr_mus);
        tr_ave = cellfun(@mean,tr_mus);
        tr_noise = tr_std./tr_ave;
        noise_compiled(expt,condition) = median(tr_noise);
        clear tr_std tr_ave tr_noise
        
    end
    clear condition
    
end

cd(source_data)
save('quantifyNoise.mat','noise_compiled')


