function [Tracks, NParticles, ROIChoice, n_ROIs, NParticlesTracked, Particle_SNR, Track_JumpDist1, Track_nextNearestD, Particles, pixelSize,maxJump,condChosen,Loc_prec] = compileTracksFromTables(trackTable,maxTimeIn,fig_h,filetype_str)

if nargin > 3
    progTitleStr = ['Reading ', filetype_str, ' Table'];
else
    progTitleStr = 'Reading Table';
end


%check for multiple conditions, as someone may want to analyze them
%seperately
conditions_present = unique(trackTable.condition);

if length(conditions_present) > 1
    condString = [{'All'};conditions_present];
    idx_choose = CondChooseDlg(condString);

    if idx_choose ~= 1 
        condChosen = condString{idx_choose};
        idx = strcmp(trackTable.condition,condChosen);
        trackTable = trackTable(idx,:);
    end
else
    condChosen = conditions_present{1};
end
%Make sure the ROI_classes are specified as strings
if ismember('ROI_class',trackTable.Properties.VariableNames)
    for i = 1:height(trackTable)
        if ~ischar(trackTable.ROI_class{i})
            trackTable.ROI_class{i} = '';
        end
    end
end

%Check if there are multiple ROI classes
if ismember('ROI_class',trackTable.Properties.VariableNames)
    roiLabels = unique(trackTable.ROI_class);
    nClasses = length(roiLabels);
    if nClasses > 1
        ROIstring = roiLabels;
        ROIstring{end+1,1} = 'All';
       
        ROIidx = ROIClassChooseDlg(ROIstring);
        if ROIidx == nClasses + 1
            indx = true(height(trackTable),1);
            ROIChoice_all = 'All';
        else
            ROIChoice_all = ROIstring{ROIidx,:};
            indx = ismember(trackTable.ROI_class,ROIChoice_all);
        end
        trackTable = trackTable(indx,:);
    else
        ROIChoice_all = 'All';
    end

else
    ROIChoice_all = 'All';

end

movieIDs = unique(trackTable.movieID);
nFiles = length(movieIDs);
ROIChoice = cell(nFiles,1);
n_ROIs = 0;

Tracks = cell(nFiles,1);
Particles = cell(nFiles,1);
NParticles = cell(nFiles,1);
Loc_prec = zeros(nFiles,1);
if ~isempty(fig_h)
    d = uiprogressdlg(fig_h,'Title',progTitleStr);
    d.Value = 0;
else
    d = waitbar(0,['Reading Table entry 1 of ', num2str(nFiles)],'Name',progTitleStr);
end
for i = 1:nFiles
    ROIChoice{i} = ROIChoice_all;
    %Display the appropriate type of progress bar
    if ~isempty(fig_h)
        d.Message = ['Reading Data from Movie ', num2str(i), ' of ', num2str(nFiles)];
    else
        waitbar((i-1)/nFiles,d,['Reading Data from Movie ', num2str(i), ' of ', num2str(nFiles)]);
    end
    
    movieTrackTable = trackTable(trackTable.movieID == movieIDs(i),:);
    Loc_prec(i) = movieTrackTable.Loc_precision(1);

    n_ROIs = n_ROIs + height(movieTrackTable);

    
    if i == 1
        maxJump = movieTrackTable.trackingParam{i,:}(5);
        pixelSize = movieTrackTable.pixelSize(i);
    end



    Tracks{i} = [];
    for j = 1:height(movieTrackTable)
        for k = 1:length(movieTrackTable.xyt{j})
            curXYT = movieTrackTable.xyt{j}{k};
            curROI = movieTrackTable.ROI_ID(j);
            curROI = repmat(curROI,size(curXYT,1),1);
            %need a dummy intensity and background values
            curIB = zeros(size(curXYT,1),2);
            curID = repmat(movieTrackTable.trackID{j}(k),size(curXYT,1),1);
            curTrk = [curXYT, curID, curROI, curIB];
            Tracks{i} = [Tracks{i}; curTrk];
        end
    end
    if maxTimeIn == 0
        maxTime = length(movieTrackTable.NParticles{1});
    else
        maxTime = maxTimeIn;
    end
    
    Tracks{i} = Tracks{i}(Tracks{i}(:,3) <= maxTime,:);
    NParticles{i} = zeros(maxTime,1);
    for j = 1:height(movieTrackTable)
        lastTime = min(length(movieTrackTable.NParticles{1}), maxTime);

        NParticles{i}(1:lastTime) = NParticles{i}(1:lastTime) + movieTrackTable.NParticles{j}(1:lastTime);
    end

    frames = (1:length(NParticles{i}))';
    NParticles{i} = [frames, NParticles{i}];

    %         %Get the number of particles tracked over time if available
    %         if isfield(Temp.Results.PreAnalysis,'NParticlesTracked')
    NParticlesTracked{i} = zeros(maxTime,1);
    for j = 1:height(movieTrackTable)
        NParticlesTracked{i} = NParticlesTracked{i} + movieTrackTable.NParticlesTracked{j}(1:maxTime);
    end
    NParticlesTracked{i} = [frames, NParticlesTracked{i}];

    %Get the Signal to Noise ratio of the tracked particles if
    %available

    Particle_SNR{i} = trackTable.Particle_SNR{i};


    %Get the 1-frame jump distance in px if available
    Track_JumpDist1{i} = [];
    for j = 1:height(movieTrackTable)
        Track_JumpDist1{i} = [Track_JumpDist1{i}; movieTrackTable.Track_JumpDist{j}];
    end

    %Get the 2nd nearest neighbor values
    Track_nextNearestD{i} = [];
    for j = 1:height(movieTrackTable)
        Track_nextNearestD{i} = [Track_nextNearestD{i}; movieTrackTable.Track_nearest2Dist{j}];
    end






    if ~isempty(fig_h)
        d.Value = i/nFiles;
    else
        waitbar(i/nFiles,d);
    end

end
if ~isempty(fig_h)
    close(d);
else
    delete(d);
end
