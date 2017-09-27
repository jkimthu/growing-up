%% dataTrimmer


%  Goal: automatedly, remove or clip tracks that are unlikely to be well-tracked cells.
%         Removal or trimming is as specified by the selection criteria below.



%  Selection Criteria:

%   1. Tracks that do not increase by more than JumpFrac (30% of size at previous timepoint)
%           - tracks are clipped, not deleted
%           - data prior and after jump are considered separate tracks          


%   2. Tracks must be at least the length of fitting window
%           - note: currently, windowSize = 5 frames

%   3. Tracks cannot oscillate too quickly between gains and losses

%   4. Tracks must be of reasonable size, at least SizeStrainer (1.5um)



% last edit: Sept 27, 2017

% OK lez go!

%% initialize

% particle tracking data
clear
load('t3600-2017-01-12-xy23.mat');
%load('lb-monod-2017-09-20.mat');
%D = D_smash;

% reject data matrix
rejectD = cell(4,length(D));

% criteria counter
criteria_counter = 0;

% windowsize for mu calculations
windowSize = 5;


%% Criteria ONE: clip tracks to separate data surrounding >30% jumps in cell size


% Goal: huge jumps in cell size correspond to cells coming together. Remove
%       the additional fusion and consider that segment of data its own
%       track. Vet it like all others.

%  0. initialize threshold value
%  0. isolate data for current movie
%  0. remove 'Conversion' field, as it is only one element and interferes with downstream clipping.
%        0. for each track, search for large positive increases: > %30 jumps in size
%               0. determine if track is shorter than window size. skip over, if so. it will be trimmed later.
%               1. determine change in length between each timestep
%               2. express change of as a fraction of cell size in previous timestep
%               3. list rows in which the change exceeds size jump threshold
%               4. if the track contains jumps,
%                        i. isolate structure of target track z, in prep to clip all variables (MajAx, X, Y, etc.)
%                       ii. define timepoint of earliest jump
%                      iii. clip data structure at earliest jump
%                       iv. redefine track in data set as clipped structure
%                        v. store remainder of original Target for "reject" data matrix
%               5. repeat for all jumpy tracks
%        6. when all tracks finished, save trimmed data and accmulated rejects
%        7. report number of clipped tracks
%        8. insert at end of data matrix, D2
%  9. repeat for next movie



criteria_counter = criteria_counter + 1;

% 0. initialize
jumpFrac = 0.3;                                                            
                                                                           
for n = 1:length(D);                                                       
    
    % 0. isolate data for current movie
    data = D{n};
    
    % 0. if no data in n, continue to next movie
    if isempty(data) == 1
        disp(strcat('Clipping 0 jumps in D2 (', num2str(n),') !'))
        continue
    end
    
    % 0. remove 'Conversion' field, as it is only one element and interferes with downstream clipping.
    data = rmfield(data,'Conv'); 
    
    
    % 0. for each track, search for large positive increases: > %30 jumps in size
    jump_counter = 0;
    for m = 1:length(data)
        
        %0. determine if track is shorter than window size. skip over, if so. it will be trimmed later.
        if length(data(m).X) < windowSize
            continue
        end
        
        % 1. determine change in length between each timestep                           
        Rates = diff(data(m).MajAx);
        
        % 2. express change of as a fraction of the cell size in previous timestep
        Lengths = data(m).MajAx(1:length(Rates));
        growthFrac = Rates./Lengths;
                                                                           
        % 3. list rows in which the change exceeds size jump threshold
        jumpPoints = find(growthFrac > jumpFrac);                        

        
        % 4. if the track contains jumps...
        if isempty(jumpPoints) == 0
            
            % i. isolate structure of target track z, in prep to clip all variables (MajAx, X, Y, etc.)
            originalTrack = data(m);
            
            % ii. define timepoint of earliest jump
            clipPoint = jumpPoints(1);
            
            % iii. clip data structure at desired timepoint
            clippedTarget = structfun(@(M) M(1:clipPoint), originalTrack, 'Uniform', 0);
            
            % iv. redefine track in data set as clipped structure
            data(m) = clippedTarget;
            
            % v. store remainder of original Target for reject data matrix
            remainderTrack = structfun(@(M) M(clipPoint+1:end), originalTrack, 'Uniform', 0);
            
            jump_counter = jump_counter + 1;
            trackScraps(jump_counter,1) = remainderTrack;

            % 5. repeat for all jumpy tracks
        end
        
        clear remainderTrack clippedTarget clipPoint Lengths Rates growthFrac originalTrack jumpPoints
        
    end
    
    % 6. report!
    X = ['Clipping ', num2str(jump_counter), ' jumps in D2(', num2str(n), ')...'];
    disp(X)
    
    
    % when all tracks finished, 
    if jump_counter == 1
        
        % 7. save accmulated rejects
        rejectD{criteria_counter,n} = trackScraps;
        
        % 8. and insert data after jump at end of data matrix, D2
        D2{n} = [data; trackScraps];
    
    else
        D2{n} = data;
    end
    
    % 9. repeat for all movies
    clear trackScraps X data;
    
