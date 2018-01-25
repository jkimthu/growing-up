% buildDM

% adapted from matrixBuilder, but prevents need to save data matrices.
% ideal for smaller inputs that take less time to process.

% last updated: jen, 2018 Jan 25
% commit: edit function to receive inputs for which xy positions (start and end n values) to loop through


function [dm] = buildDM(D5,M,M_va,T,xy_start,xy_end)
%% initialize all values

condVals = [];     % col 28

trackID = [];      % col 1
Time = [];         % col 2
lengthVals = [];   % col 3
trackNum = [];     % col 27, total track number for entire experiment
tn_counter = 0;

widthVals = [];   % col 11
vcVals = [];      % col 12
veVals = [];      % col 13
vaVals = [];      % col 14

muVals = [];      % col 4
mu_vcVals = [];
mu_veVals = [];
mu_vaVals = [];   % col 17

bioProdRate = []; % col 29

dropThreshold = -0.75;  % consider greater negatives a division event
isDrop = [];            % col 5
                                                   
curveFinder = [];     % col 6                                                       
timeSinceBirth = [];  % col 7

curveDurations = [];  % col 8
addedLength = [];     % col 10
addedVC = [];
addedVE = [];
addedVA = [];         % col 20, added Va per cell cycle (same total volume added repeated)

x_pos = [];       % col 21
y_pos = [];       % col 22
orig_frame = [];  % col 23
stage_num = [];   % col 24
eccentricity = [];% col 25
angle = [];       % col 26



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
        
        %% mu
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
            if trackDrops(i) == 0                                              % 1. disregard incomplete first curve
                curveTrack(i,1) = curveCounter;                            %    by starting count at 0   
            elseif (trackDrops(i) == 1)
                curveCounter = curveCounter + 1;                           % 2. how to disregard final incomplete segment? 
                if curveCounter <= numberFullCurves                              %    stop when curveCount exceeds number of fullCurves
                    curveTrack(i,1) = curveCounter;
                else                                                       % all incomplete curves are filled with 0
                    break                                                  
                end
            end
        end
        curveFinder = [curveFinder; curveTrack];
        clear curveCounter i
        
        
        %% widths
        widthTrack = D5{n}(m).MinAx;%(7:lengthCurrentTrack+6);               % collect widths (um)
        widthVals = [widthVals; widthTrack];                               % concatenate widths
            
        %% volumes
        v_cylinder = pi * lengthTrack .* (widthTrack/2).^2;                % approx. volume as a cylinder = pi * r^2 * h
        v_ellipse = 4/3 * pi * lengthTrack/2 .* (widthTrack/2).^2;         % approx. volume as an ellipse
        vol_smallCylinder = pi * (widthTrack/2).^2 .* (lengthTrack - widthTrack);
        vol_sphere = 4/3 * pi * (widthTrack/2).^3;
        v_anupam = vol_smallCylinder + vol_sphere;                         % approx. volume as cylinder with spherical caps
        
        vcVals = [vcVals; v_cylinder];                                     % concatenate values
        veVals = [veVals; v_ellipse];
        vaVals = [vaVals; v_anupam];
        
        clear v_ellipse v_cylinder vol_sphere vol_smallCylinder
        clear widthTrack
        
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


%% fill in NaN for all non-present data
mu_vcVals = NaN(length(angle),1);
mu_veVals = NaN(length(angle),1);

addedVC = NaN(length(angle),1);
addedVE = NaN(length(angle),1);

ccFraction = NaN(length(angle),1);

%% Compile data into single matrix
dm = [trackID Time lengthVals muVals isDrop curveFinder timeSinceBirth curveDurations ccFraction addedLength widthVals vcVals veVals vaVals mu_vcVals mu_veVals mu_vaVals addedVC addedVE addedVA x_pos y_pos orig_frame stage_num eccentricity angle trackNum condVals bioProdRate];
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
% 12. vcVals
% 13. veVals
% 14. vaVals
% 15. mu_vcVals
% 16. mu_veVals
% 17. mu_vaVals
% 18. addedVC
% 19. addedVE
% 20. addedVA
% 21. x_pos
% 22. y_pos
% 23. orig_frame
% 24. stage_num
% 25. eccentricity
% 26. angle
% 27. trackNum  =  total track number (vs ID which is xy based)
% 28. condVals
% 29. biovolProductionRate


end