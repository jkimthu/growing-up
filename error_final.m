% error_final

% goal: combine errors for a multiplication or division step
%
%       error_final = ( (G_fluc - G_ave)/G_ave ) * sqrt( (error_top/(G_fluc - G_ave))^2 + (err_ave/G_ave)^2 )


% last updated: jen, 2019 June 30
% commit: first commit, function to calculate error resulting from an addition or
%         subtraction calculation

% OK, let's go!

%%
%function [err_final] = error_final(err_ave,error_top)

%error_final = ( (G_fluc - G_ave)/G_ave ) * sqrt( (error_top./(G_fluc - G_ave))^2 + (err_ave/G_ave)^2 );

%end
%%
function [err_final] = error_final(err_fluc,G_fluc,err_ave,G_ave)

err_final = ( (G_fluc - G_ave)./G_ave ) .* sqrt( ((error_top(err_fluc,err_ave))./(G_fluc - G_ave)).^2 + (err_ave/G_ave)^2 );

end

