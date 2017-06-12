%% .nd2 Proc for individually saved xy series

%  Purpose: exported multi-series from Elements on scope 5 computer are not
%  compatible with previous version of this script. (The NSeries line would
%  read the entire file as a single series.) Until resolved, by-pass this
%  error by exporting individual series and running tracking analysis on
%  each separately.


%  Last modified (jen): May 27, 2017

%  Section contents:
%
%    1. Create series directory  
%    2. Initialize tracking paramenters
%    3. Track cells, looping through all series
%    4. Compile data into single workspace, D

%   USER NOTES:
%   once particles are found in test series, manually proceed through
%         i.  trimming steps (three total)
%        ii.  tracking steps (two total)
%       iii.  quality control

%%   O N E.
%    create series directory 

xyDirectory = dir('poly-challenge-2017-06-05_xy*.nd2');
names = {xyDirectory.name};


%%   T W O.
%    initialize tracking parameters


%  set pixels to um conversion based on camera used
%  scope5 Andor COSMOS = 6.5um pixels / 60x magnification
ConversionFactor = 6.5/60;

%  use first image of first series
reader = bfGetReader(names{1});
ImageNumber=1;
%ii=1;

%  refine the filter parameters
%FilterTest_ND2(reader,ImageNumber,{[10,.8,40],'gaussian'})                 % Parameters for spatial filtering:
                                                                           
                                                                           %    first number   -  Highpass filter radius in pixels > lowpass #, Inf to skip
                                                                           %    second number  -  Lowpass filter radius in pixels, zero to skip
                                                                           %    third number   -  Filter size. Should be at least twice the max radius, more if Gaussian.  Large numbers increase processing time
                                                                           %    Filter type    -  Either 'tophat' or 'gaussian'.  The latter gives slightly less ringing
%  if happy, use these values for FilterParameters
FilterParameters = {[10,.8,40],'gaussian'};

%%
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


%%  T H R E E.
%   track the particles from all series

NSeries = length(names);
%NSeries=reader.getSeriesCount();

for ii = 1:NSeries
    %reader.setSeries(ii);
    reader = bfGetReader(names{ii});
    NImg=reader.getImageCount(); % Number of images to include in analysis, starting from 1
    
    Threshold =  [-25.8621, -1];       
    Background = [];                        
    PlotFlag = 0;                           
    ImType = {'Single'};                

    [P,Im] = Particle_Centroid_ND2(reader,FilterParameters,Threshold,[],Background,ImType,ConversionFactor,PlotFlag);  %Actual Processing

 
    %%
    %   trimming step one -- view particles as identified
    
    AnalysisNumber = 40;  %Note that if Difference or Rolling image approaches are used, 
    %make sure that the file associated with AnalysisNumber also exists (eg AnalysisNumber + 2 for ['Diff+',2])
    figure(6); clf; ParticlePropOverlay_ND2(reader,P,AnalysisNumber,ImType,'MinAx',FilterParameters,[])

    %%
    %   trimming step two -- trim by area
    
    TrimField = 'A';    % choose relevant characteristic to restrict, run several times to apply for several fields
    LowerBound = 0.8;   % lower bound for restricted field, or -Inf
    UpperBound = 8;     % upper bound for restricted field, or Inf
    
    % to actually trim the set:
    P_Trim1 = ParticleTrim(P,TrimField,LowerBound,UpperBound);
    figure(7); clf; ParticlePropOverlay_ND2(reader,P_Trim1,AnalysisNumber,ImType,'A',FilterParameters,[])

    
    %%
    %   trimming step three -- trim by particle width
    
    TrimField = 'MinAx';  % choose relevant characteristic to restrict, run several times to apply for several fields
    LowerBound = 1.0;     % lower bound for restricted field, or -Inf
    UpperBound = 1.6;     % upper bound for restricted field, or Inf
    
    % to actually trim the set:
    P_Trim2 = ParticleTrim(P_Trim1,TrimField,LowerBound,UpperBound);
    figure(8); clf; ParticlePropOverlay_ND2(reader,P_Trim2,AnalysisNumber,ImType,'MinAx',FilterParameters,[])


    %%
    %   tracking step one -- track particles based on coordinate distance
    
    TrackMode = 'position';       % Choice of {position, velocity, acceleration} to predict position based on previous behavior
    DistanceLimit = 5;            % Limit of distance a particle can travel between frames, in units defined by ConversionFactor
    MatchMethod = 'best';         % Choice of {best, single}
    P_Tracks = Particle_Track(P_Trim2,TrackMode,DistanceLimit,MatchMethod);
    
    %%
    %   tracking step two -- link tracks together and store in data matrix!
    
    PT = TrackLinker(P_Tracks, 'acceleration', 'acceleration', 3, 3, 2);
    TL=TrackLength(PT);
    PT(TL<8)=[];

    A=arrayfun(@(Q) max(Q.Area),PT);

    D{ii} = PT;
    T{ii} = ND2ReaderT(reader);

    
end



save('poly-challenge-2017-06-05.mat','D','T')

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

