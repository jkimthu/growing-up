%% revealBirths


% Goal: Reveal histogram of birth events over time, normalized by current cell count.

%       Like nSync.m and spin-offs, this script looks for cell cycle synchronization.
%       Unlike the others, this is a simple glance at the distribution of
%           birth events over the course of our experiments.
   


%  Last edit: Jen Nguyen, 2017 Sept 25



% As of Sept 2017, this script uses function, buildDM, instead of specific
% matrixBuilder.m data outputs. The overall concept is still similar.


% In these matrices is a column (#5) of boolean values:
%      where,
%               0  =  timepoint falls within a growth curve
%               1  =  occurrence of birth / division event 


% Strategy:
%
%      0.  initialize data and binning parameters
%      1.  specify current condition of interest
%               2.  isolate data from current condition
%               3.  accumulate drops (division events) by time bin
%               4.  convert bin # to absolute time
%               5.  count birth events per timebin
%               6.  count number of tracks per timebin
%               7.  plot scatter over time
%               8.  plot histogram of normalized birth events over time
%      9.  repeat for all conditions

% OK! Lez go!


%%
% 0. initialize data

clc
clear

% trimmed dataset
load('lb-monod-2017-09-20-jiggle-0p1.mat','D5','T');
dataMatrix = buildDM(D5,T);

% 0. initialize binning parameters
expHours = 10;          % duration of experiment in hours                      
binFactor = 20;         % bins per hour
hrPerBin = 1/binFactor; % hour fraction per bin


%%
% 1. specify current condition of interest
totalCond = max(dataMatrix(:,35)); % col 35 = condition value

for condition = 1:totalCond
    
    % 2. isolate data from current condition
    interestingData = dataMatrix(dataMatrix(:,35) == condition,:);

    % 3. accumulate drops by time bin
    drops = interestingData(:,5);
    timestamps = interestingData(:,2)/3600; % time in seconds converted to hours
    timeBins = ceil(timestamps*binFactor);                
    binnedDrops = accumarray(timeBins,drops,[],@(x) {x});  
    
    % 4. accumulate track count by time bin
    %tracks = interestingData(:,34); % col 34 = total track number (not track ID as assigned during particle tracking by individual movies)
    %binnedTracks = accumarray(timeBins,tracks,[],@(x) {x});
    
    % 4. convert bin # to absolute time
    %timeVector = linspace(1, expHours/hrPerBin + 1, expHours/hrPerBin + 1);         
    timeVector = linspace(1, max(timeBins), max(timeBins));
    timeVector = hrPerBin*timeVector';  
    
    % 5. count birth events per timebin
    birthEvents = zeros(max(timeBins),1);
    for i = 1:length(binnedDrops)
        
        birthEvents(i) = sum(binnedDrops{i});                                  
          
    end
    clear i;
    
    % 6.  count number of tracks per timebin
    numTracks = cell2mat(cellfun(@length,binnedDrops,'UniformOutput',false));
    
    % 6. normalize with number of tracks present in at timepoint
    %numTracks(binFactor*expHours,1) = 0;
    birthHisto = birthEvents./numTracks;
    
    % 7. plot scatter vs. time
    figure(1)
    plot(timeVector,birthHisto,'o')
    axis([0,10.1,0,.35])
    hold on
    xlabel('Time (hr)')
    ylabel('Births per capita')
    legend('full LB','1/2 LB','1/4 LB','1/8 LB','1/16 LB','1/32 LB'); 
    
    % 8. plot histogram of normalized birth events vs time
    figure(2)
    subplot(totalCond,1,condition)
    bar(timeVector,birthHisto)
    axis([0,10.1,0,.4])
    hold on
    grid on
    xlabel('Time (hr)')
    ylabel('Births per capita')
    legend(num2str(condition)); 
    
    clear interestingData drops timestamps timeBins binnedDrops timeVector
    clear birthEvents numTracks birthHisto
    
    % 9.  repeat for all conditions
end


