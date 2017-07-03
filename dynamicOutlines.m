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


% last edit: jen, 2017 Jul 3

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
rejectD = cell(5,length(D));

% criteria counter
criteria_counter = 0;


%% Criteria ONE: tracks cannot contain multiple TrackIDs

criteria_counter = criteria_counter + 1;

% Goal: it seems that any tracks with changes in trackID are ones that are poorly joined 
%       but at least the first trackID is useable. Let's keep these first ones
%       and reject data from subsequent IDs.

% 0. for each track in current movie
%       1. determine whether trackID contains number changes
%               2. if so, trim track such that only first trackID remains
%                  (all following are very likely error prone)
%                         i. isolate entire data struct of current track,
%                            in prep to clip all variables (MajAx, X, Y, etc.)
%                        ii. isolate data corresponding to first TrackID
%               3. replace data from original track (containing multiple IDs) with trimmed data
%               4. add remainder of track to temporary (movie-specific) rejects collection
%       5. if no changes, continue to next track
% 6. when all tracks finished, save accmulated rejects.
% 7. repeat for next movie

for n = 1:length(D)
    
    
    % 0. initialize
    data = D{n};
    
    % 0. remove 'Conversion' field, as it is only one element and interferes with downstream clipping.
    data = rmfield(data,'Conv'); 
    
    
    currentRejects = [];
    reject_counter = 0;
    
    for m = 1:length(data)
        
        % 1. determine whether trackID contains number changes
        trackIDs = data(m).TrackID;
        isChange = diff(trackIDs);
        
        % if so,
        if sum(isChange) ~= 0
            
            % 2. trim track such that only first trackID remains
            reject_counter = reject_counter +1;
            disp(strcat('Track (', num2str(m),') from xy (', num2str(n),') has multiple IDs! Trimming...'))
            
            % i. isolate entire data struct of current track, in prep to clip all variables (MajAx, X, Y, etc.)
            originalTrack = data(m);
            
            % ii. isolate data corresponding to first TrackID
            originalIDs = originalTrack.TrackID;
            firstIDs = originalIDs == originalTrack.TrackID(1);
            firstTrack = structfun(@(M) M(firstIDs), originalTrack, 'Uniform', 0);
            
            
            % 3. replace data from original track (containing multiple IDs) with trimmed data
            data(m) = firstTrack;
            
            
            % 4. add remainder of track to rejects collection
            rejectIDs = originalIDs ~= originalTrack.TrackID(1);
            rejectTrack = structfun(@(M) M(rejectIDs), originalTrack, 'Uniform', 0);
            currentRejects{reject_counter} = rejectTrack;
            
            % 5. if no changes, continue to next track
        end
        
    end
    
    % 6. when all tracks finished, save trimmed data and accmulated rejects
    D2{n} = data;
    rejectD{criteria_counter,n} = currentRejects;
    
    clear currentRejects data rejectTrack rejectIDs originalIDs originalTrack
    clear firstTrack firstIDs reject_counter isChange
end


%%
% build data matrix from current data
dataMatrix = buildDM(D2,T);

%%
% IMAGE DATA
% movie (xy position) of interest
n = 52;

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

% 2. define interesting IDs by pulling TracksIDs associated with each target m

% double-check:
% how many TrackID(1)s are represented only with < 5 data points?

% initialize data
currentMovie = D2{n};

% find tracks with < 5 frames in first ID
for m = 1:length(currentMovie)
    currentTrack = currentMovie(m);
    trackLengths(m,1) = length(currentTrack.X);
end
shorties = find(trackLengths < 5);
%%
% gather IDs for those tracks
for tr = 1:length(shorties)
    interestingTrackIDs(tr,1) = currentMovie(shorties(tr)).TrackID(1);
    interestingFrames(tr,1) = currentMovie(shorties(tr)).Frame(end);
end

%%

