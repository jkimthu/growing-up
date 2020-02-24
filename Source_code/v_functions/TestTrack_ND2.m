function TestTrack_ND2(reader,PTA,Conv,FilterParam,cxRng,axRng,P,Rec)

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
if nargin<7
    P=[];
end
if nargin<8
    Rec=0;
end



H=figure('Position',[115 136 1005 812]);
TrackNum=[];
for n=1:length(PTA)-1
    frame=PTA(n).Frame;
    figure(H)
    clf
    Im=double(bfGetPlane(reader, PTA(n).Frame(1)));
    Im=Im(:,:,1);
    if ~isempty(FilterParam)
        [h_obj, h_noise] = FilterGen_V(FilterParam{1}(1), FilterParam{1}(2),FilterParam{1}(3), FilterParam{2});
        Im=imfilter(Im,h_noise-h_obj,'replicate');
    end
    imagesc([1:size(Im,2)]*Conv,[1:size(Im,1)]*Conv,Im); colormap gray; axis image
    if ~isempty(cxRng)
        caxis(cxRng)
    end
    hold on
    if sum(strcmp(names,'TrackID'))
        NewTrack=~ismember(PTA(n).TrackID,TrackNum);
        EndTrack=~ismember(PTA(n).TrackID,PTA(n+1).TrackID);
%         plot(PTA(n).XFit,PTA(n).YFit,'bo','MarkerSize',10)
        DrawEllipse(PTA(n).MajAx*1.2, PTA(n).MinAx*1.2, PTA(n).Ang,PTA(n).XFit,PTA(n).YFit,'b')
        plot(PTA(n).XFit(NewTrack),PTA(n).YFit(NewTrack),'g.')
        plot(PTA(n).XFit(EndTrack),PTA(n).YFit(EndTrack),'r.')
        TrackNum=[TrackNum;PTA(n).TrackID(NewTrack)];
        if ~isempty(P)
            for m=1:length(P)
                f=find(and(P(m).Frame<frame,P(m).Frame>frame-25));
                plot(P(m).XFit(f),P(m).YFit(f),'y','LineWidth',2)
                if and(frame-max(P(m).Frame)>0,frame-max(P(m).Frame)<25)
                   plot(P(m).XFit(end),P(m).YFit(end),'r.','MarkerSize',4) 
                end
            end
        end
    else
        plot(PTA(n).X,PTA(n).Y,'bo','MarkerSize',10)
    end
    axis image
    axis off
    if ~isempty(axRng)
        axis(axRng)
    end

    
%     title(sprintf('Frame %g',PTA(n).Frame))
    drawnow
    pause(.1);
    if Rec
        export_fig(gcf,sprintf('Frame%03g',PTA(n).Frame),'-jpg','-q95','-r200')
    end
end
toc