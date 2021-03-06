% buildDM

% goal: build a data matrix of track parameters (each column) over time
%       (rows) for all cells in a given xy position. option to specificy xy
%       positions and streamline data concatenation.

% last updated: jen, 2019 Oct 17

% commit: edit to track total tracks assembled per condition


function [dm] = buildDM(D5,T,xy_start,xy_end,index,expType)
%% initialize all values
  
m_counter = 0;
tn_counter = 0;
curveCounter_total = 0;
dropThreshold = -0.75; % consider greater negatives a division event


trackID = [];           % 1. track ID, as assigned by ND2Proc_XY
Time = [];              % 2. Time
lengthVals = [];        % 3. lengthVals
isDrop = [];            % 4. isDrop
curveFinder = [];       % 5. curveFinder
timeSinceBirth = [];    % 6. timeSinceBirth
curveDurations = [];    % 7. curveDurations
ccFraction = [];        % 8. ccFraction
addedLength = [];       % 9. addedLength
widthVals = [];         % 10. widthVals
vaVals = [];            % 11. vaVals
surfaceArea = [];       % 12. surfaceArea
addedVA = [];           % 13. addedVA
x_pos = [];             % 14. x coordinate of centroid
y_pos = [];             % 15. y coordinate of centroid
orig_frame = [];        % 16. orig_frame
stage_num = [];         % 17. stage_num
eccentricity = [];      % 18. eccentricity
angle = [];             % 19. angle of rotation of fit ellipse
trackNum = [];          % 20. trackNum  =  total track number (vs ID which is xy based)
condVals = [];          % 21. condVals
                        % 22. correctedTime (trueTimes)

%% loop through all xy positions and all tracks for data concatenation

