%% figure S10D - percent change in growth rate from pre-shift value
%
%
%  Output: from upshift data, calculate percent change 
%          from pre-shift growth rate @ 7.5 min post-shift
%          note - 7.5 min is the first post-shift timepoint with data for single shifts


%  General strategy:
%
%         Part 0. initialize folder with stored meta data
%         Part 1. collect t=0 and t=7.5 growth rates from fluctuating data
%         Part 2. collect t=0 and t=7.5 growth rates from single shift data
%         Part 3. final quantifications of percent change from t=0 and t=7.5
%         Part 4. plot quantifications



%  last updated: jen, 2020 Feb 25
%  commit: final figure S10D for sharing from source data


% OK let's go!

%% Part 0. initialize

clc
clear

% 0. initialize complete meta data
source_data = '/Users/jen/Documents/StockerLab/Source_data';
cd(source_data)
load('storedMetaData.mat')


% 0. define growth rate metric and time bin of interest
specificColumn = 3; % log2 growth rate

timePerBin = 75; % matches binning in shift response plots
timePerBin_min = timePerBin/60;


% 0. define post-shift timepoint of interest
ps_timepoint = 7.5; % in minutes


%% Part 1. collect t=0 and t=0 growth rates from fluctuating data


% 1. initialize array of experiments of interest, then loop through each
exptArray = 9:15;


% 1. initialize data vectors for collection
t_0 = zeros(length(exptArray),1);
t_x = zeros(length(exptArray),1);
t_scale = zeros(length(exptArray),1);

