%% distribute( dataz )

%  Goal: plot distributions of cell cycle duration and added mass,
%        normalized by population average
%
%  Goal: plot distribution of cell size at birth



%  Last edit: Jen Nguyen, March 23th 2016


%  Section contents:
%  >> sections are separated based on input data formats
%
%       1. Cell cycle duration and added mass
%       2. Size at birth


% OK! Lez go!


%%  O N E.
%   distribute cell cycle duration and added mass


% The intended input for these scripts is the following data matrix,
% saved with the naming convention of:

% dFMMDD.mat
% dCMMDD.mat

%      where,
%              dF  =  fluctuating condition       (see matrixBuilder.m)
%              dC  =  constant condition
%              MM  =  month of experimental date
%              DD  =  day of experimental date

%      loading these gives us a two column matrix:
%              
%              column 1:  individual durations of full cell cycles
%              column 2:  added size (delta)
%


% Initialize data.
clear
dF = dir('dF*.mat');
dC = dir('dC*.mat');

load(dF.name);
load(dC.name);
clear dF dC

% Manual rename to remove date
dF = dF0810;
dC = dC0810;


% Consolidate by parameter, instead of condition
%         column 1 = constant
%         column 2 = fluctuating

duration_c = dC(:,1);
duration_f = dF(:,1);

addedMass_c = dC(:,2);
addedMass_f = dF(:,2);

dataz{1} = duration_c;
dataz{2} = duration_f;
dataz{3} = addedMass_c;
dataz{4} = addedMass_f;

clear duration_c duration_f addedMass_c addedMass_f;


% Normalize all values by respective average
normalizedDataz{1,length(dataz)} = [];
for i = 1:length(dataz)
    
    currentData = dataz{i};
    currentMean = mean(currentData);
    normalizedData = currentData./currentMean;
    normalizedDataz{i} = normalizedData;
    
end
clear currentData currentMean normalizedData i;


% Plot distribution of cell cycle durations
figure(1)
histogram(dataz{1},'BinWidth',0.1)
hold on
histogram(dataz{2},'BinWidth',0.1)


% Plot distribution of added sizes
figure(2)
histogram(dataz{3},'BinWidth',0.1)
hold on
histogram(dataz{4},'BinWidth',0.1)



% Plot distribution of normalized cell cycle durations
figure(3)
histogram(normalizedDataz{1},'BinWidth',0.1)
hold on
histogram(normalizedDataz{2},'BinWidth',0.1)



% Plot distribution of normalized added sizes
figure(4)
histogram(normalizedDataz{3},'BinWidth',0.1)
hold on
histogram(normalizedDataz{4},'BinWidth',0.1)


%%  T W O.
%   plot distribution of birth size


% The intended input for these scripts is the following data matrix,
% saved with the naming convention of:

% dmMMDD-cond.mat

%      where,
%              dm  =  dataMatrix                  (see matrixBuilder.m)
%              MM  =  month of experimental date
%              DD  =  day of experimental date
%       condition  =  experimental condition      (fluc or const)
%




% Initialize data.
clear
dmDirectory = dir('dm*.mat'); % note: this assumes the only two data matrices are 'const' and 'fluc'
names = {dmDirectory.name}; % loaded alphabetically

for dm = 1:length(names)
    load(names{dm});                
    dataMatrices{dm} = dataMatrix;                                         % for entire condition
end                                                                        
clear dataMatrix dmDirectory dm;
clear names;


%
%  Stragety:
%
%     0. designate time window of analysis
%     1. isolate data of interest (length and drop)
%     2. find length when drop == 1
%     3. plot!


% 0. designate time window of analysis

firstTimepoint = 5; % in hours
lastTimepoint = 10;

% 
for condition = 1:2   % 1 = constant, 2 = fluctuating

    interestingData = dataMatrices{condition};
    
    % 1. isolate Length and Drop data
    lengthVals = interestingData(:,3);
    drop = interestingData(:,5);
    timeStamps = interestingData(:,2);

    % 0. trim off timepoints earlier than first
    lengthVals = lengthVals(timeStamps >= firstTimepoint);
    drop = drop(timeStamps >= firstTimepoint);
    lowTrimmed_timeStamps = timeStamps(timeStamps >= firstTimepoint);
    
    % 0. trim off timepoints later than last
    lengthVals = lengthVals(lowTrimmed_timeStamps <= lastTimepoint);
    drop = drop(lowTrimmed_timeStamps <= lastTimepoint);
    finalTrimmed_timeStamps = lowTrimmed_timeStamps(lowTrimmed_timeStamps <= lastTimepoint);
    
    % 2. keep lengths when drop equals 1 (denotes birth)
    birthLengths = lengthVals(drop == 1);
    
    % 3. plot
    figure(5)
    histogram(birthLengths,'BinWidth',0.1)
    hold on

end