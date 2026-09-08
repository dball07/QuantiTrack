function [trkLenPts_all,trkLenTime_all] = trackLengthCalc_Batch()

[files, path] = uigetfile('*.mat','Select Files to Analyze','MultiSelect','on');

if ~iscell(files)
    files_tmp{1} = files;
    files = files_tmp;
end

if files{1} ~= 0
    defaults = {'0.01','50','0.05', '0.8','50'};
    prompt = {'Time-step (s)'};
    dlgtitle = 'Tracking Time-step';

    AnalysisParam = inputdlg(prompt,dlgtitle, 1, defaults);
    tstep = str2double(AnalysisParam{1});
    trkLenPts_all = [];
    trkLenTime_all = [];
    for i = 1:length(files)
        
        load(fullfile(path,files{i}));
        tracks = Results.PreAnalysis.Tracks_um;
        [trkLenPts,trkLenTime] = trackLengthCalc(tracks);
        trkLenPts_all = [trkLenPts_all; trkLenPts];
        trkLenTime_all = [trkLenTime_all; trkLenTime];
    end
    trkLenTime_all = trkLenTime_all.*tstep;
end
