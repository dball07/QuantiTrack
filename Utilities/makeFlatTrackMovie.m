function makeFlatTrackMovie(imStack,tracks,ROIpos,frameTime,pixelSize,FileNameOut, blackLevel,whiteLevel,minTrkLen,maxFrame,movFrameRate,minX,maxX,minY,maxY,scalebar_length,timestamp_flag)

%generates a movie with images with traces overlaid, optionally a scale bar
%and time-stamp can be added
%Required inputs:
%imStack - structure containing the timelapse movie, must
% have a field called 'data'
%
%tracks - Array containing the tracking data, first 3 columns should be
% X,Y and time (X,Y should be specified in pixels)
%
%ROIS - cell array containing the verticies defining the ROIs in the movie
%
% frameTime - time between images in the time-lapse
%
%FileNameOut - full path and file name of the saved movie

if nargin < 6
    errordlg('Need to specify the image stack, tracks, ROIsm and Save name');
end

%Set some default values
if nargin < 7 || isempty(blackLevel)
    blackLevel = 50;
end

if nargin < 8 || isempty(whiteLevel)
    whiteLevel = 50;
end

if nargin < 9 || isempty(minTrkLen)
    minTrkLen = 1;
end

if nargin < 10 || isempty(maxFrame)
    maxFrame = 0;
end

if nargin < 11 || isempty(movFrameRate)
    movFrameRate = 50;
end

if nargin < 12 || isempty(minX)
    minX = 1;
end

if nargin < 13 || isempty(maxX)
    maxX = nrows;
end

if nargin < 14 || isempty(minY)
    minY = 1;
end

if nargin < 15 || isempty(maxY)
    maxY = ncols;
end

if nargin < 16 || isempty(scalebar_length)
    scalebar_length = 2;
end

if nargin < 17 || isempty(timestamp_flag)
    timestamp_flag = 1;
end
%end default parameter settings

%Get the desired X and Y limits 
xlim = [minX, maxX];
ylim = [minY, maxY];

%Remove tracks that are shorter than minTrkLength
if maxFrame == 0 || maxFrame > max(tracks(:,3))
    maxFrame = length(imStack);
end
tracks = tracks(tracks(:,3) <= maxFrame,:);
% trkIDs = unique(tracks(:,4));
trkIDs = (1:max(tracks(:,4)))';
trkLen = zeros(max(trkIDs),1);
for j = 1:max(trkIDs)
    curTrk = tracks(tracks(:,4) == j,1);
    trkLen(j) = length(curTrk);
end
keepIDs = find(trkLen >= minTrkLen);


% trkLen_keep = trkLen(keepIDs);

line_cmap = jet(201);

tracks2 = [];

for j = 1:length(keepIDs)
    curTrk = tracks(tracks(:,4) == keepIDs(j),:);
    tracks2 = [tracks2; curTrk];
end

keepIDs = trkIDs(keepIDs);

line_cmap = jet(201);
tracks2 = [];

for j = 1:length(keepIDs)
    curTrk = tracks(tracks(:,4) == keepIDs(j),:);
    tracks2 = [tracks2; curTrk];
end
colorbins = linspace(minTrkLen,200,201);

v = VideoWriter(fullfile(FileNameOut),'MPEG-4');
v.Quality = 100;
v.FrameRate = movFrameRate;
open(v);

movieFig = figure;

for i = 1:maxFrame

    imshow(imStack(i).data,[blackLevel,whiteLevel],'InitialMagnification',200);


    axis off
    ImIx = find(tracks2(:,3) == i);
    if size(ROIpos,2) > 1
        ROI = ROIpos(:,i);
    else
        ROI = ROIpos(:,1);
    end
    plotROI(ROI);

    if ~isempty(ImIx)
        pIx = tracks2(ImIx,4);           %find the corresponding particle index;
        for j =pIx'
            plotIx = find(tracks2(:,4) == j & tracks2(:,3) <= i);
            hold on;
            plot(tracks2(plotIx,1),tracks2(plotIx,2),'r','LineWidth',1);
            hold off;
        end

    end
    if scalebar_length ~= 0
        %Add 2 um scalebar
        scale_posy = repmat(0.95*xlim(2),2,1);
        scale_lenPx = scalebar_length/pixelSize;
        scale_posx(1) = 0.95*ylim(2) - scale_lenPx;
        scale_posx(2) = 0.95*ylim(2);
        hold on
        plot(scale_posx,scale_posy,'w','LineWidth',3);
    end

    if timestamp_flag ~= 0
        %Add time-stamp
        tstamp_posy = 0.92*xlim(2);
        tstamp_posx = 5;
        if frameTime < 0.1
            formatSpec = '%.2f';
        elseif frameTime < 1.0
            formatSpec = '%.1f';
        else
            formatSpec = '%.0f';
        end
        hold on
        time_str = [num2str((i-1)*frameTime,formatSpec), ' s'];
        text(gca,tstamp_posx,tstamp_posy,time_str,'Color',[1 1 1],'FontSize',12);
        hold off;
    end


    F = getframe(movieFig);
    writeVideo(v,F);


end
close(v);
close(movieFig);