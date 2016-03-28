%%  added mass (per cell) over time


%  Goal: Searching responses in biomass accumulation
%        This script plots:
%
%        1. mean added mass (per cell) since birth over time
%        2. mean instantaneous added mass (per cell) over time

%  Last edit: Jen Nguyen, March 28th 2016


% The intended input for these scripts is the following data matrix,
% saved with the naming convention of:

% dmMMDD-cond.mat

%      where,
%              dm  =  dataMatrix                  (see matrixBuilder.m)
%              MM  =  month of experimental date
%              DD  =  day of experimental date
%       condition  =  experimental condition      (fluc or const)
%


%  Strategy:
%
%     0. initialize experiment and analysis parameters
%     1. isolate data of interest
%     2. accumulate data points (of cell cycle stage) by time bin
%     3. calculate mean cell cycle stage per time bin
%     4. plot!
%     


% OK! Lez go!


% 0a. Load data matrices

dmDirectory = dir('dm*.mat'); % note: this assumes the only two data matrices are 'const' and 'fluc'
names = {dmDirectory.name}; % loaded alphabetically

for dm = 1:length(names)
    load(names{dm});                
    dataMatrices{dm} = dataMatrix;                                         % for entire condition
end                                                                        
clear dataMatrix dmDirectory dm;
clear names;

%%   O N E.
%    Plot added mass since birth over time


% 0b. Initialize parameters

expHours = 10; %  duration of experiment in hours                          % 0.  initialize parameters
binFactor = 200; % time bins of 0.005 hr  
hrPerBin = 1/binFactor; 

for condition = 1:2
 
    % 1a.  isolate time and added mass data
    interestingData = dataMatrices{condition};  % condition: 1 = constant, 2 = fluctuating
    addedMass = interestingData(:,10);
    timeStamps = interestingData(:,2);
     
    % 1b.  calculate instantaneous added mass
    instaMass = diff(addedMass);
    instaMass = [0; instaMass];
   
    % 1c.  eliminate zeros (non-full track data and births) and negatives (divisions and noise) from data
    addedMass(addedMass <= 0) = NaN;
    instaMass(instaMass <= 0) = NaN;
    
    % 2.  accumulate data by associated time bin
    timeBins = ceil(timeStamps*binFactor);                                 
    binnedByTime_added = accumarray(timeBins,addedMass,[],@(x) {x});               
    binnedByTime_insta = accumarray(timeBins,instaMass,[],@(x) {x});
    
    % 3a.  calculate mean cell cycle stage per bin
    meanAdded = cell2mat( cellfun(@nanmean,binnedByTime_added,'UniformOutput',false) );      
    meanInsta = cell2mat( cellfun(@nanmean,binnedByTime_insta,'UniformOutput',false) );
    
    % 3b.  calculate std and error
    devAdded = cell2mat(cellfun(@nanstd,binnedByTime_added,'UniformOutput',false));
    nAdded = cell2mat(cellfun(@length,binnedByTime_added,'UniformOutput',false));
    errorAdded = devAdded./sqrt(nAdded);
    
    devInsta = cell2mat( cellfun(@nanstd,binnedByTime_insta,'UniformOutput',false) );
    nInsta = cell2mat( cellfun(@length,binnedByTime_insta,'UniformOutput',false) );
    errorInsta = devInsta./sqrt(nInsta);
    
    % 4a. create a time vector to convert bin # to absolute time
    timeVector = linspace(1, expHours/hrPerBin, expHours/hrPerBin);
    timeVector = hrPerBin*timeVector';                                       
    
    % 4b. before plotting, a little matrix manipulation to get around nans                                                            
    eventMask = find(~isnan(meanAdded));                                   % find indices of cell cycle data
    timeVector = timeVector(eventMask);                                    % trim all nans from time vector
    
    meanAdded = meanAdded(eventMask);                                      % trim all nans from mass vectors
    devAdded = devAdded(eventMask);
    errorAdded = errorAdded(eventMask);
    
    meanInsta = meanInsta(eventMask);                                      % same mask applies!
    devInsta = devInsta(eventMask);
    errorInsta = errorInsta(eventMask);
   
    % 4c. mean added (since birth) with standard deviation
    figure(1)
    if condition == 1
         plot(timeVector,meanAdded,'k')
         axis([0,10,0,5])
         hold on
         grid on
         %errorbar(timeVector,meanAdded, devAdded,'k')
    else
        plot(timeVector,meanAdded,'b')
        hold on
        %errorbar(timeVector,meanAdded,devAdded,'b')
    end

    % 4d. mean added (since birth) with standard error
    figure(2)
    if condition == 1
        plot(timeVector,meanAdded,'k')
        axis([0,10,0,5])
        hold on
        grid on
        errorbar(timeVector,meanAdded,errorAdded,'k')
    else
        plot(timeVector,meanAdded,'b')
        hold on
        errorbar(timeVector,meanAdded,errorAdded,'b')
    end
    
    
    % 4e. insta added with standard deviation
    figure(3)
    if condition == 1
         plot(timeVector,meanInsta,'k')
         axis([0,10,0,.25])
         hold on
         grid on
         %errorbar(timeVector,meanInsta, devInsta,'k')
    else
        plot(timeVector,meanInsta,'b')
        hold on
        %errorbar(timeVector,meanInsta,devInsta,'b')
    end

    % 4d. insta added with standard error
    figure(4)
    if condition == 1
        plot(timeVector,meanInsta,'k')
        axis([0,10,0,.25])
        hold on
        grid on
        errorbar(timeVector,meanInsta,errorInsta,'k')
    else
        plot(timeVector,meanInsta,'b')
        hold on
        errorbar(timeVector,meanInsta,errorInsta,'b')
    end
