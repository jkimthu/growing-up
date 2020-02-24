function [ParticleOut,Img]=Particle_Centroid_ND2(reader,FilterParam,Threshold,FIndex,Backgrnd,DiffInfo,ConvFactor,PlotFlag)

DtaLngth = reader.getImageCount();
T = ND2ReaderT(reader);

% if number of arguments in function...
if nargin<9; PlotFlag=0; end
if nargin<8; Fps=1; end
if nargin<7; ConvFactor=1; end
if nargin<6; DiffType='Single';DiffNum=1; end
if nargin<5; Backgrnd=[]; end
if nargin<4; FIndex=[]; end
if nargin<3; Threshold=[]; end
if nargin<2; FilterParam=[]; end
if nargin<1; FileStruct=[]; end


% [] for GUI, make array with second value +/- 1 to indicate direction of threshold, default positive.
% The second number gives the separation between images
if length(Threshold)==2      % this is given once threshold is determined
    ThreshDir=Threshold(2);
    Threshold=Threshold(1);
elseif length(Threshold)==1
    ThreshDir=1;
end

% input FIndex = [];
% count number of images in sequence within reader
if isempty(FIndex)
    FIndex=1:DtaLngth;
end

% input FilterParameters = {[10,.8,40],'gaussian'};
if ~isempty(FilterParam)
    [h_obj, h_noise] = FilterGen_V(FilterParam{1}(1), FilterParam{1}(2),FilterParam{1}(3), FilterParam{2});
    % "h_obj"   = PxP matrix to be used as a filter; if set equal to a number,
    %             h_obj is treated as diameter for a top hat filter;
    %             'default'->11
    % "h_noise" = diameter of noise response function (Gaussian); 'default'->1
else
    h_obj=1;
    h_noise=0;
end

% input is the number of um per pixel (accounting for magnification)
if isempty(ConvFactor)
    ConvFactor=1;
end


% input ImType = DiffInfo = {'Single'};
% This sets the type of image being used.  Options are:
% 'Single' - Processes individual images corresponding to the numbers in FileNumbers
if isempty(DiffInfo)
    DiffType='Single';
else
    if length(DiffInfo)==2
        DiffType=DiffInfo{1};
        DiffNum=DiffInfo{2};
    else                        % we use this case v
        DiffType=DiffInfo{1};
        DiffNum=0;
    end
end

tic %start stopwatch timer
if FIndex(end)-FIndex(1)<DiffNum
    error('File number range is smaller than difference length')
elseif  and(FIndex(end)-FIndex(1)<2*DiffNum+1,strcmp(DiffType,'Rolling'))
    error('File number range is smaller than difference length')
end

if strcmp(DiffType,'Rolling')
    FIndex(FIndex<=DiffNum)=[];
    FIndex(FIndex>DtaLngth-DiffNum)=[];
elseif strcmp(DiffType,'Diff+')
    FIndex(FIndex>DtaLngth-DiffNum)=[];
elseif strcmp(DiffType,'Diff-')
    FIndex(FIndex<=DiffNum)=[];
end

% our case reading from ND2s is 'Single'
switch DiffType
    case 'Single'
        Im=double(bfGetPlane(reader, FIndex(1))); % this case
        % I = bfGetPlane(r, 1) % First plane of the series
        % I = bfGetPlane(r, r.getImageCount()) % Last plane of the series
    case 'Diff+'
        ImR=double(bfGetPlane(reader, FIndex(1)));
        ImRP=double(bfGetPlane(reader, FIndex(1)+DiffNum));
        ImR=ImR(:,:,1);  
        ImRP=ImRP(:,:,1);  
        Im=ImR-ImRP;
    case 'Diff-'
        ImR=double(bfGetPlane(reader, FIndex(1)+DiffNum));
        ImRM=double(bfGetPlane(reader, FIndex(1)));
        ImR=ImR(:,:,1);  
        ImRM=ImRM(:,:,1);  
        Im=ImR-ImRM;
    case 'Rolling'
        ImR =double(bfGetPlane(reader, FIndex(1)));
        ImRP=double(bfGetPlane(reader, FIndex(1)+DiffNum));
        ImRM=double(bfGetPlane(reader, FIndex(1)-DiffNum));
        ImR=ImR(:,:,1);  
        ImRM=ImRM(:,:,1);  
        ImRP=ImRP(:,:,1);  
        Im=ImR-(ImRP+ImRM)/2;
end

% compare strings. our DiffType is 'Single', so this should be true
if ~strcmp(DiffType,'Single')
    Im0=ImR;
    Im1=ImR;
    ImM=ImR;
else            % this case v
    Im0=Im;
    Im1=Im;
    ImM=Im;
end

