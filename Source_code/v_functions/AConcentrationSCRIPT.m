% This file goes through all the steps for identifying, selecting, and
% tracking particles. Once all the parameters have been determined on a
% small sample of a dataset, the entire thing can be run all at once by
% pressing the play button or 'F5'.  However, it's best to comment out all
% the commands that provide feedback on the quality of each step for the
% final run.  For the more iterative first time through, it's easiest to
% make use of the cells in the code (different sections separated by a
% '%%'). If the cursor is placed in the cell of interest, Control-Enter
% will run the code between '%%'s.  To run just a single line (ie the
% FilterTest command to identify the appropriate filter parameters) you can
% highlight the line and press 'F9' or just copy it into the command line.

% This setup has been tested primarily with grayscale tif images.  There's
% no reason it shouldn't work with other grayscale image formats, but there
% might be some small bugs involved. Regardless of the format, each frame
% should be saved as a separate image file, numbered numerically.

% In general, I would suggest extracting all the associated files into a
% folder that is then added to the matlab path via File -> Set Path.  Then
% copy this file into a folder near the data to be analysized, so that all
% the modification to parameters will be saved and associated with the
% particular data set. In general, avoid making the folder with all the
% images the current folder for matlab, as it tends cause issues when there
% are so many files.

%Experimental Variables - Change for each data set
fps=10;                %Frames per second of capture
ConversionFactor = 8/15; %1 for pixel units, otherwise use pixel to um conversion from scope with magnification

%To test the algorithm on fake data, the following command will make a new
%subfolder to the current directory with 
% NumFrames = 100;
% VelRange = [5:5:200]; in microns/s
% PartRad = 1; in microns, refers to standard deviation of gaussian.
% TestData(PartRad,VelRange,NumFrames,ConversionFactor,fps)

% File Definition
FileStruct  = FileFind();         %No arguments for GUI, can also pass a path and filename to convert to correct structure.  Choose a file with the same format as the others of interest
FileNumbers = [13150:13250];          %The numbers in the filenames of the images to be processed

% File save name and path.  Modify if desired.
SaveName='TrackingResults.mat';
PathName=[FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num),filesep];

% Turn off the flag (set to 0) to not save!  Set it to 1 to save at each stage.
SaveFlag=0;
mkdir(PathName,'Saves');
FullSaveName=[PathName,'Saves',filesep,SaveName;];


%%
% Image --> Unconnected Particles

ImageNumber=FileNumbers(1);
% To refine the filter parameters, use:
FilterTest(FileStruct,ImageNumber,{[10,.2,30],'gaussian'})

FilterParameters = {[10,.2,30],'gaussian'}; %Parameters for spatial filtering:
%                                       first number   - Highpass filter radius in pixels > lowpass #, Inf to skip
%                                       second  number - Lowpass filter radius in pixels, zero to skip
%                                       third number   - Filter size. Should be at least twice the max radius, more if Gaussian.  Large numbers increase processing time
%                                       Filter type    - Either 'tophat' or 'gaussian'.  The latter gives slightly less ringing

Threshold =  [];                      %[] for GUI, make array with second value +/- 1 to indicate direction of threshold, default positive.
Background = [];                        %Background image to substract from data.  Run empty on a subset and rerun using the mean image in the Im structure if desired
PlotFlag = 0;                           %Set this flag to 1 in order to plot temporary results
ImType = {'Rolling',1};                 %This sets the type of image being used.  Options are:
                                        %   'Single' - Processes individual images corresponding to the numbers in FileNumbers
                                        %   'Diff+'  - The image with a number higher than the target image is subtracted
                                        %   'Diff-'  - The image with a number less than the target image is subtracted
                                        %   'Rolling'- The average of the adjacent images is subtracted from the target image
                                        %The second number gives the separation between images
                                        
[P,Im] = Particle_Centroid(FileStruct,FilterParameters,Threshold,FileNumbers,Background,ImType,ConversionFactor,PlotFlag);  %Actual Processing
% The output P is an array of structures.  Each structure (ie P(1))
% contains the results for that frame.  The structure has the form:
%  P.X      - a vector of central X coordinates, weighted by the pixel intensity
%   .Y      - a vector of central Y coordinates, weighted by the pixel intensity
%   .A      - a vector of the area for the particles
%   .AvgInt - a vector of the average light intensity of the particles
%   .MaxInt - a vector of the peak light intensity within the particles
%   .AvgIntRaw - Only present if ImType is not 'Single', Same as AvgInt but for raw image
%   .MaxIntRaw - Only present if ImType is not 'Single', Same as MaxInt but for raw image
%   .Frame  - a single number corresponding to the value of 'FileNumbers' associated with the structure
%   .Conv   - a single number for the conversion factor in um/pixel

