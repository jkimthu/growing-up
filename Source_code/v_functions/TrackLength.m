function TL=TrackLength(P)

%  TL=TrackLength(P_Tracks)
%       Returns the track length for all tracks in P_Tracks or 
%       P_Tracks_Analysis.

TL=arrayfun(@(Q) length(Q.X),P); 
end
