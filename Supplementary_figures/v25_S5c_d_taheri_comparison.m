%% figure S5 panel c & d


%  Goal: plot population-level birth size as a function of mean growth rate
%        across the cell cycle

%        compares data from Taheri-Araghi et al.'s conditions with our
%        steady C_low, C_ave and C_high
%
%        steady-state populations have been demonstrated to follow a strong
%        positive correlation between the natural log of cell size and
%        growth rate.
%     
%        modeled, after Figure 1C of Taheri et al., (2014)



%  Note: Part 1 & 2 organize and save data into a file SFig5c.mat that is
%        available online https://github.com/jkimthu/growing-up/tree/master/FigureS5
%
%        With this file, one can immediately jump to Part 3 without running
%        Parts 1 & 2.
%
%        Running Parts 3, 4 % 5 produce Supplementary Fig. 5c & d



%  Strategy: 
%
%        Part 1. initialize analysis
%        Part 2. collect single cell birth size and instantaneous growth rates
%        Part 3. organize data
%        Part 4. plot data from Nguyen et al.
%        Part 5. overlay data from Taheri et al.


%  Last edit: Jen Nguyen, 2021 March 29
%  Commit: revise for sharing final version of Supplementary Fig 5c and d

%  OK let's go!


%% Part 1. initialize analysis

clear 
clc

% 0. initialize complete meta data
%cd('/Users/jen/Documents/StockerLab/Data_analysis/')
source_data = '/Users/jen/Documents/StockerLab/Source_data';
cd(source_data)
load('storedMetaData.mat')
dataIndex = find(~cellfun(@isempty,storedMetaData));


% 0. define method of calculating growth rate
specificGrowthRate = 'log2';
specificColumn = 3;             % for selecting appropriate column in growthRates


% 0. create array of experiments to use in analysis
exptArray = [2,3,4,5,6,7,9,10,11,12,13,14,15]; % use corresponding dataIndex values


% 0. initialize data vectors to store stats for each experiment
compiled_data = cell(length(exptArray),1);
compiled_mu = cell(length(exptArray),1);


%% Part 2. collect single cell data from steady conditions of all experiments

%  to compare with Taheri-Araghi data: birth length, tau and lambda


