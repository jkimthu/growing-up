function TestTrack(FileStruct,PTA,FPS,Conv,FilterParam,cxRng,axRng)

tic
names=fieldnames(PTA(1));
if nargin<4
    FilterParam=[];
end
if nargin<5
    cxRng=[];
end
if nargin<6
    axRng=[];
end



H=figure('Position',[115 136 1005 812]);
TrackNum=[];
for n=1:length(PTA)-1
    figure(H)
    clf
    Im=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
               ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),PTA(n).Frame(1))]));
    Im=Im(:,:,1);
    if ~isempty(FilterParam)
        [h_obj, h_noise] = FilterGen_V(FilterParam{1}(1), FilterParam{1}(2),FilterParam{1}(3), FilterParam{2});
        Im=imfilter(Im,h_noise-h_obj,'replicate');
    end
    imagesc([1:size(Im,2)]*Conv,[1:size(Im,1)]*Conv,Im); colormap gray
    hold on
    if strcmp(names,'TrackID')
        NewTrack=~ismember(PTA(n).TrackID,TrackNum);
        EndTrack=~ismember(PTA(n).TrackID,PTA(n+1).TrackID);
        plot(PTA(n).XFit,PTA(n).YFit,'bo')
        plot(PTA(n).XFit(NewTrack),PTA(n).YFit(NewTrack),'g*')
        plot(PTA(n).XFit(EndTrack),PTA(n).YFit(EndTrack),'rx')
        TrackNum=[TrackNum;PTA(n).TrackID(NewTrack)];
    else
        plot(PTA(n).X,PTA(n).Y,'bo')
    end
    if ~isempty(cxRng)
        caxis(cxRng)
    end
    if ~isempty(axRng)
        axis(axRng)
    end
    title(sprintf('Frame %g',PTA(n).Frame))
    drawnow
    pause(.5);
end
toc