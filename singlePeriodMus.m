% timestamp-dependent distributions of dataMatrix parameters



%  Goal: plot average growth rate per period fraction

%  Last edit: Jen Nguyen, March 15th 2017



%  Sample code pulled from distributions.m and nsyncInFlux.m
%  Strategy:
%
%     0. initialize experiment and analysis parameters
%     1. isolate data of interest
%     2. accumulate data points by time bin (period fraction)
%     3. plot for all isolated groups


%%
clear

% 0. Load workspace from SlidingFits.m    
load('t3600_2017-01-12-Mus-length.mat');
load('meta.mat');

%%
% 0. Initialize period fractioning
periodLength = 3600;                         % in seconds
binsPerPeriod = 20;

%%
for i = 1:2:3
    
    % initize vectors for data accumulation
    muTrack = [];
    timeTrack = [];
    
    % designate times to trim
    minTime = meta(i,3);
    maxTime = meta(i,4);
    
    for n = meta(i,1):meta(i,2)
        for m = 1:length(M6{n})
            
            %  assemble all instantaneous growth rates into a single vector
            muTrack = [muTrack; M6{n}(m).Parameters(:,1)];
            
            %  assemble a corresponding timestamp vector
            vectorLength = length(M6{n}(m).Parameters(:,1));
            trackFrames = D6{n}(m).Frame(3:vectorLength+2);
            timeTrack = [timeTrack; T{n}(trackFrames)];
            
        end
    end
    
    %trim times to only stable
    timeTrack(timeTrack < minTime*3600) = NaN;
    timeTrack(timeTrack > maxTime*3600) = NaN;
    timeFilter = find(~isnan(timeTrack));
    muTrack = muTrack(timeFilter);
    timeTrack = timeTrack(timeFilter);
    
    timeWarp = timeTrack/periodLength; % units = seconds/seconds
    floorWarp = floor(timeWarp);
    timeWarp = timeWarp - floorWarp;
    rightBin = timeWarp * binsPerPeriod;
    rightBin = ceil(rightBin);
    
    % replace all values of Mu > 1 or Mu <= 0 with NaN
    trimmedMu = muTrack;
    trimmedMu(trimmedMu > 1) = NaN;
    trimmedMu(trimmedMu <= 0) = NaN;
    
    % remove NaNs from data sets
    nanFilter = find(~isnan(trimmedMu));
    trimmedMu = trimmedMu(nanFilter);
    trimmedTime = rightBin(nanFilter);
    

    muMeans = accumarray(trimmedTime,trimmedMu,[],@nanmean);
    muSTDs = accumarray(trimmedTime,trimmedMu,[],@nanstd);
    
    %   calculate s.e.m.
    %   count number of total tracks in each bin
    for j = 1:binsPerPeriod
        currentBin_count = find(rightBin==j);
        counter = 1;
        
        for k = 2:length(currentBin_count)
            if currentBin_count(k) == currentBin_count(k-1)+1;
                counter = counter;
            else
                counter = counter + 1;
            end
        end
        muCounts(j) = counter;
        clear k counter;
    end
    
    %   2. divide standard dev by square root of tracks per bin
    muSEMs = muSTDs./sqrt(muCounts');
    

    errorbar(muMeans,muSEMs)
    hold on
    grid on
    axis([0.8,20.2,0.15,.35])
    xlabel('Time')
    ylabel('Elongation rate (1/hr)')

end

%%
% 2. determine bin size for mu
    

    
    
    % 4. calculate mean, std, n, and error
    meanStage = cell2mat( cellfun(@nanmean,binnedByMu,'UniformOutput',false) );
    stdStage = cell2mat( cellfun(@nanstd,binnedByMu,'UniformOutput',false) );
    nStage = cell2mat( cellfun(@length,binnedByMu,'UniformOutput',false) );
    errorStage = stdStage./sqrt(nStage);

