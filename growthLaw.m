% growthLaw


% last edit: jen nguyen, 2016 Nov 18

% inspired by Figure 2A of Taheri-Araghi, et al. (2015)
% which looks at population average and single cell data, plotting
% added size (delta = division size - birth size) vs. birth size


% the code below:
%   1.  per condition,
%   2.  per curve
%   3.  plot birth size vs growth rate (of full curve)
%   4.  plot average of all individuals per condition

% OK lez go!

%%

% condition one. 30 second fluctuations (data from 2016-10-10)


% initialize
homeFolder = cd('/Users/jen/Documents/Stocker Lab/Data/2016-10-10');

steadyState = [1 4 10; 2 4.5 7.5; 3 3 8; 4 2 8];
% [fluc Ti Tf; low Ti Tf; ave Ti Tf; high Ti Tf];
% where,
%       Ti = start of steady-state behavior (in hours)
%       Tf = end of steady-state behavior (in hours)

dataSets = {'dm2016-10-10-fluc.mat', 'dF_2016-10-10.mat';
            'dm2016-10-10-low.mat', 'dL_2016-10-10.mat';
            'dm2016-10-10-ave.mat', 'dA_2016-10-10.mat';
            'dm2016-10-10-high.mat', 'dH_2016-10-10.mat'};


for condition = 1:4         % [fluc low ave high];
    
    Ti = steadyState(condition,2);
    Tf = steadyState(condition,3);
    
    load(dataSets{condition,1});
    load(dataSets{condition,2});
    
    
   % criteria for measured curves:
    
   %       1. ccStage (col 9, dataMatrix) = integer
   %          if ccStage = NaN, then curve is not complete
    
   %       2. timestamps in curve are within Ti and Tf
    
    
    
   % program:
    
   % 1. isolate individual tracks (col 1), one by one
    skippedTrackCounter = 0;                                    % count tracks without curves
    curveCounter = 0;                                           % count curves analyzed
    
    totalTracks = max(dataMatrix(:,1));
    for track = 1:totalTracks
        
        targetTrack = find( dataMatrix(:,1)==track );           % get rows of target track
        isoTrack = dataMatrix(targetTrack,:);                   % isolate data for target track
        
   % 2. determine whether track contains any full curves
        
        max_ccStage = max( isoTrack(:,9) );
        noCurves = isnan( max_ccStage );                        % 1 = true, no curves
        if noCurves == 1                                        % if no full curves in track...
            skippedTrackCounter = skippedTrackCounter + 1;      % count tracks that do not meet criteria
            continue                                            % jump to next track (no curves to analyze)
            
        else                                                    % if there are curves... (yay!!)
            fullCurves = max( isoTrack(:,6) );                  % get number of full curves in track
            
    % 3. isolate curves in track, one by one
            
            for curve = 1:fullCurves                            % for each full curve in track
                curveCounter = curveCounter + 1;                % tally curve
                targetCurve = find( isoTrack(:,6)==curve );     % get rows of target curve
                isoCurve = isoTrack(targetCurve,:);             % isolate data for target curve
                            
    % 4. birth and division size, calculate added size          % added size = delta
                
                birthSize = min( isoCurve(:,3) );
                divSize = max( isoCurve(:,3) );
                Delta = divSize - birthSize;
                
    % 5. timestamp for start and end of curve
    
                Start = min( isoCurve(:,2) );
                End = max( isoCurve(:,2) );
                
    % 6. growth rate calculations
    
                instantMus = isoCurve(:,4);                     % isolate instantaneous Mus from sliding windows
                instantMus = instantMus( instantMus<1 );        % remove high outliers
                instantMus = instantMus( instantMus>0 );        % remove low outliers
                aveMu = mean( instantMus );                     % average instantaneous mus across entire curve
                
                LN2 = log(2);                                   % LN2 = ln(2), natural log
                curveDuration = End - Start;
                calcMu = log(divSize/birthSize) / (LN2*curveDuration);
    
    % 7. tabulate data!
                
                tabulatedData(curveCounter,:) = [track birthSize divSize Delta Start End aveMu calcMu];
                                                        
            end                                                 % end of loop through curves per track, section 3
        end                                                     % end of if statement checking presence of full curves, section 2
    end                                                         % end of loop through tracks per condition, section 1
    
    
    % 8. determine whether curve falls within Ti and Tf
                
    pastTi = find( tabulatedData(:,5) >= Ti );                  % identify rows (curves) starting at or after Ti 
    trimmedData = tabulatedData(pastTi,:);                      % trim rows (curves) starting before Ti
    
    underTf = find( trimmedData(:,6) <= Tf );                   % identify rows (curves) continuing past Tf
    dreamData = trimmedData(underTf,:);                         % trim rows (curves) continuing past Tf
                
    dreamy_t30_20161010{condition} = dreamData;                    % store curves that meet criteria
    clear tabulatedData trimmedData dreamData;                  % clear data before starting next condition
end

save('dreamy_t30_20161010.mat','dreamy_t30_20161010');
%%

% condition two. 15 minute fluctuations (data from 2016-10-20)


% initialize
homeFolder = cd('/Users/jen/Documents/Stocker Lab/Data/2016-10-20');

