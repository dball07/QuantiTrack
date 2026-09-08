function makePerspectiveTrackMovie(imStack,tracks,frameTime,FileNameOut, blackLevel,whiteLevel,minTrkLen,maxFrame,movFrameRate,minX,maxX,minY,maxY,fig_bgColor,ax_bgColor,textColor)

%generates a movie with images moving into the plane and leaving the traces
%behind
%Required inputs:
%imStack - structure containing the timelapse movie, must
% have a field called 'data'
%
%tracks - Array containing the tracking data, first 3 columns should be
% X,Y and time (X,Y should be specified in pixels)
%
%frameTime - time between images in the time-lapse
%
%FileNameOut - full path and file name of the saved movie

if nargin < 4
    errordlg('Need to specify the image stack, tracks, and Save name');
end

[nrows, ncols] = size(imStack(1).data);

%Set some default values
if nargin < 5 || isempty(blackLevel)
    blackLevel = 50;
end

if nargin < 6 || isempty(whiteLevel)
    whiteLevel = 50;
end

if nargin < 7 || isempty(minTrkLen)
    minTrkLen = 1;
end

if nargin < 8 || isempty(maxFrame)
    maxFrame = 0;
end

if nargin < 9 || isempty(movFrameRate)
    movFrameRate = 50;
end

if nargin < 10 || isempty(minX)
    minX = 1;
end

if nargin < 11 || isempty(maxX)
    maxX = nrows;
end

if nargin < 12 || isempty(minY)
    minY = 1;
end

if nargin < 13 || isempty(maxY)
    maxY = ncols;
end

if nargin < 14 || isempty(fig_bgColor)
    fig_bgColor = [0.94 0.94 0.94];
end

if nargin < 15 || isempty(ax_bgColor)
    ax_bgColor = [1 1 1];
end

if nargin < 16 || isempty(textColor)
    textColor = [0 0 0];
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
set(movieFig,'Color',fig_bgColor);

for i = 1:maxFrame

    IM = imStack(i).data;


    IM = IM(xlim(1):xlim(2),ylim(1):ylim(2));

    IM_tmp = (double(IM) - blackLevel)./whiteLevel;
    IM_tmp(IM_tmp < 0) = 0;
    IM_tmp(IM_tmp > 1) = 1;
    IM = uint8(IM_tmp*255);
    IM(:,end+1) = 255*ones(size(IM,1),1);
    IM(end+1,:) = zeros(1,size(IM,2));

    [y,z] = meshgrid(1:size(IM,2),1:size(IM,1));
    x = i*ones(size(y));
    subplot(1,10,1:9)
    s = surf(x,y,z,IM);
    s.AlphaData = s.CData;
    shading flat;
    colormap gray
    axis image;
    set(gca,'XLim',[1,maxFrame]);
    set(gca,'Ylim',[1 size(IM,2)])
    set(gca,'Zlim',[1 size(IM,1)]);
    set(gca,'Zdir','reverse');
    set(gca,'Ydir','reverse');

    view(-72,10);
    set(gca,'Projection','perspective');
    set(gca,'Color',ax_bgColor);
    set(gca,'YTick',[]);
    set(gca,'ZTick',[]);
    %change xtick labels to time
    xticks = get(gca,'XTick');
    xticks_new = xticks.*frameTime;
    xtickLabels = get(gca,'XTickLabel');
    xtickLabels_new = xtickLabels;
    for j = 1:length(xtickLabels_new)
        xtickLabels_new{j,:} = num2str(xticks_new(j));
    end
    set(gca,'XTickLabel',xtickLabels_new);

    set(gca,'Box','on')
    %                         set(gca,'BoxStyle','full');
    set(gca,'LineWidth',2);

    xlabel('Time (s)','Color',textColor);
    set(gca,'XColor',textColor);
    set(gca,'YColor',textColor);
    set(gca,'ZColor',textColor);

    %plot the tracks
    curPt_tracks = tracks2(tracks2(:,3) <= i,:);

    curIDs = unique(curPt_tracks(:,4));
    hold("on");
    %                         if i == 200
    %                             bagb = 1;
    %                         end

    for j = 1:length(curIDs)
        tmpTrk = curPt_tracks(curPt_tracks(:,4) == curIDs(j),:);
        colInd = find(colorbins <= size(tracks2(tracks2(:,4) == curIDs(j)),1),1,'last');
        if isempty(colInd)
            colInd = 201;
        end
        currentCol = line_cmap(colInd,:);
        plot3(tmpTrk(:,3),tmpTrk(:,1)-(ylim(1)-1),tmpTrk(:,2)-(xlim(1)-1),'Color', currentCol);
    end
    hold("off");

    subplot(1,10,10)
    line_col(:,:,1) = line_cmap(:,1);
    line_col(:,:,2) = line_cmap(:,2);
    line_col(:,:,3) = line_cmap(:,3);

    imagesc([1 2 3],colorbins,line_col);
    set(gca,'YAxisLocation','right')
    set(gca,'YDir','normal')
    %change xtick labels to time
    yticks = get(gca,'YTick');
    yticks_new = yticks.*frameTime;
    ytickLabels = get(gca,'YTickLabel');
    ytickLabels_new = ytickLabels;
    for j = 1:length(ytickLabels_new)
        ytickLabels_new{j,:} = num2str(yticks_new(j));
    end
    set(gca,'YTickLabel',ytickLabels_new);
    %%%
    ylabel('Track Length (s)','Color',[1 1 1]);

    set(gca,'FontSize',10)
    set(gca,'YColor',textColor);
    set(gca,'XColor',textColor);
    set(gca,'Xtick',[])

    %     print(gcf,[tempDir,filesep,'View_',num2str(i),'.tif'],'-dtiff','-r300');
    f = getframe(movieFig);
    writeVideo(v,f);

end
close(v);
close(movieFig);

end