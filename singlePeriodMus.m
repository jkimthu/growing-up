% singlePeriodMus



%  Goal: plot average of mus, binned by period fraction

%  Last edit: Jen Nguyen, 2017 Dec 13



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


%% 0. initialize target experiment and analysis parameters
clear
clc

% 0. initialize period fractioning
binsPerPeriod = 30;

% 0. identify data of interest
targetDate = '2017-11-15';

%% 1. initialize experiment meta and measured data

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

%%
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

%%

