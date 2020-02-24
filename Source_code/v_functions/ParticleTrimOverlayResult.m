function ParticleTrimOverlayResult(FileStruct,P,PT,N,DiffInfo,FilterParam)

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
        ImRP=ImRP(:,:,1);  
        ImRM=ImRM(:,:,1);
        Im=ImR-(ImRP+ImRM)/2;
end
          
           
[h_obj, h_noise] = FilterGen_V(FilterParam{1}(1), FilterParam{1}(2),FilterParam{1}(3), FilterParam{2});
Im_Filt=imfilter(Im,h_noise-h_obj,'replicate');
PN=find([P.Frame]==N(1));
clf
if ~strcmp(DiffType,'Single')
    subplot(121)
    imagesc(imfilter(ImR,h_noise-h_obj,'replicate'))
    colormap gray
    hold on
    plot(P(PN).X/P(1).Conv,P(PN).Y/P(1).Conv,'bo');
    plot(PT(PN).X/P(1).Conv,PT(PN).Y/P(1).Conv,'rx');
    title(['Filtered Image, Final Trim'])
    subplot(122)
end
imagesc(Im_Filt)
colormap gray
hold on
plot(P(PN).X/P(1).Conv,P(PN).Y/P(1).Conv,'bo');
plot(PT(PN).X/P(1).Conv,PT(PN).Y/P(1).Conv,'rx');
title([DiffType,' Image, Final Trim'])