%% calculate lag in signal

% goal: determine the lag between the time at which signal is generated at junction
%       and the time at which the transitions are experienced by cells
%
%       in other words, solve for TIME LAG (sec) as detailed below.
%


% method: flow rate (Q) =  effective velocity  *  effective cross-sectional area         
%
%            A_effective  =  a constant, calculated from fluorescein tests
%                            between junction and cell imaging positions (cm squared)
%
%                      Q  =  measured flow rate through MPG (ul/min) 
%
%            V_effective  =  distance traveled (cm) / time lag 
%


% Strategy:

% SECTION ONE. function to calculate and return lag time per xy position of a given experiment
%
%     0. initialize meta data and specify value of effective area
%     1. specify experiment of interest
%     2. load flow rate and x coordinates from specified experiment
%     3. for all 10 xy positions
%             3. calculate distance traveled from x coordinates
%             4. solve for time lag
%     5. report calculated time lags and distance traveled per experiment



% SECTION TWO. overivew of summary statistics across experiments
%
%     Performs function of section for all experiments listed in array.
%     Calculate and reports mean lag time per experiment and standard deviation.
%     Also reports time difference between position #1 and #10 per experiment.
%     Output is used in Supplementary Table 1 in growth reductions paper.


% last update: jen, 2019 Feb 8

% commit: edit comments for SECTION TWO


% OK let's go!!

%% ONE. function to calculate and return lag time per xy position of a given experiment

function [timeLags,distances] = calculateLag(index)


% 0. initialize data
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')


% 0. specify value of effective area
A_effective = 0.000264; % cm^2


% 1. specify experiment of interest, for which to calculate time lag
% 


% 2. load flow rate and x coordinates from specified experiment
if isfield(storedMetaData{index},'x_cell') == 0
    
    timeLags(1:10,1) = 1.7;
    distances(1:10,1) = NaN;
    disp('missing cell or junc position data - estimating time lag as 1.7 sec!')
    
elseif isfield(storedMetaData{index},'flow_rate') == 0
    
    timeLags(1:10,1) = 1.7;
    distances(1:10,1) = NaN;
    disp('missing flow rate data - estimating time lag as 1.7 sec!')
    
else
    
    Q = storedMetaData{index}.flow_rate;
    x_cells = storedMetaData{index}.x_cell;
    x_junc = storedMetaData{index}.x_junc;
    
    
    for xy = 1:10
        
        % 3. calculate distance traveled from x coordinates (cm)
        distance_traveled = (x_junc - x_cells(xy))/10000;   % um * cm/10000um
        distances(xy,1) = distance_traveled;
        
        % 4. solve for time lag = distance traveled * A_eff / Q
        timeLag = distance_traveled * A_effective / (Q * 0.001 / 60); % convert Q from ul/min to cubic cm/sec
        timeLags(xy,1) = timeLag;
        
    end
    
    
end

end

%% TWO. overview of lag time summary statistics across experiments

% * commented so as not to disturb function performance, when called

%  
% clear
% clc
% 
% % 0. initialize data
% %cd('/Users/jen/Documents/StockerLab/Data_analysis/')
% load('storedMetaData.mat')
% dataIndex = find(~cellfun(@isempty,storedMetaData));
% 
% exptArray = [2:4,5:7,9:12,13:15];
% experimentCount = length(exptArray);
% 
% 
% % 0. specify value of effective area
% A_effective = 0.000264; % cm^2
% 
% 
% for e = 1:experimentCount
%     
%     
%     % 1. specify experiment of interest, for which to calculate time lag
%     index = exptArray(e);
%     
%     
%     % 2. load flow rate and x coordinates from specified experiment
%     date = storedMetaData{index}.date;
%     Q = storedMetaData{index}.flow_rate;
%     x_cells = storedMetaData{index}.x_cell;
%     x_junc = storedMetaData{index}.x_junc;
%     
%     
%     for xy = 1:10
%         
%         % 3. calculate distance traveled from x coordinates (cm)
%         distance_traveled = (x_junc - x_cells(xy))/10000;   % um * cm/10000um
%         distances(xy,1) = distance_traveled;
%         
%         % 4. solve for time lag = distance traveled * A_eff / Q
%         timeLag = distance_traveled * A_effective / (Q * 0.001 / 60); % convert Q from ul/min to cubic cm/sec
%         timeLags(xy,1) = timeLag;
%         
%     end
%     
%     % 5. report solution
%     betweenXYs(e,1) = sum(diff(timeLags));
%     meanLag(e,1) = mean(timeLags);
%     stdLag(e,1) = std(timeLags);
%     
% end



