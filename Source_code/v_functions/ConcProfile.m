function [B,R,HCorr]=ConcProfile(P,Im,edges,BMask,DispFlag)

% This script assumes that particles have been found and are contained in a
% structure P (from ATrackingScript) and that the associated image
% structure Im exists.

if nargin<5
    DispFlag=0;
end
if nargin<4
    BMask=[];
end
if nargin<3
    edges=[0:5:500];
end
cntrs=(edges(1:end-1)+edges(2:end))/2;

%%
x=[1:size(Im.Mean,2)]*P(1).Conv;
y=[1:size(Im.Mean,1)]*P(1).Conv;

figure(1)
clf
imagesc(x,y,Im.Mean); colormap gray
axis image
hold on
axis xy
title('Choose Central Point')
[xo,yo]=ginput(1);
plot(xo,yo,'ro')

%%  Mask Processing & Distance Calculation
if ~isempty(BMask)
    Bnd = bwboundaries(BMask,'noholes');
    P_Trim_Mask=[];
    h=waitbar(0,'Applying Mask to Found Particles');
    for n=1:length(P);
        waitbar(n/length(P),h)
        Bbin=zeros(size(P(n).X));
        for m=1:length(Bnd)
            [fin,fon]=inpolygon(P(n).X,P(n).Y,Bnd{m}(:,2)*P(n).Conv,Bnd{m}(:,1)*P(n).Conv);
            Bbin=or(Bbin,or(fin,fon));
        end
        P_Mask(n).X=P(n).X(~Bbin);
        P_Mask(n).Y=P(n).Y(~Bbin);
        P_Mask(n).Conv=P(n).Conv;
        P_Mask(n).Frame=P(n).Frame;
    end
    close(h);
    P=P_Mask;
    
    %Find Normalizing Correction 
    [xm,ym]=find(~BMask');
    Xg=xm*P(1).Conv;
    Yg=ym*P(1).Conv;
    Rg=sqrt((Xg-xo).^2+(Yg-yo).^2);
    HMask=histc(Rg(:),edges);
    HMask(end)=[];
    HCorr=HMask.*1./(2*pi*cntrs');
    f=find((max(HCorr(3:end))-HCorr)/max(HCorr(3:end))<.01);
    HCorr=HCorr/mean(HCorr(f));

    if DispFlag
        n=3;
        figure(1)
        clf
        plot(Xg,Yg,'.')
        hold on
        f=find(and(Rg>edges(n),Rg<edges(n+1)));
        plot(Xg(f),Yg(f),'r*')
        axis image
        title('Testing Masking Results')
    end
else
    %Find Normalizing Correction 
    [xm,ym]=find(ones(size(Im.Mean)));
    Xg=xm*P(1).Conv;
    Yg=ym*P(1).Conv;
    Rg=sqrt((Xg-xo).^2+(Yg-yo).^2);
    HMask=histc(Rg(:),edges);
    HMask(end)=[];
    HCorr=HMask.*1./(2*pi*cntrs');
    f=find((max(HCorr(3:end))-HCorr)/max(HCorr(3:end))<.01);
    HCorr=HCorr/mean(HCorr(f));

end
Rp=arrayfun(@(Q) sqrt((Q.X-xo).^2+(Q.Y-yo).^2),P,'UniformOutput',0);

%%  Plotting
%Plotting Parameters
if DispFlag
    nR=6;  %Radial ring number (1 being closest to center)
    nF=20;  % Image Number

    figure(2)
    clf
    imagesc(x,y,Im.Mean); colormap gray
    axis image
    axis xy
    hold on
    plot(xo,yo,'ro')
    title('Example Radial Search')

    plot(P(nF).X,P(nF).Y,'.')
    f=find(and(Rp{nF}>edges(nR),Rp{nF}<edges(nR+1)));
    plot(P(nF).X(f),P(nF).Y(f),'m.')
    plot(xo+edges(nR)*cos(2*pi*[0:.01:1]),yo+edges(nR)*sin(2*pi*[0:.01:1]),'m')
    plot(xo+edges(nR+1)*cos(2*pi*[0:.01:1]),yo+edges(nR+1)*sin(2*pi*[0:.01:1]),'m')
end
%%
%Calculate Histogram
H=cellfun(@(q) histc(q,edges),Rp,'UniformOutput',0);
H=cell2mat(H);
H(end,:)=[];

%Normalize Histogram
zdist = 10; %depth of field in microns
B=H.*repmat(1./(2*pi*cntrs'*zdist*(edges(2)-edges(1)).*HCorr),1,size(H,2));
B(isnan(B))=0;
R=cntrs;

