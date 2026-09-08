% This script is adapted from SpotOn_main.m by Hansen et al. This has been
% written specifically for addressing the reviewers' comments on the 2
% state SMT paper (Wagh, Stavreva. et al 2022). To begin the process ensure
% that you have run convert_summary_table_tracks_to_spotOn_format. This
% script starts from the directory Spot-On_mat_files and expects the
% following structure:
% Spot-On_mat_files >> <cell_protein folder> >> <all_tracks> OR <State_XX>
% >> mat file ready for SpotOn

% Edit 2023/08/18 – Calculate diffusive fraction from fast data

clear; clc; clearvars -global; close all; 

%% Step 1: Define the parameters 


%%%%% Acquisition Parameters: 
TimeGap = 12; % delay between frames in milliseconds
dZ = 0.700; % The axial observation slice in micrometers; Rougly 0.7 um for the example data (HiLo)
GapsAllowed = 0; % The number of allowed gaps in the tracking

%%%%% Data Processing Parameters:
TimePoints = 4; % How many delays to consider: N timepoints yield N-1 delays
BinWidth = 0.010; % Bin Width for computing histogram in micrometers (only for PDF; Spot-On uses 1 nm bins for CDF)
UseEntireTraj = 1; % If UseEntireTraj=1, all dispplacements from all trajectories will be used; If UseEntireTraj=0, only the first X displacements will be used. NB. this variable was previously called UseAllTraj but has been renamed UseEntireTraj
JumpsToConsider = 6; % If UseEntireTraj=0, the first JumpsToConsiders displacements for each dT where possible will be used. 
MaxJumpPlotPDF = 0.6; % the cut-off for displaying the displacement histograms plots
MaxJumpPlotCDF = 0.6; % the cut-off for displaying the displacement CDF plots
MaxJump = 5.05; % the overall maximal displacements to consider in micrometers
SavePlot = 1; % if SavePlot=1, key output plots will be saved to the folder "SavedPlots"; Otherwise set SavePlot = 0;
DoPlots = 1; % if DoPlots=1, Spot-On will output plots, but not if it's zero. Avoiding plots speeds up Spot-On for batch analysis

%%%%% Model Fitting Parameters:
ModelFit = 2; %Use 1 for PDF-fitting; Use 2 for CDF-fitting
DoSingleCellFit = 0; %Set to 1 if you want to analyse all single cells individually (slow). 
%NumberOfStates = 3; % If NumberOfStates=2, a 2-state model will be used; If NumberOfStates=3, a 3-state model will be used 
FitIterations = 3; % Input the desired number of fitting iterations (random initial parameter guess for each)
FitLocError = 1; % If FitLocError=1, the localization error will fitted from the data
FitLocErrorRange = [0.010 0.075]; % min/max for model-fitted localization error in micrometers.
LocError = 0.035; % If FitLocError=0, LocError in units of micrometers will be used. 
UseWeights = 1; % If UseWeights=0, all TimePoints are given equal weights. If UseWeights=1, TimePoints are weighted according to how much data there is. E.g. 1dT will be weighted more than 5dT.
D_Free_2State = [0.05 1]; % min/max Diffusion constant for Free state in 2-state model (units um^2/s)
D_Bound_2State = [0.0001 0.05]; % min/max Diffusion constant for Bound state in 2-state model (units um^2/s)
D_Free1_3State = [0.05 1]; % min/max Diffusion constant #1 for Free state in 3-state model (units um^2/s)
D_Free2_3State = [0.0001 0.1]; % min/max Diffusion constant #2 for Free state in 3-state model (units um^2/s)
D_Bound_3State = [0.0001 0.1]; % min/max Diffusion constant for Bound state in 3-state model (units um^2/s)

%% Step 2: Identify datasets for processing – classified subtracks only

base_dir    = uigetdir(pwd, 'Choose the Spot-On_mat_files_directory');

cd(base_dir);

%%%% Create a list of locations that contain the mat files to be analyzed
dir_list    = dir(fullfile(base_dir, '*', 'State_*', 'Spot-on_input*.mat'));

SpotOn_table    = table;

