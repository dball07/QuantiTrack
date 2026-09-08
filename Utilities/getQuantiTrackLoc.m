function QT_location = getQuantiTrackLoc()

%finds the parent folder where QuantiTrack is installed.

%get the list of folders on the MATLAB search path

allPath = matlabpath;


ps = pathsep;

locInPath = strfind(allPath,'QuantiTrack');

locInPath = locInPath(1);

ps_loc = strfind(allPath,ps);

last_ps = find(ps_loc < locInPath,1,'last');
if ~isempty(last_ps)
    left_border = ps_loc(last_ps)+1;
else
    left_border = 1;
end


QT_location = allPath(left_border:locInPath);

QT_location = fileparts(QT_location);
