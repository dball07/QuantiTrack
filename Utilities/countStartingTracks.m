function trkLengths = countStartingTracks(varargin)

if isempty(varargin)
    [files,path] = uigetfile('*.mat','Select Files to analyze','MultiSelect','on');
end
trkLengths = [];

    if ~iscell(files)
        files = {files};
    end
    if files{1} ~= 0
    
        for i = 1:length(files)
            filename = fullfile(path,files{i});
            load(filename)
            trks = Results.PreAnalysis.Tracks_um;

            for j = 1:max(trks(:,4))
                curTrk = trks(trks(:,4) == j,:);
                if curTrk(1,3) == 1
                    trkLengths = [trkLengths;size(curTrk,1)];
                end
            end

        end
    end
end