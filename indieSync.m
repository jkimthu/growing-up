%%  nSYNC


%  Goal: Searching for synchrony in growth data.
%        This script plots up multiple views of cell cycle stage.
%
%  Last edit: Jen Nguyen, February 11th 2016




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
%


%        col        1         2        3         4         5          6              7                8              9 
%       ------------------------------------------------------------------------------------------------------------------
%        row      Track#    Time     Lngth      Mu       drop?      curve#    timeSinceBirth    curveDuration    cc stage
%       ------------------------------------------------------------------------------------------------------------------
%         1         1         t        x         u         0*         1              0                3              0
%         2         1         t        x         u         0          1              1                3             .5
%         3         1         t        x         u         0          1              2                3              1
%         4         1         t        x         u         1          2              0                3              0
%         5         1         t        x         u         0          2              1                3             .5 
%         6         1         t        x         u         0          2              2                3              1
%         7         1         t        x         u         1          3              0                3              0
%         8         1         t        x         u         0          3              1                3             .5
%         9         1         t        x         u         0          3              2                3              1
%         10        1         t        x         u         1          4              0                3             nan


%       where,
%                row     =  row number, obvi
%                t       =  all timepoints associated with concatinated length trajectories
%                x       =  length values from concatentated length trajectories
%                mu      =  calculated growth rates from SlidingFits.m
%                drop?   =  finding where individual cell cycles start and end, a boolean
%                curve   =  an id number for each individual cell cycle
%                stage   =  time since birth / duration of entire cycle


% Strategy:
%
%       1.  for each curve, determine duration (time)
%       2.  for each time step, determine absolute time since birth
%       3.  for each data point in vector, record as fraction:
%                
%               ccStage = time since birth / total curve duration



% Considerations:
%
%       1. Does separation between phase-sorted subpopulations occur?
%       2. Vary number of fractions. Which leads to the best separation?
%       3. If there is separation, what explains it?



% OK! Lez go!

%%
%   Initialize.

dmDirectory = dir('dm0810-xy*.mat');
names = {dmDirectory.name}; % loaded alphabetically

for dm = 1:length(names)
    load(names{dm});                
    %dataMatrices{dm} = dataMatrix;                                        % for entire condition                               
    dataMatrices{dm} = indivMatrix;                                        % for individual positions
end                                                                        

clear dataMatrix dmDirectory dm;
clear names;


%%


%      O N E.  Cell cycle stage over experiment



%  Heatmap: fraction of population in each cell cycle stage vs. time
%
%     -  figure 3 of Mathis & Ackermann pre-print: line plots separate
%        experiments to illustrate reduced variation after pulsed shock
%     -  here, let's plot all data points per timestep


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
    time = interestingData(:,2);
    ccStage = interestingData(:,9);                                            % 0.  isolate time and ccStage vectors
    
    timeBins = ceil(time*200);  % time bins of 0.005 hr                        % 1a. define bin size (time)
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

%%




%%

% B R A I N S T O R M


% 1. Cell cycle fraction over time
%
%           i. line (average)
%          ii. scatter
%         iii. heatmap
%          iv. percent dividing

% 2. Cycle durations over time 
%
%
%








