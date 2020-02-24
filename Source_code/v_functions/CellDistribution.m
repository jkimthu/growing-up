function [X,Nx]=CellDistribution(P,Nbins,Axs)

% [X,Nx]=CellDistribution(P)
%       The input P is a structure of particles that have NOT been arranged
%       into tracks.
%       Returns the distribution of cell X position as a function of time.
%       The output X contains a vector of the center of the bins, and Nx is 
%       a matrix with a column for each frame, and each value in the column
%       representing the number of data points that fell into the 
%       corresponding bin. By default, 100 equally spaced bins are used.  
%       To generate another figure from this data, use the command 
%       "bar(X,Nx)". 
% [X,Nx]=CellDistribution(P,Nbins)
%       The optional input Nbins specifies the number of bins used in the
%       histogram. In addition, it can be replaced by a vector containing
%       the edges of the bins in order to provide more fine control.
% [X,Nx]=CellDistribution(P,Nbins,Axs)
%       The additional optional input Axs can be either string 'X' or 'Y'
%       and indicates which axis the distribution will be calculated over.
%       The default is 'X'.

if nargin<2
    Nbins=20;
    Axs='X';
elseif nargin<3
    Axs='X';
end

if strcmp(Axs,'Y')
    Mx=round(max(arrayfun(@(Q) max(Q.Y),P))); 
    Mn=round(min(arrayfun(@(Q) min(Q.Y),P))); 
    if length(Nbins)==1;
        edges=[Mn:(Mx-Mn)/(Nbins):Mx];
        X=(edges(1:end-1)+edges(2:end))/2;
    else
        edges=Nbins;
    end
    Nx=cell2mat(arrayfun(@(Q) histc(Q.Y,edges),P,'UniformOutput',0));
else
    Mx=round(max(arrayfun(@(Q) max(Q.X),P))); 
    Mn=round(min(arrayfun(@(Q) min(Q.X),P))); 
    if length(Nbins)==1;
        edges=[Mn:(Mx-Mn)/(Nbins):Mx];
        X=(edges(1:end-1)+edges(2:end))/2;
    else
        edges=Nbins;
    end
    Nx=cell2mat(arrayfun(@(Q) histc(Q.X,edges),P,'UniformOutput',0));
end
Nx(end,:)=[];
T=arrayfun(@(Q) max(Q.Frame),P)/P(1).FPS;

figure
imagesc(T,X,Nx);
xlabel('Time')
ylabel('Position across channel')
title('Cell Distribution Evolution')
colorbar
end