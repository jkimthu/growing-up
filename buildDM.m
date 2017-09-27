% buildDM
% adapted from matrixBuilder, but prevents need to save data matrices.
% ideal for smaller inputs that take less time to process.

% last updated: jen, 2017 Sept 25

function [dm] = buildDM(D5,M,T)
%%
% initialize all values
condVals = [];    % col 35 (of 35 columns)

trackID = [];     % col 1
trackNum = [];    % col 34, total track number for entire experiment
tn_counter = 0;

Time = [];        % col 2

x_pos = [];       % col 28
y_pos = [];       % col 29
orig_frame = [];  % col 30
stage_num = [];   % col 31
eccentricity = [];
angle = [];

lengthVals = [];  % col 3
widthVals = [];
vcVals = [];
veVals = [];
vaVals = [];

muVals = [];     % col 4
mu_vcVals = [];
mu_veVals = [];
mu_vaVals = [];

isDrop = [];      % col 5
dropThreshold = -0.75;                                                     % consider greater negatives a division event

curveFinder = [];                                                        

timeSinceBirth = [];
lengthAdded_incremental_sinceBirth = [];
vcAdded_incremental_sinceBirth = [];
veAdded_incremental_sinceBirth = [];
vaAdded_incremental_sinceBirth = [];

allDurations = [];
allDeltas = [];
allTimestamps = [];

birthSizes = [];
birthTimes = [];

curveDurations = [];  % col 8
addedDelta = [];      % col 11
addedVC = [];
addedVE = [];
addedVA = [];

addedLength_incremental = [];
addedVC_incremental = [];
addedVE_incremental = [];
addedVA_incremental = [];

%%
% Select xy positions for analysis / concatenation

