% buildDM

% goal: build a data matrix of track parameters (each column) over time
%       (rows) for all cells in a given xy position. option to specificy xy
%       positions and streamline data concatenation.

% last updated: jen, 2018 Mar 22
% commit: corrected such that surfaceArea is actually accumulated in matrix! oops.


function [dm] = buildDM(D5,M,M_va,T,xy_start,xy_end,e)
%% initialize all values
  
tn_counter = 0;
dropThreshold = -0.75; % consider greater negatives a division event


trackID = [];           % 1. track ID, as assigned by ND2Proc_XY
Time = [];              % 2. Time
lengthVals = [];        % 3. lengthVals
muVals = [];            % 4. muVals
isDrop = [];            % 5. isDrop
curveFinder = [];       % 6. curveFinder
timeSinceBirth = [];    % 7. timeSinceBirth
curveDurations = [];    % 8. curveDurations
ccFraction = [];        % 9. ccFraction
addedLength = [];       % 10. addedLength
widthVals = [];         % 11. widthVals
vaVals = [];            % 12. vaVals
surfaceArea = [];       % 13. surfaceArea
mu_vaVals = [];         % 14. mu_vaVals
addedVA = [];           % 15. addedVA
x_pos = [];             % 16. x_pos
y_pos = [];             % 17. y_pos
orig_frame = [];        % 18. orig_frame
stage_num = [];         % 19. stage_num
eccentricity = [];      % 20. eccentricity
angle = [];             % 21. angle
trackNum = [];          % 22. trackNum  =  total track number (vs ID which is xy based)
condVals = [];          % 23. condVals
bioProdRate = [];       % 24. biovolProductionRate
% 25. correctedTime (trueTimes)

%% loop through all xy positions and all tracks for data concatenation

