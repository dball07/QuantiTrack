function [trkLenPts,trkLenTime] = trackLengthCalc(tracks_in)
% Returns all track lengths in number of points and length of time for each
% track (in seconds) in the tracks_in variable

%Get the IDs of all tracks in the file
trkIDs = unique(tracks_in(:,4));

%intialize output variables
trkLenPts = zeros(length(trkIDs),1);
trkLenTime = zeros(length(trkIDs),1);

%Go through all tracks and find the length
for i = 1:length(trkIDs)
    curTrk = tracks_in(tracks_in(:,4) == trkIDs(i),:);
    trkLenPts(i) = size(curTrk,1);
    trkLenTime(i) = curTrk(end,3) - curTrk(1,3);
end