%
% The output Im is a structure of various image transportations on the data
% set
% Im.MaxProj     - Maximum pixel intensity projection of the raw data
%   .MaxProjProc - Maximum pixel intensity projection of the filtered data
%   .MinProj     - Minimum pixel intensity projection of the raw data
%   .MinProjProc - Minimum pixel intensity projection of the filtered data
%   .Mean        - Mean of the raw data
%   .MeanFilt    - Mean of the filtered data

% This command makes a subdirectory with filtered images for later reference.
% Don't use it unless you want to wait a while.
% Rng=[-50,500]; %Post-filter dynamic range limits for rescaling
% FileFilter(FileStruct,FileNumbers,FilterParameters,Rng,PlotFlag)

if SaveFlag
    save(FullSaveName, 'P','Im','FileStruct','FilterParameters','FileNumbers')
end

%%
% Remove Unwanted Particles

%Uncomment the following lines to examine particle distribution, it may be
%desireable to run on a subset of the results due to processing limitations
NumParticles=arrayfun(@(Q) length(Q.X),P)';
figure(1); clf; plot(NumParticles);
	

AnalysisNumber=FileNumbers(1);  %Note that if Difference or Rolling image approaches are used, 
%make sure that the file associated with AnalysisNumber also exists (eg AnalysisNumber + 2 for ['Diff+',2])
figure(5); clf; ParticlePropOverlay(FileStruct,P,AnalysisNumber,ImType,'AvgInt',FilterParameters)
figure(6); clf; ParticlePropOverlay(FileStruct,P,AnalysisNumber,ImType,'A',FilterParameters)

TrimField = 'A';  %Choose relevant characteristic to restrict, run several times to apply for several fields
LowerBound = 1;  %Lower bound for restricted field, or -Inf
UpperBound = 12; %Upper bound for restricted field, or Inf

% To evaluate the parameters, for a single trim, use the following:
figure(3); clf; ParticleTrimOverlay(FileStruct,P,AnalysisNumber,TrimField, LowerBound, UpperBound,ImType,FilterParameters)
% Blue circles are below the lower bound, red above the upper bound, green would be kept.

% To actually trim the set:
P_Trim0 = ParticleTrim(P,TrimField,LowerBound,UpperBound);
% The output P_Trim has the same format as P, but has only the particles
% that satisfied the limited range specified.


%The process can be repeated, for example:
TrimField = 'AvgInt';  %Choose relevant characteristic to restrict, run several times to apply for several fields
LowerBound = -Inf  ;  %Lower bound for restricted field, or -Inf
UpperBound = -3000; %Upper bound for restricted field, or Inf
P_Trim = ParticleTrim(P_Trim0,TrimField,LowerBound,UpperBound);


% To see the result of several trim passes:
figure(4); clf; ParticleTrimOverlayResult(FileStruct,P,P_Trim,AnalysisNumber,ImType,FilterParameters)
%These aren't color coded, but will highlight all the original particles in
%blue, and put red x's inside those that are kept.


NumParticles(:,2)=arrayfun(@(Q) length(Q.X),P_Trim)';


% This will play a movie of raw images (no differences etc) with the
% particles that have been identified and kept highlighted.  Leave
% commented if you're running the whole file at once:
% TestTrack(FileStruct,P,fps,ConversionFactor,FilterParameters)


if SaveFlag
    save(FullSaveName, 'P','Im','FileStruct','FilterParameters','NumParticles','FileNumbers','P_Trim')
end


%% Calculate Concentration Profile and Filter
Mask=[];        % Binary image mask to remove bacteria over objects
DispFlag=1;     % 1 or 0 flag to plot extra descriptive figures
edges=[0:2:500];% Edges of distance bins, in microns
[B,R,H]=ConcProfile(P_Trim,Im,edges,Mask,DispFlag);
% B - Concentration as function of distance and time, in # of bacteria per micron ^3
% R - Centers of the bins in distance
% H - Area correction factor.  Small values mean very low SNR and should be cut
T=[1:size(B,2)]/fps;  % Time progression for B

break
% Plot raw concentration profile
figure(2)
clf
imagesc(T,R,B)

%Filter with multivariate gaussian
HPr=Inf;    % High Pass Filter Radius (set to Inf to skip)
LPx=25;    % Low Pass standard deviation in T direction
LPy=2;      % Low Pass standard deviation in R direction
FilterSz=500; %Size of filter, must be larger than 2x max(LPx,Lpy,HPr)
[h_obj, h_noise, h_comb] = FilterGen_Mvn(HPr, LPx, LPy, FilterSz);
Bfg=imfilter(B(2:70,:),h_comb,'replicate');
figure(4)
imagesc(T,cntrs(2:70),Bfg)
title('Asymmetric Gaussian Filter')

%Filter with median filter (for noise)
Bfm=medfilt2(B(2:70,:),[1,100]);
figure(5)
imagesc(T,cntrs(2:70),Bfm)
title('Asymmetric Median Filter')

if SaveFlag
    save(FullSaveName, 'P','Im','FileStruct','FilterParameters','NumParticles','FileNumbers','P_Trim','B','R','T')
end
