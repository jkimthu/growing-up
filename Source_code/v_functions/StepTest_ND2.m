function StepTest_ND2(reader,FileNumber,Rng,FilterParam)

if nargin<4
    FilterParam={[Inf,0,5],'gaussian'};
end
[h_obj, h_noise] = FilterGen_V(FilterParam{1}(1), FilterParam{1}(2),FilterParam{1}(3), FilterParam{2});
Im=double(bfGetPlane(reader, FileNumber(1)));
Im0=imfilter(Im(:,:,1),h_noise-h_obj,'replicate');

figure
clf
h=subplot(2,ceil((length(Rng)+1)/2),1);
imagesc(Im0)
colormap gray
axis image
axis off
title('Base Image')
for n=1:length(Rng)
h(n+1)=subplot(2,ceil((length(Rng)+1)/2),n+1);
Im=double(bfGetPlane(reader, FileNumber(1)+Rng(n)));
Im=imfilter(Im(:,:,1),h_noise-h_obj,'replicate');
imagesc(Im0-Im)
colormap gray
axis image
axis off
title(sprintf('Base-%g',Rng(n)))
end
linkaxes(h,'xy')    