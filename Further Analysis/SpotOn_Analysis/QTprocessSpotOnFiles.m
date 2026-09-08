function summary_table = QTprocessSpotOnFiles(base_dir, Params, useParallel, figH)
    % This function processes Spot-On input files using parallel computing
    % and outputs a summary table where each row corresponds to the output
    % of SpotOn_core_vKW for one dataset.
    
    if nargin < 3 || isempty(useParallel)
        useParallel = 0;
    end

    if nargin < 4 
        figH = [];
    end

    % Change directory to the base directory
    cd(base_dir);

    % Create a list of locations that contain the mat files to be analyzed
    dir_list = dir(fullfile(base_dir, 'Spot-On_input_*.mat'));

    % Initialize a cell array to store results
    results = cell(length(dir_list), 1);

    % Parallel loop to process each file
    if ~isempty(figH)
        if useParallel == 1
            d = uiprogressdlg(figH,'Title','Processing SpotOn files',...
                'Message','Analyzing bootstrapped data with SpotOn','Indeterminate','on');
        else
            d = uiprogressdlg(figH,'Title','Processing SpotOn files',...
                'Message','Analyzing bootstrapped data with SpotOn', 'Value',0);
        end
    end

    if useParallel == 1
        
        parfor i = 1:length(dir_list)
            ParamsIn = Params;
            if ~contains(dir_list(i).name,'original')
                ParamsIn.DoPlots = 0;
                ParamsIn.SavePlot = 0;
            end

            results{i} = processSingleSpotOnFile(dir_list(i), base_dir, ParamsIn);
            
            
            fprintf('\n Dataset %d/%d DONE\n', i, length(dir_list));
        end
    else
        for i = 1:length(dir_list)
            ParamsIn = Params;
            if ~contains(dir_list(i).name,'original')
                ParamsIn.DoPlots = 0;
                ParamsIn.SavePlot = 0;
            end
            results{i} = processSingleSpotOnFile(dir_list(i), base_dir, ParamsIn);
            
            
            fprintf('\n Dataset %d/%d DONE\n', i, length(dir_list));
            d.Value = i/length(dir_list);

        end
    end

    % Combine all results into a summary table
    summary_table = vertcat(results{:});

    % Adjust for the untracked particles
    summary_table.trueFracBound     = summary_table.FracBound.*summary_table.N_tracked_particles./summary_table.N_detected_particles;

    % Adjust the confidence intervals
    for i=1:height(summary_table)
        summary_table.ci_trueFracBound{i}  = summary_table.ci_FracBound{i}...
            .*summary_table.N_tracked_particles(i)./summary_table.N_detected_particles(i); 
    end 

    % Only save the relevant fields to reduce file size
    keep_common = {'cell_protein','condition','N_cells','N_tracks', ...
        'N_detected_particles','N_tracked_particles', ...
        'D_bound','FracBound','FracFree','LocErr','trueFracBound'};
    nStates_summary = 2;
    if height(summary_table) > 0 && ismember('Params', summary_table.Properties.VariableNames)
        p_first = summary_table.Params{1};
        if isfield(p_first,'NumberOfStates'), nStates_summary = p_first.NumberOfStates; end
    end
    if nStates_summary == 3
        keep_cols = [keep_common, {'D_Free1','D_Free2','Frac_Free1'}];
    else
        keep_cols = [keep_common, {'D_Free'}];
    end
    keep_cols = keep_cols(ismember(keep_cols, summary_table.Properties.VariableNames));
    summary_table = summary_table(:, keep_cols);
end

