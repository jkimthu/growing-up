%% revealBirthVolumes

% Goal: Plot mean birth volumes over time

%       Like revealBirthSizes.m, this script looks for an evolution of cell cycle behavior.
%       Unlike it, this calculates an average of the volume (vs length or width) at birth across time.
   


%  Last edit: Jen Nguyen, 2017 Sept 30



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
load('lb-monod-2017-09-20-window5-jiggle-0p1.mat','D5','M','T');
dataMatrix = buildDM(D5,M,T);

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
    
    % i. isolate volume and time data
    allVc = interestingData(:,13); % col 13 = calculated vc_vals (cubic um)
    allVe = interestingData(:,14); % col 14 = calculated ve_vals (cubic um)
    allVa = interestingData(:,15); % col 15 = calcalated va_vals (cubic um)
    timestamps = interestingData(:,2)/3600; % time in seconds converted to hours
    
    % ii. select rows where isDrop = 1
    isDrop = interestingData(:,5);
    birthTimes = timestamps(isDrop == 1);
    birthVc = allVc(isDrop == 1);
    birthVe = allVe(isDrop == 1);
    birthVa = allVa(isDrop == 1);
    
    % iii. convert birthTimes into timebins
    timeBins = ceil(birthTimes*binFactor);                
    binnedVc = accumarray(timeBins,birthVc,[],@(x) {x});
    binnedVe = accumarray(timeBins,birthVe,[],@(x) {x});
    binnedVa = accumarray(timeBins,birthVa,[],@(x) {x});
    
    % 4.  convert bin # to absolute time
    timeVector = linspace(1, max(timeBins), max(timeBins));
    timeVector = hrPerBin*timeVector'; 
    
    
    % 5.  calculate average and s.e.m. per timebin
    meanVc = cellfun(@mean,binnedVc);
    countVc = cellfun(@length,binnedVc);
    stdVc = cellfun(@std,binnedVc);
    semVc = stdVc./sqrt(countVc);
    
    meanVe = cellfun(@mean,binnedVe);
    countVe = cellfun(@length,binnedVe);
    stdVe = cellfun(@std,binnedVe);
    semVe = stdVe./sqrt(countVe);
    
    meanVa = cellfun(@mean,binnedVa);
    countVa = cellfun(@length,binnedVa);
    stdVa = cellfun(@std,binnedVa);
    semVa = stdVa./sqrt(countVa);
    
    
    % 6.  plot 
%     figure()
%     errorbar(timeVector,meanVc,semVc,'Color',[0.25 0.25 0.9]) % dark blue
%     hold on
%     errorbar(timeVector,meanVe,semVe,'Color',[0 0.7 0.7]) % teal
%     hold on
%     errorbar(timeVector,meanVa,semVa,'Color',[1 0.6 0]) % orange
%     axis([0,10.5,0,12])
%     xlabel('Time (hr)')
%     ylabel('Birth volume + s.e.m. (cubic microns)')
%     legend('full LB, Vc','Ve','Va');
%     
    
    figure(1)
    errorbar(timeVector,meanVa,semVa)
    axis([0,10.5,0,12])
    hold on
    xlabel('Time (hr)')
    ylabel('Volume at birth + s.e.m. (cubic um)')
    legend('full LB','1/2 LB','1/4 LB','1/8 LB','1/16 LB','1/32 LB');
    
    
    
    % 7. plot pdfs from steady-state
    
    % i. isolate data from stabilized timepoints
    stableBirthVc = birthVc(birthTimes > 3);
    stableBirthVe = birthVe(birthTimes > 3);
    stableBirthVa = birthVa(birthTimes > 3);
    
    % ii. bin birth volumes
    binStable_Vc = ceil(stableBirthVc*10);
    binnedVc = accumarray(binStable_Vc,stableBirthVc,[],@(x) {x});
    binCounts_Vc = cellfun(@length,binnedVc);
    
    binStable_Ve = ceil(stableBirthVe*10);
    binnedVe = accumarray(binStable_Ve,stableBirthVe,[],@(x) {x});
    binCounts_Ve = cellfun(@length,binnedVe);
    
    binStable_Va = ceil(stableBirthVa*10);
    binnedVa = accumarray(binStable_Va,stableBirthVa,[],@(x) {x});
    binCounts_Va = cellfun(@length,binnedVa);
    
    
    % iii. normalize bin quantities by total births 
    stableVa_counts = length(stableBirthVa);
    
    normalizedVc = binCounts_Vc/stableVa_counts;
    normalizedVe = binCounts_Ve/stableVa_counts;
    normalizedVa = binCounts_Va/stableVa_counts;
    
    
    
%     figure(3)
%     subplot(3,1,1)
%     bar(normalizedVc,0.4,'FaceColor',[0.25 0.25 0.9])
%     axis([0,200,0,0.06])
%     legend('Vc')
%     hold on
%     subplot(3,1,2)
%     bar(normalizedVe,0.4,'FaceColor',[0 0.7 0.7])
%     axis([0,200,0,0.06])
%     legend('Ve')
%     hold on
%     subplot(3,1,3)
%     bar(normalizedVa,0.4,'FaceColor',[1 0.6 0])
%     axis([0,200,0,0.06])
%     legend('Va')
%     xlabel('Volume at birth (um)')
%     ylabel('pdf')
%     
    
    
    figure(4)
    subplot(totalCond,1,condition)
    bar(normalizedVa,0.4)
    axis([0,200,0,0.06])
    hold on
    xlabel('size at birth (um)')
    ylabel('pdf')
    legend(num2str(condition));
    
   
    % 8. repeat for all conditions
end

               






