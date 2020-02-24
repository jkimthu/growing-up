function [ParticleOut,Img]=Particle_Centroid(FileStruct,FilterParam,Threshold,FIndex,Backgrnd,DiffInfo,ConvFactor,Fps,PlotFlag)

if nargin<9; PlotFlag=0; end
if nargin<8; Fps=1; end
if nargin<7; ConvFactor=1; end
if nargin<6; DiffType='Single';DiffNum=1; end
if nargin<5; Backgrnd=[]; end
if nargin<4; FIndex=[]; end
if nargin<3; Threshold=[]; end
if nargin<2; FilterParam=[]; end
if nargin<1; FileStruct=[]; end

if length(Threshold)==2
    ThreshDir=Threshold(2);
    Threshold=Threshold(1);
elseif length(Threshold)==1
    ThreshDir=1;
end

if isempty(FileStruct)
    FileStruct=FileFind;
elseif  iscell(FileStruct)
    FileStruct=FileFind(FileStruct{1},FileStruct{2});
end
if isempty(FIndex)
    FIndex=FileStruct.File.Num;
end
if ~isempty(FilterParam)
    [h_obj, h_noise] = FilterGen_V(FilterParam{1}(1), FilterParam{1}(2),FilterParam{1}(3), FilterParam{2});
else
    h_obj=1;
    h_noise=0;
end
if isempty(ConvFactor)
    ConvFactor=1;
end

if isempty(DiffInfo)
    DiffType='Single';
else
    if length(DiffInfo)==2
        DiffType=DiffInfo{1};
        DiffNum=DiffInfo{2};
    else
        DiffType=DiffInfo{1};
        DiffNum=1;
    end
end

tic
if FIndex(end)-FIndex(1)<DiffNum
    error('File number range is smaller than difference length')
elseif  and(FIndex(end)-FIndex(1)<2*DiffNum+1,strcmp(DiffType,'Rolling'))
    error('File number range is smaller than difference length')
end
switch DiffType
    case 'Single'
        Im=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(1))]));
        Im=Im(:,:,1);
    case 'Diff+'
        ImR=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(1))]));
        ImRP=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(1)+DiffNum)]));
        ImR=ImR(:,:,1);  
        ImRP=ImRP(:,:,1);  
        Im=ImR-ImRP;
    case 'Diff-'
        ImR=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(1)+DiffNum)]));
        ImRM=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(1))]));
        ImR=ImR(:,:,1);  
        ImRM=ImRM(:,:,1);  
        Im=ImR-ImRM;
    case 'Rolling'
        ImR=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(1)+DiffNum)]));
        ImRP=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(1)+2*DiffNum)]));
        ImRM=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(1))]));
        ImR=ImR(:,:,1);  
        ImRM=ImRM(:,:,1);  
        ImRP=ImRP(:,:,1);  
        Im=ImR-(ImRP+ImRM)/2;
end
if ~strcmp(DiffType,'Single')
    Im0=ImR;
    Im1=ImR;
    ImM=ImR;
else
    Im0=Im;
    Im1=Im;
    ImM=Im;
end
if isempty(Backgrnd)
    Backgrnd=zeros(size(Im));
end
Im=Im-Backgrnd;



