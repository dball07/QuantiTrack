function [track_nn, track_nn2] = calcTrack_NN(tracks,centroids)

trkIDs = unique(tracks(:,4));
nTrks = length(trkIDs);
track_nn = zeros(length(tracks)-nTrks,1);
track_nn2 = [];

curInd1 = 1;
if size(centroids,2) > 7
    centX = 10;
else
    centX = 1;
end
centroids(centroids(:,1) == 0,:) = [];

%first get the distance for the point that was tracked
for i = 1:nTrks
    curTrk = tracks(tracks(:,4) == trkIDs(i),1:2);
    dXY = diff(curTrk);
    dXY2 = dXY.^2;
    dR = sqrt(sum(dXY2,2));

    track_nn(curInd1:curInd1+length(dR)-1,1) = dR;
    curInd1 = curInd1+length(dR);
end


%now get the 2 nearest neighbors for each track point in the
%next frame

for i = min(tracks(:,3)):max(tracks(:,3))
    curT_tracks = tracks(tracks(:,3) == i,1:2);
    nextT_part = centroids(centroids(:,6) == i+1,centX:centX+1);
    
    if size(nextT_part,1) > 1 && ~isempty(curT_tracks)
        [~, nn_cur] = knnsearch(nextT_part,curT_tracks,'K',2);
        track_nn2 = [track_nn2; nn_cur];
    elseif size(nextT_part,1) == 1 && ~isempty(curT_tracks)
        [~, nn_cur] = knnsearch(nextT_part,curT_tracks);
        nn_cur = [nn_cur, -1*ones(size(nn_cur,1),1)];
        track_nn2 = [track_nn2; nn_cur];
    else
        nn_cur = [-1, -1];
        track_nn2 = [track_nn2; nn_cur];
    end
end

