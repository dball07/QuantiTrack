% This script will take the tracks from summary_table and convert them to
% the format that can be used for spot-on analysis.


%% STEP 1: Load in the summary_table

clc; clear;

base_dir        = uigetdir; % Base directory where the mat file is located

[file, path]    = uigetfile(fullfile('**', 'summary_table_*.mat'), ...
    'Please select the summary table file');

load(fullfile(path, file));

%% STEP 2: Save all sub-tracks to a mat file that can be used as Spot-On input

base_save_dir        = uigetdir(pwd, 'Select location to save the Spot-On files');

dt  = 0.2; % Change for different datasets

for i=1:height(summary_table)

    % Load the split tracks from the summary_table
    X           = summary_table.splitX{i};
    
    % Initialize the trackedPar structure
    trackedPar  = struct;

    nFrames     = summary_table.splitLength(i); % number of frames per track

    % Make a new directory to save the files and assign this to the handle
    % save_dir
    mkdir(fullfile(base_save_dir, 'Spot-On_mat_files', [summary_table.cell_protein{i} '_' summary_table.condition{i}]));

    save_dir    = fullfile(base_save_dir, 'Spot-On_mat_files', [summary_table.cell_protein{i} '_' summary_table.condition{i}]);

    % Save all the track data to the trackedPar parameter
    for j = 1:length(X)
        trackedPar(j).xy            = X{j}; % xy coordinates in microns

        trackedPar(j).Frame         = [1:nFrames]';

        trackedPar(j).TimeStamp     = dt.*[0:nFrames-1]';
    end

    % Save this to a mat file
    save(fullfile(save_dir, sprintf('Spot-on_input_%s_%s.mat', summary_table.cell_protein{i}, ...
        summary_table.condition{i})));

    fprintf('\n Dataset %d/%d Complete\n', i, height(summary_table));
end

%% STEP 3: Create a separate file for each state

base_save_dir        = uigetdir(pwd, 'Select location to save the Spot-On files');

dt  = 0.2; % Change for different datasets

for i=1:height(summary_table)
    cell_protein    = [summary_table.cell_protein{i} ' ' summary_table.condition{i}];
    cell_protein(cell_protein == '_') = ' ';

    optimalState    = summary_table.optimalState{i};
    deltaPP_thresh  = summary_table.deltaPP_thresh(i);
    deltaPP_states  = summary_table.states_deltaPP{i};
    pp              = summary_table.posteriorProb{i};
    mpp             = summary_table.maxPosteriorProb{i};
    sort_pp         = sort(pp, 2, 'descend');
    delta_pp        = sort_pp(:,1) - sort_pp(:,2);
    
%     % Define deltaPP only for the lowest two states
%     delta_pp12      = abs(pp(:,deltaPP_states(1)) - pp(:,deltaPP_states(2)));

    trackID         = summary_table.trackID{i};
    splitID         = summary_table.splitID{i};
    optimalState    = optimalState + 100; % dummy change of variable

    

    % Redefine the states to states 1, 2, etc.
    for j=1:length(deltaPP_states)
%         optimalState(optimalState == deltaPP_states(j) + 100 & ...
%             delta_pp > deltaPP_thresh) = j;
        optimalState(optimalState == deltaPP_states(j) + 100) = j;
    end
    
    % Assign all other states to another state
    optimalState(optimalState>100)  = 1  + length(deltaPP_states);


    % Load the split tracks from the summary_table
    X           = summary_table.splitX{i};

    nFrames     = summary_table.splitLength(i); % number of frames per track

    for m=1:2

        % Make a new directory to save the files and assign this to the handle
        % save_dir
        mkdir(fullfile(base_save_dir, 'Spot-On_mat_files', [summary_table.cell_protein{i} '_' summary_table.condition{i}],...
            sprintf('State_%d', m)));
    
        save_dir    = fullfile(base_save_dir, 'Spot-On_mat_files', [summary_table.cell_protein{i} '_' summary_table.condition{i}],...
            sprintf('State_%d', m));

        % Initialize the trackedPar structure
        trackedPar  = struct;

        % Indices of all subtracks that satisfy both deltaPP and
        % optimalState constraints
        idx = find(delta_pp > deltaPP_thresh & optimalState == m);

        % Save all the track data to the trackedPar parameter
        for j = 1:length(idx)
            trackedPar(j).xy            = X{idx(j)}; % xy coordinates in microns
    
            trackedPar(j).Frame         = [1:nFrames]';
    
            trackedPar(j).TimeStamp     = dt.*[0:nFrames-1]';
        end
    
        % Save this to a mat file
        save(fullfile(save_dir, sprintf('Spot-on_input_%s_%s_state_%d.mat', summary_table.cell_protein{i}, ...
            summary_table.condition{i}, m)));
    end
    fprintf('\n Dataset %d/%d Complete\n', i, height(summary_table));
end


%% STEP 4: Save all full length tracks to a mat file that can be used as Spot-On input

base_save_dir        = uigetdir(pwd, 'Select location to save the Spot-On files');

dt  = 0.2; % Change for different datasets

for i=1:height(summary_table)

    % Load the split tracks from the summary_table
    X           = summary_table.X{i};
    
    % Initialize the trackedPar structure
    trackedPar  = struct;

    % Make a new directory to save the files and assign this to the handle
    % save_dir
    mkdir(fullfile(base_save_dir, 'Spot-On_mat_files', [summary_table.cell_protein{i} '_' summary_table.condition{i}], 'full_length_tracks'));

    save_dir    = fullfile(base_save_dir, 'Spot-On_mat_files', [summary_table.cell_protein{i} '_' summary_table.condition{i}], 'full_length_tracks');

    % Save all the track data to the trackedPar parameter
    for j = 1:length(X)
        nFrames     = length(X{j}); % number of frames per track
        
        trackedPar(j).xy            = X{j}; % xy coordinates in microns

        trackedPar(j).Frame         = [1:nFrames]';

        trackedPar(j).TimeStamp     = dt.*[0:nFrames-1]';
    end

    % Save this to a mat file
    save(fullfile(save_dir, sprintf('Spot-on_input_full_length_tracks_%s_%s.mat', summary_table.cell_protein{i}, ...
        summary_table.condition{i})));

    fprintf('\n Dataset %d/%d Complete\n', i, height(summary_table));
end