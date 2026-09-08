% This script will take the tracks from trackTable and convert them to
% the format that can be used for spot-on analysis.


%% STEP 1: Load in the trackTable

clc; clear;

base_dir        = uigetdir; % Base directory where the mat file is located

[file, path]    = uigetfile(fullfile('**', 'trackTable_*.mat'), ...
    'Please select the trackTable file');

load(fullfile(path, file));

%% STEP 2: Save all sub-tracks to a mat file that can be used as Spot-On input

base_save_dir       = uigetdir(pwd, 'Select location to save the Spot-On files');

% Identify unique conditions
conditions          = unique(trackTable.condition);  

for i=1:length(conditions)
    idx = ismember(trackTable.condition, ...
        conditions{i});                                 % Identify cells corresponding to this condition
    
    restrictedTable = trackTable(idx, :);               % Create new table with only relevant rows

    
    % Make a new directory to save the files and assign this to the handle
    % save_dir
    mkdir(fullfile(base_save_dir, 'Spot-On_mat_files', ...
        [restrictedTable.cell_protein{1} '_' restrictedTable.condition{1}]));
    
    save_dir    = fullfile(base_save_dir, 'Spot-On_mat_files', ...
        [restrictedTable.cell_protein{1} '_' restrictedTable.condition{1}]);

    dt  = restrictedTable.interval(1); % Imaging interval inferred from trackTable

    X   = [restrictedTable.X{:}]; 

    % Initialize the trackedPar structure
    trackedPar  = struct;

     % Save all the track data to the trackedPar parameter
    for j = 1:length(X)
        trackedPar(j).xy            = X{j}; % xy coordinates in microns

        trackedPar(j).Frame         = [1:length(X{j})]';

        trackedPar(j).TimeStamp     = dt.*[0:length(X{j})-1]';
    end
    % Save this to a mat file
    save(fullfile(save_dir, sprintf('Spot-on_input_%s_%s.mat', restrictedTable.cell_protein{1}, ...
        conditions{i})), 'trackedPar', 'X', 'trackTable');

end