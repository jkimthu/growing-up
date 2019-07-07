%% Percent change and error calculations


% Output: Calculated percent change from reference growth rate, and
%         calculated errors (accounting for error combination)
%           

% Input:  Mean growth rate (i.e. G_fluc, G_low, G_ave, G_high) with
%         standard deviation between replicates


% Percent change calculations:
%           1. from G_ave
%           2. from G_Jensens
%           3. from G_low
%
%    example:
%         % change = (G_fluc - G_ave)/G_ave * 100


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



% Last edit: jen, 2019 July 7
% Commit: add part 5 to calculate for day-to-day relationships (parts 1-4 use averages)

% OK let's go!


%% Part One. Input growth rate data

% mean growth rate
G_low = 1.07;
G_ave = 2.31;
G_high = 2.86;
G_fluc = [1.93; 1.53; 1.15; 1.15]; % G_fluc [30s, 5min, 15min, 60min]

% standard deviation between replicates
err_low = 0.23;
err_ave = 0.18;
err_high = 0.14;
err_fluc = [0.16; 0.20; 0.28; 0.13]; % err_fluc [30s, 5min, 15min, 60min]

%% Part Two. Calculate G_Jensens

G_Jensens = (G_low + G_high)/2;                % check! consistent with by-hand calculation
err_Jensens = error_top(err_low,err_high);     % check! consistent with by-hand calculation

%% Part Three. Percent change calculations


% 1. from G_ave
G_fromAve = (G_fluc - G_ave)./G_ave * 100;   


% 2. from G_Jensens
G_fromJensens = (G_fluc - G_Jensens)./G_Jensens * 100;   % check! consistent with by-hand calculation


% 3. from G_low
G_fromLow = (G_fluc - G_low)./G_low * 100;     % check! consistent with by-hand calculation

%% Part Four. Error combination ("final" accounting for division step)  

% 1. from G_ave
err_fromAve = error_final(err_fluc,G_fluc,err_ave,G_ave);   % check! consistent with by-hand calculation


% 2. from G_Jensens
err_fromJensens = error_final(err_fluc,G_fluc,err_Jensens,G_Jensens);

% 3. from G_low
err_fromLow = error_final(err_fluc,G_fluc,err_low,G_low);   % check! consistent with by-hand calculation


%% Part Five. same as above except for day-by-day calculation
clear
clc

% 0. initialize growth rate data, mean (G) and standard deviation
fluc = 1; low = 2; ave = 3; high = 4;

daily_G = [
    1.8391, 1.0965, 2.4439, 2.9497; % 30 sec, 2017-11-12
    2.1229, 1.2170, 2.4692, 2.6744; % 30 sec, 2017-11-14
    1.8373, 0.8430, 2.2755, 2.9907; % 30 sec, 2018-01-04
    
    1.6728, 1.4814, 2.6296, 2.8919; % 5 min, 2017-10-10
    1.6198, 1.3525, 2.3198, 2.9588; % 5 min, 2017-11-15
    1.3032, 0.9503, 2.1744,    NaN; % 5 min, 2018-01-11
    
    1.5064, 1.3282, 2.4434, 3.1206; % 15 min, 2017-11-13
    1.3302,    NaN, 2.4605,    NaN; % 15 min, 2018-01-12
    0.9695, 0.9870, 2.0733, 2.7382; % 15 min, 2018-01-16
    0.8595, 1.0341, 2.0362, 2.7467; % 15 min, 2018-01-17 

    1.2941, 0.7944, 2.3412, 2.8273; % 60 min, 2018-01-29 
    1.1211, 0.8357, 2.1422, 2.7684; % 60 min, 2018-01-31
    1.0272, 0.9130, 2.2123, 2.7572; % 60 min, 2018-02-01

    ];

daily_err = [
    
    0.0040, 0.0024, 0.0053, 0.0067;
    0.0040, 0.0038, 0.0087, 0.0183;
    0.0077, 0.0036, 0.0092, 0.0109;
    
    0.0063, 0.0050, 0.0105, 0.0143;
    0.0075, 0.0054, 0.0098, 0.0110;
    0.0037, 0.0018, 0.0088,    NaN;
    
    0.0109, 0.0061, 0.0105, 0.0150;
    0.0077,    NaN, 0.0083,    NaN;
    0.0123, 0.0024, 0.0151, 0.0156;
    0.0123, 0.0029, 0.0141, 0.0092;
   
    0.0096, 0.0026, 0.0055, 0.0050;
    0.0129, 0.0026, 0.0063, 0.0096;
    0.0091, 0.0022, 0.0076, 0.0074;
    
    ];



% 1. calculate daily Jensens
daily_Jensens = (daily_G(:,low) + daily_G(:,high))/2;  
daily_Jensens_err = error_top(daily_err(:,low),daily_err(:,high));



% 2. percent change calculations

% from G_ave
daily_pc_fromAve = (daily_G(:,fluc) - daily_G(:,ave))./daily_G(:,ave) * 100;   

% from G_Jensens
daily_pc_fromJensens = (daily_G(:,fluc) - daily_Jensens)./daily_Jensens * 100;   

% from G_low
daily_pc_fromLow = (daily_G(:,fluc) - daily_G(:,low))./daily_G(:,low) * 100;   



% 3. percent error calculations, combing top and bottom

% from G_ave
daily_perr_fromAve = error_final(daily_err(:,fluc),daily_G(:,fluc),daily_err(:,ave),daily_G(:,ave));
daily_perr_fromAve = daily_perr_fromAve * 100;

% from G_Jensens
daily_perr_fromJensens = error_final(daily_err(:,fluc),daily_G(:,fluc),daily_Jensens_err,daily_Jensens);
daily_perr_fromJensens = daily_perr_fromJensens * 100;

% from G_low
daily_perr_fromLow = error_final(daily_err(:,fluc),daily_G(:,fluc),daily_err(:,low),daily_G(:,low)); 
daily_perr_fromLow = daily_perr_fromLow * 100;


