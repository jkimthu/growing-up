%% rateBiomassProduction

% Goal: Calculate and plot the biovolume production rate for individual
%       cells over time.   


%  Last edit: Jen Nguyen, 2017 Oct 22



% Strategy:
%
%      0.  initialize data and binning parameters
%      1.  specify current condition of interest
%               2.  isolate all data from current condition
%               3.  isolate volume (Va), mu (mu_va) and time data from current condition
%               4.  remove data for which mu = 0, as these were the edges of tracks that never get calculated
%               5.  calculate: biovolume production rate = V(t) * mu(t) * ln(2)
%               6.  bin biovolume production rate by time
%               7.  calculate average and s.e.m. per timebin
%               8.  create a vector that converts timebin value to real time 
%               9.  plot average biovolume production rate over time
%              10.  isolate data to stabilized regions of growth
%              11.  plot distribution of biovolume production rate
%     12.  repeat for all conditions


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
% 1. specify current condition of interest
totalCond = max(dataMatrix(:,35)); % col 35 = condition value

for condition = 1:totalCond
    
    % 2. isolate all data from current condition
    interestingData = dataMatrix(dataMatrix(:,35) == condition,:);
    
    % 3. isolate volume (Va), mu (mu_va) and time data from current condition
    volumes = interestingData(:,15);        % col 15 = calculated va_vals (cubic um)
    mus = interestingData(:,18)/60;      % col 18 = calculated mu_vals
    timestamps = interestingData(:,2)/3600; % time in seconds converted to hours
    
    % 4. remove data for which mu = 0, as these were the edges of tracks that never get calculated
    trueMus = mus(mus > 0);
    trueVols = volumes(mus > 0);
    trueTimes = timestamps(mus > 0);
    
    % 5. calculate: biovolume production rate = V(t) * mu(t) * ln(2)
    bioProdRate = trueVols .* trueMus * log(2); % log(2) in matlab = ln(2)
    
    % 6. bin biovolume production rate by time
    timeBins = ceil(trueTimes*binFactor);
    binned = accumarray(timeBins,bioProdRate,[],@(x) {x});
    
    % 7. calculate average and s.e.m. per timebin
    mean_bioProdRate = cellfun(@mean,binned);
    count_BioProdRate = cellfun(@length,binned);
    std_BioProdRate = cellfun(@std,binned);
    sem_BioProdRate = std_BioProdRate./sqrt(count_BioProdRate);
    
    % 8. create a vector that converts timebin value to real time 
    rtVector = linspace(1, max(timeBins), max(timeBins));
    rtVector = hrPerBin*rtVector'; 
    
    % 9. plot average biovolume production rate over time
    figure(1)
    errorbar(rtVector,mean_bioProdRate,sem_BioProdRate)
    axis([0,10.5,0,0.3])
    hold on
    xlabel('Time (hr)')
    ylabel('biovolume production rate (cubic um/hr)')
    legend('fluc','1/1000 LB','ave','1/50 LB');
    
    % 10. isolate data to stabilized regions of growth
    minTime = meta(condition,3);  % hr
    maxTime = meta(condition,4);
    
    times_trim1 = trueTimes(trueTimes >= minTime);
    bioProdRate_trim1 = bioProdRate(trueTimes >= minTime);
    
    times_trim2 = times_trim1(times_trim1 <= maxTime);
    bioProdRate_trim2 = bioProdRate_trim1(times_trim1 <= maxTime);
    
    % 11. bin biovol production rates by time
    binAssignments = ceil(bioProdRate_trim2*100);
    binnedTrimmed = accumarray(binAssignments,bioProdRate_trim2,[],@(x) {x});
    binnedTrimmed_counts = cellfun(@length,binnedTrimmed);
    
    % iii. normalize bin quantities by total births 
    countStable = length(bioProdRate_trim2);
    pdf_biovolProdRates = binnedTrimmed_counts/countStable;
    
    % 12. plot distribution of biovolume production rate
    figure(2)
    subplot(totalCond,1,condition)
    bar(pdf_biovolProdRates,0.4)
    axis([0,100,0,0.2])
    hold on
    xlabel('biovolume production rate (cubic um/hr)')
    ylabel('pdf')
    legend(num2str(condition));
    
    % 13. repeat for all conditions
end
 




%%
    
    % ii. remove data from cell cycles that last less that 15 mins
    shorties = birthDurations_trim2(birthDurations_trim2 < 13);
    % condition 1, 26 cell cycles are shorter than 15 mins. non
    % physiological...??? the occurrence of these increases with ave mu investigate!
    
    taus = birthDurations_trim2(birthDurations_trim2 >= 1);
    Va_nots = birthVa_trim2(birthDurations_trim2 >= 1);
    final_birthTimes = birthTimes_trim2(birthDurations_trim2 >= 1);
    
    
    % iv. assign data to appropriate bin
    vaPerCC = Va_nots./taus;
    %notNum = isnan(vaPerCC);
    %sum(notNum)
  
    
    % 8. plot Vo vs tau, color different conditions differently
    figure(3)
    plot(taus,Va_nots,'o')
    hold on
    xlabel('Length of cell cycle (min)')
    ylabel('Volume at birth (cubic um)')
    legend('fluc','1/1000 LB','ave','1/50 LB');
   
    % 9. repeat for all conditions
end





