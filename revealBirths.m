%% revealBirths


% Goal: Reveal histogram of birth events in growth data.

%       Like nSync.m and spin-offs, this script looks for cell cycle synchronization.
%       Unlike the others, this is a simple glance at the distribution of
%           birth events over the course of our experiments.
   


%  Last edit: Jen Nguyen, February 22nd 2016



% The intended input for these scripts is the following data matrix,
% saved with the naming convention of:

% dmMMDD-cond.mat

%      where,
%              dm  =  dataMatrix                  (see matrixBuilder.m)
%              MM  =  month of experimental date
%              DD  =  day of experimental date
%       condition  =  experimental condition      (fluc or const)


% In these matrices is a column (#5) of boolean values:
%      where,
%               0  =  timepoint falls within a growth curve
%               1  =  occurrence of birth / division event 


% Strategy:
%
%      0.  initialize data and parameters
%      1.  find indices where drop? == 1
%      2.  match indices with corresponding timestamp
%      3.  count events within incremental bins of time
%      4.  plot as a histogram of event counts vs. time


% OK! Lez go!


%%
%   Initialize.

% data
dmDirectory = dir('dm*.mat'); % note: this assumes the only two data matrices are 'const' and 'fluc'
names = {dmDirectory.name}; % loaded alphabetically

for dm = 1:length(names)
    load(names{dm});                
    dataMatrices{dm} = dataMatrix;                                         % for entire condition
end                                                                        

% parameters
expHours = 10; %  duration of experiment in hours                      
binFactor = 200; % time bins of 0.005 hr  
hrPerBin = 1/binFactor; 

clear dataMatrix dmDirectory dm;
clear names;

%
%   Find and plot birth events.

for condition = 1:2
    
    interestingData = dataMatrices{condition};  % condition: 1 = constant, 2 = fluctuating
    timestamps = interestingData(:,2);
    drops = interestingData(:,5);                                              % isolate time and drop data
    
    timeBins = ceil(timestamps*binFactor);  % time bins of 0.005 hr                  % define bin size (time)
    binnedByTime = accumarray(timeBins,drops,[],@(x) {x});                     % accumulate drops by associated time bin
    
    timeVector = linspace(1, expHours/hrPerBin, expHours/hrPerBin);            % as exact timestamps vary between xy positions,
    timeVector = hrPerBin*timeVector';                                         % create a time vector to convert bin # to absolute time
    
    birthHisto = zeros(binFactor*expHours,1);
    for i = 1:length(binnedByTime)
        
        birthHisto(i) = sum(binnedByTime{i});                                  % count birth events per timebin
        
    end
    clear i;
    
    figure(1)
    subplot(2,1,condition)
    bar(timeVector,birthHisto)
    axis([0,10,0,12])
    hold on
    
end

