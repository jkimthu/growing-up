% dynamicOutlines

% Goal: this version of dynamic outlines highlights which cells have a
%       measured interdivision time of 20 min or less. colors indicate
%       exactly how short the cell cycle was.


% Strategy:
%
%     0. initialize tracking and image data
%     1. isolate ellipse data from movie (stage xy) of interest
%     2. identify tracks in rejects. all others are tracked.
%     3. for each image, initialize current image
%            4. define major axes, centroids, angles, growth rates
%            5. draw ellipses from image, color based on interdivision time
%                       0 min = LightPink
%                     1-5 min = Crimson
%                    6-10 min = Goldenrod
%                   11-15 min = SeaGreen
%                   16-20 min = SlateBlue
%                     20+ min = Indigo
%           6. display and save
%     7. woohoo!


% last edit: jen, 2018 Mar 29
% commit: visualize tracked lineages, with colors to indicate those with interdivision times =< 20 min
%         last used to visualize xy 10, 20, 30 and 40 from 2018-02-01


% OK LEZ GO!

%% Initialize experiment data

clc
clear

% 0. initialize complete meta data
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')
dataIndex = find(~cellfun(@isempty,storedMetaData));


% 0. initialize experiment and xy movie to analyze
e = 14;
xy = 40;

% 1. collect experiment meta data
index = dataIndex(e);
date = storedMetaData{index}.date;


% 2. load measured data
experimentFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',date);
cd(experimentFolder)
filename = strcat('lb-fluc-',date,'-window5-width1p4-1p7-jiggle-0p5.mat');
load(filename,'D5','M','M_va','T');

    
% 3. compile experiment data matrix
xy_start = xy;
xy_end = xy;
xyData = buildDM(D5, M, M_va, T, xy_start, xy_end,e);
clear D5 M M_va T xy_start xy_end e


% 4. trim dm to only include particles with interdiv times =< 20 min
%interdivisionTime = xyData(:,8)/60;   % col 8 = curve duration, sec converted to min
%shortDivData = xyData(interdivisionTime <= 20,:); 
%clear interdivisionTime


% 5. initialize image data
conversionFactor = 6.5/60;      % scope5 Andor COSMOS = 6.5um pixels / 60x magnification
n = 40;                         % movie (xy position) of interest, in case different than xy
img_prefix = strcat('lb-fluc-',date,'_xy', num2str(xy), 'T'); 
img_suffix = 'XY1C1.tif';


% 6. open folder for images of interest (one xy position of experiment)
img_folder=strcat('xy', num2str(xy));
cd(img_folder);


% 7. create directory of image names in chronological order
imgDirectory = dir(strcat('lb-fluc-',date,'_xy*.tif'));
names = {imgDirectory.name};
clear img_folder img_prefix img_suffix experiment newFolder img_folder


% 8. identify tracks present in each frame
totalFrames = length(imgDirectory); % total frame number
trackIDs = [];
for fr = 1:totalFrames
    
    tracksInCurrentFrame = xyData(xyData(:,18) == fr,:);    % col 18 = frame #
    trackIDs{fr,1} = tracksInCurrentFrame(:,1);                         % col 1 = TrackID, as given by tracking script ND2Proc_XY

end
clear fr tracksInCurrentFrame

%%
% 9. overlay colored cell outlines over each image file
for img = 1:length(names)
    
    % i. initialize current image
    cla
    I=imread(names{img});
    filename = strcat('dynamicOutlines-xy',num2str(xy),'-frame',num2str(img),'-n',num2str(n),'.tif');
    
    figure(1)
    % imtool(I), displays image in grayscale with range
    imshow(I, 'DisplayRange',[2000 6000]); %lowering right # increases num sat'd pxls
    
    
    % ii. if no particles to display, save and skip
    if isempty(trackIDs{img}) == 1
        saveas(gcf,filename)
        continue
        
    else
        % iii. else when tracked lineages are present, isolate data for each image
        dm_currentImage = xyData(xyData(:,18) == img,:);    % col 18 = frame #
        
        majorAxes = dm_currentImage(:,3);           %  col 3 = lengths
        minorAxes = dm_currentImage(:,11);          % col 11 = widths
        
        centroid_X = dm_currentImage(:,16);         % col 16 = x coordinate of centroid
        centroid_Y = dm_currentImage(:,17);         % col 17 = y coordinate of centroid
        angles = dm_currentImage(:,21);             % col 21 = angle of rotation of fit ellipses

        IDs = dm_currentImage(:,1);                 % col 1 = track ID as assigned in ND2Proc_XY
        shortDivTimes = dm_currentImage(:,8)/60;    % col 8 = curve duration, converted from sec to min
        
        
        % iv. for each particle of interest in current image,
        %     draw ellipse colored based on interdivision time
       
        %                       0 min = LightPink  (bin 0)
        %                     < 5 min = Crimson    (bin 1)
        %                    < 10 min = Goldenrod  (bin 2)
        %                    < 15 min = SeaGreen   (bin 3)
        %                   <= 20 min = SlateBlue  (bin 4)
        %                    > 20 min = Indigo     (bin 5)
         
        for particle = 1:length(IDs)
            
            [x_rotated, y_rotated] = drawEllipse(particle,majorAxes, minorAxes, centroid_X, centroid_Y, angles, conversionFactor);
            lineVal = 2;
            
            % if track is not a full cell cycle (divTime = 0), color LightPink
            if shortDivTimes(particle) == 0
                
                color = rgb('LightPink');
                
                hold on
                plot(x_rotated,y_rotated,'Color',color,'lineWidth',lineVal)
                text((centroid_X(particle)+2)/conversionFactor, (centroid_Y(particle)+2)/conversionFactor, num2str(IDs(particle)),'Color',color,'FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                
            
            elseif shortDivTimes(particle) <= 5
               
                color = rgb('Crimson');
                
                hold on
                plot(x_rotated,y_rotated,'Color',color,'lineWidth',lineVal)
                text((centroid_X(particle)+2)/conversionFactor, (centroid_Y(particle)+2)/conversionFactor, num2str(IDs(particle)),'Color',color,'FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                
            elseif shortDivTimes(particle) <= 10 
                               
                color = rgb('Goldenrod');
                
                hold on
                plot(x_rotated,y_rotated,'Color',color,'lineWidth',lineVal)
                text((centroid_X(particle)+2)/conversionFactor, (centroid_Y(particle)+2)/conversionFactor, num2str(IDs(particle)),'Color',color,'FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                
            elseif shortDivTimes(particle) <= 15 
                
                color = rgb('SeaGreen');
                
                hold on
                plot(x_rotated,y_rotated,'Color',color,'lineWidth',lineVal)
                text((centroid_X(particle)+2)/conversionFactor, (centroid_Y(particle)+2)/conversionFactor, num2str(IDs(particle)),'Color',color,'FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                
            elseif shortDivTimes(particle) <= 20 
                
                color = rgb('SlateBlue');
                
                hold on
                plot(x_rotated,y_rotated,'Color',color,'lineWidth',lineVal)
                text((centroid_X(particle)+2)/conversionFactor, (centroid_Y(particle)+2)/conversionFactor, num2str(IDs(particle)),'Color',color,'FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                
            else % longer than 20 min
                color = rgb('Indigo');
                
                hold on
                plot(x_rotated,y_rotated,'Color',color,'lineWidth',1)
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