% 1. loop through each experiment to collect data
for e = 1:length(exptArray)

    
    % 2. initialize experiment meta data
    index = exptArray(e);
    date = storedMetaData{index}.date;
    expType = storedMetaData{index}.experimentType;
    bubbletime = storedMetaData{index}.bubbletime;
    xys = storedMetaData{index}.xys;
    disp(strcat(date, ': analyze!'))
    
    
    
    % 3. initialize experiment specific variables
    ccData = cell(length(bubbletime),1);
    mu_instantaneous = cell(length(bubbletime),1);
    
    
    
    % 4. load measured experiment data    
    experimentFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',date);
    cd(experimentFolder)
    filename = strcat('lb-fluc-',date,'-c123-width1p4-c4-1p7-jiggle-0p5.mat');
    load(filename,'D5','T');

    
    % for each steady condition in experiment
    for condition = 2:length(bubbletime)
            
            
        % 5. compile condition data matrix
        %    NOTE: compiling each condition separately restarts the curveFinder count at 1 per condition
        xy_start = min(xys(condition,:));
        xy_end = max(xys(condition,:));
        conditionData = buildDM(D5, T, xy_start, xy_end,index,expType);
        clear xy_start xy_end date filename
        
        
        
        % 6. calculate growth rate before trimming
        %     i) isolate required parameters
        volumes = getGrowthParameter(conditionData,'volume');            % calculated va_vals (cubic um)
        timestamps_sec = getGrowthParameter(conditionData,'timestamp');  % timestamp in seconds
        isDrop = getGrowthParameter(conditionData,'isDrop');             % isDrop, 1 marks a birth event
        curveFinder = getGrowthParameter(conditionData,'curveFinder');   % curve finder (ID of curve in condition)
        trackNum = getGrowthParameter(conditionData,'trackNum'); 
        
        %   ii) perform growht rate calculation
        growthRates_all = calculateGrowthRate(volumes,timestamps_sec,isDrop,curveFinder,trackNum);
        growthRates = growthRates_all(:,specificColumn);
        clear volumes isDrop trackNum timestamps_sec
        
        
          
        % 7. trim condition and growth rate data to include only full cell cycles
        conditionData_fullOnly = conditionData(curveFinder > 0,:);
        growthRates_fullOnly = growthRates(curveFinder > 0,:);
        curveIDs_fullOnly = curveFinder(curveFinder > 0,:);   % for trimming growth rate
        curveIDs_unique = unique(curveIDs_fullOnly);          % for assigning birth sizes
        trackNums = getGrowthParameter(conditionData_fullOnly,'trackNum');         % track number (not ID from particle tracking)
        clear curveFinder growthRates growthRates_all conditionData
        
             
        
        % 8. isolate timestamp, isDrop, width, length, surface area and volume data for cell cycle measurements
        timestamps = getGrowthParameter(conditionData_fullOnly,'timestamp');  % timestamp in seconds
        timestamps_hr = timestamps./3600;    % convert timestamp to hours
        isDrop = getGrowthParameter(conditionData_fullOnly,'isDrop');      % isDrop, 1 marks a birth event
        majorAxis = getGrowthParameter(conditionData_fullOnly,'length');   % length (um)
        curveDuration = getGrowthParameter(conditionData_fullOnly,'curveDurations');  % length of cell cycle
        clear timestamps
        
        
        
        % 9. extract only final timeSinceBirth from each growth curve, this is the inter-division time!
        final_birthLength = majorAxis(isDrop==1);
        finalTimestamps = timestamps_hr(isDrop==1); % experiment timestamp (hours) of each division event.
        final_durations = curveDuration(isDrop==1);
        final_trackNums = trackNums(isDrop==1);
        clear conditionData_fullOnly timestamps_hr
        
        
        
        % 10. remove zeros, which occur if no full track data exists at a drop
        Lbirth = final_birthLength(final_birthLength > 0);
        birthTimestamps = finalTimestamps(final_birthLength > 0);
        curveIDs = curveIDs_unique(final_birthLength > 0);
        durations = final_durations(final_birthLength > 0);
        tracks = final_trackNums(final_birthLength > 0);
        clear final_birthLength finalTimestamps final_durations majorAxis curveDuration final_trackNums
        
        
        
        % 11. truncate data to non-erroneous (e.g. bubbles) timestamps
        %     Note: trimming first by coursest time resolution, which is for the cell cycle.
        %           later we will trim all growth rate data that are not associated with cell cycles remaining in analysis
        data = [Lbirth birthTimestamps curveIDs durations tracks];
        maxTime = bubbletime(condition);
        
        if maxTime > 0
            data_bubbleTrimmed = data(birthTimestamps <= maxTime,:);
            birthTimestamps_bubbleTrimmed = birthTimestamps(birthTimestamps <= maxTime,:);
        else
            data_bubbleTrimmed = data;
            birthTimestamps_bubbleTrimmed = birthTimestamps;
        end
        clear timestamps_hr maxTime birthTimestamps data isDrop Lbirth curveIDs durations tracks
        
        
        
        % 12. truncate data to stabilized regions
        minTime = 3;
        data_fullyTrimmed = data_bubbleTrimmed(birthTimestamps_bubbleTrimmed >= minTime,:);       
        clear data_bubbleTrimmed birthTimestamps_bubbleTrimmed minTime
        
        
        
        % 13. isolate size from time and cell cycle information, in
        %     preparation to trim by outliers based on cell volume
        data_length = data_fullyTrimmed(:,1);
        data_timestamps = data_fullyTrimmed(:,2);
        data_curves = data_fullyTrimmed(:,3);
        data_tau = data_fullyTrimmed(:,4);
        data_trackNum = data_fullyTrimmed(:,5);
        clear data_fullyTrimmed
        
        
        
        % 14. if no div data in steady-state, skip condition
        if isempty(data_curves) == 1
            continue
        else
            
            % 15. trim outliers (those 3 std dev away from median) from final dataset
            
            % i. determine median and standard deviation of birth size
            len_median = median(data_length);
            len_std_temp = std(data_length);
            
            % ii. remove cell cycles of WAY LARGE birth size, tracking IDs
            len_temp = data_length(data_length <= (len_median+len_std_temp*3),:); % cut largest vals, over 3 std out
            time_temp = data_timestamps(data_length <= (len_median+len_std_temp*3),:);
            IDs_temp = data_curves(data_length <= (len_median+len_std_temp*3));
            tau_temp = data_tau(data_length <= (len_median+len_std_temp*3));
            track_temp = data_trackNum(data_length <= (len_median+len_std_temp*3));
            clear data_curves data_length
            
            % iii. remove cell cycle of WAY SMALL birth size, tracking IDs
            len_final = len_temp(len_temp >= (len_median-len_std_temp*3),:);          % cut smallest vals, over 3 std out 
            times_final = time_temp(len_temp >= (len_median-len_std_temp*3),:); 
            IDs_final = IDs_temp(len_temp >= (len_median-len_std_temp*3));   
            tau_final = tau_temp(len_temp >= (len_median-len_std_temp*3));
            trackNum_final = track_temp(len_temp >= (len_median-len_std_temp*3));
            clear len_median len_std_temp len_temp IDs_temp tau_temp track_temp time_temp
            
            % iv. remove corresponding growth rates from datasets
            trimmedIDs = setdiff(curveIDs_unique,IDs_final);    % curve IDs in growth rate dataset, NOT in final IDs trimmed by cell cycle
            toTrim = ismember(curveIDs_fullOnly,trimmedIDs);   % vector of what to trim or not in growth rate
            trimmed_curves_insta = curveIDs_fullOnly(toTrim == 0);
            trimmed_mus = growthRates_fullOnly(toTrim == 0);
            clear toTrim trimmedIDs curveIDs_fullOnly growthRates_fullOnly curveIDs_unique
            
 
            
            % 16. bin growth rates by cell cycle, to match organization of birth size data
            mus_binned = accumarray(trimmed_curves_insta,trimmed_mus,[],@(x) {x});
            mus = mus_binned(~cellfun('isempty',mus_binned));
            lambdas = cellfun(@nanmean,mus);
            clear trimmed_curves_insta trimmed_mus mus_binned
            
        
            
            % 17. store condition data into one variable per experiment
            cc_data = [IDs_final len_final lambdas tau_final/60 trackNum_final times_final]; % tau here is converted from sec to min
            
            ccData{condition} = cc_data;
            mu_instantaneous{condition} = mus;
        
            
        end
        clear IDs_final len_final lambdas tau_final trackNum_final times_final mus
        
    end
      
    % 18. store experiment data into single variable for further analysis
    compiled_data{e} = ccData;
    compiled_mu{e} = mu_instantaneous;
    
    clear ccData mu_instantaneous bubbletime
