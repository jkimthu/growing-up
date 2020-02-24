function PlotTrackStats(PTracks)

AvgA=arrayfun(@(X) mean(X.Area),PTracks);
AvgI=arrayfun(@(X) mean(X.Intensity),PTracks);
TrL=arrayfun(@(X) length(X.X),PTracks);
TrF=arrayfun(@(X) X.Frame(1),PTracks);
MedV=arrayfun(@(X) median(sqrt(X.VelX.^2+X.VelY.^2)),PTracks);

figure(gcf)
set(gcf,'Position',[360 78 526 620])
clf
subplot(211)
scatter(AvgA,AvgI,TrL,TrF)
xlabel('Avg Area')
ylabel('Avg Intensity')
title('Size ~ Track Length, Color ~ Start Frame')

subplot(223)
scatter(AvgA,MedV,TrL,TrF)
xlabel('Avg Area')
ylabel('Avg Velocity')
% title('Color ~ Start Frame')
title('Size ~ Track Length, Color ~ Start Frame')

subplot(224)
scatter(TrL,MedV,12,TrF)
xlabel('Track Length')
ylabel('Avg Velocity')
title('Color ~ Start Frame')