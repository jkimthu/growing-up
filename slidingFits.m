%% Determination of growth rate by fitting an exponential to length trajectories
%


%  After quality control step is complete, D6 is a row of cells -- each
%  representing a different experimental movie / xy-position.
%           ex.  D6{n} = movie n from dataset D6
%
%  Each cell containss a column of structures, each the data for one track
%  from that movie.
%           ex.  D6{n}(m} = track m from movie n
%
%  Each structure contains a variety of metrics measured for that track,
%  including: X, Y, Area, Frame, and MajAx
%           ex.  D6{n}(m).MajAx = column of cell length values (double) for
%                                 each frame (row #) of track m
%


%  GOAL: measure the instantaneous growth rate for each track
%


%  APPROACH: fit sections of each track to the following exponential
%
%                   L(t) = l * 2^(mu*t)
%
%            where, L = final cell length
%                   l = initial cell length
%                   mu = growth rate over time t
%                   t = time window
%
%       Note: frame is NOT equal to t, but multiple of it. Instead, t
%       depends on how many points are used to calculate fit (measure mu)
%
%       Sections in this script are defined by a sliding window, which contains an odd
%       number of points. The calculated mu is then assigned to the
%       centermost timepoint.
%
%

%  OK! HERE WE GO!

%%
%last update: June 14th, 2016

% Each condition saved under "stable" or "fluc"
% Datasets concatenated using:

load('2016-06-14-fluc-trimmed.mat');
D_all = D6;
T_all = T;
clear D D2 D3 D4 D5 D6 T;

load('2016-06-14-const-trimmed.mat');
D_all = [D_all D6];
T_all = [T_all T];
clear D D2 D3 D4 D5 D6 T;

D6 = D_all;
T = T_all;

save('2016-06-14-trimmed.mat', 'D6', 'T');
clear D_all T_all;
%%
load('2016-06-14-trimmed.mat');


%%

clear m n Ltrack Ttotal dT t_hr Ltime Ldiff L_Fit w Fit pFit Wdiff;
clear total_windows init_window Ttrack Ttrack_row Test Fenster Fenster_track Screen;
clear Fenster_trim hr_trim log_Fit SlidingData;


% 1. Initialize:
%
%       i.      Load length trajectory for track m
%       ii.     Determine length of time window
%       iii.    Establish whether window contains a division event
%       iv.     If it does, then remove dip from fit and double lengths of subsequent points
%


for n = 1:length(D7)
    
    for m = 1:length(D7{n})
        
        % Original length data (microns)
        lengthTrack = D7{n}(m).MajAx;                                           % loads current length trajectory
        lengthDiffs = diff(lengthTrack);                                              % used to find sharp drops
        
        % Time data (hours)
        
        %Ttotal = length(Ltrack);                                           % finds number of frames in current trajectory
        %dT = mean(mean(diff(T{n})));                                       % mean time between frames (seconds)
        %Ttrack_row = linspace(1,Ttotal,Ttotal);                            % creates row of numbers from 1 to Ttotal, increment = Ttotal/Ttotal
        timeTrack = T{n}/3600;
        %t_hr = (Ttrack_row.'*dT)/(60*60);
     
        % Set-up windows
        pointsInWindow = 5;                                                % sets number of frames in one window
        firstWindow = linspace(1,pointsInWindow,pointsInWindow);           % defines frame numbers for first window
        numWindows = length(lengthDiffs) - (pointsInWindow-1);             % total windows in track
        
        clear  Ttrack_row Ttotal dT
        
        
        
        % Fitting directions for special cases, where a window contains a break in growth (division event)
        for w = 1:numWindows
            
            % Determine frames of analysis
            currentWindow = firstWindow + (w-1);                           % defines vector of frame numbers
            Wtrack(w,:) = currentWindow;
            Wdiff = lengthDiffs(currentWindow(1:4));                             % incremental length differences in current window
            
            % Working around sharp dips in length
            dipFinder = find(Wdiff < -.75);  % returns 1 if all diffs are above threshold, 0 if a dip was found
            
            % When a window has a dip, remove dip from analysis
            % Method used depends on where dip is located:
            if isempty(dipFinder) == 0
                
                % If dip is found between window points 4 and 5,
                % trim last data point to remove dip, only use first 4 for fit
                if dipFinder == 4
                    trimmedWindow = currentWindow(1:4);
                    Wtrack(w,:) = [trimmedWindow 0];
                    %disp(['Window ', num2str(w), '... Red!'])
                    
                    % covert length to log scale for linear fit
                    logLength = log(lengthTrack(trimmedWindow));
                    trimmedTime = timeTrack(trimmedWindow);
                    Fit = polyfit(trimmedTime,logLength,1);
                    pFit(w,:) = Fit;
                    log_Fit = polyval(Fit,trimmedTime);
                    
                    %figure()
                    %plot(hr_trim,log_Fit,hr_trim,log_L,'o');
                    %grid on;
                    %legend('Fit','Data')
                    %title('log Data Plot')
                    
                    % return to linear scale and generate exponential fit
                    Slope = Fit(1);
                    Intercept = Fit(2);
                    hr = timeTrack(currentWindow);
                    L_Fit(w,:) = exp(Intercept)*exp(hr*Slope);
                    
                    clear Fit Slope Intercept log_L hr Fenster w;
                end
                
                if dipFinder == 3
                    %disp(['Window ', num2str(w), '... Dark blue!'])
                    Lengths = lengthTrack(currentWindow);
                    Dbl = 2*Lengths(4:5);
                    Ltrack_d4d5 = [Lengths(1:3); Dbl];
                    
                    % Working in log scale
                    logLength = log(Ltrack_d4d5);
                    hr = timeTrack(currentWindow);
                    Fit = polyfit(hr,logLength,1);
                    pFit(w,:) = Fit;
                    
                    % Back to linear scale
                    Slope = Fit(1);
                    Intercept = Fit(2);
                    L_Fit(w,:) = exp(Intercept)*exp(hr*Slope);
                    
                    %figure()
                    %plot(hr,L_Fit(w,:),hr,Ltrack_d4d5,'o');
                    
                    clear Fit Slope Intercept log_L hr Ltrack_d4d5 Wdiff Fenster w Dbl;
                end
                
                
                if dipFinder == 2
                    %disp(['Window ', num2str(w), '... Dark bluuuuuueee!'])
                    Lengths = lengthTrack(currentWindow);
                    dbl = 2*Lengths(3:5);
                    Ltrack_d345 = [Lengths(1:2); dbl];
                    
                    logLength = log(Ltrack_d345);
                    hr = timeTrack(currentWindow);
                    Fit = polyfit(hr,logLength,1);
                    pFit(w,:) = Fit;
                    
                    Slope = Fit(1);
                    Intercept = Fit(2);
                    L_Fit(w,:) = exp(Intercept)*exp(hr*Slope);
                    
                    %figure()
                    %plot(hr,L_Fit(w,:),hr,Ltrack_d345,'o');
                    
                    clear Fit Slope Intercept log_L hr Ltrack_d345 Wdiff Lengths Fenster w dbl;
                    
                end
                
                if dipFinder == 1
                    disp(['Series ', num2str(n), ', track ', num2str(m), ', window ', num2str(w), '... a division!'])
                    pFit(w,:) = [0 0];
                    L_Fit(w,:) = [0 0 0 0 0];
                end
                
                
%           when there are no length breaks in window
            else
                %disp(['Window ', num2str(w), '... smooth sailing!'])
                
                logLength = log(lengthTrack(currentWindow));                              
                hr = timeTrack(currentWindow);
                Fit = polyfit(hr,logLength,1);                                
                pFit(w,:) = Fit;
                
                Slope = Fit(1);
                Intercept = Fit(2);
                L_Fit(w,:) = exp(Intercept)*exp(hr*Slope);
                
                clear Fit Slope Intercept Screen Fenster Wdiff;
                clear log_L hr Window w;
                
            end
            
            clear Fenster Fenster_trim Wdiff Screen log_L hr hr_trim Slope Intercept log_Fit;
            
        end

        % saving data
        SlidingData = struct('Parameters',pFit,'Fits',L_Fit,'Windows',Wtrack);
        M6{n}(m) = SlidingData;
        
        clear SlidingData total_windows init_window Ltrack Ldiff total_windows;
        clear pFit L_Fit Fenster_track;
    end
    
end

%%

save('2016-06-14-Mus-length.mat', 'D6', 'M6', 'T') %'D'
clear Fenster_track L_Fit Ltime pFit t_hr;