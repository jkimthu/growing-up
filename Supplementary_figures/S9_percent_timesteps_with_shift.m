%% Figure S9: percent of timesteps with nutrient shift

%  Goal: quantify the fraction of imaging timesteps in each nutrient
%        timescale that contain a nutrient shift (up or down)



%  Strategy: 

%  Part 1. initialize analysis
%
%       0. initialize timescales
%       0. initialize length of timestep
%       0. initialize duration of experiment

%  Part 2. calculate percent of timesteps with shift
%       
%       1. for each timescale, determine current to calculate
%       2. loop through each second, marking places of shift
%       3. calculate percent of timesteps with shift

%  Part 3. plot



%  Last edit: jen, 2019 June 23
%  Commit: first commit, calculate fraction of timesteps with nutrient shift


%  OK let's go!

%% Part 1. initialize analysis

clear
clc

% 0. initialize timescales
timescales = [30; 300; 900; 3600]; % sec


% 0. initialize duration of experiment
duration = 10*60*60; % 10 h * 60 min/h * 60 sec/min
time = 1:duration;


% 0. initialize length of timestep
timestep = 60+57; % sec
nTimesteps = floor(duration/timestep);
bins = ceil(time/timestep)'; % bin time by timepoint


%% Part 2. calculate percent of timesteps with shift

% 1. for each timescale...
for tt = 1:length(timescales)
    
    
    % 1. determine current timescale
    period = timescales(tt);
    first_shift = ceil(period/4); % second containing first shift
    frequency_shift = period/2;
    
    
    
    % 2. loop through each second, marking places of shift
    tpt = first_shift;
    isShift = zeros(duration,1);
    while tpt < duration
        isShift(tpt,1) = 1;
        tpt = tpt + frequency_shift;
    end
    
     
    
    % 3. calculate percent of timesteps with shift
    shifts_per_bin = accumarray(bins,isShift,[],@sum);
    nShifts = shifts_per_bin(1:307);
    
    min_shifts = min(nShifts);
    max_shifts = max(nShifts);
    
    counter = 0;
    for ns = min_shifts:max_shifts
        
        counts = length(find(nShifts == ns));
        
        counter = counter + 1;
        %pt{tt}(counter) = counts/nTimesteps * 100;
        %numShifts{tt}(counter) = ns;
        pt(tt,counter) = counts/nTimesteps * 100;
        numShifts(tt,counter) = ns;
        
    end
    
end
clear bins counter counts duration first_shift frequency_shift isShift
clear max_shift min_shift ns nShifts period shifts_per_bin time timestep tpt tt


%% Part 3. plot

percents = pt;

figure(1)
bar(percents)
ylabel('Percent of timesteps')
xlabel('Number of shifts')





