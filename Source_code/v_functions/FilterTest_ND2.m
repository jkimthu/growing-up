function FilterTest_ND2(reader,FileNumber,FilterParam,BackIm)

Im=double(bfGetPlane(reader, FileNumber(1)));
Im=Im(:,:,1);
           
if nargin<4
    BackIm=zeros(size(Im(:,:,1)));
end
Im=Im-BackIm;
           
[h_obj, h_noise] = FilterGen_V(FilterParam{1}(1), FilterParam{1}(2),FilterParam{1}(3), FilterParam{2});
Im_Filt=imfilter(Im,h_noise-h_obj,'replicate');

figure('Position',[84,340,836,358])
clf
h1=subplot(121);
imagesc(Im)
colormap gray
axis image
axis off
title('Original')
h2=subplot(122);
imagesc(Im_Filt)
colormap gray
axis image
axis off
linkaxes([h1,h2],'xy')
title(sprintf('%g, %g, %g   %s',FilterParam{1}(1), FilterParam{1}(2),FilterParam{1}(3), FilterParam{2}))