%Preperations to do outside of loop
Im_Filt=imfilter(Im,h_noise-h_obj,'replicate');
Im0F=Im_Filt;
Im1F=Im_Filt;
ImMF=Im_Filt;
if isempty(Threshold)
    ThreshDir=1;
    H=figure('Position',[34 314 1083 384]);
    subplot(121)
    imagesc(Im_Filt);
    colormap(gray)
    title('Mask - White Positive')
    subplot(122)
    cla
    hist(Im_Filt(:),100);
    ARange=axis;
    dX=ARange(2)-ARange(1);
    dY=ARange(4)-ARange(3);
    hold on
    plot([ARange(2)-dX*.2,ARange(2)-dX*.01,ARange(2)-dX*.01,ARange(2)-dX*.2,ARange(2)-dX*.2],...
         [ARange(4)-dY*.1,ARange(4)-dY*.1,ARange(4)-dY*.01,ARange(4)-dY*.01,ARange(4)-dY*.1],'k')
    text(ARange(2)-dX*.135,ARange(4)-dY*.06,'End')
    plot([ARange(2)-dX*.2,ARange(2)-dX*.01,ARange(2)-dX*.01,ARange(2)-dX*.2,ARange(2)-dX*.2],...
         [ARange(4)-dY*.1,ARange(4)-dY*.1,ARange(4)-dY*.01,ARange(4)-dY*.01,ARange(4)-dY*.1]-dY*.11,'k')
    text(ARange(2)-dX*.14,ARange(4)-dY*(.06+.11),'Sign')
    
    response=0;
    while ~response
        [x,y]=ginput(1);
        if and(x>ARange(2)-dX*.2,y>ARange(4)-dY*.1);
            response=1;
            break
        elseif and(and(x>ARange(2)-dX*.2,x<ARange(2)-dX*.01),and(y>ARange(4)-dY*.1-dY*.11,ARange(4)-dY*.01-dY*.11))
            ThreshDir=ThreshDir*-1;
            subplot(121)
            if ThreshDir<0
                imagesc(Im_Filt<=Threshold);
            else
                imagesc(Im_Filt>=Threshold);
            end
            colormap(gray)
            title('Mask - White Positive')
        else
            Threshold=x;
            subplot(121)
            if ThreshDir<0
                imagesc(Im_Filt<=Threshold);
            else
                imagesc(Im_Filt>=Threshold);
            end
            colormap(gray)
            title('Mask - White Positive')
            subplot(122)
            cla
            hist(Im_Filt(:),100);
            hold on
            plot([ARange(2)-dX*.2,ARange(2)-dX*.01,ARange(2)-dX*.01,ARange(2)-dX*.2,ARange(2)-dX*.2],...
                 [ARange(4)-dY*.1,ARange(4)-dY*.1,ARange(4)-dY*.01,ARange(4)-dY*.01,ARange(4)-dY*.1],'k')
            text(ARange(2)-dX*.135,ARange(4)-dY*.06,'End')
            plot([ARange(2)-dX*.2,ARange(2)-dX*.01,ARange(2)-dX*.01,ARange(2)-dX*.2,ARange(2)-dX*.2],...
                 [ARange(4)-dY*.1,ARange(4)-dY*.1,ARange(4)-dY*.01,ARange(4)-dY*.01,ARange(4)-dY*.1]-dY*.11,'k')
            text(ARange(2)-dX*.14,ARange(4)-dY*(.06+.11),'Sign')
            plot([x,x],[ARange(3),ARange(4)],'k--')
        end
    end
    disp(sprintf('Threshold is: [%g, %g]',Threshold,ThreshDir))
elseif Threshold=='default'
    Threshold=mean(Im_Filt(:))+std(Im_Filt(:))*3;
    ThreshDir=1;
    disp(sprintf('Threshold is: [%g, %g]',Threshold,ThreshDir))
end

