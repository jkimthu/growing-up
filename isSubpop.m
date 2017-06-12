%% isSubpop?

% Goal: this script aims to find subpopulations in our growth experiments

%       the final figure (four panels) plots the distribution unique tracks
%       across bins of doubling rate.
%
%       the four panels sample four distinct time periods on population
%       level observations of doubling rate, and compare distributions
%       between two experimental conditions.
%

% Strategy:
%           0. initialize data matrix
%           1. time period of interest
%                2. isolate condition of interest
%                     3. collect mu and track ID 
%                     4. bin mu and track ID's according to mu
%                     5. count unique track ID's per bin
%                     6. normalize counts by total for fraction of population
%                     7. plot histogram onto subplot (according to time period)
%                8. repeat for second condition of interest                   
%           9. repeat for all time periods of interest


% last edit: jen, 2017 May 31

% OK LEZ GO!

%%

% 0. initialize data matrix
clear
load('dm-2017-05-26.mat');

conditions = [1,2,3,4,5,6];
c = 1;
%%

% 1. define time periods of interest
periods = [1,3,7,9]; % first(0-1 hr), third(2-3), sixth(5-6), and ninth(8-9)

for i=1:length(periods);
    
    timeByHour = ceil(dataMatrix(:,2));
    interestingTimePeriod = find(timeByHour == periods(i));
    currentPeriodData = dataMatrix(interestingTimePeriod,:);
    
    
    % 2. isolate condition of interest
    for condition = 1:2:3
        
        interestingCondition = find(currentPeriodData(:,28) == condition);
        currentConditionData = currentPeriodData(interestingCondition,:);
        
        
        % 3. collect mu data and track IDs
        currentMus = currentConditionData(:,18);
        currentTracks = currentConditionData(:,1);
        
        
        % 4. bin mu data into 0.1 sized bins
        binnedMus = ceil(currentMus*10);
        
        % 4. remove negative growth rates
        binnedMus(binnedMus < 0) = NaN;
        nanFilter = find(~isnan(binnedMus)); %find values that are NOT nan
        binnedMus = binnedMus(nanFilter);
        currentTracks = currentTracks(nanFilter);
        
        
        % 4. accumulate track IDs according to mu bins
        binnedMus = binnedMus+1;
        tracksBinnedByMu = accumarray(binnedMus,currentTracks,[],@(x) {x});
        
        
        % 5. count unique tracks per bin
        for t = 1:length(tracksBinnedByMu)
            uniqueTracks = unique(tracksBinnedByMu{t});
            trackCountsPerBin(t,1) = length(uniqueTracks);
            clear uniqueTracks;
        end
        
        
        % 6. normalize by total counts for population fraction
        totalCounts = sum(trackCountsPerBin)
        popFractionPerBin = trackCountsPerBin/totalCounts;
        
        % 7. plot bars of population fraction
        if condition > c
            subplot(1,4,i)
            barh(popFractionPerBin,0.25,'FaceColor',[0 0.7 0.7])
            title(periods(i))
            axis([0,.5,0,25])

        else
            subplot(1,4,i)
            barh(popFractionPerBin,0.5)
            title(periods(i))
            axis([0,.5,0,25])
            
            hold on
        end
        xlabel('Fraction of populations')
        ylabel('doubling rate bin')
        legend('1 uM','100mM');
        
    end
end