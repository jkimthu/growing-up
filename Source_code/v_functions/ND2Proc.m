Name='hcb33-tbover2-tb-';
reader=bfGetReader([Name,'.nd2']);      %This line takes a long time if the ND2 file is large.
ConversionFactor = 6.45/60;             %Scope1 Hamamatsu = 6.45um pixels, divide by magnification used

%%
% Image --> Unconnected Particles

ImageNumber=1;
% To refine the filter parameters, use:
FilterTest_ND2(reader,ImageNumber,{[10,.8,40],'gaussian'})
% StepTest_ND2(reader,ImageNumber,[1:10],{[Inf,0.8,40],'gaussian'})


%%  Section Three: Process All Files
NSeries=reader.getSeriesCount();

for ii=0:NSeries-1
    reader.setSeries(ii);
    NImg=reader.getImageCount();
    %fps=1/mean(diff(T));
    
    FilterParameters = {[10,.8,40],'gaussian'}; %Parameters for spatial filtering:
    %                                       first number   - Highpass filter radius in pixels > lowpass #, Inf to skip
    %                                       second  number - Lowpass filter radius in pixels, zero to skip
    %                                       third number   - Filter size. Should be at least twice the max radius, more if Gaussian.  Large numbers increase processing time
    %                                       Filter type    - Either 'tophat' or 'gaussian'.  The latter gives slightly less ringing

    Threshold =  [];         %[-5.46961, -1];%[] for GUI, make array with second value +/- 1 to indicate direction of threshold, default positive.
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
%     figure(5); clf; ParticlePropOverlay_ND2(reader,P,AnalysisNumber,ImType,'AvgInt',FilterParameters,[0,600])
    figure(6); clf; ParticlePropOverlay_ND2(reader,P,AnalysisNumber,ImType,'MinAx',FilterParameters,[])

    %%
    TrimField = 'A';  %Choose relevant characteristic to restrict, run several times to apply for several fields
    LowerBound = 3;  %Lower bound for restricted field, or -Inf
    UpperBound = Inf; %Upper bound for restricted field, or Inf
    % To actually trim the set:
    P_Trim1 = ParticleTrim(P,TrimField,LowerBound,UpperBound);
    figure(7); clf; ParticlePropOverlay_ND2(reader,P_Trim1,AnalysisNumber,ImType,'A',FilterParameters,[])

    
    %%
    TrimField = 'MinAx';  %Choose relevant characteristic to restrict, run several times to apply for several fields
    LowerBound = 1.2;  %Lower bound for restricted field, or -Inf
    UpperBound = 2; %Upper bound for restricted field, or Inf
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
%     PT(A<4.5)=[];
%     A=arrayfun(@(Q) min(Q.Area),PT);
%     PT(A<4)=[];
    
    D{ii+1}=PT;
end

T=ND2ReaderT(reader);

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

%%  Begin Plotting Results
figure(1)
clf
dT=mean(mean(diff(T)));
subplot(211)
for n=1:3
    for m=1:length(D{n})
       plot(T(D{n}(m).Frame(1:end-1),n)/60,diff(D{n}(m).MajAx)/dT*60*60,'.','MarkerSize',15,'color',[0,0,1]+(n-1)*[.25,.25,0])
       hold on
    end
end
axis([0,315,-5,15])
plot(T(:,1)/60,polyval(p1,T(:,1)),'b','LineWidth',3)

xlabel('Time (min)')
ylabel('Growth Rate (um/hr - Length)')
title(sprintf('Oscillating Input: %0.03g um/hr',p1(1)*3600))
subplot(212)
for n=4:6
    for m=1:length(D{n})
       plot(T(D{n}(m).Frame(1:end-1),n)/60,diff(D{n}(m).MajAx)/dT*60*60,'.','MarkerSize',15,'color',[1,0,0]+(n-1)*[0,.1,.1])
       hold on
    end
