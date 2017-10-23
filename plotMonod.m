% plotMonod

% goal: plot monod curve using compiled LB data

% strategy:
%
%       0. initialize experiment data
%       1. for each experiment...load data
%               2. for each condition in experiment...
%                       3. isolate condition specific Mu_va and time data
%                       4. remove mu data with timestamps prior to and after stabilization
%                       5. remove zeros (always two at start and end of track) and negatives
%                       6. calculate mean and sem
%                       7. plot ave mu_va vs concentration

%                       5. plot mu vs log(concentration)
%               6. repeat for all conditions
%       7.  repeat for all experiments
%   


% last updated: 2017 October 23

%%
clear
clc

% 0. initialize experiment data
experimentList = {
    '2017-09-26';
    '2017-10-10';
    };


dataList = {
    'lb-monod-2017-09-26-window5-va-jiggle-c12-0p1-c3456-0p5-bigger1p8.mat';
    'lb-fluc-2017-10-10-window5-va-width1p4v1p7-jiggle-0p5-bigger1p8.mat';
    };

concentrationList = {
    % each col = a condition
    % each row = an experiment
    1, 1/8, 1/32, 1/100, 1/1000, 1/10000;       % 2017-09-26: all stable envir
    105/10000, 1/1000, 105/10000, 1/50, [], []; % 2017-10-10: fluc (5min), low, ave, high
    };

conditionsList = {
    % each col = a condition
    % each row = an experiment
    1:10, 11:20, 21:30, 31:40, 41:50, 51:60; % 2017-09-26: all stable envir
    1:10, 11:20, 21:30, 31:40, [], [];       % 2017-10-10: fluc (5min), low, ave, high  
    };

stablePeriods = { 
    % each cell = an experiment
    % first col = start, second col = end
    [2, 4.5; 2, 10; 2, 10; 3.5, 10; 3, 10; 3, 10];             % 2017-09-26: all stable envir
    [2.5, 6.5; 4, 7.5; 2.5, 10; 2.5, 10; NaN, NaN; NaN, NaN];  % 2017-10-10: fluc (5min), low, ave, high       
    };
                   
               
%%
% 1. for each experiment
experimentCount = length(dataList);
for e = 1:experimentCount
    
    % 1. open corresponding directory
    newFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',experimentList{e});%,'  (t300)');
    cd(newFolder);
    
    % 1. load experiment data
    load(dataList{e},'D5','M','M_va','T');
    currentStabilizedPeriods = stablePeriods{e};
    
    exptData = buildDM(D5,M,M_va,T);
    
    % 2. for each condition in experiment
    conditions = find(~cellfun(@isempty,conditionsList(e,:)));
    
    for c = 1:max(conditions)
        
        % 3. isolate condition specific mu_va and time data
        conditionStabilizedPeriod = currentStabilizedPeriods(c,:);
        conditionData = exptData(exptData(:,35) == c,:); % col 35 = condition
        %Mus = conditionData(:,4); % col 4 = mus
        Mus_va = conditionData(:,18); % col 18 = calculated mu_vals
        Time = conditionData(:,2)/3600; % col 2 = timestamps in sec, covert to hr
        
        
        % 4. remove mu data with timestamps prior to and after stabilization
        Mus_trim1 = Mus_va(Time >= conditionStabilizedPeriod(1));
        Time_trim1 = Time(Time >= conditionStabilizedPeriod(1));
        %plot(Time_trim1,Mus_trim1,'o')
        
        Mus_trim2 = Mus_trim1(Time_trim1 <= conditionStabilizedPeriod(2));
        Time_trim2 = Time_trim1(Time_trim1 <= conditionStabilizedPeriod(2));
        %plot(Time_trim2,Mus_trim2,'o')
        
        
        % 5. remove zeros (always two at start and end of track) and negatives
        Mus_trim3 = Mus_trim2(Mus_trim2 > 0);
        
        
        % 6. calculate mean and sem
        muMean = mean(Mus_trim3);
        muStd = std(Mus_trim3);
        muCounts = length(Mus_trim3);
        muSem = muStd./sqrt(muCounts);
        
        
        % 7. plot ave mu_va vs concentration
        figure(1)
        if e == 1
            errorbar(concentrationList{e,c},muMean,muSem,'o','Color',[0 0.7 0.7],'MarkerSize',10)
            axis([0,1.1,0,4])
            grid on
            hold on
            xlabel('Concentration (Fraction LB)')
            ylabel('doubling rate of volume (hr-1)')  
        else
            errorbar(concentrationList{e,c},muMean,muSem,'o','Color',[1 0.6 0],'MarkerSize',10)
            axis([0,1.1,0,4])
            hold on 
        end
        legend('expt1-1','expt1-1/8','expt1-1/32','expt1-1/100','expt1-1/1000','expt1-1/10000','fluc1','low1','ave1','high1')
    end
    clear exptData M D5 T
end