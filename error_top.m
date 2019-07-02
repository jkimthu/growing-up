% error_top

% goal: combine errors for an addition/subtraction step
%
%       error_top = sqrt( err_fluc^2 + err_ave^2 )


% last updated: jen, 2019 June 16
% commit: first commit, function to calculate error resulting from an addition or
%         subtraction calculation

% OK, let's go!

%%
function [err_top] = error_top(err_fluc,err_ave)

err_top = sqrt( err_fluc.^2 + err_ave^2 );

end