function idx_choice = ROIClassChooseDlg(ROIstring,varargin)

if isempty(varargin)
    XYPos = [0.5, 0.5];
else
    XYPos = varargin{1};
end
Pos = [XYPos, 0.1,0.05];
Pos(1) = Pos(1) - (Pos(3)/2);
Pos(2) = Pos(2) - (Pos(4)/2);
d = dialog('Units','normalized','Position',Pos,'Name', 'Choose Class');

ROIstring2 = cell(size(ROIstring));
for i = 1:length(ROIstring)
    if iscell(ROIstring{i,:})
        ROIstring2{i,:} = ROIstring{i,:}{1,:};
    else
        ROIstring2{i,:} = ROIstring{i,:};
    end
end
ROIstring = ROIstring2;
txt = uicontrol('Parent',d,'Style','text','Units','normalized','Position',[0.05, 0.42, 0.9, 0.5],...
    'String','Choose a Class to apply to the current ROI');

popup = uicontrol('Parent',d, 'Style','popup','Units','normalized','Position', [0.1 0.12 0.35 0.5], ...
    'String',ROIstring,'Callback',@ROIchoicePop_callback,'Value',1);

btn = uicontrol('Parent',d,'Units','normalized','Position',[0.5,0.25,0.4,0.4], 'String', 'Select','Callback','delete(gcf)');

idx_choice = 1;
uiwait(d);

    function ROIchoicePop_callback(popup,callbackdata)
        
        idx_choice = get(popup,'Value');
        
    end
end