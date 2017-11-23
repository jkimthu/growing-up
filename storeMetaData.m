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
%               2. each row is a different experimental replicate
%


% strategy:
%
%       0. initialize dimensions of current data structure
%       1. prompt user for timescale data
%       2. determine location of new cell (experiment) to add to current data
%       3. generate data structure to assign to new cell
%               4. prompt user for experiment date, assign to field
%               5. prompt user for bubbles in fluc, assign to field
%               6. prompt user for bubbles in low, assign to field
%               7. prompt user for bubbles in ave, assign to field
%               8. prompt user for bubbles in high, assign to field
%       9. assign data structure to new (experiment-specific cell)



% last updated: 2017 Nov 23

% OK let's go!

%% 0. initialize dimensions of current data structure
clc
clear
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')


% 1. prompt user for timescale data
prompt = 'Enter fluctuating timescale in seconds: ';
timescale = input(prompt);
metadata(1).timescale = timescale;


% 2. determine location of new cell (experiment) to add to current data
if timescale == 30
    column = 1;
elseif timescale == 300
    column = 2;
else
    column = 3;
end

replicates = ~isempty(length(storedMetaData(:,column)));
addedReplicate = replicates + 1;

%% 3. generate data structure to assign to new cell

%  4. prompt user for experiment date, assign to field
prompt = 'Enter experiment date as a string: ';
date = input(prompt);
metadata(1).date = date;


% 5. prompt user for bubbles in fluc, assign to field
prompt = 'Enter time at which bubbles appeared in fluc (enter 0 if perfect): ';
bubbleTime = input(prompt);
metadata(1).haltFluc = bubbleTime;


% 6. prompt user for bubbles in low, assign to field
prompt = 'Enter time at which bubbles appeared in low (enter 0 if perfect): ';
bubbleTime = input(prompt);
metadata(1).haltLow = bubbleTime;

% 7. prompt user for bubbles in ave, assign to field
prompt = 'Enter time at which bubbles appeared in ave (enter 0 if perfect): ';
bubbleTime = input(prompt);
metadata(1).haltAve = bubbleTime;


% 8. prompt user for bubbles in high, assign to field
prompt = 'Enter time at which bubbles appeared in high (enter 0 if perfect): ';
bubbleTime = input(prompt);
metadata(1).haltHigh = bubbleTime;


%% 9. assign data structure to new (experiment-specific cell)
storedMetaData{addedReplicate,column} = metadata;

% 10. save storedMetaData
save('storedMetaData.mat','storedMetaData')
