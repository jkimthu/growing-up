%% widths

clear
clc

% Load workspace from SlidingFits.m     
load('t300_2017-01-18-Mus-length.mat');
conditions = [1 10; 11 20; 21 30; 31 40];

%%

% average cell width for each condition
for i = 1:4 %number of conditions
    
    %    Condition One    %
    width_cond = [];
    Time_cond = [];
    
    for n = conditions(i,1):conditions(i,2)
        for m = 1:length(D6{n})
            
            %  assemble all instantaneous growth rates into a single vector
            width_cond = [width_cond; D6{n}(m).MinAx(:,1)];
            
            %  assemble a corresponding timestamp vector
            vectorLength = length(D6{n}(m).MinAx(:,1));
            trackFrames = D6{n}(m).Frame;
            Time_cond = [Time_cond; T{n}(trackFrames)];
            
        end
    end
    
    %  convert all timestamps from seconds to hours
    Time_cond = Time_cond/3600;
    
    %  eliminate negative growth rates
    %Mu_cond1(Mu_cond1<0)=NaN;
    
    %  determine size of time bins
    BinsPerHour = 60;                              % multiplying by 10 gives bins of 0.1 hr
    Bins = ceil(Time_cond*BinsPerHour);            % multiplying by 200 gives time bins of 0.005 hr
    %plotUntil = floor(conditions(xy,3)*BinsPerHour);
    
    %  accumulate growth rates by bin, and calculate mean and std dev
    width_Means = accumarray(Bins,width_cond,[],@nanmean);
    width_STDs = accumarray(Bins,width_cond,[],@nanstd);
    
    
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
        clear i counter Kasten;
    end
    
    %   2. divide standard dev by square root of tracks per bin
    Mu_sems = width_STDs./sqrt(Mu_Counts');
    
    errorbar(width_Means,Mu_sems)
    %errorbar( Mu_Means(1:plotUntil),Mu_sems(1:plotUntil) )
    hold on
    grid on
    axis([0,550,1.05,1.3])
    xlabel('Time')
    ylabel('Elongation rate (1/hr)')
    %forLegend = num2str(xy);
    %legend(forLegend)
    
    clear vectorLength trackFrams Mu_Means Mu_STDs Mu_sems Bins hr dT Mu_Counts n m j;
    clear Mu_cond Time_cond plotUntil;
    
end
legend('fluc', 'low', 'ave', 'high');