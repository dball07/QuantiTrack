function [trackTable_tmp,parentpath,savename] = genFullTrackTable(varargin)

if isempty(varargin)
    parentpath = uigetdir('Select directory where data are located');

    % Define image acquisition parameters
    % The popupdialog will ask the user for the following parameters:
    %
    % * Pixel size ($$\mu$m$)
    % * Exposure time (ms)
    % * Acquisition interval (ms)
    %
    % These parameters will be saved in the |trackTable| table.

    prompt = {'Enter pixel size (um/pixel):', 'Enter exposure time (ms):', 'Enter acquisition interval (ms):'};
    dlgtitle = 'Acquisition parameter input';
    dims = [1 35];
    definput = {'0.144', '10', '20'};
    acqParam  = inputdlg(prompt, dlgtitle, dims, definput);
    if isempty(acqParam)
        return
    end
    %
    % Aggregate track information from individual track files
    % Ask the user to define the split length. Tracks smaller than the split length
    % will be deleted.
    %
    % In this section, we will perform the following tasks:
    %%
    % # Select all the tracked mat files that we would like to analyze
    % # Extract tracking parameters, and tracks
    % # Save tracked data for each cell to a different row of |trackTable|
    % # Assign unique trackID and cellID to each track. See notes below.
    %%
    % Notes:
    %
    % * It is essential that each file name be unique. This helps us assign unique
    % IDs to the cells.
    % * Each track is assigned two IDs: a trackID and cellID, which together will
    % help uniquely identify the origin of each subtrack

    % prompt = {'Enter the split length (frames):'};
    % dlgtitle = 'Shortest track input';
    % dims = [1 35];
    % definput = {'7'};
    % splitParam = inputdlg(prompt, dlgtitle, dims, definput);
    % if isempty(splitParam)
    %     return
    % end
    % splitLength_base = str2double(splitParam{1});   % split length to filter tracks

    pixelSize_base   = str2double(acqParam{1});     % pixel size
    expTime  = str2double(acqParam{2});
    intervalTime = str2double(acqParam{3});
else
    parentpath = varargin{1};
    pixelSize_base = varargin{2};
    expTime = varargin{3};
    intervalTime = varargin{4};

end
[~,parentName] = fileparts(parentpath);

cell_protein_base = parentName; % Extract the cell line and the protein from the folder name

condPath = FindDirectory(parentpath);
ind2rem = [];
for i = 1:length(condPath)
    if strfind(condPath{i},'results')
        ind2rem = [ind2rem; i];
    end
end
condPath(ind2rem) = [];

numConds = length(condPath);
% varNames = {'cell_protein', 'condition', 'session', 'name', 'pixelSize',...
%     'exposure','interval','trackingParam', 'splitLength', 'X', 'trackID',...
%     'cellID'};
% Initialize the table

counter     = 1;                        % pseudo variable to keep track of all the cells

trackCount = 1;
dwait_cond = waitbar(0,'Processing Condition ','Name','Generating TrackTable');
pos_dwaitCond = get(dwait_cond,'Position');

for i=1:numConds
    
    waitbar((i-1)/numConds,dwait_cond,['Processing Condition ', num2str(i), ' of ', num2str(numConds)]);

    [p, condition_base]  = fileparts(condPath{i});       % Extract condition from the path

    sessionPath     = FindDirectory(condPath{i});   % Find directories for all the sessions

    numSessions     = length(sessionPath);          % Number of separate experiments

    %     fprintf('\n')
    disp('-------------------------------------------------------');
    fprintf('Condition %.1d of %.1d: %s\n',i, numConds, condition_base);
    disp('-------------------------------------------------------');
    dwait_session = waitbar(0,'Processing Session ','Name','Generating TrackTable');
    pos_dwaitSess = get(dwait_session,'Position');
    pos_dwaitSess2 = pos_dwaitSess;
    pos_dwaitSess2(2) = pos_dwaitCond(2) + pos_dwaitCond(4);
    set(dwait_session,'Position',pos_dwaitSess2);

    for j=1:numSessions
        waitbar((j-1)/numSessions,dwait_session,['Processing Session ', num2str(j), ' of ', num2str(numSessions)]);
        [p, session_base] = fileparts(sessionPath{j});   % Extract the session information from the path

        %         files = uigetfile(fullfile(sessionPath{j}, '*.mat'), 'MultiSelect', 'on'); % Get list of track mat files for this session
        %         if ~iscell(files)
        %             files2{1} = files;
        %             files = files2;
        %         end
        files = dir([sessionPath{j}, filesep,'*.mat']);
        fprintf('Session %.1d (%s): ', j, session_base);
        str3 = sprintf('0/%.1d complete\n',length(files));
        strLen3 = length(str3);
        fprintf('0/%.1d complete\n',length(files));

        dwait_files = waitbar(0,'Processing File ','Name','Generating TrackTable');
        pos_dwaitFiles = get(dwait_files,'Position');
        pos_dwaitFiles2 = pos_dwaitFiles;
        pos_dwaitFiles2(2) = pos_dwaitSess2(2) + pos_dwaitSess2(4);
        set(dwait_files,'Position',pos_dwaitFiles2);
        for k = 1:length(files)
            waitbar((k-1)/length(files),dwait_files,['Processing File ', num2str(k), ' of ', num2str(length(files))]);
            IN = load(fullfile(sessionPath{j}, files(k).name));                           % Load the track results
            SaveParams.lastCellProtein = cell_protein_base;
            SaveParams.lastCondition = condition_base;
            SaveParams.lastSession = session_base;
            SaveParams.lastName = files(k).name;
            SaveParams.pixelSize = pixelSize_base;
            SaveParams.exposureTime = expTime;
            SaveParams.frameTime = intervalTime;
            trackTable_tmp = generateTrackTable(IN.Results,SaveParams);
            if i == 1 && j == 1 && k == 1
                trackTable = trackTable_tmp;
            else
                last_cellID = trackTable.cellID(height(trackTable));
                last_trackID = trackTable.trackID{height(trackTable)}(end);
                last_movieID = trackTable.movieID(height(trackTable));

                trackTable_tmp.cellID = trackTable_tmp.cellID + last_cellID;
                trackTable_tmp.movieID = trackTable_tmp.movieID + last_movieID;
                for m = 1:height(trackTable_tmp)
                    trackTable_tmp.trackID{m} = trackTable_tmp.trackID{m} + last_trackID;
                end

                trackTable = [trackTable; trackTable_tmp];
            end
            fprintf(repmat('\b',1,strLen3));
            str3_2 = sprintf('%.1d/%.1d complete\n', k, length(files));
            %                 str3 = strcat(str3_1,str3_2);
            strLen3 = length(str3_2);
            fprintf('%.1d/%.1d complete\n', k, length(files));
        end
        close(dwait_files);

        %         fprintf('\n');

    end
    close(dwait_session)
    fprintf('\n');
end
close(dwait_cond);

%
% Save the table
% |trackTable| is saved in a timestamped file, so that multiple runs do not
% overwrite the file.

savename  = sprintf('trackTable_%s_%s.mat', cell_protein_base, ...
    datestr(now, 'yyyy-mm-dd_THHMM'));
% Generate file name containing cell_protein and the current date and time
save(fullfile(parentpath, savename), "trackTable", '-v7.3');