for n = 1:length(D5)
%%
    for m = 1:length(D5{n})                                                
        
        % 1. track ID                                                        
        lengthCurrentTrack = length(D5{n}(m).TrackID);
        Track = D5{n}(m).TrackID;
        trackID = [trackID; Track];
        
        
        % 34. track number
        tn_counter = tn_counter + 1;
        tnTrack = ones(length(Track),1)*tn_counter;
        trackNum = [trackNum; tnTrack];
        
        
        % 30. frame number in original image
        frameTrack = D5{n}(m).Frame;
        %frameTrack = D5{n}(m).Frame(3:lengthCurrentTrack+2); % trimming to fit mu
        orig_frame = [orig_frame; frameTrack];
        
        
        % 2. time
        %timeTrack = T(3:lengthCurrentTrack+2,n)/(60*60);                  % collect timestamp (hr)
        timeTrack = T{n}(frameTrack(1):lengthCurrentTrack+frameTrack(1)-1);%(7:lengthCurrentTrack+6)./(3600);
                                                                           % data format, if all ND2s were processed individually
        Time = [Time; timeTrack];                                          %concat=enate timestamp
       
        
        
        % 3. lengths
        lengthTrack = D5{n}(m).MajAx;%(7:lengthCurrentTrack+6);              % collect lengths (um)
        lengthVals = [lengthVals; lengthTrack];                            % concatenate lengths
        dLengths = diff(lengthTrack);
        dLengths = [0; dLengths];
        addedLength_incremental = [addedLength_incremental; dLengths];
        
        
        % 4. mu
        muTrack = zeros(lengthCurrentTrack,1);
        measuredMus = M{n}(m).mu(:,1);                                     % collect elongation rates (1/hr)
        muTrack(3:length(measuredMus)+2) = measuredMus;
        muVals = [muVals; muTrack];                                        % concatenate growth rates
        
        
        
        % 5. drop?
        dropTrack = diff(lengthTrack);
        toBool = dropTrack < dropThreshold;                                % converts different to a Boolean based on dropThreshold
        toBool = [0; toBool];                                              % * add zero to front, to even track lengths
        isDrop = [isDrop; toBool];
        
        
        % 6.  curve finder                                                 % identifying full curves for cell cycle stats
        numberFullCurves = sum(toBool) - 1;                                % all curves start and end with a division, isDrop = 1                                      
        curveTrack = zeros(length(toBool),1);
        
        % find and number the full curves within a single track
        curveCounter = 0;                                                  
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
        curveFinder = [curveFinder; curveTrack];
        clear curveCounter i
        
        
        % 7 & 8. time since birth and curve duration                                                
        durationsPerTrack = zeros(numberFullCurves,1);     
        durationVector = zeros(lengthCurrentTrack,1);   % a vector of cell cycle durations (completion time per cell cycle)
        lengthVector = zeros(lengthCurrentTrack,1);
        tsbPerTrack = zeros(lengthCurrentTrack,1);
        
        % stratgey: per individual curve...
        %       i.   identify events bounding each curve
        %       ii.  isolate timepoints in between events for calculations specific to that curve
        %       iii. time since birth = isolated timepoints minus time of birth
        %       iv.  added mass since birth = length(at timepoints) minus length at birth
        %       v.   final added mass and total curve duration = values at division event
        
        for currentCurve = 1:numberFullCurves;
            
            % i. identify events bounding each curve
            isolateEvents = timeTrack.*toBool;
            eventTimes = isolateEvents(isolateEvents~=0);
            %clear isolateEvents
            
            currentBirthRow = find(timeTrack == eventTimes(currentCurve)); % row in which current curve begins
            nextBirthRow = find(timeTrack == eventTimes(currentCurve+1));
            currentTimes = timeTrack(currentBirthRow:nextBirthRow-1);
            
            % ii. incremental time
            tsbPerCurve = currentTimes - timeTrack(currentBirthRow);       % time since birth, per timestep of curve
            tsbPerTrack(currentBirthRow:nextBirthRow-1,1) = tsbPerCurve;
            
            % incremental length
            lsbPerCurve = lengthTrack(currentBirthRow:nextBirthRow-1) - lengthTrack(currentBirthRow);
            lsbPerTrack(currentBirthRow:nextBirthRow-1,1) = lsbPerCurve;
            
            % final duration and mass
            durationsPerTrack(currentCurve) = tsbPerCurve(end);            % tsb = time since brith
            lengthPerTrack(currentCurve) = lsbPerCurve(end);               % lsb = length added since birth
        end
        %clear tsbPerCurve lsbPerCurve currentCurve currentTimes eventTimes
        %clear currentBirthRow nextBirthRow numberFullCurves toBool timeTrack
        
        % 7. time since birth
        if numberFullCurves <= 0
            
            noCurves = zeros(lengthCurrentTrack,1);
            timeSinceBirth = [timeSinceBirth; noCurves];
            
        else
            
            %filler = zeros(lengthCurrentTrack-length(tsbPerTrack),1);
            timeSinceBirth = [timeSinceBirth; tsbPerTrack];%; filler];        % compiled values of time passed since last birth event
            %lengthSinceBirth = [lengthSinceBirth; lsbPerTrack; filler];
            %clear filler tsbPerTrack lsbPerTrack lengthTrack
        end
        
        
        % for all timepoints in current track:
        %       - if timepoint is part of a full curve, move on so value remains zero
        %       - if timepoint is part of a full curve, record final curve duration and added size
        
        for j = 1:length(curveTrack)
            if curveTrack(j) == 0
                continue
            else
                durationVector(j,1) = durationsPerTrack(curveTrack(j));
                lengthVector(j,1) = lengthPerTrack(curveTrack(j));
            end
        end
        clear durationsPerTrack lengthPerTrack curveTrack j
        
        % 8. curve duration (total time of current cell cycle)
        curveDurations = [curveDurations; durationVector];
        clear durationVector
        
        % 11. added delta (total added length in current cell cycle)
        addedDelta = [addedDelta; lengthVector];
        clear lengthVector
        
        
        % 12. widths
        widthTrack = D5{n}(m).MinAx;%(7:lengthCurrentTrack+6);               % collect widths (um)
        widthVals = [widthVals; widthTrack];                               % concatenate widths
        clear widthTrack
        
        
        % 28. x positions in original image
        xTrack = D5{n}(m).X;%(7:lengthCurrentTrack+6); 
        x_pos = [x_pos; xTrack];
        clear xTrack
        
        
        % 29. y positions in original image
        yTrack = D5{n}(m).Y;%(7:lengthCurrentTrack+6);
        y_pos = [y_pos; yTrack];
        clear yTrack
        
        
        % 31. trim stage in dataTrimmer
        trimTrack = ones(length(Track),1)*n;
        stage_num = [stage_num; trimTrack];
        clear Track trimTrack
        
        
        % 32. eccentricity of ellipses used in particle tracking
        eccTrack = D5{n}(m).Ecc;%(7:lengthCurrentTrack+6);
        eccentricity = [eccentricity; eccTrack];
        clear eccTrack
        
        
        % 33. angle of ellipses used in particle tracking
        angTrack = D5{n}(m).Ang;%(7:lengthCurrentTrack+6);
        angle = [angle; angTrack];
        clear angTrack
         
                                                                           
        % 34. CONDITION
        % assign condition based on xy number
        condition = ceil(n/10);
        
        % label each row with a condition #
        condTrack = ones(lengthCurrentTrack,1)*condition;
        condVals = [condVals; condTrack];
        clear condTrack
        
    end % for m
    
    disp(['Tracks (', num2str(m), ') assembled from movie (', num2str(n), ') !'])
