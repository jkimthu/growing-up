% buildDM

% goal: build a data matrix of track parameters (each column) over time
%       (rows) for all cells in a given xy position. option to specificy xy
%       positions and streamline data concatenation.

% last updated: jen, 2018 August 17

% commit: use index number of experiment to define data of interest
%         for better consistency between scripts


function [dm] = buildDM(D5,M,M_va,T,xy_start,xy_end,index,expType)
%% initialize all values
  
tn_counter = 0;
curveCounter_total = 0;
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
x_pos = [];             % 16. x coordinate of centroid
y_pos = [];             % 17. y coordinate of centroid
orig_frame = [];        % 18. orig_frame
stage_num = [];         % 19. stage_num
eccentricity = [];      % 20. eccentricity
angle = [];             % 21. angle of rotation of fit ellipse
trackNum = [];          % 22. trackNum  =  total track number (vs ID which is xy based)
condVals = [];          % 23. condVals
bioProdRate = [];       % 24. biovolProductionRate
                        % 25. correctedTime (trueTimes)

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
        
        %% biovolume production rate = V(t) * mu(t) * ln(2)
        bioProdRate_track = v_anupam .* mu_vaTrack * log(2); % log(2) in matlab = ln(2)
        bioProdRate = [bioProdRate; bioProdRate_track];
        clear bioProdRate_track v_anupam
        
    end % for m
    
    disp(['Tracks (', num2str(m), ') assembled from movie (', num2str(n), ') !'])
    
end % for n



%% lag corrected time

% if experiment numbers are designated
if nargin > 6
    
    % correct for lag in fluctuating conditions only
    if strcmp(expType,'origFluc') == 0
        
        % skip corrections if not original fluctuation experiment
        disp('no fluctuating data: true times = original times')
        trueTimes = Time;
        
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
                    %disp(strcat('fluc xy (',num2str(xy),'): corrected for lag!'))
                    
                else
                    
                    % iv. not a fluctuating condition
                    nonEdits = Time(stage_num == xy);
                    trueTimes = [trueTimes; nonEdits];
                    %disp(strcat('stable xy (',num2str(xy),'): original time is true'))
                    
                end
                
            end
            
        end
    end
    
else
    trueTimes = NaN(length(angle),1);
    
end


% compile data into single matrix
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