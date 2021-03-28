%% Supplementary Fig. 3


% goal: characterize signal between junction and cell positions
%            1. time lag between fluorescein signal at junction and at final cell imaging point, xy10
%            2. timescale of transition between low and high phases of signal
%            3. time between shifts (regularity of fluctuation periods)


% these three goals correspond to Supplementary Fig. 3a, b and c, respectively.
% running this script gives:
%            figure 1 = Supplementary Fig. 3a
%            figure 5 = Supplementary Fig. 3b
%            figure 3 & 4 = Supplementary Fig. 3c


% strategy: find peaks and troughs in fluorescent signal to determine when
%           transitions between low and high "nutrient" are completed
%     
%       0. initialize experiment parameters, including intended signal period
%       1. load signal and time data
%       2. find time location of transitions (upshifts and downshifts) 
%               i. find local max of signal derivative
%              ii. find local min of signal derivative
%       3. confirm period of signal junction and cell position by calculating the time
%          between upshift and downshift transitions
%       4. calculate phase shift as difference in time locations between
%          transitions at signal junction and at cell position
%               i. using fluorescein derivative maxima
%              ii. using fluorescein derivative minima
%       5. plot


% last edit: jen, 2021 Mar 27
% commit: revised bar plots for final submission

% OK let's go!

%% characterizing nutrient signals by identifying peaks and troughs in fluorescent label

clear
clc

for i = 1 % choose dataset with which to visualize timescale characterization
    
    % 0. initialize experiment parameters, includign intended signal period
    if i == 1
        
        experiment = '2017-11-15';  % date of experiment
        type = 'fluorescein';       % experiment type, fluorescein OR growth
        period = 30;                % in seconds, period used in 2017-11-15 tests
        scale = 5/6;
        
    elseif i == 2
        
        experiment = '2018-01-31';  % date of experiment
        type = 'fluorescein';       % experiment type, fluorescein OR growth
        period = 10;                % in seconds, period used in 2018-01-31 tests
        scale = 2/3;
        
    elseif i == 3
       
        experiment = '2018-02-01';  % date of experiment
        type = 'fluorescein';       % experiment type, fluorescein OR growth
        period = 10;                % in seconds, period used in 2018-02-01 tests
        scale = 2/3;
        
    end
    
    % 1. load signal and time data
    exptFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',experiment);
    cd(exptFolder);
    [signals,timestamps] = calculateFluoresceinSignal(experiment); % 1st column = junc, 2nd column = xy10
    
    
    % CALCULATING PERIOD AND PHASE SHIFT
    
    % 2. find time location of transitions (upshifts and downshifts)
    %    by finding local max and min of signal derivative
    signal_junc = signals{1}';
    signal_cellXY = signals{2}';
    
    timestamps_junc{i,1} = timestamps(2:end,1);
    timestamps_cellXY{i,1} = timestamps(2:length(signal_cellXY),2);
    
    deriv_junc{i,1} = diff(signal_junc);
    deriv_cellXY{i,1} = diff(signal_cellXY);
    
    plot(timestamps_junc{i,1},signal_junc(2:end))
    hold on
    plot(timestamps_cellXY{i,1},signal_cellXY(2:end))
    
    
    % i. find local maxima in derivative
    figure(2)
    plot(timestamps_junc{i,1},deriv_junc{i,1})
    findpeaks(deriv_junc{i,1},timestamps_junc{i,1},'MinPeakDistance',period*scale)
    [peaks_junc,peakLocations_junc] = findpeaks(deriv_junc{i,1},timestamps_junc{i,1},'MinPeakDistance',period*scale);
    hold on
    
    plot(timestamps_cellXY{i,1},deriv_cellXY{i,1})
    findpeaks(deriv_cellXY{i,1},timestamps_cellXY{i,1},'MinPeakDistance',period*scale)
    [peaks_cellXY,peakLocations_cellXY] = findpeaks(deriv_cellXY{i,1},timestamps_cellXY{i,1},'MinPeakDistance',period*scale);
    title('fluorescence signal deritatives with identified local maxima')
    legend('reference signal','local maxima','test signal')
    
    % ii. find local minima in derivative
    [troughs_junc,troughLocations_junc] = findpeaks(-deriv_junc{i,1},timestamps_junc{i,1},'MinPeakDistance',period*scale);
    [troughs_cellXY,troughLocations_cellXY] = findpeaks(-deriv_cellXY{i,1},timestamps_cellXY{i,1},'MinPeakDistance',period*scale);
    
    
    clear peaks_reference_deriv peaks_test_deriv troughs_reference troughs_test
    
    
    % 3. confirm period in junction and cell position by calculating the time
    %    between up and down transitions
    distances_peaks{1} = diff(peakLocations_junc);
    distances_peaks{2} = diff(peakLocations_cellXY);
    
    distances_troughs{1} = diff(troughLocations_junc);
    distances_troughs{2} = diff(troughLocations_cellXY);
    
    mean_timeBetweenPeaks{i,1} = cellfun(@mean,distances_peaks); % each cell has two values: 1 = junction, 2 = cell position
    std_timeBetweenPeaks{i,1} = cellfun(@std,distances_peaks);
    
    mean_timeBetweenTroughs{i,1} = cellfun(@mean,distances_troughs);
    std_timeBetweenTroughs{i,1} = cellfun(@std,distances_troughs);
    
    
    
    % 4. calculate phase shift as difference in time locations between
    %    test and reference transitions
    
    % i. using fluorescein derivative maxima (time of upshifts)
    phaseShift{1} = peakLocations_cellXY - peakLocations_junc(1:length(peakLocations_cellXY));
    
    % ii. using fluorescein derivative minima (time of downshifts)
    phaseShift{2} = troughLocations_cellXY - troughLocations_junc(1:length(troughLocations_cellXY));
    
    mean_phaseShift{i,1} = cellfun(@mean,phaseShift);
    std_phaseShift{i,1} = cellfun(@std,phaseShift);
    
