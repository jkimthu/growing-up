% dynamicOutlines

% Goal: this script overlays data onto images, such that we can see the
%       results of current image analysis parameters

% Strategy:
%           0. initialize tracking and image data
%           1. isolate ellipse data from movie (stage xy) of interest
%           2. identify tracks in rejects. all others are tracked.
%           3. for each image, initialize current image
%                   4. define major axes, centroids, angles, growth rates
%                   5. draw ellipses from image, color based on tracked vs trimmed:
%                           i. if track number is found in reject list,
%                              color red
%                          ii. else, color green
%                   6. display and save
%           7. woohoo!


% last edit: jen, 2017 Jul 5

% OK LEZ GO!
%%

% 0. initialize data
clear
clc
experiment = '2017-06-12';


% TRACKING DATA
% open folder for experiment of interest
newFolder = strcat('/Users/jen/Documents/StockerLab/Data/',experiment);
cd(newFolder);

% FROM DATA TRIMMER
% particle tracking data
clear
load('letstry-2017-06-12-dSmash.mat');
D = D_smash;

% reject data matrix
%rejectD = cell(5,length(D));

% criteria counter
%criteria_counter = 0;



%%
% build data matrix from current data
dataMatrix = buildDM(D,T);

%%
% IMAGE DATA
% movie (xy position) of interest
n = 1;

img_prefix = strcat('letstry-2017-06-12_xy', num2str(n), 'T'); 
img_suffix = 'XY1C1.tif';

% open folder for images of interest (one xy position of experiment)
img_folder=strcat('xy', num2str(n));
cd(img_folder);

% pixels to um 
conversionFactor = 6.5/60;      %  scope5 Andor COSMOS = 6.5um pixels / 60x magnification

% image names in chronological order
imgDirectory = dir('letstry-2017-06-12_xy*.tif');
names = {imgDirectory.name};

% total frame number
finalFrame = length(imgDirectory);

clear img_folder img_prefix img_suffix experiment newFolder img_folder


%%
% 1. isolate ellipse data from movie (stage xy) of interest
dm_currentMovie = dataMatrix(dataMatrix(:,31) == n,:);


%%
% 2. assemble SIGN data
D4 = D;

% i. initialize threshold ratio, below which tracks are removed
gainLossRatio = 0.85;

for m = 1:length(D4{n})
    
    % ii. determine change in length between each timestep
    Signs = diff(D4{n}(m).MajAx);
    
    
    % iii. minute res is so noisy. average this derivative over every 10 timesteps
    sampleLength = floor( length(Signs)/10 ) * 10;
    Signs = mean(reshape(Signs(1:sampleLength),10,[]))';
    
    
    % iv. determine ratio of negatives to positives
    Signs(Signs<0) = 0;
    Signs(Signs>0) = 1;
    trackRatio = sum(Signs)/length(Signs);
    
    % v. store ratios from all tracks to reference during removal
    allRatios(m,1) = trackRatio;
    
    clear Signs trackRatio sampleLength;
end


% vi. determine which tracks in current movie fall below threshold
swigglyIDs = find(allRatios < 0.85);

% vii. report!
X = ['Removing ', num2str(length(swigglyIDs)), ' swiggly tracks from D4(', num2str(n), ')...'];
disp(X)

% viii. remove structures based on row # (in reverse order)
swiggle_counter = 0;
for q = 1:length(swigglyIDs)
    
    r = length(swigglyIDs) - swiggle_counter;   % reverse order
    D4{n}(swigglyIDs(r)) = [];                  % deletes data
    swigglyTracks(r,1) = D{n}(swigglyIDs(r));   % store data for reject data matrix
    swiggle_counter = swiggle_counter + 1;
    
end

% ix. save tracks that are too swiggly into reject data matrix
rejectD = swigglyTracks;

clear allRatios allTracks bottomTracks gainLossRatio swigglyIDs swigglyTracks q r m swiggle_counter X;

%%
% 3. assemble nonDrop data
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

belowThreshold = find(nonDropRatio < -0.1);

clear nonDropRatio lengthTrack diffTrack dropTrack nonDropNegs squiggleFactor binaryTrack

%%
% 3. define interesting TracksIDs associated with either method

% i. sign method
data = rejectD;
sign_IDs = [];

for i = 1:length(data)

    trackIDs = unique(data(i).TrackID);
    sign_IDs = [sign_IDs; trackIDs];

end
clear trackIDs i m data;

% ii. nonDrop method

data = D{n}(belowThreshold);
nonDrop_IDs = [];

for i = 1:length(data)
    
    trackIDs = unique(data(i).TrackID);
    nonDrop_IDs = [nonDrop_IDs; trackIDs];
    
end
clear trackIDs i data;
%%
% 4. seperate IDs into:
%           i. only rejected in Signs
%          ii. only rejected nonDrop
%         iii. rejected by both
%          iv. all tracks

% iii. rejected by both
overLap = intersect(sign_IDs, nonDrop_IDs);

% i. only rejected in Signs
onlySigns = setdiff(sign_IDs, overLap);

% ii. only rejected nonDrop
onlyNonDrops = setdiff(nonDrop_IDs, overLap);

