%% parameterCorrelations

%  goal: plot all cell parameters against each other.
%        determine whether there are any interesting (and hypothesis inspiring!)
%        correlations between them.
 

%  last update: jen, 2018 March 27
%  commit: begin plotting cell parameter correlations


%  cell parameters included in correlation analysis fall into six categories:
%
%     A. cell size parameters:
%
%               1. length
%               2. width
%               3. volume
%               4. surface area
%               5. SA/V ratio
%
%
%     B. growth rate parameters:
%               
%               6. interdivision time
%               7. mu
%               8. biovolume production rate
%
%
%     C. size at birth parameters:
%
%               9. length at birth
%              10. width at birth
%              11. volume at birth
%              12. SA at birth
%              13. SA/V ratio at birth
%
%
%     D. change in size / added size, per cell cycle:
%
%              14. delta length
%              15. delta width
%              16. delta volume
%              17. delta surface area
%              18. delta SA/V
%
%
%     E. environment
%
%              19. timescale
%              20. nutrient concentration
%              21. nutrient phase
%
%
%     F. nutrient experience
%
%              22. nScore: binary
%              23. nScore: gaussian
%              24. nScore: gradient



%  strategy:
%  
%       0. initialize complete meta data
%       0. initialize experiment to analyze
%       1. compile parameter data
%       2. perform linear regression, output slope
%       3. plot and save
%



% OK let's go!

%%

clc
clear

% 0. initialize complete meta data
cd('/Users/jen/Documents/StockerLab/Data_analysis/')
load('storedMetaData.mat')

dataIndex = find(~cellfun(@isempty,storedMetaData));
experimentCount = length(dataIndex);

% 0. initialize experiment to analyze
% exclude outliers from analysis (2017-10-31 and monod experiments)
%if strcmp(date, '2017-10-31') == 1 || strcmp (timescale, 'monod') == 1
%    disp(strcat(date,': excluded from analysis'))
%    continue
%end
%disp(strcat(date, ': analyze!'))
e = 14;

%

% 1. collect experiment meta data
index = dataIndex(e);
date = storedMetaData{index}.date;
timescale = storedMetaData{index}.timescale;
bubbletime = storedMetaData{index}.bubbletime;


% 2. load measured data
experimentFolder = strcat('/Users/jen/Documents/StockerLab/Data/LB/',date);
cd(experimentFolder)
filename = strcat('lb-fluc-',date,'-window5-width1p4-1p7-jiggle-0p5.mat');
load(filename,'D5','M','M_va','T');

    
% 3. compiled experiment data matrix
xy_start = min(min(storedMetaData{index}.xys));
xy_end = max(max(storedMetaData{index}.xys));
exptData = buildDM(D5, M, M_va, T, xy_start, xy_end,e);
clear D5 M M_va T xy_start xy_end e

%% Part 1. group A vs group A

