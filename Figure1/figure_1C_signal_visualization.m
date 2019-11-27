%% figure 1C - fluorescein signal in the Microfluidic Signal Generator


% Output: plot of normalized fluorescein signal (fluctuating) from calibration movies

% strategy: 
%           0. input date of calibration data
%           0. initialize image series of signals to compare: 
%                   i. channel only crop of junc at start
%                  ii. channel only crop of junc at end
%           1. for each image series, go to directory and initialize images
%                   2. for each image in current series, load image
%                   3. calculate sum intensity of entire image, save
%                   4. load timestamp data
%                   5. normalize intensities by signal max
%                   6. plot normalized intensity over time
%           7. repeat for both reference (junc) and test (xy10) signals
%           8. save plot and output signal and timestamp data



% last updated: jen nguyen, 2019 November 27
% commit: visualize fluorescein signal in the MSG

% OK let's go!

%% Part One. initialize data


% 0. initialize fluctuating fluorescein image series
experiment = '2017-11-15'; % 30 sec period

timestamps = xlsread(strcat(experiment,'-timestamps-60x.xlsx'));
series = {
    'test_final_junc_60x';          % i. 60x mag of junc at end, no cropping required
    %'test_final_xy10'              % ii. 60x mag of xy10 at end, no cropping required
    };


%% Part Two. measure fluorescence intensity and plot time-evolution

% for each image series, go to directory and initialize images
for s = 1:length(series)
    
    % 1. open corresponding directory
    dataFolder = series{s};
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
    

end

legend('start','end')
ylim([-.05 1.05])
xlabel('time (sec)')
ylabel('raw signal intensity')
saveas(fluoresceinSignals,strcat('fluoresceinSignals-norm-',experiment),'epsc')
close(fluoresceinSignals)
    
