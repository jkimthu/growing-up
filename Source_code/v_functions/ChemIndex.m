function IC = ChemIndex(P,Im,Divd,Side,Axs,AvgN)

% IC=ChemIndex(P,Im,Divd)
%       The input P is a structure of particles that have NOT been arranged
%       into tracks. Im is the image structure returned from the particle 
%       tracking.  The input Divd denotes the location of the divide
%       between chemoattractang and non-chemoattractant regions.  Divd is a
%       number in the units of the particle locations (um if the conversion
%       factor was set correctly).  It is referenced from the left hand
%       side of the field of view, NOT the edge of the channel necessarily.
%       The function returns a vector of IC values, each element in the
%       vector represents the IC at the corresponding frame in P.
% IC=ChemIndex(P,Im,Divd,Side,Axs,Avg)
%       The additional optional input Side can be either string 'R' or 'L'
%       and indicates which side of the channel has the chemoattractant.
%       The default is 'R'.
%       The additional optional input Axs can be either string 'X' or 'Y'
%       and indicates which axis the distribution will be calculated over.
%       The default is 'X'.
%       The additional optional input Avg is the number of frames to
%       average over.  The resulting IC will still have the same number of
%       points. Must be an ODD number!


if nargin<4
    Side='R';
end
if nargin<5
    Axs='X';
end
if nargin<6
    AvgN=1;
end
if floor(AvgN/2)==AvgN/2
    AvgN=AvgN-1;
    disp(sprintf('Averaging term was even, and has been changed to %g',AvgN))
end

if strcmp(Axs,'Y')
    Mx=size(Im.Mean,1)*P(1).Conv; 
    Mn=P(1).Conv; 
    if strcmp(Side,'R')
        Nhot=arrayfun(@(Q) sum(Q.Y>=Divd),P)./(Mx-Divd);
        Ncool=arrayfun(@(Q) sum(Q.Y<Divd),P)./(Divd-Mn);
    else
        Nhot=arrayfun(@(Q) sum(Q.Y<=Divd),P)./(Divd-Mn);
        Ncool=arrayfun(@(Q) sum(Q.Y>Divd),P);
    end
else
    Mx=size(Im.Mean,2)*P(1).Conv; 
    Mn=P(1).Conv; 
    if strcmp(Side,'R')
        Nhot=arrayfun(@(Q) sum(Q.X>=Divd),P)./(Mx-Divd);
        Ncool=arrayfun(@(Q) sum(Q.X<Divd),P)./(Divd-Mn);
    else
        Nhot=arrayfun(@(Q) sum(Q.X<=Divd),P)./(Divd-Mn);
        Ncool=arrayfun(@(Q) sum(Q.X>Divd),P)./(Mx-Divd);
    end
end
IC=Nhot./Ncool-1;

IC=conv(IC,ones(AvgN,1)/AvgN,'same');
T=arrayfun(@(Q) max(Q.Frame),P)/P(1).FPS;
figure
plot(T,IC,'.-','LineWidth',2)
xlabel('Time')
ylabel('Chemotactic Index')

end