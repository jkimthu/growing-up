% singlePeriodVolumes

%  Goal: sliding fits calculates mu using a 10 min window, which is MUCH
%        too long to then use to look at immediate responses to nutrient
%        upshifts and downshifts
%
%        this script bins and plots VOLUMES by time incrememt (period fraction)


%  Last edit: jen, 2018 Mar 19

%  commit: avoid smoothing of responses by directly plotting mean volume, binned in time

%% 

%  Strategy:
%
%  Part A:
%     0. initialize analysis parameters
%     0. initialize complete meta data

%  Part B:
%     1. for all experiments in dataset:
%           2. collect experiment date and exclude outliers (2017-10-31)
%           3. initialize experiment meta data
%           4. load measured data
%           5. gather data for specified condition
%           6. isolate volume and timestamp (corrected for signal lag) data of interest
%           7. remove data not in stabilized region
%           8. remove zeros from mu data (always bounding start and end of tracks)
%           9. bin volumes by 20th of period
%          10. calculate average volume and s.e.m. per timebin
%          11. plot
%    12. repeat for all experiments

%  Part C:
%    13. save volume stats into stored data structure


%% (A) initialize analysis
clc
clear

% 0. initialize analysis parameters
binsPerPeriod = 20;

% 0. initialize complete meta data
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')

dataIndex = find(~cellfun(@isempty,storedMetaData));
experimentCount = length(dataIndex);

%% (B) bin volumes into 20th of period timescale

% 1. for all experiments in dataset
exptCounter = 0;
for e = 1:experimentCount
       
    % 2. collect experiment date
    index = dataIndex(e);
    date = storedMetaData{index}.date;
    timescale = storedMetaData{index}.timescale;
    
    % exclude outlier from analysis
    if strcmp(date, '2017-10-31') == 1 || strcmp (timescale, 'monod') == 1
        disp(strcat(date,': excluded from analysis'))
        continue
    end
    disp(strcat(date, ': analyze!'))
    exptCounter = exptCounter + 1;
    datesForLegend{exptCounter} = date;

    
    % 3. initialize experiment meta data
    xys = storedMetaData{index}.xys;
    bubbletime = storedMetaData{index}.bubbletime;
    
    
    % 4. load measured data
    experimentFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',date);
    cd(experimentFolder)
    filename = strcat('lb-fluc-',date,'-window5-width1p4-1p7-jiggle-0p5.mat');
    load(filename,'D','D5','M','M_va','T');
    
    
    % 5. gather specified condition data
    condition = 3; % 1 = fluctuating; 3 = ave nutrient condition
    xy_start = storedMetaData{index}.xys(condition,1);
    xy_end = storedMetaData{index}.xys(condition,end);
    flucData = buildDM(D5, M, M_va, T, xy_start, xy_end,e);
    
    
    % 6. isolate volume and timestamp (corrected for signal lag) data of interest
    volumes = flucData(:,14);               % col 14 = volumes (va)
    correctedTime = flucData(:,2)/3600;     % col 30 = timestamps corrected for signal lag
    clear D D5 M M_va T xy_start xy_end xys
    
    
    % 7. remove data not in stabilized region
    minTime = 3;  % hr converted to min
    volumes_trim1 = volumes(correctedTime >= minTime);
    time_trim1 = correctedTime(correctedTime >= minTime);
    
    if bubbletime(condition) == 0
        volumes_trim2 = volumes_trim1;
        Time_trim2 = time_trim1;
    else
        maxTime = bubbletime(condition);
        volumes_trim2 = volumes_trim1(time_trim1 <= maxTime);
        Time_trim2 = time_trim1(time_trim1 <= maxTime);
    end
    
    
    % 8. remove zeros from mu data (always bounding start and end of tracks)
    volumes_trim3 = volumes_trim2(volumes_trim2 > 0);
    Time_trim3 = Time_trim2(volumes_trim2 > 0);
    
    clear minTime maxTime bubbletime
    clear volumes volumes_trim1 volumes_trim2 correctedTime time_trim1 Time_trim2
    
    
    % 9. bin volumes by 20th of period
    timeInSeconds = Time_trim3*3600;
    timeInPeriods = timeInSeconds/timescale; % units = sec/sec
    timeInPeriods_floors = floor(timeInPeriods);
    timeInPeriodFraction = timeInPeriods - timeInPeriods_floors;
    assignedBin = timeInPeriodFraction * binsPerPeriod;
    assignedBin = ceil(assignedBin);
    
    binnedVolumes = accumarray(assignedBin,volumes_trim3,[],@(x) {x});
    clear timeInSeconds timeInPeriods timeInPeriodFraction assignedBin
    
    
    % 10.  calculate average volume and s.e.m. per timebin
    meanVolume(exptCounter,:) = cellfun(@mean,binnedVolumes);
    countVolume(exptCounter,:) = cellfun(@length,binnedVolumes);
    stdVolume(exptCounter,:) = cellfun(@std,binnedVolumes);
    semVolume(exptCounter,:) = stdVolume(exptCounter,:)./sqrt(countVolume(exptCounter,:));
    
    
    % 11. plot
    if timescale == 30
        color = rgb('FireBrick');
        shapeNum = index-1;
    elseif timescale == 300
        color = rgb('Gold');
        shapeNum = index-4;
    elseif timescale == 900
        color = rgb('MediumSeaGreen');
        shapeNum = index-8;
    elseif timescale == 3600
        color = rgb('MediumSlateBlue');
        shapeNum = index-12;
    end
    
    if shapeNum == 1
        shape = 'x';
    elseif shapeNum == 2
        shape = 'o';
    elseif shapeNum == 3
        shape = 'square';
    else
        shape = '+';
    end

    figure(1)
    errorbar(meanVolume(exptCounter,:),semVolume(exptCounter,:),'Color',color,'Marker',shape)
    hold on
    grid on
    title('volume: mean + s.e.m.')
    xlabel('period bin (1/20)')
    ylabel('volume, unsynchronized')
    axis([0,21,2.5,6])
    legend(datesForLegend)
    

% 12. repeat for all experiments
end

%% (C) save volume stats into stored data structure

% last saved: 2018 Mar 19
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
save('volumes_fluc.mat','meanVolume','countVolume','stdVolume','semVolume','datesForLegend')

%% (D) 

