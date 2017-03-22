%% length and width over time

% for SNSF proposal

n = 1;
counter = 0;

for m = 15;
    
    counter = counter + 1;

    % Original length data (microns)
    lengthTrack = D6{n}(m).MajAx;
    
    % Original width data (microns)
    widthTrack = D6{n}(m).MinAx;
    
    % Original time data converted to hours
    timeTrack = T{n}/(3600);
    
    
    smoothedL = smooth(lengthTrack);
    smoothedW = smooth(widthTrack);
    
    
    figure(4)
    
    %subplot(5,1,counter)
    %plot(timeTrack(1:length(lengthTrack)), lengthTrack, timeTrack(1:length(widthTrack)), widthTrack, 'r');
    plot(timeTrack(1:length(smoothedL)), smoothedL, timeTrack(1:length(smoothedW)), smoothedW);
    grid on;
    axis([0,9,-0.5,5])
    xlabel('Time (hours)')
    ylabel('Microns')
    legend('Length','Width');
    
    
    clear Mu_track Num_mu Ltrack2 Ttrack hr;

end