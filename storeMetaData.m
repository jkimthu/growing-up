% storeMetaData.m


% goal: prompt user for inputs and store to experiment specific structures
%       stored data:
%               1. experiment date
%               2. fluctuating timescale
%               3. bubble occurrence? 0 (no) or time in hours (yes)
%               4. concentrations
%               5. xys per condition: each row represents a condition
%               6. signal timestamp: first printed line of signal onset
%               7. flow rate, in ul/min as measured from MPG
%
%       each field is stored in a structure, contained in a matrix of cells,
%       such that:
%               1. each column is a different timescale
%                       1. 30 sec
%                       2. 300 sec  (5 min)
%                       3. 900 sec  (15 min)
%                       4. 3600 sec (60 min)
%                       5. none    (monod)
%               2. each row is a different experimental replicate

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
%      10. prompt user for signal timestamp
%      11. prompt user for measured flow rate through MPG 
%      12. assign data structure to new (experiment-specific cell)
%      13. save stored meta data

%      14. to add new variables to previously saved cells:
%           - for strategy, scroll to section


% last updated: 2018 Feb 20
% commit message: add measured flow rate (Q) through MPG as a meta data variable


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
elseif timescale == 3600
    column = 4;
else
    column = 5;
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

% for monod / controls
% prompt = 'Enter time at which bubbles appeared in condition 1 (enter 0 if perfect): ';
% bubbles_condition1 = input(prompt);

% 6. prompt user for bubbles in low, assign to field
prompt = 'Enter time at which bubbles appeared in low (enter 0 if perfect): ';
haltLow = input(prompt);

% for monod / controls
% prompt = 'Enter time at which bubbles appeared in condition 2 (enter 0 if perfect): ';
% bubbles_condition2 = input(prompt);

% 7. prompt user for bubbles in ave, assign to field
prompt = 'Enter time at which bubbles appeared in ave (enter 0 if perfect): ';
haltAve = input(prompt);

% for monod / controls
% prompt = 'Enter time at which bubbles appeared in condition 3 (enter 0 if perfect): ';
% bubbles_condition3 = input(prompt);

% 8. prompt user for bubbles in high, assign to field
prompt = 'Enter time at which bubbles appeared in high (enter 0 if perfect): ';
haltHigh = input(prompt);

% 9. assign bubble appearance times to field (bubbletime)
metadata(1).bubbletime = [haltFluc; haltLow; haltAve; haltHigh];
%metadata(1).bubbletime = [bubbles_condition1; bubbles_condition2; bubbles_condition3];

% 10. prompt user for signal timestamp
prompt = 'Enter signal timestamp (enter NaN if non-existent or not applicable): ';
signal_timestamp = input(prompt);
metadata(1).signal_timestamp = signal_timestamp;

% 11. prompt user for measured flow rate through MPG
prompt = 'Enter flow rate in ul/min (enter NaN if non-existent or not applicable): ';
flowRate = input(prompt);
metadata(1).flow_rate = flowRate;


%% 12. assign data structure to new (experiment-specific cell)

% prompt user for row number
prompt = 'Enter row number of new experiment replicate: ';
row = input(prompt);
storedMetaData{row,column} = metadata;

%% 13. save storedMetaData
save('storedMetaData.mat','storedMetaData')

%% 14. add new variable to pre-existing cell of experiment meta data

% last used: jen, 2018 Feb 20
% for adding flow rate to all existing data sets


% strategy:
%           0. initialize existing meta data structure
%           1. copy data structure -- safety first!
%           2. collect summary info for existing data
%           3. for all experiments (cells with data),
%                 3. print experiment date
%                 4. prompt user to enter value of new variable
%                 5. store variable into copy of meta data
%           6. if satisfied, save copy with new variable as true meta data

clear
clc

% 0. initialize
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')

% 1. copy data structure -- safety first!
copyMD = storedMetaData;

% 2. collect summary info for existing data
dataIndex = find(~cellfun(@isempty,storedMetaData));
bioProdRateData = cell(size(storedMetaData));
experimentCount = length(dataIndex);

% for all experiments (cells with data)
for e = 1:experimentCount
    
    % 3. print experiment date
    index = dataIndex(e);
    date = storedMetaData{index}.date;
      
    % 4. prompt user to enter value of new variable
    prompt = strcat('Enter value of new variable (flow rate measured on .', date,' : ');
    flowRate = input(prompt);

    % 5. store variable into copy of meta data
    currentStructure = copyMD{index};
    currentStructure.flow_rate = flowRate;
    copyMD{index} = currentStructure;

end
%% (14) 6. save copy with new variable as true meta data
storedMetaData = copyMD;
save('storedMetaData.mat','storedMetaData')