tic;
for i=1:length(dir_list)
    close all;

    data_struct = struct([]);

    cd(dir_list(i).folder); % Navigate to working directory

    data_struct(1).path = [dir_list(i).folder filesep]; % Path of the dataset
    data_struct(1).workspaces = {dir_list(i).name}; % Name of the file

    data_struct(1).Include = [1]; 

    tmp         = find(dir_list(i).name=='_', 2);
    SampleName = dir_list(i).name(tmp(2)+1:end-4);
    SampleName(SampleName == '_')   = ' ';

    NumberOfStates  = 2; % Fit to three states

    Params = struct(); % Use Params to feed all the relevant data/parameters into the relevant functions

    Params.TimeGap = TimeGap; Params.dZ = dZ; Params.GapsAllowed = GapsAllowed; Params.TimePoints = TimePoints; Params.BinWidth = BinWidth; Params.UseEntireTraj = UseEntireTraj; Params.DoPlots = DoPlots; Params.UseWeights = UseWeights;
    Params.JumpsToConsider = JumpsToConsider; Params.MaxJumpPlotPDF = MaxJumpPlotPDF; Params.MaxJumpPlotCDF = MaxJumpPlotCDF; Params.MaxJump = MaxJump; Params.SavePlot = SavePlot; Params.ModelFit = ModelFit;
    Params.DoSingleCellFit = DoSingleCellFit; Params.FitIterations = FitIterations; Params.FitLocError = FitLocError; Params.FitLocErrorRange = FitLocErrorRange; Params.LocError = LocError; Params.NumberOfStates = NumberOfStates;
    Params.D_Free_2State = D_Free_2State; Params.D_Bound_2State = D_Bound_2State; Params.D_Free1_3State = D_Free1_3State; Params.D_Free2_3State = D_Free2_3State; Params.D_Bound_3State = D_Bound_3State;
    Params.curr_dir = pwd; Params.SampleName = SampleName; Params.data_struct = data_struct;

    % add the relevant paths
    addpath(genpath([pwd, filesep, 'SpotOn_package', filesep])); 
    display('Added local paths for Spot-on core mechanics');
    [Output_struct] = SpotOn_core_vKW(Params);

    %%%% Save data to the SpotOn_table
    SpotOn_table.cell_protein{i}    = SampleName;

    output_vars                     = Output_struct.merged_model_params;

    SpotOn_table.Params{i}          = Params;

    SpotOn_table.D_Free(i)      = output_vars(1);
    SpotOn_table.D_bound(i)     = output_vars(2);
    SpotOn_table.FracFree(i)    = 1 - output_vars(3);
    SpotOn_table.FracBound(i)   = output_vars(3);
    SpotOn_table.LocErr(i)      = output_vars(4);

    save(fullfile(dir_list(i).folder, sprintf('Spot-on_output_%s', dir_list(i).name(tmp(2)+1:end))), 'Output_struct', 'Params');

    cd(base_dir);
    fprintf('\n Dataset %d/%d DONE\n', i, length(dir_list));
end

save(fullfile(base_dir, 'SpotOn_table_classified_tracks.mat'), 'SpotOn_table');
toc;
%% Run on all subtracks

base_dir    = uigetdir(pwd, 'Choose the Spot-On_mat_files_directory');

cd(base_dir);

%%%% Create a list of locations that contain the mat files to be analyzed
dir_list    = dir(fullfile(base_dir, '*', 'all_tracks', 'Spot-on_input*.mat'));

SpotOn_table    = table;