end



% 5. plot data
barWidth = 0.6;

% Supplementary Fig. 2b, part 1
figure(3) 
bar(cell2mat(mean_timeBetweenPeaks),barWidth)
hold on
errorbar(cell2mat(mean_timeBetweenPeaks), cell2mat(std_timeBetweenPeaks),'.')
set(gca,'xticklabel',{'junction','cell position'});
title('measured period and standard deviation')
ylabel('mean time between upshifts (sec)')

% add scattered individual points
spread_x = ones(size(distances_peaks)).*(1+(rand(size(distances_peaks{1}))-0.4)/10);
color = rgb('SlateGray');

figure(3)
hold on
for col = 1:2
    scatter(spread_x(:,col)+col-1,distances_peaks{:,col},'MarkerFaceColor',color,'MarkerEdgeColor',color)
end



% Supplementary Fig. 2c, part 2
figure(4) 
bar(cell2mat(mean_timeBetweenTroughs),barWidth)
hold on
errorbar(cell2mat(mean_timeBetweenTroughs), cell2mat(std_timeBetweenTroughs),'.')
%set(gca,'xticklabel',{'2017-11-15','2018-01-31','2018-02-01'});
set(gca,'xticklabel',{'junction','cell position'});
title('measured period and standard deviation')
ylabel('mean time between downshifts (sec)')

% add scattered individual points
spread_x = ones(size(distances_troughs)).*(1+(rand(size(distances_troughs{1}))-0.4)/10);
color = rgb('SlateGray');

figure(4)
hold on
for col = 1:2
    scatter(spread_x(:,col)+col-1,distances_troughs{:,col},'MarkerFaceColor',color,'MarkerEdgeColor',color)
end





% Supplementary Fig. 2b
figure(5) 
bar(cell2mat(mean_phaseShift),barWidth)
hold on
errorbar(cell2mat(mean_phaseShift), cell2mat(std_phaseShift),'.')
%set(gca,'xticklabel',{'2017-11-15','2018-01-31','2018-02-01'});
set(gca,'xticklabel',{'junction','cell position'});
title('measured lagtime and standard deviation')
ylabel('mean time between transitions (sec)')

% add scattered individual points
spread_x = ones(size(phaseShift)).*(1+(rand(size(phaseShift{1}))-0.4)/10);
color = rgb('SlateGray');

figure(5)
hold on
for col = 1:2
    scatter(spread_x(:,col)+col-1,phaseShift{:,col},'MarkerFaceColor',color,'MarkerEdgeColor',color)
end
