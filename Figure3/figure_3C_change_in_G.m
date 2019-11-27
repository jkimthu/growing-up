%% figure 3C - change in G relative to steady-state references


% Output: Calculated percent change from reference growth rate, and
%         calculated errors (accounting for error combination)
%           

% Input:  Mean growth rate (i.e. G_fluc, G_low, G_ave, G_high) of each replicate


% Percent change calculations:
%           1. from G_ave
%           2. from G_Jensens
%
%    example: relative change = (G_fluc - G_ave)/G_ave * 100


% Error calculations:
%
%         Two parts: "top" accounts for subtraction step of % change calculation
%                    "final" additionally accounts for division step
%
%         error_top = sqrt( err_fluc^2 + err_ave^2 )
%
%         error_final = ( (G_fluc - G_ave)/G_ave ) * sqrt( (error_top/(G_fluc - G_ave))^2 + (err_ave/G_ave)^2 )
%
%         Both error_top and error_final are functions performing these
%         calculations. For details, see "How to combine errors" by Robin Hogan, 2006




% Last edit: jen, 2019 November 27
% Commit: G_fluc relative to G_ave and G_jensens with standard error


% OK let's go!

%% Part A. Initialize data

clear
clc

% 0. initialize meta data
load('storedMetaData.mat')
load('growthRates_monod_curve.mat')
dataIndex = find(~cellfun(@isempty,growthRates_monod_curve));
experimentCount = length(dataIndex);


% 0. initialize column IDs of each nutrient condition
fluc = 1; low = 2; ave = 3; high = 4;


% 0. initialize row IDs of each timescale in mean growth rate data
t30s = 1:3; t5 = 4:6; t15 = 7:10; t60 = 11:13;
timescales = {t30s; t5; t15; t60};


%% Part B. Access data structure to organize replicate G from each condition


% 1. compile all mean values of G
daily_G = nan(12,4);
for ii = 1:13  % 13 fluctuating experiments, 4 conditions
    
    exp = dataIndex(ii);
    expData = growthRates_monod_curve{exp};
    
    for cond = 1:4   
        daily_G(ii,cond) = expData{1,cond}.mean;  
    end
end
clear ii exp expData



% 2. calculate daily Jensens
daily_Jensens = (daily_G(:,low) + daily_G(:,high))/2;  



% 3. relative change calculations from G_ave and from G_jensens
daily_change_ave = (daily_G(:,fluc) - daily_G(:,ave))./daily_G(:,ave) * 100;   
daily_change_jensens = (daily_G(:,fluc) - daily_Jensens)./daily_Jensens * 100;   


%% Part C. Perform calculations and plot percent change with standard error

% 4. collect mean and standard error within a timescale
daily_means = zeros(4,2); % row is timescale: 30s, 5 min, 15 min, 60 min
daily_error = zeros(4,2); % column 1 = from ave; 
                          % column 2 = from Jensens;

for tt = 1:length(timescales)
    
    daily_means(tt,1) = nanmean(daily_change_ave(timescales{tt}));
    daily_means(tt,2) = nanmean(daily_change_jensens(timescales{tt}));
    
    sdev = nanstd(daily_change_ave(timescales{tt}));
    count = length(daily_change_ave(timescales{tt}));
    daily_error(tt,1) = sdev./sqrt(count);
    
    sdev_j = nanstd(daily_change_jensens(timescales{tt}));
    count_j = sum(~isnan(daily_change_jensens(timescales{tt})));
    daily_error(tt,2) = sdev_j./sqrt(count_j);
    
end



% 4. bar plot of percent change
spacing = [0.73, 0.91, 1.09, 1.27;
           1.73, 1.91, 2.09, 2.27];
       
    
       
figure(1)
bar(daily_means')
hold on
errorbar(spacing,daily_means',daily_error','.','Color',rgb('Black'))
ylabel('percent change')
xlabel('reference growth rate')
title('percent change in growth rate')





