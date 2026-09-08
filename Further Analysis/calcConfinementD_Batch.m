function [majorAxisLnm, minorAxisLnm, angle, eccentricity, Area, circD, nPts] = calcConfinementD_Batch(minTrackPts)




[files,path] = uigetfile('*.mat','Select Files to Open',pwd,'MultiSelect','on');

if ~iscell(files)
    files_tmp{1} = files;
    files = files_tmp;
end

if files{1} == 0
    return
end
majorAxisLnm = [];
minorAxisLnm = [];
angle = [];
eccentricity = [];
Area = [];
circD = [];
nPts = [];

for i = 1:length(files)
    IN = load(fullfile(path,files{i}));
    if isfield(IN,'trackTable')
        [majorAxisLnm, minorAxisLnm, angle, eccentricity, Area, circD, nPts] = calcConfinementDfromTable_v2(IN.trackTable,minTrackPts);
    else
        
        if isfield(IN,'Results')
            tracks = IN.Results.PreAnalysis.Tracks_um;
            tracks(:,1:2) = tracks(:,1:2)*1e-6;
        elseif isfield(IN,'tracks')
            tracks = IN.tracks;
        end
        [majorAxisLnm_cur, minorAxisLnm_cur, angle_cur, eccentricity_cur, Area_cur, circD_cur, nPts_cur] = calcConfinementD_v2(tracks,minTrackPts);
        
        majorAxisLnm = [majorAxisLnm; majorAxisLnm_cur];
        minorAxisLnm = [minorAxisLnm; minorAxisLnm_cur];
        angle = [angle; angle_cur];
        eccentricity = [eccentricity; eccentricity_cur];
        Area = [Area; Area_cur];
        circD = [circD; circD_cur];
        nPts = [nPts; nPts_cur];
    end
end