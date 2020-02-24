%% getGrowthParameter

% goal: extracts desired parameter from data matrix assembled by buildDM.
%       this function is handy, as edits to buildDM only need to be
%       reflected here (as opposed to all the scripts that use it)

% strategy: from list of parameters, ordered by column number, locate index
%           of parameter name of interest and output single column


% last updated: jen, 2019 Feb 5
% commit: edit such that 'time' does not return timestamp AND time since birth

% OK let's go!

%%
function [parameter] = getGrowthParameter(dm,parameterName)


parameter_dir = {'trackID','timestamp','length','isDrop','curveFinder','timeSinceBirth',...
    'curveDurations','ccFraction','addedLength','width','volume','surfaceArea',...
    'addedVA','x_pos','y_pos','frame','xy','eccentricity','angle','trackNum',...
    'condition','correctedTime'};

% 1. track ID, as assigned by ND2Proc_XY
% 2. Time (timestamp from T)
% 3. lengthVals
% 4. isDrop
% 5. curveFinder
% 6. timeSinceBirth
% 7. curveDurations
% 8. ccFraction
% 9. addedLength
% 10. widthVals
% 11. vaVals
% 12. surfaceArea
% 13. addedVA
% 14. x coordinate of centroid
% 15. y coordinate of centroid
% 16. orig_frame
% 17. stage_num (xy position on microscope)
% 18. eccentricity
% 19. angle of rotation of fit ellipse
% 20. trackNum  =  total track number (vs ID which is xy based)
% 21. condVals
% 22. correctedTime (trueTimes)

isColumn = strfind(parameter_dir,parameterName);
col = find(~cellfun(@isempty,isColumn));
parameter = dm(:,col);

end