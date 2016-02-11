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


%        row      Track#    Time     Lngth      Mu       drop?      curve#    timeSinceBirth    curveDuration    cc stage
%         1         1         t        x         u         0*         1              0                3              1
%         2         1         t        x         u         0          1              1                3              2
%         3         1         t        x         u         0          1              2                3              3
%         4         1         t        x         u         1          2              0                3              1
%         5         1         t        x         u         0          2              1                3              2
%         6         1         t        x         u         0          2              2                3              3
%         7         1         t        x         u         1          3              0                3              1
%         8         1         t        x         u         0          3              1                3              2
%         9         1         t        x         u         0          3              2                3              3
%         10        1         t        x         u         1          4              0                3              1


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

dmDirectory = dir('dm*.mat');
names = {dmDirectory.name}; % loaded alphabetically

for dm = 1:length(names)
    load(names{dm});                
    dataMatrices{dm} = dataMatrix;                                         % 1 = const; 2 = fluc
end

clear dataMatrix dmDirectory dm;
clear names;


%%

% Plotz

% 1. Cell cycle fraction over time
%
%           i. line (average)
%          ii. scatter
%         iii. heatmap
%          


% 2. Cycle durations over time 
%
%
%








