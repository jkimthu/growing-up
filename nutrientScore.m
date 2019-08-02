% nutrientScore


% goal: devise a quantitative measure of a cell's nutrient experience,
%       using timestamps of birth and division to calculate a nutrient score

% note: input data matrix need to be trimmed such that it contains full
%       curves only

% strategy:

%       0. initialize timestamp and volume data
%       0. check that conditionData contains only one condition. if more, report error
%       1. calculate nScore for each track
%               2. isolate full curves and corresponding timestamps (lag corrected)
%               3. determine whether track contains any full curves
%               4. if no full curves, score for track = NaN
%               5. if full curves are present, for each curve
%                       6. determine time of birth and time of division
%                       7. generate an artificially resolved time vector between birth and division
%                       8. from corrected timestamps, generate a binary nutrient signal where, 1 = high and 0 = low
%                       9. calculate score
%                      10. save score
%              11. concatenate scores for all tracks
%      12. output binaryNutrientSignal and nScore vectors for entire condition


% last update: jen, 2019 March 12
% commit: edit parameter acquisition and allow for tracks with curve IDs that don't start with 1

% ok let's go!

%% 

function [binaryNutrientSignal, nScore] = nutrientScore(timescale,dm)


% 0. initialize timestamp and volume data
correctedTime = getGrowthParameter(dm,'correctedTime');    % timestamp in sec, corrected for lag in signal between junc and cell xy
curveID = getGrowthParameter(dm,'curveFinder');            % curve ID of each individual cell cycle
trackNum = getGrowthParameter(dm,'trackNum');              % track number, not ID from particle tracking
condVals = getGrowthParameter(dm,'condition');                                       % condition number (1 = fluc, etc)


% 0. check that conditionData contains only one condition
%    if more, report error
if length(unique(condVals)) > 1
    
    error('ERROR: nutrientSource function requires that conditionData contain only ONE condition')
    % single condition is a requirement, because downstream, nScore
    % calculations and assignments require that track numbers NOT be repeated
    
end


% 1. calculate nScore for each track
nScore = [];
binaryNutrientSignal = [];

for tr = 1:max(trackNum)
       
    % 2. isolate full curves and corresponding timestamps (lag corrected)
    currentTrack_curveID = curveID(trackNum == tr);
    currentTrack_curves = currentTrack_curveID(currentTrack_curveID > 0);
    currentTrack_times = correctedTime(trackNum == tr);
    
    % 3. determine whether track contains any full curves
    if sum(currentTrack_curves) == 0
        
        % 4. if no full curves, score for track = NaN
        trackScore = NaN(length(currentTrack_curves),1);
        trackBNS = NaN(length(currentTrack_curves),1);
        
    else
        
        % 5. if full curves are present, for each curve
        trackScore = NaN(length(currentTrack_curveID),1);
        trackBNS = NaN(length(currentTrack_curves),1);
        for cc = min(currentTrack_curves):max(currentTrack_curves)
            
            % 6. determine time of birth and time of division
            currentCurve_indeces = find(currentTrack_curveID == cc);
            time_ofBirth = currentTrack_times(min(currentCurve_indeces));
            time_ofDivision = currentTrack_times(max(currentCurve_indeces));
         
            % 7. generate an artificially resolved time vector between birth and division
            resolved_time = linspace(time_ofBirth,time_ofDivision,100000)'; % in min
            resolved_timeInPeriods = resolved_time/timescale; % unit = sec/sec
            resolved_timeInPeriodFraction = resolved_timeInPeriods - floor(resolved_timeInPeriods);
            resolved_timeInQuarters = ceil(resolved_timeInPeriodFraction * 4);
            
            % 8. from corrected timestamps, generate a binary nutrient signal where, 1 = high and 0 = low
            resolvedBNS = zeros(length(resolved_timeInQuarters),1);
            resolvedBNS(resolved_timeInQuarters == 1) = 1;
            resolvedBNS(resolved_timeInQuarters == 4) = 1;
            
            % 9. calculate score
            score = mean(resolvedBNS);
            
            % 10. save score
            trackScore(currentCurve_indeces) = score;
            
            % 11. save binary signal
            time_ofCurve = currentTrack_times(currentCurve_indeces);
            timeInPeriods = time_ofCurve/timescale; % unit = sec/sec
            timeInPeriodFraction = timeInPeriods - floor(timeInPeriods);
            timeInQuarters = ceil(timeInPeriodFraction * 4);
            
            curveBNS = zeros(length(timeInQuarters),1);
            curveBNS(timeInQuarters == 1) = 1;
            curveBNS(timeInQuarters == 4) = 1;
            trackBNS(currentCurve_indeces) = curveBNS;
            
            
        end
        
    end
    % 11. concatenate scores for all tracks
    nScore = [nScore; trackScore];
    binaryNutrientSignal = [binaryNutrientSignal; trackBNS];
    
    
end

% 12. output binaryNutrientSignal and nScore vectors for entire condition

end % end nutrientScore function