for condition = 1:length(bubbletime)
    
    % 4. designate plotting color
    if condition == 1
        color = rgb('DodgerBlue');
        
    elseif condition == 2
        color = rgb('Indigo');
        
    elseif condition == 3
        color = rgb('Goldenrod');
        
    elseif condition == 4
        color = rgb('FireBrick');
        
    end
    
    % 4. isolate condition specific data
    cData = exptData(exptData(:,23) == condition,:);
    
    
    % 5. trim data to stabilized non-bubble regions
    timestamps = cData(:,2)/3600;        % convert from sec to hr
    minTime = 3;                            % hr
    data_trim1 = cData(timestamps >= minTime,:);
    time_trim1 = timestamps(timestamps >= minTime);
    
    if bubbletime(condition) == 0
        data_trim2 = data_trim1;
        time_trim2 = time_trim1;
    else
        maxTime = bubbletime(condition);
        data_trim2 = data_trim1(time_trim1 <= maxTime,:);
        time_trim2 = time_trim1(time_trim1 <= maxTime);
    end
    clear time_trim1 time_trim2 data_trim1 minTime maxTime
    
    
    % 6. isolate length, width, volume, and SA data
    L = data_trim2(:,3);        % col 3 = length
    W = data_trim2(:,11);       % col 11 = width
    V = data_trim2(:,12);       % col 12 = volume (Va)
    SA = data_trim2(:,13);      % col 13 = surface area
    
    
    % 7. generate matrix of paramter group A: cell size
    SA2V = SA./V;
    groupA_size = [L W V SA SA2V];
    groupA_parameters = {'L','W','V','SA','SA/V'};
    
    
    % 8. iterate through unique pair-wise combinations to plot each parameter
    %    against all others, reporting slope of linear regression
    [~,n] = size(groupA_size);
    uniqueCombos = n * (n-1) / 2;       % total pair-wise combos in this set
    
    % below, we will plot each unique pair indexed as follows:
    %
    %        L    W    V   SA   SA2V
    %    L   -    1    2    3    4
    %    W   -    -    5    6    7
    %    V   -    -    -    8    9
    %   SA   -    -    -    -   10   , where 10 = total unique combos
    
    
    % each value of yParam is the column num of the first parameter to plot as y-axis  
    % with each iteration, we will adjust this value for each x-axis parameter 
    yParam = 2:n; 
    for pp = 1:uniqueCombos             
        
        if pp <= n-1
            
            row = 1;
            x = groupA_size(:,row);
            y = groupA_size(:,yParam(row));
            %disp(strcat('row 1 plots: ',groupA_parameters{row},' vs. ',groupA_parameters{yParam(row)}))
            
            figure(pp)
            subplot(2,2,condition)
            plot(x,y,'o','Color',color)
            xlabel(groupA_parameters{row})
            ylabel(groupA_parameters{yParam(row)})
            legend(num2str(condition));
            hold on
            
            yParam(1) = yParam(row) + 1;
            
        elseif pp <= (n-1)+(n-2)
            
            row = 2;
            x = groupA_size(:,row);
            y = groupA_size(:,yParam(row));
            %disp(strcat('row 2 plots: ',groupA_parameters{row},' vs. ',groupA_parameters{yParam(row)}))
            
            figure(pp)
            subplot(2,2,condition)
            plot(x,y,'o','Color',color)
            xlabel(groupA_parameters{row})
            ylabel(groupA_parameters{yParam(row)})
            legend(num2str(condition));
            hold on
            
            yParam(row) = yParam(row) + 1;
            
        elseif pp <= (n-1)+(n-2)+(n-3)
            
            row = 3;
            x = groupA_size(:,row);
            y = groupA_size(:,yParam(row));
            %disp(strcat('row 3 plots: ',groupA_parameters{row},' vs. ',groupA_parameters{yParam(row)}))
           
            figure(pp)
            subplot(2,2,condition)
            plot(x,y,'o','Color',color)
            xlabel(groupA_parameters{row})
            ylabel(groupA_parameters{yParam(row)})
            legend(num2str(condition));
            hold on
           
            yParam(row) = yParam(row) + 1;
            
        elseif pp <= (n-1)+(n-2)+(n-3)+(n-4)

            row=4;
            x = groupA_size(:,row);
            y = groupA_size(:,yParam(row));
            %disp(strcat('row 4 plots: ',groupA_parameters{row},' vs. ',groupA_parameters{yParam(row)}))
            
            figure(pp)
            subplot(2,2,condition)
            plot(x,y,'o','Color',color)
            xlabel(groupA_parameters{row})
            ylabel(groupA_parameters{yParam(row)})
            legend(num2str(condition));
            hold on
            
            yParam(row) = yParam(row) + 1;
            
        end
        
    end
    
end

% 9. save plots
cd('/Users/jen/Documents/StockerLab/Data_analysis/parameter_correlations')
for pp = 1:uniqueCombos
    
    currentFig = figure(pp);
    title(strcat('Group A parameter pair: ',num2str(pp),' of ',num2str(uniqueCombos),', experiment: ',date,';',num2str(timescale),'sec period'))
    saveas(currentFig,strcat('parameterCorrelations-groupA-fig',num2str(pp),'-outOf-',num2str(uniqueCombos)),'epsc')
    close(currentFig)
    
end

%% Part 2. group B vs group B

