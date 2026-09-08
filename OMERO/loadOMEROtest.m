function imStack = loadOMEROtest()

serverIP = '165.112.226.159';
serverPort = 4064;
username = 'import.user';
password = 'import.user';

happ = LoadSingleMovieOMERO(username,password,serverIP,serverPort);
waitfor(happ);
imStack = getappdata(0,'OMEROimStack');
username = getappdata(0,'OMEROuser');
password = getappdata(0,'OMEROpwd');
serverIP = getappdata(0,'OMEROserverIP');
serverPort = getappdata(0,'OMEROserverPort');

% clear app;
% clear event;
% clear happ;
% unloadOmero();