%% ccAddedMass


% Goal: Is cell cycle stage a function of current added mass?

%       This script accumulates cell cycle fraction data into incremental
%       mass added bins, and plots a mean line with error. 
%
%       x axis: mass added since birth
%       y axis: mean cell cycle stage


%  Last edit: Jen Nguyen, March 14th (pi day!) 2016



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
%     1. isolate data of interest (ccStage and mass)
%     2. determine bin size for mass
%     3. accumulate ccStage based on mass bins
%     4. calculate mean, std, n, error
%     5. plot!


for condition = 1:2          % 1 = constant, 2 = fluctuating
    
    interestingData = dataMatrices{condition};
    
    % 1. isolate mu and ccStage data
    addedMass = interestingData(:,10);
    ccStage = interestingData(:,9);
    
    
    % 2. determine bin size for mu
    
    % replace all values of Mu > 1 or Mu <= 0 with NaN
    trimmedMass = addedMass;
    trimmedMass(trimmedMass > 1) = NaN;
    trimmedMass(trimmedMass <= 0) = NaN;
    %histogram(trimmedMu)
    
    % remove NaNs from data sets
    nanFilter = find(~isnan(trimmedMass));
    trimmedMass = trimmedMass(nanFilter);
    trimmedStages = ccStage(nanFilter);
    
    % create binning vector such that bin size = 0.05 1/hr
    muBins = ceil(trimmedMass*20);
    
    
    % 3. accumulate ccStage by binned growth rates
    binnedByMass = accumarray(muBins,trimmedStages,[],@(x) {x});
    
    
    % 4. calculate mean, std, n, and error
    meanStage = cell2mat( cellfun(@nanmean,binnedByMass,'UniformOutput',false) );
    stdStage = cell2mat( cellfun(@nanstd,binnedByMass,'UniformOutput',false) );
    nStage = cell2mat( cellfun(@length,binnedByMass,'UniformOutput',false) );
    errorStage = stdStage./sqrt(nStage);
    
    
    % 5. plot mean and std
    figure(1)
    if condition == 1
        plot(meanStage,'k')
        axis([0,21,0,1])
        hold on
        grid on
        errorbar(meanStage,stdStage,'k')
    else
        plot(meanStage,'b')
        hold on
        errorbar(meanStage,stdStage,'b')
    end
    
    figure(2)
        if condition == 1
        plot(meanStage,'k')
        axis([0,21,0,1])
        hold on
        grid on
        errorbar(meanStage,errorStage,'k')
    else
        plot(meanStage,'b')
        hold on
        errorbar(meanStage,errorStage,'b')
    end
end


