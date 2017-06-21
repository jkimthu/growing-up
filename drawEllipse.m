function [outline1, outline2] = drawEllipse(p, majorAxes, minorAxes, centroid_X, centroid_Y, conversionFactor)


% 0. isolate data from particles in current image
% 1. load major axes, min axes, centroids, angles
% 2. for all particles,
%           3. calculate points on ellipse centered at centroid
%           4. rotate ellipse
%           5. plot rotated ellipse
% 5. overlay onto current image

a = majorAxes(p)/2; % horizontal radius
b = minorAxes(p)/2; % vertical radius

t = -pi:0.01:pi;

outline1 = (centroid_X(p)+a*cos(t))/conversionFactor;
outline2 = (centroid_Y(p)+b*sin(t))/conversionFactor;

end

%%
% rotate
% R = rotz(angles(p)); % negative = counterclockwise rotation around z-axis
% 
% base = [x; y; zeros(1, length(y))];
% 
% rotated = R*base;
% 
% 
% hold on
% plot(rotated(1,:),rotated(2,:),'r','lineWidth',2)
% 
% 