end
    
clear  jumpFrac jump_counter Rates m n;



%% Criteria Two: tracks must be at least window size in length (5 frames)


% Goal: after clipping tracks by track ID, some are quite short and lead to problems in
%       subsequent steps, i.e. those that require rates of change produce
%       an error if tracks are only 1 frame long. Remove these.

% 0. initiaize new dataset before trimming
% 0. in current movie
%           1. for each track, determine number of timepoints
%           2. find tracks that are shorter than threshold number of frames
%           3. report!
%           4. if no sub-threshold tracks, continue to next movie
%           5. else, remove structures based on row # (in reverse order)
%           6. save sub-threshold tracks into reject data matrix
% 7. repeat for next movie



criteria_counter = criteria_counter + 1;


% 0. initialize new dataset before trimming
D3 = D2;

for n = 1:length(D);
    
    % 0. if no data in n, continue to next movie
    if isempty(D3{n}) == 1

        disp(strcat('Removing (0) short tracks from D3 (', num2str(n),') !'))

        continue
    end
    
    % 1. determine number of timepoints in each track m 
    for m = 1:length(D3{n})
        numFrames(m) = length(D3{n}(m).MajAx);
    end
    
    % 2. find tracks that are shorter than threshold number of frames
    subThreshold = find(numFrames < windowSize);       
    
    % 3. report!
    X = ['Removing ', num2str(length(subThreshold)), ' short tracks from D3(', num2str(n), ')...'];
    disp(X)
    
    % 4. to that loop doesn't crash if nothing is too short
    if isempty(subThreshold) == 1
        continue
    end
    
    % 5. remove structures based on row # (in reverse order)
    fingers = 0;
    for toRemove = 1:length(subThreshold)
        
        r = length(subThreshold) - fingers;                  % reverse order                  
        tracks_shortGlimpses(r,1) = D3{n}(subThreshold(r));   % store data for reject data matrix
        D3{n}(subThreshold(r)) = [];                         % deletes data
        fingers = fingers + 1;
        
    end
    
    % 6. save sub-threshold tracks into reject data matrix
    rejectD{criteria_counter,n} = tracks_shortGlimpses;
    
    % 7. repeat for all movies
    clear  numFrames m subThreshold fingers toRemove r X tracks_shortGlimpses;
    
end

 clear windowSize n; 
 

%% Criteria Three: tracks cannot oscillate too quickly between gains and losses


% Goal: jiggly tracks correspond to non-growing particles or errors in tracking...remove!
%       method: are most negatives divisions?

% 0. initialize copy of dataset before trimming
% 0. define thresholds
% 0. for each movie
%        1. for each track, collect % of non-drop negatives per track length (in frames)
%                2. isolate length data from current track
%                3. find change in length between frames
%                4. convert change into binary, where positives = 0 and negatives = 1
%                5. find all drops (negatives that exceed drop threshold)
%                6. find the ratio of non-drop negatives per track length
%                7. store ratio for subsequent removal
%       8. repeat for all tracks
%       9. determine which tracks fall under jiggle threshold
%      10. report!
%      11. remove jiggly tracks in reverse order
% 12. repeat for all movies


criteria_counter = criteria_counter + 1;

% 0. initiaize new dataset before trimming
D4 = D3;

% 0. define threshold change in length considered a division
dropThreshold = -0.75;

% 0. define threshold under which tracks are too jiggly
jiggleThreshold = -0.3;

