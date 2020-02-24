function [V,VRaw]=AvgTrackVelocity(P,Lmin,Vmin)

%  V=AvgTrackVelocity(P_Tracks_Analysis)
%       Returns the average track velocity V for all tracks in
%       P_Tracks_Analysis.
%  V=AvgTrackVelocity(P_Tracks_Analysis,Lmin,Vmin)
%       Optional additional inputs are a minimum track length Lmin and a
%       minimum track velocity Vmin that are applied before calculating the
%       average track velocity V.
% [V,VRaw]=AvgTrackVelocity(P_Tracks_Analysis,Lmin,Vmin)
%       Optional additional output VRaw is a vector with the average
%       velocity for each individual track, subject to the constraints Lmin
%       and Vmin if specified.  To display a histogram of the track
%       velocities using VRaw, use the command "hist(VRaw,Nbins)" where
%       NBins is the number of bins to use in the histogram.

names=fieldnames(P(1));
if ~max(strcmp(names,'XFit'))
    error('Input must be ANALYZED Tracks in order to calculate velocity')
end

if nargin<2;
    Lmin=0;
    Vmin=0;
elseif nargin<3
    Vmin=0;
end


TrackLength=arrayfun(@(Q) length(Q.X),P); 
P(TrackLength<Lmin)=[];

TrackVel=arrayfun(@(Q) mean(sqrt(Q.VelX.^2+Q.VelY.^2)),P); 
P(TrackVel<Vmin)=[];
TrackVel(TrackVel<Vmin)=[];

V=mean(TrackVel);
if nargout>1
    VRaw=TrackVel;
end

figure
hist(TrackVel,100)
hold on
plot(V,0,'g*','MarkerSize',10)
plot(V,0,'go','MarkerSize',10)
xlabel('Velocity')
ylabel('Number of Tracks')
end
