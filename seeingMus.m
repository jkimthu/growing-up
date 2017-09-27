%%  VISUALIZING MU
%
%   For working with instantaneous growth rates after SlidingFits.m
%   
%   Goals:
%
%       1. Plot raw data and mu for selected trajectories in each condition
%               - Any qualitative differences?
%
%       2. Plot average mu (per cell cycle) vs. cell cycle #
%               - Does a steady-state emerge?
%
%       3. Average mu (with standard deviation) per timepoint in each condition 
%               - Another way of looking at steady state
%
% 

% last updated: jen, 2017 Sept 27

%%
%
%  VISUAL CHECK: plot raw data and mu over time
%

% Load workspace from SlidingFits.m    
load('t300_2017-01-16-neighbors-window5-jiggle0p4.mat','D5','M','T');

counter =0;
for n = 1:10:40
    counter = counter +1;
    m = 10;
    
    % Extracted mu
    Mu_track = M{n}(m).mu;
    vectorLength = length(Mu_track);
    
    % Original length data (microns)
    lengthTrack = D5{n}(m).MajAx(3:vectorLength+2);                                  % trimmed length trajectory to match Mu
    
    % Time data (hours)
    %dT = mean(mean(diff(T)));                                              % mean time between frames (seconds)
    %Ttrack = D6{n}(m).Frame(3:Num_mu+2);                                   % original frame # in trajectory
    %timeTrack = T{n}/(60*60);
    timeTrack = T{n}/(3600);
    
    figure(1)
    
    subplot(4,1,counter)
    plot(timeTrack(3:vectorLength+2),lengthTrack,'.',timeTrack(3:vectorLength+2),Mu_track,'r');                          
    grid on;
    %axis([0,9,-0.05,.45])
    xlabel('Time (hours)')
    ylabel('Cell Length (um)')
    legend('Length','Mu');


    clear Mu_track Num_mu lengthTrack Ttrack hr;

end
 

%% CHECK FOUR: plot average growth rate over time
%
%       - generates a single plot with all conditions 
%       - options to plot standard deviation or standard error
%       - saves average mu, standard dev, s.e.m., and number of tracks per bin per condition 
%       

% Initialize
clear;
load('t3600-2017-01-12-xy23-window5-jiggle-0p3.mat','D5','M','T');



% defining conditions: col1 = first xy; col2 = final xy; col3 = time (hr) cutoff
conditions = [1 10; 11 20; 21 30; 31 40];%; 41 50; 51 60];
%%

for i = 3:4%1:length(conditions) %number of conditions
    
    %    Condition One    %
    mu_elongation = [];
    Time_cond = [];
    
    for n = conditions(i,1):conditions(i,2)
        for m = 1:length(M{n})
            
            %  assemble all instantaneous growth rates into a single vector
            mu_elongation = [mu_elongation; M{n}(m).mu];

            
            %  assemble a corresponding timestamp vector
            %vectorLength = length(M6{n}(m).Parameters(:,1));
            vectorLength = length(M{n}(m).mu);

            trackFrames = D5{n}(m).Frame(3:vectorLength+2);
            Time_cond = [Time_cond; T{n}(trackFrames)];
            
        end
    end
    
    %  convert all timestamps from seconds to hours
    Time_cond = Time_cond/3600;
    
    %  eliminate negative growth rates
    mu_elongation(mu_elongation<0)=NaN;
    
    %  determine size of time bins
    BinsPerHour = 2;                              % multiplying by 10 gives bins of 0.1 hr
    Bins = ceil(Time_cond*BinsPerHour);            % multiplying by 200 gives time bins of 0.005 hr
    %plotUntil = floor(conditions(xy,3)*BinsPerHour);
    
    %  accumulate growth rates by bin, and calculate mean and std dev
    mu_Elong_Means = accumarray(Bins,mu_elongation,[],@nanmean);
    mu_Elong_STDs = accumarray(Bins,mu_elongation,[],@nanstd);
    

    
    %   to calculate s.e.m.
    %   1. count number of total tracks in each bin
    for j = 1:max(Bins)
        currentBin_count = find(Bins==j);
        counter = 1;
        
        for i = 2:length(currentBin_count)
            if currentBin_count(i) == currentBin_count(i-1)+1;
                counter = counter;
            else
                counter = counter + 1;
            end
        end
        Mu_Counts(j) = counter;
        clear i counter;
    end
    
%      % 5. for s.e.m. per bin
%     countsPerBin = zeros(binsPerPeriod,1);
%     for j = 1:binsPerPeriod
%         countsPerBin(j) = length(find(periodFractions_binned == j));
%     end
%     clear j
%     
%     
    %   2. divide standard dev by square root of tracks per bin
    mu_Elong_sems = mu_Elong_STDs./sqrt(Mu_Counts');

    figure(1)
    errorbar(mu_Elong_Means,mu_Elong_sems)
    hold on
    grid on

    axis([0,21,0,0.8])
    xlabel('Time')
    ylabel('Elongation rate (1/hr)')
    legend('fluc','low','ave','high');  


    clear vectorLength trackFrams Mu_Means Mu_STDs Mu_sems Bins hr dT Mu_Counts n m j;
    clear Mu_cond Time_cond plotUntil;
    
end

%% checks

% plot length and mu for individial tracks of interest

clear
load('letstry-2017-06-1-neighbors-window5-jiggle-varied.mat','D5','M','T');

%%
n=30;
data = D5{n};

% these tracks were the few left green at the end of xy1 (2017-06-12) with
% a jiggle threshold of 0.1p. do these together make sense for the gradual
% drop to a the low growth rate seen in the seeingMus plot?
interestingTracks = [49,59,75,81,87];

for i = 1:length(data)
    ID(i,1) = data(i).TrackID(1);
end

for it = 1:length(interestingTracks)

    track = find(ID == interestingTracks(it));
    
    trackLengths = D5{n}(track).MajAx;
    trackFrames = D5{n}(track).Frame;
    trackTimes = T{n}(trackFrames)/3600;
    trackMus = M{n}(track).mu;
    
    figure(it)
    plot(trackFrames, trackLengths,'o')
    hold on
    plot(trackFrames, trackLengths,'r')
    grid on
    xlim([0 202])
    title(track);
    
    hold on
    plot(trackFrames(3:end-2),trackMus,'ok');
    xlim([0 202])
    title(interestingTracks(it)); %label plot with TrackID

end

%hold on
%plot(trackFrames(3:end-2),trackMus*4,'Color',[1 0.5 0],'Marker','o'); 
%hold on
%plot(trackFrames(3:end-2),trackMus*4,'Color',[0.5 0 0.5]); 
