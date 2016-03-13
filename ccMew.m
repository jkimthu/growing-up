%% ccMew


% Goal: Is cell cycle stage a function of instantaneous growth rate?

%       This script accumulates cell cycle fraction data into instantaneous
%       growth rate bins, and plots a scatter. 
  


%  Last edit: Jen Nguyen, March 13th 2016



% The intended input for these scripts is the following data matrix,
% saved with the naming convention of:

% dmMMDD-cond.mat

%      where,
%              dm  =  dataMatrix                  (see matrixBuilder.m)
%              MM  =  month of experimental date
%              DD  =  day of experimental date
%       condition  =  experimental condition      (fluc or const)
%


% OK! Lez go!

%%

% Initialize data.

dmDirectory = dir('dm*.mat'); % note: this assumes the only two data matrices are 'const' and 'fluc'
names = {dmDirectory.name}; % loaded alphabetically

for dm = 1:length(names)
    load(names{dm});                
    dataMatrices{dm} = dataMatrix;                                         % for entire condition
end                                                                        

clear dataMatrix dmDirectory dm;
clear names;


%%

%  Stragety:
%   
%     0. initialize
%     1. isolate data of interest (ccStage and mu)
%     2. determine bin size for mu
%     3. accumulate ccStage based on mu bins
%     4. calculate mean, std, n, error
%     5. plot!


for condition = 1:2          % 1 = constant, 2 = fluctuating
    
    interestingData = dataMatrices{condition};
    
    % 1. isolate mu and ccStage data
    Mu = interestingData(:,4);
    ccStage = interestingData(:,9);
    
    
    % 2. determine bin size for mu
    
    % replace all values of Mu > 1 or Mu <= 0 with NaN
    trimmedMu = Mu;
    trimmedMu(trimmedMu > 1) = NaN;
    trimmedMu(trimmedMu <= 0) = NaN;
    %histogram(trimmedMu)
    
    % remove NaNs from data sets
    nanFilter = find(~isnan(trimmedMu));
    trimmedMu = trimmedMu(nanFilter);
    trimmedStages = ccStage(nanFilter);
    
    % create binning vector such that bin size = 0.05 1/hr
    muBins = ceil(trimmedMu*20);
    
    
    % 3. accumulate ccStage by binned growth rates
    binnedByMu = accumarray(muBins,trimmedStages,[],@(x) {x});
    
    
    % 4. calculate mean, std, n, and error
    meanStage = cell2mat( cellfun(@nanmean,binnedByMu,'UniformOutput',false) );
    stdStage = cell2mat( cellfun(@nanstd,binnedByMu,'UniformOutput',false) );
    nStage = cell2mat( cellfun(@length,binnedByMu,'UniformOutput',false) );
    errorStage = stdStage./sqrt(nStage);
    
    
    % 5. plot
    if condition == 1
        plot(meanStage,'k')
        hold on
        errorbar(meanStage,stdStage,'k')
    else
        plot(meanStage,'b')
        hold on
        errorbar(meanStage,stdStage,'b')
    end
    
end
%%


%
for condition = 1:2;                                  % for looping between conditions
    
    interestingData = dataMatrices{condition};      % condition: 1 = constant, 2 = fluctuating
    currentTimepoint = firstTimepoint;              % initialize first timepoint as current timepoint
    
    % 1. isolate time and ccStage data
    timeStamps = interestingData(:,2);
    ccStage = interestingData(:,9);
    
    % 2. accumulate data by associated time bin
    timeBins = ceil(timeStamps*binsPerHour);
    binnedByTime = accumarray(timeBins,ccStage,[],@(x) {x});
    
    for period = 1:numPeriods
        
        % 3. establish current period in loop
        currentPeriod = currentTimepoint:(currentTimepoint + binsPerPeriod -1);
        if period < numPeriods
            currentStages = binnedByTime(currentPeriod);
        else
            currentStages = binnedByTime(currentTimepoint:end);
        end
        currentTimepoint = currentTimepoint + binsPerPeriod; % re-define currentTimepoint for next loop cycle
        
        % 4. calculate mean cell cycle stage per time bin within current period
        meanStage = cell2mat( cellfun(@nanmean,currentStages,'UniformOutput',false) );
        stdStage = cell2mat( cellfun(@nanstd,currentStages,'UniformOutput',false) );
        nStage = cell2mat( cellfun(@length,currentStages,'UniformOutput',false) );
        errorStage = stdStage./sqrt(nStage);
        
        % 5. plot mean for current period
        %    ...but before plotting, remove nans from cell cycle and time data
        eventMask = find(~isnan(meanStage));                                       % find indices of cell cycle data
        meanStage = meanStage(eventMask);                                          % trim all nans from ccStage vector
        currentTime = periodTime;
        currentTime = currentTime(eventMask);                                          % trim all nans from time vector
        currentFraction = currentTime./periodDuration;
        
        figure(1)
        if condition == 1
            plot(currentFraction,meanStage,'color',[0,0,0]+(1/period)*[1,1,1],'linewidth',1.01)   % constant
            axis([0,1,0,1])
            grid on
            hold on
        else
            plot(currentFraction,meanStage,'color',[0.1,0,1]+(1/period)*[0.2,0.6,0],'linewidth',1.01)   % fluctuating (blue)
            hold on
        end
        
    end
    clear period

end

