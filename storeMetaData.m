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
%               8. experiment type
%               9. nutrient source
%              10. shift time
%
%       each field is stored in a structure, contained in a matrix of cells,
%       such that:

%               1. each column is a different timescale/experiment type
%                       1. 30 sec
%                       2. 300 sec  (5 min)
%                       3. 900 sec  (15 min)
%                       4. 3600 sec (60 min)
%                       5. none     (monod)
%                       6. single upshift
%                       7. single downshift
%                       8. fluc to stable
%                       9. ave to high
%                      10. steady to fluc

%               2. each row is a different experimental replicate

% strategy:
%
%       0. initialize dimensions of current data structure
%       1. prompt user for experiment type (1)
%       2. prompt user for experiment timescale (2)
%       3. determine column of new cell (experiment) to add to current data
%       4. prompt user for experiment date, assign to field (3)
%       5. generate data structure for experiment
%               i. designate nutrient source (4)
%              ii. designate concentrations (5)
%             iii. designate xy positions (6)
%       6. prompt user for bubbles in fluc
%       7. prompt user for bubbles in low
%       8. prompt user for bubbles in ave
%       9. prompt user for bubbles in high
%      10. assign bubble appearance times to field (bubbletime) (7)
%      11. prompt user for signal timestamp (8)
%      12. prompt user for measured flow rate through MPG (9)
%      13. prompt user for shift time in seconds (10)

%      14. assign data structure to new experiment-specific cell
%      15. save stored meta data

%      16. add new variables to previously saved data entries:
%                - for specific strategy, scroll to section


% last updated: 2019 June 27
% commit message: add new column (#10) for steady to fluc experiments

% OK let's go!

%% 0. initialize dimensions of current data structure
clc
clear
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')

%% 1. input meta data for a new experiment

% 1. prompt user for experiment type
prompt = 'Enter experiment type as a string (origFluc/monod/upshift/downshift/steady2fluc): ';
expType = input(prompt);
metadata(1).experimentType = expType;


% 2. prompt user for timescale data
prompt = 'Enter fluctuating timescale in seconds: ';
timescale = input(prompt);
metadata(1).timescale = timescale;



% 3. determine column of new cell (experiment) to add to current data

if strcmp(expType,'fluc2stable') == 1 % needs to be earlier than timescale ID, 
    column = 8;                       % as there is also a timecale designation
elseif strcmp(expType,'steady2fluc') == 1
    column = 10;
elseif timescale == 30
    column = 1;
elseif timescale == 300
    column = 2;
elseif timescale == 900
    column = 3;
elseif timescale == 3600
    column = 4;
elseif strcmp(expType,'monod') == 1
    column = 5;
elseif strcmp(expType,'upshift') == 1 % upshift = low to high
    column = 6;
elseif strcmp(expType,'ave2high') == 1 % upshift = ave to high
    column = 9;
elseif strcmp(expType,'downshift') == 1
    column = 7;
end


% 4. prompt user for experiment date, assign to field
prompt = 'Enter experiment date as a string: ';
date = input(prompt);
metadata(1).date = date;


% 5. generate data structure to assign to new cell
%    i. designate nutrient source
prompt = 'Enter nutrient source as string (LB/glucose): ';
nutrientSource = input(prompt);
metadata(1).nutrient = nutrientSource;

%   ii. designate concentrations
if strcmp(nutrientSource,'LB') == 1
    lowConc = 1/1000;
    aveConc = 105/10000;
    highConc = 1/50;
    flucConc = aveConc;
    metadata(1).concentrations = [flucConc; lowConc; aveConc; highConc];
    %metadata(1).concentrations = [highConc; highConc; lowConc; lowConc]; % for poly-lysine control 2018-12-04
else
    alternative = 'Enter concentrations as vector ([c1; c2; c3;...]): ';
    altConcentrations = input(alternative);
    metadata(1).concentrations = altConcentrations;
end


%  iii. designate xy positions
%xyfluc = 1:10;
%xylow = 11:20;
%xyave = 21:30;
%xyhigh = 31:40;
xyfluc = 1:15; % for steady to fluc experiments
xylow = 16:24; % for steady to fluc experiments
xyave = 25:33; % for steady to fluc experiments
xyhigh = 34:42; % for steady to fluc experiments
metadata(1).xys = {xyfluc; xylow; xyave; xyhigh};


% 6. prompt user for bubbles in fluc, assign to field
prompt = 'Enter time at which bubbles appeared in fluc (enter 0 if perfect): ';
haltFluc = input(prompt);


% 7. prompt user for bubbles in low, assign to field
prompt = 'Enter time at which bubbles appeared in low (enter 0 if perfect): ';
haltLow = input(prompt);

% for monod / controls
% prompt = 'Enter time at which bubbles appeared in condition 2 (enter 0 if perfect): ';
% bubbles_condition2 = input(prompt);

% 8. prompt user for bubbles in ave, assign to field
prompt = 'Enter time at which bubbles appeared in ave (enter 0 if perfect): ';
haltAve = input(prompt);

% for monod / controls
% prompt = 'Enter time at which bubbles appeared in condition 3 (enter 0 if perfect): ';
% bubbles_condition3 = input(prompt);

% 9. prompt user for bubbles in high, assign to field
prompt = 'Enter time at which bubbles appeared in high (enter 0 if perfect): ';
haltHigh = input(prompt);

% 10. assign bubble appearance times to field (bubbletime)
metadata(1).bubbletime = [haltFluc; haltLow; haltAve; haltHigh];
%metadata(1).bubbletime = [bubbles_condition1; bubbles_condition2; bubbles_condition3];

% 11. prompt user for signal timestamp
prompt = 'Enter signal timestamp (enter NaN if non-existent or not applicable): ';
signal_timestamp = input(prompt);
metadata(1).signal_timestamp = signal_timestamp;

% 12. prompt user for measured flow rate through MPG
prompt = 'Enter flow rate in ul/min (enter NaN if non-existent or not applicable): ';
flowRate = input(prompt);
metadata(1).flow_rate = flowRate;


% 13. prompt user for shift time (time at which experiment phase changes)
if strcmp(expType,'origFluc') == 1 || strcmp(expType,'monod') == 1
    metadata(1).shiftTime = 'NaN';
else
    prompt = 'Enter time of shift in seconds: ';
    shiftTime = input(prompt);
    metadata(1).shiftTime = shiftTime;
end


% 14. assign data structure to new (experiment-specific cell)
% prompt user for row number
prompt = 'Enter row number of new experiment replicate: ';
row = input(prompt);
storedMetaData{row,column} = metadata;


%% 15. save storedMetaData
save('storedMetaData.mat','storedMetaData')


%% 16. add new variable to pre-existing cell of experiment meta data

% last used: jen, 2018 November 16
% commit: edited bubbletime for fluc of 2017-11-13


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
%bioProdRateData = cell(size(storedMetaData));
experimentCount = length(dataIndex);

% for all experiments (cells with data)
for e = 8%1:experimentCount
    
    % 3. print experiment date
    index = dataIndex(e);
    date = storedMetaData{index}.date;
      
    % 4. prompt user to enter value of new variable
    prompt = strcat('Enter bubbletime as array for .', date,' : ');
    bubbletime = input(prompt);

    % 5. store variable into copy of meta data
    currentStructure = copyMD{index};
    currentStructure.bubbletime = bubbletime;
    copyMD{index} = currentStructure;

end
%% (16) continued
% 6. save copy with new variable as true meta data
storedMetaData = copyMD;
save('storedMetaData.mat','storedMetaData')