for n = 1:length(D)
    
    % 0. if no data in n, continue to next movie
    if isempty(D4{n}) == 1
        disp(strcat('Removing (0) jiggly tracks from D4 (', num2str(n),') !'))
        continue
    end
    
    % 1. for each track, collect % of non-drop negatives per track length (in frames)
    nonDropRatio = NaN(length(D{n}),1);
    
    for m = 1:length(D4{n})
        
        % 2. isolate length data from current track
        lengthTrack = D4{n}(m).MajAx;
        
        % 3. find change in length between frames
        diffTrack = diff(lengthTrack);
        
        % 4. convert change into binary, where positives = 0 and negatives = 1
        binaryTrack = logical(diffTrack < 0);
        
        % 5. find all drops (negatives that exceed drop threshold)
        dropTrack = diffTrack < dropThreshold;
        
        % 6. find the ratio of non-drop negatives per track length
        nonDropNegs = sum(dropTrack - binaryTrack);
        squiggleFactor = nonDropNegs/length(lengthTrack);
        
        % 7. store ratio for subsequent removal
        nonDropRatio(m) = squiggleFactor;
    
    % 8. repeat for all tracks
    end
    
    % 9. determine which tracks fall under jiggle threshold
    belowThreshold = find(nonDropRatio <= jiggleThreshold);
    
    % 10. report!
    X = ['Removing ', num2str(length(belowThreshold)), ' jiggly tracks from D4(', num2str(n), ')...'];
    disp(X)
    
    % 11. remove jiggly structures based on row # (in reverse order)
    counter = 0;
    for toRemove = 1:length(belowThreshold)
        
        r = length(belowThreshold) - counter;            % reverse order
        jigglers(r,1) = D4{n}(belowThreshold(r));        % store data for reject data matrix
        D4{n}(belowThreshold(r)) = [];                   % deletes data
        counter = counter + 1;
        
    end

    % 13. save sub-threshold tracks into reject data matrix
    rejectD{criteria_counter,n} = jigglers;
    
    % 14. repeat for all movies
    clear nonDropRatio lengthTrack diffTrack dropTrack nonDropNegs squiggleFactor belowThreshold
    clear toRemove binaryTrack r X jigglers
  
end

clear n gainLossRatio jiggleThreshold jigglers counter dropThreshold;




%% Criteria Four: maximum particle size must be greater than 1.5um

criteria_counter = criteria_counter + 1;

D5 = D4;
SizeStrainer = 1.5;

for n = 1:length(D);   
    
    % 1. so that loop doesn't crash if no data remaining in n
    if isempty(D5{n}) == 1
        X = ['Removing 0 small particles from D5(', num2str(n), ')...'];
        disp(X)
        continue
    end
    
    for i = 1:length(D5{n})
        lengthTrack(i) = max(D5{n}(i).MajAx);                          
    end          
    
    % finds tracks that don't exceed __ um
    tooSmalls = find(lengthTrack < SizeStrainer);                          
    
    % report!
    X = ['Removing ', num2str(length(tooSmalls)), ' small particles from D5(', num2str(n), ')...'];
    disp(X)
    
    % so loop doesn't crash if nothing is too small
    if isempty(tooSmalls) == 1
        continue
    end
    
    % remove too-small structures based on row # (in reverse order)
    countSmalls = 0;
    for s = 1:length(tooSmalls)
        t = length(tooSmalls) - countSmalls;
        tracks_tooSmalls(t,1) = D5{n}(tooSmalls(t));      %  recording to add into reject data matrix
        D5{n}(tooSmalls(t)) = [];
        countSmalls = countSmalls + 1;
    end
    
    % save tracks that are too small into reject data matrix
    rejectD{criteria_counter,n} = tracks_tooSmalls;
    clear lengthTrack lengthTrack_dbl i tooSmalls countSmalls s t X tracks_tooSmalls;

    
end 

clear SizeStrainer n i m tooSmalls X;


 

%% Saving results


save('t3600-2017-01-12-xy23-jiggle-0p3.mat', 'D', 'D2', 'D3', 'D4', 'D5', 'rejectD', 'T')%, 'reader', 'ConversionFactor')
%save('lb-monod-2017-09-20-jiggle-0p1.mat', 'D', 'D2', 'D3', 'D4', 'D5', 'rejectD', 'T')%, 'reader', 'ConversionFactor')


%% 
% 