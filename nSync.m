%%  nSYNC


%  Goal: Searching for synchrony in growth data.
%  Last edit: Jen Nguyen, February 5rd 2016


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

%        row     Track#    Time     Lngth     Mu      drop?      curve#     cc stage
%         1        1         t        x        u        0*         1           1
%         2        1         t        x        u        0          1           2
%         3        1         t        x        u        0          1           3
%         4        1         t        x        u        1          2           1
%         5        1         t        x        u        0          2           2
%         6        1         t        x        u        0          2           3
%         7        1         t        x        u        1          3           1
%         8        1         t        x        u        0          3           2
%         9        1         t        x        u        0          3           3
%         10       1         t        x        u        1          4           1


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
ccStage = [];                                                         

allDurations = [];
curveDurations = [];

timeSinceBirth = [];

% Select xy positions for analysis / concatenation

for n=1:2 
     
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

        
        
        %   time since birth  &  cycle duration
        isolateEvents = timeTrack.*toBool;                                 % step one of calculating cell cycle stage           
        eventTimes = isolateEvents(isolateEvents~=0);                      
        elapsedTime = diff(eventTimes); % durations in current track       % 1. find time of division/birth events
        allDurations = [allDurations; elapsedTime]; % compiled durations                                          
                                                                           % 2. calculate time elaspased between events, and
        curveDurs = zeros(trackDuration,1);                                %    store individual curve durations in single vector
        for j = 1:length(curveTrack)
            if curveTrack(j) == 0                                          % match ea time point with corresponding curve duration
                continue
            else
                curveDurs(j,1) = elapsedTime(curveTrack(j)); % for current track
            end
        end
        curveDurations = [curveDurations; curveDurs]; % collect all durations for analytical ease (ccStage)
        
        
        
        %   time since birth
        tsbPerTrack = zeros(trackDuration,1);
        
        for currentCurve = 1:fullCurves; % per individual curve
          
            currentBirthRow = find(timeTrack == eventTimes(currentCurve));
            nextBirthRow = find(timeTrack == eventTimes(currentCurve+1));
            
            currentTimes = timeTrack(currentBirthRow:nextBirthRow-1);
            tsbPerCurve = currentTimes - timeTrack(currentBirthRow);
            tsbPerTrack(currentBirthRow:nextBirthRow-1,1) = tsbPerCurve; 
       
        end
        timeSinceBirth = [timeSinceBirth; tsbPerTrack]; % compile per condition
        
        
        
    end % for m
end % for n
%muVals(muVals<0) = NaN;


%%

% drafting ccStage

%       1.  for each curve, determine duration (time)
%       2.  for each time step, determine absolute time since birth
%       3.  for each data point in vector, record as fraction:
%                
%               ccStage = time since birth / total curve duration


% YEAH GO!



% time since birth = currentTime - birthTime

timeSinceBirth = [];

tsbPerTrack = zeros(trackDuration,1);
for currentCurve = 1:fullCurves; % per individual curve
    
    
    currentBirthRow = find(Time == eventTimes(currentCurve));
    nextBirthRow = find(Time == eventTimes(currentCurve+1));
    
    currentTimes = Time(currentBirthRow:nextBirthRow-1);
    tsbPerCurve = currentTimes - Time(currentBirthRow);
    
    
    tsbPerTrack(currentBirthRow:nextBirthRow-1,1) = tsbPerCurve; % compile per condition
end
timeSinceBirth = [timeSinceBirth; tsbPerTrack];

%%
clear currentCurve currentBirthRow nextBirthRow currentTimes tsbPerCurve
clear timeSinceBirth
%%

% if fullCurves > 0
% birthTimes = eventTimes(1:fullCurves);
% 
% for c = 1:fullCurves
%     
%     trimmedCurveFinder = curveFinder(curveFinder~=0);                      % 1.  remove zeros bc accumarray can't deal
%     rowsPerCurve = accumarray(trimmedCurveFinder(:),1);                    % 2.  find frequency of each integer in curveFinder,
%                                                                            %     aka timepoints per full curve
%     birthRow = find(Time == birthTimes(c)); % row# in untrimmed set                                  
%     
%     for r = 0:rowsPerCurve(c)
%         currentTime = Time(birthRow(c) + r);
%         timeSinceBirth = currentTime - birthTimes(c);
%         tsbPerCurve(1+r,c) = timeSinceBirth;
%     end
%     
% end
%     
% else
%     continue
% end








%%


% Compile data into single matrix
dataMatrix = [trackNumber Time lengthVals muVals isDrop curveFinder];




%%
%
%   Part Two.
%   Identify birth/division events within individual trajectories
%
%

