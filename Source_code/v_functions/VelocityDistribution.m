function [V,Nv,VRaw]=VelocityDistribution(P,Nbins,Lmin,Vmin)

% [V,Nv]=VelocityDistribution(P_Tracks_Analysis)
%       Returns the distribution of velocity over all time and all tracks
%       in P_Tracks_Analysis.  The output V contains a vector of the center
%       of the bins, and Nv is a vector with each value representing the
%       number of data points that fell into the corresponding bin. By
%       default, 100 equally spaced bins are used.  To generate another
%       figure from this data, use the command "bar(V,Nv)".
% [V,Nv]=VelocityDistribution(P_Tracks_Analysis,Nbins)
%       The optional input Nbins specifies the number of bins used in the
%       histogram. In addition, it can be replaced by a vector containing
%       the edges of the bins in order to provide more fine control.
% [V,Nv]=VelocityDistribution(P_Tracks_Analysis,Nbins,Lmin,Vmin)
%       Optional additional inputs are a minimum track length Lmin and a
%       minimum track velocity Vmin that are applied before calculating the
%       velocity distribution.
% [V,Nv,VRaw]=VelocityDistribution(P_Tracks_Analysis,Nbins,Lmin,Vmin)
%       The optional additional output VRaw is a vector with every combined
%       velocity from each individual track, subject to the constraints Lmin
%       and Vmin if specified.  To display a histogram of the track
%       velocities using VRaw, use the command "hist(VRaw,Nbins)" where
%       NBins is the number of bins to use in the histogram.

names=fieldnames(P(1));
if ~max(strcmp(names,'XFit'))
    error('Input must be ANALYZED Tracks in order to calculate velocity')
end

if nargin<2;
    Nbins=100;
    Lmin=0;
    Vmin=0;
elseif nargin<3
    Lmin=0;
    Vmin=0;
elseif nargin<4
    Vmin=0;
end

TrackLength=arrayfun(@(Q) length(Q.X),P); 
P(TrackLength<Lmin)=[];

TrackVel=arrayfun(@(Q) mean(sqrt(Q.VelX.^2+Q.VelY.^2)),P); 
P(TrackVel<Vmin)=[];

Vtmp=arrayfun(@(Q) sqrt(Q.VelX.^2+Q.VelY.^2),P,'UniformOutput',0);
if size(Vtmp,2)==1
    VRaw=cell2mat(Vtmp);
else
    VRaw=cell2mat(Vtmp');
end
[Nv,V]=hist(VRaw,Nbins);
figure
hist(VRaw,Nbins);
xlabel('Instantaneous Velocity')
ylabel('Number of Instances')
title(['Data from ' sprintf('%g eligible tracks out of %g',length(P),length(TrackLength))])
end