end


% 19. save hard earned data
cd('/Users/jen/growing-up/FigureS5/')
save('figS5C.mat','compiled_data','compiled_mu','exptArray')


%% Part 3. sort data by nutrient condition

% goal: plot of newborn cell size vs growth rate,
%       mean of each condition replicate

% strategy: 
%
%       i. accumulate data from each condition
%          conditions: each steady and each fluctuating timescale (7 total)
%
%      ii. calculate mean birth size and growth rate for each condition (population data)
%          plot each condition as a closed orange point and fit a line (the growth law ACROSS conditions)
%
%     iii. bin individual data by growth rate
%
%      iv. calculate mean birth size and growth rate for each bin (individual data)
%          plot each bin as an open blue point and fit a line WITHIN each condition


clear
clc

% 0. initialize complete meta data
cd('/Users/jen/growing-up/FigureS5/')
load('storedMetaData.mat')
load('figS5C.mat')
lamb = 3;  % column in compiled_data that is lambda
majAx = 2; % column in compiled_data that is length at birth
tau = 4;   % column in compiled_data that is interdivision time


% 0. initialize plotting parameters
palette = {'Indigo','GoldenRod','FireBrick'};
environment_order = {'low','ave','high'};
shape = 'o';


% 1. accumulate data from each condition
%fluc = 1; 
low = 2; % row number in data structure
ave = 3; 
high = 4;


