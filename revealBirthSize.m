%% revealBirthSize

% Goal: Plot mean birth size over time

%       Like revealDurations.m, this script looks for an evolution of cell cycle behavior.
%       Unlike it, this calculates an average of the size at birth across time.
   


%  Last edit: Jen Nguyen, 2017 Sept 27



% As of Sept 2017, this script uses function, buildDM, instead of specific
% matrixBuilder.m data outputs. The overall concept is still similar.



% Strategy:
%
%      0.  initialize data and binning parameters
%      1.  specify current condition of interest
%               2.  isolate data from current condition
%               3.  accumulate size at birth data by timebin
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
binFactor = 6;         % bins per hour
hrPerBin = 1/binFactor; % hour fraction per bin

%%
% 1.  specify current condition of interest
totalCond = max(dataMatrix(:,35)); % col 35 = condition value

for condition = 1:totalCond
    
    % 2.  isolate data from current condition
    interestingData = dataMatrix(dataMatrix(:,35) == condition,:);
    
    % 3.  accumulate size at birth data by timebin
    
    % i. isolate length and time data
    allLengths = interestingData(:,3); % col 3 = measured lengths (um)
    timestamps = interestingData(:,2)/3600; % time in seconds converted to hours
    
    % ii. select rows where isDrop = 1
    isDrop = interestingData(:,5);
    birthTimes = timestamps(isDrop == 1);
    birthSizes = allLengths(isDrop == 1);
    
    % iii. convert birthTimes into timebins
    timeBins = ceil(birthTimes*binFactor);                
    binnedSizes = accumarray(timeBins,birthSizes,[],@(x) {x});
    
    
    % 4.  convert bin # to absolute time
    timeVector = linspace(1, max(timeBins), max(timeBins));
    timeVector = hrPerBin*timeVector'; 
    
    
    % 5.  calculate average and s.e.m. per timebin
    meanVector = cellfun(@mean,binnedSizes);
    countVector = cellfun(@length,binnedSizes);
    stdVector = cellfun(@std,binnedSizes);
    semVector = stdVector./sqrt(countVector);
    
    
    % 6.  plot!
    figure(1)
    errorbar(timeVector,meanVector,semVector)
    axis([0,10.3,1,8])
    hold on
    xlabel('Time (hr)')
    ylabel('Doubling time + s.e.m. (min)')
    legend('full LB','1/2 LB','1/4 LB','1/8 LB','1/16 LB','1/32 LB'); 
    
    figure(2)
    errorbar(timeVector,meanVector,stdVector)
    axis([0,10.3,0,10])
    hold on
    xlabel('Time (hr)')
    ylabel('Doubling time + standard dev (min)')
    legend('full LB','1/2 LB','1/4 LB','1/8 LB','1/16 LB','1/32 LB'); 
    
    figure(3)
    histogram(birthSizes,'Normalization','pdf')
    axis([0,20,0,0.75])
    hold on
    xlabel('Size at birth (um)')
    ylabel('pdf')
    legend('full LB','1/2 LB','1/4 LB','1/8 LB','1/16 LB','1/32 LB');
    
    figure(4)
    histogram(birthSizes,'Normalization','pdf')
    axis([0,12,0,0.75])
    hold on
    xlabel('Size at birth (um)')
    ylabel('fraction of population')
    legend('full LB','1/2 LB','1/4 LB','1/8 LB','1/16 LB','1/32 LB');
    
    % 7. repeat for all conditions
end

               






