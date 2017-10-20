%% volumePerCellCyle

% Goal: Plot the ratio of birth volume per cell cycle over time.

% Note: slower growing conditions are biased, as this script only measures
%       data at birth for complete cell cycles. Individual growth curves
%       that never end (drop) are excluded from this analysis.
%


%  Last edit: Jen Nguyen, 2017 Oct 20



% Strategy:
%
%      0.  initialize data and binning parameters
%      1.  specify current condition of interest
%               2.  isolate data from current condition
%               3.  accumulate volume at birth data by timebin
%               4.  convert bin # to absolute time
%               5.  calculate average and s.e.m. per timebin
%               6.  plot!
%      7.  repeat for all conditions


% OK! Lez go!

%%
%   Initialize.

% 0. initialze data
clc
clear

% trimmed dataset
load('lb-fluc-2017-10-10-window5-width1p4v1p7-jiggle-0p5-bigger1p8.mat','D5','M','T');
load('lb-fluc-2017-10-10-window5va-width1p4v1p7-jiggle-0p5-bigger1p8.mat','M_va');
dataMatrix = buildDM(D5,M,M_va,T);

load('meta.mat');
meta = meta_2017oct10;

% 0. initialize binning parameters
expHours = 10;          % duration of experiment in hours                      
binFactor = 4;         % bins per hour
hrPerBin = 1/binFactor; % hour fraction per bin

%%
% 1.  specify current condition of interest
totalCond = max(dataMatrix(:,35)); % col 35 = condition value

for condition = 1:totalCond
    
    % 2.  isolate data from current condition
    interestingData = dataMatrix(dataMatrix(:,35) == condition,:);
    
    % 3.  accumulate size at birth data by timebin
    
    % i. isolate volume, cell cycle duration, drop (birth event) and time data
    va_vals = interestingData(:,15);        % col 15 = calcalated va_vals (cubic um)
    durations = interestingData(:,8)/60;    % col 8 = curve (cell cycle) duration in sec converted to min
    timestamps = interestingData(:,2)/3600; % time in seconds converted to hours
    isDrop = interestingData(:,5);          % col 5 = isDrop
    
    % ii. remove data from incomplete curves, where duration == 0
    completeDurations = durations(durations > 0);
    completeVas = va_vals(durations > 0);
    completeTimes = timestamps(durations > 0);
    completeDrops = isDrop(durations > 0);  % now all drop==1 correspond to births for full curves
    
    % iii. select rows where isDrop = 1
    birthTimes = completeTimes(completeDrops == 1);
    birthVa = completeVas(completeDrops == 1);
    birthDurations = completeDurations(completeDrops ==1);
    
    
    % 3.  trim data to only account for stabilized growth
    
    % i. remove data not in stabilized region
    minTime = meta(condition,3);  % hr
    maxTime = meta(condition,4);
    
    birthVa_trim1 = birthVa(birthTimes >= minTime);
    birthDurations_trim1 = birthDurations(birthTimes >- minTime);
    birthTimes_trim1 = birthTimes(birthTimes >= minTime);
    
    birthVa_trim2 = birthVa_trim1(birthTimes_trim1 <= maxTime);
    birthDurations_trim2 = birthDurations_trim1(birthTimes_trim1 <= maxTime);
    birthTimes_trim2 = birthTimes_trim1(birthTimes_trim1 <= maxTime);
    

    % ii. remove data from cell cycles that last less that 15 mins
    shorties = birthDurations_trim2(birthDurations_trim2 < 13);
    % condition 1, 26 cell cycles are shorter than 15 mins. non
    % physiological...??? the occurrence of these increases with ave mu investigate!
    
    taus = birthDurations_trim2(birthDurations_trim2 >= 13);
    Va_nots = birthVa_trim2(birthDurations_trim2 >= 13);
    final_birthTimes = birthTimes_trim2(birthDurations_trim2 >= 13);
    
    % iii. convert birthTimes into timebins
    timeBins = ceil(final_birthTimes*binFactor);
    
    
    % iv. assign data to appropriate bin
    vaPerCC = Va_nots./taus;
    %notNum = isnan(vaPerCC);
    %sum(notNum)
    
    
    binned = accumarray(timeBins,vaPerCC,[],@(x) {x});
   
    
    % 4.  convert bin # to absolute time
    timeVector = linspace(1, max(timeBins), max(timeBins));
    timeVector = hrPerBin*timeVector'; 
    
    
    % 5.  calculate average and s.e.m. per timebin
    meanVaPerCC = cellfun(@mean,binned);
    countVaPerCC = cellfun(@length,binned);
    stdVaPerCC = cellfun(@std,binned);
    semVaPerCC = stdVaPerCC./sqrt(countVaPerCC);
    
   
    % 6.  plot 
    figure(2)
    errorbar(timeVector,meanVaPerCC,semVaPerCC)
    axis([0,10.5,0,1])
    hold on
    xlabel('Time (hr)')
    ylabel('Vo per tau (cubic um/hr)')
    legend('fluc','1/1000 LB','ave','1/50 LB');
    
    
    
    % 7. plot pdfs from steady-state
    
    % i. isolate data from stabilized timepoints
%     stableBirthVc = birthVc(birthTimes > 3);
%     stableBirthVe = birthVe(birthTimes > 3);
%    stableBirthVa = birthVa(birthTimes > 3);
    
    % ii. bin birth volumes per cc
    binStable_VoPerCC = ceil(vaPerCC*100);
    binned = accumarray(binStable_VoPerCC,vaPerCC,[],@(x) {x});
    binCounts_VoPerCC = cellfun(@length,binned);
    
    
    % iii. normalize bin quantities by total births 
    stableVoPerCC_counts = length(vaPerCC);
    normalizedVoPerCC = binCounts_VoPerCC/stableVoPerCC_counts;
    
    
    
    figure(5)
    subplot(totalCond,1,condition)
    bar(normalizedVoPerCC,0.4)
    axis([0,100,0,0.4])
    hold on
    xlabel('Vo per tau (cubic um/hr)')
    ylabel('pdf')
    legend(num2str(condition));
    
   
    % 8. repeat for all conditions
end

               






