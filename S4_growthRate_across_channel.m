%% figure S4. growth rate across channel


%  Goals: plot growth rate over time for each channel position

%  Strategy:
%
%       0. initialize directory and meta data
%       0. define time binning and growth rates of interest, see comments below for details 
%       1. create array of experiments of interest, for each:
%               2. initialize experiment meta data
%               3. load measured experiment data    
%               4. for single shift experiments, define which frames to ignore (noisy tracking)
%               5. for each condition in current experiment, build data matrix from specified condition
%                       6. isolate volume (Va), timestamp, drop, curve, and trackNum data
%                       7. calculate growth rate
%                       8. truncate data to non-erroneous (e.g. bubbles) timestamps
%                       9. isolate selected specific growth rate and timestamp
%                      10. if appropriate, assign NaN to all growth rates associated with frames to ignore
%                          else simply remove existing nans from analysis
%                      11. bin growth rate into time bins based on timestamp
%                      12. calculate mean, standard dev, counts, and standard error
%                      13. plot growth rate over time
%              14. save plot with experiment #, specific growth rate definition, and binning          
%      15. repeat for all experiments 


%  last updated: jen, 2019 Feb 20
%  commit: minor comment edits


% OK let's go!

%%

clear
clc

% 0. initialize complete meta data
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')
dataIndex = find(~cellfun(@isempty,storedMetaData));


% 0. define growth rate of interest
specificGrowthRate = 'log2';
specificColumn = 3;


% 0. initialize binning parameters
specificBinning = 30;
binsPerHour = 60/specificBinning;


%%
% 1. create array of experiments of interest, then loop through each:
exptArray = 15; % use corresponding dataIndex values

for e = 1:length(exptArray)
    
    
    % 2. initialize experiment meta data
    index = exptArray(e);
    date = storedMetaData{index}.date;
    expType = storedMetaData{index}.experimentType;
    bubbletime = storedMetaData{index}.bubbletime;
    timescale = storedMetaData{index}.timescale;
    disp(strcat(date, ': analyze!'))
    
    
    
    % 3. load measured experiment data    
    experimentFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',date);
    cd(experimentFolder)
    if strcmp(date,'2017-11-09') == 1
        filename = strcat('lb-control-',date,'-width1p4-jiggle-0p5.mat');
    elseif strcmp(date,'2017-09-26') == 1
        filename = 'lb-monod-2017-09-26-jiggle-c12-0p1-c3456-0p5-bigger1p8.mat';
    elseif strcmp(date,'2018-12-04') == 1
        filename = 'lb-monod-2018-12-04-c12-width1p7-c34-width1p4-jiggle-0p5.mat';
    elseif strcmp(expType,'origFluc') == 1
        filename = strcat('lb-fluc-',date,'-c123-width1p4-c4-1p7-jiggle-0p5.mat');
    elseif strcmp(expType,'fluc2stable') == 1
        filename = strcat('lb-fluc-',date,'-c123-width1p4-c4-1p7-jiggle-0p5.mat');
    else
        filename = strcat('lb-fluc-',date,'-width1p7-jiggle-0p5.mat');
        % single upshift and downshift data only uses larger width thresh
    end
    load(filename,'D5','T');
    
    
    
    % 5. for each xy position of each condition
    order = [1,5,10];
    for condition = 2:length(bubbletime)
        
        for position = 1:3
            
            
            % 5. select current XY and assemble data
            xys = storedMetaData{index}.xys(condition,:);
            currentXY = xys(order(position));
            xyData = buildDM(D5, T, currentXY, currentXY, index, expType);
            
            
            % 6. isolate volume (Va), timestamp, drop, curve, and trackNum data
            volumes = getGrowthParameter(xyData,'volume');             % volume = calculated va_vals (cubic um)
            timestamps_sec = getGrowthParameter(xyData,'timestamp');   % ND2 file timestamp in seconds
            isDrop = getGrowthParameter(xyData,'isDrop');              % isDrop == 1 marks a birth event
            curveFinder = getGrowthParameter(xyData,'curveFinder');    % col 5  = curve finder (ID of curve in condition)
            trackNum = getGrowthParameter(xyData,'trackNum');          % track number, not ID from particle tracking
            
            
            
            % 7. calculate growth rate
            growthRates = calculateGrowthRate(volumes,timestamps_sec,isDrop,curveFinder,trackNum);
            clear volumes isDrop curveFinder trackNum
            
            
            
            % 8. truncate data to non-erroneous (e.g. bubbles) timestamps
            maxTime = bubbletime(condition);
            timestamps_hr = timestamps_sec/3600; % time in seconds converted to hours
            
            if maxTime > 0
                xyData_bubbleTrimmed = xyData(timestamps_hr <= maxTime,:);
                growthRates_bubbleTrimmed = growthRates(timestamps_hr <= maxTime,:);
            else
                xyData_bubbleTrimmed = xyData;
                growthRates_bubbleTrimmed = growthRates;
            end
            clear timestamps_hr timestamps_sec growthRates
            
            
            
            % 9. isolate selected specific growth rate and timestamp
            growthRt = growthRates_bubbleTrimmed(:,specificColumn);
            timestamps_sec = getGrowthParameter(xyData_bubbleTrimmed,'timestamp'); % ND2 file timestamp in seconds
            timeInHours = timestamps_sec./3600;  
            clear xyData timestamps_sec
  


            % 10. remove NaNs from data analysis
            growthRt_noNaNs = growthRt(~isnan(growthRt),:);
            timeInHours_noNans = timeInHours(~isnan(growthRt),:);
            clear growthRt timeInHours
            
            
            
            % 11. bin growth rate into time bins based on timestamp
            bins = ceil(timeInHours_noNans * binsPerHour);
            binned_growthRt = accumarray(bins,growthRt_noNaNs,[],@(x) {x});
            clear growthRates_bubbleTrimmed xyData_bubbleTrimmed             
            
            
            
            % 12. calculate mean, standard dev, counts, and standard error
            bin_means = cellfun(@mean,binned_growthRt);
            bin_stds = cellfun(@std,binned_growthRt);
            bin_counts = cellfun(@length,binned_growthRt);
            bin_sems = bin_stds./sqrt(bin_counts);
            
            
            
            % 13. plot growth rate over time
            palette = {'DodgerBlue','Indigo','GoldenRod','FireBrick','LimeGreen','MediumPurple'};
            
            if condition == 2
                color = rgb(palette(condition))+[0.1*position 0 0];
            elseif condition == 3
                color = rgb(palette(condition))+[0 0.1*position 0];
            else
                color = rgb(palette(condition))+[0 0 0.1*position];
            end
            xmark = '.';
            

            figure(1)
            errorbar((1:length(bin_means))/binsPerHour,bin_means,bin_sems,'Color',color,'Marker',xmark)
            hold on
            grid on
            legend('proximal','center','distant','proximal','center','distant','proximal','center','distant')
            xlabel('Time (hr)')
            ylabel('Growth rate (1/hr)')
            xlim([0 9.5])
            title(strcat(date,': (',specificGrowthRate,')'))
            
        end
    end
    
    
    % 14. save plots in active folder
    cd('/Users/jen/Documents/StockerLab/Data_analysis/currentPlots/')
    plotName = strcat('figureS4-',specificGrowthRate,'-',date,'-',num2str(specificBinning),'minbins');
    saveas(gcf,plotName,'epsc')
    
    %close(gcf)
    clc
    
    % 15. repeat for all experiments
end


%%

