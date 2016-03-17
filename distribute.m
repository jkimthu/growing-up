%% distribute( dataz )

% Goal: plot distributions of cell cycle duration and added mass,
%       normalized by population average



%  Last edit: Jen Nguyen, March 17th 2016



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

% OK! Lez go!

%%
% Initialize data.

dF = dir('dF*.mat');
dC = dir('dC*.mat');

load(dF.name);
load(dC.name);
clear dF dC

% Manual rename to remove date
dF = dF0818;
dC = dC0818;


%%
% Consolidate by parameter, instead of condition


%    column 1 = constant
%    column 2 = fluctuating

duration_c = dC(:,1);
duration_f = dF(:,1);

addedMass_c = dC(:,2);
addedMass_f = dF(:,2);

dataz{1} = duration_c;
dataz{2} = duration_f;
dataz{3} = addedMass_c;
dataz{4} = addedMass_f;

clear duration_c duration_f addedMass_c addedMass_f;

%
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
histogram(normalizedDataz{1},'BinWidth',0.1)
hold on
histogram(normalizedDataz{2},'BinWidth',0.1)
%h.FaceColor = [0 0.5 0.5];



% Plot distribution of added sizes

figure(2)
histogram(normalizedDataz{3},'BinWidth',0.1)
hold on
histogram(normalizedDataz{4},'BinWidth',0.1)
%h.FaceColor = [0 0.5 0.5];









