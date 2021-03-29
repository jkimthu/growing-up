%% figure S8e. distributions of division time across conditions


%  Goal: testing alternative hypothesis that observed fluctuations in
%        average growth rate are division-dependent, rather than changes in
%        single-cell growth rate

%  Strategy:
%
%        0. compile division times from all experiments in study
%        1. plot histograms of division time across conditions
%        2. plot pdf of division time across conditions


%  last updated: jen, 2021 Mar 29
%  commit: final version of supplementary fig. 8e


% OK let's go!

%% Part 0. generate dataset of all interdivision times

clc
clear

% 0. initialize complete meta data
source_data = '/Users/jen/Documents/StockerLab/Source_data';
cd(source_data)
load('storedMetaData.mat')


% 0. initialize data
exptArray = [2,3,4,5,6,7,9,10,11,12,13,14,15]; % use corresponding dataIndex values


% 1. initialize environmental conditions for data collection and plotting
environment_order = {'low','30','300','900','3600','ave','high'};
environment_ticks = zeros(length(environment_order),1);

tau = cell(1,length(environment_order));
t_birth = cell(1,length(environment_order));
t_division = cell(1,length(environment_order));


% for all experiments
for e = 1:length(exptArray)
    
    
    % 2. initialize experiment meta data
    index = exptArray(e);
    date = storedMetaData{index}.date;
    timescale = storedMetaData{index}.timescale;
    bubbletime = storedMetaData{index}.bubbletime;
    expType = storedMetaData{index}.experimentType;
    
    disp(strcat(date, ': analyze!'))
    
    
    % 3. load measured data
    cd(source_data)
    filename = strcat('lb-fluc-',date,'-c123-width1p4-c4-1p7-jiggle-0p5.mat');
    load(filename,'D5','T');

    
    % 4. compile experiment data matrix
    xy_start = min(min(storedMetaData{index}.xys));
    xy_end = max(max(storedMetaData{index}.xys));
    exptData = buildDM(D5, T, xy_start, xy_end,index,expType);
    
    for condition = 1:length(bubbletime)
        
        % 5. isolate condition specific data
        condVals = getGrowthParameter(exptData,'condition');   
        conditionData = exptData(condVals == condition,:);
        clear condVals
        
        
        % 6. trim data to full cell cycles ONLY
        ccFraction = getGrowthParameter(conditionData,'ccFraction');       % col 9 = ccFraction
        conditionData_fullOnly = conditionData(~isnan(ccFraction),:);
        clear ccFraction
        
        
        % 7. isolate corrected time, cell cycle duration and birth event data (drop)
        curveFinder = getGrowthParameter(conditionData_fullOnly,'curveFinder');      % col 6   = curve Finder
        curveDurations = getGrowthParameter(conditionData_fullOnly,'curveDurations');       % col 3  = length (um)
        timestamps = getGrowthParameter(conditionData_fullOnly,'timestamp')/3600;  % col 2   = raw timestamps
        
        
        % 8. prepare to assign condition data into a cell, where:
        % column = environmental condition
        % row = biological replicate
        
        % i. determine column no. of environmental condition
        if condition == 2
            eColumn = find(strcmp(environment_order,'low'));
        elseif condition == 3
            eColumn = find(strcmp(environment_order,'ave'));
        elseif condition == 4
            eColumn = find(strcmp(environment_order,'high'));
        else
            eColumn = find(strcmp(environment_order,num2str(timescale)));
        end
        environment_ticks(eColumn) = environment_ticks(eColumn) + 1;
        
        % ii. determine replicate no. of current condition data
        eRow = environment_ticks(eColumn);
        
        
        
        % 9. for each unique cell cycle, collect birth size, added size, ad
        %    time of birth and division
        unique_cycles = unique(curveFinder);
        curveCounter = 0;
        
        condition_taus = [];
        condition_birthTimes = [];
        condition_divTimes = [];
        
        
        for cc = 1:length(unique_cycles)
            
            currentTimes = timestamps(curveFinder == unique_cycles(cc));
            
            % discard all cell cycles shorter than 10 min
            if length(currentTimes) < 5
                %disp(strcat('short cycle: ',num2str(length(currentTimes))))
                continue
            end
            
            % discard all cell cycles born before 3 hr or dividing after bubble
            if currentTimes(1) < 3
                %disp(strcat(num2str(currentTimes(1)),': toss, before 3 hrs'))
                continue
            elseif bubbletime(condition) ~= 0 && currentTimes(end) > bubbletime(condition)
                %disp(strcat(num2str(currentTimes(end)),': toss, divides after bubble'))
                continue
            end
            
            % for all remaining curves, count and collect data
            curveCounter = curveCounter + 1;

            currentTaus = curveDurations(curveFinder == unique_cycles(cc));
            condition_taus(curveCounter,1) = currentTaus(1);
            
            condition_birthTimes(curveCounter,1) = currentTimes(1);
            condition_divTimes(curveCounter,1) = currentTimes(end);
            
        end
        clear currentTaus

        tau{eRow,eColumn} = condition_taus;
        t_birth{eRow,eColumn} = condition_birthTimes;
        t_division{eRow,eColumn} = condition_divTimes;
        
        clear condition_divTimes condition_birthTimes condition_taus
        
    end
