%% Automated quality control from particle tracking and its resulting data structure (D)


%  Goals: with defined selection criteria, kick out tracks that do not
%  appear to be growing cells. of those that remain, smooth all data to
%  reduce noise in future analyses.


%  For each of selection criteria:

%       a. find tracks that disobey
%       b. remove from trimmed data structure
%       c. place removed tracks into a "trash" data structure, for review


%
%  SELECTION CRITERIA:

%   1) Tracks must be of reasonable size, SizeStrainer (1.5um)
 
%   2) Tracks that are at least 20 frames long

%   3) Tracks must undergo at least 30% growth
%           - note: 1.3 easily allows for  cells that are shrinking

%   4) Tracks with losses of extended duration nor oscillate too quickly between gains and losses

%   5) Tracks that do not increase by more than JumpFrac (30% of size at previous timepoint) 



% last edit: June 26, 2017


%% initialize

% particle tracking data
clear
load('letstry-2017-06-12-dSmash.mat');
D = D_smash;

% reject data matrix
rejectD_scram = cell(5,length(D));


%% criteria five: tracks cannot oscillate too quickly between gains and losses

Scram2 = D;
gainLossRatio = 0.85;


for n = 1:length(D)
    for i = 1:length(Scram2{n})
        
        % determine derivative of each timestep in length
        Signs = diff(Scram2{n}(i).MajAx);
        
        % minute res is so noisy. use average change for every 10 steps.
        sampleLength = floor( length(Signs)/10 ) * 10;
        
        Signs = mean(reshape(Signs(1:sampleLength),10,[]))';
        Signs(Signs<0) = 0;
        Signs(Signs>0) = 1;
        
        % determine ratio of negatives to positives
        trackRatio = sum(Signs)/length(Signs);
        
        % store ratio for track removal
        allRatios(i,1) = trackRatio;
        
        clear Signs trackRatio sampleLength;
    end
    
    
    % identify tracks with over 15% negatives
    swigglyIDs = find(allRatios < 0.85);
    
    % report!
    X = ['Removing ', num2str(length(swigglyIDs)), ' swiggly tracks from Scram2(', num2str(n), ')...'];
    disp(X)
    
    % so loop doesn't crash if nothing is too wiggly
    if isempty(swigglyIDs) == 1
        continue
    end
    
    % remove structures based on row # (in reverse order)
    counter = 0;
    for q = 1:length(swigglyIDs)
        r = length(swigglyIDs) - counter;                                
        Scram2{n}(swigglyIDs(r)) = [];
        swigglyTracks(r,1) = D{n}(swigglyIDs(r));   % recording to add into reject data matrix  
        counter = counter + 1;
    end
    
    % save tracks that are too swiggly into reject data matrix
    rejectD_scram{1,n} = swigglyTracks;
    
    clear allRatios allTracks bottomTracks gainLossRatio swigglyIDs swigglyTracks q r i counter X; 
end

clear n gainLossRatio;




