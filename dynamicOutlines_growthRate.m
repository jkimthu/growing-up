% dynamicOutlines

% Goal: this version of dynamic outlines displays colors based on large changes in growth rate.


% Strategy:
%
%     0. initialize tracking and image data
%     1. isolate ellipse data from movie (stage xy) of interest
%     2. identify tracks in rejects. all others are tracked.
%     3. for each image, initialize current image
%            4. define major axes, centroids, angles, growth rates
%            5. draw ellipses from image, color based on sign of growth rate
%
%                  large jump > x             = Crimson
%                  -x < chillin' < x          = SeaGreen
%                  large drop < -x            = MidnightBlue
%   
%                  note: x values are magnitude change in growth rate (1/hr),
%                        not change as a fraction of previous.                       
%           6. display and save
%     7. woohoo!


% last edit: jen, 2018 October 24

% commit: visualize changes in growth rate over 3


% OK LEZ GO!

%% Initialize experiment data

clc
clear


% 0. initialize definition of "large"
sigma = 0.3;
numSig = 10; % # standard deviations away from mean


% 0. initialize complete meta data
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')


% 0. initialize experiment and xy movie to analyze
index = 21; % 2018-06-15, first single upshift
xy = 1;

% 1. collect experiment meta data
date = storedMetaData{index}.date;
expType = storedMetaData{index}.experimentType;


% 2. load measured data
experimentFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',date);
cd(experimentFolder)
filename = strcat('lb-fluc-',date,'-width1p7-jiggle-0p5.mat');
load(filename,'D5','T');

    
% 3. compile experiment data matrix
xy_start = xy;
xy_end = xy;
xyData = buildDM(D5, T, xy_start, xy_end, index, expType);
clear D5T xy_start xy_end 



% 5. initialize image data
conversionFactor = 6.5/60;      % scope5 Andor COSMOS = 6.5um pixels / 60x magnification
%n = 40;                         % movie (xy position) of interest, in case different than xy
img_prefix = strcat('lb-fluc-',date,'_xy', num2str(xy), 'T'); 
img_suffix = 'XY1C1.tif';


% 6. open folder for images of interest (one xy position of experiment)
cd(experimentFolder)
if xy >10
    img_folder=strcat('xy', num2str(xy));
else
    img_folder=strcat('xy0', num2str(xy));
end
cd(img_folder);


% 7. create directory of image names in chronological order
imgDirectory = dir(strcat('lb-fluc-',date,'_xy*.tif'));
names = {imgDirectory.name};
clear img_folder img_prefix img_suffix experiment newFolder img_folder


% 8. identify tracks present in each frame
totalFrames = length(imgDirectory); % total frame number
trackIDs = [];
for fr = 1:totalFrames
    
    %tracksInCurrentFrame = xyData_fullOnly(xyData_fullOnly(:,18) == fr,:);    % col 18 = frame #
    tracksInCurrentFrame = xyData(xyData(:,16) == fr,:);    % col 16 = frame #
    trackIDs{fr,1} = tracksInCurrentFrame(:,1);             % col 1 = TrackID, as given by tracking script ND2Proc_XY

end
clear fr tracksInCurrentFrame totalFrames

%% CALCULATE GROWTH RATES

% 9. isolate volume (Va), timestamp, mu, drop and curveID data
volumes = xyData(:,11);        % col 11 = calculated va_vals (cubic um)
timestamps_sec = xyData(:,2);  % col 2  = timestamp in seconds
isDrop = xyData(:,4);          % col 4  = isDrop, 1 marks a birth event
curveFinder = xyData(:,5);     % col 5  = curve finder (ID of curve in condition)
trackNum = xyData(:,20);       % col 20 = track number (not ID from particle tracking)



% 8. calculate growth rate
growthRates_all = calculateGrowthRate(volumes,timestamps_sec,isDrop,curveFinder,trackNum);
growthRates = growthRates_all(:,3);
clear curveFinder isDrop volumes trackNum timestamps_sec growthRates_all

%%
% 11. overlay colored cell outlines over each image file
for img = 85:120%length(names) % skip first image because growth rate will not exist
                          % skip second image because diff in growth rate will not exist
    
    % i. initialize current image
    cla
    I=imread(names{img});
    %filename = strcat('dynamicOutlines-widths-fullOnly-xy',num2str(xy),'-frame',num2str(img),'-n',num2str(n),'.tif');
    filename = strcat('dynamicOutlines-negatives-xy',num2str(xy),'-frame',num2str(img),'.tif');
    
    figure(1)
    % imtool(I), displays image in grayscale with range
    imshow(I, 'DisplayRange',[2000 4000]); %lowering right # increases num sat'd pxls
    
    
    % ii. if no particles to display, save and skip
    if isempty(trackIDs{img}) == 1
        saveas(gcf,filename)
        continue
        
    else
        % iii. else when tracked lineages are present, isolate data for each image
        dm_currentImage = xyData(xyData(:,16) == img,:);    % col 16 = frame #
        
        growthRates_change = [NaN; diff(growthRates)];
        growthRates_change_currentImage = growthRates_change(xyData(:,16) == img);
        
        majorAxes = dm_currentImage(:,3);           % col 3 = lengths
        minorAxes = dm_currentImage(:,10);          % col 10 = widths
        
        centroid_X = dm_currentImage(:,14);         % col 14 = x coordinate of centroid
        centroid_Y = dm_currentImage(:,15);         % col 15 = y coordinate of centroid
        angles = dm_currentImage(:,19);             % col 19 = angle of rotation of fit ellipses

        IDs = dm_currentImage(:,1);                 % col 1 = track ID as assigned in ND2Proc_XY
        
        
        
        % iv. for each particle of interest in current image,
        %     draw ellipse colored based on current growth rate (1/hr)
        %                  positive big change = Crimson
        %                  not much change     = SeaGreen
        %                  negative big change = MidnightBlue
  
        
        for particle = 1:length(IDs) 
            
            [x_rotated, y_rotated] = drawEllipse(particle,majorAxes, minorAxes, centroid_X, centroid_Y, angles, conversionFactor);
            lineVal = 1;
            
            % if very large growth rate jump
            if growthRates_change_currentImage(particle) > (sigma * numSig)
                
                color = rgb('Crimson');
                
                hold on
                plot(x_rotated,y_rotated,'Color',color,'lineWidth',lineVal)
                text((centroid_X(particle)+2)/conversionFactor, (centroid_Y(particle)+2)/conversionFactor, num2str(IDs(particle)),'Color',color,'FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                
                         
            % if very large growth rate drop
            elseif growthRates_change_currentImage(particle) < (-sigma * numSig)
                
                color = rgb('MidnightBlue');
                
                hold on
                plot(x_rotated,y_rotated,'Color',color,'lineWidth',lineVal)
                text((centroid_X(particle)+2)/conversionFactor, (centroid_Y(particle)+2)/conversionFactor, num2str(IDs(particle)),'Color',color,'FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                
                
            % if not a big deal...
            else
                
                color = rgb('SeaGreen');
                
                hold on
                plot(x_rotated,y_rotated,'Color',color,'lineWidth',lineVal)
                text((centroid_X(particle)+2)/conversionFactor, (centroid_Y(particle)+2)/conversionFactor, num2str(IDs(particle)),'Color',color,'FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                
            end
        end
            
        
    end
    title(num2str(img))
    
    % 12. save
    saveas(gcf,filename)
    
end



%%
clearvars -except D D5 T