% for each image
for img = 1:max(interestingFrames)%length(names)
    
    cla
    
    % 3. initialize current image
    I=imread(names{img});
    %filename = strcat('dynamicOutlines-frame',num2str(img),'-track',num2str(interestingTrack),'.tif');
    filename = strcat('dynamicOutlines-frame',num2str(img),'-m18-m46-m51.tif');
    
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
            
            % i. if track number is a surviving track, plot green
            %if any(IDs(p)==survivorTracks) == 1
            %if any(IDs(p) == interestingTrack) == 1
            if IDs(p)
            
                hold on
                plot(x_rotated,y_rotated,'lineWidth',1)
                text((centroid_X(p)-5)/conversionFactor, (centroid_Y(p)-5)/conversionFactor, num2str(targetIDs(p)),'Color','m','FontSize',14);
                xlim([0 2048]);
                ylim([0 2048]);
                
%             % ii. if track number was trimmed in first stage (size), plot blue
%             elseif any(IDs(p)== lostTracks{1}) == 1
%                 hold on
%                 plot(x_rotated,y_rotated,'m','lineWidth',2)
%                 xlim([0 2048]);
%                 ylim([0 2048]);
%                 
%             % iii. if track number was trimmed in second stage (golden ratio), plot orange
%             elseif any(IDs(p)== lostTracks{2}) == 1
%                 hold on
%                 plot(x_rotated,y_rotated,'b','lineWidth',2)
%                 xlim([0 2048]);
%                 ylim([0 2048]);
%                 
%             % iv. if track number was trimmed in third stage (jumpy), plot white
%             elseif any(IDs(p)== lostTracks{3}) == 1 && any(IDs(p)== lostTracks{4}) == 1
%                 hold on
%                 plot(x_rotated,y_rotated,'r','lineWidth',2)
%                 xlim([0 2048]);
%                 ylim([0 2048]);
%                 
%                 
%             % iv. if track number was trimmed in fourth stage (too short), plot red
%             elseif any(IDs(p)== lostTracks{4}) == 1
%                 hold on
%                 plot(x_rotated,y_rotated,'w','lineWidth',2)
%                 xlim([0 2048]);
%                 ylim([0 2048]);
%                 
%                 
%             % v. if track number was trimmed in fifth stage (too swiggly), plot yellow
%             elseif any(IDs(p)== lostTracks{5}) == 1
%                 hold on
%                 plot(x_rotated,y_rotated,'y','lineWidth',2)
%                 xlim([0 2048]);
%                 ylim([0 2048]);
                
            % vi. other
%             else
%                 hold on
%                 plot(x_rotated,y_rotated,'c','lineWidth',2)
%                 xlim([0 2048]);
%                 ylim([0 2048]);
%                 
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


%%

