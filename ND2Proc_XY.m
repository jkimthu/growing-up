%% .nd2 Proc for individually saved xy series

%  Goal: from ND2 files, track particles from images. Geneate


%  Changes from original script from Vicente:
%
%       1. Original ND2 is imported here as individual movies. 
%          Something about ND2's must have changed such that the NSeries
%          line would ready the entire files as a single series.
%          Solution: export individual series and run tracking on each
%          separately.
%
%       2. Commented out Track Linker step. (2017 July 7)
%          This was originally meant to create tracks of swimming cells.
%          In these experiments, linked tracks often meld different cell
%          tracks together (say, when collisions occur) and result in
%          tracking errors.


%  Section contents:
%
%    1. Create directory of movie 
%    2. Initialize tracking paramenters
%    3. Manually adjust thresholding
%           - this step permits testing all parameters on a single movie
%             before running the entire script to track particles in all movies
%    3. id, trim, and track particles, looping through all series
%           i. track all particles using adjusted parameters
%          ii. view all particles identified
%         iii. trim particles by area
%          iv. trim particles by width
%           v. track remaining particles based on coordinate distance
%    4. Store tracked data into single workspace, D



%  Last modified (jen): 2017 Oct 30
%  Original script by the wondrous Vicente Fernandez

%  OK lez go!

%% 1. create directory of movies

xyDirectory = dir('lb-fluc-2017-10-24_xy*.nd2');
names = {xyDirectory.name};


%% 2. initialize tracking parameters
   
%  set pixels to um conversion based on camera used
%  scope5 Andor COSMOS = 6.5um pixels / 60x magnification
ConversionFactor = 6.5/60;

%  use first image of first series
ii=1;
reader = bfGetReader(names{ii});

%  refine the filter parameters
%FilterTest_ND2(reader,ImageNumber,{[10,.8,40],'gaussian'})                 % Parameters for spatial filtering:
                                                                           
                                                                           %    first number   -  Highpass filter radius in pixels > lowpass #, Inf to skip
                                                                           %    second number  -  Lowpass filter radius in pixels, zero to skip
                                                                           %    third number   -  Filter size. Should be at least twice the max radius, more if Gaussian.  Large numbers increase processing time
                                                                           %    Filter type    -  Either 'tophat' or 'gaussian'.  The latter gives slightly less ringing
%  if happy, use these values for FilterParameters
FilterParameters = {[10,.8,40],'gaussian'};


%% 3. Manually adjust thresholding

Threshold =  [];%[-147.904, -1];         % [] for GUI, make array with second value +/- 1 to indicate direction of threshold, default positive.
                                     % The second number gives the separation between images
                                     
Background = [];                     % Background image to substract from data.  Run empty on a subset and rerun using the mean image in the Im structure if desired
PlotFlag = 0;                        % Set this flag to 1 in order to plot temporary results
ImType = {'Single'};                 % This sets the type of image being used.  Options are:
                                            %   'Single' - Processes individual images corresponding to the numbers in FileNumbers
                                            %   'Diff+'  - The image with a number higher than the target image is subtracted
                                            %   'Diff-'  - The image with a number less than the target image is subtracted
                                            %   'Rolling'- The average of the adjacent images is subtracted from the target image

%  find particles in each image
[P,Im] = Particle_Centroid_ND2(reader,FilterParameters,Threshold,[],Background,ImType,ConversionFactor,PlotFlag);  %Actual Processing
%function [ParticleOut,Img]=Particle_Centroid_ND2(reader,FilterParam,Threshold,FIndex,Backgrnd,DiffInfo,ConvFactor,PlotFlag)

%% 4. track particles in each series, looping through all

NSeries = length(names);
%NSeries=reader.getSeriesCount();


