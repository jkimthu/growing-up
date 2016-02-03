%%  nSYNC


%  Goal: Searching for synchrony in growth data.
%
%  Last edit: Jen Nguyen, February 3rd 2016


% Let's first take one experiment, say 60 min fluctuations, and see if
% segregating sub-populations by growth phase leads to clear behavioral
% differences, or at least less variation within groups.


% Let's define growth phase as a specific fraction of the growth curve.

%       1. Determine duration of each individual growth curve
%               a. How does the mean and stdev of this vary between expts?
%       2. Associate each time point (in growth curve) with a fraction of cell cycle 
%       3. Bin data belonging to a desired window.
%       4. Plot the bejeezy out of these cell cycle based groupings!


% Envisioned data matrix:

%        row     Time     Lngth     Mu      drop?      curve#     cc stage
%         1        t        x        u       nan         1           1
%         2        t        x        u        0          1           2
%         3        t        x        u        0          1           3
%         4        t        x        u        1          2           1
%         5        t        x        u        0          2           2
%         6        t        x        u        0          2           3
%         7        t        x        u        1          3           1
%         8        t        x        u        0          3           2
%         9        t        x        u        0          3           3
%         10       t        x        u        1          4           1


%       where,
%                row     =  row number, obvi
%                t       =  all timepoints associated with concatinated length trajectories
%                x       =  length values from concatentated length trajectories
%                mu      =  calculated growth rates from SlidingFits.m
%                drop?   =  finding where individual cell cycles start and end, a boolean 
%                curve   =  an id number for each individual cell cycle
%                stage   =  time since birth / duration of entire cycle



% Considerations:

%       1. Does separation between phase-sorted subpopulations occur?
%       2. Vary number of fractions. Which leads to the best separation?
%       3. If there is separation, what explains it?


% OK! Lez go!


%%
%   Initialize.

load('2015-08-10-Mu-length.mat');
D7 = D6;
M7 = M6;

clear D6 M6 Mu_stats;

%%
%
%   Part One.
%   Concatenating measured length values with associated time coordinates
%
%

% Initialize data vectors for concatenation

Time = [];
lengthVals = [];
muVals = [];


% Select xy positions for analysis / concatenation

for n=1:2
                                                                           
    for m = 1:length(M7{n})                                                % use length of growth rate data as it is 
                                                                           % slightly truncated from full length track due
        trackDuration = length(M7{n}(m).Parameters(:,1));                  % to sliding fit
                                                                           
        timeTrack = T(3:trackDuration+2,n)/(60*60);                        % collect timestamp (hr)
        Time = [Time; timeTrack];                                          % concenate timestamp
       
        lengthTrack = D7{n}(m).MajAx(3:trackDuration+2);                   % collect lengths (um)
        lengthVals = [lengthVals; lengthTrack];                            % concatenate lengths
        
        muTrack = M7{n}(m).Parameters(:,1);                                % collect elongation rates (1/hr)
        muVals = [muVals; muTrack;                                         % concatenate growth rates
        
    end
end
muVals(muVals<0) = NaN;

%Tbin = ceil(Time*20);                                                     % time increments = 0.005 hr      
%Tbinned = accumarray(Tbin,lengthVals,[],@(x) {x});
%clear Num_mu Ttrack ThreeMins m n;