for n = xy_start:xy_end % n = each inidividual xy position from experiment (movie)
    
    for m = 1:length(D5{n}) % m = each individual cell track from current movie
        
        %% track ID
        lengthCurrentTrack = length(D5{n}(m).TrackID);
        Track = D5{n}(m).TrackID;
        trackID = [trackID; Track];
        
        %% track number
        tn_counter = tn_counter + 1;
        tnTrack = ones(length(Track),1)*tn_counter;
        trackNum = [trackNum; tnTrack];
        
        %% frame number in original image
        frameTrack = D5{n}(m).Frame;
        %frameTrack = D5{n}(m).Frame(3:lengthCurrentTrack+2); % trimming to fit mu
        orig_frame = [orig_frame; frameTrack];
        
        %% time
        %timeTrack = T(3:lengthCurrentTrack+2,n)/(60*60);                  % collect timestamp (hr)
        timeTrack = T{n}(frameTrack(1):lengthCurrentTrack+frameTrack(1)-1);%(7:lengthCurrentTrack+6)./(3600);                                                         % data format, if all ND2s were processed individually
        Time = [Time; timeTrack];                                          %concat=enate timestamp
        
        %% lengths
        lengthTrack = D5{n}(m).MajAx;%(7:lengthCurrentTrack+6);              % collect lengths (um)
        lengthVals = [lengthVals; lengthTrack];                            % concatenate lengths
        

        
        %% drop?
        dropTrack = diff(lengthTrack);
        trackDrops = dropTrack < dropThreshold;                                % converts different to a Boolean based on dropThreshold
        trackDrops = [0; trackDrops];                                              % * add zero to front, to even track lengths
        isDrop = [isDrop; trackDrops];
        
        
        %% widths
        widthTrack = D5{n}(m).MinAx;%(7:lengthCurrentTrack+6);               % collect widths (um)
        widthVals = [widthVals; widthTrack];                               % concatenate widths
        
        %% volume as a cylinder with hemispherical caps
        
        %v_cylinder = pi * lengthTrack .* (widthTrack/2).^2;                % approx. volume as a cylinder = pi * r^2 * h
        %v_ellipse = 4/3 * pi * lengthTrack/2 .* (widthTrack/2).^2;         % approx. volume as an ellipse
        vol_smallCylinder = pi * (widthTrack/2).^2 .* (lengthTrack - widthTrack);
        vol_sphere = 4/3 * pi * (widthTrack/2).^3;
        v_anupam = vol_smallCylinder + vol_sphere;                         % approx. volume as cylinder with spherical caps
        
        vaVals = [vaVals; v_anupam];
        
        clear v_ellipse v_cylinder vol_sphere vol_smallCylinder
        
        %% surface area
        sa_rectangle = (lengthTrack - widthTrack) .* widthTrack;
        sa_sphere = 4 * pi .* (widthTrack/2);
        sa_total = sa_rectangle + sa_sphere;
        
        surfaceArea = [surfaceArea; sa_total];
        
        
         %% cell cycle stats:
         %  curve finder, time since birth, size added per cell cycle and
         %  curve duration (inter-division time)
         
        numberFullCurves = sum(trackDrops) - 1;    % all curves start and end with a division, isDrop = 1
        curveTrack = zeros(length(trackDrops),1);
        
        % initialize data vectors
        tsbPerTrack = zeros(lengthCurrentTrack,1);
        curveDurationVector = zeros(lengthCurrentTrack,1);   % a vector of cell cycle durations (completion time per cell cycle)
        lengthAddedVector = zeros(lengthCurrentTrack,1);     % for compiling length added per cell cycle in current track
        volAddedVector = zeros(lengthCurrentTrack,1);         % for compiling Va added per cell cycle in current track
        
        
        if numberFullCurves > 0
            
            % stratgey: per individual curve...
            %       i.   identify events bounding each curve
            %       ii.  isolate timepoints in between events for calculations specific to that curve
            %       iii. time since birth = isolated timepoints minus time of birth
            %       iv.  added length since birth = length(at timepoints) minus length at birth
            %       v.   added volume since birth = Va(at timepoints) minus Va at birth
            %       vi.  accumulate added mass per cell cycle in a vector representing full track
            
            for currentCurve = 1:numberFullCurves
                
                curveCounter_total = curveCounter_total + 1;
                
                % i. identify events bounding each curve
                isolateEvents = timeTrack.*trackDrops;
                eventTimes = isolateEvents(isolateEvents~=0);
                clear isolateEvents
                
                % ii. isolate timepoints in between events for calculations specific to that curve
                currentBirthRow = find(timeTrack == eventTimes(currentCurve)); % row in which current curve begins
                nextBirthRow = find(timeTrack == eventTimes(currentCurve+1));
                currentTimes = timeTrack(currentBirthRow:nextBirthRow-1);
                
                % iii. time since birth = isolated timepoints minus time of birth
                tsbPerCurve = currentTimes - timeTrack(currentBirthRow);       % time since birth, per timestep of curve
                tsbPerTrack(currentBirthRow:nextBirthRow-1,1) = tsbPerCurve;
                
                % iv. added length since birth = length(at timepoints) minus length at birth
                lsbPerCurve = lengthTrack(currentBirthRow:nextBirthRow-1) - lengthTrack(currentBirthRow);
                lsbPerTrack(currentBirthRow:nextBirthRow-1,1) = lsbPerCurve;
                
                % v. added volume since birth (Va, volume approximated as a cylinder with spherical caps)
                vsbPerCurve = v_anupam(currentBirthRow:nextBirthRow-1) - v_anupam(currentBirthRow);
                vsbPerTrack(currentBirthRow:nextBirthRow-1,1) = vsbPerCurve;
                
                % vi.  store cell cycle stats into appropriate vectors
                curveTrack(currentBirthRow:nextBirthRow-1,1) = curveCounter_total;
                curveDurationVector(currentBirthRow:nextBirthRow-1,1) = tsbPerCurve(end);
                lengthAddedVector(currentBirthRow:nextBirthRow-1,1) = lsbPerCurve(end);
                volAddedVector(currentBirthRow:nextBirthRow-1,1) = vsbPerCurve(end);
                
            end
            
        end
        
        
        % TIME SINCE BIRTH

          timeSinceBirth = [timeSinceBirth; tsbPerTrack];        % compiled values of time passed since last birth event

        
        % CURVE DURATION (total time of current cell cycle)
        curveFinder = [curveFinder; curveTrack];
        curveDurations = [curveDurations; curveDurationVector];
        clear durationVector
        
        %% cell cycle fraction
        
        %   cc fraction = time since birth / total curve duration            
        ccFraction = timeSinceBirth./curveDurations;                       % NaN =  no full cycle                                                          % 0   =  start of full cycle
                                                                           % 1   =  end of full cycle
    
        %% added length (total added length in current cell cycle)
        addedLength = [addedLength; lengthAddedVector];
        clear lengthVector
        
        %% addedVa = volume added per cell cycle
        addedVA = [addedVA; volAddedVector];
        clear vaVector
        
        
        %% x positions in original image
        xTrack = D5{n}(m).X;%(7:lengthCurrentTrack+6);
        x_pos = [x_pos; xTrack];
        clear xTrack
        
        %% y positions in original image
        yTrack = D5{n}(m).Y;%(7:lengthCurrentTrack+6);
        y_pos = [y_pos; yTrack];
        clear yTrack
        
        %% trim stage in dataTrimmer
        trimTrack = ones(length(Track),1)*n;
        stage_num = [stage_num; trimTrack];
        clear Track trimTrack
        
        %% eccentricity of ellipses used in particle tracking
        eccTrack = D5{n}(m).Ecc;%(7:lengthCurrentTrack+6);
        eccentricity = [eccentricity; eccTrack];
        clear eccTrack
        
        %% angle of ellipses used in particle tracking
        angTrack = D5{n}(m).Ang;%(7:lengthCurrentTrack+6);
        angle = [angle; angTrack];
        clear angTrack
        
        %% CONDITION
        % assign condition based on xy number
        condition = ceil(n/10);
        
        % label each row with a condition #
        condTrack = ones(lengthCurrentTrack,1)*condition;
        condVals = [condVals; condTrack];
        clear condTrack
        
        
    end % for m
    
    disp(['Tracks (', num2str(m), ') assembled from movie (', num2str(n), ') !'])
    m_counter = m_counter + m;
    
