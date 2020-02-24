function P=ParticleTracks2Time(P0)

Fmin=min(arrayfun(@(Q) min(Q.Frame),P0));
Fmax=max(arrayfun(@(Q) max(Q.Frame),P0));
FRange=[Fmin:Fmax];

names=fieldnames(P0(1));
names0=names;
names(strcmp(names,'Frame'))=[];
names(strcmp(names,'Fit'))=[];
names(strcmp(names,'FPS'))=[];
names(strcmp(names,'Conv'))=[];

tic

h = waitbar(0,['Converting ...']);
FrameField=cell2mat(arrayfun(@(Q) Q.Frame,P0,'UniformOutput',0));
P=[];

for m=1:length(names)
    waitbar(m/length(names),h)
    TempField=cell2mat(arrayfun(@(Q) getfield(Q,names{m}),P0,'UniformOutput',0));
    for n=1:length(FRange);
        CellTemp{m,n}=TempField(FrameField==FRange(n));
    end
end
CellTemp(m+1,1:length(FRange))=num2cell(FRange);
names{length(names)+1}='Frame';

% Reintroduce single valued fields
if max(strcmp(names0,'Fit'))
    CellTemp(length(names)+1,1:length(FRange))=num2cell(ones(size(FRange))*P0(1).Fit);
    names{length(names)+1}='Fit';
end

if max(strcmp(names0,'FPS'))
    CellTemp(length(names)+1,1:length(FRange))=num2cell(ones(size(FRange))*P0(1).FPS);
    names{length(names)+1}='FPS';
end

if max(strcmp(names0,'Conv'))
    CellTemp(length(names)+1,1:length(FRange))=num2cell(ones(size(FRange))*P0(1).Conv);
    names{length(names)+1}='Conv';
end

P=cell2struct(CellTemp,names,1);
close(h)
    

% informational
mytime = toc;
disp(['Elapsed Time: ', num2str(mytime), ' seconds'])
disp('  ')