%% criteria 3: clip tracks to remove >30% jumps in cell size
%          
%              - if too positive (cells shouldn't double within three minutes)
%              - in these cases, what causes these large jumps? check!
%              - negatives are OK because cells have to divide!

Scram3 = Scram2;  
JumpFrac = 0.3;                                                            % JumpFrac = threshold parameter
                                                                           % tracks that increase by a cell size fraction greater than JumpFrac will be eliminated from final dataset
for n = 1:length(D);                                                       
    
    counter = 0;                                                           
    Scram3{n} = rmfield(Scram3{n},'Conv');                                         % removes the 'Conversion' field, as it is only one element. it interferes with downstream clipping.
    
    for i = 1:length(Scram3{n})                                            % error "undefined variable" if some cells have no tracks, []     
                                                                           
        % derivative of current length tracjetory                            
        Rates = diff(Scram3{n}(i).MajAx);                                   
                                                                           
        % list rows in which Rate exceeds threshold
        jumpPoints = find(Rates > JumpFrac);                        

        
        % for tracks containing jumps...
        if isempty(jumpPoints) == 0
            
            % record track row, such that jumpTrack lists all jumpy tracks
            %currentJumpTrack = i;
            counter = counter + 1;                             
            %jumpTrack(counter) = i;
            
            % loop through and trim all jumpy tracks
            % uh oh- does this continuous loop keep snipping tracks when
            % they don't need to be?
            %for z = 1:length(jumpTrack) 
               
                % isolate structure of target track z, in prep to clip all variables (MajAx, X, Y, etc.)
                target2Snip = Scram3{1,n}(i);                            
                
                % defines timepoint at point of earliest jump
                snipPoint = jumpPoints(1);  
                
                % clips structure at desired timepoint
                snippedTarget = structfun(@(M) M(1:snipPoint), target2Snip, 'Uniform', 0);   
                
                % redefines track in data set as trimmed structure
                Scram3{1,n}(i) = snippedTarget;
                
                % store original Target for reject data matrix
                tracks_clipJump(counter,1) = target2Snip;
            %end
        end
        
    end
    
    % report!
    X = ['Clipping ', num2str(counter), ' jumps from Scram3(', num2str(n), ')...'];
    disp(X)
    
    % save tracks that are too small into reject data matrix
    rejectD_scram{2,n} = tracks_clipJump;
    
    if n < length(D)
        clear Rates jumpTrack z;                                        % erases info from current series, so that tracks don't roll into next iteration
    end
    
end
    
clear tf JumpFrac Target counter jumpTrack Rates Tpt clipTarget i n z X;
clear Jumpers tracks_clipJump;


%% criteria 4: total track length must be at least 30 mins

Scram4 = Scram3;
Shortest = 20;                                                             % each timepoint = 1:05 mins;

for n = 1:length(D);

    % determine number of timepoints in each track i 
    for i = 1:length(Scram4{n})
        cellLength{i} = length(Scram4{n}(i).MajAx);
    end
    
    % find tracks that are shorter than ___ mins
    cellLength_dbl = cell2mat(cellLength);
    shortGlimpse = find(cellLength_dbl < Shortest);       
    
    % report!
    X = ['Removing ', num2str(length(shortGlimpse)), ' short tracks from Scram4(', num2str(n), ')...'];
    disp(X)
    
    % to that loop doesn't crash if nothing is too short
    if isempty(shortGlimpse) == 1
        continue
    end
    
    % remove structures based on row # (in reverse order)
    fingers = 0;
    for q = 1:length(shortGlimpse)
        r = length(shortGlimpse) - fingers;                                
        Scram4{n}(shortGlimpse(r)) = [];
        tracks_shortGlimpses(r,1) = D{n}(shortGlimpse(r));   % recording to add into reject data matrix  
        fingers = fingers + 1;
    end
    
    % save tracks that are too small into reject data matrix
    rejectD_scram{3,n} = tracks_shortGlimpses;
    
    clear  cellLength cellLength_dbl i shortGlimpse fingers q r X tracks_shortGlimpses;
    
end

 clear Shortest n; 

 %% criteria 2: tracks must increase in size by > 30%


Scram5 = Scram4;
GoldenRatio = 1.3;                  

for n = 1:length(D);      
    
    if isempty(Scram5{n}) == 1
        continue
        
    else
        % determine difference percent change between min and max length for each track, i
        for i = 1:length(Scram5{n})
            
            maxLengths(i) = arrayfun(@(Q) max(Q.MajAx), Scram5{n}(i));
            minLengths(i) = arrayfun(@(Q) min(Q.MajAx), Scram5{n}(i));
            
        end
           lengthRatio = maxLengths./minLengths;
    end
    

    
    % find tracks that show little growth                      
    littleGrowth = find(lengthRatio < GoldenRatio); 
    
    % report!
    X = ['Removing ', num2str(length(littleGrowth)), ' non-doublers from Scram5(', num2str(n), ')...']; 
    disp(X)                                                         
    
    % so loop doesn't crash if nothing grows too little
    if isempty(littleGrowth) == 1
        continue
    end
    
    % remove structures based on row # (in reverse order)
    counter = 0;
    for j = 1:length(littleGrowth)
        
        k = length(littleGrowth) - counter;
        Scram5{n}(littleGrowth(k)) = [];
        tracks_littleGrowth(k,1) = D{n}(littleGrowth(k));   % recording to add into reject data matrix
        counter = counter + 1;
        
    end
    
    % save tracks that hardly increase into reject data matrix
    rejectD_scram{4,n} = tracks_littleGrowth;
    clear maxLengths minLengths littleGrowth lengthRatio i j k X counter ToCut tracks_littleGrowth;
    
end

clear GoldenRatio n;
 
%% criteria 1: max particle size must be greater than 1.5um

Scram6 = Scram5;
SizeStrainer = 1.5;

for n = 1:length(Scram5);                           
    
    for i = 1:length(Scram6{n})
        lengthTrack{i} = max(Scram6{n}(i).MajAx);                          
    end          
    
    % finds tracks that don't exceed __ um
    lengthTrack_dbl = cell2mat(lengthTrack);  
    tooSmalls = find(lengthTrack_dbl < SizeStrainer);                          
    
    % report!
    X = ['Removing ', num2str(length(tooSmalls)), ' small particles from Scram6(', num2str(n), ')...'];
    disp(X)
    
    % so loop doesn't crash if nothing is too small
    if isempty(tooSmalls) == 1
        continue
    end
    
    % remove too-small structures based on row # (in reverse order)
    countSmalls = 0;
    for s = 1:length(tooSmalls)
        t = length(tooSmalls) - countSmalls;
        Scram6{n}(tooSmalls(t)) = [];
        tracks_tooSmalls(t,1) = D{n}(tooSmalls(t));      %  recording to add into reject data matrix
        countSmalls = countSmalls + 1;
    end
    
    % save tracks that are too small into reject data matrix
    rejectD_scram{1,n} = tracks_tooSmalls;
    clear lengthTrack lengthTrack_dbl i tooSmalls countSmalls s t X tracks_tooSmalls;
    %
%     else
%         % jump to next xy if no tracks are too small
%         clear lengthTrack lengthTrack_dbl i tooSmalls countSmalls s t X tracks_tooSmalls;
%         continue
%     end
%     
    
end 

clear SizeStrainer n;


 

%% Saving results

save('letstry-2017-06-12-autoTrimmed-scrambledOrder-editedJumpTrack.mat', 'D_smash', 'Scram2', 'Scram3', 'Scram4', 'Scram5', 'Scram6', 'rejectD_scram', 'T')%, 'reader', 'ConversionFactor')