end


%%   T W O.
%    Instantaneous added mass over time



for condition = 1:2
    
    interestingData = dataMatrices{condition};  % condition: 1 = constant, 2 = fluctuating
    timestamps = interestingData(:,2);
    ccStage = interestingData(:,9);                                            % 0.  isolate time and ccStage vectors
    
    timeBins = ceil(timestamps*200);  % time bins of 0.005 hr                        % 1a. define bin size (time)
    binnedByTime_added = accumarray(timeBins,ccStage,[],@(x) {x});                   % 2.  accumulate data by associated time bin
    
    
    
    
    % A. Generate grid of absolute counts
    
    dataGrid = zeros(10,2000);                                                 % (rows) ccStage: 0 - 1, with 0.1 incr.
    % (columns) time: 0 - 10, with 0.005 incr
    for i = 1:length(binnedByTime_added)
        if isempty(binnedByTime_added{i})
            continue
        else
            stageBins = ceil(binnedByTime_added{i}/.1);                              % 1b. define bin size (cell cycle stage)
            stageBins(stageBins==0) = 1;                                       %     manually include birth into 1st bin
            
            currentTimeStep = binnedByTime_added{i};                                 % 3.  accumulate ccStage into bins
            binnedByStage = accumarray(stageBins(~isnan(stageBins)),currentTimeStep(~isnan(currentTimeStep)),[],@(x){x});
            
            if isempty(binnedByStage)                                          % 4.  some timepoints are empty vectors
                continue                                                       %     due to non-counting of NaNs.
            else                                                               %     by-pass these empty vectors!
                counts = cellfun(@length,binnedByStage,'UniformOutput',false);
                counts = cell2mat(counts);
            end
            
            dataGrid(1:length(counts),i) = counts;
        end
    end
    clear i currentTimeStep binnedByStage counts;
    
    
    
    % B. Normalized grid
    
    countsPerTimePoint = sum(dataGrid);                                        % 5.  find total counts per timepoint
    normalizedByCount = zeros(10,2000);                                        %     divide each bin count by total
    
    for ii = 1:length(dataGrid)
        if countsPerTimePoint(ii) > 0
            normalizedByCount(:,ii) = dataGrid(:,ii)./countsPerTimePoint(ii);
        else
            continue
        end
    end
    
    
    
    % C. Plot!!
    
    figure(1)
    subplot(2,1,condition)
    imagesc(normalizedByCount,[0.02 .1])
    axis xy
    axis([0,2000,1,10])
    colorbar
    hold on
    
end










