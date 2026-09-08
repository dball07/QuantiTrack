function [trkLengths,endpt] = countTracksStartingNper(percentage,varargin)


if percentage > 1
    percentage = percentage./100;
end

if isempty(varargin)
    [files,path] = uigetfile('*.mat','Select Files to analyze','MultiSelect','on');
end
trkLengths = [];
endpt = [];

    if ~iscell(files)
        files = {files};
    end
    if files{1} ~= 0
    
        for i = 1:length(files)
            filename = fullfile(path,files{i});
            load(filename)
            trks = Results.PreAnalysis.Tracks_um;
            nframes = Results.Data.nImages;
            th = round(percentage.*nframes);
            for j = 1:max(trks(:,4))
                curTrk = trks(trks(:,4) == j,:);
                if curTrk(1,3) <= th
                    trkLengths = [trkLengths;size(curTrk,1)];
                    endpt = [endpt; curTrk(end,3)];
                end
            end

        end
    end
end