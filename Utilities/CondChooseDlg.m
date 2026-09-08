function idx_choice = CondChooseDlg(CondString)

set(0,'Units','points');
dispPts = get(0,'ScreenSize');



XYPos = dispPts(3:4)./2;
Pos = [XYPos, 180,100];
Pos(1) = Pos(1) - (Pos(3)/2);
Pos(2) = Pos(2) - (Pos(4)/2);
d = dialog('Units','points','Position',Pos,'Name', 'Select one','Color',[0.65 0.65 0.65]);


txt = uicontrol('Parent',d,'Style','text','Position',[20 80 210 40],...
    'String','Choose a Condition to Analyze','BackgroundColor',[0.65 0.65 0.65]);

popup = uicontrol('Parent',d, 'Style','popup','Position', [75 70 100 25], ...
    'String',CondString,'Callback',@CondChoicePop_callback,'Value',1);

btn = uicontrol('Parent',d,'Position',[89 20 70 25], 'String', 'Select','Callback','delete(gcf)');

idx_choice = length(CondString);
uiwait(d);

    function CondChoicePop_callback(popup,callbackdata)
        
        idx_choice = get(popup,'Value');
        
    end
end