end
xlabel('Time (min)')
ylabel('Growth Rate (um/hr - Length)')
title(sprintf('Constant Input: %0.03g um/hr',p2(1)*3600))
axis([0,315,-5,15])
plot(T(:,1)/60,polyval(p2,T(:,1)),'r','LineWidth',3)

%%
D_osc=[];
for n=1:3
    for m=1:length(D{n})
       Dt=[T(D{n}(m).Frame(1:end-1),n)/60,diff(D{n}(m).MajAx)/dT*60*60];
       D_osc=[D_osc;Dt];
    end
end
D_con=[];
for n=4:6
    for m=1:length(D{n})
       Dt=[T(D{n}(m).Frame(1:end-1),n)/60,diff(D{n}(m).MajAx)/dT*60*60];
       D_con=[D_con;Dt];
    end
end

%%

D_osc(D_osc(:,2)<-8,2)=NaN;
D_con(D_con(:,2)<-8,2)=NaN;
D_osc(D_osc(:,2)>15,2)=NaN;
D_con(D_con(:,2)>15,2)=NaN;

figure(2)
clf
dTmn=dT/60;
D_osc_mn=accumarray(1+round(D_osc(:,1)/dTmn),D_osc(:,2),[size(T,1),1],@nanmean);
D_con_mn=accumarray(1+round(D_con(:,1)/dTmn),D_con(:,2),[size(T,1),1],@nanmean);


f=find(~isnan(D_osc(:,2)));
plot(D_osc(f,1),D_osc(f,2),'.')
hold on
f=find(~isnan(D_con(:,2)));
plot(D_con(f,1),D_con(f,2),'.r')
p1=polyfit(T(:,1),D_osc_mn,1);

f=find(D_con_mn~=0);
% plot(T(:,1)/60,D_osc_mn,'b.')
% hold on
% plot(T(f,1)/60,D_con_mn(f),'r.')
p2=polyfit(T(f,1),D_con_mn(f),1);
plot(T(:,1)/60,polyval(p1,T(:,1)),'b','LineWidth',3)
plot(T(:,1)/60,polyval(p2,T(:,1)),'r','LineWidth',3)
axis([0,315,-5,15])
xlabel('Time (min)')
ylabel('Growth Rate, Length')
title(sprintf('Fitted Growth: %0.03g um^2/hr, %0.03g um^2/hr',p1(1)*3600,p2(1)*3600))

% 
% 
% figure(3)
% clf
% f=find(~isnan(D_osc(:,2)));
% Dot=D_osc(f,:);
% [~,SI]=sort(Dot(:,1));
% Dot=Dot(SI,:);
% p1b=polyfit(Dot(:,1),Dot(:,2),1);
% plot(D_osc(f,1),D_osc(f,2),'.')
% hold on
% f=find(~isnan(D_con(:,2)));
% p2b=polyfit(D_con(f,1),D_con(f,2),1);
% plot(D_con(f,1),D_con(f,2),'.r')
% plot(T(:,1)/60,polyval(p1b,T(:,1)),'b--','LineWidth',3)
% plot(T(:,1)/60,polyval(p2b,T(:,1)),'r--','LineWidth',3)
%        
%     

%%
figure(1)
clf
dT=mean(mean(diff(T)));
subplot(211)
for n=1:3
    for m=1:length(D{n})
       plot(T(D{n}(m).Frame(1:end),n)/60,(D{n}(m).MajAx),'color',[0,0,1]+(n-1)*[.15,.15,0],'Linewidth',2)
       hold on
    end
end
axis([0,315,0,15])

xlabel('Time (min)')
ylabel('Length (um)')
title('Raw Growth, Oscillating Input')
subplot(212)
for n=4:6
    for m=1:length(D{n})
       plot(T(D{n}(m).Frame(1:end),n)/60,(D{n}(m).MajAx),'color',[1,0,0]+(n-1)*[0,.05,.05],'Linewidth',2)
       hold on
    end
end
xlabel('Time (min)')
ylabel('Length (um)')
title('Raw Growth, Constant Input')
axis([0,315,0,15])

