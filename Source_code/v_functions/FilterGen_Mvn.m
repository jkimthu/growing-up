function [h_obj, h_noise, h_comb] = FilterGen_Mvn(h_obj, h_noisex, h_noisey, F_size)

% "h_obj"   = PxP matrix to be used as a filter; if set equal to a number,
%             h_obj is treated as diameter for a top hat filter;
%             'default'->11
% "h_noise" = diameter of noise response function (Gaussian); 'default'->1
% "F_size"  = size of the filters


if mod(F_size,2) == 0; F_size=F_size+1; end;

if or(or(F_size<2*h_noisex,all([F_size<2*h_obj,~isinf(h_obj)])),F_size<2*h_noisey)
    error('Filter size too small')
end
if or(h_obj<=h_noisex,h_obj<=h_noisey)
    error('Highpass cutoff must be larger than lowpass cutoff')
end

x = -(F_size-1)/2:(F_size-1)/2;
[xx,yy] = meshgrid(x,x);
rr = sqrt(xx.^2+yy.^2);


if isinf(h_obj)
    h_obj=zeros(F_size);
else
    h_obj=fspecial('Gaussian',F_size,h_obj);
    h_obj = h_obj/sum(h_obj(:));
end

h_noise=reshape(mvnpdf([xx(:),yy(:)],[0,0],[h_noisex,0;0,h_noisey]),size(xx,1),[]);
h_noise = h_noise/sum(h_noise(:));

h_comb=h_noise-h_obj;
H_comb=h_comb/sum(h_comb(:));
