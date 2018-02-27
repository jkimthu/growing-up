% nutrientScore


% goal: devise a quantitative measure of a cell's nutrient experience

% strategy:

%       0.  initialize timestamp and curve data
%       1.  split timestamps into quarters
%       2.  from corrected timestamps, generate a binary nutrient signal, where: 1 = high and 0 = low           
%       3.  calculate nScore for each curve in each track
%               4.  for each track, isolate curve and binary nutrient signal
%               5.  determine whether track contains any full curves
%               5i. if not, score of track = NaN
%               5ii. else, if track contains at least one full curve
%                       6.  for each curve, isolate nutrient signal
%                       7.  calculate score = sum(signal)/length(signal)
%                       8.  save score
%               8.  concatenate scores for all tracks
%       9.  output binaryNutrientSignal and nScore vectors for entire condition

% last update: jen, 2018 Feb 27

% commit: function takes condition data and timescale to calculate nutrient
%         score, being the fraction of time spent in high nutrient per cell
%         cycle


function [binaryNutrientSignal, nScore] = nutrientScore(timescale,conditionData)


% 0. initialize timestamp and volume data
correctedTime = conditionData(:,30);           % col 30  = timestamps, reflecing true time for all conditions in sec
curveID = conditionData(:,6);                  % col 6  =  curve ID per track
trackNum = conditionData(:,27);                % col 27 =  track number, not ID from particle tracking
condVals = conditionData(:,28);                % col 28 =  condition number


% 0. check that conditionData contains only one condition
%    if more, report error
if length(unique(condVals)) > 1
    
    error('ERROR: nutrientSource function requires that conditionData contain only ONE condition')
    % single condition is a requirement, because downstream, nScore
    % calculations and assignments require that track numbers NOT be repeated
    
end


% 1. split timestamps into quarters
timeInPeriods = correctedTime/timescale; % unit = sec/sec
timeInPeriodFraction = timeInPeriods - floor(timeInPeriods);
timeInQuarters = ceil(timeInPeriodFraction * 4);


% 2. from corrected timestamps, generate a binary nutrient signal where, 1 = high and 0 = low
binaryNutrientSignal = zeros(length(timeInQuarters),1);
binaryNutrientSignal(timeInQuarters == 1) = 1;
binaryNutrientSignal(timeInQuarters == 4) = 1;


% 3. calculate nScore for each curve in each track

nScore = [];
for tr = 1:max(trackNum)
    
    % 4. for each track, isolate curve and binary nutrient signal
    currentTrack_signal = binaryNutrientSignal(trackNum == tr);
    currentTrack_curves = curveID(trackNum == tr);
    
    % 5. determine whether track contains any full curves
    if sum(currentTrack_curves) == 0
        
        % if no full curves, score for track = NaN
        trackScore = NaN(length(currentTrack_signal),1);
        
    else
        
        % 6. for each curve,
        trackScore = NaN(length(currentTrack_signal),1);
        
        for cc = 1:max(currentTrack_curves)
            
            % 6. isolate nutrient signal
            currentCurve_signal = currentTrack_signal(currentTrack_curves == cc);
            
            % 7. calculate score
            score = sum(currentCurve_signal) / length(currentCurve_signal);
            
            % 8. save score
            trackScore(currentTrack_curves == cc) = score;
            
        end
        
    end
    
    % 8. concatenate scores for all tracks
    nScore = [nScore; trackScore];
    
end


% 9. output binaryNutrientSignal and nScore vectors for entire condition

end % end nutrientScore function