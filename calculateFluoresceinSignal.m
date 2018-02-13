%% calculateFluoresceinSignal

% goal: measure fluorescein signal from fluctuation calibration movies

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

% last updated: jen, 2018 Feb 13

% commit: update names for intialization of 40x image series and timestamps

% OK let's go!

function [signals,timestamps] = calculateFluoresceinSignal(experiment)

% 0. initialize image series

% initialize fluctuating fluorescein image series
if strcmp(experiment,'2017-11-15') == 1
    timestamps = xlsread(strcat(experiment,'-timestamps-60x.xlsx'));
    series = {
        'test_final_junc_60x';          % i. 60x mag of junc at end, no cropping required
        'test_final_xy10'              % ii. 60x mag of xy10 at end, no cropping required
        };
else
    timestamps = xlsread(strcat('timestamps-',experiment,'-40x.xlsx'));
    series = {
        'test_start_junc_40x_crop';
        'test_start_xy10_40x'
        };
end
clear ans

% for each image series, go to directory and initialize images

for s = 1:length(series)
    
    % 1. open corresponding directory
    dataFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',experiment,'/',series{s});
    cd(dataFolder);
    
    % initialize image data
    xyDirectory = dir(strcat(series{s},'*'));
    names = {xyDirectory.name};
    
    % initialize sum intensity vector
    sumIntensity = zeros(1,length(xyDirectory));
    
    % for each image
    for img = 1:length(xyDirectory)
        
        % 1. read in image
        I=imread(names{img});
        
        % 2. calculate mean pixel intensity in x direction and timestamp
        meanIntensity = mean(I,2);
        seriesTimestamps = timestamps(:,s);
        timeVector = seriesTimestamps(~isnan(seriesTimestamps));
        
        % 3. calculate sum intensity of entire image, save sum in vector
        sumIntensity_x = sum(I,2);
        sumIntensity(img) = sum(sumIntensity_x);
        
        % 4. repeat for all images
    end
    
    % 5. plot raw intensity over time
    fluoresceinSignals = figure(1);
    plot(timeVector, sumIntensity)
    hold on
    
    signals{s} = sumIntensity;
    clear sumIntensity
end

legend('start','end')
xlabel('time (sec)')
ylabel('raw signal intensity')
saveas(fluoresceinSignals,strcat('fluoresceinSignals-',experiment),'epsc')
close(fluoresceinSignals)
    
end