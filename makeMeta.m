%% makeMeta.m

%  goal: document all "meta" data, the times and xy positions 
%        assigned to stabilized growth and specific conditions

%  last update: jen, 2017 Oct 23

%% monod: 2017-09-26 

meta_2017sep26 = [
    1 10 2 10;      % full LB
    11 20 2 10;     % 1/8 LB
    21 30 3 10;     % 1/32 LB
    31 40 4 10;     % 1/100 LB  <-- possibly contaminated with full?
    41 50 3 10;     % 1/1000 LB
    51 60 3 10;     % 1/10000 LB
];

save('meta.mat','meta_2017sep26')

%% fluc: 2017-10-10 

meta_2017oct10 = [
    1 10 2.5 6.5;   % fluc
    11 20 4 7.5;    % 1/1000 LB
    21 30 2.5 10;   % ave
    31 40 2.5 10;   % 1/50 LB
];

save('meta.mat','meta_2017oct10')

%% -- 

