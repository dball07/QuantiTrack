function [majorAxisLnm, minorAxisLnm, angle, eccentricity, Area, circD, nPts] = calcConfinementD_v2(tracks,minTrackPts)

%Gets stats for the spacial confinement of the tracks that have at least
%MINTRACKPTs points. Uses a resolution of RESOLUTION to estimate the
%distances

%Initialize the output variables
trkIDs = tracks(:,4);
nTrks = length(unique(trkIDs));

majorAxisLnm = zeros(nTrks,1);
minorAxisLnm = zeros(nTrks,1);
angle = zeros(nTrks,1);
eccentricity = zeros(nTrks,1);
Area = zeros(nTrks,1);
circD = zeros(nTrks,1);
nPts = zeros(nTrks,1);
trackIDs = unique(tracks(:,4));


for i = 1:length(trackIDs)
    curID = trackIDs(i);
    curTrk = tracks(tracks(:,4) == curID,1:2);
    curTrk = curTrk.*1e9;
    nPts(i) = size(curTrk,1);
    
    if size(curTrk,1) >= minTrackPts
        %get the convex hull and Area of the track points
        
        [k,Area(i)] = convhull(curTrk);
        
        XY_hull = curTrk(k(1:end-1),:);

        %get the covariance of the convex hull
        Sigma = cov(XY_hull);
        %find the major and minor axes with eigenvalues 
        [V, D] = eig(Sigma);
        
        a = sqrt(max(D(1,1),D(2,2)));
        b = sqrt(min(D(1,1),D(2,2)));
        majorAxisLnm(i) = 2*a;
        minorAxisLnm(i) = 2*b;
        if D(1,1) > D(2,2)
            angle(i) = atan2d(V(1,2),V(1,1));
        else
            angle(i) = atan2d(V(2,2),V(2,1));
        end
        if angle(i) > 90
            angle(i) = angle(i) - 180;
        end
        if angle(i) < -90
            angle(i) = angle(i) + 180;
        end

        %eccentricity
        eccentricity(i) = sqrt(1 - (b/a)^2);
        % eccentricity(i) = 1 - (b/a);

        %Circle with same area as convex hull
        r_circ = sqrt(Area(i)/pi);
        circD(i) = 2*r_circ;
    else
        majorAxisLnm(i) = NaN;
        minorAxisLnm(i) = NaN;
        angle(i) = NaN;
        eccentricity(i) = NaN;
        Area(i) = NaN;
        circD(i) = NaN;
    end

 

    
end
        
% majorAxisLnm(isnan(majorAxisLnm)) = [];
% minorAxisLnm(isnan(minorAxisLnm)) = [];
% angle(isnan(angle)) = [];
% eccentricity(isnan(eccentricity)) = [];
% Area(isnan(Area)) = [];
% circD(isnan(circD)) = [];
        