% 
% FilterParameters = {[10,.8,40],'gaussian'};
% Threshold =  [-14.1379, -1];
% Background = [];
% PlotFlag = 0;
% ImType = {'Single'};
% 
% 
% %test=Particle_Centroid(FileStruct,FilterParam,Threshold,FIndex,Backgrnd,DiffInfo,ConvFactor,Fps,PlotFlag);
% %test=Particle_Centroid(I,FilterParameters,Threshold,[],Background,ImType,conversionFactor,PlotFlag);
% %%
% 
% FN=1;
% FileStruct = FileFind;
% FIndex = FileStruct.File.Num;
% 
% 
% Im=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
%     ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(FN))]));
% 
% Im=Im(:,:,1);
% 
% Im0 = Im;
% Im1 = Im;
% ImM = Im;
% 
% Backgrnd = zeros(size(Im));
% Im=Im - Backgrnd;
% 
% 
% [h_obj, h_noise] = FilterGen_V(FilterParameters{1}(1), FilterParameters{1}(2), FilterParameters{1}(3), FilterParameters{2});
% %Preperations to do outside of loop
% Im_Filt=imfilter(Im,h_noise-h_obj,'replicate');
% Im0F=Im_Filt;
% Im1F=Im_Filt;
% ImMF=Im_Filt;
% 
% % Threshold
% ThreshDir = Threshold(2);
% Threshold = Threshold(1);
% 
% %%
% 
% ParticleOut = [];
% h = waitbar(0,['Finding Particles...']);
% 
% %for FN = 1:length(FIndex)
% %%
% try
%     switch ImType
%         case 'Single'
% Im=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
%     ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(FN))]));
% Im=Im(:,:,1);
%     end
% catch err
%     disp('Early Termination Reading Images!')
%     disp(sprintf('Failed File Number: %g', FIndex(FN)))
%     %break  %(if in loop)
% end
% %%
% 
% Im0=max(cat(3,Im,Im0),[],3);
% Im1=min(cat(3,Im,Im1),[],3);
% ImM=ImM+Im;
% 
% 
% Im=Im-Backgrnd;
% %%
% if ~isempty(FilterParameters);
%     Im_Filt=imfilter(Im,h_noise-h_obj,'replicate');
%     if ~strcmp(ImType,'Single')
%         ImR_Filt=imfilter(ImR,h_noise-h_obj,'replicate');
%     end
% else
%     Im_Filt=Im;
% end
% %%
% 
% waitbar(FN/length(FIndex), h)
% 
% %%
% 
% Im0F=max(cat(3,Im_Filt,Im0F),[],3);
% Im1F=min(cat(3,Im_Filt,Im1F),[],3);
% ImMF=ImMF+Im_Filt;
% 
% %%
% 
% if ThreshDir < 0
%     Im_BW = Im_Filt <= Threshold;
% else
%     Im_Bw = ImFilt >= Threshold;
% end
% 
% imshow(Im_BW)
% %%
% Im_CC = bwconncomp(Im_BW);
% tempXY = regionprops(Im_CC, 'PixelList', 'PixelIdxList', 'Area');
% %%
%     ParticleOut(FN).X=arrayfun(@(x) sum(x.PixelList(:,1).*Im_Filt(x.PixelIdxList))/sum(Im_Filt(x.PixelIdxList)),tempXY).*conversionFactor;
%     ParticleOut(FN).Y=arrayfun(@(x) sum(x.PixelList(:,2).*Im_Filt(x.PixelIdxList))/sum(Im_Filt(x.PixelIdxList)),tempXY).*conversionFactor;
%     ParticleOut(FN).A=arrayfun(@(x) x.Area,tempXY).*conversionFactor^2;
%     ParticleOut(FN).AvgInt=arrayfun(@(x) sum(Im_Filt(x.PixelIdxList)),tempXY);
%     ParticleOut(FN).MaxInt=arrayfun(@(x) max(Im_Filt(x.PixelIdxList)),tempXY);
%     if ~strcmp(ImType,'Single')
%         ParticleOut(FN).AvgIntRaw=arrayfun(@(x) sum(ImR_Filt(x.PixelIdxList)),tempXY);
%         ParticleOut(FN).MaxIntRaw=arrayfun(@(x) max(ImR_Filt(x.PixelIdxList)),tempXY);
%     end
%     ParticleOut(FN).Frame=FIndex(FN);
%     ParticleOut(FN).Conv=conversionFactor;
%    % ParticleOut(FN).FPS=Fps;
% %%
%     %if PlotFlag
%         figure(2); imagesc(Im); daspect([1 1 1]); colormap('gray'); title('Raw Image')
%         figure(3); imagesc(Im_Filt); daspect([1 1 1]); colormap('gray'); title('Filtered Image')
%         figure(4); imagesc(Im_BW); daspect([1 1 1]); colormap('gray'); title('Thresholded Image')
%         figure(2); hold on; plot(ParticleOut(FN).X,ParticleOut(FN).Y,'go');hold off
%         figure(3); hold on; plot(ParticleOut(FN).X,ParticleOut(FN).Y,'go');hold off
%         figure(4); hold on; plot(ParticleOut(FN).X,ParticleOut(FN).Y,'go');hold off
%         drawnow
%    % end
% 

