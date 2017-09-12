% buildDM
% adapted from matrixBuilder, but prevents need to save data matrices.
% ideal for smaller inputs that take less time to process.

% last updated: jen, 2017-06-23

function [dm] = buildDM(D7,T)

% initialize all values
condVals = [];

trackNumber = [];                                                      

Time = [];

x_pos = [];
y_pos = [];
orig_frame = [];
stage_num = [];  % col 31
eccentricity = [];
angle = [];

lengthVals = [];
widthVals = [];
vcVals = [];
veVals = [];
vaVals = [];

muVals = [];
mu_vcVals = [];
mu_veVals = [];
mu_vaVals = [];

isDrop = []; 
dropThreshold = -0.75;                                                     % consider greater negatives a division event

curveFinder = [];                                                        

timeSinceBirth = [];
lengthAdded_incremental_sinceBirth = [];
vcAdded_incremental_sinceBirth = [];
veAdded_incremental_sinceBirth = [];
vaAdded_incremental_sinceBirth = [];

allDurations = [];
allDeltas = [];
allTimestamps = [];

birthSizes = [];
birthTimes = [];

curveDurations = [];
addedLength = [];
addedVC = [];
addedVE = [];
addedVA = [];

addedLength_incremental = [];
addedVC_incremental = [];
addedVE_incremental = [];
addedVA_incremental = [];


% Select xy positions for analysis / concatenation

for n = 1:length(D7)
     
    for m = 1:length(D7{n})                                                
        
        %   TRACK #                                                        
        lengthCurrentTrack = length(D7{n}(m).TrackID);
        Track = D7{n}(m).TrackID;
        trackNumber = [trackNumber; Track];
        
        
        %   frame number in original image
        frameTrack = D7{n}(m).Frame;%(7:lengthCurrentTrack+6);
        orig_frame = [orig_frame; frameTrack];
        
        
        %   TIME
        %timeTrack = T(3:lengthCurrentTrack+2,n)/(60*60);                  % collect timestamp (hr)
        timeTrack = T{n}(frameTrack(1):lengthCurrentTrack+frameTrack(1)-1);%(7:lengthCurrentTrack+6)./(3600);                  % data format, if all ND2s were processed individually
        Time = [Time; timeTrack];                                          % concat=enate timestamp
        
        
        
        %   lengths
        lengthTrack = D7{n}(m).MajAx;%(7:lengthCurrentTrack+6);              % collect lengths (um)
        lengthVals = [lengthVals; lengthTrack];                            % concatenate lengths
        dLengths = diff(lengthTrack);
        dLengths = [0; dLengths];
        addedLength_incremental = [addedLength_incremental; dLengths];
        
        
        %   widths
        widthTrack = D7{n}(m).MinAx;%(7:lengthCurrentTrack+6);               % collect widths (um)
        widthVals = [widthVals; widthTrack];                               % concatenate widths
        
        
        %   x positions in original image
        xTrack = D7{n}(m).X;%(7:lengthCurrentTrack+6); 
        x_pos = [x_pos; xTrack];
        
        
        %   y positions in original image
        yTrack = D7{n}(m).Y;%(7:lengthCurrentTrack+6);
        y_pos = [y_pos; yTrack];
        
        
        %   trim stage in dataTrimmer
        trimTrack = ones(length(Track),1)*n;
        stage_num = [stage_num; trimTrack];
        
        
        %   eccentricity of ellipses used in particle tracking
        eccTrack = D7{n}(m).Ecc;%(7:lengthCurrentTrack+6);
        eccentricity = [eccentricity; eccTrack];
        
        
        %   angle of ellipses used in particle tracking
        angTrack = D7{n}(m).Ang;%(7:lengthCurrentTrack+6);
        angle = [angle; angTrack];
         
                                                                           
        %   CONDITION
        % assign condition based on xy number
        condition = ceil(n/10);
        
        % label each row with a condition #
        condTrack = ones(lengthCurrentTrack,1)*condition;
        condVals = [condVals; condTrack];
        
        
    end % for m
    
    disp(['Tracks (', num2str(m), ') assembled from movie (', num2str(n), ') !'])
    
    
end % for n


% fill in NaN for all non-present data
vcVals = NaN(length(angle),1);
veVals = NaN(length(angle),1);
vaVals = NaN(length(angle),1);

muVals = NaN(length(angle),1);
mu_vcVals = NaN(length(angle),1);
mu_veVals = NaN(length(angle),1);
mu_vaVals = NaN(length(angle),1);

isDrop = NaN(length(angle),1);  
curveFinder = NaN(length(angle),1);                                                      

timeSinceBirth = NaN(length(angle),1);
lengthAdded_incremental_sinceBirth = NaN(length(angle),1);
vcAdded_incremental_sinceBirth = NaN(length(angle),1);
veAdded_incremental_sinceBirth = NaN(length(angle),1);
vaAdded_incremental_sinceBirth = NaN(length(angle),1);

allDurations = NaN(length(angle),1);
allDeltas = NaN(length(angle),1);
allTimestamps = NaN(length(angle),1);

birthSizes = NaN(length(angle),1);
birthTimes = NaN(length(angle),1);

curveDurations = NaN(length(angle),1);
addedLength = NaN(length(angle),1);
addedVC = NaN(length(angle),1);
addedVE = NaN(length(angle),1);
addedVA = NaN(length(angle),1);

addedLength_incremental = NaN(length(angle),1);
addedVC_incremental = NaN(length(angle),1);
addedVE_incremental = NaN(length(angle),1);
addedVA_incremental = NaN(length(angle),1);

ccFraction = NaN(length(angle),1);


% Compile data into single matrix
dm = [trackNumber Time lengthVals muVals isDrop curveFinder timeSinceBirth curveDurations ccFraction lengthAdded_incremental_sinceBirth addedLength widthVals vcVals veVals vaVals mu_vcVals mu_veVals mu_vaVals vcAdded_incremental_sinceBirth veAdded_incremental_sinceBirth vaAdded_incremental_sinceBirth addedVC addedVE addedVA addedVC_incremental addedVE_incremental addedVA_incremental x_pos y_pos orig_frame stage_num eccentricity angle condVals];
% 1. track Number
% 2. Time
% 3. lengthVals
% 4. muVals
% 5. isDrop
% 6. curveFinder
% 7. timeSinceBirth
% 8. curveDurations
% 9. ccFraction 
% 10. lengthAdded_incremental_sinceBirth
% 11. addedLength
% 12. widthVals
% 13. vcVals
% 14. veVals
% 15. vaVals
% 16. mu_vcVals
% 17. mu_veVals
% 18. mu_vaVals
% 19. vcAdded_incremental_sinceBirth
% 20. veAdded_incremental_sinceBirth
% 21. vaAdded_incremental_sinceBirth
% 22. addedVC
% 23. addedVE
% 24. addedVA
% 25. addedVC_incremental
% 26. addedVE_incremental
% 27. addedVA_incremental
% 28. x_pos
% 29. y_pos
% 30. orig_frame
% 31. stage_num
% 32. eccentricity
% 33. angle
% 34. condVals


end