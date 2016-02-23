%% revealDurations

% Goal: Plot mean cell cycle duration over time

%       Like revealBirths.m, this script looks for an evolution of cell cycle behavoir.
%       Unlike it, this calculates an average of the durations across time.
   


%  Last edit: Jen Nguyen, February 23nd 2016



% The intended input for these scripts is the following data matrix,
% saved with the naming convention of:

% dmMMDD-cond.mat

%      where,
%              dm  =  dataMatrix                  (see matrixBuilder.m)
%              MM  =  month of experimental date
%              DD  =  day of experimental date
%       condition  =  experimental condition      (fluc or const)


% In these matrices is a column (#8) of doubles, one for each cell at any
% given timepoint.


% Strategy:
%
%      0.  initialize data and parameters
%      1.  bin durations by corresponding timestamp
%      2.  caculated average and s.e.m. per timestep
%      3.  plot !

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
    durations = interestingData(:,8);                                          
    
    % accumulate durations by time bin
    timeBins = ceil(timestamps*binFactor);                
    binnedByTime = accumarray(timeBins,durations,[],@(x) {x});                     
    
    % convert bin # to absolute time
    timeVector = linspace(1, expHours/hrPerBin, expHours/hrPerBin);         
    timeVector = hrPerBin*timeVector';                                         
    
    % find average duration per timebin EXCLUDING zeros
    duration = zeros(expHours/hrPerBin,1);
    sem = zeros(expHours/hrPerBin,1);
    for i = 1:length(binnedByTime)
        if isempty(binnedByTime{i})
            continue
        else
            woz = binnedByTime{i};          % without zeros
            woz(woz==0) = NaN;
            meanWOZ = nanmean(woz);
            stdWOZ = nanstd(woz);
            totalWOZ = sum(~isnan(woz));
            sem(i,1) = stdWOZ / sqrt(totalWOZ);
            duration(i,1) = meanWOZ;
        end
    end
    
    % remove zeros and NaNs for plotting simplicity
    duration(duration==0) = NaN;
    mask = find(~isnan(duration));
    duration = duration(mask);
    sem = sem(mask);
    timeVector = timeVector(mask);

    
    figure(1)
    if condition == 1
        plot(timeVector,duration,'k')
        axis([0,10,1,5])
        hold on
    else
        plot(timeVector,duration,'b')
    %hold on
    %errorbar(timeVector,duration,sem)
    end
    
end





