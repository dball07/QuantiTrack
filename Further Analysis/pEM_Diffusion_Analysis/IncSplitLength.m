function trackTable = IncSplitLength(trackTable_in,splitLength)


trk_count = 1;
counter = 1;



for i = 1:size(trackTable_in,1)
    X_tmp = {};
    trackID_mat = [];
    curTrks = trackTable_in.X{i,:};
    trkCount2 = 1;
    for j = 1:length(curTrks)
        
        trk = curTrks{j};
        if size(trk,1) >= splitLength
                X_tmp{trkCount2} = trk;
                trkCount2 = trkCount2 + 1;
                trackID_mat = [trackID_mat; trk_count];
                trk_count = trk_count + 1;
        end
    end
    X{counter,:} = X_tmp;
    trackID{counter,:} = trackID_mat;
    counter = counter + 1;
end
     

trackTable = trackTable_in;
trackTable.X = X;
trackTable.trackID = trackID;
for i = 1:size(trackTable,1)
    trackTable.splitLength(i) = splitLength;
end