sigmas = 3;
for ee = 1:length(environment_order)
    
    condition = environment_order{ee};
    
    if ischar(condition) == 1
        
        % steady environment! concatenate data based on nutrient level
        if strcmp(condition,'low') == 1
            
            lambda_low = [];
            birthLength_low = [];
            tau_low = [];
            
            % loop through all experiments and store low data
            for expt = 1:length(compiled_data)
                
                expt_data = compiled_data{expt,1}{low,1};
                if ~isempty(expt_data)
                    
                    % isolate data
                    expt_lambda = compiled_data{expt,1}{low,1}(:,lamb); % note: mu is all instananeous vals in each cell cycle
                    expt_lengths = compiled_data{expt,1}{low,1}(:,majAx);
                    expt_taus = compiled_data{expt,1}{low,1}(:,tau);
                    
                    % concanetate individual cell cycle values
                    lambda_low = [lambda_low; expt_lambda];
                    birthLength_low = [birthLength_low; expt_lengths];
                    tau_low = [tau_low; expt_taus];
                    clear expt_lambda expt_lengths expt_taus
                end
                
            end
            clear expt expt_data
            
            condition_lambda = lambda_low;
            condition_lengths = birthLength_low;
            condition_tau = tau_low;
            
            % isolate cycles within some error of replicate
            condition_mean = nanmean(condition_lambda);
            condition_std = nanstd(condition_lambda);
            
            lower = condition_lambda < condition_mean + (condition_std * sigmas);
            upper = condition_lambda > condition_mean - (condition_std * sigmas);
            combined = lower + upper;
            
            range_lambda = condition_lambda(combined == 2);
            range_length = condition_lengths(combined == 2,:);
            range_tau = condition_tau(combined == 2,:);
            clear condition_mean condition_std lower upper
            
            
            % store condition data
            birthLengths{2} = range_length;
            lambda{2} = range_lambda;
            divTimes{2} = range_tau;
            
            
        elseif strcmp(condition,'ave') == 1
            
            lambda_ave = [];
            birthSizes_ave = [];
            tau_ave = [];
            
            % loop through all experiments and store ave data
            for expt = 1:length(compiled_data)
                
                expt_data = compiled_data{expt,1}{ave,1};
                if ~isempty(expt_data)
                    
                    % isolate data
                    expt_lambda = compiled_data{expt,1}{ave,1}(:,lamb); % note: mu is all instananeous vals in each cell cycle
                    expt_lengths = compiled_data{expt,1}{ave,1}(:,majAx);
                    expt_taus = compiled_data{expt,1}{ave,1}(:,tau);
                    
                    % concanetate individual cell cycle values
                    lambda_ave = [lambda_ave; expt_lambda];
                    birthSizes_ave = [birthSizes_ave; expt_lengths];
                    tau_ave = [tau_ave; expt_taus];
                    clear expt_lambda expt_lengths expt_taus
                    
                end
            end
            clear expt expt_data
            
            
            condition_lambda = lambda_ave;
            condition_length = birthSizes_ave;
            condition_tau = tau_ave;
            
            % isolate cycles within 3 st dev of mean
            condition_mean = nanmean(condition_lambda);
            condition_std = nanstd(condition_lambda);
            
            lower = condition_lambda < condition_mean + (condition_std * sigmas);
            upper = condition_lambda > condition_mean - (condition_std * sigmas);
            combined = lower + upper;
            
            range_lambda = condition_lambda(combined == 2);
            range_length = condition_length(combined == 2,:);
            range_tau = condition_tau(combined == 2,:);
            clear condition_mean condition_std lower upper
            
            % store condition data
            lambda{3} = range_lambda;
            birthLengths{3} = range_length;
            divTimes{3} = range_tau;
            
            
        elseif strcmp(condition,'high') == 1
            
            lambda_high = [];
            birthSizes_high = [];
            tau_high = [];
            
            % loop through all experiments and store high data
            for expt = 1:length(compiled_data)
                
                expt_data = compiled_data{expt,1}{high,1};
                if ~isempty(expt_data)
                    
                    % isolate data
                    expt_lambda = compiled_data{expt,1}{high,1}(:,lamb); % note: mu is all instananeous vals in each cell cycle
                    expt_lengths = compiled_data{expt,1}{high,1}(:,majAx);
                    expt_taus = compiled_data{expt,1}{high,1}(:,tau);
                    
                    % concanetate individual cell cycle values
                    lambda_high = [lambda_high; expt_lambda];
                    birthSizes_high = [birthSizes_high; expt_lengths];
                    tau_high = [tau_high; expt_taus];
                    clear expt_lambda expt_lengths expt_taus
                    
                end
            end
            clear expt expt_data
            
            condition_lambda = lambda_high;
            condition_length = birthSizes_high;
            condition_tau = tau_high;
            
            % isolate cycles within 3 st dev of mean
            condition_mean = nanmean(condition_lambda);
            condition_std = nanstd(condition_lambda);
            
            lower = condition_lambda < condition_mean + (condition_std * sigmas);
            upper = condition_lambda > condition_mean - (condition_std * sigmas);
            combined = lower + upper;
            
            range_lambda = condition_lambda(combined == 2);
            range_length = condition_length(combined == 2,:);
            range_tau = condition_tau(combined == 2,:);
            clear condition_mean condition_std lower upper
            
            % store condition data in cell corresponding to Condition Order
            lambda{4} = range_lambda;
            birthLengths{4} = range_length;
            divTimes{4} = range_tau;
            
        end
    
    end
