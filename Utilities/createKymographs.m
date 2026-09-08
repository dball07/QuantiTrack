function createKymographs(Results)

nImages = Results.Data.nImages;

for i = 1:nImages
    I(:,:,i) = Results.Process.filterStack(i).data;
end

I_x = max(I,[],2);
I_x = reshape(I_x,size(I_x,1),nImages);

I_y = max(I,[],1);
I_y = reshape(I_y,size(I_y,2),nImages);

figure; imagesc(I_x,[0,2000])
colormap(gray);

hold on

tracks = Results.Tracking.Tracks;
trackIDs = unique(tracks(:,4));
for i = 1:length(trackIDs)
    curTrk = tracks(tracks(:,4) == trackIDs(i),:);
    
    plot(curTrk(:,3),curTrk(:,2))
end
axis image
set(gca,'Xlim',[0, 600])
xlabel('Frame');
ylabel('X position (\mum)')

figure; imagesc(I_y,[0,2000])
colormap(gray);
hold on
for i = 1:length(trackIDs)
    curTrk = tracks(tracks(:,4) == trackIDs(i),:);
    plot(curTrk(:,3),curTrk(:,1))
end
axis image
set(gca,'Xlim',[0, 600])
xlabel('Frame');
ylabel('Y position (\mum)')