counter = 0; % because timescales will differ between experiments
for e = 1:length(exptArray)
    
    counter = counter + 1;
    
    % 2. initialize experiment meta data
    index = exptArray(e);                               % previous, dataIndex(e);
    date = storedMetaData{index}.date;
    timescale = storedMetaData{index}.timescale;
    bubbletime = storedMetaData{index}.bubbletime;
    expType = storedMetaData{index}.experimentType;

    disp(strcat(date, ': analyze!'))
    t_scale(e) = timescale;
    
    
    % 3. load measured data
    source_data = '/Users/jen/Documents/StockerLab/Source_data';
    cd(source_data)
    filename = strcat('lb-fluc-',date,'-c123-width1p4-c4-1p7-jiggle-0p5.mat');
    load(filename,'D5','T')
    clear experimentFolder
    
    
    
    % 4. specify condition of interest (fluc) and build data matrix
    condition = 1;                                      % 1 = fluctuating
    xy_start = storedMetaData{index}.xys(condition,1);
    xy_end = storedMetaData{index}.xys(condition,end);
    conditionData = buildDM(D5, T, xy_start, xy_end,index,expType);
    
    
    
    % 5. isolate volume (Va), timestamp, mu, drop and curveID data
    volumes = getGrowthParameter(conditionData,'volume');             % volume = calculated va_vals (cubic um)
    timestamps_sec = getGrowthParameter(conditionData,'timestamp');   % ND2 file timestamp in seconds
    isDrop = getGrowthParameter(conditionData,'isDrop');              % isDrop == 1 marks a birth event
    curveFinder = getGrowthParameter(conditionData,'curveFinder');    % col 5  = curve finder (ID of curve in condition)
    trackNum = getGrowthParameter(conditionData,'trackNum');          % track number, not ID from particle tracking
    clear expType xy_start xy_end
    
    
    % 6. calculate growth rate
    growthRates = calculateGrowthRate(volumes,timestamps_sec,isDrop,curveFinder,trackNum);
    clear curveFinder trackNum isDrop volumes
    
    
    
    % 7. isolate data to stabilized regions of growth
    %    NOTE: errors (excessive negative growth rates) occur at trimming
    %          point if growth rate calculation occurs AFTER time trim.
    minTime = 3; % hr
    
    maxTime = bubbletime(condition);
    timestamps_hr = timestamps_sec / 3600;
    
    % trim to minumum
    times_trim1 = timestamps_hr(timestamps_hr >= minTime);
    conditionData_trim1 = conditionData(timestamps_hr >= minTime,:);
    growthRates_trim1 = growthRates(timestamps_hr >= minTime,:);
    
    % trim to maximum
    if maxTime > 0
        conditionData_trim2 = conditionData_trim1(times_trim1 <= maxTime,:);
        growthRates_trim2 = growthRates_trim1(times_trim1 <= maxTime,:);
    else
        conditionData_trim2 = conditionData_trim1;
        growthRates_trim2 = growthRates_trim1;
    end
    clear growthRates conditionData maxTime minTime timestamps_sec timestamps_hr bubbletime

    
     
    % 8. isolate selected specific growth rate
    growthRt = growthRates_trim2(:,specificColumn);
    clear growthRates_trim1 growthRates_trim2 conditionData_trim1
    

    
    % 9. isolate corrected timestamp
    if strcmp(date, '2017-10-10') == 1
        correctedTime = getGrowthParameter(conditionData_trim2,'timestamp');   % ND2 file timestamp in seconds
    else
        correctedTime = getGrowthParameter(conditionData_trim2,'correctedTime'); % timestamps corrected for signal lag
    end
    clear D5 T isDrop timestamps_sec conditionData_trim2
    
    
    
    
    % 10. remove nans from data analysis
    growthRt_noNaNs = growthRt(~isnan(growthRt),:);
    correctedTime_noNans = correctedTime(~isnan(growthRt),:);
    clear growthRt correctedTime times_trim1
    
    
    
    % 11. assign corrected timestamps to bins, by which to accumulate growth data
    timeInPeriods = correctedTime_noNans/timescale; % unit = sec/sec
    timeInPeriodFraction = timeInPeriods - floor(timeInPeriods);
    
    timeInPeriodFraction_inSeconds = timeInPeriodFraction * timescale;
    bins = ceil(timeInPeriodFraction_inSeconds/timePerBin);
    clear timeInPeriods timeInPeriodFraction
    
    
    
    % 12. find which bins are boundaries signal phases
    lastBin_Q1 = (timescale/timePerBin)/4;                      % last bin before downshift
    lastBin_downshift = (timescale*3/4)/timePerBin;             % last bin before upshift
    
    firstBin_upshift = (timescale*3/4)/timePerBin + 1;          % first bin of upshift
    lastBin_ofPeriod = timescale/timePerBin;                    % total bins in signal period
    
    
    
    % 13. list bins chronologically to combine broken up high nutrient phase
    %       i.e. start of upshift is Q4, concatenate Q1
    upshiftBins{counter} = [firstBin_upshift:lastBin_ofPeriod, 1:lastBin_Q1];
    clear timeInPeriodFraction timeInPeriodFraction_inSeconds
    
    

    % 14. choose which pre-shift data bins to plot
    % decide how much data to plot prior to shift
    % upshift used here, but it is equal in length to downshift
    if length(upshiftBins{counter}) >= 5
        numPreshiftBins = 4;
    else
        numPreshiftBins = 2;
    end
    
    
    % for upshifts
    % bins are already chronological in number, so the job is easy!
    pre_upshiftBins{counter} = lastBin_downshift - (numPreshiftBins-1) : lastBin_downshift;
    


    % 16. collect growth rate data into bins and calculate stats
    binned_growthRate{counter} = accumarray(bins,growthRt_noNaNs,[],@(x) {x});
    binned_mean{counter} = accumarray(bins,growthRt_noNaNs,[],@mean);
    clear bins growthRt_noNaNs
    
  
    
    
    % 17. concatenate pre and post upshift data
    
    % time
    preUpshift_times = ((numPreshiftBins-1)*-1:0)*timePerBin_min;
    postUpshift_times = (1:length( binned_mean{counter}( upshiftBins{counter} ) ) )*timePerBin_min;
    upshift_times = [preUpshift_times,postUpshift_times];
    
    % growth rate
    preUpshift_growth = binned_mean{counter}(pre_upshiftBins{counter});
    postUpshift_growth = binned_mean{counter}(upshiftBins{counter});
    
    
    
    % 18. collect t=0 and t=5 growth rates
    t_0(e) = preUpshift_growth(preUpshift_times == 0);
    t_x(e) = postUpshift_growth(postUpshift_times == ps_timepoint);


    
    clear index lastBin_Q1 lastBin_ofPeriod lastBin_downshift firstBin_upshift firstBin_downshift
    clear first_pre_downshiftBin date condition e
    
end

clear bins_unique correctedTime_noNans filename numPreshiftBins timescale
clear postUpshift_growth postUpshift_times
clear preUpshift_growth preUpshift_times preShift_bins upshift_growth upshift_times


%% Part 2. collect t=0 and t=0 growth rates from single shift data


% 1. create array of experiments of interest, then loop through each
exptArray = [21,22]; % dataIndex values of single upshift experiments

