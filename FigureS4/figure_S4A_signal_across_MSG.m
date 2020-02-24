%% figure S4A - signal at switching junction and cell position


% Output: plot of normalized fluorescein signal (fluctuating) from calibration movies

% strategy: 
%           0. input date of calibration data
%           0. initialize image series of signals to compare: 
%                   i. channel only crop of junc at start
%                  ii. channel only crop of junc at end
%           1. for each image series, go to directory
%                   2. initialize images
%                   3. initialize vector for summed intensities
%                   4. for each image in current series, load image
%                   5. calculate sum intensity of entire image, save
%                   6. load timestamp data
%                   7. normalize intensities by signal max
%                   8. plot normalized intensity over time
%           9. repeat for both reference (junc) and test (xy10) signals



% last updated: jen, 2019 November 27
% commit: in-progress, need to add tests with a different timescale

% OK let's go!

%%



% 0. initialize fluctuating fluorescein image series
experiment = '2017-11-15';

timestamps = xlsread(strcat(experiment,'-timestamps-60x.xlsx'));
series = {
    'test_final_junc_60x';          % i. 60x mag of junc at end, no cropping required
    'test_final_xy10'              % ii. 60x mag of xy10 at end, no cropping required
    };



% for each image series, go to directory and initialize images
for s = 1:length(series)
    
    % 1. open corresponding directory
    dataFolder = strcat('/Users/jen/Documents/FigureS4/',experiment,'/',series{s});
    cd(dataFolder);
    
    % 2. initialize image data
    xyDirectory = dir(strcat(series{s},'*'));
    names = {xyDirectory.name};
    
    % 3. initialize sum intensity vector
    sumIntensity = zeros(1,length(xyDirectory));
    
    
    % for each image
    for img = 1:length(xyDirectory)
        
        % 4. read in image
        I=imread(names{img});
        
        % 5. calculate sum intensity of entire image, save sum in vector
        sumIntensity_x = sum(I,2);
        sumIntensity(img) = sum(sumIntensity_x);
        
    end
    
    % 6. load timestamps
    seriesTimestamps = timestamps(:,s);
    timeVector = seriesTimestamps(~isnan(seriesTimestamps));
    
    
    % 7. normalize intensities by signal max
    minInt = min(sumIntensity);
    bottom_norm = sumIntensity-minInt;
    maxInt = max(bottom_norm);
    normIntensity = bottom_norm./maxInt;
    
    
    % 8. plot raw intensity over time
    fluoresceinSignals = figure(1);
    plot(timeVector, normIntensity)
    
    hold on
    
    signals{s} = sumIntensity;
    clear sumIntensity
    
    % 9. repeat for both reference (junc) and test (xy10) signals
end

legend('start','end')
ylim([-.05 1.05])
xlabel('time (sec)')
ylabel('raw signal intensity')
saveas(fluoresceinSignals,strcat('fluoresceinSignals-norm-',experiment),'epsc')
close(fluoresceinSignals)
    