end

clear low ave high condition ee expt arrayIndex combined
clear condition_lambda condition_length  condition_tau range_lambda range_length range_tau 
clear birthLength_low birthSizes_ave birthSizes_high lambda_low lambda_ave lambda_high
clear tau_low tau_ave tau_high


%% Part 4. plot cell size at birth vs mean growth rate (lambda) and best fit line from steady points

% 1. calculate mean birth size and growth rate for each condition (population data)
pop_length = cellfun(@mean,birthLengths,'UniformOutput',false);
pop_lambda = cellfun(@mean,lambda);
pop_tau = cellfun(@mean,divTimes);


% 2. plot length at birth vs. growth rate
figure(1)
steady_lengths = nan(1,3);
for ii = 1:3
    cond = ii+1;    
    steady_lengths(ii) = pop_length{cond};
    color = rgb(palette(ii));
    plot(pop_lambda(cond),log(pop_length{cond}),'Color',color,'Marker',shape,'MarkerSize',10,'LineWidth',2)
    hold on
end



% 3. plot division time vs. growth rate
figure(2)
steady_lengths = nan(1,3);
for ii = 1:3
    cond = ii+1;    
    steady_lengths(ii) = pop_length{cond};
    color = rgb(palette(ii));
    plot(pop_lambda(cond),pop_tau(cond),'Color',color,'Marker',shape,'MarkerSize',10,'LineWidth',2)
    hold on
end
ylabel('tau')
xlabel('lambda')



clear color cc cond ii


%% Part 5. overlay data from Taheri-Araghi et al. 2014

% 0. initiate data copied from Table S3 of Taheri-Araghi et al. Current Biology (2014)

% column 1 = mean
% column 2 = std
taheri_conditions = {'TSB'; 'synth_rich'; 'glc12'; 'glc6'; 'glucose'; 'sorbitol'; 'glycerol'};
taheri_lambdas = [0.0569, 0.0045; 0.0433,0.0032; 0.0372,0.0021; 0.0330,0.0022; 0.0270,0.0016; 0.0187,0.0020; 0.0189,0.0018]; % 1/min
taheri_birth_lengths = [3.9839,0.7170; 3.3361,0.5005; 2.8754,0.3268; 2.3564,0.2747; 2.1091,0.2429; 2.2672,0.3510; 2.0789,0.2936]; % um
taheri_taus = [17.0861,3.7549; 22.5043,4.6321; 26.6143,3.7947; 30.1391,4.6266; 37.6550,5.8287; 50.9376,9.6385; 51.4759,9.6270]; % min


% 1. growth rate vs. length at birth plot
figure(1)
hold on
scatter(taheri_lambdas(:,1)*60,log(taheri_birth_lengths(:,1)),'MarkerFaceColor',rgb('SlateGray'))


% 2. determine best fit line
steady_lambda = pop_lambda(2:4);
fit = polyfit(steady_lambda,log(steady_lengths),1);
clear steady_lambda


% 3. plot best fit line
x = linspace(0,4,100);
y = fit(1)*x + fit(2);
figure(1)
hold on
plot(x,y,'Color',rgb('SlateGray'))
ylabel('ln( Lbirth )')
xlabel('lambda')
xlim([0.5 4])
legend('low','ave','high','Taheri et al. 2015','Nguyen et al. (this paper)')


% 4. growth rate vs. interdivision time
figure(2)
hold on
scatter(taheri_lambdas(:,1)*60,taheri_taus(:,1),'MarkerFaceColor',rgb('SlateGray'))


% 5. plot expected (inverse) relationship
y2 = (1./x)*60; % 60 multiplier converts from h to min
figure(2)
hold on
plot(x,y2,'Color',rgb('SlateGray'))
xlim([0.5 4])
legend('low','ave','high','Taheri et al. 2015','y=1/x')


clear y y2 x fit
