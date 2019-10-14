%% figure 4G - difference in fluc-adapted and single-shift growth over time after an upshift
%
%  Output: plot the difference in growth rate in real time after an upshift
%          between fluc-adapted (60 min) and single-shift growth rates as a
%          percentage of the single-shift growth rate at any given
%          timepoint



%  General strategy:
%
%         Part A. initialize folder with stored meta data
%         Part B. collect for single shift data (see figure 4C)
%         Part C. save single shift data
%         Part D. collect fluctuating data ()



%  last updated: jen, 2019 October 14

%  commit: first commit, adapted from Fig6_adaptiveGain script


% OK let's go!


%% A. Gain during upshift


clc
clear


% 0. load mean growth rate signal from upshift and downshift comparisons
cd('/Users/jen/Documents/StockerLab/Writing/manuscript 1/figures/figure5/')
load('response_singleUpshift.mat')
single_upshift_means = upshift_means_single;
single_upshift_times = upshift_times_single;
clear upshift_means_single upshift_times_single


% 0. fluctuating data, upshift
load('response_flucUpshift_2.mat','upshift_times_frep','upshift_growth_frep')
fluc_upshift_mean_60min = upshift_growth_frep;
fluc_upshift_times = upshift_times_frep;
clear replicate_mean_60min upshift_times_frep



% 1. define shift type, growth rate and time bin of interest
shiftType = 'upshift';


% 2. calculate mean growth rate between time zero and t = 30 min

% single
start_s = find(single_upshift_times == 0);
final_s = find(single_upshift_times == 60);
counter = 0;
for ss = start_s+1:final_s
    counter = counter + 1;
    growth_upshift_single(counter) = mean(single_upshift_means(start_s:ss));
end
clear counter ss

growth_upshift_single_times = single_upshift_times(start_s+1:final_s);

%figure(1)
%hold on
%plot(growth_upshift_single_times,growth_upshift_single)




% fluctuating (60 min only)
start_f = find(fluc_upshift_times == 0);
final_f = find(fluc_upshift_times == 30);
ct = 0;
for ff = start_f+1:final_f
    ct = ct + 1;
    growth_upshift_fluc(ct) = mean(fluc_upshift_mean_60min(start_f:ff));
end
clear ct ff 

growth_upshift_fluc_times = fluc_upshift_times(start_f+1:final_f);

figure(1)
hold on
plot(growth_upshift_fluc_times,growth_upshift_fluc)

clear start_s final_s start_f final_f



% 3. calculate difference between means

% i. find timepoints in single that fit within range of fluctuating data
inBoth = ismember(fluc_upshift_times,single_upshift_times);
time_both = fluc_upshift_times(inBoth==1);
overlap = time_both(time_both > 0);
clear inBoth time_both



% ii. find means from both for these timepoints
for ot = 1:length(overlap)
    
    comparable_single(ot) = growth_upshift_single(growth_upshift_single_times == overlap(ot));
    comparable_fluc(ot) = growth_upshift_fluc(growth_upshift_fluc_times == overlap(ot));
    
end

figure(1)
hold on
plot(overlap,comparable_single,'o')
hold on
plot(overlap,comparable_fluc,'o')
xlim([0 65])
xlabel('mean growth rate since shift (1/h)')
ylabel('time since shift (min)')


% iii. find means from single data extending beyond overlap
overlap_final = find(growth_upshift_single_times == overlap(ot));
comparable_single_extended = growth_upshift_single(overlap_final+1:end);
comparable_single_extended_times = growth_upshift_single_times(overlap_final+1:end);
clear ot


% iv. generate vector of 'extended' data for fluctuating condition, of
%     equal length to extended single data
extension = ones(1,length(comparable_single_extended));
comparable_fluc_extended = extension * mean(comparable_fluc(11:end));

%figure(1)
%hold on
%plot(comparable_single_extended_times,comparable_fluc_extended,'o')


% v. calculate % difference between means of measured and extended data
for comp = 1:length(comparable_fluc)
    
    sub = comparable_fluc(comp) - comparable_single(comp);
    compared_data(comp) = sub/comparable_single(comp) * 100;
    
end
clear comp sub

for ext = 1:length(comparable_fluc_extended)
    
    sb = comparable_fluc_extended(ext) - comparable_single_extended(ext);
    compared_extended(ext) = sb/comparable_single_extended(ext) * 100;
    
end
clear ext


% vi. plot comparison
compared_extended = [compared_data'; compared_extended'];
compared_extended_times = [overlap'; comparable_single_extended_times'];

figure(2)
plot(compared_extended_times,compared_extended)
xlim([7.5 60])
ylabel('percent difference from steady-state')
xlabel('time since shift (min)')


