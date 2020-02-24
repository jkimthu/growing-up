function FilterTest(FileStruct,FileNumber,FilterParam,BackIm)

Im=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FileNumber(1))]));
Im=Im(:,:,1);
           
if nargin<4
    BackIm=zeros(size(Im(:,:,1)));
end
Im=Im-BackIm;
           
[h_obj, h_noise] = FilterGen_V(FilterParam{1}(1), FilterParam{1}(2),FilterParam{1}(3), FilterParam{2});
Im_Filt=imfilter(Im,h_noise-h_obj,'replicate');

figure('Position',[84,340,836,358])
clf
subplot(121)
imagesc(Im)
colormap gray
axis image
axis off
title('Original')
subplot(122)
imagesc(Im_Filt)
colormap gray
axis image
axis off
title(sprintf('%g, %g, %g   %s',FilterParam{1}(1), FilterParam{1}(2),FilterParam{1}(3), FilterParam{2}))