function T=ND2ReaderT(reader)
NSeries=reader.getSeriesCount();
FileN=reader.getImageCount();
ome=reader.getMetadataStore();
c=1;
for m=0:NSeries-1;
for n=1:FileN
T(c)=double(ome.getPlaneDeltaT(m,n-1));
c=c+1;
end
end

T=reshape(T,NSeries,[])';