for i=1:length(dir_list)
    close all;

    data_struct = struct([]);

    cd(dir_list(i).folder); % Navigate to working directory

    data_struct(1).path = [dir_list(i).folder filesep]; % Path of the dataset
    data_struct(1).workspaces = {dir_list(i).name}; % Name of the file

    data_struct(1).Include = [1]; 

    tmp         = find(dir_list(i).name=='_', 2);
    SampleName = dir_list(i).name(tmp(2)+1:end-4);
    SampleName(SampleName == '_')   = ' ';

    NumberOfStates  = 3; % Fit to three states

    Params = struct(); % Use Params to feed all the relevant data/parameters into the relevant functions

    Params.TimeGap = TimeGap; Params.dZ = dZ; Params.GapsAllowed = GapsAllowed; Params.TimePoints = TimePoints; Params.BinWidth = BinWidth; Params.UseEntireTraj = UseEntireTraj; Params.DoPlots = DoPlots; Params.UseWeights = UseWeights;
    Params.JumpsToConsider = JumpsToConsider; Params.MaxJumpPlotPDF = MaxJumpPlotPDF; Params.MaxJumpPlotCDF = MaxJumpPlotCDF; Params.MaxJump = MaxJump; Params.SavePlot = SavePlot; Params.ModelFit = ModelFit;
    Params.DoSingleCellFit = DoSingleCellFit; Params.FitIterations = FitIterations; Params.FitLocError = FitLocError; Params.FitLocErrorRange = FitLocErrorRange; Params.LocError = LocError; Params.NumberOfStates = NumberOfStates;
    Params.D_Free_2State = D_Free_2State; Params.D_Bound_2State = D_Bound_2State; Params.D_Free1_3State = D_Free1_3State; Params.D_Free2_3State = D_Free2_3State; Params.D_Bound_3State = D_Bound_3State;
    Params.curr_dir = pwd; Params.SampleName = SampleName; Params.data_struct = data_struct;

    % add the relevant paths
    addpath(genpath([pwd, filesep, 'SpotOn_package', filesep])); 
    display('Added local paths for Spot-on core mechanics');
    [Output_struct] = SpotOn_core_vKW(Params);

    %%%% Save data to the SpotOn_table
    SpotOn_table.cell_protein{i}    = SampleName;

    output_vars                     = Output_struct.merged_model_params;

    SpotOn_table.Params{i}          = Params;

    SpotOn_table.D_Free(i)     = output_vars(1);
    SpotOn_table.D_state2(i)     = max([output_vars(2) output_vars(3)]);
    SpotOn_table.D_state1(i)     = min([output_vars(3) output_vars(2)]);
    SpotOn_table.Frac_Free(i)   = output_vars(5);
    SpotOn_table.Frac_state2(i)   = 1 - output_vars(4) - output_vars(5);
    
    if min([output_vars(3) output_vars(2)]) == output_vars(3)
        SpotOn_table.Frac_state1(i)   = output_vars(4);
        SpotOn_table.Frac_state2(i)   = 1 - output_vars(4) - output_vars(5);
    elseif min([output_vars(3) output_vars(2)]) == output_vars(2)
        SpotOn_table.Frac_state2(i)   = output_vars(4);
        SpotOn_table.Frac_state1(i)   = 1 - output_vars(4) - output_vars(5);
    end
    SpotOn_table.LocErr(i)      = output_vars(6);

    save(fullfile(dir_list(i).folder, sprintf('Spot-on_output_%s', dir_list(i).name(tmp(2)+1:end))), 'Output_struct', 'Params');

    cd(base_dir);

    fprintf('\n Dataset %d/%d DONE\n', i, length(dir_list));
end

save(fullfile(base_dir, 'SpotOn_table_all_tracks_v2.mat'), 'SpotOn_table');

%% Run on full length tracks


%%%%% Acquisition Parameters: 
TimeGap = 12; % delay between frames in milliseconds
dZ = 0.700; % The axial observation slice in micrometers; Rougly 0.7 um for the example data (HiLo)
GapsAllowed = 0; % The number of allowed gaps in the tracking

%%%%% Data Processing Parameters:
TimePoints = 7; % How many delays to consider: N timepoints yield N-1 delays
BinWidth = 0.010; % Bin Width for computing histogram in micrometers (only for PDF; Spot-On uses 1 nm bins for CDF)
UseEntireTraj = 1; % If UseEntireTraj=1, all dispplacements from all trajectories will be used; If UseEntireTraj=0, only the first X displacements will be used. NB. this variable was previously called UseAllTraj but has been renamed UseEntireTraj
JumpsToConsider = 7; % If UseEntireTraj=0, the first JumpsToConsiders displacements for each dT where possible will be used. 
MaxJumpPlotPDF = 0.6; % the cut-off for displaying the displacement histograms plots
MaxJumpPlotCDF = 0.6; % the cut-off for displaying the displacement CDF plots
MaxJump = 5.05; % the overall maximal displacements to consider in micrometers
SavePlot = 1; % if SavePlot=1, key output plots will be saved to the folder "SavedPlots"; Otherwise set SavePlot = 0;
DoPlots = 1; % if DoPlots=1, Spot-On will output plots, but not if it's zero. Avoiding plots speeds up Spot-On for batch analysis

%%%%% Model Fitting Parameters:
ModelFit = 2; %Use 1 for PDF-fitting; Use 2 for CDF-fitting
DoSingleCellFit = 0; %Set to 1 if you want to analyse all single cells individually (slow). 
%NumberOfStates = 3; % If NumberOfStates=2, a 2-state model will be used; If NumberOfStates=3, a 3-state model will be used 
FitIterations = 5; % Input the desired number of fitting iterations (random initial parameter guess for each)
FitLocError = 1; % If FitLocError=1, the localization error will fitted from the data
FitLocErrorRange = [0.010 0.075]; % min/max for model-fitted localization error in micrometers.
LocError = 0.035; % If FitLocError=0, LocError in units of micrometers will be used. 
UseWeights = 1; % If UseWeights=0, all TimePoints are given equal weights. If UseWeights=1, TimePoints are weighted according to how much data there is. E.g. 1dT will be weighted more than 5dT.
D_Free_2State = [0.1 20]; % min/max Diffusion constant for Free state in 2-state model (units um^2/s)
D_Bound_2State = [0.0001 0.1]; % min/max Diffusion constant for Bound state in 2-state model (units um^2/s)
D_Free1_3State = [0.009 1]; % min/max Diffusion constant #1 for Free state in 3-state model (units um^2/s)
D_Free2_3State = [0.00001 0.009]; % min/max Diffusion constant #2 for Free state in 3-state model (units um^2/s)
D_Bound_3State = [0.00001 0.009]; % min/max Diffusion constant for Bound state in 3-state model (units um^2/s)


