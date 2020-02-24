    function ParticleTrimOverlay(FileStruct,P,N,TrimField,LowerBound,UpperBound,DiffInfo,FilterParam)

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

switch DiffType
    case 'Single'
        Im=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),N(1))]));
        Im=Im(:,:,1);   
    case 'Diff+'
        ImR=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),N(1))]));
        ImRP=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),N(1)+DiffNum)]));
        ImR=ImR(:,:,1);  
        ImRP=ImRP(:,:,1);  
        Im=ImR-ImRP;
    case 'Diff-'
        ImR=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),N(1))]));
        ImRM=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),N(1)-DiffNum)]));
        ImR=ImR(:,:,1);  
        ImRM=ImRM(:,:,1);  
        Im=ImR-ImRM;
    case 'Rolling'
        ImR=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),N(1))]));
        ImRP=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),N(1)+DiffNum)]));
        ImRM=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),N(1)-DiffNum)]));
        ImR=ImR(:,:,1);  
        ImRM=ImRM(:,:,1);  
        ImRP=ImRP(:,:,1);  
        Im=ImR-(ImRP+ImRM)/2;
end
           
[h_obj, h_noise] = FilterGen_V(FilterParam{1}(1), FilterParam{1}(2),FilterParam{1}(3), FilterParam{2});
Im_Filt=imfilter(Im,h_noise-h_obj,'replicate');

PN=find([P.Frame]==N(1));
D=getfield(P(PN),TrimField);


clf
if ~strcmp(DiffType,'Single')
    subplot(121)
    imagesc(imfilter(ImR,h_noise-h_obj,'replicate'))
    colormap gray
    hold on
    f=find(D<LowerBound);
    plot(P(PN).X(f)/P(1).Conv,P(PN).Y(f)/P(1).Conv,'bo');
    f=find(D>UpperBound);
    plot(P(PN).X(f)/P(1).Conv,P(PN).Y(f)/P(1).Conv,'ro');
    f=find(and(D>=LowerBound,D<=UpperBound));
    plot(P(PN).X(f)/P(1).Conv,P(PN).Y(f)/P(1).Conv,'go');
    title(['Filtered Image, Trim Overlay'])

    subplot(122)
end
imagesc(Im_Filt)
colormap gray
hold on
f=find(D<LowerBound);
plot(P(PN).X(f)/P(1).Conv,P(PN).Y(f)/P(1).Conv,'bo');
f=find(D>UpperBound);
plot(P(PN).X(f)/P(1).Conv,P(PN).Y(f)/P(1).Conv,'ro');
f=find(and(D>=LowerBound,D<=UpperBound));
plot(P(PN).X(f)/P(1).Conv,P(PN).Y(f)/P(1).Conv,'go');
title([DiffType,' Image, Trim Overlay'])