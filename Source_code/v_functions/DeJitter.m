function [DX,DY]=DeJitter(InterpNum,DMax,FileNumbers)


[IFileName,IPathName,FilterIndex]=uigetfile('*.tif','Choose the initial image in series');
if FilterIndex==0
    return
end
if nargin<3
    FileNumbers=[];
end
if isempty(FileNumbers)
    warning('Will run until out of images...')
end

if isempty(DMax)
    Dx=10;
    Dy=10;
elseif length(DMax==1)
    Dx=DMax;
    Dy=DMax;
else
    Dx=DMax(1);
    Dy=DMax(2);
end

mkdir(IPathName,'DeJitter');
%Annoying File Name Processing Stuff
h=find(IFileName=='.'); %find extension
f=find(IFileName=='0'); %find final zero-padding, assumes there is a zero
g=find(abs(diff(f(end:-1:1)))>1);  %number of zeros
if isempty(g)
    IFileName_Base=IFileName(1:f(1)-1);
    IFileName_Num=str2num(IFileName(f(1):h(end)-1));
    IFileName_Appnd=IFileName(h(end):end);
    IFileName_Length=length(f(1):h(end)-1);
else
    IFileName_Base=IFileName(1:f(end-g(1))+1);
    IFileName_Num=str2num(IFileName(f(end-g(1))+2:h(end)-1));
    IFileName_Appnd=IFileName(h(end):end);
    IFileName_Length=length(f(end-g(1))+2:h(end)-1);
end

if isempty(FileNumbers)
    Im0=double(imread([IPathName,sprintf(sprintf([IFileName_Base,'%%0%gg',IFileName_Appnd],IFileName_Length),IFileName_Num)]));
else
    Im0=double(imread([IPathName,sprintf(sprintf([IFileName_Base,'%%0%gg',IFileName_Appnd],IFileName_Length),FileNumbers(1))]));
end
figure(3); clf
imagesc(Im0); colormap gray
title('Interrogation Area')
rect=getrect(gcf);
RangeX=round([rect(1),rect(1)+rect(3)]);
RangeY=round([rect(2),rect(2)+rect(4)]);
hold on 
plot([rect(1),rect(1)+rect(3),rect(1)+rect(3),rect(1),rect(1)]',[rect(2),rect(2),rect(2)+rect(4),rect(2)+rect(4),rect(2)]')

[X0,Y0]=meshgrid(RangeX(1):1/InterpNum:RangeX(2),RangeY(1):1/InterpNum:RangeY(2));
Im0i=interp2(Im0,X0,Y0);
imwrite(uint16(Im0),[IPathName,'DeJitter\',sprintf('ImD_%04g',1),'.tif'],'tif','Compression','none')

RangeX0=RangeX;
RangeY0=RangeY;
RangeX=(RangeX-1)*InterpNum+1;
RangeY=(RangeY-1)*InterpNum+1;
DeltaX=[-Dx:Dx];
DeltaY=[-Dy:Dy];

N=1;
if isempty(FileNumbers)
    Ex=exist([IPathName,sprintf(sprintf([IFileName_Base,'%%0%gg',IFileName_Appnd],IFileName_Length),IFileName_Num+N)]);
    DX=[];
    DY=[];
else
    Ex=exist([IPathName,sprintf(sprintf([IFileName_Base,'%%0%gg',IFileName_Appnd],IFileName_Length),FileNumbers(N)+1)]);
    DX=zeros(length(FileNumbers),1);
    DY=zeros(length(FileNumbers),1);
end
while Ex>0    
    disp(N)
    if isempty(FileNumbers)
        ImNew=double(imread([IPathName,sprintf(sprintf([IFileName_Base,'%%0%gg',IFileName_Appnd],IFileName_Length),IFileName_Num+N)]));
    else
        ImNew=double(imread([IPathName,sprintf(sprintf([IFileName_Base,'%%0%gg',IFileName_Appnd],IFileName_Length),FileNumbers(N)+1)]));
    end
    [XN,YN]=meshgrid(1:1/InterpNum:size(ImNew,2),1:1/InterpNum:size(ImNew,1));
    ImNewi=interp2(ImNew,XN,YN);

    SAD=zeros(length(DeltaY),length(DeltaX));
    for n=1:length(DeltaX)
        for m=1:length(DeltaY)
            ImT1=Im0i;
            ImT2=ImNewi(RangeY(1)+DeltaY(m):RangeY(2)+DeltaY(m),RangeX(1)+DeltaX(n):RangeX(2)+DeltaX(n));
            ImD=abs(ImT1-ImT2);
            SAD(m,n)=sum(ImD(:));
        end
    end

    [m,n]=find(SAD==min(SAD(:)));
    [XN,YN]=meshgrid([1:size(ImNew,2)]+DeltaX(n)/InterpNum,[1:size(ImNew,1)]+DeltaY(m)/InterpNum);
    ImNewF=interp2(ImNew,XN,YN,'spline');%interp2(ImNew,XN,YN);
    DX(N)=DeltaX(n)/InterpNum;
    DY(N)=DeltaY(m)/InterpNum;
    Im0i=interp2(ImNewF,X0,Y0);
    
    imwrite(uint16(ImNewF),[IPathName,'DeJitter\',sprintf('ImD_%04g',N+1),'.tif'],'tif','Compression','none')

    N=N+1;
    if isempty(FileNumbers)
        Ex=exist([IPathName,sprintf(sprintf([IFileName_Base,'%%0%gg',IFileName_Appnd],IFileName_Length),IFileName_Num+N)]);
    else
        if N>length(FileNumbers)
            Ex=0;
        else
            Ex=exist([IPathName,sprintf(sprintf([IFileName_Base,'%%0%gg',IFileName_Appnd],IFileName_Length),FileNumbers(N)+1)]);
        end
    end
    
    figure(1)
    subplot(121)
    imagesc(abs(Im0-ImNewF)); axis image; colormap gray
    subplot(122)
    imagesc(abs(Im0-ImNew)); axis image; colormap gray
    figure(2)
    imagesc(SAD)
    axis equal
    drawnow
end
save([IPathName,'DeJitter\','ShiftData'],'DX','DY')


