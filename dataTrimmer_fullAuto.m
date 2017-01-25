%% Automated quality control from particle tracking and its resulting data structure (D)
%

%  For each of selection criteria:

%       a. find tracks that disobey
%       b. remove from trimmed data structure
%       c. place removed tracks into a "trash" data structure, for review

%
%  SELECTION CRITERIA:


%   1) Tracks must be of reasonable size, SizeStrainer (1.5um)
 
%   2) Tracks that are at least NumTpts (30 mins) long

%   3) Tracks must undergo at least 30% growth
%           - note: 1.3 easily allows for  cells that are shrinking

%   4) Tracks with losses of extended duration nor oscillate too quickly between gains and losses

%   5) Tracks that do not increase by more than JumpFrac (30% of size at previous timepoint) 



% last edit: Jan 25, 2017


%% initialize

% particle tracking data
clear
load('t300_2017-01-16.mat');

% reject data matrix
rejectD = cell(5,40);


%% criteria 1: max particle size must be greater than 1.5um

D2 = D;
SizeStrainer = 1.5;

for n = 1:length(D);                           
    
    for i = 1:length(D2{n})
        lengthTrack{i} = max(D2{n}(i).MajAx);                          
    end          
    
    % finds tracks that don't exceed __ um
    lengthTrack_dbl = cell2mat(lengthTrack);  
    tooSmalls = find(lengthTrack_dbl < SizeStrainer);                          
    
    % report!
    X = ['Removing ', num2str(length(tooSmalls)), ' small particles from D2(', num2str(n), ')...'];
    disp(X)
    
    % remove structures based on row # (in reverse order)
    countSmalls = 0;
    for s = 1:length(tooSmalls)                                            
        t = length(tooSmalls) - countSmalls;                              
        D2{n}(tooSmalls(t)) = [];                                         
        tracks_tooSmalls(t,1) = D{n}(tooSmalls(t));      %  recording to add into reject data matrix 
        countSmalls = countSmalls + 1;     
    end
    
    % save tracks that are too small into reject data matrix
    rejectD{1,n} = tracks_tooSmalls;
    
    clear lengthTrack lengthTrack_dbl i tooSmalls countSmalls s t X tracks_tooSmalls;
end 

clear SizeStrainer n;


 
%% criteria 2: tracks must increase in size by > 30%


D3 = D2;
GoldenRatio = 1.3;                  

for n = 1:length(D);      
    
    % determine difference percent change between min and max length for each track, i
    for i = 1:length(D3{n})                                                
        maxLengths{i} = arrayfun(@(Q) max(Q.MajAx), D3{n}(i));     
        minLengths{i} = arrayfun(@(Q) min(Q.MajAx), D3{n}(i));             
        lengthRatio{i} = maxLengths{i}/minLengths{i};
    end
    
    % find tracks that show little growth
    lengthRatio = cell2mat(lengthRatio);                           
    littleGrowth = find(lengthRatio < GoldenRatio); 
    
    % report!
    X = ['Removing ', num2str(length(littleGrowth)), ' non-doublers from D3(', num2str(n), ')...']; 
    disp(X)                                                         
    
    % remove structures based on row # (in reverse order)   
    counter = 0;
    for j = 1:length(littleGrowth)
        k = length(littleGrowth) - counter;                                
        D3{n}(littleGrowth(k)) = [];
        tracks_littleGrowth(k,1) = D2{n}(littleGrowth(k));   % recording to add into reject data matrix  
        counter = counter + 1;
    end
    
    % save tracks that are too small into reject data matrix
    rejectD{2,n} = tracks_littleGrowth;
    
    clear maxLengths minLengths littleGrowth lengthRatio i j k X counter ToCut tracks_littleGrowth;        
    
end
clear GoldenRatio n;

