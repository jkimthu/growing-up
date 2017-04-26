%%  matrixBuilder


%  Goal: Assembling growth data to facilitate plotting the bejeezy out of it!
%        This script define growth phase as a specific fraction of the growth curve
%        and tables it along with all other associated data into an awesome,
%        organized matrix
%
%  Last edit: Jen Nguyen, April 12 2017




% Envisioned data matrix:

%        row      Track#    Time     Lngth      Mu       drop?      curve#    timeSinceBirth    curveDuration    cc stage    lngthAdded    addedLngth    Width    V_cyl   V_elpse  mu_vc    mu_ve  Condition o
%         1         1         t        x         u         0*         1              0                3              1           0            z-x          wx                                          1  
%         2         1         t        y         u         0          1              1                3              2          y-x           z-x          wy      v                                   1
%         3         1         t        z         u         0          1              2                3              3          z-x           z-x          wz      v                                   1
%         4         1         t        a         u         1          2              0                3              1           0            c-a          wa      v                                   1 
%         5         1         t        b         u         0          2              1                3              2          b-a           c-a          wb      v                                   1
%         6         1         t        c         u         0          2              2                3              3          c-a           c-a          wc      v                                   1
%         7         1         t        q         u         1          3              0                3              1           0            s-q          wq      v                                   1
%         8         1         t        r         u         0          3              1                3              2          r-q           s-q          wr      v                                   1
%         9         1         t        s         u         0          3              2                3              3          s-q           s-q          ws      v                                   1
%         10        1         t        j         u         1          4              0                0              1           0             0           wj      v                                   1  



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
%       10.        lAdded    =   increments of added length since time of birth
%       11.        addedL    =   total length added during cell cycle pertaining to current row
%       12.        width     =   width values
%       13.        v_cyl     =   volume approximated as a cylinder
%       14.        v_elspe   =   volume approximated as an ellipse
%       15.        mu_vc     =   rate of doubling vol as cylinder
%       16.        mu_ve     =   rate of doubling vol as ellipse
%       17.        addedVC   =   volume (cylindrical) added per cell cycle
%       18.        addedVE   =   volume (ellipsoidal) added per cell cycle
%       19.        condition =   1 fluc; 2 low; 3 ave; 4 high

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

load('t900_2016-10-20-increasedWindow-Mus-LV.mat');
D7 = D6;
M7 = M6;

clear D6 M6 rejectsD;


%%
%   Part One.
%   Assemble the ultimate data matrix!
%


% Initialize data vectors for concatenation

condVals = [];

trackNumber = [];
trackCounter = 1;                                                          

Time = [];

lengthVals = [];
widthVals = [];
vcVals = [];
veVals = [];

muVals = [];
mu_vcVals = [];
mu_veVals = [];

isDrop = []; 
dropThreshold = -0.75;                                                     % consider greater negatives a division event

curveFinder = [];                                                        

timeSinceBirth = [];
lengthAddedSinceBirth = [];

allDurations = [];
allDeltas = [];
allTimestamps = [];

birthSizes = [];
birthTimes = [];

curveDurations = [];
addedLength = [];
addedVC = [];
addedVE = [];

%%
% Select xy positions for analysis / concatenation

