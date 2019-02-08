%% figure 1C - fluorescein signal at switching junction and cell position


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



% last updated: jen, 2019 Feb 8
% commit: in-progress, need to add tests with a different timescale

% OK let's go!

%%



% 0. initialize fluctuating fluorescein image series
prompt = 'What experiment date to use for analysis?';
experiment = input(prompt);

% 2017-11-15 = 30 sec period
% 2018-01-31 = 10 sec period (but noisy)


exptFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',experiment,'/signal tests');
cd(exptFolder);

if strcmp(experiment,'2017-11-15') == 1
    timestamps = xlsread(strcat(experiment,'-timestamps-60x.xlsx'));
    series = {
        'test_final_junc_60x';          % i. 60x mag of junc at end, no cropping required
        'test_final_xy10'              % ii. 60x mag of xy10 at end, no cropping required
        };
elseif strcmp(experiment,'2018-01-31') == 1
    timestamps = xlsread(strcat('timestamps-',experiment,'-40x.xlsx'));
    series = {
        'test_start_junc_40x_crop';         
        'test_start_xy10_40x_crop'         
        };
else
    error('incomplete data: this function needs both junc and cell position')
end


% for each image series, go to directory and initialize images
for s = 1:length(series)
    
    % 1. open corresponding directory
    dataFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',experiment,'/signal tests/',series{s});
    cd(dataFolder);
    
    % initialize image data
    xyDirectory = dir(strcat(series{s},'*'));
    names = {xyDirectory.name};
    
    % initialize sum intensity vector
    sumIntensity = zeros(1,length(xyDirectory));
    
    
    % for each image
    for img = 1:length(xyDirectory)
        
        % 2. read in image
        I=imread(names{img});
        
        % 3. calculate sum intensity of entire image, save sum in vector
        sumIntensity_x = sum(I,2);
        sumIntensity(img) = sum(sumIntensity_x);
        
    end
    
    % 4. load timestamps
    seriesTimestamps = timestamps(:,s);
    timeVector = seriesTimestamps(~isnan(seriesTimestamps));
    
    
    % 5. normalize intensities by signal max
    minInt = min(sumIntensity);
    bottom_norm = sumIntensity-minInt;
    maxInt = max(bottom_norm);
    normIntensity = bottom_norm./maxInt;
    
    
    % 6. plot raw intensity over time
    fluoresceinSignals = figure(1);
    plot(timeVector, normIntensity)
    
    hold on
    
    signals{s} = sumIntensity;
    clear sumIntensity
    
    % 7. repeat for both reference (junc) and test (xy10) signals
end

% 8. save plot 
exptFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',experiment,'/signal tests');
cd(exptFolder);

legend('start','end')
ylim([-.05 1.05])
xlabel('time (sec)')
ylabel('raw signal intensity')
saveas(fluoresceinSignals,strcat('fluoresceinSignals-norm-',experiment),'epsc')
close(fluoresceinSignals)
    