end

cd(source_data)
save('sfig8_data.mat','tau','t_birth','t_division')


%% Part 1. plot distributions of division time per condition


clear
clc


% 0. initialize complete meta data
source_data = '/Users/jen/Documents/StockerLab/Source_data';
cd(source_data)
load('storedMetaData.mat')
load('sfig8_data.mat')

environment_order = {'low','30','300','900','3600','ave','high'};
palette = {'Indigo','DarkTurquoise','SteelBlue','DeepSkyBlue','DodgerBlue','GoldenRod','FireBrick'};


% 1. loop through conditions to plot histogram as subplot
for cond = 1:length(environment_order)
    
    
    % i. initialize color for current condition
    color = rgb(palette(cond));
    
    
    % ii. isolate data from current condition
    cond_tau = tau(:,cond);
    
    
    % iii. compile division times from all replicates
    compiled_tau = [];
    for rep = 1:length(cond_tau)
        
        rep_taus = cond_tau{rep,1};
        compiled_tau = [compiled_tau; rep_taus];
        
    end
    clear rep rep_taus
    
    
    % iv. convert division times from seconds to min
    tau_min = compiled_tau./60;
    
    
    % v. plot division events over time
    figure(1)
    subplot(1,length(environment_order),cond)
    histogram(tau_min,'FaceColor',color,'EdgeColor',color,'BinWidth',2)
    hold on
    title(environment_order{cond})
    xlim([0 100])
    
    if cond == 1
        
        figure(1)
        hold on
        ylabel('Cell count')
        
    elseif cond == ceil(length(environment_order)/2)
        
        figure(1)
        hold on
        xlabel('Division time (min)')
 
    end
    
    
    % vi. calculate and plot mean tau per condition
    tau_means(cond,1) = mean(tau_min);
    tau_medians(cond,1) = median(tau_min);
    tau_stds(cond,1) = std(tau_min);
    tau_counts(cond,1) = length(tau_min);
    
    figure(1)
    subplot(1,length(environment_order),cond)
    hold on
    plot(tau_means(cond,1),0,'o','Color',color)

end


%% Part 2. plot pdfs of division time per condition


clear
clc


% 0. initialize complete meta data
source_data = '/Users/jen/Documents/StockerLab/Source_data';
cd(source_data)
load('storedMetaData.mat')
load('sfig11_data.mat')

environment_order = {'low','30','300','900','3600','ave','high'};
palette = {'Indigo','DarkTurquoise','SteelBlue','DeepSkyBlue','DodgerBlue','GoldenRod','FireBrick'};


% 1. loop through conditions to plot histogram as subplot
for cond = 1:length(environment_order)
    
    
    % i. initialize color for current condition
    color = rgb(palette(cond));
    
    
    % ii. isolate data from current condition
    cond_tau = tau(:,cond);
    
    
    % iii. compile division times from all replicates
    compiled_tau = [];
    for rep = 1:length(cond_tau)
        
        rep_taus = cond_tau{rep,1};
        compiled_tau = [compiled_tau; rep_taus];
        
    end
    clear rep rep_taus
    
    
    % iv. convert division times from seconds to min
    tau_min = compiled_tau./60;
    
    
    % v. bin division times into 2 min bins
    lastbin = max(tau_min)/2;
    numbins = ceil(lastbin);
    
    bins = (1:numbins)*2;
    tau_by_bins = (ceil(tau_min./2));
    tau_binned = accumarray(tau_by_bins,tau_min,[],@(x) {x});
    tau_counts = cellfun(@length,tau_binned);
    tau_pdf = tau_counts./length(tau_min);
    
    
    % vi. plot pdf of division events
    figure(cond)
    bar(bins,tau_pdf,'FaceColor',color,'EdgeColor',color,'BarWidth',0.75)
    hold on
    title(environment_order{cond})
    xlim([10 90])
    ylim([0 0.3])
    ylabel('Cell count')
    xlabel('Division time (min)')
    
  
    
    % vi. calculate and plot mean tau per condition
    tau_means(cond,1) = mean(tau_min);
    tau_medians(cond,1) = median(tau_min);
    tau_stds(cond,1) = std(tau_min);
    tau_counts(cond,1) = length(tau_min);
    
    
    figure(cond)
    hold on
    plot(tau_means(cond,1),0,'o','Color',color)
    
    %saveas(gcf,strcat('supfig8e-',environment_order{cond}),'epsc')
    

end



