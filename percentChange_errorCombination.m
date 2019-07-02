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



% Last edit: jen, 2019 June 30
% Commit: first commit, code to double check hand calculations

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