t_0_single = zeros(length(exptArray),1);
t_x_single = zeros(length(exptArray),1);

%counter = 0;  % keep counter value from part B and continue
for e_shift = 1:length(exptArray)
    
    counter = counter + 1;
    
    % 2. initialize experiment meta data
    index = exptArray(e_shift); 
    date = storedMetaData{index}.date;
    
    % define which frames to ignore (noisy tracking)
    if strcmp(date,'2018-06-15') == 1
        ignoredFrames = [112,113,114];
    elseif strcmp(date,'2018-08-01') == 1
        ignoredFrames = [94,95];
    end
    
    bubbletime = storedMetaData{index}.bubbletime;
    expType = storedMetaData{index}.experimentType;
    shiftTime(e_shift) = storedMetaData{index}.shiftTime;        % sec

    disp(strcat(date, ': analyze!'))
    
    
    
    % 3. load measured data
    source_data = '/Users/jen/Documents/StockerLab/Source_data';
    cd(source_data)
    filename = strcat('lb-fluc-',date,'-width1p7-jiggle-0p5.mat');
    load(filename,'D5','T')
    
     
    
    % 4. specify condition of interest (fluc) and build data matrix
    condition = 1;                                      % 1 = fluctuating
    xy_start = storedMetaData{index}.xys(condition,1);
    xy_end = storedMetaData{index}.xys(condition,end);
    conditionData = buildDM(D5, T, xy_start, xy_end,index,expType);
    
    
    
    % 5. isolate volume (Va), timestamp, mu, drop and curveID data
    volumes = getGrowthParameter(conditionData,'volume');             % volume = calculated va_vals (cubic um)
    timestamps_sec = getGrowthParameter(conditionData,'timestamp');   % ND2 file timestamp in seconds
    isDrop = getGrowthParameter(conditionData,'isDrop');              % isDrop == 1 marks a birth event
    curveFinder = getGrowthParameter(conditionData,'curveFinder');    % col 5  = curve finder (ID of curve in condition)
    trackNum = getGrowthParameter(conditionData,'trackNum');          % track number, not ID from particle tracking
    clear xy_start xy_end
    
    
    
    % 6. calculate growth rate
    growthRates = calculateGrowthRate(volumes,timestamps_sec,isDrop,curveFinder,trackNum);
    clear curveFinder trackNum isDrop volumes
    
    
    
    % 7. isolate data to stabilized regions of growth
    %    NOTE: errors (excessive negative growth rates) occur at trimming
    %          point if growth rate calculation occurs AFTER time trim.
    
    minTime = 2.5; % for single shift data, unlike original fluc
    
    maxTime = bubbletime(condition);
    timestamps_hr = timestamps_sec / 3600;
    clear condition
    
    % trim to minumum
    times_trim1 = timestamps_hr(timestamps_hr >= minTime);
    conditionData_trim1 = conditionData(timestamps_hr >= minTime,:);
    growthRates_trim1 = growthRates(timestamps_hr >= minTime,:);
    
    % trim to maximum
    if maxTime > 0
        conditionData_trim2 = conditionData_trim1(times_trim1 <= maxTime,:);
        growthRates_trim2 = growthRates_trim1(times_trim1 <= maxTime,:);
    else
        conditionData_trim2 = conditionData_trim1;
        growthRates_trim2 = growthRates_trim1;
    end
    clear growthRates conditionData maxTime minTime timestamps_sec timestamps_hr

    
     
    % 8. isolate selected specific growth rate
    growthRt = growthRates_trim2(:,specificColumn);
    % specificColumn is already defined in Part B.
    % not re-defining it here ensures that we use the same metric between both
    clear growthRates_trim1 growthRates_trim2
    

    
    % 9. isolate corrected timestamp
    correctedTime = getGrowthParameter(conditionData_trim2,'correctedTime'); % timestamps corrected for signal lag
    clear D5 T isDrop conditionData_trim1
    
    
    
    % 10. assign NaN to all growth rates associated with frames to ignore
    frameNum = getGrowthParameter(conditionData_trim2,'frame'); % original frame number
    growthRt_ignorant = growthRt;
    for fr = 1:length(ignoredFrames)
        growthRt_ignorant(frameNum == ignoredFrames(fr),1) = NaN;
    end
    
    
    
    % 11. remove nans from data analysis
    growthRt_noNaNs = growthRt_ignorant(~isnan(growthRt_ignorant),:);
    correctedTime_noNans = correctedTime(~isnan(growthRt_ignorant),:);
    clear growthRt growthRt_ignorant correctedTime frameNum
    
    
    
    % 12. assign corrected timestamps to bins, by which to accumulate growth data
    bins = ceil(correctedTime_noNans/timePerBin);      % bin 1 = first timePerBin sec of experiment
    bins_unique = (min(bins):max(bins))';              % avoids missing bins due to lack of data
    
    % find bins after shift
    % generalized for single shift experiments
    first_postshiftBin_single = ceil(shiftTime(e_shift)/timePerBin) + 1; % shift occurs at shiftTime/timePerBin, so first full bin with shifted data is the next one
    postshiftBins_single{counter} = (first_postshiftBin_single:max(bins))';
    
    
    
    % 13. choose which pre-shift data bins to plot
    
    % single shift experiments don't have high/low phase interruptions
    % however, they do have bins missing data!
    numPreshiftBins = 10;
    
    % determine pre-shift bins
    index_single_shift = find(bins_unique == first_postshiftBin_single);
    pre_upshiftBins{counter} = bins_unique(index_single_shift-numPreshiftBins : index_single_shift-1); % same bins in both single down and upshifts

    
    
    % 14. collect growth rate data into bins and calculate stats
    binned_growthRate{counter} = accumarray(bins,growthRt_noNaNs,[],@(x) {x});
    binned_mean{counter} = accumarray(bins,growthRt_noNaNs,[],@mean);
    clear bins growthRt_noNaNs
    
  
    
    % 15. concatenate pre and post upshift data
    
    % time
    preUpshift_times = ((numPreshiftBins-1)*-1:0)*timePerBin_min;
    postUpshift_times = (1:length(binned_mean{counter}(postshiftBins_single{counter})))*timePerBin_min;
    upshift_times_gapped = [preUpshift_times, postUpshift_times];
    
    % growth rate
    preUpshift_growth = binned_mean{counter}(pre_upshiftBins{counter});
    postUpshift_growth_single = binned_mean{counter}(postshiftBins_single{counter});
    upshift_growth_gapped = [preUpshift_growth; postUpshift_growth_single];
    
    
    
    % 16. collect t=0 and t=5 growth rates
    t_0_single(e_shift) = preUpshift_growth(preUpshift_times == 0);
    t_x_single(e_shift) = postUpshift_growth_single(postUpshift_times == ps_timepoint);

    
  
    % don't plot zeros that are place holders for gaps in data
   % upshift_growth = upshift_growth_gapped(upshift_growth_gapped > 0);
   % upshift_times = upshift_times_gapped(upshift_growth_gapped > 0);
    
    
    %plot(upshift_times,upshift_growth,'Color',color,'LineWidth',1,'Marker','.')
     
