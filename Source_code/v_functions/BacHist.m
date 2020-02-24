function [Cntrs,D,Sn]=BacHist(PTA,PCntrs,Md)



N=length(PTA);

if iscell(PCntrs)
    Cntrs=PCntrs;
else
    mxX=max(arrayfun(@(X) max(X.X),PTA));
    mxY=max(arrayfun(@(X) max(X.Y),PTA));
%     [cX,cY]=meshgrid([0:mxX/(Param-1):mxX],[0:mxY/(Param-1):mxY]);
%     Cntrs{1}=cX(:)';
%     Cntrs{2}=cY(:)';
    Cntrs{1}=[0:mxX/(PCntrs-1):mxX];
    Cntrs{2}=[0:mxY/(PCntrs-1):mxY];
end
for i=1:2
    c = Cntrs{i};
    dc = diff(c);
    edges{i} = [c(1) c] + [-dc(1) dc dc(end)]/2;
    binwidth{i} = diff(edges{i});
    histcEdges{i} = [-Inf edges{i}(2:end-1) Inf];
end
D=cell(length(Cntrs{1}),length(Cntrs{2}),N);
Sn=zeros(length(Cntrs{1}),length(Cntrs{2}),N);
h = waitbar(0,['Finding Particles ...']);
for n=1:N
    if round(n/10)==n/10;
        waitbar(n/N,h)
    end
    X=PTA(n).X;
    X(:,2)=PTA(n).Y;
    bin = zeros(size(X,1),2);
    [dum,bin(:,1)] = histc(X(:,1),histcEdges{1});
    [dum,bin(:,2)] = histc(X(:,2),histcEdges{2});
    Sn(:,:,n) = accumarray(bin(all(bin>0,2),:),ones(size(X,1),1),[length(Cntrs{1}),length(Cntrs{2})],[],0);
    if strcmp(Md,'VelX')
        Dt = accumarray(bin(all(bin>0,2),:),PTA(n).VelX,[length(Cntrs{1}),length(Cntrs{2})],@(q) {q},{});
    elseif strcmp(Md,'VelY')
        Dt = accumarray(bin(all(bin>0,2),:),PTA(n).VelY,[length(Cntrs{1}),length(Cntrs{2})],@(q) {q},{});
    elseif strcmp(Md,'Vel')
        Dt = accumarray(bin(all(bin>0,2),:),sqrt(PTA(n).VelX.^2+PTA(n).VelY.^2),[length(Cntrs{1}),length(Cntrs{2})],@(q) {q},{});
    else
        Dt=cell(length(Cntrs{1}),length(Cntrs{2}));
    end
    D(:,:,n)=Dt;
    
%     if strcmp(Md,'Vel')
%         Dt = accumarray(bin(all(bin>0,2),:),sqrt(PTA(n).VelX.^2+PTA(n).VelY.^2),[length(Cntrs{1}),length(Cntrs{2})],[],NaN);
%     elseif strcmp(Md,'VelX')
%         Dt = accumarray(bin(all(bin>0,2),:),PTA(n).VelX,[length(Cntrs{1}),length(Cntrs{2})],[],NaN);
%     elseif strcmp(Md,'VelY')
%         Dt = accumarray(bin(all(bin>0,2),:),PTA(n).VelY,[length(Cntrs{1}),length(Cntrs{2})],[],NaN);
%     else
%         Dt=Sn(:,:,n);
%     end
%     D(:,:,n)=Dt;
end
close(h)

% Dmn=nansum(D,3)./nansum(Sn,3);
% Dmd=nanmedian(D,3);
% Dmn(sum(Sn,3)==0)=NaN;
% % figure(1)
% % imagesc(Dmn'); %caxis([0,500])
% figure(2)
% imagesc(Dmd'); %caxis([0,500])
% title('Median')
% figure(3)
% imagesc(sum(Sn,3)')
% title('Number of Particles')
