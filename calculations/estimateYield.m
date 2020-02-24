% estimateYield


% Goal

% Estimate (conservatively) the yield difference between fluctuating and
% steady average environment.


% Assumptions

% 1. volume is equal to biomass
% 2. all cells start at the same volume


% last update: jen, 2019 May 16
% commit: first commit, code for discussion on biogeochemical implications


% ok let's go!

%%


% m_o = initial mass of one cell
m_o = [1,2,3,4]; % cubic um

% mu = growth rate, G
mu = [1.93; 1.53; 1.15; 2.31]; % 1/hr: 30 sec, 5 min, 15 min, G_ave

% t = time elapsed (one day)
t = 24;

% M = mass after a day 
for ii = 1:length(mu)
    
    M(m_o,ii) = m_o * 2^(mu(ii)*t);
    
end



