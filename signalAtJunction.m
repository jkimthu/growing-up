%% signalAtJunction

% goal: analyze fluorescein signal from start and end of experiment to
%           1. confirm that signal is robust from start to end
%           2. enable comparison with downstream signal




% strategy: 
%           0. initialize image series of signals to compare: 
%                   i. channel only crop of junc at start
%                  ii. channel only crop of junc at end
%           1. for each image series, go to directory and initialize images
%                   2. for each image in current series, load image
%                          3. calculate mean pixel intensity in x direction and timestamp
%                          4. plot intensity in y direction over time
%                          5. save plot as timepoint
%                          6. calculate sum intensity of entire image, save
%                   6. repeat for all images
%           7. plot sum intensity over time
%           8. repeat for all series, holding sum intensity data

% last updated: jen, 2018 Feb 5

% commit: retired, see now function calculateFluoresceinSignal.m

% OK let's go!

%% 0. initialize image series
clear

exptFolder = '/Users/jen/Documents/StockerLab/Data/LB/2017-11-15';
cd(exptFolder);

timestamps = xlsread('2017-11-15-timestamps.xlsx');

series = {
    'test_start_cropped';          % i. 60x mag of junc at end
    'test_final_junc_20x_channelonly'              % ii. 60x mag of xy10 at end
    };

crops = {
    'test_start*';
    'test_final_junc_20x*'
    };

%% 1. for each image series, go to directory and initialize images

for s = 1:length(series)
    
    % 1. open corresponding directory
    newFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/2017-11-15/',series{s});%,'  (t300)');
    cd(newFolder);

    % initialize image data
    xyDirectory = dir(crops{s});
    names = {xyDirectory.name};
    
    % initialize sum intensity vector
    sumIntensity = zeros(1,length(xyDirectory));
    
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
        
        seriesTimestamps = timestamps(:,s);
        timeVector = seriesTimestamps(~isnan(seriesTimestamps));
        
        %% 3. plot intensity in y direction over time
        %figure(1)
        %plot(meanIntensity)
        %axis([1 414 1.6*10^4 3.6*10^4])
        %axis([1 505 1.6*10^4 3.6*10^4])
        %text(340,3.45*10^4, strcat(num2str(timestamp),'  sec'),'Color',[0 0 0],'FontSize',15);
        
        %% 4. save plot as timepoint
        %filename = strcat('intensityPlot-junc-20x-frame',num2str(img),'.tif');
        %saveas(gcf,filename)
        
        %% 5. calculate sum intensity of entire image, save sum in vector
        sumIntensity_x = sum(I,2);
        sumIntensity(img) = sum(sumIntensity_x);
        
        % 6. repeat for all images
    end
    
    % 7. plot raw intensity over time
    figure(1)
    plot(timeVector, sumIntensity)
    hold on
    
    clear sumIntensity
end

legend('start','end')
xlabel('time (sec)')
ylabel('raw signal intensity')