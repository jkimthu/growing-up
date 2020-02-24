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
fps=125;                %Frames per second of capture
ConversionFactor = 1.7; %1 for pixel units, otherwise use pixel to um conversion from scope with magnification (use microscope booking site for camera spec)

%To test the algorithm on fake data, the following command will make a new
%subfolder to the current directory with 
% NumFrames = 100;
% VelRange = [5:5:200]; in microns/s
% PartRad = 1; in microns, refers to standard deviation of gaussian.
% TestData(PartRad,VelRange,NumFrames,ConversionFactor,fps)

% File Definition
FileStruct  = FileFind();         %No arguments for GUI, can also pass a path and filename to convert to correct structure.  Choose a file with the same format as the others of interest
FileNumbers = [10:100];        %The numbers in the filenames of the images to be processed

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
% FilterTest(FileStruct,ImageNumber,{[5,.1,30],'gaussian'})

FilterParameters = {[5,.2,30],'gaussian'}; %Parameters for spatial filtering:
%                                       first number   - Highpass filter radius in pixels > lowpass #, Inf to skip
%                                       second  number - Lowpass filter radius in pixels, zero to skip
%                                       third number   - Filter size. Should be at least twice the max radius, more if Gaussian.  Large numbers increase processing time
%                                       Filter type    - Either 'tophat' or 'gaussian'.  The latter gives slightly less ringing

Threshold =  [];%[] for GUI, make array with second value +/- 1 to indicate direction of threshold, default positive.
Background = [];                        %Background image to substract from data.  Run empty on a subset and rerun using the mean image in the Im structure if desired
PlotFlag = 0;                           %Set this flag to 1 in order to plot temporary results
ImType = {'Rolling',6};                 %This sets the type of image being used.  Options are:
                                        %   'Single' - Processes individual images corresponding to the numbers in FileNumbers
                                        %   'Diff+'  - The image with a number higher than the target image is subtracted
                                        %   'Diff-'  - The image with a number less than the target image is subtracted
                                        %   'Rolling'- The average of the adjacent images is subtracted from the target image
                                        %The second number gives the separation between images
                                        
[P,Im] = Particle_Centroid(FileStruct,FilterParameters,Threshold,FileNumbers,Background,ImType,ConversionFactor,fps,PlotFlag);  %Actual Processing
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
%   .FPS  - a single number representing capture rate
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
    disp(['Saved Raw Particle Data to', FullSaveName])
end

%%
% Remove Unwanted Particles

%Uncomment the following lines to examine particle distribution, it may be
%desireable to run on a subset of the results due to processing limitations
Num_Particles=ParticleNum(P);
figure(1); clf; plot(Num_Particles);
figure(2); clf; PlotParticles(P); colormap(jet)

AnalysisNumber=FileNumbers(1);  %Note that if Difference or Rolling image approaches are used, 
%make sure that the file associated with AnalysisNumber also exists (eg AnalysisNumber + 2 for ['Diff+',2])
figure(5); clf; ParticlePropOverlay(FileStruct,P,AnalysisNumber,ImType,'AvgInt',FilterParameters)
figure(6); clf; ParticlePropOverlay(FileStruct,P,AnalysisNumber,ImType,'A',FilterParameters)

TrimField = 'AvgInt';  %Choose relevant characteristic to restrict, run several times to apply for several fields
LowerBound = .1*10^4;  %Lower bound for restricted field, or -Inf
UpperBound = Inf; %Upper bound for restricted field, or Inf

% To evaluate the parameters, for a single trim, use the following:
figure(3); clf; ParticleTrimOverlay(FileStruct,P,AnalysisNumber,TrimField, LowerBound, UpperBound,ImType,FilterParameters)
% Blue circles are below the lower bound, red above the upper bound, green would be kept.

% To actually trim the set:
P_Trim = ParticleTrim(P,TrimField,LowerBound,UpperBound);
% The output P_Trim has the same format as P, but has only the particles
% that satisfied the limited range specified.


%The process can be repeated, for example:
TrimField = 'A';  %Choose relevant characteristic to restrict, run several times to apply for several fields
LowerBound = .5;  %Lower bound for restricted field, or -Inf
UpperBound = 1.2; %Upper bound for restricted field, or Inf
P_Trim = ParticleTrim(P_Trim,TrimField,LowerBound,UpperBound);

% To see the result of several trim passes:
figure(4); clf; ParticleTrimOverlayResult(FileStruct,P,P_Trim,AnalysisNumber,ImType,FilterParameters)
%These aren't color coded, but will highlight all the original particles in
%blue, and put red x's inside those that are kept.