%% criteria 3: clip tracks to remove >30% jumps in cell size
%          
%              - if too positive (cells shouldn't double within three minutes)
%              - in these cases, what causes these large jumps? check!
%              - negatives are OK because cells have to divide!

D4 = D3;  
JumpFrac = 0.3;                                                            % JumpFrac = threshold parameter
                                                                           % tracks that increase by a cell size fraction greater than JumpFrac will be eliminated from final dataset
for n = 1:length(D);                                                       
    counter = 0;                                                           
    D4{n} = rmfield(D4{n},'Conv');                                         % removes the 'Conversion' field, as it is only one element. it interferes with downstream clipping.
    
    for i = 1:length(D4{n})                                                % error "undefined variable" if some cells have no tracks, [], run groups separately as needed        
                                                                           
        % derivative of length tracjetory                            
        Rates{i} = diff(D4{n}(i).MajAx);                                   
                                                                           
        % lists the tpt for which the Rate in any track jumps higher than 30%
        Jumpers{n,i} = find(Rates{i} > JumpFrac);                        

                                                                                                                                   
        tf = find(Jumpers{n,i});
        if tf > 0
            counter = counter + 1;                             
            jumpTrack(counter) = i;
            
            for z = 1:length(jumpTrack)
               
                % isolate structure of target track z, in prep to clip all variables (MajAx, X, Y, etc.)
                Target = D4{1,n}(jumpTrack(z));                            
                
                % defines timepoint at point of jump
                Tpt = Jumpers{n,jumpTrack(z)};  
                
                % clips structure at desired timepoint
                clipTarget = structfun(@(M) M(1:Tpt), Target, 'Uniform', 0);   
                
                % redefines track in data set as trimmed structure
                D4{1,n}(jumpTrack(z)) = clipTarget;
                
                % store original Target for reject data matrix
                tracks_clipJump(z,1) = Target;
            end
            
        else
            continue
        end
        
    end
    
    % report!
    X = ['Clipping ', num2str(counter), ' jumps from D4(', num2str(n), ')...'];
    disp(X)
    
    % save tracks that are too small into reject data matrix
    rejectD{3,n} = tracks_clipJump;
    
    if n < length(D)
        clear Rates jumpTrack z;                                        % erases info from current series, so that tracks don't roll into next iteration
    end
    
end
    
clear tf JumpFrac Target counter jumpTrack Rates Tpt clipTarget i n z X;
clear Jumpers tracks_clipJump;


%% criteria 4: total track length must be at least 30 mins

D5 = D4;
Shortest = 30;                                                             % each timepoint = 1:05 mins;

for n = 1:length(D);

    % determine number of timepoints in each track i 
    for i = 1:length(D5{n})
        cellLength{i} = length(D5{n}(i).MajAx);
    end
    
    % find tracks that are shorter than ___ mins
    cellLength_dbl = cell2mat(cellLength);
    shortGlimpse = find(cellLength_dbl < Shortest);       
    
    % report!
    X = ['Removing ', num2str(length(shortGlimpse)), ' short tracks from D5(', num2str(n), ')...'];
    disp(X)
    
    % to that loop doesn't crash if nothing is too short
    if isempty(shortGlimpse) == 1
        continue
    end
    
    % remove structures based on row # (in reverse order)
    fingers = 0;
    for q = 1:length(shortGlimpse)
        r = length(shortGlimpse) - fingers;                                
        D5{n}(shortGlimpse(r)) = [];
        tracks_shortGlimpses(r,1) = D4{n}(shortGlimpse(r));   % recording to add into reject data matrix  
        fingers = fingers + 1;
    end
    
    % save tracks that are too small into reject data matrix
    rejectD{4,n} = tracks_shortGlimpses;
    
    clear  cellLength cellLength_dbl i shortGlimpse fingers q r X tracks_shortGlimpses;
end

 clear Shortest n; 


%% criteria five: tracks cannot oscillate too quickly between gains and losses

D6 = D5;
gainLossRatio = 0.85;


for n = 1:length(D)
    for i = 1:length(D6{n})
        
        % determine derivative of each timestep in length
        Signs = diff(D6{n}(i).MajAx);
        
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
    X = ['Removing ', num2str(length(swigglyIDs)), ' swiggly tracks from D6(', num2str(n), ')...'];
    disp(X)
    
    % remove structures based on row # (in reverse order)
    counter = 0;
    for q = 1:length(swigglyIDs)
        r = length(swigglyIDs) - counter;                                
        D6{n}(swigglyIDs(r)) = [];
        swigglyTracks(r,1) = D5{n}(swigglyIDs(r));   % recording to add into reject data matrix  
        counter = counter + 1;
    end
    
    % save tracks that are too swiggly into reject data matrix
    rejectD{5,n} = swigglyTracks;
    
    clear allRatios allTracks bottomTracks gainLossRatio swigglyIDs swigglyTracks q r i counter X; 
end

clear n gainLossRatio;


%% Saving results

save('t300_2017-01-16-autoTrimmed.mat', 'D', 'D2', 'D3', 'D4', 'D5', 'D6', 'rejectD', 'T')%, 'reader', 'ConversionFactor')


%% visualizing samples of data set

% -- criteria five, check
% select sample of tracks to visualize
bottomTracks = find(allRatios < 0.9);
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

for n = 34%:length(D6)
    for i = 1:length(D6{n})
        
        % designate subplot position
        subplot(ceil(length(D6{n})/5), 5, i)
        
        % plot
        plot(T{n}(D6{n}(i).Frame(1:end))/3600,(D6{n}(i).MajAx),'Linewidth',2)
        
        % label
        title(i);
        
    end
