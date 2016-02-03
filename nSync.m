%%  nSYNC


%  Goal: Searching for synchrony in growth data.
%
%  Last edit: Jen Nguyen, February 3rd 2016


% Let's first take one experiment, say 60 min fluctuations, and see if
% segregating sub-populations by growth phase leads to clear behavioral
% differences, or at least less variation within groups.


% Let's define growth phase as a specific fraction of the growth curve.

%       1. Determine duration of each individual growth curve
%               a. How does the mean and stdev of this vary between expts?
%       2. Fraction these time-lengths
%       3. For a set number of fractions, starting with three, bin all data
%          belonging to a specific fraction.
%       4. Plot growth rate vs time


% Envisioned data matrix:

%       t(row)     Lngth     drop?      curve#    fraktion
%         1          x        nan         1           1
%         2          x         0          1           2
%         3          x         0          1           3
%         4          x         1          2           1
%         5          x         0          2           2
%         6          x         0          2           3
%         7          x         1          3           1
%         8          x         0          3           2
%         9          x         0          3           3
%         10         x         1          4           1


%       1. t(row) is row number
%       2. Use drops in length to determine end of each growth curve
%       3. If drop, then start counting upcoming rows as part of new curve
%       4. max(curve#) is more likely than not less than a full growth curve
%                a. throw out? how does this deplete our data set?
%                b. clever way to use final curve?
%       5. Pool timepoints from each fraction bin
%       6. Use timepoints to pool appropriate growth rates (Mews)


% Assessment goal:

%       1. Does separation between phase-sorted subpopulations occur?
%       2. Vary number of fractions. Which leads to the best separation?
%       3. If there is separation, what explains it?


% OK! Lez go!

%%
%   Initialize.

load('2015-08-10-Mu-length.mat');
D7 = D6;
M7 = M6;


%%

