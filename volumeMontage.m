% volumeMontage

%  Goal: can we observe changes in volume trajectories in response to nutrient shifts?
%        plot volume over time, overlaying nutrient signal


%  Strategy:
%
%  Part A:
%     0. initialize analysis parameters
%     0. initialize complete meta data

%  Part B:
%     1. for all experiments in dataset:
%           2. collect experiment date and exclude outliers (2017-10-31)
%           3. initialize experiment meta data
%           4. load measured data
%           5. for each condition,
%                   6. isolate data for current condition
%                   7. find all tracks that are at least x hours long
%                   8. plot track volume vs time, overlay with nutrient signal
%                      note: if number of long tracks exceeds 10, choose 10 at random
%                            i. initialize random number generator to make results repeatable
%                           ii. create vector of 10 random integers drawn from a uniform
%                               distribution between 1 and numLongTracks
%                   9. isolate data from current long track
%                  10. isolate volume and timestamp (corrected for signal lag) data of interest
%                  11. translate corrected time into binary signal where, 1 = high and 0 = low
%                  12. designate plotting color
%                  13. scale binary nutrient signal
%                  14. plot
%          15. repeat for all conditions
%          16. save figures
%    17. repeat for all experiments


%  Last edit: jen, 2018 Apr 6

%  commit: plot and save 10 random individual tracks of 5+ hours from all
%          experiments






%% (A) initialize analysis
clc
clear

% 0. initialize complete meta data
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')

dataIndex = find(~cellfun(@isempty,storedMetaData));
experimentCount = length(dataIndex);

%% (B) plot volume over time, overlaying nutrient signal

% 1. for all experiments in dataset
exptCounter = 0;
for e = 1:experimentCount
    
    % 2. collect experiment date
    index = dataIndex(e);
    date = storedMetaData{index}.date;
    timescale = storedMetaData{index}.timescale;
    
    % exclude outlier from analysis
    if strcmp(date, '2017-10-31') == 1 || strcmp (timescale, 'monod') == 1
       disp(strcat(date,': excluded from analysis'))
       continue
    end
    disp(strcat(date, ': analyze!'))
    exptCounter = exptCounter + 1;
    
    
    % 3. initialize experiment meta data
    xys = storedMetaData{index}.xys;
    bubbletime = storedMetaData{index}.bubbletime;
    
    
    % 4. load measured data
    experimentFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',date);
    cd(experimentFolder)
    filename = strcat('lb-fluc-',date,'-window5-width1p4-1p7-jiggle-0p5.mat');
    load(filename,'D','D5','M','M_va','T');
    xy_start = min(min(xys));
    xy_end = max(max(xys));
    exptData = buildDM(D5, M, M_va, T, xy_start, xy_end,e);
    
    
    % 5. for each condition, specify:
    for condition = 1:4 % 1 = fluctuating; 3 = ave nutrient condition
        
        % 6. gather specified condition data
        conditionData = exptData(exptData(:,23) == condition,:);
        
        
        % 7. find all tracks that are at least x hours long
        x = 5;
        trackNum = conditionData(:,22);               % col 22 = track num for condition (not xy based ID from tracking)
        
        uniqueTracks = unique(trackNum);
        framesPerTrack = histc(trackNum(:), uniqueTracks);
        framesPerHour = 3600/(60+57);
        longTracks = uniqueTracks(framesPerTrack(:) >= framesPerHour * x);
        clear xy_start xy_end xys trackNum
        
        
        % 8. plot track volume vs time, overlay with nutrient signal
        %    note: if number of long tracks exceeds 10, choose 10 at random
        %          to plot
        numLongTracks = length(longTracks);
        max_numTracks = 10;
        
        if numLongTracks > max_numTracks
            
            % i. initialize random number generator to make results repeatable
            rng(0,'twister');
            
            % ii. create vector of 10 random integers drawn from a uniform
            %     distribution between 1 and numLongTracks
            a = 1;
            b = numLongTracks;
            ri = randi([a b],max_numTracks,1);
            tracks2Plot = longTracks(ri);
            
        else
            tracks2Plot = longTracks;
        end
        
        for lt = 1:length(tracks2Plot)
            
            % 9. isolate data from current long track
            current_longTrack = conditionData(conditionData(:,22) == tracks2Plot(lt),:);
            
            % 10. isolate volume and timestamp (corrected for signal lag) data of interest
            volume = current_longTrack(:,12);                 % col 12 = volumes (va)
            correctedTime = current_longTrack(:,25);          % col 25 = timestamps corrected for signal lag
            
            % 11. translate corrected time into binary signal where, 1 = high and 0 = low
            resolved_time = linspace(correctedTime(1),correctedTime(end),100000)';
            timeInPeriods = resolved_time/timescale; % unit = sec/sec
            timeInPeriodFraction = timeInPeriods - floor(timeInPeriods);
            timeInQuarters = ceil(timeInPeriodFraction * 4);
            
            binaryNutrientSignal = zeros(length(timeInQuarters),1);
            binaryNutrientSignal(timeInQuarters == 1) = 1;
            binaryNutrientSignal(timeInQuarters == 4) = 1;
            
            % 12. designate plotting color
            if condition == 1
                color = rgb('DodgerBlue');
            elseif condition == 2
                color = rgb('Indigo');
            elseif condition == 3
                color = rgb('Goldenrod');
            elseif condition == 4
                color = rgb('FireBrick');
            end
            color_nutrientSignal = rgb('LightSlateGray');
            
            % 13. scale binary nutrient signal
            high_val = 9;
            low_val = 1;
            
            if condition == 1
                nutrientSignal(binaryNutrientSignal == 1) = high_val;
                nutrientSignal(binaryNutrientSignal == 0) = low_val;
            elseif condition == 2
                nutrientSignal(binaryNutrientSignal == 1) = low_val;
                nutrientSignal(binaryNutrientSignal == 0) = low_val;
            elseif condition == 3
                nutrientSignal(binaryNutrientSignal == 1) = (low_val+high_val)/2;
                nutrientSignal(binaryNutrientSignal == 0) = (low_val+high_val)/2;
            else
                nutrientSignal(binaryNutrientSignal == 1) = high_val;
                nutrientSignal(binaryNutrientSignal == 0) = high_val;
            end
            
            % 14. plot
            figure(condition)
            subplot(length(tracks2Plot),1,lt)
            plot(correctedTime/3600,volume,'Color',color)
            hold on
            plot(resolved_time/3600,nutrientSignal,'Color',color_nutrientSignal)
            axis([0,10,0,15])
            legend(strcat('track number:',num2str(tracks2Plot(lt))))
            
            if lt == 1
                title(strcat('individual lineages from condition (',num2str(condition),'), experiment: ',date))
            elseif lt == 3
                ylabel('volume (cubic um) and nutrient signal')
            elseif lt == length(tracks2Plot)
                xlabel('time (hr)')
            end
            
            
        end
        
        % 15. repeat for all conditions
        clear conditionData binaryNutrientSignal binaryNutrientSignal_scaled
        clear correctedTime resolved_time volume
        clear longTracks numLongTracks
    end
    
    % 16. save figures
    for f = 1:4
        
        cd('/Users/jen/Documents/StockerLab/Data_analysis/volume_tracks')
        currentFig = figure(f);
        saveas(currentFig,strcat('Fig',num2str(f),'-c',num2str(f),'-',date,'-t',num2str(timescale)),'epsc')
        close(currentFig)
        
    end
    clear D D5 M M_va T
    
    % 17. repeat for all experiments
end



