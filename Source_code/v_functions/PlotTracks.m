function PlotTracks(P)

figure(gcf)
clf
plot(P(1).X,P(1).Y,'-k')
hold on
for n=2:length(P)
    plot(P(n).X,P(n).Y,'.-k')
end

if isfield(P,'XFit')
    X=cell2mat(arrayfun(@(X) X.XFit,P,'UniformOutput',0));
    Y=cell2mat(arrayfun(@(X) X.YFit,P,'UniformOutput',0));
    VX=cell2mat(arrayfun(@(X) X.VelX,P,'UniformOutput',0));
    VY=cell2mat(arrayfun(@(X) X.VelY,P,'UniformOutput',0));
    if length(X)>12000;
        warning('Too many points to plot velocity')
        return
    end
    scatter(X,Y,6,sqrt(VX.^2+VY.^2),'filled')
end
axis equal