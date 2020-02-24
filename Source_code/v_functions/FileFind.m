function FileStruct=FileFind(PathName,FileName,Extension,FileString)

if nargin<3;Extension='*.*';end
if nargin<4;FileString='Choose the starting image';end

if nargin<2
    [FileName,PathName,FilterIndex]=uigetfile(Extension,FileString);
elseif or(isempty(PathName),isempty(FileName))
    [FileName,PathName,FilterIndex]=uigetfile(Extension,FileString);
end

%Annoying File Name Processing Stuff 
h=find(FileName=='.',1,'last');  
f=find(~isstrprop(FileName(1:h-1), 'digit'));
ImF.Base=FileName(1:f(end));
ImF.Num=str2num(FileName(f(end)+1:h-1));
ImF.Appnd=FileName(h:end);
ImF.Length=h-f(end)-1;
ImF.Full=FileName;

%Annoying Path Name Processing Stuff 
h=find(PathName==filesep);
ImP.Root=PathName(1:h(end-1));
FolderName=PathName(h(end-1)+1:h(end)-1);
f=find(~isstrprop(FolderName, 'digit'));
if ~isempty(f)
    if length(FolderName)==f(end);
        ImP.Base=FolderName;
        ImP.Num=[];
        ImP.Length=0;
    else
        ImP.Base=FolderName(1:f(end));
        ImP.Num=str2num(FolderName(f(end)+1:end));
        ImP.Length=length(FolderName)-f(end);
    end
else
    ImP.Base=[];
    ImP.Num=str2num(FolderName);
    ImP.Length=length(FolderName);
end
ImP.Full=PathName;

FileStruct.File=ImF;
FileStruct.Path=ImP;