ParticleOut=[];
h = waitbar(0,['Finding Particles ...']);
for FN=1:length(FIndex)-1
    try
    switch DiffType
        case 'Single'
            Im=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
                   ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(FN))]));
            Im=Im(:,:,1);   
        case 'Diff+'
            ImR=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
                   ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(FN))]));
            ImRP=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
                   ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(FN)+DiffNum)]));
            ImR=ImR(:,:,1);  
            ImRP=ImRP(:,:,1);  
            Im=ImR-ImRP;
        case 'Diff-'
            ImR=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
                   ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(FN))]));
            ImRM=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
                   ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(FN)-DiffNum)]));
            ImR=ImR(:,:,1);  
            ImRM=ImRM(:,:,1);  
            Im=ImR-ImRM;
        case 'Rolling'
            ImR=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
                   ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(FN))]));
            ImRP=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
                   ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(FN)+DiffNum)]));
            ImRM=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
                   ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(FN)-DiffNum)]));
            ImR=ImR(:,:,1);  
            ImRM=ImRM(:,:,1);  
            ImRP=ImRP(:,:,1);  
            Im=ImR-(ImRP+ImRM)/2;
    end
    catch err
        disp('Early Termination Reading Images!')
        disp(sprintf('Failed File Number: %g',FIndex(FN)))
        break
    end
    
    if ~strcmp(DiffType,'Single')
        Im0=max(cat(3,ImR,Im0),[],3);
        Im1=min(cat(3,ImR,Im1),[],3);
        ImM=ImM+ImR;
    else
        Im0=max(cat(3,Im,Im0),[],3);
        Im1=min(cat(3,Im,Im1),[],3);
        ImM=ImM+Im;
    end
   
    
    Im=Im-Backgrnd;
    
    if ~isempty(FilterParam);
        Im_Filt=imfilter(Im,h_noise-h_obj,'replicate');
        if ~strcmp(DiffType,'Single')
            ImR_Filt=imfilter(ImR,h_noise-h_obj,'replicate');
        end
        else
            Im_Filt=Im;
    end
    
    waitbar(FN/length(FIndex),h)
 
    Im0F=max(cat(3,Im_Filt,Im0F),[],3);
    Im1F=min(cat(3,Im_Filt,Im1F),[],3);
    ImMF=ImMF+Im_Filt;
    


    if ThreshDir<0
        Im_BW=Im_Filt<=Threshold;
    else
        Im_BW=Im_Filt>=Threshold;
    end

    Im_CC=bwconncomp(Im_BW);
    tempXY=regionprops(Im_CC,'PixelList','PixelIdxList','Area');

    ParticleOut(FN).X=arrayfun(@(x) sum(x.PixelList(:,1).*Im_Filt(x.PixelIdxList))/sum(Im_Filt(x.PixelIdxList)),tempXY).*ConvFactor;
    ParticleOut(FN).Y=arrayfun(@(x) sum(x.PixelList(:,2).*Im_Filt(x.PixelIdxList))/sum(Im_Filt(x.PixelIdxList)),tempXY).*ConvFactor;
    ParticleOut(FN).A=arrayfun(@(x) x.Area,tempXY).*ConvFactor^2;
    ParticleOut(FN).AvgInt=arrayfun(@(x) sum(Im_Filt(x.PixelIdxList)),tempXY);
    ParticleOut(FN).MaxInt=arrayfun(@(x) max(Im_Filt(x.PixelIdxList)),tempXY);
    if ~strcmp(DiffType,'Single')
        ParticleOut(FN).AvgIntRaw=arrayfun(@(x) sum(ImR_Filt(x.PixelIdxList)),tempXY);
        ParticleOut(FN).MaxIntRaw=arrayfun(@(x) max(ImR_Filt(x.PixelIdxList)),tempXY);
    end
    ParticleOut(FN).Frame=FIndex(FN);
    ParticleOut(FN).Conv=ConvFactor;
    ParticleOut(FN).FPS=Fps;

    if PlotFlag
        figure(2); imagesc(Im); daspect([1 1 1]); colormap('gray'); title('Raw Image')
        figure(3); imagesc(Im_Filt); daspect([1 1 1]); colormap('gray'); title('Filtered Image')
        figure(4); imagesc(Im_BW); daspect([1 1 1]); colormap('gray'); title('Thresholded Image')
        figure(2); hold on; plot(ParticleOut(FN).X,ParticleOut(FN).Y,'go');hold off
        figure(3); hold on; plot(ParticleOut(FN).X,ParticleOut(FN).Y,'go');hold off
        figure(4); hold on; plot(ParticleOut(FN).X,ParticleOut(FN).Y,'go');hold off
        drawnow
    end
end
close(h)

if nargout>1
    Img.MaxProj=Im0;
    Img.MaxProjProc=Im0F;
    Img.MinProj=Im1;
    Img.MinProjProc=Im1F;
    Img.Mean=ImM/length(FIndex);
    Img.MeanFilt=ImMF/length(FIndex);
end

mytime = toc;
disp(['Images Processed']);
disp(['  Number of Particles: ', num2str(sum(arrayfun(@(x) length(x.X),ParticleOut)))])
disp(['  Number of Frames: ', num2str(length(FIndex))])
disp(['  Elapsed Time: ', num2str(mytime), ' seconds'])
disp('  ')

