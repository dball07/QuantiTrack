function tracksDcoded(Results)

tracks = Results.Tracking.Tracks;

%calculate diff. coefficients for each track and bin them for color-coding
[R_sq, tracks_used] = calculateMSD2(tracks,0.2,100,6);
logD = log10(R_sq);
bins = linspace(-3,1,25);
D_bin = zeros(length(logD),1);

for i = 1:length(logD)

    D_bin(i) = find(bins >= logD(i,1),1,'first');
end

%set the pixel size
px_size = Results.Parameters.Acquisition.pixelSize;
%make a 2 um scale bar
sb_2um_xsize = 5/px_size;
sb_2um_xlim(1) = Results.Data.imageStack(1).width - 10 - sb_2um_xsize + 1;
sb_2um_xlim(2) = Results.Data.imageStack(1).width - 10;
sb_2um_ylim = [Results.Data.imageStack(1).height - 10, Results.Data.imageStack(1).height - 10];


BG = zeros(Results.Data.imageStack(1).height,Results.Data.imageStack(1).width);
line_cmap = cool(length(bins));
figure;
subplot(1,10,1:9);
imagesc(BG,[0,1])
colormap(gray);
hold on
for i = 1:length(tracks_used)
    curTrk = tracks(tracks(:,4) == tracks_used(i),:);
    plot(curTrk(:,1),curTrk(:,2),'Color',line_cmap(D_bin(i),:));
end
axis image
ROIpos = Results.Process.ROIpos;
for i = 1:length(ROIpos)
    curROI = ROIpos{i};
    curROI(end+1,:) = curROI(1,:);
    plot(curROI(:,1),curROI(:,2),'w--');
end
set(gca,'XTick',[]);
set(gca,'YTick',[]);
set(gca,'YDir','reverse');

plot(sb_2um_xlim,sb_2um_ylim,'w','LineWidth',3);

subplot(1,10,10)
line_col(:,:,1) = line_cmap(:,1);
line_col(:,:,2) = line_cmap(:,2);
line_col(:,:,3) = line_cmap(:,3);
imagesc(line_col)
set(gca,'YAxisLocation','right')
set(gca,'YDir','normal')
set(gca,'FontSize',10)
set(gca,'Xtick',[])
yticks = [1, 7, 13, 19, 25];
set(gca,'YTick',yticks)
YtickNum = bins(yticks);
for i = 1:length(YtickNum)
    ytickLab{i} = num2str(YtickNum(i));
end
set(gca,'YTickLabel',ytickLab)
ylabel('logD (\mum^2/s)')