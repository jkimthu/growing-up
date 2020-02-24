function TestData(Sz,V,L,Conv,FPS)

if isempty(Conv)
    Conv=1;
end
if isempty(FPS)
    FPS=1;
end

V=sort(V);

MaxDiff=V(end)/Conv/FPS;
SzP=Sz/Conv;
SzBuff=round(6*SzP);

D=zeros(round(SzBuff+sum((V(:)-V(1))/Conv/FPS*1.5+SzBuff)+MaxDiff),(ceil(MaxDiff))*(L+2),L);
[X,Y]=meshgrid(1:size(D,2),1:size(D,1));

for m=1:L
    mu=[SzBuff+(m-1)*V(:)/Conv/FPS,SzBuff/2+cumsum((V(:)-V(1))/Conv/FPS*1.5+SzBuff)];%[0:length(V)-1]'*(SzBuff+1.5*ceil(MaxDiff))];
    sig=eye(2)*SzP;
    Dt=1/(2*pi*sig(1,1)*sig(2,2))*exp(-1/2*((repmat(X(:),1,size(mu,1))-repmat(mu(:,1)',length(X(:)),1)).^2/sig(1,1)^2+(repmat(Y(:),1,size(mu,1))-repmat(mu(:,2)',length(Y(:)),1)).^2/sig(2,2)^2));
    D(:,:,m)=reshape(sum(Dt,2),size(D,1),[]);
end


figure(1)
imagesc(sum(D,3))

figure(2)
imagesc(D(:,:,2)-D(:,:,1))

% return
mkdir('TestData');
for m=1:L
imwrite(uint8(RescaleMatrix(D(:,:,m),1,2^8)),sprintf('./TestDAta/Im%03g.tif',m),'tiff')
end