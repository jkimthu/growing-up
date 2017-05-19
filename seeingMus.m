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
%%
%
%  VISUAL CHECK: plot raw data and mu over time
%

% Load workspace from SlidingFits.m     (should be Year-Mon-Day-Mus-length.m)
load('t900_2016-10-20-increasedWindow-Mus-LVVV.mat');

counter =0;
for n = 1:4%10:40
    counter = counter +1;
    m = 10;
    
    % Extracted mu
    Mu_track = M6{n}(m).Parameters_VE(:,1);
    vectorLength = length(Mu_track);
    
    % Original length data (microns)
    Ltrack2 = D6{n}(m).MajAx(7:vectorLength+6);                                  % trimmed length trajectory to match Mu
    
    % Time data (hours)
    %dT = mean(mean(diff(T)));                                              % mean time between frames (seconds)
    %Ttrack = D6{n}(m).Frame(3:Num_mu+2);                                   % original frame # in trajectory
    %timeTrack = T{n}/(60*60);
    timeTrack = T{n}/(3600);
    
    figure(1)
    
    subplot(4,1,counter)
    plot(timeTrack(7:vectorLength+6),Ltrack2,'.',timeTrack(7:vectorLength+6),Mu_track*log(2),'r');                          
    grid on;
    axis([0,9,-0.05,.45])
    xlabel('Time (hours)')
    ylabel('Cell Length (um)')
    legend('Length','Mu');


    clear Mu_track Num_mu Ltrack2 Ttrack hr;

end
 

%% CHECK FOUR: plot average growth rate over time
%
%       - generates a single plot with all conditions 
%       - options to plot standard deviation or standard error
%       - saves average mu, standard dev, s.e.m., and number of tracks per bin per condition 
%       

% Initialize
clear;
load('mopsvnc-2017-05-04-increasedWindow-Mus-LVVV.mat','D6','M6','T');

% defining conditions: col1 = first xy; col2 = final xy; col3 = time (hr) cutoff
conditions = [1 10; 11 20; 21 30; 31 40; 41 50; 51 60];
%%

for i = 1:6 %number of conditions
    
    %    Condition One    %
    mu_elongation = [];
    mu_vc = [];
    mu_ve =[];
    mu_va =[];
    Time_cond = [];
    
    for n = conditions(i,1):conditions(i,2)
        for m = 1:length(M6{n})
            
            %  assemble all instantaneous growth rates into a single vector
            mu_elongation = [mu_elongation; M6{n}(m).Parameters_L(:,1)];
            mu_vc = [mu_vc; M6{n}(m).Parameters_VC(:,1)];
            mu_ve = [mu_ve; M6{n}(m).Parameters_VE(:,1)];
            mu_va = [mu_va; M6{n}(m).Parameters_VA(:,1)];
            
            %  assemble a corresponding timestamp vector
            vectorLength = length(M6{n}(m).Parameters_L(:,1));
            trackFrames = D6{n}(m).Frame(7:vectorLength+6);
            Time_cond = [Time_cond; T{n}(trackFrames)];
            
        end
    end
    
    %  convert all timestamps from seconds to hours
    Time_cond = Time_cond/3600;
    
    %  eliminate negative growth rates
    %Mu_cond1(Mu_cond1<0)=NaN;
    
    %  determine size of time bins
    BinsPerHour = 2;                              % multiplying by 10 gives bins of 0.1 hr
    Bins = ceil(Time_cond*BinsPerHour);            % multiplying by 200 gives time bins of 0.005 hr
    %plotUntil = floor(conditions(xy,3)*BinsPerHour);
    
    %  accumulate growth rates by bin, and calculate mean and std dev
    mu_Elong_Means = accumarray(Bins,mu_elongation,[],@nanmean);
    mu_Elong_STDs = accumarray(Bins,mu_elongation,[],@nanstd);
    
    mu_VC_Means = accumarray(Bins,mu_vc,[],@nanmean);
    mu_VC_STDs = accumarray(Bins,mu_vc,[],@nanstd);
    
    mu_VE_Means = accumarray(Bins,mu_ve,[],@nanmean);
    mu_VE_STDs = accumarray(Bins,mu_ve,[],@nanstd);
    
    mu_VA_Means = accumarray(Bins,mu_va,[],@nanmean);
    mu_VA_STDs = accumarray(Bins,mu_va,[],@nanstd);
    
    
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
    
    %   2. divide standard dev by square root of tracks per bin
    mu_Elong_sems = mu_Elong_STDs./sqrt(Mu_Counts');
    mu_VC_sems = mu_VC_STDs./sqrt(Mu_Counts');
    mu_VE_sems = mu_VE_STDs./sqrt(Mu_Counts');
    mu_VA_sems = mu_VA_STDs./sqrt(Mu_Counts');
    
    
    figure(1)
    errorbar(mu_Elong_Means,mu_Elong_sems)
    hold on
    grid on
    axis([0,19,-0.1,.6])
    xlabel('Time')
    ylabel('Elongation rate (1/hr)')
    
    figure(2)
    errorbar(mu_VC_Means,mu_VC_sems)
    hold on
    grid on
    axis([0,19,-0.1,.6])
    xlabel('Time')
    ylabel('Growth rate from V_cylinder (1/hr)')
    
    figure(3)
    errorbar(mu_VE_Means,mu_VE_sems)
    hold on
    grid on
    axis([0,19,-0.1,.6])
    xlabel('Time')
    ylabel('Growth rate from V_ellipse (1/hr)')
    
    figure(4)
    errorbar(mu_VA_Means,mu_VA_sems)
    hold on
    grid on
    axis([0,19,-0.1,.6])
    xlabel('Time')
    ylabel('Growth rate from V_anupam (1/hr)')
%     
    
    clear vectorLength trackFrams Mu_Means Mu_STDs Mu_sems Bins hr dT Mu_Counts n m j;
    clear Mu_cond Time_cond plotUntil;
    
end
legend('1', '2', '3', '4', '5', '6');
%%
