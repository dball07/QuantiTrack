function gapLengths = calcGaps(TrkPtsAdded)


gapLengths = [];
for i = 1:length(TrkPtsAdded)
    if ~isempty(TrkPtsAdded{i})
        curTrkPts = TrkPtsAdded{i};
        if length(curTrkPts) == 1
            gapLengths = [gapLengths; 1];
        else
            dFrame = diff(curTrkPts);
            ind = 1;
            while ind <= length(dFrame)
                curGap = 1;
                while  ind <= length(dFrame) && dFrame(ind) == 1
                    curGap = curGap + 1;
                    ind = ind + 1;
                end
                gapLengths = [gapLengths; curGap];
                ind = ind + 1;
            end
        end
    end
end