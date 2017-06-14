%% distributeDoublingTime

% Goal: this script plots the PDF of division times from a given condition


% Strategy:
%           0. initialize data matrix
%           1. isolate condition of interest
%                  2. isolate time period of interest
%                  3. collect drop data and track ID
%                  4. count number of drops per track
%                         5. if at least two, there's a whole curve:
%                                 i. align drop and time data
%                                ii. measure time between birth and division
%                               iii. save in div time array
%                            else, move onto next track
%                  6. build PDF from completed div time array
%           7. repeat for any other conditions of interest



% last edit: jen, 2017 Jun 14

% OK LEZ GO!

%%
% 0. initialize data matrix
clear
load('dm-2017-05-26.mat');
conditions = [1,2,3,4,5,6];
c = 4;



% 1. isolate condition of interest
trimmedData = dataMatrix(dataMatrix(:,28) == c,:);



% 2. isolate time period of interest
minTime = 3; % based on where growth rate seems to stabilize
maxTime = 10;

% remove data from timepoints earlier than minTime
trimmedData2 = trimmedData(trimmedData(:,2) >= minTime,:);

% remove data from timepoints later than maxTime
trimmedData_final = trimmedData2(trimmedData2(:,2) <= maxTime,:);



% 3. collect drop data and track ID
drops = trimmedData_final(:,5);
trackIDs = trimmedData_final(:,1);
time = trimmedData_final(:,2);




% 4. count number of drops per track

% associate track ID to each drop
dropIDs = trackIDs(drops == 1); 

% count drops per ID
unique_dropIDs = unique(dropIDs);
drop_counts_per_ID = histc(dropIDs,unique_dropIDs);

% IDs with at least 2 drops
atLeast2 = find(drop_counts_per_ID == 2);




% 5. for each track with at least two drops
divisionTimes = [];
for tr = 1:length(atLeast2)
    
    % isolate drop data
    tr_drops = drops(trackIDs == unique_dropIDs( atLeast2(tr) ));
    
    % get timestamp at all drops (when drop == 1)
    tr_time = time(trackIDs == unique_dropIDs( atLeast2(tr) ));
    drop_times = tr_time(tr_drops == 1);
    
    % calculate time duration between drops
    tr_divTimes = diff(drop_times);
    
    % concatenate array of all div times per condition
    divisionTimes = [divisionTimes; tr_divTimes]; %in hours
end



% 6. build PDF from completed div time array
inMinutes = divisionTimes*60;

figure()
histogram(inMinutes,'Normalization','pdf','BinWidth',10);


%%
%           7. repeat for any other conditions of interest
