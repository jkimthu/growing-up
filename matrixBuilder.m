%%  matrixBuilder


%  Goal: Searching for synchrony in growth data.
%        This specific script determines cell cycle stage data and compiles
%        all data into an awesome, organized matrix
%
%  Last edit: Jen Nguyen, February 11th 2016


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

%        row      Track#    Time     Lngth      Mu       drop?      curve#    timeSinceBirth    curveDuration    cc stage
%         1         1         t        x         u         0*         1              0                3              1
%         2         1         t        x         u         0          1              1                3              2
%         3         1         t        x         u         0          1              2                3              3
%         4         1         t        x         u         1          2              0                3              1
%         5         1         t        x         u         0          2              1                3              2
%         6         1         t        x         u         0          2              2                3              3
%         7         1         t        x         u         1          3              0                3              1
%         8         1         t        x         u         0          3              1                3              2
%         9         1         t        x         u         0          3              2                3              3
%         10        1         t        x         u         1          4              0                3              1


%       where,
%                row     =  row number, obvi
%                t       =  all timepoints associated with concatinated length trajectories
%                x       =  length values from concatentated length trajectories
%                mu      =  calculated growth rates from SlidingFits.m
%                drop?   =  finding where individual cell cycles start and end, a boolean
%                curve   =  an id number for each individual cell cycle
%                stage   =  time since birth / duration of entire cycle


% Strategy:
%
%       1.  for each curve, determine duration (time)
%       2.  for each time step, determine absolute time since birth
%       3.  for each data point in vector, record as fraction:
%                
%               ccStage = time since birth / total curve duration


% Considerations:
%
%       1. Does separation between phase-sorted subpopulations occur?
%       2. Vary number of fractions. Which leads to the best separation?
%       3. If there is separation, what explains it?



% OK! Lez go!

%%
%   Initialize.

load('2015-08-10-Mu-length.mat');
D7 = D6;
M7 = M6;

monthDay = '0810';

clear D6 M6 Mu_stats;

%%
%
%   Part One.
%   Assemble the ultimate data matrix!
%


% Initialize data vectors for concatenation

trackNumber = [];
trackCounter = 1;                                                          

Time = [];
lengthVals = [];
muVals = [];

isDrop = []; 
dropThreshold = -0.75;                                                     % consider greater negatives a division event

curveFinder = [];                                                        

allDurations = [];
curveDurations = [];

timeSinceBirth = [];

% Select xy positions for analysis / concatenation

for n=1:10 
     
    for m = 1:length(M7{n})                                                % use length of growth rate data as it is
                                                                           % slightly truncated from full length track due
                                                                           % to sliding fit
                                                                           
        %   track #                                                        
        trackDuration = length(M7{n}(m).Parameters(:,1));
        Track = ones(trackDuration,1);
        trackNumber = [trackNumber; trackCounter*Track];
        trackCounter = trackCounter + 1;                                   % cumulative count of tracks in condition
        
        
        
        %   time
        timeTrack = T(3:trackDuration+2,n)/(60*60);                        % collect timestamp (hr)
        Time = [Time; timeTrack];                                          % concenate timestamp
        
        
        
        %   lengths
        lengthTrack = D7{n}(m).MajAx(3:trackDuration+2);                   % collect lengths (um)
        lengthVals = [lengthVals; lengthTrack];                            % concatenate lengths
        
        
        
        %   growth rate
        muTrack = M7{n}(m).Parameters(:,1);                                % collect elongation rates (1/hr)
        muVals = [muVals; muTrack];                                        % concatenate growth rates
        
        
        
        %   drop?
        dropTrack = diff(lengthTrack);
        toBool = dropTrack < dropThreshold;                                % converts different to a Boolean based on dropThreshold
        toBool = [0; toBool];                                              % * add zero to front, to even track lengths
        isDrop = [isDrop; toBool];
        
        
        
        %   curve finder                                                   
        fullCurves = sum(toBool) - 1;                                      
        curveTrack = zeros(length(toBool),1);
        curveCounter = 0;                                                  % finds and labels full curves within a single track
                                                                           % hint: full curves are bounded by ones
        for i = 1:length(toBool) 
            if toBool(i) == 0                                              % 1. disregard incomplete first curve
                curveTrack(i,1) = curveCounter;                            %    by starting count at 0   
            elseif (toBool(i) == 1)
                curveCounter = curveCounter + 1;                           % 2. how to disregard final incomplete segment? 
                if curveCounter <= fullCurves                              %    stop when curveCount exceeds number of fullCurves
                    curveTrack(i,1) = curveCounter;
                else                                                       % all incomplete curves are filled with 0
                    break                                                  
                end
            end
        end
        curveFinder = [curveFinder; curveTrack];
        
        
        
        %   time since birth  
        isolateEvents = timeTrack.*toBool;
        eventTimes = isolateEvents(isolateEvents~=0);                      % 1. find time of division/birth events
        
        tsbPerTrack = zeros(trackDuration,1);                              % 2. calculate: 
        durationsPerTrack = zeros(fullCurves,1);                           %     - time since birth for each timestep
                                                                           %     - final timestep is also cycle duration
        for currentCurve = 1:fullCurves; % per individual curve
            
            currentBirthRow = find(timeTrack == eventTimes(currentCurve)); % 3. store individual curve durations in single vector
            nextBirthRow = find(timeTrack == eventTimes(currentCurve+1));  
            currentTimes = timeTrack(currentBirthRow:nextBirthRow-1);      % 4. cell cycle fraction = time since birth / total curve duration
            
            tsbPerCurve = currentTimes - timeTrack(currentBirthRow);
            tsbPerTrack(currentBirthRow:nextBirthRow-1,1) = tsbPerCurve;
            
            durationsPerTrack(currentCurve) = tsbPerCurve(end); % for cell cycle durations
        end
        
        timeSinceBirth = [timeSinceBirth; tsbPerTrack]; % compile per condition
        allDurations = [allDurations; durationsPerTrack]; % compiled durations
        
        
        
        %   cycle duration
        trackBuilder = zeros(trackDuration,1);
        for j = 1:length(curveTrack)
            if curveTrack(j) == 0
                continue
            else
                trackBuilder(j,1) = durationsPerTrack(curveTrack(j)); % for current track
            end
        end
        curveDurations = [curveDurations; trackBuilder]; % collect all durations for analytical ease (ccStage)
        
        
        
        %   fraction of cell cycle
        ccFraction = timeSinceBirth./curveDurations;                       % NaN =  no full cycle
                                                                           % 0   =  start of full cycle
                                                                           % 1   =  end of full cycle
    
    end % for m
    
    % to save data matrices for each xy position
    indivDM = [trackNumber Time lengthVals muVals isDrop curveFinder timeSinceBirth curveDurations ccFraction];
    xyName = strcat('dm', monthDay, '-xy', num2str(n), '.mat');
    save(xyName, 'indivDM');
    
end % for n
%muVals(muVals<0) = NaN;


%%

% Compile data into single matrix
dataMatrix = [trackNumber Time lengthVals muVals isDrop curveFinder timeSinceBirth curveDurations ccFraction];



%%
clear currentCurve currentBirthRow nextBirthRow currentTimes tsbPerCurve
clear timeSinceBirth