for n = 1:40
     
    for m = 1:length(M7{n})                                                % use length of growth rate data as it is
                                                                           % slightly truncated from full length track due
                                                                           % to sliding fit
                                                                           
        %   TRACK #                                                        
        lengthCurrentTrack = length(M7{n}(m).Parameters_L(:,1));
        Track = ones(lengthCurrentTrack,1);
        trackNumber = [trackNumber; trackCounter*Track];
        trackCounter = trackCounter + 1;                                   % cumulative count of tracks in condition
        
        
        
        %   TIME
        %timeTrack = T(3:lengthCurrentTrack+2,n)/(60*60);                  % collect timestamp (hr)
        timeTrack = T{n}(7:lengthCurrentTrack+6)./(3600);                  % data format, if all ND2s were processed individually
        Time = [Time; timeTrack];                                          % concat=enate timestamp
        
        
        
        %   lengths
        lengthTrack = D7{n}(m).MajAx(7:lengthCurrentTrack+6);              % collect lengths (um)
        lengthVals = [lengthVals; lengthTrack];                            % concatenate lengths
        
        
        %   widths
        widthTrack = D7{n}(m).MinAx(7:lengthCurrentTrack+6);               % collect widths (um)
        widthVals = [widthVals; widthTrack];                               % concatenate widths
        
        
        %   ELONGATION RATE
        muTrack = M7{n}(m).Parameters_L(:,1);                                % collect elongation rates (1/hr)
        muVals = [muVals; muTrack];                                        % concatenate growth rates
        
        
        %   VOLUME
        v_cylinder = pi * lengthTrack .* (widthTrack/2).^2;                % approx. volume as a cylinder
        v_ellipse = 4/3 * pi * lengthTrack/2 .* (widthTrack/2.^2);         % approx. volume as an ellipse
        vcVals = [vcVals; v_cylinder];                                     % concatenate values
        veVals = [veVals; v_ellipse];
        
        
        %   GROWTH RATE (VOLUME)
        mu_vcTrack = M7{n}(m).Parameters_VC(:,1);                          % as approximated by a cylinder
        mu_vcVals = [mu_vcVals; mu_vcTrack];                               % see slidingFits
        
        mu_veTrack = M7{n}(m).Parameters_VE(:,1);                          % as approximated by an ellipse
        mu_veVals = [mu_veVals; mu_veTrack];                               % see slidingFits
        
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
        lengthPerTrack = zeros(numberFullCurves,1);
        vcPerTrack = zeros(numberFullCurves,1);
        vePerTrack = zeros(numberFullCurves,1);
        
        % Part A & B.
        % preparing to collect incremental time and mass for all timesteps
        tsbPerTrack = zeros(lengthCurrentTrack,1);
        lsbPerTrack = zeros(lengthCurrentTrack,1);
        vcsbPerTrack = zeros(lengthCurrentTrack,1);
        vesbPerTrack = zeros(lengthCurrentTrack,1);
        
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
                      
            % incremental length
            lsbPerCurve = lengthTrack(currentBirthRow:nextBirthRow-1) - lengthTrack(currentBirthRow);
            lsbPerTrack(currentBirthRow:nextBirthRow-1,1) = lsbPerCurve;
            
            % incremental volume (cylindrical)
            vcsbPerCurve = v_cylinder(currentBirthRow:nextBirthRow-1) - v_cylinder(currentBirthRow);
            vcsbPerTrack(currentBirthRow:nextBirthRow-1,1) = vcsbPerCurve;
            
            % incremental volume (ellipsoidal)
            vesbPerCurve = v_ellipse(currentBirthRow:nextBirthRow-1) - v_ellipse(currentBirthRow);
            vesbPerTrack(currentBirthRow:nextBirthRow-1,1) = vesbPerCurve;
            
            % final duration and mass
            durationsPerTrack(currentCurve) = tsbPerCurve(end);            % tsb = time since brith
            lengthPerTrack(currentCurve) = lsbPerCurve(end);               % lsb = length added since birth
            vcPerTrack(currentCurve) = vcsbPerCurve(end);                  % vcsb = volume added since birth
            vePerTrack(currentCurve) = vesbPerCurve(end);
            
        end
        
        
        %   SPIN-OFF DATA COMPILATIONS (two groups):
        %       
        %       1. "all" group:
        %               - all cell cycle durations
        %               - all added masses since birth
        %               - all corresponding timestamps per cell cycle (end)
        %
        %       2. "birth" group
        %               - birth lengths
        %               - birth timestamps
        %
        
        % "ALL" group
        timeSinceBirth = [timeSinceBirth; tsbPerTrack]; % compiled values of time passed
        allDurations = [allDurations; durationsPerTrack]; % compiled final cell cycle durations
        
        lengthAddedSinceBirth = [lengthAddedSinceBirth; lsbPerTrack]; % compiled increments of added length
        allDeltas = [allDeltas; lengthPerTrack]; % compiled final added mass per cell cycle
        
        if length(eventTimes) > 1
            allTimestamps = [allTimestamps; eventTimes(2:end)]; % compiled timestamps for FULL cell cycles
        end
        
        % "BIRTH" group
        birthLengths = lengthTrack.*toBool; % isolate lengths at birth
        birthRows = find(birthLengths > 0); % when drop=1, then that is the start of new curve
        sizeAtBirth = birthLengths(birthRows);
        birthSizes = [birthSizes; sizeAtBirth];
        
        timeAtBirth = timeTrack(birthRows);
        birthTimes = [birthTimes; timeAtBirth];
        

        
        %   CURVE DURATION & ADDED LENGTH
        
        %   for calculations of cell cycle fraction, etc, generate:
        %           1.  a vector of total cell cycle duration
        %           2.  a vector of final length added in that cell cycle
        %   compile individual curve durations in single vector
        perTrack_duration = zeros(lengthCurrentTrack,1);
        perTrack_length = zeros(lengthCurrentTrack,1);
        perTrack_vc = zeros(lengthCurrentTrack,1);
        perTrack_ve = zeros(lengthCurrentTrack,1);
        
        
        % for all timepoints in current track:           
        %       - if timepoint is part of a full curve, move on so value remains zero
        %       - if timepoint is part of a full curve, record final curve duration and added size 
        
        for j = 1:length(curveTrack) 
            if curveTrack(j) == 0 
                continue
            else
                perTrack_duration(j,1) = durationsPerTrack(curveTrack(j));
                perTrack_length(j,1) = lengthPerTrack(curveTrack(j));
                perTrack_vc(j,1) = vcPerTrack(curveTrack(j));
                perTrack_ve(j,1) = vePerTrack(curveTrack(j));
            end
        end
        curveDurations = [curveDurations; perTrack_duration]; % collect all durations for analytical ease (ccStage)
        addedLength = [addedLength; perTrack_length];
        addedVC = [addedVC; perTrack_vc];
        addedVE = [addedVE; perTrack_ve];
        
        
        %    CELL CYCLE FRACTION
        
        %   cc fraction = time since birth / total curve duration
        ccFraction = timeSinceBirth./curveDurations;                       % NaN =  no full cycle
                                                                           % 0   =  start of full cycle
                                                                           % 1   =  end of full cycle
    
                                                                           
        %   CONDITION
        if n >= 1 && n <= 10
            condition = 1;
        end
        
        if n >= 11 && n <= 20
            condition = 2;
        end
        
        if n >= 21 && n <= 30
            condition = 3;
        end
        
        if n >= 31 && n <= 40
            condition = 4;
        end
        
        condTrack = ones(lengthCurrentTrack,1)*condition;
        condVals = [condVals; condTrack];
    end % for m
    
    disp(['Track ', num2str(m), ' of ', num2str(length(M7{n})), ' from xy ', num2str(n), ' complete!'])
    
    % to save data matrices for each xy position
    %indivDM = [trackNumber Time lengthVals muVals isDrop curveFinder timeSinceBirth curveDurations ccFraction];
    %xyName = strcat('dm', monthDay, '-xy', num2str(n), '.mat');
    %save(xyName, 'indivDM');
    
end % for n



% Compile data into single matrix
dataMatrix = [trackNumber Time lengthVals muVals isDrop curveFinder timeSinceBirth curveDurations ccFraction lengthAddedSinceBirth addedLength widthVals vcVals veVals mu_vcVals mu_veVals addedVC addedVE condVals];

%%

% Naming convention for data matrices of HCF experiments:

% dmMMDD-cond.mat

%      where,
%              dm  =  dataMatrix                  (see matrixBuilder.m)
%              MM  =  month of experimental date
%              DD  =  day of experimental date
%       condition  =  experimental condition      (fluc or const)


%dm1010_high = dataMatrix;
save('dm-t900-2016-10-20.mat', 'dataMatrix');


%%
% Naming convention for "BIRTH" group


spinOffs = struct('allDurations', allDurations, 'allDeltas', allDeltas, 'allTimestamps', allTimestamps, 'birthTimes', birthTimes, 'birthSizes', birthSizes);

save('dF_2017-01-18.mat', 'spinOffs');