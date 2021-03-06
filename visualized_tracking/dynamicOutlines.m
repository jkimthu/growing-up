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


% last edit: jen, 2017 Nov 29

% OK LEZ GO!


%% Initialize experiment data

% 0. initialize data
clear
clc
experiment = '2017-11-12';


% TRACKING DATA
% open folder for experiment of interest
newFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',experiment);%,'  (t300)');
cd(newFolder);

% FROM DATA TRIMMER
% particle tracking data
clear
load('lb-fluc-2017-11-12-window5-width1p4-1p7-jiggle-0p5.mat');



%% Assemble all data from experiment

% build data matrix from fully trimmed data
survivorDM = buildDM(D5,M,M_va,T);

% build data matrix for each rejected track
totalDM = buildRejectDM(D,T);
reject1_DM = buildRejectDM(rejectD(1,:),T); % build Reject DM doesn't take M input
reject2_DM = buildRejectDM(rejectD(2,:),T);
reject3_DM = buildRejectDM(rejectD(3,:),T);
reject4_DM = buildRejectDM(rejectD(4,:),T);


%% Initialize image data

% movie (xy position) of interest
n = 10;
movieNum = 10; % in case different than n

img_prefix = strcat('lb-fluc-2017-11-12_xy', num2str(movieNum), 'T'); 
img_suffix = 'XY1C1.tif';

% open folder for images of interest (one xy position of experiment)
img_folder=strcat('xy', num2str(movieNum));
cd(img_folder);

% pixels to um 
conversionFactor = 6.5/60;      %  scope5 Andor COSMOS = 6.5um pixels / 60x magnification

% image names in chronological order
imgDirectory = dir('lb-fluc-2017-11-12_xy*.tif');
names = {imgDirectory.name};

% total frame number
finalFrame = length(imgDirectory);

clear img_folder img_prefix img_suffix experiment newFolder img_folder


%% 1. isolate ellipse data from movie (stage xy) of interest
% 
dm_survivors = survivorDM(survivorDM(:,31) == n,:);

dm_total = totalDM(totalDM(:,31) == n,:);
%dm_reject1 = reject1_DM(reject1_DM(:,31) == n,:);
dm_reject2 = reject2_DM(reject2_DM(:,31) == n,:);
dm_reject3 = reject3_DM(reject3_DM(:,31) == n,:);
dm_reject4 = reject4_DM(reject4_DM(:,31) == n,:);


%% when tracking all tracked cells, surviving AND trimmed

% 2. for all frames, assemble tracks present in each category
allTracks = unique(dm_total(:,1));

allData = [];

survivorTrackIDs = [];
rejectGroup1 = [];
rejectGroup2 = [];
rejectGroup3 = [];
rejectGroup4 = [];

for fr = 1:finalFrame
    
    % i. isolate data from each frame
    totals = dm_total(dm_total(:,30) == fr,:);
    
    survivors = dm_survivors(dm_survivors(:,30) == fr,:); % col 30 = frame #
    %reject1s = dm_reject1(dm_reject1(:,30) == fr,:);
    reject2s = dm_reject2(dm_reject2(:,30) == fr,:);
    reject3s = dm_reject3(dm_reject3(:,30) == fr,:);
    reject4s = dm_reject4(dm_reject4(:,30) == fr,:);

    
    allData{fr} = totals(:,1);
    
    survivorTrackIDs{fr} = survivors(:,1); % col 1 = TrackID
    %rejectGroup1{fr} = reject1s(:,1);
    rejectGroup2{fr} = reject2s(:,1);
    rejectGroup3{fr} = reject3s(:,1);
    rejectGroup4{fr} = reject4s(:,1);

    
end
clear fr;


% for each image
for img = 1:length(names)
    
    cla
    
    % 3. initialize current image
    I=imread(names{img});
    filename = strcat('dynamicOutlines-xy',num2str(movieNum),'-frame',num2str(img),'-n',num2str(n),'.tif');
    
    figure(1)
    % imtool(I), displays image in grayscale with range
    imshow(I, 'DisplayRange',[2000 14000]); %lowering right # increases num sat'd pxls
    
    
    % 3. if no particles to display, save and skip
    if isempty(allData{img}) == 1
        saveas(gcf,filename)
        
        continue
        
    else
        % 4. else, isolate data for each image
        dm_currentImage = dm_total(dm_total(:,30) == img,:); % col 30 = frame #
        
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
        
        
        % 5. for each particle of interest in current image, draw ellipse
        for p = 1:length(IDs)
            
            
            [x_rotated, y_rotated] = drawEllipse(p,majorAxes, minorAxes, centroid_X, centroid_Y, angles, conversionFactor);
            
            
            % i. if track number is a surivor track, plot outline with
            % color based on cell width
            
            if any(IDs(p) == survivorTrackIDs{img}) == 1
                
                hold on
                plot(x_rotated,y_rotated,'g','lineWidth',1)
                text((centroid_X(p)+2)/conversionFactor, (centroid_Y(p)+2)/conversionFactor, num2str(IDs(p)),'Color','g','FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                                
            end
            
%             if any(IDs(p) == rejectGroup1{img}) == 1
%                 
%                 hold on
%                 plot(x_rotated,y_rotated,'b','lineWidth',1)
%                 text((centroid_X(p)+2)/conversionFactor, (centroid_Y(p)+2)/conversionFactor, num2str(IDs(p)),'Color','b','FontSize',10);
%                 xlim([0 2048]);
%                 ylim([0 2048]);
%                 
%             end
            
            if any(IDs(p) == rejectGroup2{img}) == 1
                
                hold on
                plot(x_rotated,y_rotated,'Color',[0.5 0 0.5],'lineWidth',1)
                text((centroid_X(p)+3)/conversionFactor, (centroid_Y(p)+3)/conversionFactor, num2str(IDs(p)),'Color',[0.5 0 0.5],'FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                
            end
            
            if any(IDs(p) == rejectGroup3{img}) == 1
                
                hold on
                plot(x_rotated,y_rotated,'Color',[1 0.5 0],'lineWidth',1)
                text((centroid_X(p)+2)/conversionFactor, (centroid_Y(p)+2)/conversionFactor, num2str(IDs(p)),'Color',[1 0.5 0],'FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                
            end
            
            if any(IDs(p) == rejectGroup4{img}) == 1
                
                hold on
                plot(x_rotated,y_rotated,'r','lineWidth',1)
                text((centroid_X(p)+2)/conversionFactor, (centroid_Y(p)+2)/conversionFactor, num2str(IDs(p)),'Color','r','FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                
            end
            
        end
        
    end
    
    % 6. save
    saveas(gcf,filename)
    
end





%%
clearvars -except D D5 M T rejectD survivorDM totalDM reject2_DM reject3_DM reject4_DM



