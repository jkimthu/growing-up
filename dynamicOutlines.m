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


% last edit: jen, 2017 Jun 23

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

% import tracking data
load('dm-2017-06-12_untrimmed.mat');
dataMatrix_untrimmed = dataMatrix;

load('dm-2017-06-12.mat');
dataMatrix_trimmed = dataMatrix;

load('letstry-2017-06-12-dSmash.mat','T');

clear dataMatrix;

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



% 1. isolate ellipse data from movie (stage xy) of interest
dm_currentMovie_untrimmed = dataMatrix_untrimmed(dataMatrix_untrimmed(:,31) == n,:); % col 31 is movie number (n)
dm_currentMovie_trimmed = dataMatrix_trimmed(dataMatrix_trimmed(:,31) == n,:);

% 2. define IDs for tracked vs trimmed tracks
survivorTracks = unique(dm_currentMovie_trimmed(:,1)); % col 1 = track IDs

% build data matrix of rejected tracks
rejects_currentMovie = rejectD(:,n);
dm_currentMovie_rejects = buildDM(rejects_currentMovie,T);
%%

% sort by trim stage number
for stage = 1:length(rejects_currentMovie)
    
    dm_currentRejects = dm_currentMovie_rejects(dm_currentMovie_rejects(:,31) == stage,:); %not in D2
    lostTracks{stage} = unique(dm_currentRejects(:,1));

end
%%

% for each image
for img = 1:length(names)
    
    cla
    
    % 3. initialize current image
    I=imread(names{img});
    filename = strcat('dynamicOutlines-frame',num2str(img),'-trackedVtrimmed.tif');
    
    figure(1)
    imshow(I, 'DisplayRange',[3200 7400]);
    
    
    % 3. if no tracked cells, save and skip
    if sum(dm_currentMovie_untrimmed(:,30) == img) == 0
        saveas(gcf,filename)
        
        continue
        
    else
        % 4. else, isolate data for each image
        dm_currentImage = dm_currentMovie_untrimmed(dm_currentMovie_untrimmed(:,30) == img,:); % col 30 = frame #
        
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
        
        
        % 5. for each particle in current image, draw ellipse
        for p = 1:length(majorAxes)
            
            
            [x_rotated, y_rotated] = drawEllipse(p,majorAxes, minorAxes, centroid_X, centroid_Y, angles, conversionFactor);
            
            % i. if track number is a surviving track, plot green
            if any(IDs(p)==survivorTracks) == 1
                
                hold on
                plot(x_rotated,y_rotated,'g','lineWidth',2)
                xlim([0 2048]);
                ylim([0 2048]);
                
            % ii. if track number was trimmed in first stage (size), plot blue
            elseif any(IDs(p)== lostTracks{1}) == 1
                hold on
                plot(x_rotated,y_rotated,'m','lineWidth',2)
                xlim([0 2048]);
                ylim([0 2048]);
                
            % iii. if track number was trimmed in second stage (golden ratio), plot orange
            elseif any(IDs(p)== lostTracks{2}) == 1
                hold on
                plot(x_rotated,y_rotated,'b','lineWidth',2)
                xlim([0 2048]);
                ylim([0 2048]);
                
            % iv. if track number was trimmed in third stage (jumpy), plot white
            elseif any(IDs(p)== lostTracks{3}) == 1 && any(IDs(p)== lostTracks{4}) == 1
                hold on
                plot(x_rotated,y_rotated,'r','lineWidth',2)
                xlim([0 2048]);
                ylim([0 2048]);
                
                
            % iv. if track number was trimmed in fourth stage (too short), plot red
            elseif any(IDs(p)== lostTracks{4}) == 1
                hold on
                plot(x_rotated,y_rotated,'w','lineWidth',2)
                xlim([0 2048]);
                ylim([0 2048]);
                
                
            % v. if track number was trimmed in fifth stage (too swiggly), plot yellow
            elseif any(IDs(p)== lostTracks{5}) == 1
                hold on
                plot(x_rotated,y_rotated,'y','lineWidth',2)
                xlim([0 2048]);
                ylim([0 2048]);
                
            % vi. other
            else
                hold on
                plot(x_rotated,y_rotated,'c','lineWidth',2)
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

