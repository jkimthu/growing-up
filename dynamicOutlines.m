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


% last edit: jen, 2017 Jul 17

% OK LEZ GO!
%%

% 0. initialize data
clear
clc
experiment = '2017-01-16';


% TRACKING DATA
% open folder for experiment of interest
newFolder = strcat('/Users/jen/Documents/StockerLab/Data/',experiment,'  (t300)');
cd(newFolder);

% FROM DATA TRIMMER
% particle tracking data
clear
load('t300_2017-01-16-revisedTrimmer-jiggle0p3.mat','D7','D','T','rejectD');
%D = D_smash;



%%
% build data matrix from fully trimmed data
survivorDM = buildDM(D7,T);

% build data matrix for each rejected tracks
totalDM = buildDM(D,T);
%reject1_DM = buildDM(rejectD(1,:),T);
reject2_DM = buildDM(rejectD(2,:),T);
reject3_DM = buildDM(rejectD(3,:),T);
reject4_DM = buildDM(rejectD(4,:),T);
reject5_DM = buildDM(rejectD(5,:),T);
reject6_DM = buildDM(rejectD(6,:),T);

%%
% IMAGE DATA
% movie (xy position) of interest
n = 1;

img_prefix = strcat('t300_2017-01-16_xy', num2str(n), 'T'); 
img_suffix = 'XY1C1.tif';

% open folder for images of interest (one xy position of experiment)
img_folder=strcat('xy', num2str(n));
cd(img_folder);

% pixels to um 
conversionFactor = 6.5/60;      %  scope5 Andor COSMOS = 6.5um pixels / 60x magnification

% image names in chronological order
imgDirectory = dir('t300_2017-01-16_xy*.tif');
names = {imgDirectory.name};

% total frame number
finalFrame = length(imgDirectory);

clear img_folder img_prefix img_suffix experiment newFolder img_folder


%%
% 1. isolate ellipse data from movie (stage xy) of interest
dm_survivors = survivorDM(survivorDM(:,31) == n,:);

dm_total = totalDM(totalDM(:,31) == n,:);
%dm_reject1 = reject1_DM(reject1_DM(:,31) == n,:);
dm_reject2 = reject2_DM(reject2_DM(:,31) == n,:);
dm_reject3 = reject3_DM(reject3_DM(:,31) == n,:);
dm_reject4 = reject4_DM(reject4_DM(:,31) == n,:);
dm_reject5 = reject5_DM(reject5_DM(:,31) == n,:);
dm_reject6 = reject6_DM(reject6_DM(:,31) == n,:);

clear totalDM survivorDM reject1_DM reject2_DM reject3_DM reject4_DM reject5_DM reject6_DM
%%
% 2. for all frames, assemble tracks present in each category
allTracks = unique(dm_total(:,1));

allData = [];

survivorTrackIDs = [];
%rejectGroup1 = [];
rejectGroup3 = [];
rejectGroup4 = [];
rejectGroup6 = [];
rejectGroup_shorts =[];

for fr = 1:finalFrame
    
    % i. isolate data from each frame
    totals = dm_total(dm_total(:,30) == fr,:);
    
    survivors = dm_survivors(dm_survivors(:,30) == fr,:); % col 30 = frame #
    %reject1s = dm_reject1(dm_reject1(:,30) == fr,:);
    reject2s = dm_reject2(dm_reject2(:,30) == fr,:);
    reject3s = dm_reject3(dm_reject3(:,30) == fr,:);
    reject4s = dm_reject4(dm_reject4(:,30) == fr,:);
    reject5s = dm_reject5(dm_reject5(:,30) == fr,:);
    reject6s = dm_reject6(dm_reject6(:,30) == fr,:);
    
    allData{fr} = totals(:,1);
    
    survivorTrackIDs{fr} = survivors(:,1); % col 1 = TrackID
    %rejectGroup1{fr} = reject1s(:,1);
    rejectGroup3{fr} = reject3s(:,1);
    rejectGroup4{fr} = reject4s(:,1);
    rejectGroup6{fr} = reject6s(:,1);
    rejectGroup_shorts{fr} = [reject2s(:,1); reject5s(:,1)];
    
end
clear fr;


%%
% for each image
for img = 1:length(names)%max(interestingFrames)
    
    cla
    
    % 3. initialize current image
    I=imread(names{img});
    %filename = strcat('dynamicOutlines-frame',num2str(img),'-track',num2str(interestingTrack),'.tif');
    filename = strcat('dynamicOutlines-frame',num2str(img),'-n',num2str(n),'.tif');
    
    figure(1)
    imshow(I, 'DisplayRange',[4000 10000]);
    
    
    % 3. if no tracked cells (surivors NOR rejects), save and skip
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
           
            
            if any(IDs(p) == rejectGroup3{img}) == 1
                
                hold on
                plot(x_rotated,y_rotated,'r','lineWidth',1)
                text((centroid_X(p)-4)/conversionFactor, (centroid_Y(p)-4)/conversionFactor, num2str(IDs(p)),'Color','r','FontSize',12);
                xlim([0 2048]);
                ylim([0 2048]);
                
            end
            
            if any(IDs(p) == rejectGroup4{img}) == 1
                
                hold on
                plot(x_rotated,y_rotated,'Color',[1 0.5 0],'lineWidth',1)
                text((centroid_X(p)-5)/conversionFactor, (centroid_Y(p)-5)/conversionFactor, num2str(IDs(p)),'Color',[1 0.5 0],'FontSize',12);
                xlim([0 2048]);
                ylim([0 2048]);
                
            end
            
            if any(IDs(p) == rejectGroup6{img}) == 1
                
                hold on
                plot(x_rotated,y_rotated,'b','lineWidth',1)
                text((centroid_X(p)-3)/conversionFactor, (centroid_Y(p)-3)/conversionFactor, num2str(IDs(p)),'Color','b','FontSize',12);
                xlim([0 2048]);
                ylim([0 2048]);
                
            end

            if any(IDs(p) == rejectGroup_shorts{img}) == 1
                
                hold on
                plot(x_rotated,y_rotated,'Color',[0.5 0 0.5],'lineWidth',1)
                text((centroid_X(p)-2)/conversionFactor, (centroid_Y(p)-2)/conversionFactor, num2str(IDs(p)),'Color',[0.5 0 0.5],'FontSize',12);
                xlim([0 2048]);
                ylim([0 2048]);
                
            end
                        % i. if track number is a reject of nonDrops method, plot green
            if any(IDs(p) == survivorTrackIDs{img}) == 1
                
                hold on
                plot(x_rotated,y_rotated,'g','lineWidth',1)
                text((centroid_X(p)+4)/conversionFactor, (centroid_Y(p)+4)/conversionFactor, num2str(IDs(p)),'Color','g','FontSize',12);
                xlim([0 2048]);
                ylim([0 2048]);
                
            end
            
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


