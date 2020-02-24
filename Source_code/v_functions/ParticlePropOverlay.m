function ParticlePropOverlay(FileStruct,P,N,DiffInfo,PropField,FilterParam)

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
D=getfield(P(PN),PropField);

clf
if ~strcmp(DiffType,'Single')
    subplot(121)
    scatter(P(PN).X/P(1).Conv,P(PN).Y/P(1).Conv,RescaleMatrix(D,4,100),D);
    hold on
    imagesc(RescaleMatrix(ImR,max(D)+1,max(D)+1+(max(D)-min(D))))
    scatter(P(PN).X/P(1).Conv,P(PN).Y/P(1).Conv,RescaleMatrix(D,4,100),D);
    colormap([jet(64);gray(64)])
    axis tight
    H1=colorbar;
    set(H1,'YLim',[min(D),max(D)])
    title(['Filtered Image, property: ',PropField])


    subplot(122)
end
scatter(P(PN).X/P(1).Conv,P(PN).Y/P(1).Conv,RescaleMatrix(D,4,100),D);
hold on
imagesc(RescaleMatrix(Im_Filt,max(D)+1,max(D)+1+(max(D)-min(D))))
scatter(P(PN).X/P(1).Conv,P(PN).Y/P(1).Conv,RescaleMatrix(D,4,100),D);
colormap([jet(64);gray(64)])
axis tight
H2=colorbar;
set(H2,'YLim',[min(D),max(D)])
title([DiffType,' Image, property: ',PropField])


drawnow
