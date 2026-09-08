function plotTracks(Tracks, imageIx,varargin)
if isempty(varargin)
    ax_h = gca;
else
    ax_h = varargin{1};
end

delete(findobj(ax_h,'Color','g'));
ImIx = find (Tracks(:,3) == imageIx); % find tracks with a segment in the image
if ~isempty(ImIx)
    pIx = Tracks(ImIx,4);           %find the corrisponding particle index;
    for i =pIx'
        plotIx = find(Tracks(:,4) == i);% & Tracks(:,3) <= imageIx);
        hold(ax_h,'on');
        plot(ax_h,Tracks(plotIx,1),Tracks(plotIx,2),'g','LineWidth',2);
        hold(ax_h,'off');
    end
end