end % for n
disp(['Total tracks in condition (',num2str(m_counter),')'])


%% lag corrected time


% correct for lag in fluctuating conditions only
if strcmp(expType,'monod') == 1
    
    % skip corrections if not original fluctuation experiment
    disp('no fluctuating data: true times = original times')
    %         trueTimes = Time;
    trueTimes = NaN(length(angle),1);
    
else
    
    fluc_xys = 1:10;
    compiled_xys = xy_start:xy_end;
    
    trueTimes = [];
    
    % in the case that compiled data matrix contains fluctuating data,
    % subtract lag time from timestamps derived from corresponding xy position
    
    if isempty( intersect(compiled_xys,fluc_xys) )
        
        % only stable environments, skip corrections
        disp('no fluctuating data: true times = original times')
        trueTimes = Time;
        
    else
        
        % calculate lag times for corrections
        [lagTimes,~] = calculateLag(index);
        
        % accumulate "true" times for all assembled conditions
        % "true" can be corrected fluctuating timestamps, or original stable timestamps
        for xy = xy_start:xy_end
            
            if ~isempty( intersect(xy,fluc_xys) )
                
                % i. identify position and corresponding lag time
                currentLag = lagTimes(xy);
                
                % ii. subtract lag time from timestamp, to re-align cell experience (xy) with generated signal (junc)
                edits = Time(stage_num == xy) - currentLag;
                
                % iii. re-assign
                trueTimes = [trueTimes; edits];
                
                
            else
                
                % iv. not a fluctuating condition
                nonEdits = Time(stage_num == xy);
                trueTimes = [trueTimes; nonEdits];
                
                
            end
            
        end
        
    end
end



% compile data into single matrix
dm = [trackID Time lengthVals isDrop curveFinder timeSinceBirth curveDurations ccFraction addedLength widthVals vaVals surfaceArea addedVA x_pos y_pos orig_frame stage_num eccentricity angle trackNum condVals trueTimes];
% 1. track ID, as assigned by ND2Proc_XY
% 2. Time
% 3. lengthVals
% 4. isDrop
% 5. curveFinder
% 6. timeSinceBirth
% 7. curveDurations
% 8. ccFraction
% 9. addedLength
% 10. widthVals  
% 11. vaVals
% 12. surfaceArea
% 13. addedVA
% 14. x_pos
% 15. y_pos
% 16. orig_frame
% 17. stage_num
% 18. eccentricity
% 19. angle
% 20. trackNum  =  total track number (vs ID which is xy based)
% 21. condVals
% 22. correctedTime (trueTimes)


end