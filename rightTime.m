%% (at the) rightTime


% Goal: Searching for any influence of nutrient environment on the cell cycle.

%       Like nsyncNFlux.m, this script follows cell cycle behavoir over a single nutrient period.
%       Key difference: this script plots the average cell cycle duration of
%                       cells born within a given increment of the nutrient period.


%  Last edit: Jen Nguyen, February 24th 2016




% Growth phase is defined as a specific fraction of the growth curve, as
% calculated and assembled in matrixBuilder.
%
% The intended input for these scripts is the following data matrix,
% saved with the naming convention of:

% dmMMDD-cond.mat

%      where,
%              dm  =  dataMatrix                  (see matrixBuilder.m)
%              MM  =  month of experimental date
%              DD  =  day of experimental date
%       condition  =  experimental condition      (fluc or const)



%  Strategy:
%
%     0. initialize experimental and analytical parameters
%     1. isolate data of interest
%     2. assign all timestamps a period fraction
%     3. determine which individuals were born in which period fraction
%     4. accumulate cell cycle duration of those individuals by period fraction
%     5. average durations
%     6. plot !
    


% OK! Lez go!

%%

% Initialize data.

dmDirectory = dir('dm*.mat'); % note: this assumes the only two data matrices are 'const' and 'fluc'
names = {dmDirectory.name}; % loaded alphabetically

for dm = 1:length(names)
    load(names{dm});                
    dataMatrices{dm} = dataMatrix;
end                                                                        

clear dataMatrix dmDirectory dm;
clear names;


% 0. initialize experimental parameters
expHours = 10; %  duration of experiment in hours                      

% 0. initialize time binning parameters
periodDuration = 1;%0.25;                           % duration of nutrient period in hours                 
binsPerHour = 200;                                  % bPH of 200 = time bins of 0.005 hours (18 sec)
hrPerBin = 1/binsPerHour;                           % bPH of 40  = time bins of 0.025 hours (1.5 min)

% 0. initialize time vector for plotting
binsPerPeriod = periodDuration/hrPerBin;
periodTime = linspace(1, binsPerPeriod, binsPerPeriod);
periodTime = hrPerBin*periodTime';                                       

% 0. initialize looping parameters for analysis
firstHour = 5;                                      % time at which to initate analysis
finalHour = 10;                                     % time at which to terminate analysis
firstTimepoint = firstHour*binsPerHour + 1;         % calculate first timepoint (row number in binnedByTime)
numPeriods = (finalHour-firstHour)/periodDuration;  % number of periods of interest
totalPeriods = finalHour/periodDuration;            % total periods in experiment


for condition = 1:2;                                  % for looping between conditions
 
    % 1. isolate data of interest
    interestingData = dataMatrices{condition};      % condition: 1 = constant, 2 = fluctuating
    currentTimepoint = firstTimepoint;              % initialize first timepoint as current timepoint
    
    timeStamps = interestingData(:,2);
    durations = interestingData(:,8);               % col #8 = curve duration
    durations(durations==0) = NaN;                  % to avoid zeros while averaging
    
    % 2a. bin data by time
    timeBins = ceil(timeStamps*binsPerHour);
    binnedByTime = accumarray(timeBins,durations,[],@(x) {x});
    binnedByTime{expHours/hrPerBin,1} = [];
    
    % 2b. average data points per time bin (and count, for normalization downstream)
    notNormalized = cell2mat( cellfun(@nanmean,binnedByTime,'UniformOutput',false) );
    countsPerTimeBin = cell2mat( cellfun(@length,binnedByTime,'UniformOutput',false) );
    
    % 2b. associate time bin with appropriate period fraction
    periodFraction = [];
    for p = 1:totalPeriods
        periodFraction = [periodFraction; periodTime];
    end
    clear p;
    periodIntegers = floor(periodFraction.*binsPerHour);          % accumarray requires integers
    binnedByPeriod = accumarray(periodIntegers,notNormalized,[],@(x) {x});
    countsByPeriod = accumarray(periodIntegers,countsPerTimeBin,[],@(x) {x});

   
    % 3. average accumulated averages, accounting for original counts
    normalizedDuration = zeros(binsPerPeriod,1);
    for f = 1:binsPerPeriod
        if isempty(binnedByPeriod{f})
            continue
        else
            averages = binnedByPeriod{f};
            counts = sum(countsByPeriod{f});
            weights = countsByPeriod{f}/counts;
            normalized = averages.*weights;
            normalizedDuration(f) = nansum(normalized);
        end
    end
    clear f;
    
    
    % 4. plot mean over period fraction
    %    ...but before plotting, remove zeros and nans
    normalizedDuration(normalizedDuration==0) = NaN;
    eventMask = find(~isnan(normalizedDuration));                      % find indices of cell cycle data
    normalizedDuration = normalizedDuration(eventMask);                % trim all nans from ccStage vector
    currentTime = periodTime;
    currentTime = currentTime(eventMask);                              % trim all nans from time vector
    currentFraction = currentTime./periodDuration;
    
    figure(1)
    if condition == 1
        plot(currentFraction,normalizedDuration,'k')   % constant
        axis([0,1,0,5])
        grid on
        hold on
    else
        plot(currentFraction,normalizedDuration,'b')   % fluctuating (blue)
    end
    


end