%% visualizing samples of data set

% -- criteria five, check
% select sample of tracks to visualize
bottomTracks = find(allRatios < 0.85);
sampleTracks = find(allRatios < 1);

c = ismember(sampleTracks, bottomTracks);
sampleTracks(c) = [];

for st = 1:length(sampleTracks)
    
    % designate subplot position
    subplot(ceil(length(sampleTracks)/5), 5, st)
    
    % plot
    figure(n)
    plot(T{n}(D6{n}(sampleTracks(st)).Frame(1:end))/3600,(D6{n}(sampleTracks(st)).MajAx),'Linewidth',2)
   
    
    % label
    title(sampleTracks(st));
    
end

%%
% -- final pass, check

%
for n = 51 %:length(D6)
    %counter = counter +1;
    
    for i = 1:20%length(D6{n})
        
        % designate subplot position
        %subplot(ceil(length(D6{n})/5), 5, i)
        subplot(ceil(20/5), 5, i)
        
        % plot
        %figure(counter)
        plot(T{n}(D6{n}(i).Frame(1:end))/3600,(D6{n}(i).MajAx),'Linewidth',2)
        
        % label
        title(i);
        
    end
end

%% visualize any one single curve

%
plot(T{n}(D6{n}(i).Frame(1:end))/3600,(D6{n}(i).MajAx),'Linewidth',2)
        axis([0,10,0,15])



