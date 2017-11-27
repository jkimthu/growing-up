% plotMonod

% goal: plot monod curve using compiled LB data

% strategy:
%
%       0. initialize experiment data
%       1. for each experiment, load data
%               2. for each condition in experiment:
%                       3. isolate condition specific Mu_va and time data
%                       4. remove mu data with timestamps prior to and after stabilization
%                       5. remove zeros (always two at start and end of track) and negatives
%                       6. calculate mean and sem
%                       7. store mean and conc data for fitting
%                       8. plot ave mu_va vs concentration
%                       9. plot ave mu_va vs log(concentration)
%                      10. calculate and plot fit curve
%              11. repeat for all conditions
%      12.  repeat for all experiments
%   


% last updated: 2017 November 24

%% 0. initialize experiment data
clear
clc

cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')

dataIndex = find(~cellfun(@isempty,storedMetaData));
measuredData = cell(size(storedMetaData));

%% 1. for each experiment, load data
for e = 1:length(dataIndex)
    
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
    
    %% 2. for each condition in experiment, calculate mean mu and error
    xys = storedMetaData{index}.xys;
    xy_dimensions = size(xys);
    totalConditions = xy_dimensions(1);
    
    % initialize structures for data storage
    compiledTrackMeans = cell(1,totalConditions);
    compiledIndividualStats= cell(1,totalConditions);
    
    for c = 1:totalConditions
        
        % 3. isolate condition specific Mu_va and time data
        condition = exptData(exptData(:,35) == c,:); % col 35 = condition
        mu_va = condition(:,18); % col 18 = calculated mu_vals
        time = condition(:,2)/3600; % col 2 = timestamps in sec, covert to hr
        track = condition(:,34); % col 34 = track count, not ID from tracking
        clear condition
        
        % 4. remove mu data with timestamps prior to and after stabilization
        haltTimes = storedMetaData{index}.bubbletime;
        
        mus_trim1 = mu_va(time >= 3);  % consider only timepoints after 3 hrs
        time_trim1 = time(time >= 3);
        track_trim1 = track(time >= 3);
        
        if haltTimes(c) > 0
            mus_trim2 = mus_trim1(time_trim1 <= haltTimes(c));
            %time_trim2 = time_trim1(time_trim1 <= haltTimes(c));
            track_trim2 = track_trim1(time_trim1 <= haltTimes(c));
        else
            mus_trim2 = mus_trim1;
            track_trim2 = track_trim1;
        end
        
        % 5. remove zeros (always two at start and end of track) and negatives
        mus_trim3 = mus_trim2(mus_trim2 > 0);
        track_trim3 = track_trim2(mus_trim2 > 0);
        
        % 6. calculate mean and sem
        % i. for all individual (but not independent) points
        muMean = mean(mus_trim3);
        muStd = std(mus_trim3);
        muCounts = length(mus_trim3);
        muSem = muStd./sqrt(muCounts);
        
        
        % ii. for each track, then calculate condition mean (weighted by track)
        
        % determine length of each track (post-trimming)
        [a,trackID]=hist(track_trim3,unique(track_trim3));
        trackLength = a';
        
        % limit analysis to tracks >= 30 points long
        finalTracks = trackID(trackLength>=10);
        
        % calculate mean for each track
        trackMeans = zeros(length(finalTracks),1);
        for t = 1:length(finalTracks)
            currentTrack = finalTracks(t);
            trackMus = mus_trim3(track_trim3==currentTrack);
            trackMeans(t) = mean(trackMus);
        end
        clear finalTracks trackMus
        
        % 7. accumulate data for storage
        compiledTrackMeans{c} = trackMeans;
        compiledIndividualStats{c}.muMean = muMean; 
        compiledIndividualStats{c}.muStd = muStd;
        compiledIndividualStats{c}.muCounts = muCounts;
        compiledIndividualStats{c}.muSem = muSem;
        
        clear track_trim1 track_trim2 track_trim3 mus_trim1 mus_trim2 mus_trim3
        clear time_trim1 time_trim2 trackLength trackID a currentTrack
    end
    
    % 8. store data from all conditions into measured data structure
    measuredData{index}.tracks = compiledTrackMeans;
    measuredData{index}.individuals = compiledIndividualStats;
    
end
%% 9. save stored data into measured data structure
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
save('measuredData.mat','measuredData')

%% 10. plot ave mu_va vs concentration
clc
clear