end

%% visualize any one single curve

%
plot(T{n}(D6{n}(i).Frame(1:end))/3600,(D6{n}(i).MajAx),'Linewidth',2)
        axis([0,10,0,15])



%% QUALITY CONTROL
%
%  Goal: manually examine length trajectories to ensure successful trimming
%  Approach: display trajectories for manual discard (if needed)
%
%
%  Step 1 - Plotting individual tracks from a series
%         - Choose to either accept or discard each track
%         

figure(1)

for n=31:40                                                                 % adjust n as needed!
    counter = 0;
    Delete = zeros(1,length(n));
    
    J = ['Click mouse to flag track for deletion'];
    disp(J);
    K = ['Hit keyboard to approve track'];
    disp(K);
    
    for m=1:length(D6{n})
        plot(T{n}(D6{n}(m).Frame(1:end))/3600,(D6{n}(m).MajAx),'Linewidth',2)
        axis([0,10,0,15])
        drawnow                                                             % displays current track m
        %pause()
        w = waitforbuttonpress;                                             % waits for user to approve or reject
        % mouse click = flags track for deletion (w = 0)
                                                                           % keyboard key = OK                      (w = 1) 
       if w == 0
           counter = counter + 1;
           Delete(counter) = m;                                            % saves track number for future removal
           X = ['Track ', num2str(m), ' of ', num2str(length(D6{n})), ' marked for deletion...'];
           disp(X);
       else
           disp('OK!');
       end
    end
    
    Rejects{n} = Delete;
    clear Delete m w X J K counter;
    save('2016-11-23-Rejects.mat', 'Rejects')                              % saves current Rejects after finishing each series
end                                                                        % both D5 and Rejects are saved for potential revisitation of removed data

clear n;

%% Quality control, continued...
%
%  Step 2 - Fine pass through Reject list to confirm deletion
%
%

figure(1)
for n=1:40                                                              % adjust n as needed!
    counter = 0;                                                           
    Confirmed = zeros(1,length(n));
    
    if Rejects{n} == 0
        continue
    end
    
    J = ['Click mouse to approve deletion'];
    disp(J);
    K = ['Hit keyboard to rescue track'];
    disp(K);
    
    
    for i=1:length(Rejects{n})                                             % number of tracks in Rejects piles
        m = Rejects{n}(i);

            plot(T{n}(D6{n}(m).Frame(1:end))/3600,(D6{n}(m).MajAx),'Linewidth',2)
            axis([0,11,0,15])
            %plot(T(D5{n}(m).Frame(1:end),n)/60,(D5{n}(m).MajAx),'color',[0,0,1]+(n-1)*[.05,.05,0],'Linewidth',2)
            %axis([0,1100,0,15])
            drawnow                                                             % displays current track m
            %pause()
            w = waitforbuttonpress;                                             % waits for user to approve or reject
            % mouse click = flags track for deletion (w = 0)
            % keyboard key = OK                      (w = 1)
            if w == 0
                counter = counter + 1;
                Confirmed(counter) = m;                                            % saves track number for future removal
                X = [ num2str(i), ' track of ', num2str(length(Rejects{n})), ' initial rejects confirmed for deletion...'];
                disp(X);
            else
                disp('Rescued!');
            end
            
        end
        Trash{n} = Confirmed;

    clear Confirmed m w X J K counter;
    save('2016-11-23-Rejects.mat', 'Rejects','Trash')
                                                                        % saves current Rejects after finishing each series
end                                                                        % both D5 and Rejects are saved for potential revisitation of removed data

clear n;

%% Quality control, continued... 
%
%  Step 3 - Removing flagged tracks from data set
%         - Delete based on track numbers saved in 'Rejects'
%
D6 = D6;
Trash = cellfun(@(x)x(logical(x)),Trash,'uni',false); 

for n = 1:length(D6);                                                       
    
    Remove = Trash(n);
    Remove = cell2mat(Remove);
               % replaces 0 with empty cells
    F = ['Removing ', num2str(length(Remove)), ' flagged tracks from D6(', num2str(n), ')...']; 
    disp(F)                                                         
                                                   
    counter = 0;
    for j = 1:length(Remove)
        k = length(Remove) - counter;                                      % remove structures based on row #
        D6{n}(Remove(k)) = [];                                             % remove in reverse order to avoid changing smaller positions
        counter = counter + 1;
    end
    clear j k F counter Remove;           
end
%clear n;
save('2016-11-21-trimmed.mat', 'D', 'D2', 'D3', 'D4', 'D5', 'D6', 'T')%, 'reader', 'ConversionFactor')