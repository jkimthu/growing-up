function Img=ImgAnalysis(FileStruct,FilterParam,FIndex,Backgrnd,DiffInfo)

if nargin<5; DiffType='Single';DiffNum=1; end
if nargin<4; Backgrnd=[]; end
if nargin<3; FIndex=[]; end
if nargin<2; FilterParam=[]; end
if nargin<1; FileStruct=[]; end

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
    [h_obj, h_noise]=[1,0];
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
        FStart=FIndex(1);
        FEnd=FIndex(end);
    case 'Diff+'
        ImR=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(1))]));
        ImRP=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(1)+DiffNum)]));
        ImR=ImR(:,:,1);   
        ImRP=ImRP(:,:,1);  
        Im=ImR-ImRP;
        FStart=FIndex(1);
        FEnd=FIndex(end)-DiffNum;
    case 'Diff-'
        ImR=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(1)+DiffNum)]));
        ImRM=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FIndex(1))]));
        ImR=ImR(:,:,1);  
        ImRM=ImRM(:,:,1);  
        Im=ImR-ImRM;
        FStart=FIndex(1)+DiffNum;
        FEnd=FIndex(end);
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
        FStart=FIndex(1)+DiffNum;
        FEnd=FIndex(end)-DiffNum;
end

f=find(Im>2000);
Im(f)=2000;

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
end
close(h)


Img.MaxProj=Im0;
Img.MaxProjProc=Im0F;
Img.MinProj=Im1;
Img.MinProjProc=Im1F;
Img.Mean=ImM/length(FIndex);
Img.MeanFilt=ImMF/length(FIndex);


mytime = toc;
disp(['Images Processed']);
disp(['  Number of Frames: ', num2str(length(FIndex))])
disp(['  Elapsed Time: ', num2str(mytime), ' seconds'])
disp('  ')