base_dir    = uigetdir(pwd, 'Choose the Spot-On_mat_files_directory');

cd(base_dir);

%%%% Create a list of locations that contain the mat files to be analyzed
dir_list    = dir(fullfile(base_dir, '*', 'full_length_tracks', 'Spot-on_input*.mat'));

SpotOn_table    = table;

for i=1:length(dir_list)
    close all;

    data_struct = struct([]);

    cd(dir_list(i).folder); % Navigate to working directory

    data_struct(1).path = [dir_list(i).folder filesep]; % Path of the dataset
    data_struct(1).workspaces = {dir_list(i).name}; % Name of the file

    data_struct(1).Include = [1]; 

    tmp         = find(dir_list(i).name=='_', 2);
    SampleName = dir_list(i).name(tmp(2)+1:end-4);
    SampleName(SampleName == '_')   = ' ';

    NumberOfStates  = 2; % Fit to three states

    Params = struct(); % Use Params to feed all the relevant data/parameters into the relevant functions

    Params.TimeGap = TimeGap; Params.dZ = dZ; Params.GapsAllowed = GapsAllowed; Params.TimePoints = TimePoints; Params.BinWidth = BinWidth; Params.UseEntireTraj = UseEntireTraj; Params.DoPlots = DoPlots; Params.UseWeights = UseWeights;
    Params.JumpsToConsider = JumpsToConsider; Params.MaxJumpPlotPDF = MaxJumpPlotPDF; Params.MaxJumpPlotCDF = MaxJumpPlotCDF; Params.MaxJump = MaxJump; Params.SavePlot = SavePlot; Params.ModelFit = ModelFit;
    Params.DoSingleCellFit = DoSingleCellFit; Params.FitIterations = FitIterations; Params.FitLocError = FitLocError; Params.FitLocErrorRange = FitLocErrorRange; Params.LocError = LocError; Params.NumberOfStates = NumberOfStates;
    Params.D_Free_2State = D_Free_2State; Params.D_Bound_2State = D_Bound_2State; Params.D_Free1_3State = D_Free1_3State; Params.D_Free2_3State = D_Free2_3State; Params.D_Bound_3State = D_Bound_3State;
    Params.curr_dir = pwd; Params.SampleName = SampleName; Params.data_struct = data_struct;

    % add the relevant paths
    addpath(genpath([pwd, filesep, 'SpotOn_package', filesep])); 
    display('Added local paths for Spot-on core mechanics');
    [Output_struct] = SpotOn_core_vKW(Params);

    %%%% Save data to the SpotOn_table
    SpotOn_table.cell_protein{i}    = SampleName;

    output_vars                     = Output_struct.merged_model_params;

    SpotOn_table.Params{i}          = Params;

    SpotOn_table.D_Free(i)     = output_vars(1);
    SpotOn_table.D_state2(i)     = max([output_vars(2) output_vars(3)]);
    SpotOn_table.D_state1(i)     = min([output_vars(3) output_vars(2)]);
    SpotOn_table.Frac_Free(i)   = output_vars(5);
    SpotOn_table.Frac_state2(i)   = 1 - output_vars(4) - output_vars(5);
    
    if min([output_vars(3) output_vars(2)]) == output_vars(3)
        SpotOn_table.Frac_state1(i)   = output_vars(4);
        SpotOn_table.Frac_state2(i)   = 1 - output_vars(4) - output_vars(5);
    elseif min([output_vars(3) output_vars(2)]) == output_vars(2)
        SpotOn_table.Frac_state2(i)   = output_vars(4);
        SpotOn_table.Frac_state1(i)   = 1 - output_vars(4) - output_vars(5);
    end
    SpotOn_table.LocErr(i)      = output_vars(6);

    save(fullfile(dir_list(i).folder, sprintf('Spot-on_output_full_length_tracks_%s', dir_list(i).name(tmp(2)+1:end))), 'Output_struct', 'Params');

    cd(base_dir);

    fprintf('\n Dataset %d/%d DONE\n', i, length(dir_list));
end

save(fullfile(base_dir, 'SpotOn_table_full_length_tracks_v2.mat'), 'SpotOn_table');

