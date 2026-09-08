function [majorAxisLnm, minorAxisLnm, angle, eccentricity, Area, circD, nPts] = calcConfinementDfromTable_v2(trackTable,minTrackPts)

%Gets stats for the spacial confinement of the tracks that have at least
%MINTRACKPTs points. Uses a resolution of RESOLUTION to estimate the
%distances

%Initialize the output variables

nTrks = 0;
for i = 1:height(trackTable)
    nTrks = nTrks + length(trackTable.X{i});
end


majorAxisLnm = zeros(nTrks,1);
minorAxisLnm = zeros(nTrks,1);
angle = zeros(nTrks,1);
eccentricity = zeros(nTrks,1);
Area = zeros(nTrks,1);
circD = zeros(nTrks,1);
nPts = zeros(nTrks,1);
% trackIDs = unique(tracks(:,4));

trInd = 0;
for i = 1:height(trackTable)
    curMovieTracks = trackTable.X{i};
    for j = 1:length(curMovieTracks)
        trInd = trInd +1;
        curTrk = curMovieTracks{j};
   
        curTrk = curTrk.*1e3;
        nPts(trInd) = size(curTrk,1);
        
        if size(curTrk,1) >= minTrackPts
            %get the convex hull and Area of the track points
            
            [k,Area(trInd)] = convhull(curTrk);
            
            XY_hull = curTrk(k(1:end-1),:);
    
            %get the covariance of the convex hull
            Sigma = cov(XY_hull);
            %find the major and minor axes with eigenvalues 
            [V, D] = eig(Sigma);
            
            a = sqrt(max(D(1,1),D(2,2)));
            b = sqrt(min(D(1,1),D(2,2)));
            majorAxisLnm(trInd) = 2*a;
            minorAxisLnm(trInd) = 2*b;
            if D(1,1) > D(2,2)
                angle(trInd) = atan2d(V(1,2),V(1,1));
            else
                angle(trInd) = atan2d(V(2,2),V(2,1));
            end
            if angle(trInd) > 90
                angle(trInd) = angle(trInd) - 180;
            end
            if angle(trInd) < -90
                angle(trInd) = angle(trInd) + 180;
            end
    
            %eccentricity
            eccentricity(trInd) = sqrt(1 - (b/a)^2);
    
            %Circle with same area as convex hull
            r_circ = sqrt(Area(i)/pi);
            circD(trInd) = 2*r_circ;
        else
            majorAxisLnm(trInd) = NaN;
            minorAxisLnm(trInd) = NaN;
            angle(trInd) = NaN;
            eccentricity(trInd) = NaN;
            Area(trInd) = NaN;
            circD(trInd) = NaN;
        end
    end
 

    
end
        
% majorAxisLnm(isnan(majorAxisLnm)) = [];
% minorAxisLnm(isnan(minorAxisLnm)) = [];
% angle(isnan(angle)) = [];
% eccentricity(isnan(eccentricity)) = [];
% Area(isnan(Area)) = [];
% circD(isnan(circD)) = [];
        