for n = xy_start:xy_end
    
    for m = 1:length(D5{n})
        
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
        
        %% mu_length
        muTrack = zeros(lengthCurrentTrack,1);
        measuredMus = M{n}(m).mu(:,1);                                     % collect elongation rates (1/hr)
        muTrack(3:length(measuredMus)+2) = measuredMus;
        muVals = [muVals; muTrack];                                        % concatenate growth rates
        
        %% mu_Va
        mu_vaTrack = zeros(lengthCurrentTrack,1);
        measuredMus_va = M_va{n}(m).mu_va(:,1);
        mu_vaTrack(3:length(measuredMus_va)+2) = measuredMus_va;
        mu_vaVals = [mu_vaVals; mu_vaTrack];
        
        %% drop?
        dropTrack = diff(lengthTrack);
        trackDrops = dropTrack < dropThreshold;                                % converts different to a Boolean based on dropThreshold
        trackDrops = [0; trackDrops];                                              % * add zero to front, to even track lengths
        isDrop = [isDrop; trackDrops];
        
        %% curve finder: identifying full curves for cell cycle stats
        numberFullCurves = sum(trackDrops) - 1;                                % all curves start and end with a division, isDrop = 1
        curveTrack = zeros(length(trackDrops),1);
        
        % find and number the full curves within a single track
        curveCounter = 0;
        for i = 1:length(trackDrops)
            if trackDrops(i) == 0                   % disregard incomplete first curve by starting count at 0
                curveTrack(i,1) = curveCounter;
            elseif (trackDrops(i) == 1)
                curveCounter = curveCounter + 1;        % how to disregard final incomplete segment?
                if curveCounter <= numberFullCurves     % stop when curveCount exceeds number of fullCurves
                    curveTrack(i,1) = curveCounter;
                else                                    % all incomplete curves are filled with 0
                    break
                end
            end
        end
        curveFinder = [curveFinder; curveTrack];
        clear curveCounter i
        
        
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
        
        %% time since birth, size added per cell cycle and curve duration
        
        % initialize data vectors
        tsbPerTrack = zeros(lengthCurrentTrack,1);
        durationsPerTrack = zeros(numberFullCurves,1);
        lengthPerTrack = zeros(numberFullCurves,1);
        vaPerTrack = zeros(numberFullCurves,1);
        
        durationVector = zeros(lengthCurrentTrack,1);   % a vector of cell cycle durations (completion time per cell cycle)
        lengthVector = zeros(lengthCurrentTrack,1);     % for compiling length added per cell cycle in current track
        vaVector = zeros(lengthCurrentTrack,1);         % for compiling Va added per cell cycle in current track
        
        
        % stratgey: per individual curve...
        %       i.   identify events bounding each curve
        %       ii.  isolate timepoints in between events for calculations specific to that curve
        %       iii. time since birth = isolated timepoints minus time of birth
        %       iv.  added length since birth = length(at timepoints) minus length at birth
        %       v.   added volume since birth = Va(at timepoints) minus Va at birth
        %       vi.  accumulate added mass per cell cycle in a vector representing full track
        
        for currentCurve = 1:numberFullCurves;
            
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
            clear currentBirthRow
            
            % vi.  calculate mass added in current cell cycle
            durationsPerTrack(currentCurve) = tsbPerCurve(end);            % tsb = time since brith
            lengthPerTrack(currentCurve) = lsbPerCurve(end);               % lsb = length added since birth
            vaPerTrack(currentCurve) = vsbPerCurve(end);
        end
        
        
        % TIME SINCE BIRTH
        if numberFullCurves <= 0
            noCurves = zeros(lengthCurrentTrack,1);
            timeSinceBirth = [timeSinceBirth; noCurves];
        else
            timeSinceBirth = [timeSinceBirth; tsbPerTrack];%; filler];        % compiled values of time passed since last birth event
        end
        
        
        % LENGTH or VOLUME ADDED PER CELL CYCLE
        
        % create vector of added size with a value for each cell cycle in track
        % for all timepoints in current track:
        for j = 1:length(curveTrack)
            if curveTrack(j) == 0 % if timepoint is NOT part of a full curve, move on so value remains zero
                continue
            else % if timepoint is part of a full curve, record final curve duration and added size
                durationVector(j,1) = durationsPerTrack(curveTrack(j));
                lengthVector(j,1) = lengthPerTrack(curveTrack(j));
                vaVector(j,1) = vaPerTrack(curveTrack(j));
            end
        end
        clear durationsPerTrack lengthPerTrack curveTrack j
        
        
        % CURVE DURATION (total time of current cell cycle)
        curveDurations = [curveDurations; durationVector];
        clear durationVector
        
        %% cell cycle fraction
        
        %   cc fraction = time since birth / total curve duration            
        ccFraction = timeSinceBirth./curveDurations;                       % NaN =  no full cycle                                                          % 0   =  start of full cycle
                                                                           % 1   =  end of full cycle
    
        %% added length (total added length in current cell cycle)
        addedLength = [addedLength; lengthVector];
        clear lengthVector
        
        %% addedVa = volume added per cell cycle
        addedVA = [addedVA; vaVector];
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
        
        %% biovolume production rate = V(t) * mu(t) * ln(2)
        bioProdRate_track = v_anupam .* mu_vaTrack * log(2); % log(2) in matlab = ln(2)
        bioProdRate = [bioProdRate; bioProdRate_track];
        clear bioProdRate_track v_anupam
        
    end % for m
    
    disp(['Tracks (', num2str(m), ') assembled from movie (', num2str(n), ') !'])
    
end % for n



%% lag corrected time

%
if nargin > 6
    
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
        [lagTimes,~] = calculateLag(e);
        
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
                disp(strcat('fluc xy (',num2str(xy),'): corrected for lag!'))
                
            else
                
                % iv. not a fluctuating condition
                nonEdits = Time(stage_num == xy);
                trueTimes = [trueTimes; nonEdits];
                disp(strcat('stable xy (',num2str(xy),'): original time is true'))
                
            end
            
        end
        
    end
    
else
    trueTimes = NaN(length(angle),1);
end



%% Compile data into single matrix
dm = [trackID Time lengthVals muVals isDrop curveFinder timeSinceBirth curveDurations ccFraction addedLength widthVals vaVals surfaceArea mu_vaVals addedVA x_pos y_pos orig_frame stage_num eccentricity angle trackNum condVals bioProdRate trueTimes];
% 1. track ID, as assigned by ND2Proc_XY
% 2. Time
% 3. lengthVals
% 4. muVals
% 5. isDrop
% 6. curveFinder
% 7. timeSinceBirth
% 8. curveDurations
% 9. ccFraction
% 10. addedLength
% 11. widthVals  
% 12. vaVals
% 13. surfaceArea
% 14. mu_vaVals
% 15. addedVA
% 16. x_pos
% 17. y_pos
% 18. orig_frame
% 19. stage_num
% 20. eccentricity
% 21. angle
% 22. trackNum  =  total track number (vs ID which is xy based)
% 23. condVals
% 24. biovolProductionRate
% 25. correctedTime (trueTimes)


end