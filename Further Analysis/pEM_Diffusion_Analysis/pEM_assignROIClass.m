function [trkROIind, trkROIclass, allROIClasses] = pEM_assignROIClass(pEMTable,trackTable,trackFileRootFolder)

%Goes through the pEM table and extracts the ROI class that each track is a
%part of.

if nargin < 3
    %     If the location of the tracking files is not specified, ask the user
%     to select it
    trackFileRootFolder = uigetdir(pwd,'Select the root folder for all tracking files');
    if trackFileRootFolder == 0
        return;
    end
end
if nargin == 0
%     If the pEM results file is not specified ask the user to select it
    [pEMfile, pEMpath] = uigetfile('*.mat','Select pEM results file to analyze');
    
    if pEMfile == 0
        return;
    end
    IN = load(fullfile(pEMpath,pEMfile));
    pEMTable = IN.pEMTable;
    trackTable = IN.trackTable;



end

for i = 1:length(pEMTable.splitX{1,:})
    
    curX = pEMTable.splitX{1}{i};
    curSplit = pEMTable.splitID{1}(i);
    curID = pEMTable.trackID{1}(curSplit);
    splitLength = pEMTable.trackInfo{1}.splitLength;
    pxSize = trackTable.pixelSize(1);
    %compare the curID to the trackIDs in the trackTable
    foundID = 0;
    for j = 1:length(trackTable.trackID)
        trackIDs2check = trackTable.trackID{j};
        for k = 1:length(trackIDs2check)
            if curID == trackIDs2check(k)
                foundID = 1;
                break;
            end
        end
        if foundID == 1
            break;
        end
    end
    
    %Determine the identifiers for the appropriate tracking file
    cell_protein = trackTable.cell_protein{j,:};
    condition = trackTable.condition{j,:};
    session = trackTable.session{j,:};
    name = trackTable.name{j,:};
    
    %Recapitulate the full path to the tracking file
    track_file_fullpath = [trackFileRootFolder,filesep,cell_protein,filesep,condition,filesep,session,filesep,name];
    %load in the tracking file
    tIN = load(track_file_fullpath);
    
    %find the current subtrack in the tracking file
    allTracks = tIN.Results.Tracking.Tracks;
    allTracks(:,1:2) = allTracks(:,1:2).*pxSize;

    firstInd = find(allTracks(:,1) == curX(1,1));
    ROI = allTracks(firstInd:firstInd+splitLength - 1,5);
    ROIs_present = unique(ROI);
%     if length(ROIs_present) > 1
%         bloa = 1;
%     end
    nPts_ROIs = zeros(size(ROIs_present,1),1);
    for j = 1:length(ROIs_present)
        nPts_ROIs(j,1) = length(find(ROI == ROIs_present(j)));
    end
    ROIchoose = find(nPts_ROIs == max(nPts_ROIs),1,'first');
%     ROI = ROIs_present(ROIchoose);
    allROIClasses{i,:} = tIN.Results.Process.ROIClass;
    
    trkROIind(:,i) = ROI;

%     if length(unique(ROI)) > 1
%         blah = 1;
%     else
    % if i == 113
    %     blah = 1;
    % end
    if i == 413
        ainigan = 1;
    end
    if isfield(tIN.Results.Process,'ROIClass')
        if iscell(tIN.Results.Process.ROIClass{ROI(ROIchoose),:})
            trkROIclass{i,:} = tIN.Results.Process.ROIClass{ROI(ROIchoose),:}{1,:};
        else
            trkROIclass{i,:} = tIN.Results.Process.ROIClass{ROI(ROIchoose),:}(1,:);
        end

    else
        trkROIclass{i,:} = [];
    end
%     end
    
    
end
