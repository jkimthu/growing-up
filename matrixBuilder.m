%%  matrixBuilder


%  Goal: Assembling growth data to facilitate plotting the bejeezy out of it!
%        This script define growth phase as a specific fraction of the growth curve
%        and tables it along with all other associated data into an awesome,
%        organized matrix
%
%  Last edit: Jen Nguyen, March 12th 2016




% Envisioned data matrix:

%        row      Track#    Time     Lngth      Mu       drop?      curve#    timeSinceBirth    curveDuration    cc stage    massAdded    addedSize
%         1         1         t        x         u         0*         1              0                3              1           0           z-x  
%         2         1         t        y         u         0          1              1                3              2          y-x          z-x
%         3         1         t        z         u         0          1              2                3              3          z-x          z-x
%         4         1         t        a         u         1          2              0                3              1           0           c-a
%         5         1         t        b         u         0          2              1                3              2          b-a          c-a
%         6         1         t        c         u         0          2              2                3              3          c-a          c-a
%         7         1         t        q         u         1          3              0                3              1           0           s-q
%         8         1         t        r         u         0          3              1                3              2          r-q          s-q
%         9         1         t        s         u         0          3              2                3              3          s-q          s-q
%         10        1         t        j         u         1          4              0                0              1           0            0  



%     where,
%                  row       =   row number, obvi
%        1.        track     =   identifies track 
%        2.        t         =   all timepoints associated with concatinated length trajectories
%        3.        x         =   length values from concatentated length trajectories
%        4.        mu        =   calculated growth rates from SlidingFits.m
%        5.        drop?     =   finding where individual cell cycles start and end, a boolean
%        6.        curve     =   an id number for each individual cell cycle
%        7.        tSince    =   time since birth
%        8.        Duration  =   full duration of cell cycle pertaining to current row
%        9.        stage     =   time since birth / duration of entire cycle
%       10.        mass      =   increments of added size since time of birth
%       11.        added     =   total mass added during cell cycle pertaining to current row



% Strategy (for determining cell cycle stage):
%
%        1.  for each curve, determine duration (time)
%        2.  for each time step, determine absolute time since birth
%        3.  for each data point in vector, record as fraction:
%                
%               ccStage = time since birth / total curve duration



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

timeSinceBirth = [];
massAddedSinceBirth = [];

allDurations = [];
allDeltas = [];

curveDurations = [];
addedSize = [];


% Select xy positions for analysis / concatenation

