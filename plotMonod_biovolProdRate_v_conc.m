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


% last updated: 2017 November 28

%% 0. initialize experiment data
clear
clc

cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')

dataIndex = find(~cellfun(@isempty,storedMetaData));
bioProdRateData = cell(size(storedMetaData));

% initialize summary vectors for calculated data
experimentCount = length(dataIndex);

%% 1. for each experiment, move to folder and load data

for e = 1:experimentCount
    
    % identify experiment by date
    index = dataIndex(e);
    date = storedMetaData{index}.date;
    
    % move directory to experiment data
    experimentFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',date);
    cd(experimentFolder)
    
    % load data
    timescale = storedMetaData{index}.timescale;
    if ischar(timescale) == 0
        filename = strcat('lb-fluc-',date,'-window5-width1p4-1p7-jiggle-0p5.mat');
    elseif strcmp(date,'2017-09-26') == 1
        filename = 'lb-monod-2017-09-26-window5-va-jiggle-c12-0p1-c3456-0p5-bigger1p8.mat';
    elseif strcmp(date, '2017-11-09') == 1
        filename = 'lb-control-2017-11-09-window5-width1p4-jiggle-0p5.mat';
    end
    load(filename,'D5','M','M_va','T')
    
    % build experiment data matrix
    display(strcat('Experiment (', num2str(e),') of (', num2str(length(dataIndex)),')'))
    exptData = buildDM(D5,M,M_va,T);
    
    clear D5 M M_va T filename experimentFolder
   
    % 2. for each condition, calculate mean biovolume production rate per condition
    xys = storedMetaData{index}.xys;
    xy_dimensions = size(xys);
    totalConditions = xy_dimensions(1);
    
    for c = 1:totalConditions
        
        % 3. isolate all data from current condition
        conditionData = exptData(exptData(:,35) == c,:);
        
        % 4. isolate volume (Va), mu (mu_va) and time data from current condition
        volumes = conditionData(:,15);        % col 15 = calculated va_vals (cubic um)
        mus = conditionData(:,18);            % col 18 = calculated mu_va 
        timestamps = conditionData(:,2)/3600; % time in seconds converted to hours
        clear conditionData
        
        % 5. remove data for which mu = 0, as these were the edges of tracks that never get calculated
        trueMus = mus(mus > 0);
        trueVols = volumes(mus > 0);
        trueTimes = timestamps(mus > 0);
        clear volumes mus timestamps
        
        % 6. calculate: biovolume production rate = V(t) * mu(t) * ln(2)
        bioProdRate = trueVols .* trueMus * log(2); % log(2) in matlab = ln(2)
        clear trueVols trueMus 
        
        % 7. isolate data to stabilized regions of growth
        minTime = 3;  % hr
        maxTime = storedMetaData{index}.bubbletime(c);
        
        times_trim1 = trueTimes(trueTimes >= minTime);
        bioProdRate_trim1 = bioProdRate(trueTimes >= minTime);
        clear trueTimes
        
        if maxTime > 0
            bioProdRate_trim2 = bioProdRate_trim1(times_trim1 <= maxTime);
        else
            bioProdRate_trim2 = bioProdRate_trim1;
        end
        clear times_trim1
        
        % 8. calculate average and s.e.m. per timebin
        mean_bioProdRate = mean(bioProdRate_trim2);
        count_BioProdRate = length(bioProdRate_trim2);
        std_BioProdRate = std(bioProdRate_trim2);
        sem_BioProdRate = std_BioProdRate./sqrt(count_BioProdRate);
        
        % 9. accumulate data for storage / plotting
        compiledbioProdRate{c}.mean = mean_bioProdRate;
        compiledbioProdRate{c}.std = std_BioProdRate;
        compiledbioProdRate{c}.count = count_BioProdRate;
        compiledbioProdRate{c}.sem = sem_BioProdRate;
        
        clear mean_bioProdRate std_BioProdRate count_BioProdRate sem_BioProdRate
        clear bioProdRate bioProdRate_trim1 bioProdRate_trim2 maxTime  
    
    end
    
    % 10. store data from all conditions into measured data structure        
    bioProdRateData{index} = compiledbioProdRate;
    
end


%% 11. save stored data into data structure
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
save('bioProdRateData.mat','bioProdRateData')

%% 12. plot average biovolume production rate over time
clc
clear

cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')
load('bioProdRateData.mat')
dataIndex = find(~cellfun(@isempty,storedMetaData));
experimentCount = length(dataIndex);

% initialize summary stats for fitting
counter = 0;
summaryMeans = zeros(1,(experimentCount-1)*3 + 6);
summaryConcentrations = zeros(1,(experimentCount-1)*3 + 6);


for e = 1:experimentCount
    
    % identify experiment by date
    index = dataIndex(e);
    date{e} = storedMetaData{index}.date;
    
    % load timescale
    timescale = storedMetaData{index}.timescale;
    
    % isolate biomass prod data for current experiment
    experimentData = bioProdRateData{index};
    
    % isolate concentration data for current experiment
    concentration = storedMetaData{index}.concentrations;
    
    % plot, labeled by experiment date
    figure(1)
    for c = 1:length(concentration)
        h(e) = errorbar(log(concentration(c)), experimentData{c}.mean, experimentData{c}.sem,'o','Color',[0 1 1]*e*.1,'MarkerSize',10);
        hold on
        legend(h(:),date)
    end
    ylabel('biomass prodution rate (cubic um/hr)')
    xlabel('log fold LB dilution')
    
    % plot individual data, labeled by stable vs fluc
    figure(2)
    for c = 1:length(concentration)
        % if fluc experiment
        if ischar(timescale)
            errorbar(log(concentration(c)), experimentData{c}.mean, experimentData{c}.sem,'o','Color','k','MarkerSize',10);
            hold on

            % for stable conditions, accumulate data into summary vector
            counter = counter + 1;
            summaryMeans(counter) = experimentData{c}.mean;
            summaryConcentrations(counter) = concentration(c);

        elseif timescale == 30 && c == 1
            errorbar(log(concentration(c)), experimentData{c}.mean, experimentData{c}.sem,'o','Color',[0.25 0.25 0.9],'MarkerSize',10);
            hold on
        elseif timescale == 300 && c == 1
            errorbar(log(concentration(c)), experimentData{c}.mean, experimentData{c}.sem,'o','Color',[0 .7 .7],'MarkerSize',10);
            hold on
            legend('5 min')
        elseif timescale == 900 && c == 1
            errorbar(log(concentration(c)), experimentData{c}.mean, experimentData{c}.sem,'o','Color',[1 0.6 0],'MarkerSize',10);
            hold on
        else
            errorbar(log(concentration(c)), experimentData{c}.mean, experimentData{c}.sem,'o','Color','k','MarkerSize',10);
            hold on
            
            % for stable conditions, accumulate data into summary vector
            counter = counter + 1;
            summaryMeans(counter) = experimentData{c}.mean;
            summaryConcentrations(counter) = concentration(c);
        end
    end
    legend('30 sec','5 min','15 min','stable')
    ylabel('biomass prod rate (cubic um/hr)')
    xlabel('log fold LB dilution')
    
end

