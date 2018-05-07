% physioResponse_dvdt

%  Goal: determine how similar or different physiologies are between
%        fluctuating timescales by measuring plasticity in growth rate, as
%        seen by immediate changes upon upshift and downshift


%  Last edit: jen, 2018 May 7

%  commit: 



%  Strategy:
%
%     0. initialize complete meta data
%     1. for all experiments in dataset:
%           2. collect experiment date and exclude outliers (2017-10-31)
%           3. initialize experiment meta data
%           4. load measured data
%           5. build data matrix from specified condition
%           6. isolate condition data to those with full cell cycles
%           7. isolate data to stabilized regions of growth
%           8. isolate volume (Va) and timestamp data and caluclate dVdt
%           9. isolate corrected timestamp

%          10. calculate average volume and s.e.m. per timebin
%          11. plot
%    12. repeat for all experiments



%% (A) initialize analysis
clc
clear

% 0. initialize complete meta data
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')
load('dVdtData_fullOnly_newdVdt.mat')

dataIndex = find(~cellfun(@isempty,storedMetaData));


% 1. for all experiments in dataset
ec = 0; % experiment counter
%%
for e = 12:14
    
    % 2. collect experiment date
    index = dataIndex(e);
    date = storedMetaData{index}.date;
    timescale = storedMetaData{index}.timescale;
    
    % exclude outliers from analysis (2017-10-31 and monod experiments)
    if strcmp(date, '2017-10-31') == 1 || strcmp (timescale, 'monod') == 1
        disp(strcat(date,': excluded from analysis'))
        continue
    end
    disp(strcat(date, ': analyze!'))
    ec = ec + 1;
    
    
    % 3. initialize experiment meta data
    xys = storedMetaData{index}.xys;
    bubbletime = storedMetaData{index}.bubbletime;
    
    
    % 4. load measured data
    experimentFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',date);
    cd(experimentFolder)
    filename = strcat('lb-fluc-',date,'-window5-width1p4-1p7-jiggle-0p5.mat');
    load(filename,'D5','M','M_va','T');
    
    
    % 5. build data matrix from specified condition
    condition = 1; % 1 = fluctuating; 3 = ave nutrient condition
    xy_start = storedMetaData{index}.xys(condition,1);
    xy_end = storedMetaData{index}.xys(condition,end);
    conditionData = buildDM(D5, M, M_va, T, xy_start, xy_end,e);
    
    
    % 6. isolate condition data to those with full cell cycles
    curveIDs = conditionData(:,6);           % col 6 = curve ID
    conditionData_fullOnly = conditionData(curveIDs > 0,:);
    clear curveFinder
    
    
    % 7. isolate data to stabilized regions of growth
    minTime = 3;  % hr
    maxTime = bubbletime(condition);
    timestamps = conditionData_fullOnly(:,2)/3600; % time in seconds converted to hours
    
    times_trim1 = timestamps(timestamps >= minTime);
    conditionData_trim1 = conditionData_fullOnly(timestamps >= minTime,:);
    
    if maxTime > 0
        conditionData_trim2 = conditionData_trim1(times_trim1 <= maxTime,:);
    else
        conditionData_trim2 = conditionData_trim1;
    end
    clear times_trim1 timestamps minTime maxTime bubbletime
    
    
    % 8. isolate volume (Va) and timestamp data
    volumes = conditionData_trim2(:,12);        % col 12 = calculated va_vals (cubic um)
    timestamps = conditionData_trim2(:,2);      % col 2  = timestamp in seconds
    isDrop = conditionData_trim2(:,5);          % col 5  = isDrop, 1 marks a birth event
    curveFinder = conditionData_trim2(:,6);     % col 6  = curve finder (ID of curve in condition)
    
    
    % 9. calculate mean timestep and dVdt
    curveIDs = unique(curveFinder);
    firstFullCurve = curveIDs(2);
    if length(firstFullCurve) > 1
        firstFullCurve_timestamps = timestamps(curveFinder == firstFullCurve);
    else
        firstFullCurve = curveIDs(3);
        firstFullCurve_timestamps = timestamps(curveFinder == firstFullCurve);
    end
    dt = mean(diff(firstFullCurve_timestamps)); % timestep in seconds
    
    dV_raw = [NaN; diff(volumes)];
    dVdt = dV_raw/dt;                    % final units = cubic um/sec
    dVdt(isDrop == 1) = NaN;
    
    
    % 9. isolate corrected timestamp
    if strcmp(date, '2017-10-10') == 1
        correctedTime = conditionData_trim2(:,2);
    else
        correctedTime = conditionData_trim2(:,25); % col 25 = timestamps corrected for signal lag
    end
    clear D5 M M_va T xy_start xy_end xys
    clear isDrop timestamps dV_raw firstFullCurve firstFullCurve_timestamps
    
    
    % 10. compute nutrient signal, where 1 = high and 0 = low
    %       (i) translate timestamps into quarters of nutrient signal
    timeInPeriods = correctedTime/timescale; % unit = sec/sec
    timeInPeriodFraction = timeInPeriods - floor(timeInPeriods);
    timeInQuarters = ceil(timeInPeriodFraction * 4);
    
    %      (ii) from nutrient signal quarters, generate a binary nutrient signal where, 1 = high and 0 = low
    binaryNutrientSignal = zeros(length(timeInQuarters),1);
    binaryNutrientSignal(timeInQuarters == 1) = 1;
    binaryNutrientSignal(timeInQuarters == 4) = 1;
    
    
    % 11. assign corrected timestamps to bins, by which to accumulate volume and dV/dt data
    timePerBin = 30; % sec
    timeInPeriodFraction_inSeconds = timeInPeriodFraction * 3600;
    timeInPeriodFraction_inBins = ceil(timeInPeriodFraction_inSeconds/timePerBin);
    
    downshiftBins = timePerBin+1:timePerBin*3;
    upshiftBins = [timePerBin*3+1:timePerBin*4, 1:timePerBin];
    
    pre_downshiftBins = 29:30;
    pre_upshiftBins = 89:90;
    
    
    
    % 12. remove data associated with NaN (these are in dVdt as birth events)
    growthData = [curveFinder timeInPeriodFraction_inBins volumes dVdt];
    growthData_nans = growthData(isnan(dVdt),:);
    growthData_none = growthData(~isnan(dVdt),:);
    
    % 13. collect volume and dV/dt data into bins and calculate stats
    binned_volumes_mean = accumarray(growthData_none(:,2),growthData_none(:,3),[],@mean);
    binned_volumes_std = accumarray(growthData_none(:,2),growthData_none(:,3),[],@std);
    binned_volumes_counts = accumarray(growthData_none(:,2),growthData_none(:,3),[],@length);
    binned_volumes_sems = binned_volumes_std./sqrt(binned_volumes_counts);
    
    binned_dVdt = accumarray(growthData_none(:,2),growthData_none(:,4),[],@(x) {x});
    binned_dVdt_mean = accumarray(growthData_none(:,2),growthData_none(:,4),[],@mean);
    binned_dVdt_std = accumarray(growthData_none(:,2),growthData_none(:,4),[],@std);
    binned_dVdt_counts = accumarray(growthData_none(:,2),growthData_none(:,4),[],@length);
    binned_dVdt_sems = binned_dVdt_std./sqrt(binned_dVdt_counts);
    
    
    
    % 14. plot
    shapes = {'o','*','square'};
    
    % dV/dt and standard dev
    figure(2)
    subplot(2,1,1) % upshift
    errorbar(-1:0,binned_dVdt_mean(pre_upshiftBins)*3600,binned_dVdt_std(pre_upshiftBins)*3600,'Color',rgb('DodgerBlue'),'Marker','o')
    hold on
    errorbar(1:60,binned_dVdt_mean(upshiftBins)*3600,binned_dVdt_std(upshiftBins)*3600,'Color',rgb('Chocolate'),'Marker',shapes{ec})
    grid on
    hold on
    title('upshift: mean dV/dt and standard dev')
    xlabel('period bin (30 sec)')
    ylabel('dV/dt, unsynchronized')
    axis([-1,60,-10,25])
    
    subplot(2,1,2) % downshift
    errorbar(-1:0,binned_dVdt_mean(pre_downshiftBins)*3600,binned_dVdt_std(pre_downshiftBins)*3600,'Color',rgb('Chocolate'),'Marker',shapes{ec})
    hold on
    errorbar(1:60,binned_dVdt_mean(downshiftBins)*3600,binned_dVdt_std(downshiftBins)*3600,'Color',rgb('DodgerBlue'),'Marker',shapes{ec})
    grid on
    hold on
    title('downshift: mean dV/dt and standard dev')
    xlabel('period bin (30 sec)')
    ylabel('dV/dt, unsynchronized')
    axis([-1,60,-10,25])
    
    
    % dV/dt and sem
    figure(3)
    subplot(2,1,1) % upshift
    errorbar(-1:0,binned_dVdt_mean(pre_upshiftBins)*3600,binned_dVdt_sems(pre_upshiftBins)*3600,'Color',rgb('DodgerBlue'),'Marker',shapes{ec})
    hold on
    errorbar(1:60,binned_dVdt_mean(upshiftBins)*3600,binned_dVdt_sems(upshiftBins)*3600,'Color',rgb('Chocolate'),'Marker',shapes{ec})
    grid on
    hold on
    title('upshift: mean dV/dt and s.e.m.')
    xlabel('period bin (30 sec)')
    ylabel('dV/dt, unsynchronized')
    axis([-1,60,-5,15])
    
    subplot(2,1,2) % downshift
    errorbar(-1:0,binned_dVdt_mean(pre_downshiftBins)*3600,binned_dVdt_sems(pre_downshiftBins)*3600,'Color',rgb('Chocolate'),'Marker',shapes{ec})
    hold on
    errorbar(1:60,binned_dVdt_mean(downshiftBins)*3600,binned_dVdt_sems(downshiftBins)*3600,'Color',rgb('DodgerBlue'),'Marker',shapes{ec})
    grid on
    hold on
    title('downshift: mean dV/dt and s.e.m.')
    xlabel('period bin (30 sec)')
    ylabel('dV/dt, unsynchronized')
    axis([-1,60,-5,15])
    
    clearvars -except dVdtData_fullOnly_newdVdt storedMetaData ec datesForLegend dataIndex
    
end



