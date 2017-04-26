%% distribute( dataz )

%  Goal: plot distributions of cell cycle duration and added mass,
%        normalized by population average
%
%  Goal: plot distribution of cell size at birth



%  Last edit: Jen Nguyen, April 5 2017


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

% Initialize data.
clear
dF = dir('dF*.mat');
dC = dir('dC*.mat');

load(dF.name);
load(dC.name);
clear dF dL dA dH;

% Manual rename to remove date
dF = dF0810;
dC = dC0810;
clear dF0810 dC0810;

%%
%  OR

% for Hella Controlled Fluctuating (HCF) experiments, with three stable
% environments:

% dFMMDD.mat     (fluc, positions 1-10)
% dLMMDD.mat     (low,  positions 11-20)
% dAMMDD.mat     (ave,  positions 21-30)
% dHMMDD.mat     (high, positions 31-40)


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
dL = dir('dL*.mat');
dA = dir('dA*.mat');
dH = dir('dH*.mat');

load(dF.name);
load(dL.name);
load(dA.name);
load(dH.name);
clear dF dL dA dH;

% Manual rename to remove date
dF = dF0730;
dL = dL0730;
dA = dA0730;
dH = dH0730;
clear dF0730 dL0730 dA0730 dH0730;

%%
% Consolidate by parameter, instead of condition
%         column 1 = constant
%         column 2 = fluctuating

duration_ave = dA(:,1);
duration_f = dF(:,1);

addedMass_ave = dA(:,2);
addedMass_f = dF(:,2);

dataz{1} = duration_ave;
dataz{2} = duration_f;
dataz{3} = addedMass_ave;
dataz{4} = addedMass_f;


% Remove zeros
for i = 1:length(dataz)
        currentVar = dataz{i};
        currentVar(currentVar <= 0) = NaN;
        nanFilter = find(~isnan(currentVar));
        currentVar = currentVar(nanFilter);
        dataz_trimmed{i} = currentVar;
end

clear duration_ave duration_f addedMass_ave addedMass_f currentVar i nanFilter;

%%
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
legend('ave','fluc')

% Plot distribution of added sizes
figure(2)
histogram(dataz{3},'BinWidth',0.1)
hold on
histogram(dataz{4},'BinWidth',0.1)
legend('ave','fluc')


% Plot distribution of normalized cell cycle durations
figure(3)
histogram(normalizedDataz{1},'BinWidth',0.1)
hold on
histogram(normalizedDataz{2},'BinWidth',0.1)
legend('ave','fluc')


% Plot distribution of normalized added sizes
figure(4)
histogram(normalizedDataz{3},'BinWidth',0.1)
hold on
histogram(normalizedDataz{4},'BinWidth',0.1)
legend('ave','fluc')

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

firstTimepoint = 2; % in hours
lastTimepoint = 4;

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

%% testing distributionPlot.m

% functions from distributionPlot.m files, as shared by Jonas Dorn on File
% Exchange. 

data1 = randn(500,5);
data2 = bsxfun(@plus,randn(500,5),0:0.1:0.4);
figure
distributionPlot(data1,'widthDiv',[2 1],'histOri','left','color','b','showMM',4)
distributionPlot(gca,data2,'widthDiv',[2 2],'histOri','right','color','k','showMM',4)

% bsxfun(fun, A, B) : applies the function (fun) to arrays A and B
%                       ex. C = bsxfun(@minus, A, mean(A))
%                           subtracts the mean of A column-wise from each
%                           element in corresponding columns of A

% gca : helps return to previous plot

% widthDiv : [numberOfDivisions,currentDivision], allows comparison of
%              multiple distributions

% histOri : orientation of histogram ('center','left', or 'right'), with 'center' as default
%             'left' or 'right' only shows left or right half of violin plot

% color : uniform coloring of histograms. Supply either a color
%           string ('r'), or a truecolor vector ([1 0 0]). Use a
%           cell array of length nData to specify one color per
%           distribution. Default: 'k' 

% showMM : if 1, mean and median are shown as red crosses and
%                green squares, respectively. This is the default
%                2: only mean
%                3: only median
%                4: mean +/- standard error of the mean (no median)
%                5: mean +/- standard deviation (no median)
%                6: draw lines at the 25,50,75 percentiles (no mean)
%                0: plot neither mean nor median

