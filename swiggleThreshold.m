%% squiggleThreshold.m


% Goal: this script visualizes the tracks suriving and rejected by the
%       "squiggle threshold" - a threshold intended to filture out junk
%       tracks from particle tracking data.
%
%       the initial issue, which leads to this separate testing script
%       here, was that fast growing but otherwise perfect tracks (LB)
%       were getting discarded under the following criteria:

%       1. gainLossRatio = 0.85
%       2. ratio calculated from change in size, diff(length),
%          time-averaged across 10 frames (10 diffs)
%       3. 





% last edit: jen, 2017 Jul 5

% OK LEZ GO!



%% initialize

% particle tracking data
clear
load('letstry-2017-06-12-dSmash.mat');
D = D_smash;

% reject data matrix
rejectD = cell(6,length(D));

%%

for n = 1 %:length(D6)
    %counter = counter +1;
    
    subplot_counter = 0;
    for i = 61:80%length(D6{n})
        
        subplot_counter = subplot_counter + 1;
        % designate subplot position
        %subplot(ceil(length(D6{n})/5), 5, i)
        subplot(ceil(20/5), 5, subplot_counter)
        
        % plot
        %figure(counter)
        plot(T{n}(D{n}(i).Frame(1:end))/3600,(D{n}(i).MajAx),'Linewidth',2)
        
        % label
        title(i);
        
    end
end


%%

% 0. initiaize new dataset before trimming
slowData = D{1};
fastData = D{52};

%%
i = 200;
figure(1)
plot(slowData(i).MajAx)
uni_slow = unique(slowData(i).TrackID)
slowIDs = slowData(i).TrackID;

figure(2)
plot(fastData(i).MajAx)
uni_fast = unique(fastData(i).TrackID)
fastIDs = fastData(i).TrackID;

%%
% new scheme: are most negatives drops?

% 1. for each track,
%       2. find change in length between frames
%       3. convert change into binary, where positives = 0 and negatives = 1
%       4. find all drops (negaitves that exceed drop threshold)
%       5. find the ratio of non-drop negatives per track length
%       6. store ratio for subsequent removal
%
for n = 1:length(D)
    
    nonDropRatio = NaN(length(D{n}),1);
    dropThreshold = -0.75;
    
    
    for m = 1:length(D{n})
        
        % 1. isolate length data from current track
        lengthTrack = D{n}(m).MajAx;
        
        % 2. find change in length between frames
        diffTrack = diff(lengthTrack);
        
        % 3. convert change into binary, where positives = 0 and negatives = 1
        binaryTrack = logical(diffTrack < 0);
        
        % 4. find all drops (negatives that exceed drop threshold)
        dropTrack = diffTrack < dropThreshold;
        
        % 5. find the ratio of non-drop negatives per track length
        nonDropNegs = sum(dropTrack - binaryTrack);
        squiggleFactor = nonDropNegs/length(lengthTrack);
        
        
        nonDropRatio(m) = squiggleFactor;
        
    end
    
    belowThreshold{n} = find(nonDropRatio < -0.1);
    total2Trim(n) = length(belowThreshold{n});
    
    clear nonDropRatio lengthTrack diffTrack dropTrack nonDropNegs squiggleFactor
end

%%
% find TrackIDs of removed tracks from both methods:

% method 1. SIGNS
data = rejectD{1,1};
signs_IDs_slow = [];

for i = 1:length(data)

    trackIDs = unique(data(i).TrackID);
    signs_IDs_slow = [signs_IDs_slow; trackIDs];

end

data = rejectD{1,52};
signs_IDs_fast = [];

for i = 1:length(data)

    trackIDs = unique(data(i).TrackID);
    signs_IDs_fast = [signs_IDs_fast; trackIDs];

end

%%
% method 2. NONDROPS
nonDrop_IDs_slow = [];
data = belowThreshold{1,1};

for i = 1:length(data)
    
    trackIDs = unique(D{1}(data(i)).TrackID);
    nonDrop_IDs_slow = [nonDrop_IDs_slow; trackIDs];
    
end

nonDrop_IDs_fast = [];
data = belowThreshold{1,52};

for i = 1:length(data)
    
    trackIDs = unique(D{52}(data(i)).TrackID);
    nonDrop_IDs_fast = [nonDrop_IDs_fast; trackIDs];
    
end
%%
% build vectors of IDs in only Signs, only NonDrops, and both

% find IDs rejected in both methods, without repetitions
overLap_slow = intersect(signs_IDs_slow, nonDrop_IDs_slow);
overLap_fast = intersect(signs_IDs_fast, nonDrop_IDs_fast);

% find all unque
unique_rejectIDs_slow = unique([signs_IDs_slow; nonDrop_IDs_slow]);
unique_rejectIDs_fast = unique([signs_IDs_fast; nonDrop_IDs_fast]);

% find IDs ONLY in Signs
rows2keep = find(~ismember(signs_IDs_slow, overLap_slow));
onlySigns_slow = signs_IDs_slow(rows2keep);

rows2keep = find(~ismember(signs_IDs_fast, overLap_fast));
onlySigns_fast = signs_IDs_fast(rows2keep);


% find IDs ONLY in nonDrops
rows2keep = find(~ismember(nonDrop_IDs_slow, overLap_slow));
onlyNonDrops_slow = nonDrop_IDs_slow(rows2keep);

rows2keep = find(~ismember(nonDrop_IDs_fast, overLap_fast));
onlyNonDrops_fast = nonDrop_IDs_fast(rows2keep);