function spotOnTable = processSingleSpotOnFile(file, base_dir, Params)
    % Process a single Spot-On input file and return a table with results

    % Navigate to the folder containing the file
    cd(file.folder);

    % Initialize data structure
    data_struct = struct([]);
    data_struct(1).path = [file.folder filesep];
    data_struct(1).workspaces = {file.name};
    data_struct(1).Include = [1];

    % Extract sample name
    tmp = find(file.name == '_', 2);
    SampleName = file.name(tmp(2)+1:end-4);
    SampleName(SampleName == '_') = ' ';

    % Set parameters
    
    Params.curr_dir = pwd; Params.SampleName = SampleName; Params.data_struct = data_struct;

    % Add Spot-On package paths
    addpath(genpath([pwd, filesep, 'SpotOn_package', filesep]));
    display('Added local paths for Spot-on core mechanics');

    % Run Spot-On core function
    [Output_struct] = SpotOn_core_vKW_QT(Params);

    % Load the spotOnTable from the mat file
    load(fullfile(file.folder, file.name), 'spotOnTable');

    % Extract output variables and confidence intervals
    output_vars = Output_struct.merged_model_params;
    ci = Output_struct.merged_model_params_ci;
    nStates = 2;
    if isfield(Params,'NumberOfStates'), nStates = Params.NumberOfStates; end
    fitsLocErr = isfield(Params,'FitLocError') && Params.FitLocError == 1;
    spotOnTable.Params{1} = Params;
    spotOnTable.Output_struct{1} = Output_struct;
    if nStates == 2
        spotOnTable.D_Free(1) = output_vars(1);
        spotOnTable.ci_D_Free{1} = ci(1,:);
        spotOnTable.D_bound(1) = output_vars(2);
        spotOnTable.ci_D_Bound{1} = ci(2,:);
        spotOnTable.FracBound(1) = output_vars(3);
        spotOnTable.ci_FracBound{1} = ci(3,:);
        spotOnTable.FracFree(1) = 1 - output_vars(3);
        if fitsLocErr
            spotOnTable.LocErr(1) = output_vars(4);
            spotOnTable.ci_LocErr{1} = ci(4,:);
        else
            spotOnTable.LocErr(1) = Params.LocError;
            spotOnTable.ci_LocErr{1} = [Params.LocError, Params.LocError];
        end
        spotOnTable.D_Free1(1) = NaN; spotOnTable.ci_D_Free1{1} = [NaN NaN];
        spotOnTable.D_Free2(1) = NaN; spotOnTable.ci_D_Free2{1} = [NaN NaN];
        spotOnTable.Frac_Free1(1) = NaN; spotOnTable.ci_Frac_Free1{1} = [NaN NaN];
    elseif nStates == 3
        spotOnTable.D_Free1(1) = output_vars(1);
        spotOnTable.ci_D_Free1{1} = ci(1,:);
        spotOnTable.D_Free2(1) = output_vars(2);
        spotOnTable.ci_D_Free2{1} = ci(2,:);
        spotOnTable.D_bound(1) = output_vars(3);
        spotOnTable.ci_D_Bound{1} = ci(3,:);
        spotOnTable.FracBound(1) = output_vars(4);
        spotOnTable.ci_FracBound{1} = ci(4,:);
        spotOnTable.Frac_Free1(1) = output_vars(5);
        spotOnTable.ci_Frac_Free1{1} = ci(5,:);
        spotOnTable.FracFree(1) = 1 - output_vars(4) - output_vars(5); % Frac_Free2
        spotOnTable.D_Free(1) = NaN; spotOnTable.ci_D_Free{1} = [NaN NaN];
        if fitsLocErr
            spotOnTable.LocErr(1) = output_vars(6);
            spotOnTable.ci_LocErr{1} = ci(6,:);
        else
            spotOnTable.LocErr(1) = Params.LocError;
            spotOnTable.ci_LocErr{1} = [Params.LocError, Params.LocError];
        end
    else
        error('QTprocessSpotOnFiles:unsupportedNumberOfStates', ...
            'NumberOfStates=%d is not supported (only 2 or 3).', nStates);
    end

    % Save the updated Spot-On table
    save(fullfile(file.folder, sprintf('Spot-On_output_%s', file.name(tmp(2)+1:end))), ...
        'spotOnTable', 'Output_struct');

    % Return to base directory
    cd(base_dir);
    %fprintf('\n Dataset %d DONE\n', i);
end
