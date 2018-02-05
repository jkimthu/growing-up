% singlePeriodMus

%  Goal: plot average of mus, binned by period fraction


%  Sample code pulled from distributions.m and nsyncInFlux.m
%  Strategy:
%
%     0. initialize experiment and analysis parameters
%     1. initialize experiment meta and measured data
%     2. isolate data of interest
%     3. remove data not in stabilized region
%     4. remove zeros from mu data (always bounding start and end of tracks)
%     5. accumulate data points by time bin (period fraction)
%     6. plot for all isolated groups



%  Last edit: jen, 2018 Feb 5

%  commit: update summary plot section to experiments through 2018-02-01


%% original, single experiment plots with high pulse in center

%  Strategy:
%
%     0. initialize experiment and analysis parameters
%     1. initialize experiment meta and measured data
%     2. isolate data of interest
%     3. remove data not in stabilized region
%     4. remove zeros from mu data (always bounding start and end of tracks)
%     5. accumulate data points by time bin (period fraction)
%     6. plot for all isolated groups

% 0. initialize target experiment and analysis parameters
clear
clc

% 0. initialize period fractioning
binsPerPeriod = 30;

% 0. identify data of interest
targetDate = '2017-11-15';

% 1. initialize experiment meta and measured data

cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')
dataIndex = find(~cellfun(@isempty,storedMetaData));

% initialize summary vectors for calculated data
experimentCount = length(dataIndex);
datesByIndex = cell(experimentCount,1);

for e = 1:experimentCount
    
    date = storedMetaData{dataIndex(e)}.date;
    datesByIndex{e} = date;
    
end
clear e date

targetIndex = strfind(datesByIndex,targetDate);
indexID = cellfun(@length,targetIndex);
targetExperiment = dataIndex(indexID == 1);

% 0. load meta data
timescale = storedMetaData{targetExperiment}.timescale;
concentrations = storedMetaData{targetExperiment}.concentrations;
xys = storedMetaData{targetExperiment}.xys;
bubbletime = storedMetaData{targetExperiment}.bubbletime;

% 0. Load workspace
experimentFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',targetDate);
cd(experimentFolder)

filename = strcat('lb-fluc-',targetDate,'-window5-width1p4-1p7-jiggle-0p5.mat');
load(filename);

dataMatrix = buildDM(D5,M,M_va,T);

