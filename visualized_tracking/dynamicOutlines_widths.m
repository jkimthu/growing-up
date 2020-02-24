% dynamicOutlines

% Goal: this version of dynamic outlines displays colors based on width.
%       this version is not limited to full cell cycles.



% Strategy:
%
%     0. initialize tracking and image data
%     1. isolate ellipse data from movie (stage xy) of interest
%     2. identify tracks in rejects. all others are tracked.
%     3. for each image, initialize current image
%            4. define major axes, centroids, angles, growth rates
%            5. draw ellipses from image, color based on width

        %                       < 1 um = LightPink
        %                  1.0-1.19 um = Crimson
        %                  1.2-1.29 um = Goldenrod
        %                  1.3-1.39 um = SeaGreen
        %                  1.4-1.49 um = SlateBlue
        %                     1.5+  um = Indigo
        
%           6. display and save
%     7. woohoo!


% last edit: jen, 2018 May 7

% commit: making a pretty movie for image analysis visualizations


% OK LEZ GO!

%% Initialize experiment data

clc
clear



% 0. initialize complete meta data
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')


% 0. initialize experiment and xy movie to analyze
index = 22; % 2018-08-01
xy = 32;

% 1. collect experiment meta data
date = storedMetaData{index}.date;
expType = storedMetaData{index}.experimentType;



% 2. load measured data
experimentFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',date);
cd(experimentFolder)
%filename = strcat('lb-fluc-',date,'-c123-width1p4-c4-1p7-jiggle-0p5.mat');
filename = strcat('lb-fluc-',date,'-width1p7-jiggle-0p5.mat');
load(filename,'D5','T');

    
% 3. compile experiment data matrix
xy_start = xy;
xy_end = xy;
xyData = buildDM(D5, T, xy_start, xy_end, index, expType);
clear D5 T xy_start xy_end e



% 4. initialize image data
conversionFactor = 6.5/60;      % scope5 Andor COSMOS = 6.5um pixels / 60x magnification
%n = 40;                         % movie (xy position) of interest, in case different than xy
img_prefix = strcat('lb-fluc-',date,'_xy', num2str(xy), 'T'); 
img_suffix = 'XY1C1.tif';


% 5. open folder for images of interest (one xy position of experiment)
cd(experimentFolder)
if xy >= 10
    img_folder=strcat('xy', num2str(xy));
else
    img_folder=strcat('xy0', num2str(xy));
end
cd(img_folder);


% 6. create directory of image names in chronological order
%imgDirectory = dir(strcat('lb-fluc-',date,'_xy*.tif'));
imgDirectory = dir(strcat('singleupshift-',date,'_xy*.tif'));
names = {imgDirectory.name};
clear img_folder img_prefix img_suffix experiment newFolder img_folder


% 7. identify tracks present in each frame
totalFrames = length(imgDirectory); % total frame number
trackIDs = [];
for fr = 1:totalFrames
    
    %tracksInCurrentFrame = xyData_fullOnly(xyData_fullOnly(:,18) == fr,:);    % col 18 = frame #
    tracksInCurrentFrame = xyData(xyData(:,16) == fr,:);                % col 16 = frame #
    trackIDs{fr,1} = tracksInCurrentFrame(:,1);                         % col 1 = TrackID, as given by tracking script ND2Proc_XY

end
clear fr tracksInCurrentFrame