load('storedMetaData.mat')
load('measuredData.mat')
dataIndex = find(~cellfun(@isempty,storedMetaData));

% for each experiment, load data
for e = 1:length(dataIndex)
    
    % identify experiment by date
    index = dataIndex(e);
    date{e} = storedMetaData{index}.date;
    
    % load timescale
    timescale = storedMetaData{index}.timescale;
    
    % isolate mu data for current experiment
    data_individuals = measuredData{index}.individuals;
    data_tracks = measuredData{index}.tracks;
    
    % isolate concentration data for current experiment
    concentration = storedMetaData{index}.concentrations;
    
    % plot individual data, labeled by experiment date
    figure(1)
    for c = 1:length(concentration)
        h(e) = errorbar(log(concentration(c)), data_individuals{c}.muMean, data_individuals{c}.muSem,'o','Color',[0 1 1]*e*.1,'MarkerSize',10);
        hold on
        legend(h(:),date)
    end
    xlabel('mu, individual (1/hr)')
    ylabel('log fold LB dilution')
    
    % plot individual data, labeled by stable vs fluc
    figure(2)
    for c = 1:length(concentration)
        % if fluc experiment
        if ischar(timescale)
            errorbar(log(concentration(c)), data_individuals{c}.muMean, data_individuals{c}.muSem,'o','Color','k','MarkerSize',10);
            hold on
        elseif timescale == 30 && c == 1
            errorbar(log(concentration(c)), data_individuals{c}.muMean, data_individuals{c}.muSem,'o','Color',[0.25 0.25 0.9],'MarkerSize',10);
            hold on
        elseif timescale == 300 && c == 1
            errorbar(log(concentration(c)), data_individuals{c}.muMean, data_individuals{c}.muSem,'o','Color',[0 .7 .7],'MarkerSize',10);
            hold on
            legend('5 min')
        elseif timescale == 900 && c == 1
            errorbar(log(concentration(c)), data_individuals{c}.muMean, data_individuals{c}.muSem,'o','Color',[1 0.6 0],'MarkerSize',10);
            hold on
        else
            errorbar(log(concentration(c)), data_individuals{c}.muMean, data_individuals{c}.muSem,'o','Color','k','MarkerSize',10);
            hold on
        end
    end
    legend('30 sec','5 min','15 min','stable')
    xlabel('mu, individual (1/hr)')
    ylabel('log fold LB dilution')
    
    % plot track data, labeled by experiment date
    figure(3)
    expMeans = cellfun(@mean,data_tracks);
    expStds = cellfun(@std,data_tracks);
    expCounts = cellfun(@length, data_tracks);
    expSems = expStds./sqrt(expCounts);
    
    for c = 1:length(concentration)
        if ~isempty(data_tracks{c})
            p(e) = errorbar(log(concentration(c)), expMeans(c), expSems(c),'o','Color',[0 1 1]*e*.1,'MarkerSize',10);
            hold on
            legend(p(:),date)
        else
            continue
        end
        axis([-10 2 0 4])
    end
    xlabel('mu, track (1/hr)')
    ylabel('log fold LB dilution')
    
end

%
%                      10. calculate and plot fit curve (model: quadratic)
%              11. repeat for all conditions
%      12.  repeat for all experiments
               
%%

    
    for c = 1:max(conditions)
 
        
        % 8. plot ave mu_va vs concentration
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
        
        % 9. plot ave mu_va vs log(concentration)
        figure(2)
        if e == 1
            errorbar(log10(concentrationList{e,c}),muMean,muSem,'o','Color',[0 0.7 0.7],'MarkerSize',10)
            axis([-4,0.1,0,4])
            grid on
            hold on
            xlabel('log concentration (Fraction LB)')
            ylabel('doubling rate of volume (hr-1)')
        else
            errorbar(log10(concentrationList{e,c}),muMean,muSem,'o','Color',[1 0.6 0],'MarkerSize',10)
            axis([-4,0.1,0,4])
            hold on 
        end
        legend('expt1-1','expt1-1/8','expt1-1/32','expt1-1/100','expt1-1/1000','expt1-1/10000','fluc1','low1','ave1','high1')

        
    end
    clear exptData M D5 T
end
%%
% 10. calculate and plot fit (model: quadratic)
qFit = fit(x,y,'smoothingspline','Exclude',2);
figure(4); hold on; plot(qFit,x,y);