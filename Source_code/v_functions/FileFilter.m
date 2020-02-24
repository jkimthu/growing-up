function FileFilter(FileStruct,FileNumbers,FilterParam,Rng,PlotFlag)

if nargin<4
    Rng=[-50,500];
end
if nargin<5
    PlotFlag=0;
end

MxI=Rng(2);
MnI=Rng(1);

IPathName=[FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num),filesep];
[h_obj, h_noise] = FilterGen_V(FilterParam{1}(1), FilterParam{1}(2),FilterParam{1}(3), FilterParam{2});

mkdir(IPathName,'Filtered');
h = waitbar(0,['Filtering Files']);
for n=1:length(FileNumbers)
    if n/round(length(FileNumbers)/100)==round(n/round(length(FileNumbers)/100))
        waitbar(n/length(FileNumbers),h)
    end

    Im=double(imread([IPathName,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),FileNumbers(n))]));
    Im=Im(:,:,1);
    Im_Filt=imfilter(Im,h_noise-h_obj,'replicate');
    ImO=Im_Filt;
    ImO=(ImO-MnI)/(MxI-MnI)*2^8;
    if PlotFlag
        figure(1)
        imagesc(uint8(ImO)); colormap gray
    end
    imwrite(uint8(ImO),[IPathName,'Filtered\',sprintf('ImF_%04g',n),'.tif'],'tif')
end
close(h)