%%    
    
end % for n


% fill in NaN for all non-present data
vcVals = NaN(length(angle),1);
veVals = NaN(length(angle),1);
vaVals = NaN(length(angle),1);

mu_vcVals = NaN(length(angle),1);
mu_veVals = NaN(length(angle),1);
mu_vaVals = NaN(length(angle),1);
                                                   
lengthAdded_incremental_sinceBirth = NaN(length(angle),1);
vcAdded_incremental_sinceBirth = NaN(length(angle),1);
veAdded_incremental_sinceBirth = NaN(length(angle),1);
vaAdded_incremental_sinceBirth = NaN(length(angle),1);

allDurations = NaN(length(angle),1);
allDeltas = NaN(length(angle),1);
allTimestamps = NaN(length(angle),1);

birthSizes = NaN(length(angle),1);
birthTimes = NaN(length(angle),1);

addedVC = NaN(length(angle),1);
addedVE = NaN(length(angle),1);
addedVA = NaN(length(angle),1);

addedLength_incremental = NaN(length(angle),1);
addedVC_incremental = NaN(length(angle),1);
addedVE_incremental = NaN(length(angle),1);
addedVA_incremental = NaN(length(angle),1);

ccFraction = NaN(length(angle),1);


% Compile data into single matrix
dm = [trackID Time lengthVals muVals isDrop curveFinder timeSinceBirth curveDurations ccFraction lengthAdded_incremental_sinceBirth addedDelta widthVals vcVals veVals vaVals mu_vcVals mu_veVals mu_vaVals vcAdded_incremental_sinceBirth veAdded_incremental_sinceBirth vaAdded_incremental_sinceBirth addedVC addedVE addedVA addedVC_incremental addedVE_incremental addedVA_incremental x_pos y_pos orig_frame stage_num eccentricity angle trackNum condVals];
% 1. track ID, as assigned by ND2Proc_XY
% 2. Time
% 3. lengthVals
% 4. muVals
% 5. isDrop
% 6. curveFinder
% 7. timeSinceBirth
% 8. curveDurations
% 9. ccFraction 
% 10. lengthAdded_incremental_sinceBirth
% 11. addedDelta
% 12. widthVals
% 13. vcVals
% 14. veVals
% 15. vaVals
% 16. mu_vcVals
% 17. mu_veVals
% 18. mu_vaVals
% 19. vcAdded_incremental_sinceBirth
% 20. veAdded_incremental_sinceBirth
% 21. vaAdded_incremental_sinceBirth
% 22. addedVC
% 23. addedVE
% 24. addedVA
% 25. addedVC_incremental
% 26. addedVE_incremental
% 27. addedVA_incremental
% 28. x_pos
% 29. y_pos
% 30. orig_frame
% 31. stage_num
% 32. eccentricity
% 33. angle
% 34. trackNum  =  total track number (vs ID which is xy based)
% 35. condVals


end