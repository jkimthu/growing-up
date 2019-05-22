%% figure 5A - in text quantifications
%
%  Output: quantifications from growth rate dynamics

%          (1) timescale of change in growth rate
%          (2) magntitude of change in growth rate


%  Both quantifications are performed between the pre-shift and post-shift growth rates
%  where,
%           i. pre-shift growth rate = mean growth rate of 11-12 min preceding shift
%          ii. post-shift growth rate is the resolved timepoint after shift


%  These quantifications are performed for the dynamic reponse to upshifts and downshifts, from:
%
%           Part A. cells grown in steady-state exposed to a single shift
%           Part B. cells grown in repeatedly shifting environments (period 15 min)
%           Part C. cells grown in repeatedly shifting environments (period 60 min)


%  last update: jen, 2019 May 3

%  OK let's go!

%% PART A. single upshift and single downshift

clear
clc

load('response_singleUpshift.mat')
load('response_singleDownshift.mat')


% single upshift

%   i. define pre and post shift growth rates
shiftTime = find(upshift_times_single == 0);
preUpshift_mu_single = mean(upshift_means_single(1:shiftTime));
postUpshift_mu_single = upshift_means_single(shiftTime+1);

%   ii. quantify percent change between pre and post shift growth rate
G_low = 1.09;
percentChange_single_up(1) = (postUpshift_mu_single - preUpshift_mu_single)/preUpshift_mu_single;
percentChange_single_up(2) = (postUpshift_mu_single - G_low)/G_low;

%   iii. quantify time step of detected increase
timescale_of_change_single_up = upshift_times_single(shiftTime+1);



% single downshift
%   i. define pre and post shift growth rates
shiftTime = find(downshift_times_single == 0);
preDownshift_mu_single = mean(downshift_means_single(1:shiftTime));
postDownshift_mu_single = downshift_means_single(shiftTime+1);

%   ii. quantify percent change between pre and post shift growth rate
G_high = 2.86;
percentChange_single_down(1) = (postDownshift_mu_single - preDownshift_mu_single)/preDownshift_mu_single;
percentChange_single_down(2) = (postDownshift_mu_single - G_high)/G_high;
percentChange_single_down(3) = (postDownshift_mu_single - G_low)/G_low;

%   iii. quantify time step of detected increase
timescale_of_change_single_down = downshift_times_single(shiftTime+1);


%% PART B. upshifts and downshifts from 15 min periods

clear
clc

load('response_flucUpshift.mat')
load('response_flucDownshift.mat')


% upshift (15 min)

%   i. define pre and post shift growth rates
upTime = 9;
preUpshift_mu_15 = mean(replicate_mean_15min(upTime-3:upTime));
postUpshift_mu_15 = replicate_mean_15min(upTime+1);

%   ii. quantify percent change between pre and post shift growth rate
percentChange_15_up(1) = (postUpshift_mu_15 - preUpshift_mu_15)/preUpshift_mu_15; % change from mean of 4 min prior to shift
percentChange_15_up(2) = (postUpshift_mu_15 - replicate_mean_15min(upTime))/replicate_mean_15min(upTime); % change from growth rate measured immediately preceding shift

%   iii. quantify time step of detected increase
shiftTime = find(upshift_times_frep == 0);
timescale_of_change_15min = upshift_times_frep(shiftTime+1);



% downshift

%   i. define pre and post shift growth rates
downTime = 3;
preDownshift_bins = [12,1,2];
preDownshift_mu_15 = mean(replicate_mean_15min(preDownshift_bins));
postDownshift_mu_15 = replicate_mean_15min(downTime+1);

%   ii. quantify percent change between pre and post shift growth rate
percentChange_15_down(1) = (postDownshift_mu_15 - preDownshift_mu_15)/preDownshift_mu_15; % change from mean of 4 min prior to shift
percentChange_15_down(2) = (postDownshift_mu_15 - replicate_mean_15min(downTime))/replicate_mean_15min(downTime); % change from growth rate measured immediately preceding shift



%% PART C. upshifts and downshifts from 60 min periods

clear
clc

load('response_flucUpshift.mat')
load('response_flucDownshift.mat')


% upshift (60 min)

%   i. define pre and post shift growth rates
upTime = 36;
preUpshift_mu_60 = mean(replicate_mean_60min(upTime-3:upTime));
postUpshift_mu_60 = replicate_mean_60min(upTime+1);

%   ii. quantify percent change between pre and post shift growth rate
percentChange_single_up(1) = (postUpshift_mu_60 - preUpshift_mu_60)/preUpshift_mu_60;
percentChange_single_up(2) = (postUpshift_mu_60 - replicate_mean_60min(upTime))/replicate_mean_60min(upTime);

%   iii. quantify time step of detected increase
shiftTime = find(upshift_times_frep == 0);
timescale_of_change_15min = upshift_times_frep(shiftTime+1);
