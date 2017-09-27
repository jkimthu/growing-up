%% revealDurations

% Goal: Plot mean cell cycle duration over time

%       Like revealBirths.m, this script looks for an evolution of cell cycle behavior.
%       Unlike it, this calculates an average of the durations across time.
   


%  Last edit: Jen Nguyen, 2017 Sept 27



% As of Sept 2017, this script uses function, buildDM, instead of specific
% matrixBuilder.m data outputs. The overall concept is still similar.


% Strategy:
%
%      0.  initialize data and binning parameters
%      1.  specify current condition of interest
%               2.  isolate data from current condition
%               3.  accumulate cell cycle duration data by timebin
%               4.  convert bin # to absolute time
%               5.  calculate average and s.e.m. per timebin
%               6.  plot!
%      7.  repeat for all conditions


% OK! Lez go!

%%
%   Initialize.

% 0. initialze data
clc
clear

% trimmed dataset
load('lb-monod-2017-09-20-jiggle-0p1.mat','D5','T');
dataMatrix = buildDM(D5,T);

% 0. initialize binning parameters
expHours = 10;          % duration of experiment in hours                      
binFactor = 12;         % bins per hour
hrPerBin = 1/binFactor; % hour fraction per bin

%%
% 1.  specify current condition of interest
totalCond = max(dataMatrix(:,35)); % col 35 = condition value

for condition = 1:totalCond
    
    % 2.  isolate data from current condition
    interestingData = dataMatrix(dataMatrix(:,35) == condition,:);
    
    % 3.  accumulate cell cycle duration data by timebin
    
    %     note: in data matrix, curve durations lists a value of 0 for
    %           incomplete curve. thus, we must not include zeros in analysis.
    
    %     solution: so that we can apply the same rows to time data, 
    %               select rows based on the following scheme:
    %                   i. find all non-zero duration times
    %                  ii. select rows from (i) where isDrop = 1 (col 5)
    %                 iii. convert birthTimes into timebins
    
    % i .find all non-zero duration times
    allDurations = interestingData(:,8)/60; % col 8 = curve durations
    timestamps = interestingData(:,2)/3600; % time in seconds converted to hours
    
    fullCycles = allDurations(allDurations > 0);
    fullTimes = timestamps(allDurations > 0);
    
    % ii. select rows from (i) where isDrop = 1
    isDrop = interestingData(:,5);
    fullDrops = isDrop(allDurations > 0);
    
    uniqueDurations = fullCycles(fullDrops == 1);
    birthTimes = fullTimes(fullDrops == 1);
    
    % iii. convert birthTimes into timebins
    timeBins = ceil(birthTimes*binFactor);                
    binnedDurations = accumarray(timeBins,uniqueDurations,[],@(x) {x});
    
    
    % 4.  convert bin # to absolute time
    timeVector = linspace(1, max(timeBins), max(timeBins));
    timeVector = hrPerBin*timeVector'; 
    
    
    % 5.  calculate average and s.e.m. per timebin
    meanVector = cellfun(@mean,binnedDurations);
    countVector = cellfun(@length,binnedDurations);
    stdVector = cellfun(@std,binnedDurations);
    semVector = stdVector./sqrt(countVector);
    
    
    % 6.  plot!
    figure(1)
    errorbar(timeVector,meanVector,semVector)
    axis([0,10,0,60])
    hold on
    xlabel('Time (hr)')
    ylabel('Doubling time + s.e.m. (min)')
    legend('full LB','1/2 LB','1/4 LB','1/8 LB','1/16 LB','1/32 LB'); 
    
    figure(2)
    errorbar(timeVector,meanVector,stdVector)
    axis([0,10,0,60])
    hold on
    xlabel('Time (hr)')
    ylabel('Doubling time + standard dev (min)')
    legend('full LB','1/2 LB','1/4 LB','1/8 LB','1/16 LB','1/32 LB');
    
    figure(3)
    histogram(uniqueDurations,'Normalization','pdf')
    axis([0,80,0,0.25])
    hold on
    xlabel('cell cycle duration (min)')
    ylabel('fraction of population')
    legend('full LB','1/2 LB','1/4 LB','1/8 LB','1/16 LB','1/32 LB');
    
    figure(4)
    subplot(totalCond,1,condition)
    histogram(uniqueDurations,'Normalization','pdf')
    axis([0,80,0,0.25])
    hold on
    xlabel('cell cycle duration (min)')
    ylabel('fraction of population')
    legend(num2str(condition));
    
    % 7. repeat for all conditions
end

               






