function trkIDs_plotted = plotTrkStates(pEMTable,nPlots)

% plots the longest tracks' positions in individual figures from the 
% pEMTable input . Each track segment is color coded based on the state
% ID. If the pEMTable is not input, then a file open dialog will appear to 
% load in the data. The nPlots input determines how many of the tracks to
% plot, default is 5. If nPlots is set to 0, all of the tracks will be
% plotted.

%D. Ball
%July 2023


if nargin < 1 || isempty(pEMTable)
    [pEMfile,pEMpath] = uigetfile('*.mat','Select pEM results',pwd);
    IN = load(fullfile(pEMpath,pEMfile));
    pEMTable = IN.pEMTable;
end

if nargin < 2 || isempty(nPlots)
    nPlots = 5;
end


nStates = pEMTable.optimalSize;
cmap = colormap('lines');

%Get the number of segments from each track
trkIDs = pEMTable.trackID{1};
trkSegments = zeros(length(trkIDs),1);


for i = 1:length(trkIDs)
    trkSegments(i,1) = length(find(pEMTable.splitID{1} == trkIDs(i)));
end
if nPlots > 0
    %sort the tracks based on the number of segments
    [~, ind] = sortrows(trkSegments,'descend');

    trkIDs_plotted = trkIDs(ind(1:nPlots));
else
    ind = (1:length(trkIDs))';
    trkIDs_plotted = trkIDs;
    nPlots = length(trkIDs_plotted);
end


for i = 1:nPlots
    %get the indices for the current track to extract position information
    seg_ind = find(pEMTable.splitID{1} == trkIDs_plotted(i));
    figure; hold on
    for j = 1:length(seg_ind)-1
        curPos = pEMTable.splitX{1}{seg_ind(j)};
        curPos = [curPos; pEMTable.splitX{1}{seg_ind(j)}(1,:)];
        curState = pEMTable.optimalState{1}(seg_ind(j));
        if curState < 8
            plot(curPos(:,1),curPos(:,2),'Color',cmap(curState,:),'LineWidth',2);
        else
            plot(curPos(:,1),curPos(:,2),'-.','Color',cmap(curState,:),'LineWidth',2);
        end
    end
    j = length(seg_ind);
    curPos = pEMTable.splitX{1}{seg_ind(j)};
    curPos = [curPos; pEMTable.splitX{1}{seg_ind(j)}(1,:)];
    curState = pEMTable.optimalState{1}(seg_ind(j));
    if curState < 8
        plot(curPos(:,1),curPos(:,2),'Color',cmap(curState,:),'LineWidth',2);
    else
        plot(curPos(:,1),curPos(:,2),'-.','Color',cmap(curState,:),'LineWidth',2);
    end
    title(sprintf('Track ID: %d', trkIDs_plotted(i)));
    %Plot the first (green) nad last (red) points
    firstPt = pEMTable.splitX{1}{seg_ind(1)}(1,:);
    lastPt = pEMTable.splitX{1}{seg_ind(j)}(end,:);
    scatter(firstPt(:,1),firstPt(:,2),'g','filled');
    scatter(lastPt(:,1),lastPt(:,2),'r','filled');
    
    xlabel('X (\mum)');
    ylabel('Y (\mum)');
    axis image
    


end
