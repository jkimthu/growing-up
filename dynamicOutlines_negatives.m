% dynamicOutlines

% Goal: this version of dynamic outlines displays colors based on (+) or (-) growth rate.


% Strategy:
%
%     0. initialize tracking and image data
%     1. isolate ellipse data from movie (stage xy) of interest
%     2. identify tracks in rejects. all others are tracked.
%     3. for each image, initialize current image
%            4. define major axes, centroids, angles, growth rates
%            5. draw ellipses from image, color based on sign of growth rate
%                  negative = Crimson
%                  positive = SeaGreen
%                      zero = MidnightBlue
%           6. display and save
%     7. woohoo!


% last edit: jen, 2018 Jul 12

% commit: this version is not limited to full cell cycles


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
xy = 30;

% 1. collect experiment meta data
index = dataIndex(e);
date = storedMetaData{index}.date;


% 2. load measured data
experimentFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',date);
cd(experimentFolder)
filename = strcat('lb-fluc-',date,'-window5-width1p4-1p7-jiggle-0p5.mat');
load(filename,'D5','M','M_va','T','rejectD');

    
% 3. compile experiment data matrix
xy_start = xy;
xy_end = xy;
xyData = buildDM(D5, M, M_va, T, xy_start, xy_end,e);
clear D5 M M_va T xy_start xy_end e


% % 4. isolate condition data to those with full cell cycles
% curveIDs = xyData(:,6);                         % col 6 = curve ID
% xyData_fullOnly = xyData(curveIDs > 0,:);
% clear curveFinder


% 5. initialize image data
conversionFactor = 6.5/60;      % scope5 Andor COSMOS = 6.5um pixels / 60x magnification
%n = 40;                         % movie (xy position) of interest, in case different than xy
img_prefix = strcat('lb-fluc-',date,'_xy', num2str(xy), 'T'); 
img_suffix = 'XY1C1.tif';


% 6. open folder for images of interest (one xy position of experiment)
cd(experimentFolder)
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
    
    %tracksInCurrentFrame = xyData_fullOnly(xyData_fullOnly(:,18) == fr,:);    % col 18 = frame #
    tracksInCurrentFrame = xyData(xyData(:,18) == fr,:);    % col 18 = frame #
    trackIDs{fr,1} = tracksInCurrentFrame(:,1);                         % col 1 = TrackID, as given by tracking script ND2Proc_XY

end
clear fr tracksInCurrentFrame

%% CALCULATE GROWTH RATES

% 9. isolate volume (Va) and timestamp data
volumes = xyData(:,12);        % col 12 = calculated va_vals (cubic um)
timestamps_sec = xyData(:,2);  % col 2  = timestamp in seconds
isDrop = xyData(:,5);          % col 5  = isDrop, 1 marks a birth event
curveFinder = xyData(:,6);     % col 6  = curve finder (ID of curve in condition)


% 10. calculate mean timestep and dVdt
curveIDs = unique(curveFinder);
firstFullCurve = curveIDs(2);
if length(firstFullCurve) > 1
    firstFullCurve_timestamps = timestamps_sec(curveFinder == firstFullCurve);
else
    firstFullCurve = curveIDs(3);
    firstFullCurve_timestamps = timestamps_sec(curveFinder == firstFullCurve);
end
dt = mean(diff(firstFullCurve_timestamps)); % timestep in seconds

dV_raw = [NaN; diff(volumes)];
dVdt = dV_raw/dt * 3600;                    % final units = cubic um/sec
dVdt(isDrop == 1) = NaN;

dV_raw_noNan = diff(volumes);
dV_norm = [NaN; dV_raw_noNan./volumes(1:end-1)];
dVdt_overV = dV_norm/dt * 3600;                    % final units = cubic um/hr

dVdt_overV(isDrop == 1) = NaN;

clear curveFinder isDrop volumes

%%
% 11. overlay colored cell outlines over each image file
for img = 1:length(names)
    
    % i. initialize current image
    cla
    I=imread(names{img});
    %filename = strcat('dynamicOutlines-widths-fullOnly-xy',num2str(xy),'-frame',num2str(img),'-n',num2str(n),'.tif');
    filename = strcat('dynamicOutlines-negatives-xy',num2str(xy),'-frame',num2str(img),'.tif');
    
    figure(1)
    % imtool(I), displays image in grayscale with range
    imshow(I, 'DisplayRange',[2000 6000]); %lowering right # increases num sat'd pxls
    
    
    % ii. if no particles to display, save and skip
    if isempty(trackIDs{img}) == 1
        saveas(gcf,filename)
        continue
        
    else
        % iii. else when tracked lineages are present, isolate data for each image
        %dm_currentImage = xyData_fullOnly(xyData_fullOnly(:,18) == img,:);    % col 18 = frame #
        dm_currentImage = xyData(xyData(:,18) == img,:);    % col 18 = frame #
        
        growthRates = dVdt_overV(xyData(:,18) == img);
        
        majorAxes = dm_currentImage(:,3);           %  col 3 = lengths
        minorAxes = dm_currentImage(:,11);          % col 11 = widths
        
        centroid_X = dm_currentImage(:,16);         % col 16 = x coordinate of centroid
        centroid_Y = dm_currentImage(:,17);         % col 17 = y coordinate of centroid
        angles = dm_currentImage(:,21);             % col 21 = angle of rotation of fit ellipses

        IDs = dm_currentImage(:,1);                 % col 1 = track ID as assigned in ND2Proc_XY
        
        
        
        % iv. for each particle of interest in current image,
        %     draw ellipse colored based on current growth rate (1/hr)
        %                  negative = Crimson
        %                  positive = SeaGreen
        %                      zero = MidnightBlue
  
        
        for particle = 1:length(IDs)
            
            [x_rotated, y_rotated] = drawEllipse(particle,majorAxes, minorAxes, centroid_X, centroid_Y, angles, conversionFactor);
            lineVal = 1;
            
            
            % if track is not a full cell cycle (divTime = 0), color LightPink
            if growthRates(particle) < 0
                
                color = rgb('Crimson');
                
                hold on
                plot(x_rotated,y_rotated,'Color',color,'lineWidth',lineVal)
                text((centroid_X(particle)+2)/conversionFactor, (centroid_Y(particle)+2)/conversionFactor, num2str(IDs(particle)),'Color',color,'FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                
                
            elseif growthRates(particle) > 0
                
                color = rgb('SeaGreen');
                
                hold on
                plot(x_rotated,y_rotated,'Color',color,'lineWidth',lineVal)
                text((centroid_X(particle)+2)/conversionFactor, (centroid_Y(particle)+2)/conversionFactor, num2str(IDs(particle)),'Color',color,'FontSize',10);
                xlim([0 2048]);
                ylim([0 2048]);
                
            elseif minorAxes(particle) == 0
                
                color = rgb('MidnightBlue');
                
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
clearvars -except D D5 M T rejectD survivorDM totalDM reject2_DM reject3_DM reject4_DM



