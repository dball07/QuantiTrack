function [trkLengthsAll, trkLengthsFirstFrame, trkLengthsFirstNframes, endptN]   = compileTrackLengths(varargin)

%Counts the length of 3 different sets of tracks: 1) All Tracks; 2) Tracks
%present in the first frame; 3) Tracks that originate in the first 30
%frames. Saves the data in the same folder where the files are

%This parameter determines where the cutoff for the analysis of (3) falls
frameCutoff = 30;

if isempty(varargin)
    [files,path] = uigetfile('*.mat','Select Files to analyze','MultiSelect','on');
end
trkLengthsAll = [];
trkLengthsFirstFrame = [];
trkLengthsFirstNframes = [];
endptN = [];

    if ~iscell(files)
        files = {files};
    end
    if files{1} ~= 0
    
        for i = 1:length(files)
            filename = fullfile(path,files{i});
            IN = load(filename);
            trks = IN.Results.PreAnalysis.Tracks_um;

            for j = 1:max(trks(:,4))
                curTrk = trks(trks(:,4) == j,:);
                trkLengthsAll = [trkLengthsAll;size(curTrk,1)];
                if curTrk(1,3) == 1
                    trkLengthsFirstFrame = [trkLengthsFirstFrame;size(curTrk,1)];
                end
                if curTrk(1,3) <= frameCutoff
                    trkLengthsFirstNframes = [trkLengthsFirstNframes; size(curTrk,1)];
                    endptN = [endptN; curTrk(end,3)];
                end
            end

        end
    end
end

%Save data
outputfile = fullfile(path,'TrkLengthAnalysis.mat');
save(outputfile,'trkLengths*','endptN');