end


clear bubbletime color conditionData_trim2 date correctedTime_noNans
clear bins_unique e_shift experimentFolder exptArray expType filename
clear fr growthRt_noNaNs ignoredFrames index index_single_shift
clear numPreshiftBins postshiftBins_single preUpshift_times preUpshift_growth
clear shiftType specificColumn specificGrowthRate timePerBin_min
clear timescale times_trim1 upshift_growth upshift_growth_gapped
clear xmax xmin first_postshiftBin_single postUpshift_growth_single
clear postUpshift_times upshift_times_gapped upshift_times


%% Part 3. quantify percent change from growth rate

% 1. calculate percent change from t=0 as (t_x - t_0)/t_0 * 100
p_change_fluc = (t_x - t_0)./t_0 * 100;
p_change_15min = p_change_fluc(t_scale == 900);
p_change_60min = p_change_fluc(t_scale == 3600);
p_change_single = (t_x_single - t_0_single)./t_0_single * 100;


% 2. calculate mean and standard dev for each condition
p_change_means(1) = mean(p_change_15min);
p_change_means(2) = mean(p_change_60min);
p_change_means(3) = mean(p_change_single);

p_change_std(1) = std(p_change_15min);
p_change_std(2) = std(p_change_60min);
p_change_std(3) = std(p_change_single);


%% Part 4. plot bar graphs of time to saturation and final saturation value

% percent change from t=0 growth rate value
figure(1)
hold on
bar(p_change_means)
errorbar(1:3,p_change_means,p_change_std,'.')
ylabel('% change from t=0 growth rate')




