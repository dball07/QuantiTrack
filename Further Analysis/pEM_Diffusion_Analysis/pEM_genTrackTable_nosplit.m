function [trackTable,parentpath,savename] = pEM_genTrackTable_nosplit(varargin)

if isempty(varargin)
    parentpath = uigetdir('Select directory where data are located');
    [tmp,parentName] = fileparts(parentpath);
    
    cell_protein_base = parentName; % Extract the cell line and the protein from the folder name
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
    definput = {'0.104', '10', '200'};
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
    
%     prompt = {'Enter the split length (frames):'};
%     dlgtitle = 'Shortest track input';
%     dims = [1 35];
%     definput = {'7'};
%     splitParam = inputdlg(prompt, dlgtitle, dims, definput);
%     if isempty(splitParam)
%         return
%     end
%     splitLength_base = str2double(splitParam{1});   % split length to filter tracks

    pixelSize_base   = str2double(acqParam{1});     % pixel size
    expTime  = str2double(acqParam{2});
    intervalTime = str2double(acqParam{3});
end

condPath = FindDirectory(parentpath);
numConds = length(condPath); 
% varNames = {'cell_protein', 'condition', 'session', 'name', 'pixelSize',...
%     'exposure','interval','trackingParam', 'splitLength', 'X', 'trackID',...
%     'cellID'};
                   % Initialize the table 

counter     = 1;                        % pseudo variable to keep track of all the cells

trackCount = 1;

for i=1:numConds
    [p, condition_base]  = fileparts(condPath{i});       % Extract condition from the path
    
    sessionPath     = FindDirectory(condPath{i});   % Find directories for all the sessions
    
    numSessions     = length(sessionPath);          % Number of separate experiments
    
    for j=1:numSessions
        [p, session_base] = fileparts(sessionPath{j});   % Extract the session information from the path
        
%         files = uigetfile(fullfile(sessionPath{j}, '*.mat'), 'MultiSelect', 'on'); % Get list of track mat files for this session
%         if ~iscell(files)
%             files2{1} = files;
%             files = files2;
%         end
        files = dir([sessionPath{j}, filesep,'*.mat']);
        
        for k = 1:length(files)
            
            IN = load(fullfile(sessionPath{j}, files(k).name));                           % Load the track results
            
            cell_protein{counter,:}    = cell_protein_base;                 % E.g. D4_pHalo-GR
            condition{counter,:}       = condition_base;
            session{counter,:}         = session_base;                      % Save the experimental session
            
            name{counter,:}            = files(k).name;                     % File name
            pixelSize(counter,:)       = pixelSize_base;         % pixel size in um/pixel
            exposure(counter,:)        = expTime/1000;    % exposure time in sec
            interval(counter,:)        = intervalTime/1000;    % acquisition time in sec
            if isfield(IN,'Results')
                trackingParam{counter,:}   = IN.Results.Parameters.Tracking;  % Tracking parameters
            else
                trackingParam{counter,:}   = [];
            end
            splitLength(counter,:)     = 0;                  % Split length. All the tracks smaller than this are discarded
            if isfield(IN,'Results')
                Tracks                          = IN.Results.Tracking.Tracks;      % Extract the tracks from the results folder. 
            else
                Tracks                  = IN.tracks;
            end
            
            % Remove all tracks smaller than the split length
            [G, trackID_tmp]                    = groupcounts(Tracks(:,4));
%             trackID_tmp(G<splitLength_base)              = [];                           
            
            trackID_mat = [];
            
            X_tmp = {};
            
            for l=1:length(trackID_tmp)
                idx     = find(Tracks(:,4)==trackID_tmp(l));        % Find indices of all the positions for the track trackID(idx)
                if isfield(IN,'Results')
                    x       = Tracks(idx,1)*pixelSize_base;              % Convert the coordinates to um
                    y       = Tracks(idx,2)*pixelSize_base;              % Convert the coordinates to um
                    X_tmp{l}    = [x y];
                else
                    x       = Tracks(idx,1)*1e6;              % Convert the coordinates to um
                    y       = Tracks(idx,2)*1e6;              % Convert the coordinates to um
                    t       = Tracks(idx,3);
                    X_tmp{l}    = [x y t];
                end
                
                
                trackID_mat = [trackID_mat; trackCount];
                trackCount = trackCount +1;
            end
            
            X{counter,:}       = X_tmp;                    % All the tracks for cell # counter
            trackID{counter,:} = trackID_mat;          % IDs for all tracks
            cellID(counter,:)  = counter;              % Corresponding ID for cell
            counter = counter+1;
            
            fprintf('\n Condition %.1d, session %.1d, %.1d/%.1d complete\n', i, j, k,length(files));
        end
        
    end
end
trackTable  = table(cell_protein, condition, session, name, pixelSize,...
    exposure,interval,trackingParam, splitLength, X, trackID,cellID); 
% 
% Save the table 
% |trackTable| is saved in a timestamped file, so that multiple runs do not 
% overwrite the file.

savename  = sprintf('trackTable_%s_Split%d_%s.mat', cell_protein_base, ...
    0, datestr(now, 'yyyy-mm-dd_THHMM'));
% Generate file name containing cell_protein and the current date and time
save(fullfile(parentpath, savename), "trackTable", '-v7.3');