function PN=ParticleNum(P);

%  PN=ParticleNum(P)
%       Returns the number of particles for all frames in P

PN=arrayfun(@(Q) length(Q.X),P)';