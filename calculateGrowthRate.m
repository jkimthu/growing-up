% calculateGrowthRate


% goal: this function centralizes the calculation of 4 plausible growth
%       rates. the only growth rate not calculated here is mu.


% strategy: 
%
%       0. feed function volume and timestamp data
%       0. function returns arrays of growth rate data of identical length
%          to volume and timestamp input 
%       0. calculate dt
%       1. calculate dVdt
%            -  change in volume over time between two neighboring timepoints (i.e. dt ~ 1 min and 57 sec)
%       2. calculate dVdt_norm
%            -  normalize dVdt calculated in step 1 by initial volume
%       3. calculate dVdt_log2
%            -  take log(volume) before calculating change between timesteps
%       4. caluclate dVdt_lognorm
%            -  take log(volume) before calcuting change and normalizing by initial volume
%       5. replace all growth rates at division events with NaN
%       6. output array with all growth rates, of columns in following
%          order:
%                   1. dVdt_raw
%                   2. dVdt_norm
%                   3. dVdt_log2
%                   4. dVdt_lognorm



% last updated: jen, 2018 September 20

% commit: apply change of base rule to make base of exponential 2


% Go go let's go!

%%
function [growthRates] = calculateGrowthRate(volumes,timestamps,isDrop,curveFinder)

% input data:
%        volumes     =  calculated va_vals (cubic um)
%        timestamps  =  timestamp in seconds
%        isDrop      =  1 marks a birth event, 0 is normal growth
%        curveFinder =  ID number of curve in condition, repeats between
%                       conditions but not within
        

% 0. calculate dt
curveIDs = unique(curveFinder);
firstFullCurve = curveIDs(2);
if length(firstFullCurve) > 1
    firstFullCurve_timestamps = timestamps(curveFinder == firstFullCurve);
else
    firstFullCurve = curveIDs(3);
    firstFullCurve_timestamps = timestamps(curveFinder == firstFullCurve);
end
dt = mean(diff(firstFullCurve_timestamps)); % timestep in seconds


% 1. calculate dVdt
dV_noNan = diff(volumes);
dV = [NaN; dV_noNan];
dVdt_raw = dV/dt * 3600;                % final units = cubic um/hr



% 2. calculate dVdt_norm (normalized by initial volume)
dV_norm = [NaN; dV_noNan./volumes(1:end-1)];
dVdt_norm = dV_norm/dt * 3600;          % final units = 1/hr   
        

                
% 3. calculate dVdt_log = d(log V)/dt
dV_log_noNan = diff(log(volumes));
dV_log = [NaN; dV_log_noNan];
dVdt_log = dV_log/dt * 3600;           % final units = cubic um/hr
dVdt_log2 = dVdt_log/log(2);


% 4. calculate dVdt_lognorm = d(log V)/dt normalized by initial volume
dV_lognorm = [NaN; dV_log_noNan./volumes(1:end-1)];
dVdt_lognorm = dV_lognorm/dt * 3600;         % final units = 1/hr



% 5. replace all growth rates at division events with NaN
growthRates = [dVdt_raw, dVdt_norm, dVdt_log2, dVdt_lognorm];
growthRates(isDrop == 1,:) = NaN;

        
% 6. output array with all growth rates, of columns in following order:
%     (i) dVdt_raw; (ii) dVdt_norm; (iii) dVdt_log2; (iv) dVdt_lognorm
end







