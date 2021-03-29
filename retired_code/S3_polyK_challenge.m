%% figure S2c. poly-lysine challenge


%  Goals: plot growth rate over time for poly-lysine +/- conditions

%  Strategy:
%
%       0. initialize analysis with source data and experimental parameters
%       1. calculate growth rate from different conditions and plot growth
%          rate over time


%  last updated: jen, 2021 March 29
%  commit: supplementary fig 2c, revised for sharing with source data


%  OK let's go!

%% Part 0. initialize

clear
clc

% 0. initialize complete meta data
%cd('/Users/jen/Documents/StockerLab/Data_analysis/')
source_data = '/Users/jen/Documents/StockerLab/Source_data';
cd(source_data)
load('storedMetaData.mat')
dataIndex = find(~cellfun(@isempty,storedMetaData));


% 0. define growth rate of interest
specificGrowthRate = 'log2';
specificColumn = 3;


% 0. initialize binning parameters
specificBinning = 30;
binsPerHour = 60/specificBinning;


%% Part 1. calculate and plot growth rate over time

% 1. create array of experiments of interest, then loop through each:
exptArray = 19; % use corresponding dataIndex values

for e = 1:length(exptArray)
    
    
    % 2. initialize experiment meta data
    index = exptArray(e);
    date = storedMetaData{index}.date;
    expType = storedMetaData{index}.experimentType;
    bubbletime = storedMetaData{index}.bubbletime;
    timescale = storedMetaData{index}.timescale;
    disp(strcat(date, ': analyze!'))
    
    
    % 3. load measured experiment data    
    if strcmp(date,'2018-12-04') == 1
        filename = 'lb-monod-2018-12-04-c12-width1p7-c34-width1p4-jiggle-0p5.mat';
    end
    load(filename,'D5','T');
    
    
    % 4. build data matrix from specified condition
    for condition = 1:length(bubbletime)
        
        xy_start = storedMetaData{index}.xys(condition,1);
        xy_end = storedMetaData{index}.xys(condition,end);
        conditionData = buildDM(D5, T, xy_start, xy_end,index,expType);
        
        
        % 5. isolate volume (Va), timestamp, drop, curve, and trackNum data
        volumes = getGrowthParameter(conditionData,'volume');             % volume = calculated va_vals (cubic um)
        timestamps_sec = getGrowthParameter(conditionData,'timestamp');   % ND2 file timestamp in seconds
        isDrop = getGrowthParameter(conditionData,'isDrop');              % isDrop == 1 marks a birth event
        curveFinder = getGrowthParameter(conditionData,'curveFinder');    % col 5  = curve finder (ID of curve in condition)
        trackNum = getGrowthParameter(conditionData,'trackNum');          % track number, not ID from particle tracking

        
        % 6. calculate growth rate
        growthRates = calculateGrowthRate(volumes,timestamps_sec,isDrop,curveFinder,trackNum);
        clear volumes isDrop curveFinder trackNum
        

        % 7. truncate data to non-erroneous (e.g. bubbles) timestamps
        maxTime = 6;
        timestamps_hr = conditionData(:,2)/3600; % time in seconds converted to hours
        
        if maxTime > 0
            conditionData_bubbleTrimmed = conditionData(timestamps_hr <= maxTime,:);
            growthRates_bubbleTrimmed = growthRates(timestamps_hr <= maxTime,:);
        else
            conditionData_bubbleTrimmed = conditionData;
            growthRates_bubbleTrimmed = growthRates;
        end
        clear timestamps_hr timestamps_sec growthRates
           
        
        % 8. isolate selected specific growth rate and timestamp
        growthRt = growthRates_bubbleTrimmed(:,specificColumn);
        timestamps_sec = getGrowthParameter(conditionData_bubbleTrimmed,'timestamp'); % ND2 file timestamp in seconds
        timeInHours = timestamps_sec./3600;
        clear conditionData timestamps_sec
                 

        % 9. remove NaNs from data analysis
        growthRt_noNaNs = growthRt(~isnan(growthRt),:);
        timeInHours_noNans = timeInHours(~isnan(growthRt),:);
        clear growthRt timeInHours growthRates_bubbleTrimmed
            
                
        % 10. bin growth rate into time bins based on timestamp
        bins = ceil(timeInHours_noNans*binsPerHour);

        
        % 11. calculate mean, standard dev, counts, and standard error
        binned_growthRt = accumarray(bins,growthRt_noNaNs,[],@(x) {x});
        bin_means = cellfun(@mean,binned_growthRt);
        bin_stds = cellfun(@std,binned_growthRt);
        bin_counts = cellfun(@length,binned_growthRt);
        bin_sems = bin_stds./sqrt(bin_counts);
        
        
        % 12. plot growth rate over time
        palette = {'DodgerBlue','Indigo','GoldenRod','FireBrick','LimeGreen','MediumPurple'};
        color = rgb(palette{condition});
        xmark = '.';
        
        figure(e)
        errorbar((1:length(bin_means))/binsPerHour,bin_means,bin_sems,'Color',color,'Marker',xmark)
        hold on
        legend('high,untreated','high,treated','low,untreated','low,treated')
        xlabel('Time (hr)')
        ylabel('Growth rate (1/hr)')
        title(strcat(date,': (',specificGrowthRate,')'))
        
        %end
    end
    
end