% background is empty, true
if isempty(Backgrnd)
    Backgrnd=zeros(size(Im));
end
Im=Im-Backgrnd;



%Preparations to do outside of loop
Im_Filt=imfilter(Im,h_noise-h_obj,'replicate');
% B = imfilter(A,h) filters the multidimensional array A with the multidimensional filter h.

% imfilter computes each element of the output, B, using double-precision floating point.
% If A is an integer or logical array,
% imfilter truncates output elements that exceed the range of the given type,
% and rounds fractional values.

Im0F=Im_Filt;
Im1F=Im_Filt;
ImMF=Im_Filt;

% when Threshold = [], display GUI to determine Threshold
if isempty(Threshold) % not true when after initialized
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

% trackin particles once all is initialized
ParticleOut=[];
h = waitbar(0,['Finding Particles ...']);
for FN=1:length(FIndex) % for all images in sequence
    try
    switch DiffType
        case 'Single'
            Im=double(bfGetPlane(reader, FIndex(FN)));
        case 'Diff+'
            ImR=double(bfGetPlane(reader, FIndex(FN)));
            ImRP=double(bfGetPlane(reader, FIndex(FN)+DiffNum));
            ImR=ImR(:,:,1);  
            ImRP=ImRP(:,:,1);  
            Im=ImR-ImRP;
        case 'Diff-'
            ImR=double(bfGetPlane(reader, FIndex(FN)));
            ImRM=double(bfGetPlane(reader, FIndex(FN)-DiffNum));
            ImR=ImR(:,:,1);  
            ImRM=ImRM(:,:,1);  
            Im=ImR-ImRM;
        case 'Rolling'
            ImR =double(bfGetPlane(reader, FIndex(FN)));
            ImRP=double(bfGetPlane(reader, FIndex(FN)+DiffNum));
            ImRM=double(bfGetPlane(reader, FIndex(FN)-DiffNum));
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
    
    % we use DiffType = Single
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
    
    % Not empty!
    if ~isempty(FilterParam);
        Im_Filt=imfilter(Im,h_noise-h_obj,'replicate');
        if ~strcmp(DiffType,'Single')
            ImR_Filt=imfilter(ImR,h_noise-h_obj,'replicate');
        end
        else
            Im_Filt=Im; % if empty, no filter applied
    end
    
    waitbar(FN/length(FIndex),h)
 
    Im0F=max(cat(3,Im_Filt,Im0F),[],3);
    Im1F=min(cat(3,Im_Filt,Im1F),[],3);
    ImMF=ImMF+Im_Filt;
    

    % apply Threshold, taking direction into account
    if ThreshDir<0
        Im_BW=Im_Filt<=Threshold;
    else
        Im_BW=Im_Filt>=Threshold;
    end

    Im_CC=bwconncomp(Im_BW);
    tempXY=regionprops(Im_CC,'PixelList','PixelIdxList','Area','Eccentricity','MajorAxisLength','MinorAxisLength','Orientation');

    ParticleOut(FN).X=arrayfun(@(x) sum(x.PixelList(:,1).*Im_Filt(x.PixelIdxList))/sum(Im_Filt(x.PixelIdxList)),tempXY).*ConvFactor;
    ParticleOut(FN).Y=arrayfun(@(x) sum(x.PixelList(:,2).*Im_Filt(x.PixelIdxList))/sum(Im_Filt(x.PixelIdxList)),tempXY).*ConvFactor;
    ParticleOut(FN).A=arrayfun(@(x) x.Area,tempXY).*ConvFactor^2;
    ParticleOut(FN).AvgInt=arrayfun(@(x) sum(Im_Filt(x.PixelIdxList)),tempXY);
    ParticleOut(FN).MaxInt=arrayfun(@(x) max(Im_Filt(x.PixelIdxList)),tempXY);
    ParticleOut(FN).Ecc=arrayfun(@(x) x.Eccentricity,tempXY);
    ParticleOut(FN).MajAx=arrayfun(@(x) x.MajorAxisLength,tempXY).*ConvFactor;
    ParticleOut(FN).MinAx=arrayfun(@(x) x.MinorAxisLength,tempXY).*ConvFactor;
    ParticleOut(FN).Ang=arrayfun(@(x) x.Orientation,tempXY);
    if ~strcmp(DiffType,'Single')
        ParticleOut(FN).AvgIntRaw=arrayfun(@(x) sum(ImR_Filt(x.PixelIdxList)),tempXY);
        ParticleOut(FN).MaxIntRaw=arrayfun(@(x) max(ImR_Filt(x.PixelIdxList)),tempXY);
    end
    ParticleOut(FN).Frame=FIndex(FN);
    ParticleOut(FN).Conv=ConvFactor;
    ParticleOut(FN).Time=T(FN);

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

