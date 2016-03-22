
Name='poly-challenge-2016-03-16a';
reader=bfGetReader([Name,'.nd2']);      %This line takes a long time if the ND2 file is large.
ConversionFactor = 6.5/60;              %Scope5 Andor COSMOS = 6.5um pixels, divide by magnification used

%%
% Image --> Unconnected Particles

ImageNumber=1;
% To refine the filter parameters, use:
FilterTest_ND2(reader,ImageNumber,{[10,.8,40],'gaussian'})



%%  Section Three: Process All Files
NSeries=reader.getSeriesCount();

for ii=0:NSeries-1
    reader.setSeries(ii);
    NImg=reader.getImageCount();
    
    FilterParameters = {[10,.8,40],'gaussian'}; %Parameters for spatial filtering:
    %                                       first number   - Highpass filter radius in pixels > lowpass #, Inf to skip
    %                                       second  number - Lowpass filter radius in pixels, zero to skip
    %                                       third number   - Filter size. Should be at least twice the max radius, more if Gaussian.  Large numbers increase processing time
    %                                       Filter type    - Either 'tophat' or 'gaussian'.  The latter gives slightly less ringing

    Threshold =  [-147.904, -1];         %[-5.46961, -1];%[] for GUI, make array with second value +/- 1 to indicate direction of threshold, default positive.
    Background = [];                        %Background image to substract from data.  Run empty on a subset and rerun using the mean image in the Im structure if desired
    PlotFlag = 0;                           %Set this flag to 1 in order to plot temporary results
    ImType = {'Single'};                 %This sets the type of image being used.  Options are:
                                            %   'Single' - Processes individual images corresponding to the numbers in FileNumbers
                                            %   'Diff+'  - The image with a number higher than the target image is subtracted
                                            %   'Diff-'  - The image with a number less than the target image is subtracted
                                            %   'Rolling'- The average of the adjacent images is subtracted from the target image
                                            %The second number gives the separation between images

    [P,Im] = Particle_Centroid_ND2(reader,FilterParameters,Threshold,[],Background,ImType,ConversionFactor,PlotFlag);  %Actual Processing

 
    %%
%     figure(2); clf; PlotParticles(P); colormap(jet)
    AnalysisNumber=40;  %Note that if Difference or Rolling image approaches are used, 
    %make sure that the file associated with AnalysisNumber also exists (eg AnalysisNumber + 2 for ['Diff+',2])
    figure(6); clf; ParticlePropOverlay_ND2(reader,P,AnalysisNumber,ImType,'MinAx',FilterParameters,[])

    %%
    TrimField = 'A';  %Choose relevant characteristic to restrict, run several times to apply for several fields
    LowerBound = 0.8;  %Lower bound for restricted field, or -Inf
    UpperBound = 8; %Upper bound for restricted field, or Inf
    % To actually trim the set:
    P_Trim1 = ParticleTrim(P,TrimField,LowerBound,UpperBound);
    figure(7); clf; ParticlePropOverlay_ND2(reader,P_Trim1,AnalysisNumber,ImType,'A',FilterParameters,[])

    
    %%
    TrimField = 'MinAx';  %Choose relevant characteristic to restrict, run several times to apply for several fields
    LowerBound = 1.2;  %Lower bound for restricted field, or -Inf
    UpperBound = 1.6; %Upper bound for restricted field, or Inf
    % To actually trim the set:
    P_Trim2 = ParticleTrim(P_Trim1,TrimField,LowerBound,UpperBound);
    figure(8); clf; ParticlePropOverlay_ND2(reader,P_Trim2,AnalysisNumber,ImType,'MinAx',FilterParameters,[])


    %%
    TrackMode = 'position';   % Choice of {position, velocity, acceleration} to predict position based on previous behavior
    DistanceLimit = 5;            % Limit of distance a particle can travel between frames, in units defined by ConversionFactor
    MatchMethod = 'best';         % Choice of {best, single}
    P_Tracks = Particle_Track(P_Trim2,TrackMode,DistanceLimit,MatchMethod);
    
    %%
    PT = TrackLinker(P_Tracks, 'acceleration', 'acceleration', 3, 3, 2);
    TL=TrackLength(PT);
    PT(TL<8)=[];

    A=arrayfun(@(Q) max(Q.Area),PT);

    D{ii+1}=PT;
end
T=ND2ReaderT(reader);
save('poly-challenge-2016-03-16a.mat','D','T')

%%


   %% Section Three (E): clear section variables.
   
    clear ii P_Trim1 P_Trim2 AnalysisNumber TrimField UpperBound LowerBound;
    % Restart analysis from the end of Section Two.
    
    
%%  

figure(1)
clf
for n=1:length(P_Tracks)
% plot(PT(n).Frame,PT(n).Area)
plot(PT(n).Frame(1:end-1),diff(PT(n).MajAx),'.')
hold on
end

%%
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

