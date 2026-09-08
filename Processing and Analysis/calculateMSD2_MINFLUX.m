function R_sq = calculateMSD2_MINFLUX(tracks,maxframeDisp,minPts)

%Calculates the mean-squared displacement curve for individual tracks.
%frameTime is the interval between time-points. Optionally the maximum
%number of frame displacements can be specified (Default is 100).
if nargin == 1
    maxframeDisp = 100;
    minPts = 10;
elseif nargin == 2
    minPts = 10;
end


trkIDs = unique(tracks(:,4));
r_sq = zeros(length(trkIDs),2);

for i = 1:length(trkIDs)

    curTrack = tracks(tracks(:,4) == trkIDs(i),:);
    curTrack(:,1:2) = 1e6*curTrack(:,1:2);
    
    dt_all = diff(curTrack(:,3));
    dt = min(dt_all);

    segment_length = maxframeDisp.*dt;

    if size(curTrack,1) >= minPts
        [lags,msd,num_lag_tracks] = msdcalc_new(tracks,segment_length);
        msd = [lags(:),msd(:)];
        if size(msd,1) > maxframeDisp
            msd = msd(1:maxframeDisp,:);
        end

        [D,~, D_CI, ~, D_fit, Rc_fit] = fitMSD_Rc(msd(:,1),msd(:,2),[2 5]);
        if abs(D_CI/D) < 1.0 && D > 0
            r_sq(i,:) = [D/4, D_CI/4];
        end
    end
end

R_sq = r_sq(r_sq(:,1) > 0 & r_sq(:,2) > 0,:);