%% phasePhinder

% goal: calculate phase shift between signals, such as
%            1. time lag between fluorescein signal at junction and at final cell imaging point, xy10
%            2. phase shift between growth signal and nutrient signal


% initially, I thought I could use the following oscillator model to fit a value for phase shift
% however, the signals are not quite sinusoidal and at least some contain multiple frequencies

% model:   y(t) = A * sin( omega*t - phi )
% where,
%               A   =  amplitude of oscillations
%             omega =  angular velocity = 2*pi/period,
%                      which represents a repeating process on a unit circle
%              phi  =  phase constant, which shifts the phase left or right
%                      example: phi = -pi/2 shifts signal a quarter period forwards
%               t   =  time
%              y(t) =  signal


% thus, i'm using other solutions to quantify period, amplitude, and phase shift

% ONE. strategy based on finding signal peaks:
%     
%       0. initialize experiment parameters, including intended signal period
%       1. load signal and time data
%       2. find time location of transitions (upshifts and downshifts) 
%               i. find local max of signal derivative
%              ii. find local min of signal derivative
%       3. confirm period of reference and test by calculating the time
%          bewteen upshift and downshift transitions
%       4. calculate phase shift as difference in time locations between
%          test and reference transitions
%               i. using fluorescein derivative maxima
%              ii. using fluorescein derivative minima
%       5. find time location of local max and min of fluorescent signal
%       6. calculate amplitude of oscillations = max(i) - min(i) / 2
%       7. plot



% TWO. strategy based on best alignment (overlap) between two signals

%       0. initialize experiment parameters, including intended signal period
%       1. load signal and time data


% last edit: jen, 2018 Feb 20

% commit: adding new method to measure phase shift, using a normalized
%         cross correlation to determine the time lag between junction and
%         xy10. note: current fluorescein timeseries are imaged with "no
%         delay", in other words: inconsistent frame rate. since
%         cross-correlation works with indeces, it's not so effect for
%         these.

% OK lez go!

%% ONE. finding peaks of signal and derivative

clear
clc

for i = 1:3 % currently only three experiments with this type of test
    
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
    referenceSignal = signals{1}';
    testSignal = signals{2}';
    
    referenceTimestamps{i,1} = timestamps(2:end,1);
    testTimestamps{i,1} = timestamps(2:length(testSignal),2);
    
    deriv_reference{i,1} = diff(referenceSignal);
    deriv_test{i,1} = diff(testSignal);
    
    plot(referenceTimestamps{i,1},referenceSignal(2:end))
    hold on
    plot(testTimestamps{i,1},testSignal(2:end))
    
    
    % i. find local maxima in derivative
    figure(2)
    plot(referenceTimestamps{i,1},deriv_reference{i,1})
    findpeaks(deriv_reference{i,1},referenceTimestamps{i,1},'MinPeakDistance',period*scale)
    [peaks_reference_deriv,location_referencePeaks_deriv] = findpeaks(deriv_reference{i,1},referenceTimestamps{i,1},'MinPeakDistance',period*scale);
    hold on
    
    plot(testTimestamps{i,1},deriv_test{i,1})
    findpeaks(deriv_test{i,1},testTimestamps{i,1},'MinPeakDistance',period*scale)
    [peaks_test_deriv,location_testPeaks_deriv] = findpeaks(deriv_test{i,1},testTimestamps{i,1},'MinPeakDistance',period*scale);
    title('fluorescence signal deritatives with identified local maxima')
    legend('reference signal','local maxima','test signal')
    
    % ii. find local minima in derivative
    %plot(referenceTimestamps{i,1},deriv_reference{i,1})
    %findpeaks(-deriv_reference{i,1},referenceTimestamps{i,1},'MinPeakDistance',period*5/6)
    [troughs_reference,location_referenceTroughs] = findpeaks(-deriv_reference{i,1},referenceTimestamps{i,1},'MinPeakDistance',period*scale);
    [troughs_test,location_testTroughs] = findpeaks(-deriv_test{i,1},testTimestamps{i,1},'MinPeakDistance',period*scale);
    
    
    clear peaks_reference_deriv peaks_test_deriv troughs_reference troughs_test
    
    
    % 3. confirm period of reference and test by calculating the time
    %    between up and down transitions
    distances_peaks{1} = diff(location_referencePeaks_deriv);
    distances_peaks{2} = diff(location_testPeaks_deriv);
    
    distances_troughs{1} = diff(location_referenceTroughs);
    distances_troughs{2} = diff(location_testTroughs);
    
    mean_timeBetweenPeaks{i,1} = cellfun(@mean,distances_peaks); % each cell has two values: 1 = reference, 2 = test
    std_timeBetweenPeaks{i,1} = cellfun(@std,distances_peaks);
    
    mean_timeBetweenTroughs{i,1} = cellfun(@mean,distances_troughs);
    std_timeBetweenTroughs{i,1} = cellfun(@std,distances_troughs);
    
    
    
    % 4. calculate phase shift as difference in time locations between
    %    test and reference transitions
    
    % i. using fluorescein derivative maxima (time of upshifts)
    phaseShift{1} = location_testPeaks_deriv - location_referencePeaks_deriv(1:length(location_testPeaks_deriv));
    
    % ii. using fluorescein derivative minima (time of downshifts)
    phaseShift{2} = location_testTroughs - location_referenceTroughs(1:length(location_testTroughs));
    
    mean_phaseShift{i,1} = cellfun(@mean,phaseShift);
    std_phaseShift{i,1} = cellfun(@std,phaseShift);
    
   
    
    % CALCULATING AMPLITUDE
    
    % 5. find time location of local max and min of fluorescent signal
    
    % i. local maxima
    figure(6)
    plot(referenceTimestamps{i,1},referenceSignal(2:end))
    findpeaks(referenceSignal(2:end),referenceTimestamps{i,1},'MinPeakDistance',period*5/6)
    [peaks_reference,location_referencePeaks] = findpeaks(referenceSignal(2:end),referenceTimestamps{i,1},'MinPeakDistance',period*5/6);
    hold on
    
    plot(testTimestamps{i,1},testSignal(2:end))
    findpeaks(testSignal(2:end),testTimestamps{i,1},'MinPeakDistance',period*5/6)
    [peaks_test,location_testpeaks] = findpeaks(testSignal(2:end),testTimestamps{i,1},'MinPeakDistance',period*5/6);
    
    % ii. local minima
    [troughs_reference,location_referenceTroughs] = findpeaks(-referenceSignal(2:end),referenceTimestamps{i,1},'MinPeakDistance',period*5/6);
    [troughs_test,location_testtroughs] = findpeaks(-testSignal(2:end),testTimestamps{i,1},'MinPeakDistance',period*5/6);
    
    
    % 6. calculate amplitude of oscillations = max(i) - min(i) / 2
    %    note: below, we ADD peaks and troughs because troughs are
    %    identified as the peaks of negative signal. ie
    
    amplitude{1} = (peaks_reference(1:length(troughs_reference)) + troughs_reference)/2;
    amplitude{2} = (peaks_test(1:length(troughs_test)) + troughs_test)/2;
    
    mean_amplitude{i,1} = cellfun(@mean,amplitude);
    std_amplitude{i,1} = cellfun(@std,amplitude);
    

