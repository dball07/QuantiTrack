function [R_sq, tracks_used] = calculateMSD2(tracks,frameTime,maxframeDisp,minPts)

%Calculates the mean-squared displacement curve for individual tracks.
%frameTime is the interval between time-points. Optionally the maximum
%number of frame displacements can be specified (Default is 100).
if nargin == 2
    maxframeDisp = 100;
    minPts = 10;
elseif nargin == 3
    minPts = 10;
end

trkIDs = unique(tracks(:,4));
r_sq = zeros(length(trkIDs),2);
tracks_used = trkIDs;

for i = 1:length(trkIDs)

    curTrack = tracks(tracks(:,4) == trkIDs(i),:);
    if size(curTrack,1) >= minPts
%        tracks_used = [tracks_used; trkIDs(i)];
        %extract time, and space coordinates
        t = uint16(curTrack(:,3));
%         t = (t-t(1)).*frameTime;
        x = curTrack(:,1);
        y = curTrack(:,2);
    
        %Calculate the differences
        t1 = repmat(t',length(t),1);
        t2 = repmat(t,1,length(t));
    
        x1 = repmat(x',length(x),1);
        x2 = repmat(x,1,length(x));
    
        y1 = repmat(y',length(y),1);
        y2 = repmat(y,1,length(y));
    
    
        dt = tril((t2 - t1));
        dx = tril((x2 - x1));
        dy = tril((y2 - y1));
    
        dt = dt(:);
        dx = dx(:);
        dy = dy(:);
        dx1 = dx;
        dy1 = dy;
    
        dt((dx1 == 0 & dy1 == 0)) = [];
        dx((dx1 == 0 & dy1 == 0)) = [];
        dy((dx1 == 0 & dy1 == 0)) = [];
    
        dr2 = dx.^2 + dy.^2;
        dt_un = unique(dt);
        
        n_delays = length(dt_un);
        n_msd    = zeros(n_delays,1);
        mean_msd = zeros(n_delays,1);
        std_msd  = zeros(n_delays,1);
        binEdges = (dt_un(1) - 0.5):dt_un(end) + 0.5;
        [N,~,bin] = histcounts(dt,binEdges);
        for j = 1:max(bin)
            indices = (bin == j);
            N = sum(indices);
            [~, index_in_all_delays, ~] = intersect(dt_un, dt(indices));
            n_msd(index_in_all_delays) = n_msd(index_in_all_delays) + N;
            mean_msd(index_in_all_delays) = mean(dr2(indices));
            std_msd(index_in_all_delays) = std(dr2(indices));
        end
        
        msd = [frameTime.*double(dt_un(:)),mean_msd(:)];
        if size(msd,1) > maxframeDisp
            msd = msd(1:maxframeDisp,:);
        end
        
        [D,~, D_CI, ~, D_fit, Rc_fit] = fitMSD_Rc(msd(:,1),msd(:,2),[2 5]);
        % if abs(D_CI/D) < 1.0 && D > 0
        if D > 0
            r_sq(i,:) = [D/4, D_CI/4];
        end
    end
end
tracks_used = tracks_used(r_sq(:,1) > 0 & r_sq(:,2) > 0,:);
R_sq = r_sq(r_sq(:,1) > 0 & r_sq(:,2) > 0,:);