for n = 1:10 
     
    for m = 1:length(M7{n})                                                % use length of growth rate data as it is
                                                                           % slightly truncated from full length track due
                                                                           % to sliding fit
                                                                           
        %   TRACK #                                                        
        lengthCurrentTrack = length(M7{n}(m).Parameters(:,1));
        Track = ones(lengthCurrentTrack,1);
        trackNumber = [trackNumber; trackCounter*Track];
        trackCounter = trackCounter + 1;                                   % cumulative count of tracks in condition
        
        
        
        %   TIME
        timeTrack = T(3:lengthCurrentTrack+2,n)/(60*60);                        % collect timestamp (hr)
        Time = [Time; timeTrack];                                          % concenate timestamp
        
        
        
        %   lengths
        lengthTrack = D7{n}(m).MajAx(3:lengthCurrentTrack+2);              % collect lengths (um)
        lengthVals = [lengthVals; lengthTrack];                            % concatenate lengths
        
        
        
        %   GROWTH RATE
        muTrack = M7{n}(m).Parameters(:,1);                                % collect elongation rates (1/hr)
        muVals = [muVals; muTrack];                                        % concatenate growth rates
        
        
        
        %   DROP?
        dropTrack = diff(lengthTrack);
        toBool = dropTrack < dropThreshold;                                % converts different to a Boolean based on dropThreshold
        toBool = [0; toBool];                                              % * add zero to front, to even track lengths
        isDrop = [isDrop; toBool];
        
        
        
        %   CURVE FINDER                                                  
        numberFullCurves = sum(toBool) - 1;                                      
        curveTrack = zeros(length(toBool),1);
        curveCounter = 0;                                                  % finds and labels full curves within a single track
                                                                           % hint: full curves are bounded by ones
        for i = 1:length(toBool) 
            if toBool(i) == 0                                              % 1. disregard incomplete first curve
                curveTrack(i,1) = curveCounter;                            %    by starting count at 0   
            elseif (toBool(i) == 1)
                curveCounter = curveCounter + 1;                           % 2. how to disregard final incomplete segment? 
                if curveCounter <= numberFullCurves                              %    stop when curveCount exceeds number of fullCurves
                    curveTrack(i,1) = curveCounter;
                else                                                       % all incomplete curves are filled with 0
                    break                                                  
                end
            end
        end
        %   generate column that identifies each tpt to a curve in given track
        %   i.e. count starts over with each new track
        curveFinder = [curveFinder; curveTrack];
        
        
        
        %   TIME SINCE BIRTH
        
        % 1. find timepoints with division/birth events
        % 2. calculate, for each timestep: 
        %       a)  time since birth
        %       b)  added mass since birth
        %       c)  final timestep is also cycle duration & added size 
        
        
        % Part C.
        % generate a vector of timestamps where events occur
        isolateEvents = timeTrack.*toBool;
        eventTimes = isolateEvents(isolateEvents~=0);                      
        
        % Part C.
        % preparing to collect duration and size at the end of each full cell cycle (curve)             
        durationsPerTrack = zeros(numberFullCurves,1);
        sizesPerTrack = zeros(numberFullCurves,1);
        
        % Part A & B.
        % preparing to collect incremental time and mass for all timesteps
        tsbPerTrack = zeros(lengthCurrentTrack,1);
        msbPerTrack = zeros(lengthCurrentTrack,1);
        
        % per individual curve
        %       - identify current birth event and division event (i.e. next birth)
        %       - isolate timepoints in between events for calculations specific to that curve
        %       - time since birth = isolated timepoints minus time of birth
        %       - added mass since birth = length(at timepoints) minus length at birth 
        %       - final added mass and total curve duration = values at division event
       
        for currentCurve = 1:numberFullCurves; 
            
            % identify events bounding each curve
            currentBirthRow = find(timeTrack == eventTimes(currentCurve)); 
            nextBirthRow = find(timeTrack == eventTimes(currentCurve+1));  
            currentTimes = timeTrack(currentBirthRow:nextBirthRow-1);      
            
            % incremental time
            tsbPerCurve = currentTimes - timeTrack(currentBirthRow);
            tsbPerTrack(currentBirthRow:nextBirthRow-1,1) = tsbPerCurve;
                      
            % incremental mass
            msbPerCurve = lengthTrack(currentBirthRow:nextBirthRow-1) - lengthTrack(currentBirthRow);
            msbPerTrack(currentBirthRow:nextBirthRow-1,1) = msbPerCurve;
            
            % final duration and mass
            durationsPerTrack(currentCurve) = tsbPerCurve(end);            % tsb = time since brith
            sizesPerTrack(currentCurve) = msbPerCurve(end);                % msb = mass added since birth
        end
        
        timeSinceBirth = [timeSinceBirth; tsbPerTrack]; % compiled values of time passed
        allDurations = [allDurations; durationsPerTrack]; % compiled final cell cycle durations
        
        massAddedSinceBirth = [massAddedSinceBirth; msbPerTrack]; % compiled increments of added length
        allDeltas = [allDeltas; sizesPerTrack]; % compiled final added mass per cell cycle
        
        
        %   CURVE DURATION & ADDED SIZE
        
        %   for calculations of cell cycle fraction, etc, generate:
        %           1.  a vector of total cell cycle duration
        %           2.  a vector of final mass added in that cell cycle
        %   compile individual curve durations in single vector
        perTrack_duration = zeros(lengthCurrentTrack,1);
        perTrack_size = zeros(lengthCurrentTrack,1);
        
        
        % for all timepoints in current track:           
        %       - if timepoint is part of a full curve, move on so value remains zero
        %       - if timepoint is part of a full curve, record final curve duration and added size 
        
        for j = 1:length(curveTrack) 
            if curveTrack(j) == 0 
                continue
            else
                perTrack_duration(j,1) = durationsPerTrack(curveTrack(j));
                perTrack_size(j,1) = sizesPerTrack(curveTrack(j));
            end
        end
        curveDurations = [curveDurations; perTrack_duration]; % collect all durations for analytical ease (ccStage)
        addedSize = [addedSize; perTrack_size];
        
        
        %    CELL CYCLE FRACTION
        
        %   cc fraction = time since birth / total curve duration
        ccFraction = timeSinceBirth./curveDurations;                       % NaN =  no full cycle
                                                                           % 0   =  start of full cycle
                                                                           % 1   =  end of full cycle
    
    end % for m
    
    % to save data matrices for each xy position
    %indivDM = [trackNumber Time lengthVals muVals isDrop curveFinder timeSinceBirth curveDurations ccFraction];
    %xyName = strcat('dm', monthDay, '-xy', num2str(n), '.mat');
    %save(xyName, 'indivDM');
    
end % for n
%muVals(muVals<0) = NaN;



% Compile data into single matrix
dataMatrix = [trackNumber Time lengthVals muVals isDrop curveFinder timeSinceBirth curveDurations ccFraction massAddedSinceBirth addedSize];



%%

dF0810(:,1) = allDurations; 
dF0810(:,2) = allDeltas;

dC0810(:,1) = allDurations;
dC0810(:,2) = allDeltas;

