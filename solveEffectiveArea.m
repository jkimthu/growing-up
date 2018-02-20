%% solving for effective area in using 2017-11-15 data

% goal: solve for A_eff, for use as a constant in other experiments that
%       do not have fluorescein calibrations at junc and xy10 

      
% strategy:
%   
%     0. initialize experiment meta data:
%               i. positions of junc and xy10 (um)
%              ii. flow rate (ul/min)
%             iii. time lag as measured in 2017-11-15
%     1. calculate distance (cm) between junction and xy10
%     2. calculate effective velocity (cm/sec)
%     3. calculate effective area (square cm) using A = Q / V_eff 


% last update: jen, 2018 Feb 20
% commit: effective area solved as 0.00026 cm^2, using 2017-11-15
%         fluorescein calibrations at junc and xy10

% OK let's go!!

%%
% 0. initialize experiment meta data: 2017-11-15

    % i. positions of junc and xy10 (um)
    x_junc = 26468.30; %y_junc = 2666.70;
    x_xy10 = -2559.40; %y_xy10 = 2124.20;

    % ii. flow rate
    flowRate_measured = 21;                 % ul/min
    Q = (flowRate_measured / 60) * 0.001;   % ul/min * min/60sec * 0.001cm3/ul

    % iii. time lag, as measured by peaks of fluorescence signal derivatives
    time_lag = 2.19; % sec

% 1. calculate distance in cm between junction and xy10
distance_horiz = (x_junc - x_xy10)/10000;   % um * cm/10000um 

% 2. calculate effective velocity
velocity_eff = distance_horiz / time_lag;   % cm / sec

% 3. calculate effective area (A = Q / V_eff)               
area_eff = Q / velocity_eff;
