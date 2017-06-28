%% slidingFits_helpfulNeighbors

% Goal: a method of calculating doubling rate (mu), in which we use the
% points in a neighboring curve to add more points for fitting.
% 
% Strategy:
%
%       0. initialize trimmed track data
%       0. initialize window parameters (number of frames)
%       0. initialize division parameters (drop threshold)
%       1. for each movie, identify the number of tracks
%                2. per track, isolate length and time data
%                        3. build an array with length(track) that identifies curve #
%                                i. identify all changes in size > threshold (30% loss of previous size)
%                               ii. starting with zero, list curve # for each frame
%                        4. identify all windows for that track
%                        5. per window, build an array of "effective length"
%                                6. use "effective length" to calculate mu
%                                      i. ln(effective length) vs time
%                                     ii. fit linear slope to ln(eL) vs time
%                                    iii. mu = slope / ln(2)
%                                7. save mu and y-intercept
%                        8. repeat for all windows
%                9. repeat for all tracks
%       10. repeat for all movies


% last update: jen, 2017 Jun 28

% OK lez go!

%%
% testing mu calculations
doublingRate = 1.0000;
t = [0,1,2,3,4];
data = 1 * 2.^(doublingRate*t);  % gives: data = [1,2,4,8,16]

ln_data = log(data);  % gives: ln_data = [0, 0.6931, 1.3863, 2.0794, 2.7726]

plot(t,data) % exponential
plot(t,ln_data) % linear

fitLine = polyfit(t,ln_data,1); % gives: fitLine = [0.6931, -0.0000]
                                % where: slope = fitLine(1)
                                %        y-int = fitLine(2)
                                
mu = fitLine(1)/log(2);         % gives: mu = 1
                                % woot! we found the doublingRate from the data!
                         
%%

% 0. initialize trimmed track data
load('letstry-2017-06-12-autoTrimmed-scrambled-proportional.mat','Scram6','T');
D6 = Scram6;
numMovies = length(D6);


% 0. initialize window parameters
windowSize = 5;


% 0. initialize division parameters
dropThreshold = -0.3;


%  1. for each movie, identify the number of tracks
n = 52;
numTracks = length(D6{n});



%  2. per track, isolate length and time data
track = 2;
trackLength = D6{n}(track).MajAx;
trackFrames = D6{n}(track).Frame;
trackTimes = T{n}(trackFrames);
trackID = D6{n}(track).TrackID;

%%
%  3. build an array that identifies curve #

% testing notes: n=52, m=1: has no divisions (trackID = 159, visualized and confirmed)
curveNum = zeros(length(trackFrames),1);

% i. identify all changes in size > threshold (30% loss of previous size)
sizeChange = diff(trackLength);
changeFraction = sizeChange./trackLength(1:end-1);
dropTrack = find(changeFraction <= dropThreshold);

currentCurve = 0;
nextCurve = 1;
if ~isempty(dropTrack)
    for i = 1:length(curveNum)
        if nextCurve <= length(dropTrack)
            curveNum(i) = currentCurve;
            
            if i == dropTrack(nextCurve)
                currentCurve = currentCurve+1;
                nextCurve = nextCurve+1;
            end
            
        else
            curveNum(i) = currentCurve;
        end
    end
end
% ii. starting with zero, list curve # for each frame
%%
%                
%                       
%                        4. identify all windows for that track
%                        5. per window, build an array of "effective length"
%                                6. use "effective length" to calculate mu
%                                      i. ln(effective length) vs time
%                                     ii. fit linear slope to ln(eL) vs time
%                                    iii. mu = slope / ln(2)
%                                7. save mu and y-intercept
%                        8. repeat for all windows
%                9. repeat for all tracks
%       10. repeat for all movies