% iv. all tracks
interestingTrackIDs = [overLap; onlySigns; onlyNonDrops];



%%

% for each image
for img = 1:length(names)%max(interestingFrames)
    
    cla
    
    % 3. initialize current image
    I=imread(names{img});
    %filename = strcat('dynamicOutlines-frame',num2str(img),'-track',num2str(interestingTrack),'.tif');
    filename = strcat('dynamicOutlines-frame',num2str(img),'-n52-signVsswiggle.tif');
    
    figure(1)
    imshow(I, 'DisplayRange',[3200 7400]);
    
    
    % 3. if no tracked cells, save and skip
    if sum(dm_currentMovie(:,30) == img) == 0 % tallies up # tracks in current img
        saveas(gcf,filename)
        
        continue
        
    else
        % 4. else, isolate data for each image
        dm_currentImage = dm_currentMovie(dm_currentMovie(:,30) == img,:); % col 30 = frame #
        
        % axes
        majorAxes = dm_currentImage(:,3); % lengths
        minorAxes = dm_currentImage(:,12); % widths
        
        % centroids
        centroid_X = dm_currentImage(:,28);
        centroid_Y = dm_currentImage(:,29);
        
        % angles
        angles = dm_currentImage(:,33);
        
        % growth rates (mu)
        mus = dm_currentImage(:,18); % mu calculated from Va
        
        % frames
        frames = dm_currentImage(:,30);
        
        % trackIDs
        IDs = dm_currentImage(:,1);
        
        
        % 4. isolate specific trackIDs of interest from current image
        targets = ismember(IDs, interestingTrackIDs);
        targets = find(targets == 1);
        targetIDs = IDs(targets);
        % axes
        majorAxes = dm_currentImage(targets,3); % lengths
        minorAxes = dm_currentImage(targets,12); % widths
        
        % centroids
        centroid_X = dm_currentImage(targets,28);
        centroid_Y = dm_currentImage(targets,29);
        
        % angles
        angles = dm_currentImage(targets,33);
        
        % growth rates (mu)
        mus = dm_currentImage(targets,18); % mu calculated from Va
        
        % frames
        frames = dm_currentImage(targets,30);
        
        
        
        
        % 5. for each particle of interest in current image, draw ellipse
        for p = 1:length(majorAxes)
            
            
            [x_rotated, y_rotated] = drawEllipse(p,majorAxes, minorAxes, centroid_X, centroid_Y, angles, conversionFactor);
            
            % i. if track number is a reject of nonDrops method, plot green
            if any(IDs(p) == onlyNonDrops) == 1
                
                hold on
                plot(x_rotated,y_rotated,'g','lineWidth',1)
                text((centroid_X(p)-5)/conversionFactor, (centroid_Y(p)-5)/conversionFactor, num2str(targetIDs(p)),'Color','g','FontSize',14);
                xlim([0 2048]);
                ylim([0 2048]);
                
                % ii. if track number is a reject of both methods, plot red
            elseif any(IDs(p)== overLap) == 1
                
                hold on
                plot(x_rotated,y_rotated,'r','lineWidth',1)
                text((centroid_X(p)-5)/conversionFactor, (centroid_Y(p)-5)/conversionFactor, num2str(targetIDs(p)),'Color','r','FontSize',14);
                xlim([0 2048]);
                ylim([0 2048]);
                
            end
            
            
            
            %             % i. if track number is a reject of nonDrops method, plot green
            %             if any(intersect(IDs(p),onlyNonDrops)) == 1
            %
            %                 hold on
            %                 plot(x_rotated,y_rotated,'g','lineWidth',1)
            %                 text((centroid_X(p)-5)/conversionFactor, (centroid_Y(p)-5)/conversionFactor, num2str(targetIDs(p)),'Color','g','FontSize',14);
            %                 xlim([0 2048]);
            %                 ylim([0 2048]);
            %
            %             % ii. if track number is a reject of signs method, plot red
            %             elseif any(intersect(IDs(p), onlySigns)) == 1
            %
            %                 hold on
            %                 plot(x_rotated,y_rotated,'r','lineWidth',1)
            %                 text((centroid_X(p)-5)/conversionFactor, (centroid_Y(p)-5)/conversionFactor, num2str(targetIDs(p)),'Color','r','FontSize',14);
            %                 xlim([0 2048]);
            %                 ylim([0 2048]);
            %
            %             % iii. if track number is rejected in both methods, plot
            %             elseif any(intersect(IDs(p), overLap)) == 1
            %
            %                 hold on
            %                 plot(x_rotated,y_rotated,'o','lineWidth',1)
            %                 text((centroid_X(p)-5)/conversionFactor, (centroid_Y(p)-5)/conversionFactor, num2str(targetIDs(p)),'Color','w','FontSize',14);
            %                 xlim([0 2048]);
            %                 ylim([0 2048]);
            %
            %             end
            %
        end
        
        % 6. save
        saveas(gcf,filename)
        
    end
end








%%
% I2 = imadjust(I);
% figure(2)
% inshow(I2)


%figure(2)
%I2=imshow(flipud(names{i}), 'DisplayRange',[3200 7400]);

%set(gca,'Ydir','Normal')


