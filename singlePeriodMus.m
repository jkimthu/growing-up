% singlePeriodMus



%  Goal: plot average of mus, binned by period fraction

%  Last edit: Jen Nguyen, 2017 Oct 13



%  Sample code pulled from distributions.m and nsyncInFlux.m
%  Strategy:
%
%     0. initialize experiment and analysis parameters
%     1. isolate data of interest
%     2. remove data not in stabilized region
%     3. accumulate data points by time bin (period fraction)
%     4. plot for all isolated groups


%%
clear

% 0. Load workspace from SlidingFits.m    
load('lb-fluc-2017-10-10-window5-width1p4v1p7-jiggle-0p5-bigger1p8.mat');
load('meta.mat');
meta = meta_2017oct10;

dataMatrix = buildDM(D5,M,T);
%%
% 0. Initialize period fractioning
periodLength = 5;                   % in min
binsPerPeriod = 30;
timePerBin = 5*60/30;               % in sec

% 0. initialize analysis parameters
%%
for condition = 1:4
    
    % 1. isolate data of interest
    conditionData = dataMatrix(dataMatrix(:,35)==condition,:);
    Mus = conditionData(:,4); % col 4 = mus
    Time = conditionData(:,2)/60; % col 2 = timestamps in sec, covert to min
    
    % 2. remove data not in stabilized region
    minTime = meta(condition,3)*60;  % hr converted to min
    maxTime = meta(condition,4)*60;
    
    % i. remove mu data with timestamps prior to and after stabilization
    Mus_trim1 = Mus(Time >= minTime);
    Time_trim1 = Time(Time >= minTime);
    %plot(Time_trim1,Mus_trim1,'o')
    
    Mus_trim2 = Mus_trim1(Time_trim1 <= maxTime);
    Time_trim2 = Time_trim1(Time_trim1 <= maxTime);
    %plot(Time_trim2,Mus_trim2,'o')
    
    % i. remove zeros (always two at start and end of track) and negatives
    Mus_trim3 = Mus_trim2(Mus_trim2 > 0);
    Time_trim3 = Time_trim2(Mus_trim2 > 0);
        
    
    % 3. accumulate data points by time bin (period fraction)
    timeWarp = Time_trim3/periodLength; % units = seconds/seconds
    floorWarp = floor(timeWarp);
    timeBins = timeWarp - floorWarp;
    rightBin = timeBins * binsPerPeriod;
    rightBin = ceil(rightBin);
        
    binnedMus = accumarray(rightBin,Mus_trim3,[],@(x) {x});
    
    % 4.  convert bin # to absolute time (in seconds)
    timeVector = linspace(1, binsPerPeriod, binsPerPeriod);
    timeVector = timePerBin*timeVector'; 
    
    
    % 5.  calculate average and s.e.m. per timebin
    meanVector = cellfun(@mean,binnedMus);
    countVector = cellfun(@length,binnedMus);
    stdVector = cellfun(@std,binnedMus);
    semVector = stdVector./sqrt(countVector);
    
    
    % 6. plot
    figure(1)
    errorbar(timeVector,meanVector,semVector)
    hold on
    grid on
    axis([-0.2,300.2,0.25,3.2])
    xlabel('Time')
    ylabel('elongation rate (1/hr)')
    legend('fluc','low','ave','high')

end

%%

