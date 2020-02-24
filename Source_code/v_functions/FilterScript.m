% FileStruct = FileFind; 
FileNumbers = [1:1000];
FilterParam = FilterParameters;
IPathName=[FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num),'\'];

[h_obj, h_noise] = FilterGen_V(FilterParam{1}(1), FilterParam{1}(2),FilterParam{1}(3), FilterParam{2});

MxI=500;
MnI=-50;
mkdir(IPathName,'Filtered');
figure(1)
for n=1:length(FileNumbers)
    n
    Im=double(imread([IPathName,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FileNumbers(n))]));
    Im_Filt=imfilter(Im,h_noise-h_obj,'replicate');
    ImO=Im_Filt;
    ImO=(ImO-MnI)/(MxI-MnI)*2^8;
%     imagesc(uint8(ImO)); colormap gray
    imwrite(uint8(ImO),[IPathName,'Filtered\',sprintf('ImF_%04g',n),'.tif'],'tif')
end