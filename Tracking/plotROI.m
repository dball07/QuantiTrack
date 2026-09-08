function plotROI(ROI,varargin)

if isempty(varargin)
    ax_h = gca;
    selROI = 0;
elseif length(varargin) == 1
    ax_h = varargin{1};
    selROI = 0;
else
    ax_h = varargin{1};
    selROI = varargin{2};
end


delete(findobj(ax_h,'LineWidth',1.1));
origCO = get(groot,'DefaultAxesColorOrder');
origCO = repmat(origCO,[100,1]);

% axes(ax_h);
for i = 1:length(ROI)
    hold(ax_h,'on');
    if ~isempty(ROI{i,:})
        if i == selROI
            plot(ax_h,[ROI{i,:}(:,1);ROI{i,:}(1,1)],[ROI{i,:}(:,2);ROI{i,:}(1,2)],'LineWidth',1.1,'Color',[1 1 1]);
        else
            plot(ax_h,[ROI{i,:}(:,1);ROI{i,:}(1,1)],[ROI{i,:}(:,2);ROI{i,:}(1,2)],'LineWidth',1.1,'Color',origCO(i,:));
        end
    end
    hold(ax_h, 'off');
end