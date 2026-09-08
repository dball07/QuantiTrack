function QuantiTrack_installer()

%Adds the QuantiTrack files to the MATLAB search path. Should be run after
%changing to the QuantiTrack main folder. 

curFold = pwd;

if ~strcmp(curFold(end-10:end),'QuantiTrack')
    errordlg('Change to the QuantiTrack folder before running QuantiTrack_installer ');
    return
end
QT_parent = fileparts(pwd);

curMatPath = matlabpath;
if ~contains(curMatPath,[pathsep,QT_parent,pathsep]) && ~contains(curMatPath,[QT_parent,pathsep])
    addpath(QT_parent,'-begin');
end

QuantiTrack_contents = dir(fullfile(pwd,'**'));
%create a progress bar
d = waitbar(0,'Adding QuantiTrack to the Matlab search path...','Name','QuantiTrack Installation');

%Add all of the folders to the search path
for i = 1:length(QuantiTrack_contents)
    
    if QuantiTrack_contents(i).isdir && ~strcmp(QuantiTrack_contents(i).name,'.') && ~strcmp(QuantiTrack_contents(i).name,'..') ...
            && ~strcmp(QuantiTrack_contents(i).name(1),'@') && ~strcmp(QuantiTrack_contents(i).name(1),'+') ...
            && ~strcmpi(QuantiTrack_contents(i).name,'private')
        Fold_tmp = QuantiTrack_contents(i).name;
        parent = QuantiTrack_contents(i).folder;
        if ~contains(curMatPath,[pathsep,fullfile(parent,Fold_tmp),pathsep])
            addpath(fullfile(parent,Fold_tmp),'-begin');
        end
    end
    %update the progress bar
    waitbar(i/(length(QuantiTrack_contents)+1),d);
end

if ~contains(curMatPath,[pathsep,curFold,pathsep])
    addpath(curFold,'-begin');
    waitbar(1,d);
end
savepath;

%save a local copy of the parameters that can be edited without affecting
%the distributed defaults
QT_location = getQuantiTrackLoc();
LocDefaultExists = dir(fullfile(QT_location,'QuantiTrack_localDefaults.mat'));

%if we don't have the local version, then we will create it and save
if isempty(LocDefaultExists)
    %Load in the master default parameters
    Profiles_in = load('QuantiTrack_defaults.mat');
    lastProfile = 1; %to specify which profile was last used
    %ask the user for the location to store all tracking files
    trackingSaveDir = uigetdir(pwd,['Select the Location where all Tracking ' ...
        'files will be saved']);
    Profiles = Profiles_in.Profiles;
    Profiles(1).trackingSaveDir = trackingSaveDir;

    save(fullfile(QT_location,'QuantiTrack_localDefaults.mat'), 'Profiles', 'lastProfile');

else
    %This part should generally not be needed, only including for initial
    %testing where versions without Profiles were installed
    IN = load(fullfile(QT_location,'QuantiTrack_localDefaults.mat'));
    if ~isfield(IN,'Profiles')
        %Load in the master default parameters
        Profiles_in = load('QuantiTrack_defaults.mat');
        lastProfile = 1; %to specify which profile was last used
        %Here we will use the previously saved database location
        Profiles = Profiles_in.Profiles;
        Profiles(1).trackingSaveDir = IN.trackingSaveDir;
        Profiles(1).Anisotropy_binT = Profiles(1).frameTime;
        Profiles(1).Anisotropy_binD = 1.5e-3;
        Profiles(1).Anisotropy_bootIter = 50;
        save(fullfile(QT_location,'QuantiTrack_localDefaults.mat'), 'Profiles', 'lastProfile');
    end
end



%close the progress bar window
delete(d);