%%
% 9. overlay colored cell outlines over each image file
for img = 1:length(names)
    
    % i. initialize current image
    cla
    I=imread(names{img});
    %filename = strcat('dynamicOutlines-widths-fullOnly-xy',num2str(xy),'-frame',num2str(img),'-n',num2str(n),'.tif');
    filename = strcat('dynamicOutlines-widths-xy',num2str(xy),'-frame',num2str(img),'.tif');
    
    figure(1)
    % imtool(I), displays image in grayscale with range
    imshow(I, 'DisplayRange',[500 1600]); %lowering right # increases num sat'd pxls
    
    
    % ii. if no particles to display, save and skip
    if isempty(trackIDs{img}) == 1
        saveas(gcf,filename)
        continue
        
    else
        
        % iii. else when tracked lineages are present, isolate data for each image
        dm_currentImage = xyData(xyData(:,16) == img,:);    % col 16 = frame #
        
        majorAxes = getGrowthParameter(dm_currentImage,'length');         %  lengths
        minorAxes = getGrowthParameter(dm_currentImage,'width');          %  widths
        
        centroid_X = getGrowthParameter(dm_currentImage,'x_pos');          % x coordinate of centroid
        centroid_Y = getGrowthParameter(dm_currentImage,'y_pos');          % y coordinate of centroid
        angles = getGrowthParameter(dm_currentImage,'angle');             % angle of rotation of fit ellipses

        IDs = getGrowthParameter(dm_currentImage,'trackID');              % track ID as assigned in ND2Proc_XY
        
        
        
        % iv. for each particle of interest in current image,
        %     draw ellipse colored based on current width
        
        %                       < 1 um = LightPink
        %                  1.0-1.19 um = Crimson
        %                  1.2-1.29 um = Goldenrod
        %                  1.3-1.39 um = SeaGreen
        %                  1.4-1.49 um = SlateBlue
        %                     1.5+  um = Indigo
        
        
        for particle = 1:length(IDs)
            
            [x_rotated, y_rotated] = drawEllipse(particle,majorAxes, minorAxes, centroid_X, centroid_Y, angles, conversionFactor);
            lineVal = 0.5;
            
            
            % if track is not a full cell cycle (divTime = 0), color LightPink
            if minorAxes(particle) < 1
                
                color = rgb('LightPink');
                
                hold on
                plot(x_rotated,y_rotated,'Color',color,'lineWidth',lineVal)
                text((centroid_X(particle)+2)/conversionFactor, (centroid_Y(particle)+2)/conversionFactor, num2str(IDs(particle)),'Color',color,'FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                
            
            elseif minorAxes(particle) < 1.2
               
                color = rgb('Crimson');
                
                hold on
                plot(x_rotated,y_rotated,'Color',color,'lineWidth',lineVal)
                text((centroid_X(particle)+2)/conversionFactor, (centroid_Y(particle)+2)/conversionFactor, num2str(IDs(particle)),'Color',color,'FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                
            elseif minorAxes(particle) < 1.3 
                               
                color = rgb('Goldenrod');
                
                hold on
                plot(x_rotated,y_rotated,'Color',color,'lineWidth',lineVal)
                text((centroid_X(particle)+2)/conversionFactor, (centroid_Y(particle)+2)/conversionFactor, num2str(IDs(particle)),'Color',color,'FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                
            elseif minorAxes(particle) < 1.4 
                
                color = rgb('SeaGreen');
                
                hold on
                plot(x_rotated,y_rotated,'Color',color,'lineWidth',lineVal)
                text((centroid_X(particle)+2)/conversionFactor, (centroid_Y(particle)+2)/conversionFactor, num2str(IDs(particle)),'Color',color,'FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                
            elseif minorAxes(particle) < 1.5 
                
                color = rgb('SlateBlue');
                
                hold on
                plot(x_rotated,y_rotated,'Color',color,'lineWidth',lineVal)
                text((centroid_X(particle)+2)/conversionFactor, (centroid_Y(particle)+2)/conversionFactor, num2str(IDs(particle)),'Color',color,'FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                
            else % width greater than 1.5 um
                color = rgb('Indigo');
                
                hold on
                plot(x_rotated,y_rotated,'Color',color,'lineWidth',lineVal)
                text((centroid_X(particle)+2)/conversionFactor, (centroid_Y(particle)+2)/conversionFactor, num2str(IDs(particle)),'Color',color,'FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                                
            end
            
        end
        
    end
    title(num2str(img))
    
    % 6. save
    saveas(gcf,filename)
    
end



%%
clearvars -except D D5 M T rejectD survivorDM totalDM reject2_DM reject3_DM reject4_DM



