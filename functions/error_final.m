% error_final

% goal: combine errors for a multiplication or division step
%
%       error_final = ( (G_fluc - G_ave)/G_ave ) * sqrt( (error_top/(G_fluc - G_ave))^2 + (err_ave/G_ave)^2 )


% last updated: jen, 2019 July 7
% commit: edit to accomodate more than single values of reference Gs

% OK, let's go!

%%
function [err_final] = error_final(err_fluc,G_fluc,err_ave,G_ave)

err_final = ( (G_fluc - G_ave)./G_ave ) .* sqrt( ((error_top(err_fluc,err_ave))./(G_fluc - G_ave)).^2 + (err_ave./G_ave).^2 );

end

