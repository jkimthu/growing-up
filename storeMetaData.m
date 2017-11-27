% storeMetaData.m


% goal: prompt user for inputs and store to experiment specific structures
%       stored data:
%               1. experiment date
%               2. fluctuating timescale
%               3. bubble occurrence? 0 (no) or time in hours (yes)
%
%       each field is stored in a structure, contained in a matrix of cells,
%       such that:
%               1. each column is a different timescale
%                       1. 30 sec
%                       2. 300 sec (5 min)
%                       3. 900 sec (15 min)
%                       4. none    (monod)
%               2. each row is a different experimental replicate
%


% strategy:
%
%       0. initialize dimensions of current data structure
%       1. prompt user for timescale data
%       2. determine location of new cell (experiment) to add to current data
%       3. prompt user for experiment date, assign to field
%       4. generate data structure for experiment
%               i. designate concentrations
%              ii. designate xy positions
%       5. prompt user for bubbles in fluc
%       6. prompt user for bubbles in low
%       7. prompt user for bubbles in ave
%       8. prompt user for bubbles in high
%       9. assign bubble appearance times to field (bubbletime)
%      10. assign data structure to new (experiment-specific cell)
%      11. save stored meta data



% last updated: 2017 Nov 24

% OK let's go!

%% 0. initialize dimensions of current data structure
clc
clear
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')

%%
% 1. prompt user for timescale data
prompt = 'Enter fluctuating timescale in seconds: ';
timescale = input(prompt);
metadata(1).timescale = timescale;


% 2. determine location of new cell (experiment) to add to current data
if timescale == 30
    column = 1;
elseif timescale == 300
    column = 2;
elseif timescale == 900
    column = 3;
else
    column = 4;
end

% 3. prompt user for experiment date, assign to field
prompt = 'Enter experiment date as a string: ';
date = input(prompt);
metadata(1).date = date;

% 4. generate data structure to assign to new cell
%    i. designate concentrations
lowConc = 1/1000;
aveConc = 105/10000;
highConc = 1/50;
flucConc = aveConc;
metadata(1).concentrations = [flucConc; lowConc; aveConc; highConc];

%   ii. designate xy positions
xyfluc = 1:10;
xylow = 11:20;
xyave = 21:30;
xyhigh = 31:40;
metadata(1).xys = [xyfluc; xylow; xyave; xyhigh];

% 5. prompt user for bubbles in fluc, assign to field
prompt = 'Enter time at which bubbles appeared in fluc (enter 0 if perfect): ';
haltFluc = input(prompt);

% 6. prompt user for bubbles in low, assign to field
prompt = 'Enter time at which bubbles appeared in low (enter 0 if perfect): ';
haltLow = input(prompt);

% 7. prompt user for bubbles in ave, assign to field
prompt = 'Enter time at which bubbles appeared in ave (enter 0 if perfect): ';
haltAve = input(prompt);

% 8. prompt user for bubbles in high, assign to field
prompt = 'Enter time at which bubbles appeared in high (enter 0 if perfect): ';
haltHigh = input(prompt);

% 9. assign bubble appearance times to field (bubbletime)
metadata(1).bubbletime = [haltFluc; haltLow; haltAve; haltHigh];


%% 10. assign data structure to new (experiment-specific cell)
storedMetaData{1,column} = metadata;

% 11. save storedMetaData
save('storedMetaData.mat','storedMetaData')