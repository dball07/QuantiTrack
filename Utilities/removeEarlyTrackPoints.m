function trackTable_out = removeEarlyTrackPoints(trackTable_in)

trackTable2 = trackTable_in;


for i = 1:height(trackTable2)
    curXYT = trackTable2.xyt{i};
    newXYT = {};
    newXY = {};
    newTrackIDs = [];
    trkID = 0;
    for j = 1:length(curXYT)
        ind = find(curXYT{j}(:,3) > 50);
        if ~isempty(ind)
            trkID = trkID+1;
            newXYT{1,trkID} = curXYT{j}(ind,:);
            newXY{1,trkID} = trackTable2.X{i}{j}(ind,:);
            newTrackIDs(trkID) = trackTable2.trackID{i}(j);
        end
    end
    trackTable2.X{i} = newXY;
    trackTable2.xyt{i} = newXYT;
    trackTable2.trackID{i} = newTrackIDs;
    trackTable2.NParticles{i} = trackTable2.NParticles{i}(51:end,:);
    trackTable2.NParticlesTracked{i} = trackTable2.NParticlesTracked{i}(51:end,:);
end


trackTable_out = trackTable2;
trackID_offset = trackTable_out.trackID{1}(1) - 1;
cellID_offset = trackTable_out.cellID(1)-1;
movieID_offset = trackTable_out.movieID(1)-1;
for i = 1:height(trackTable_out)
    trackTable_out.trackID{i} = trackTable_out.trackID{i} - trackID_offset;
    trackTable_out.cellID(i) = trackTable_out.cellID(i) - cellID_offset;
    trackTable_out.movieID(i) = trackTable_out.movieID(i) - movieID_offset;
end

