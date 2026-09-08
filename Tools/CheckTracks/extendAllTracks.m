function ResultsOut = extendAllTracks(Results)

%extends all of the Tracks in Results.Tracking.CheckTracks to start at
%frame 1 and end at the final frame. For tracks that begin/end away from
%the first/last frame, the first/last known particle position is progated
%to the beginning/end.

ResultsOut = Results;
if isfield(Results.Tracking,'CheckTracks')
    Trks = Results.Tracking.CheckTracks;
elseif isfield(Results.Tracking,'Tracks')
    Trks = Results.Tracking.Tracks;
else
    return;
end
nTrks = max(Trks(:,4));
nImages = Results.Data.nImages;
newTrks = [];
for i = 1:nTrks
    curTrk = Trks(Trks(:,4) == i,:);
    preTrk = [];
    appTrk = [];
    if curTrk(1,3) > 1
        toAddPre = curTrk(1,3) - 1;
        preTrk(:,1) = curTrk(1,1)*ones(toAddPre,1);
        preTrk(:,2) = curTrk(1,2)*ones(toAddPre,1);
        preTrk(:,3) = (1:curTrk(1,3)-1)';
        preTrk(:,4) = curTrk(1,4)*ones(toAddPre,1);
        preTrk(:,5) = curTrk(1,5)*ones(toAddPre,1);
    end
    if curTrk(end,3) < nImages
        toAddEnd = nImages - curTrk(end,3);
        appTrk(:,1) = curTrk(end,1)*ones(toAddEnd,1);
        appTrk(:,2) = curTrk(end,2)*ones(toAddEnd,1);
        appTrk(:,4) = curTrk(end,4)*ones(toAddEnd,1);
        appTrk(:,5) = curTrk(end,5)*ones(toAddEnd,1);
        appTrk(:,3) = (curTrk(end,3)+1:nImages)';
    end
    newCurTrk = [preTrk;curTrk; appTrk];
    newTrks = [newTrks; newCurTrk];
end
if isfield(Results.Tracking,'CheckTracks')
    ResultsOut.Tracking.CheckTracks = newTrks;
elseif isfield(Results.Tracking,'Tracks')
    ResultsOut.Tracking.Tracks = newTrks;
end
