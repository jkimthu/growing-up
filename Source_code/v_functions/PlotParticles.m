function PlotParticles(P)
NumP=arrayfun(@(X) length(X.A),P)';
Pf=find(cumsum(NumP)>1000000,1);
Pf=min([Pf,length(P)]);
P=P(1:Pf);

PArea=round(cell2mat(arrayfun(@(X) X.A,P,'UniformOutput',0)')/P(1).Conv^2);
PInt=cell2mat(arrayfun(@(X) X.AvgInt,P,'UniformOutput',0)');

edges=[min(PInt(:))-1:max((max(PInt(:))-min(PInt(:)))/500,1):max(PInt(:))+1];
bins=(edges(2:end)+edges(1:end-1))/2;
h = waitbar(0,['Sorting Particles ...']);
for n=1:max(PArea(:))
    waitbar(n/max(PArea(:)),h)
    fA=find(PArea==n);
    N(1:length(edges),n)=histc(PInt(fA),edges);
end
close (h);
N=N(1:end-1,:);

[fx,fy,Nv]=find(N');
[Nv,Indx]=sort(Nv,'ascend');
 
AreaX=[1:max(PArea(:))];
figure(gcf); clf; scatter(AreaX(fx(Indx))*P(1).Conv^2,bins(fy(Indx)),max(6,4*log(Nv)),log(Nv),'filled'); xlabel('Area (units^2)'); ylabel('Avg Intensity')
title(['Points from first ',num2str(Pf),' frames out of ', num2str(length(NumP)),', Log Number'])
drawnow
