function PTrim=ParticleTrim(P,field,LowerL,UpperL)

%TRIMMED = ParticleTrim(P,FIELD,LOWERL,UPPERL)
%   P - Structure of particles found in each frame, with different fields
%       describing characteristics
%   FIELD - A string corresponding to a field in the structure P which will
%           be used to restrict the particles
%   LOWERL - A numerical value indicating the lower bound for the specified
%            field name, use '-inf' to skip.
%   UPPERL - A numerical value indicating the upper bound for the specified
%            field name, use 'inf' to skip.
%
%   TRIMMED - The output is in the same structure array form as the input
%             structure P,  but with only the valid particles.


names=fieldnames(P(1));
names(strcmp(names,'Frame'))=[];
names(strcmp(names,'Conv'))=[];
names(strcmp(names,'FPS'))=[];
names(strcmp(names,'Time'))=[];
PTrim=P;
for n=1:length(P)
    D=getfield(P(n),field);
    f=find(and(D>LowerL,D<UpperL));
    for m=1:length(names)
        tempField=getfield(P(n),names{m});
        PTrim(n)=setfield(PTrim(n),names{m},tempField(f));
    end
end