Num_Particles(:,2)=ParticleNum(P_Trim);

% This will play a movie of raw images (no differences etc) with the
% particles that have been identified and kept highlighted.  Leave
% commented if you're running the whole file at once:
TestTrack(FileStruct,P_Trim,fps,ConversionFactor,FilterParameters)


if SaveFlag
    save(FullSaveName, 'P','Im','FileStruct','FilterParameters','Num_Particles','FileNumbers','P_Trim')
    disp(['Saved Filtered Particle Data to', FullSaveName])
end

%% 
% Find Tracks from Particle List
TrackMode = 'acceleration';   % Choice of {position, velocity, acceleration} to predict position based on previous behavior
DistanceLimit = 8;            % Limit of distance a particle can travel between frames, in units defined by ConversionFactor
MatchMethod = 'best';         % Choice of {best, single}
P_Tracks = Particle_Track(P_Trim,TrackMode,DistanceLimit,MatchMethod);  %Routine for connecting found particles into tracks
% The output P_Tracks is a structure array with each structure in an array
% representing the the information for a track.
% P_Tracks.X         - a vector of the X position of a particle over time
%         .Y         - a vector of the Y position of a particle over time
%         .Area      - a vector of the associated particle area over time
%         .Intensity - a vector of the peak intensity of the particle over time
%         .Frame     - a vector of the frames associated with each step in
%                      the particle track, corresponding to the time
%         .TrackID   - a vector repeating the track ID number
%         .Conv      - a single number for the conversion factor in um/pixel

if SaveFlag
    save(FullSaveName, 'P','Im','FileStruct','FilterParameters','Num_Particles','FileNumbers','P_Trim','P_Tracks')
    disp(['Saved Raw Track Data to', FullSaveName])
end

%%
% Track Trimming and Analysis

% Routine for Trimming Tracks based on length
MinFrameLength=6;  %Set the minimum number of frames for a track of interest, needs to be at least > 2*FitLength
Track_Length=TrackLength(P_Tracks);        %Find track lengths
P_Tracks_Trim=P_Tracks(Track_Length>MinFrameLength);     %Trim tracks with less than desired length

% Calculate Fitted Position, Velocity, and Acceleration
FitLength=3;    %This describes the type and size of fitting for calculation, 
                % 0 - first order difference
                % 1 - second order difference
                % n>1 - polynomial fit, must be equal or larger than MinFrameLength
P_Tracks_Analysis=Trajectory(P_Tracks_Trim,FitLength,fps); %Calculate Track Properties
% The output P_Tracks_Analysis is a structure array with each structure
% element in the array representing a different track.
% P_Tracks_Analysis - in addition to the fields from the particle tracking (ie X, Y, Area, etc):
%                  .XFit - a vector of the fitted X position 
%                  .YFit - a vector of the fitted Y position
%                  .VelX - a vector of the X velocity based on the fitted position
%                  .VelY - a vector of the Y velocity based on the fitted position
%                  .AccX - a vector of the X acceleration based on the fitted position
%                  .AccY - a vector of the Y acceleration based on the fitted position
%                  .Fit  - a single number representing the fit length used for calculation
%                  .FPS  - a single number representing capture rate
%                  .Conv - a single number for the conversion factor in um/pixel

% Plot the resulting data distribution
figure(2); PlotTrackStats(P_Tracks_Analysis) 

% Plot the Tracks & overlay velocity
figure(3); PlotTracks(P_Tracks_Analysis)

if SaveFlag
    save(FullSaveName, 'P','Im','FileStruct','FilterParameters','Num_Particles','FileNumbers','P_Trim','P_Tracks','P_Tracks_Analysis')
    disp(['Saved Analyzed Track Data to', FullSaveName])
end

%%
% Look at velocity as function of time
PTA=ParticleTracks2Time(P_Tracks_Analysis); 
%PTA has the same fields as P_Tracks_Analysis, but it is sorted by time.
%Each element of PTA is a single frame.

%Plot the velocity distribution over time
figure(4); clf; PlotParticleVel(PTA)

% Look at the overall tracking result (with fitted positions)
TestTrack(FileStruct,PTA,fps,ConversionFactor,FilterParameters)

if SaveFlag
    save(FullSaveName, 'P','Im','FileStruct','FilterParameters','Num_Particles','FileNumbers','P_Trim','P_Tracks','P_Tracks_Analysis','PTA')
    disp(['Saved Resorted Track Data to', FullSaveName])
end
