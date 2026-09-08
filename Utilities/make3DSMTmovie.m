function make3DSMTmovie(Results)


Height = Results.Data.imageStack(1).height;
Width = Results.Data.imageStack(1).width;

nFrames = Results.Data.nImages;

%initialize the 3D image
IM_3d = uint16(zeros(Width+1,Height+1,nFrames));
globMN = 1e6;
globMX = 0;

%fill in the image data
for i = 1:nFrames
    IM_3d(1:Width,1:Height,i) = Results.Data.imageStack(i).data;
    if min(Results.Data.imageStack(i).data(:)) < globMN
        globMN = min(Results.Data.imageStack(i).data(:));
    end
    if max(Results.Data.imageStack(i).data(:)) > globMX
        globMX = max(Results.Data.imageStack(i).data(:));
    end
%     IM_3d(:,:,i) = Results.Process.filterStack(i).data;

end
globMN = 50;
globMX = 4000;


for i = 1:nFrames
    IM_3d(Width+1,:,i) = globMX.*uint16(ones(Height+1,1));
    IM_3d(:,Height,i) = globMN.*uint16(ones(Width+1,1));
end

% test = double(IM_3d);
% mn = min(test(:));
% mx = max(test(:));
% % test = (test - mn);
% test(test < 0) = 0;
% IM_3d = test;

%parse the tracking data
tracks = Results.Tracking.Tracks;

trkIDs = unique(tracks(:,4));

trkLen = zeros(length(trkIDs),1);
for i = 1:length(trkIDs)
    curTrk = tracks(tracks(:,4) == trkIDs(i),1);
    trkLen(i) = length(curTrk);
end
keepIDs = find(trkLen >= 20);
keepIDs = trkIDs(keepIDs);
trkLen_keep = trkLen(keepIDs);

line_cmap = jet((max(trkLen_keep) - min(trkLen_keep))+1);

tracks2 = [];

for j = 1:length(keepIDs)
    curTrk = tracks(tracks(:,4) == keepIDs(j),:);
    tracks2 = [tracks2; curTrk];
end

figure;

%set up save location
defName = [Results.Data.fileName(1:end-4), 'trackMovie.mp4'];
defPath = Results.Data.pathName;

[savename,savepath] = uiputfile('.mp4','Select file to write',fullfile(defPath,defName));

% tempDir = [savepath,filesep,'Views'];
% mkdir(tempDir);

if savename == 0
    return
end
v = VideoWriter(fullfile(savepath,savename),'MPEG-4');
v.Quality = 100;
% v.LosslessCompression = true;

open(v);

for i = 1:nFrames
    IM = IM_3d(:,:,i);
    [y,z] = meshgrid(1:size(IM,2),1:size(IM,1));
    x = i*ones(size(y));
    s = surf(x,y,z,IM);
    s.AlphaData = s.CData;
    shading flat;
    colormap gray
    axis image;
    set(gca,'XLim',[1,nFrames]);
    set(gca,'Ylim',[1 size(IM,2)])
    set(gca,'Zlim',[1 size(IM,1)]);
    view(-72,10);
    set(gca,'Projection','perspective');
    set(gca,'Color',[1,1,1]);
    set(gca,'YTick',[]);
    set(gca,'ZTick',[]);
    set(gca,'Box','on')
    set(gca,'BoxStyle','full');
    set(gca,'LineWidth',2);
    xlabel('Frame');

    %plot the tracks
    curPt_tracks = tracks2(tracks2(:,3) <= i,:);
        
    curIDs = unique(curPt_tracks(:,4));
    hold("on");
    for j = 1:length(curIDs)
        tmpTrk = tracks2(tracks2(:,4) == curIDs(j),:);
        currentCol = line_cmap(trkLen(curIDs(j)) - min(trkLen_keep)+ 1,:);
        plot3(tmpTrk(:,3),tmpTrk(:,1),tmpTrk(:,2),'Color', currentCol);
    end
    hold("off");

%     print(gcf,[tempDir,filesep,'View_',num2str(i),'.tif'],'-dtiff','-r300');
    f = getframe(gcf);
    writeVideo(v,f);


    


end

% open(v);
% for i = 1:nFrames
%     I = imread(fullfile(tempDir,['View_',num2str(i),'.tif']));
%     writeVideo(v,I);
% end
% 
close(v);
close(gcf);
% rmdir(tempDir,'s');