end
%
% 7. plot data
barWidth = 0.6;

figure(3)
bar(cell2mat(mean_timeBetweenPeaks),barWidth)
hold on
errorbar(cell2mat(mean_timeBetweenPeaks), cell2mat(std_timeBetweenPeaks),'.')
legend('within reference','wihtin test')
set(gca,'xticklabel',{'reference','test'});
title('measured period and standard deviation')
ylabel('mean time between upshifts (sec)')

figure(4)
bar(cell2mat(mean_timeBetweenTroughs),barWidth)
hold on
errorbar(cell2mat(mean_timeBetweenTroughs), cell2mat(std_timeBetweenTroughs),'.')
legend('within reference','within test')
set(gca,'xticklabel',{'2017-11-15','2018-01-31','2018-02-01'});
title('measured period and standard deviation')
ylabel('mean time between downshifts (sec)')

figure(5)
bar(cell2mat(mean_phaseShift),barWidth)
hold on
errorbar(cell2mat(mean_phaseShift), cell2mat(std_phaseShift),'.')
legend('between upshifts','between downshifts')
set(gca,'xticklabel',{'2017-11-15','2018-01-31','2018-02-01'});
title('measured lagtime and standard deviation')
ylabel('mean time between junc and xy10 transitions (sec)')

figure(7)
bar(cell2mat(mean_amplitude),barWidth)
hold on
errorbar(cell2mat(mean_amplitude), cell2mat(std_amplitude),'.')
legend('of reference','of test')
set(gca,'xticklabel',{'2017-11-15','2018-01-31','2018-02-01'});
title('measured amplitude and standard deviation')
ylabel('mean signal amplitude (a.u.)')

%% TWO. find shift that produces greatest overlap between reference and test signals (x-corr)

%       0. initialize experiment parameters, including intended signal period
%       1. load signal and time data
%       2. perform cross-correlation between two signals

clear
clc

i = 1;

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
%%
clearvars -except signals experiment exptFolder period timestamps
%%
% 2. perform cross-correlation between two signals

