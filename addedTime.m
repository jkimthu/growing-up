%%  added mass (per cell) over time


%  Goal: Searching responses in biomass accumulation
%        This script plots mean added mass (per cell) since birth over time


%  Last edit: Jen Nguyen, March 27th 2016


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


% 0b. Initialize parameters

expHours = 10; %  duration of experiment in hours                          % 0.  initialize parameters
binFactor = 200; % time bins of 0.005 hr  
hrPerBin = 1/binFactor; 

for condition = 1:2
   
    % 1.  isolate time and added mass data
    interestingData = dataMatrices{condition};  % condition: 1 = constant, 2 = fluctuating
    addedMass = interestingData(:,10);
    timeStamps = interestingData(:,2);
                                         
   % **** 
    
    % 2.  accumulate data by associated time bin
    timeBins = ceil(timeStamps*binFactor);                                 
    binnedByTime = accumarray(timeBins,addedMass,[],@(x) {x});               
    
    % 3a.  calculate mean cell cycle stage per bin
    meanAdded = cellfun(@nanmean,binnedByTime,'UniformOutput',false);      
    meanAdded = cell2mat(meanAdded);
    
    % 3b.  calculate std and error
    devAdded = cell2mat(cellfun(@nanstd,binnedByTime,'UniformOutput',false));
    nAdded = cell2mat(cellfun(@length,binnedByTime,'UniformOutput',false));
    errorAdded = devAdded./sqrt(nAdded);
    
    % 4a. create a time vector to convert bin # to absolute time
    timeVector = linspace(1, expHours/hrPerBin, expHours/hrPerBin);
    timeVector = hrPerBin*timeVector';                                       
    
    % 4b. before plotting, a little matrix manipulation to get around nans                                                            
    eventMask = find(~isnan(meanAdded));                                   % find indices of cell cycle data
    meanAdded = meanAdded(eventMask);                                      % trim all nans from ccStage vector
    devAdded = devAdded(eventMask);
    errorAdded = errorAdded(eventMask);
    timeVector = timeVector(eventMask);                                    % trim all nans from time vector
    
    % 4c. mean with standard deviation
    figure(1)
    if condition == 1
         plot(timeVector,meanAdded,'k')
         axis([0,10,0,2])
         hold on
         grid on
         %errorbar(timeVector,meanAdded, devAdded,'k')
    else
        plot(timeVector,meanAdded,'b')
        hold on
        %errorbar(timeVector,meanAdded,devAdded,'b')
    end

    % 4d. mean with standard error
    figure(2)
    if condition == 1
        plot(timeVector,meanAdded,'k')
        axis([0,10,0,2])
        hold on
        grid on
        errorbar(timeVector,meanAdded,errorAdded,'k')
    else
        plot(timeVector,meanAdded,'b')
        hold on
        errorbar(timeVector,meanAdded,errorAdded,'b')
    end
end


%%   T W O.
%    Heatmap of cell cycle stage over time


%  Goal: display fraction of population in each cell cycle stage vs. time
%        striations suggest synchrony, whereas uniformity indicates
%        heterogeneity


%  Strategy:
%
%     0. isolate data of interest
%     1. define bin sizes: time and cell cycle stage
%     2. accumulate data points (of cell cycle stage) by time bin
%     3. spread time binned data into vertical cell cycle stage bins
%     4. count number of points in each bin
%     5. with counts, generate normalized plot!


for condition = 1:2
    
    interestingData = dataMatrices{condition};  % condition: 1 = constant, 2 = fluctuating
    timestamps = interestingData(:,2);
    ccStage = interestingData(:,9);                                            % 0.  isolate time and ccStage vectors
    
    timeBins = ceil(timestamps*200);  % time bins of 0.005 hr                        % 1a. define bin size (time)
    binnedByTime = accumarray(timeBins,ccStage,[],@(x) {x});                   % 2.  accumulate data by associated time bin
    
    
    
    
    % A. Generate grid of absolute counts
    
    dataGrid = zeros(10,2000);                                                 % (rows) ccStage: 0 - 1, with 0.1 incr.
    % (columns) time: 0 - 10, with 0.005 incr
    for i = 1:length(binnedByTime)
        if isempty(binnedByTime{i})
            continue
        else
            stageBins = ceil(binnedByTime{i}/.1);                              % 1b. define bin size (cell cycle stage)
            stageBins(stageBins==0) = 1;                                       %     manually include birth into 1st bin
            
            currentTimeStep = binnedByTime{i};                                 % 3.  accumulate ccStage into bins
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










