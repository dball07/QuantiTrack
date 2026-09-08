function ChangeAppPosition(fig_h,Qtrack_pos)



fig_h.Units = 'normalized';


pos_app = fig_h.Position;
pos_app(1) = Qtrack_pos(1);
pos_app(2) = Qtrack_pos(2) + Qtrack_pos(4) - pos_app(4);%(Qtrack_pos(2) + (Qtrack_pos(2) + Qtrack_pos(4)))/2 - pos_app(4)/2 + (Qtrack_pos(4)/2 - pos_app(4)/2);
if pos_app(1)+pos_app(3) > 1
    pos_app(1) = 0.0;
%     pos_app(3) = 0.95;
end
if pos_app(2)+pos_app(4) > 1
    pos_app(2) = 0.0;
%     pos_app(4) = 0.95;
end


fig_h.Position = pos_app;
fig_h.Units = 'pixels';
drawnow;