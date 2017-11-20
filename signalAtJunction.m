%% signalAtJunction

% goal: analyze fluorescein signal from start and end of experiment to
%           1. confirm that signal is robust from start to end
%           2. enable comparison with downstream signal


% last updated: jen, 2017 Nov 19

% strategy: 
%           0. initialize image data: vertical crop of channel just after junction
%                                     crop dimensions: 538 x 88 pixels
%           1. for each image, load image
%                   2. calculate mean pixel intensity in x direction and timestamp
%                   3. plot intensity in y direction over time
%                   4. save plot as timepoint
%           5. repeat for all images
%


% OK let's go!

%% 0. initialize image data
clear

xyDirectory = dir('test_final_junc_20x*');
names = {xyDirectory.name};

% initialize timestamp info
t0 = 0.74; % first timestamp in seconds
deltaTime = 0.21; % time between frames in seconds

% for each image
for img = 1:length(xyDirectory)
    
    %% 1. read in image
    I=imread(names{img});
    
    % figure(1)
    % imshow(I)
    % imtool(I), displays image in grayscale with range
    % imshow(I, 'DisplayRange',[2000 8000]);
    
    %% 2. calculate mean pixel intensity in x direction and timestamp
    meanIntensity = mean(I,2);
    timestamp = t0 + (img-1)*deltaTime;
    
    %% 3. plot intensity in y direction over time
    figure(1)
    plot(meanIntensity)
    %axis([1 538 1.6*10^4 3.6*10^4])
    axis([1 505 1.6*10^4 3.6*10^4])
    text(430,3.45*10^4, strcat(num2str(timestamp),'  sec'),'Color',[0 0 0],'FontSize',15);
    
    %% 4. save plot as timepoint
    filename = strcat('intensityPlot-junc-20x-frame',num2str(img),'.tif');
    saveas(gcf,filename)

% repeat for all images    
end