% initialize signals
signal_lengths = cellfun(@length, signals);
trimTo = min(signal_lengths);
s1 = signals{1}(1:trimTo)'; % reference signal
s2 = signals{2}(1:trimTo)'; % test signal

t1 = timestamps(1:trimTo,1);   % timestamps for reference signal
t2 = timestamps(1:trimTo,2);   % timestamps for test signal

% plot signals in real time (un aligned)
figure(1)
plot(t1,s1)
hold on
plot(t2,s2)
xlabel('Time (s)')
ylabel('sum intensity (a.u.)')
legend('reference','test')

% cross correlate raw signals and find index of optimal correlation value
[corr_results,lags] = xcorr(s2,s1);
[~,index] = max(abs(corr_results)); % ~ does not keep val, vector of cross-correction values
lagDiff = lags(index); % lagDiff = 0, when signals are identical, even if not in time

% shift reference signal (s1) back in time by lag to visualize result
shift = nan([-lagDiff 1],'double'); % +1 to lag diff to account for 1-based indexing used by Matlab
s1_aligned = [shift; s1]; 
t1_aligned = [t1; shift];

figure(2)
plot(t1_aligned,s1_aligned)
hold on
plot(t2,s2)
xlabel('Time (s)')
ylabel('sum intensity (a.u.)')
legend('reference aligned','test')
title('reference aligned to test')

% normalized cross correlation
[corr_results_normalized,lags_normalize] = xcorr(s2,s1,'coeff');
[~,index_normalized] = max(abs(corr_results_normalized)); % ~ does not keep val, vector of cross-correction values
lagDiff_normalized = lags_normalize(index_normalized); % lagDiff = 0, when signals are identical, even if not in time

% shift reference signal (s1) back in time by lag to visualize result
shift_normalized = nan([-lagDiff_normalized 1],'double'); % +1 to lag diff to account for 1-based indexing used by Matlab
s1_aligned_normalized = [shift_normalized; s1]; 
t1_aligned_normalized = [t1; shift_normalized];

figure(3)
plot(t1_aligned_normalized,s1_aligned_normalized)
hold on
plot(t2,s2)
xlabel('Time (s)')
ylabel('sum intensity (a.u.)')
legend('reference aligned','test')
title('reference aligned to test')


% after confirming cross correlation result, calculate shift in time
t0 = t1(1); % positive = y is shifter t time later than x
t_shift = t1(-lagDiff+1);


%% learning & testing cross-correlation function
close all
clc

% two signals
x = [0 0 1 5 1 -2 -3 -2 0 0 0 0]';
y = [0 0 0 0 1 5 1 -2 -3 -2 0 0]';

% timestep and index
dt = 1.2;
tx = [1 2 3 4 5 6 7 8 9 10 11 12]'*dt;
ty = [1 2 3 4 5 6 7 8 9 10 11 12]'*dt;

% visualize signals over time
figure(1)
subplot(2,1,1)
plot(tx,x)
title('reference signal')

subplot(2,1,2)
plot(ty,y)
title('test signal')
xlabel('Time (s)')

% compute cross-correlation as signal y slides over x
[corr_results,lags] = xcorr(x,y);
[~,index] = max(abs(corr_results)); % ~ does not keep val, vector of cross-correction values
lagDiff = lags(index); % lagDiff = 0, when signals are identical, even if not in time

shift = nan([-lagDiff 1],'double'); % +1 to lag diff to account for 1-based indexing used by Matlab
x_aligned = [shift; x]; 
tx_aligned = [tx; shift];

figure(2)
plot(tx,x)
hold on
plot(ty,y)
hold on
plot(tx_aligned,x_aligned,'o')
xlabel('Time (s)')
ylabel('normalized intensity (a.u.)')
legend('reference','test','reference aligned')
title('reference aligned to test, normalized signals')

t=-dt*lagDiff; % positive = y is shifter t time later than x

%% when a non-normalized correlation can be more beneficial than a normalized one
% adapted from a video by David Doran on YouTube, explaining and demo-ing normalized correlations

t = (0:100-1)/100;
s1 = cos(2*pi*1*t);
s2 = cos(2*pi*4*t);
s3 = cos(2*pi*10*t);

% the following signals contain the three sinusoids above
a = 2*s1 + 4*s2 + s3;
b = s1 + s2;

% comparing the results, it can be seen that non-normalized correlation is
% useful for identifying how strongly resent one signal is in another
corr_result_1 = sum(a.*s1)
norm_corr_result_1 = sum(a.*s1)/sqrt((sum(a.^2).*sum(s1.^2)))

corr_result_2 = sum(b.*s1)
norm_corr_result_2 = sum(b.*s1)/sqrt((sum(b.^2).*sum(s1.^2)))



