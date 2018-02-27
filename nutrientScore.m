% nutrientScore


% goal: devise a quantitative measure of a cell's nutrient experience

% for strategies, see comments preceding each version below

% last update: jen, 2018 Feb 27

% commit: previous version broke down at faster timescales. the actual
% sampling rate (imaging) too slow, creating biases in score. this version
% gets around this limitation by artificially increasing the sampling rate,
% and calculating nScore from this more resolved time vector.

%% version one
% % convert timestamps to nutrient score, lower resolution especially at
% % faster timescales

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
% 


% function [binaryNutrientSignal, nScore] = nutrientScore(timescale,conditionData)
% 
% 
% % 0. initialize timestamp and volume data
% correctedTime = conditionData(:,30);           % col 30  = timestamps, reflecing true time for all conditions in sec
% curveID = conditionData(:,6);                  % col 6  =  curve ID per track
% trackNum = conditionData(:,27);                % col 27 =  track number, not ID from particle tracking
% condVals = conditionData(:,28);                % col 28 =  condition number
% 
% 
% % 0. check that conditionData contains only one condition
% %    if more, report error
% if length(unique(condVals)) > 1
%     
%     error('ERROR: nutrientSource function requires that conditionData contain only ONE condition')
%     % single condition is a requirement, because downstream, nScore
%     % calculations and assignments require that track numbers NOT be repeated
%     
% end
% 
% 
% % 1. split timestamps into quarters
% timeInPeriods = correctedTime/timescale; % unit = sec/sec
% timeInPeriodFraction = timeInPeriods - floor(timeInPeriods);
% timeInQuarters = ceil(timeInPeriodFraction * 4);
% 
% 
% % 2. from corrected timestamps, generate a binary nutrient signal where, 1 = high and 0 = low
% binaryNutrientSignal = zeros(length(timeInQuarters),1);
% binaryNutrientSignal(timeInQuarters == 1) = 1;
% binaryNutrientSignal(timeInQuarters == 4) = 1;
% 
% 
% % 3. calculate nScore for each curve in each track
% 
% nScore = [];
% for tr = 10%1:max(trackNum)
%     
%     % 4. for each track, isolate curve and binary nutrient signal
%     currentTrack_signal = binaryNutrientSignal(trackNum == tr);
%     currentTrack_curves = curveID(trackNum == tr);
%     
%     % 5. determine whether track contains any full curves
%     if sum(currentTrack_curves) == 0
%         
%         % if no full curves, score for track = NaN
%         trackScore = NaN(length(currentTrack_signal),1);
%         
%     else
%         
%         % 6. for each curve,
%         trackScore = NaN(length(currentTrack_signal),1);
%         
%         for cc = 1:max(currentTrack_curves)
%             
%             % 6. isolate nutrient signal
%             currentCurve_curve = currentTrack_curves(currentTrack_curves == cc)
%             currentCurve_signal = currentTrack_signal(currentTrack_curves == cc);
%             
%             % 7. calculate score
%             score = mean(currentCurve_signal);
%             
%             % 8. save score
%             trackScore(currentTrack_curves == cc) = score;
%             
%         end
%         
%     end
%     
%     % 8. concatenate scores for all tracks
%     nScore = [nScore; trackScore];
%     
% end
% 
% 
% % 9. output binaryNutrientSignal and nScore vectors for entire condition
% 
% end % end nutrientScore function

%% version two
% use timestamps of birth and division to calculate higher resolution
% nutrient score

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


% 1. calculate nScore for each track
nScore = [];

for tr = 1:max(trackNum)
       
    % 2. isolate full curves and corresponding timestamps (lag corrected)
    currentTrack_curves = curveID(trackNum == tr);
    currentTrack_times = correctedTime(trackNum == tr);
    
    % 3. determine whether track contains any full curves
    if sum(currentTrack_curves) == 0
        
        % 4. if no full curves, score for track = NaN
        trackScore = NaN(length(currentTrack_curves),1);
        
    else
        
        % 5. if full curves are present, for each curve
        trackScore = NaN(length(currentTrack_curves),1);
        for cc = 1:max(currentTrack_curves)
            
            % 6. determine time of birth and time of division
            currentCurve_indeces = find(currentTrack_curves == cc);
            time_ofBirth = currentTrack_times(min(currentCurve_indeces));
            time_ofDivision = currentTrack_times(max(currentCurve_indeces));
         
            % 7. generate an artificially resolved time vector between birth and division
            resolved_time = linspace(time_ofBirth,time_ofDivision,100000)'; % in min
            timeInPeriods = resolved_time/timescale; % unit = sec/sec
            timeInPeriodFraction = timeInPeriods - floor(timeInPeriods);
            timeInQuarters = ceil(timeInPeriodFraction * 4);
            
            % 8. from corrected timestamps, generate a binary nutrient signal where, 1 = high and 0 = low
            binaryNutrientSignal = zeros(length(timeInQuarters),1);
            binaryNutrientSignal(timeInQuarters == 1) = 1;
            binaryNutrientSignal(timeInQuarters == 4) = 1;
            
            % 9. calculate score
            score = mean(binaryNutrientSignal);
            
            % 10. save score
            trackScore(currentCurve_indeces) = score;
            
        end
        
    end
    % 11. concatenate scores for all tracks
    nScore = [nScore; trackScore];
    
end

% 12. output binaryNutrientSignal and nScore vectors for entire condition

end % end nutrientScore function
