% plotMonod: biovolume production rate vs conc

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


% last updated: 2017 October 25

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
    
    dataMatrix = buildDM(D5,M,M_va,T);
    
    % 2. for each condition in experiment
    conditions = find(~cellfun(@isempty,conditionsList(e,:)));
   
    %% calculate mean biovolume production rate per condition
    
    totalCond = max(dataMatrix(:,35));
    
    for c = 1:totalCond
        
        % 3. isolate all data from current condition
        interestingData = dataMatrix(dataMatrix(:,35) == c,:);
        
        % 4. isolate volume (Va), mu (mu_va) and time data from current condition
        volumes = interestingData(:,15);        % col 15 = calculated va_vals (cubic um)
        mus = interestingData(:,18);            % col 18 = calculated mu_va 
        timestamps = interestingData(:,2)/3600; % time in seconds converted to hours
        
        % 5. remove data for which mu = 0, as these were the edges of tracks that never get calculated
        trueMus = mus(mus > 0);
        trueVols = volumes(mus > 0);
        trueTimes = timestamps(mus > 0);
        
        % 6. calculate: biovolume production rate = V(t) * mu(t) * ln(2)
        bioProdRate = trueVols .* trueMus * log(2); % log(2) in matlab = ln(2)
        
        % 7. isolate data to stabilized regions of growth
        conditionStabilizedPeriod = currentStabilizedPeriods(c,:);
        
        minTime = conditionStabilizedPeriod(1);  % hr
        maxTime = conditionStabilizedPeriod(2);
        
        times_trim1 = trueTimes(trueTimes >= minTime);
        bioProdRate_trim1 = bioProdRate(trueTimes >= minTime);
        
        bioProdRate_trim2 = bioProdRate_trim1(times_trim1 <= maxTime);
        
        % 8. calculate average and s.e.m. per timebin
        mean_bioProdRate = mean(bioProdRate_trim2);
        count_BioProdRate = length(bioProdRate_trim2);
        std_BioProdRate = std(bioProdRate_trim2);
        sem_BioProdRate = std_BioProdRate./sqrt(count_BioProdRate);
        

        % 9. plot average biovolume production rate over time
        figure(1)
        if e == 1
            errorbar(concentrationList{e,c},mean_bioProdRate,sem_BioProdRate,'o','Color',[0 0.7 0.7],'MarkerSize',10)
            axis([0,1.1,0,30])
            grid on
            hold on
            xlabel('Concentration (Fraction LB)')
            ylabel('biovolume production rate (cubic um/hr)')  
        else
            errorbar(concentrationList{e,c},mean_bioProdRate,sem_BioProdRate,'o','Color',[1 0.6 0],'MarkerSize',10)
            hold on 
        end
        legend('expt1-1','expt1-1/8','expt1-1/32','expt1-1/100','expt1-1/1000','expt1-1/10000','fluc1','low1','ave1','high1')
        
        
        % 14. repeat for all conditions
    end
    clear exptData M D5 T
end