for ii = 1:NSeries

    %% i. track all particles using adjusted parameters
    
    %reader.setSeries(ii);
    reader = bfGetReader(names{ii});
    NImg=reader.getImageCount(); % Number of images to include in analysis, starting from 1
    
    Threshold =  [-215.172, -1]; %threshold for 2017-10-24      
    Background = [];                        
    PlotFlag = 0;                           
    ImType = {'Single'};                

    [P,Im] = Particle_Centroid_ND2(reader,FilterParameters,Threshold,[],Background,ImType,ConversionFactor,PlotFlag);  %Actual Processing

 
    %% ii. view all particles identified
    
    AnalysisNumber = 40;  %Note that if Difference or Rolling image approaches are used, 
    
    %make sure that the file associated with AnalysisNumber also exists (eg AnalysisNumber + 2 for ['Diff+',2])
    figure(6); clf; ParticlePropOverlay_ND2(reader,P,AnalysisNumber,ImType,'MinAx',FilterParameters,[])

    %% iii. trim particles by area
    
    TrimField = 'A';    % choose relevant characteristic to restrict, run several times to apply for several fields
    LowerBound = 0.8;   % lower bound for restricted field, or -Inf
    UpperBound = 26;     % upper bound for LB
    %UpperBound = 8;     % upper bound for glucose only 
    
    % to actually trim the set:
    P_Trim1 = ParticleTrim(P,TrimField,LowerBound,UpperBound);
    figure(7); clf; ParticlePropOverlay_ND2(reader,P_Trim1,AnalysisNumber,ImType,'A',FilterParameters,[])

    
    %% iv. trim particles by width
    
    TrimField = 'MinAx';  % choose relevant characteristic to restrict, run several times to apply for several fields
    LowerBound = 1.0;     % lower bound for restricted field, or -Inf
    if ii < 31
        UpperBound = 1.4;     % upperbound in conditions 1, 2 ,3
    else
        UpperBound = 1.7;     % upper bound for condition 4
    end
    % to actually trim the set:
    P_Trim2 = ParticleTrim(P_Trim1,TrimField,LowerBound,UpperBound);
    figure(8); clf; ParticlePropOverlay_ND2(reader,P_Trim2,AnalysisNumber,ImType,'MinAx',FilterParameters,[])


    %% v. track remaining particles based on coordinate distance
    
    TrackMode = 'position';       % Choice of {position, velocity, acceleration} to predict position based on previous behavior
    DistanceLimit = 5;            % Limit of distance a particle can travel between frames, in units defined by ConversionFactor
    MatchMethod = 'best';         % Choice of {best, single}
    P_Tracks = Particle_Track(P_Trim2,TrackMode,DistanceLimit,MatchMethod);
    
    %% 4. Store tracked data into single workspace, D
    
    % change 2: commented out track linker for non-swimming cells
    
    %PT = TrackLinker(P_Tracks, 'acceleration', 'acceleration', 3, 3, 2);
    %TL=TrackLength(PT);
    %PT(TL<8)=[];

    %A=arrayfun(@(Q) max(Q.Area),PT);

    D{ii} = P_Tracks;
    T{ii} = ND2ReaderT(reader);

    
end


save('lb-fluc-2017-10-24-c123-width1p4-c4-width1p7.mat','D','T')


   %% Section Three (E): clear section variables.
   
    clear ii P_Trim1 P_Trim2 AnalysisNumber TrimField UpperBound LowerBound;
    % Restart analysis from the end of Section Two.
    
    


%%
%   quality control -- visualize tracks on image

figure(2)
Img=double(bfGetPlane(reader, 1));
clf
imagesc([1:size(Img,2)]*ConversionFactor,[1:size(Img,1)]*ConversionFactor,Img); colormap gray
hold on
for n=1:length(P_Tracks)
plot([1:length(P_Tracks(n).X)]*ConversionFactor+P_Tracks(n).X(1),P_Tracks(n).MajAx+P_Tracks(n).Y(1))
%hold on
%plot(P_Tracks(n).X(1),P_Tracks(n).Y(1),'r.')
end
axis xy