%
for condition = 1:4
    
    % 1. isolate data of interest
    conditionData = dataMatrix(dataMatrix(:,35)==condition,:);
    Mus = conditionData(:,18); % col 18 = mu_va
    bioVolPR = conditionData(:,36); % col 36 = biovol production rate
    Time = conditionData(:,2)/3600; % col 2 = timestamps in sec, covert to hr
    
    % 2. remove data not in stabilized region
    minTime = 3;  % hr converted to min
    Mus_trim1 = Mus(Time >= minTime);
    BVPR_trim1 = bioVolPR(Time >= minTime);
    Time_trim1 = Time(Time >= minTime);
    
    if bubbletime(condition) == 0
        Mus_trim2 = Mus_trim1;
        BVPR_trim2 = BVPR_trim1;
        Time_trim2 = Time_trim1;
    else
        maxTime = bubbletime(condition);
        Mus_trim2 = Mus_trim1(Time_trim1 <= maxTime);
        BVPR_trim2 = BVPR_trim1(Time_trim1 <= maxTime);
        Time_trim2 = Time_trim1(Time_trim1 <= maxTime);
    end
    
    % 4. remove zeros from mu data (always bounding start and end of tracks)
    Mus_trim3 = Mus_trim2(Mus_trim2 > 0);
    BVPR_trim3 = BVPR_trim2(Mus_trim2 > 0);
    Time_trim3 = Time_trim2(Mus_trim2 > 0);
        
    
    % 5. accumulate data points by time bin (period fraction)
    timeInSeconds = Time_trim3*3600;
    timeWarp = timeInSeconds/timescale; % units = sec/sec
    floorWarp = floor(timeWarp);
    timeBins = timeWarp - floorWarp;
    rightBin = timeBins * binsPerPeriod;
    rightBin = ceil(rightBin);
        
    binnedMus = accumarray(rightBin,Mus_trim3,[],@(x) {x});
    binnedBVPR = accumarray(rightBin,BVPR_trim3,[],@(x) {x});
    
    % 4.  convert bin # to absolute time (in seconds)
    timePerBin = timescale/30;               % in sec
    timeVector = linspace(1, binsPerPeriod, binsPerPeriod);
    timeVector = timePerBin*timeVector';
    
    
    % 5.  calculate average and s.e.m. per timebin
    meanVector = cellfun(@mean,binnedMus);
    countVector = cellfun(@length,binnedMus);
    stdVector = cellfun(@std,binnedMus);
    semVector = stdVector./sqrt(countVector);
    
    meanBVPR = cellfun(@mean,binnedBVPR);
    countBVPR = cellfun(@length,binnedBVPR);
    stdBVPR = cellfun(@std,binnedBVPR);
    semBVPR = stdBVPR./sqrt(countBVPR);
    
    
    
    % 6. plot period, with some repetition at ends
    muSignal = [meanVector(binsPerPeriod/2:binsPerPeriod); meanVector; meanVector(1:binsPerPeriod/2)];
    semSignal = [semVector(binsPerPeriod/2:binsPerPeriod); semVector; semVector(1:binsPerPeriod/2)];
    if timescale == 30
        timeSignal = [(-15:0)'; timeVector; (31:45)'];
    elseif timescale == 300
        timeSignal = [(-150:10:0)'; timeVector; (310:10:450)'];
    else
        timeSignal = [(-450:30:0)'; timeVector; (930:30:1350)'];
    end
    
    figure(1)
    errorbar(timeSignal,muSignal,semSignal)
    hold on
    grid on
    axis([min(timeSignal),max(timeSignal),0.25,3.7])
    title(strcat(targetDate,' (',num2str(timescale),' sec period)'))
    xlabel('Time')
    ylabel('doubling rate of volume (1/hr)')
    legend('fluc','low','ave','high')
    
    
    bvpr_Signal = [meanBVPR(binsPerPeriod/2:binsPerPeriod); meanBVPR; meanBVPR(1:binsPerPeriod/2)];
    bvpr_semSignal = [semBVPR(binsPerPeriod/2:binsPerPeriod); semBVPR; semBVPR(1:binsPerPeriod/2)];
    
    figure(2)
    errorbar(timeSignal,bvpr_Signal,bvpr_semSignal)
    hold on
    grid on
    axis([min(timeSignal),max(timeSignal),0.25,17])
    title(strcat(targetDate,' (',num2str(timescale),' sec period)'))
    xlabel('Time')
    ylabel('biovol production rate (cubic um/hr)')
    legend('fluc','low','ave','high')

end

%% summary plot, with growth responses aligned to nutrient signal according to timestamp

%  Strategy:
%
%     0. initialize complete meta data
%     1. for all experiments in dataset:
%           2. initialize collect experiment date and exclude outliers
%           3. initialize experiment meta data
%           4. load measured data
%           5. for each condition
%                 6. isolate data of interest
%                 7. remove data not in stabilized region
%                 8. remove zeros from mu data (always bounding start and end of tracks)
%                 9. accumulate data points by SHIFTED time bin (period fraction)
%     7. plot for all isolated groups

clc
clear

% 0. initialize analysis parameters
binsPerPeriod = 20;

% 0. initialize complete meta data
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')

dataIndex = find(~cellfun(@isempty,storedMetaData));
experimentCount = length(dataIndex);

