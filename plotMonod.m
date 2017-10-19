% plotMonod

% goal: plot monod curve using steady-state LB data

% strategy:
%
%       0. initialize experiment data
%       1. for each experiment...load data
%               2. for each condition in experiment...
%                       3. find mean and sem of stabilized region
%                       4. plot mu vs concentration
%                       5. plot mu vs log(concentration)
%               6. repeat for all conditions
%       7.  repeat for all experiments
%   


% last updated: 2017 October 13

%%
clear
clc

% 0. initialize experiment data
experimentList = {
    '2017-09-26';
    '2017-10-10';
    };


dataList = {
    'lb-monod-2017-09-26-window5-jiggle-c12-0p1-c3456-0p5-bigger1p8.mat';
    'lb-fluc-2017-10-10-window5-width1p4v1p7-jiggle-0p5-bigger1p8.mat';
    };

concentrationList = {
    1, 1/8, 1/32, 1/100, 1/1000, 1/10000; % each col = a condition
    105/10000, 1/1000, 105/10000, 1/50, [], []; % each row = an experiment
    };

conditionsList = {
    1:10, 11:20, 21:30, 31:40, 41:50, 51:60; % each col = a condition
    1:10, 11:20, 21:30, 31:40, [], [];         % each row = an experiment
    };

stablePeriods = { 
    [2, 4.5; 2, 10; 2, 10; 3.5, 10; 3, 10; 3, 10];   % each cell = an experiment
    [2.5, 6.5; 4, 7.5; 2.5, 10; 2.5, 10; NaN, NaN; NaN, NaN];         % first col = start, second col = end
    };
                   
               
%%
% 1. for each experiment
experimentCount = length(dataList);
for e = 1:experimentCount
    
    % 1. open corresponding directory
    newFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',experimentList{e});%,'  (t300)');
    cd(newFolder);
    
    % 1. load experiment data
    load(dataList{e},'D5','M','T');
    currentStabilizedPeriods = stablePeriods{e};
    
    exptData = buildDM(D5,M,T);
    
    % 2. for each condition in experiment
    conditions = find(~cellfun(@isempty,conditionsList(e,:)));
    
    for c = 1:max(conditions)
        
        % 3. find mean and sem of stabilized region
        
        % i. isolate condition specific data
        conditionStabilizedPeriod = currentStabilizedPeriods(c,:);
        conditionData = exptData(exptData(:,35) == c,:); % col 35 = condition
        Mus = conditionData(:,4); % col 4 = mus
        Time = conditionData(:,2)/3600; % col 2 = timestamps in sec, covert to hr
        
        
        % ii. remove mu data with timestamps prior to and after stabilization
        Mus_trim1 = Mus(Time >= conditionStabilizedPeriod(1));
        Time_trim1 = Time(Time >= conditionStabilizedPeriod(1));
        %plot(Time_trim1,Mus_trim1,'o')
        
        Mus_trim2 = Mus_trim1(Time_trim1 <= conditionStabilizedPeriod(2));
        Time_trim2 = Time_trim1(Time_trim1 <= conditionStabilizedPeriod(2));
        %plot(Time_trim2,Mus_trim2,'o')
        
        
        % iii. remove zeros (always two at start and end of track) and negatives
        Mus_trim3 = Mus_trim2(Mus_trim2 > 0);
        
        
        % iv. calculate mean and sem
        muMean = mean(Mus_trim3);
        muStd = std(Mus_trim3);
        muCounts = length(Mus_trim3);
        muSem = muStd./sqrt(muCounts);
        
        
        % 4. plot mu vs concentration
        figure(1)
        if e == 1
            errorbar(concentrationList{e,c},muMean,muSem,'o','Color',[0 0.7 0.7])
            axis([0,0.15,0,4])
            hold on
            xlabel('Concentration (Fraction LB)')
            ylabel('Elongation rate (hr-1)')  
        else
            %figure(2)
            errorbar(concentrationList{e,c},muMean,muSem,'o','Color',[1 0.6 0])
            axis([0,0.15,0,4])
            hold on 
        end
        legend('expt1-1','expt1-1/8','expt1-1/32','expt1-1/100','expt1-1/1000','expt1-1/10000','fluc1','low1','ave1','high1')
    end
    clear exptData M D5 T
end