function ROI_disp = calcROIdisp(pxSize)

%Calculates the 1-frame displacement of the ROI centroids. If the pixel
%size is not specified, a default value of 1 um will be used.

if nargin == 0
    pxSize = 1;
end

[trkfiles, trkpath] = uigetfile('*.mat','Select the files to analyze','MultiSelect','on');

if ~iscell(trkfiles)
    files_tmp = {trkfiles};
    trkfiles = files_tmp;
end

ROI_disp = [];

if trkfiles{1} == 0
    return;
end


for i = 1:length(trkfiles)
    IN = load(fullfile(trkpath,trkfiles{:,i}));
    ROICent = IN.Results.PreAnalysis.Tracks_um;
    trkIDs = unique(ROICent(:,4));

    for j = 1:length(trkIDs)
        curROI = ROICent(ROICent(:,4) == trkIDs(j),1:2);
        
        dX = diff(curROI);
        dX2 = dX.^2;
        dR = sqrt(sum(dX2,2));
        ROI_disp = [ROI_disp; dR];
       
    end
end