%%
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
    concentrations = storedMetaData{index}.concentrations;
    xys = storedMetaData{index}.xys;
    bubbletime = storedMetaData{index}.bubbletime;
    signal_timestamp = storedMetaData{index}.signal_timestamp;
    
    
    % 4. load measured data
    experimentFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',date);
    cd(experimentFolder)
    filename = strcat('lb-fluc-',date,'-window5-width1p4-1p7-jiggle-0p5.mat');
    load(filename,'D','D5','M','M_va','T');
    
    condition = 3; % 3 = stable average condition
    xy_start = storedMetaData{index}.xys(condition,1);
    xy_end = storedMetaData{index}.xys(condition,end);
    stableAveData = buildDM(D5, M, M_va, T, xy_start, xy_end);


    % 5. find average growth rate of stable average condition

    %    i. isolate data
    %stableAveData = dataMatrix(dataMatrix(:,28)== condition,:); 
    stableMus = stableAveData(:,17); % col 17 = mu_va
    stablebioVolPR = stableAveData(:,29); % col 29 = biovol production rate
    stableTime = stableAveData(:,2)/3600; % col 2 = timestamps in sec, covert to hr
    
    %   ii. remove data not in stabilized region
    minTime = 3;  % hr converted to min
    stableMus_trim1 = stableMus(stableTime >= minTime);
    stableBVPR_trim1 = stablebioVolPR(stableTime >= minTime);
    stableTime_trim1 = stableTime(stableTime >= minTime);
    
    if bubbletime(condition) == 0
        stableMus_trim2 = stableMus_trim1;
        stableBVPR_trim2 = stableBVPR_trim1;
        stableTime_trim2 = stableTime_trim1;
    else
        maxTime = bubbletime(condition);
        stableMus_trim2 = stableMus_trim1(stableTime_trim1 <= maxTime);
        stableBVPR_trim2 = stableBVPR_trim1(stableTime_trim1 <= maxTime);
        stableTime_trim2 = stableTime_trim1(stableTime_trim1 <= maxTime);
    end
    
    %   iii. remove zeros from mu data (always bounding start and end of tracks)
    stableMus_trim3 = stableMus_trim2(stableMus_trim2 > 0);
    stableBVPR_trim3 = stableBVPR_trim2(stableMus_trim2 > 0);
    stableTime_trim3 = stableTime_trim2(stableMus_trim2 > 0);
    
    %   iv. calculate mean value for of mu and bvpr in stable
    stableMean_mu = mean(stableMus_trim3);
    stableMean_bvpr = mean(stableBVPR_trim3);
    
    clear stableAveData stableMus stableMus_trim1 stableMus_trim2
    clear stablebioVolPR stableBVPR_trim1 stableBVPR_trim2 stableTime stableTime_trim1 stableTime_trim2
    
    
    
    % 6. for fluctuating condition...
    condition = 1; % 1 = fluctuating nutrient condition
    xy_start = storedMetaData{index}.xys(condition,1);
    xy_end = storedMetaData{index}.xys(condition,end);
    flucData = buildDM(D5, M, M_va, T, xy_start, xy_end);
    
    %    i .isolate data of interest
    %flucData = dataMatrix(dataMatrix(:,28)== 1,:);
    Mus = flucData(:,17); % col 17 = mu_va
    bioVolPR = flucData(:,29); % col 29 = biovol production rate
    Time = flucData(:,2)/3600; % col 2 = timestamps in sec, covert to hr
    clear D D5 M M_va T
    
    
    %    ii. normalize mu and bvpr data by mean of stable average condition
    normalizedMus = Mus/stableMean_mu;
    normalizedBVPR = bioVolPR/stableMean_bvpr;
    
    %    iii. remove data not in stabilized region
    minTime = 3;  % hr converted to min
    nMus_trim1 = normalizedMus(Time >= minTime);
    nBVPR_trim1 = normalizedBVPR(Time >= minTime);
    Time_trim1 = Time(Time >= minTime);
    
    if bubbletime(condition) == 0
        nMus_trim2 = nMus_trim1;
        nBVPR_trim2 = nBVPR_trim1;
        Time_trim2 = Time_trim1;
    else
        maxTime = bubbletime(condition);
        nMus_trim2 = nMus_trim1(Time_trim1 <= maxTime);
        nBVPR_trim2 = nBVPR_trim1(Time_trim1 <= maxTime);
        Time_trim2 = Time_trim1(Time_trim1 <= maxTime);
    end
    
    % 	iv. remove zeros from mu data (always bounding start and end of tracks)
    nMus_trim3 = nMus_trim2(nMus_trim2 > 0);
    nBVPR_trim3 = nBVPR_trim2(nMus_trim2 > 0);
    Time_trim3 = Time_trim2(nMus_trim2 > 0);
    
    % 9. accumulate data by shifted time bin (period fraction)
    %       i. from original timestamp, subtract shift = period/4 + offset
    %          offset = signal timestamp - 900
    timeInSeconds = Time_trim3*3600;
    if  strcmp(date, '2017-11-15') == 1
        disp(strcat(date,': uses timestamp from 2017-10-10 data'))
        offset = 923.4830;
    else
        offset = signal_timestamp - 900; % calcalute shift in signal
    end
    shift = timescale/4 + offset;
    
    %      ii. re-define period to begin at start of high nutrient pulse
    shiftedTimeInSeconds = timeInSeconds - shift;
    
    %     iii. bin data by period fraction
    timeInPeriods = shiftedTimeInSeconds/timescale; % units = sec/sec
    fractionFloors = floor(timeInPeriods);
    timeInPeriodFraction = timeInPeriods - fractionFloors;
    assignedBin = timeInPeriodFraction * binsPerPeriod;
    assignedBin = ceil(assignedBin);
    
    binnedMus = accumarray(assignedBin,nMus_trim3,[],@(x) {x});
    binnedBVPR = accumarray(assignedBin,nBVPR_trim3,[],@(x) {x});
    
    % 10.  convert bin # to absolute time (in seconds)
    timePerBin = timescale/binsPerPeriod;  % in sec
    timeVector = linspace(1, binsPerPeriod, binsPerPeriod);
    timeVector = timePerBin*timeVector';
    
    % 11.  calculate average and s.e.m. per timebin
    meanVector = cellfun(@mean,binnedMus);
    countVector = cellfun(@length,binnedMus);
    stdVector = cellfun(@std,binnedMus);
    semVector = stdVector./sqrt(countVector);
    
    meanBVPR = cellfun(@mean,binnedBVPR);
    countBVPR = cellfun(@length,binnedBVPR);
    stdBVPR = cellfun(@std,binnedBVPR);
    semBVPR = stdBVPR./sqrt(countBVPR);
    
    % 12. plot, with some repetition at ends
    addedFraction = binsPerPeriod/2;
    muSignal = [meanVector; meanVector(1:addedFraction)];
    stdSignal = [stdVector; stdVector(1:addedFraction)];
    semSignal = [semVector; semVector(1:addedFraction)];
    
    bvpr_Signal = [meanBVPR; meanBVPR(1:addedFraction)];
    bvpr_stdSignal = [stdBVPR; meanBVPR(1:addedFraction)];
    bvpr_semSignal = [semBVPR; semBVPR(1:addedFraction)];
    
    
    % create new vector to amend to time and periodFraction signals, allowing for repeat
    additionalPeriodFractions = ((1:addedFraction)+binsPerPeriod)';
    additionalShiftedTimes = additionalPeriodFractions*timePerBin;
    
    % create amended time and periodFraction signals for x axes
    periodFractionSignal = ([(1:binsPerPeriod)'; additionalPeriodFractions])/binsPerPeriod;
    timeSignal = [timeVector; additionalShiftedTimes];
    
    
    %     figure(1)
    %     errorbar(timeSignal,muSignal,semSignal)
    %     hold on
    %     grid on
    %     axis([min(timeSignal),max(timeSignal),0.25,3.7])
    %     title('summary plot: real time vs mu response')
    %     xlabel('Time')
    %     ylabel('doubling rate of volume (1/hr)')
    %     legend(datesForLegend)
    %
    %     figure(2)
    %     errorbar(timeSignal,bvpr_Signal,bvpr_semSignal)
    %     hold on
    %     grid on
    %     axis([min(timeSignal),max(timeSignal),0.25,17])
    %     title('summary plot: real time vs bvpr response')
    %     xlabel('Time')
    %     ylabel('biovolume production rate (cubic um/hr)')
    %     legend(datesForLegend)
    
    figure(5)
    errorbar(periodFractionSignal,muSignal,semSignal)
    hold on
    grid on
    axis([min(periodFractionSignal),max(periodFractionSignal),0,1.2])
    title('summary plot: period fraction vs mu response (as fraction of stable ave)')
    ax = gca;
    ax.XTick = 0:0.25:1.5;
    xlabel('Period Fraction')
    ylabel('doubling rate of volume (1/hr)')
    legend(datesForLegend)
    
    figure(6)
    errorbar(periodFractionSignal,bvpr_Signal,bvpr_semSignal)
    hold on
    grid on
    axis([min(periodFractionSignal),max(periodFractionSignal),0,1.2])
    title('summary plot: period fraction vs bvpr response (as fraction of stable ave)')
    ax = gca;
    ax.XTick = 0:0.25:1.5;
    xlabel('Period Fraction')
    ylabel('Biovolme production rate (cubic um/hr)')
    legend(datesForLegend)
    



end
clearvars -except dataIndex experimentCount exptCounter storedMetaData binsPerPeriod