steadyState = [1 3 7.5; 2 5 7; 3 3 5.2; 4 2.5 6.7];
% [fluc Ti Tf; low Ti Tf; ave Ti Tf; high Ti Tf];
% where,
%       Ti = start of steady-state behavior (in hours)
%       Tf = end of steady-state behavior (in hours)

dataSets = {'dm2016-10-20-fluc.mat', 'dF_2016-10-20.mat';
            'dm2016-10-20-low.mat', 'dL_2016-10-20.mat';
            'dm2016-10-20-ave.mat', 'dA_2016-10-20.mat';
            'dm2016-10-20-high.mat', 'dH_2016-10-20.mat'};


for condition = 1:4         % [fluc low ave high];
    
    Ti = steadyState(condition,2);
    Tf = steadyState(condition,3);
    
    load(dataSets{condition,1});
    load(dataSets{condition,2});
    
    
   % criteria for measured curves:
    
   %       1. ccStage (col 9, dataMatrix) = integer
   %          if ccStage = NaN, then curve is not complete
    
   %       2. timestamps in curve are within Ti and Tf
    
    
    
   % program:
    
   % 1. isolate individual tracks (col 1), one by one
    skippedTrackCounter = 0;                                    % count tracks without curves
    curveCounter = 0;                                           % count curves analyzed
    
    totalTracks = max(dataMatrix(:,1));
    for track = 1:totalTracks
        
        targetTrack = find( dataMatrix(:,1)==track );           % get rows of target track
        isoTrack = dataMatrix(targetTrack,:);                   % isolate data for target track
        
   % 2. determine whether track contains any full curves
        
        max_ccStage = max( isoTrack(:,9) );
        noCurves = isnan( max_ccStage );                        % 1 = true, no curves
        if noCurves == 1                                        % if no full curves in track...
            skippedTrackCounter = skippedTrackCounter + 1;      % count tracks that do not meet criteria
            continue                                            % jump to next track (no curves to analyze)
            
        else                                                    % if there are curves... (yay!!)
            fullCurves = max( isoTrack(:,6) );                  % get number of full curves in track
            
    % 3. isolate curves in track, one by one
            
            for curve = 1:fullCurves                            % for each full curve in track
                curveCounter = curveCounter + 1;                % tally curve
                targetCurve = find( isoTrack(:,6)==curve );     % get rows of target curve
                isoCurve = isoTrack(targetCurve,:);             % isolate data for target curve
                            
    % 4. birth and division size, calculate added size          % added size = delta
                
                birthSize = min( isoCurve(:,3) );
                divSize = max( isoCurve(:,3) );
                Delta = divSize - birthSize;
                
    % 5. timestamp for start and end of curve
    
                Start = min( isoCurve(:,2) );
                End = max( isoCurve(:,2) );
                
    % 6. growth rate calculations
    
                instantMus = isoCurve(:,4);                     % isolate instantaneous Mus from sliding windows
                instantMus = instantMus( instantMus<1 );        % remove high outliers
                instantMus = instantMus( instantMus>0 );        % remove low outliers
                aveMu = mean( instantMus );                     % average instantaneous mus across entire curve
                
                LN2 = log(2);                                   % LN2 = ln(2), natural log
                curveDuration = End - Start;
                calcMu = log(divSize/birthSize) / (LN2*curveDuration);
    
    % 7. tabulate data!
                
                tabulatedData(curveCounter,:) = [track birthSize divSize Delta Start End aveMu calcMu];
                                                        
            end                                                 % end of loop through curves per track, section 3
        end                                                     % end of if statement checking presence of full curves, section 2
    end                                                         % end of loop through tracks per condition, section 1
    
    
    % 8. determine whether curve falls within Ti and Tf
                
    pastTi = find( tabulatedData(:,5) >= Ti );                  % identify rows (curves) starting at or after Ti 
    trimmedData = tabulatedData(pastTi,:);                      % trim rows (curves) starting before Ti
    
    underTf = find( trimmedData(:,6) <= Tf );                   % identify rows (curves) continuing past Tf
    dreamData = trimmedData(underTf,:);                         % trim rows (curves) continuing past Tf
                
    dreamy_t900_20161020{condition} = dreamData;                    % store curves that meet criteria
    clear tabulatedData trimmedData dreamData;                  % clear data before starting next condition
end

save('dreamy_t900_20161020.mat','dreamy_t900_20161020');

%%

% plot dreamData: delta vs birth size

homeFolder = cd('/Users/jen/Documents/Stocker Lab/Data/2016-10-10');
load('dreamy_t30_20161010.mat');

homeFolder = cd('/Users/jen/Documents/Stocker Lab/Data/2016-10-20');
load('dreamy_t900_20161020.mat');



for condition = 1:4
    
    Sb1 = dreamy_t30_20161010{1,condition}(:,2);
    delta1 = dreamy_t30_20161010{1,condition}(:,4);
    
    Sb2 = dreamy_t900_20161020{1,condition}(:,2);
    delta2 = dreamy_t900_20161020{1,condition}(:,4);
    
    subplot(1,4,condition);
    plot(Sb1,delta1,'bo')
    hold on
    plot(Sb2,delta2,'ro')
    axis([1,5,0,5])
end