function pEM_postProcess(varargin)
% Post-processing
% Note: All the files analyzed from a particular pEM_results file will be saved 
% with the same timestamp as  that in the name of the pEM_results file. This is 
% to allow the user to map the results back to the pEMTable.
if isempty(varargin)
    [pEMFile_fname, pEMPath] = uigetfile('pEM_results*.mat', 'Please select the pEM_results*.mat file');
    load(fullfile(pEMPath, pEMFile_fname));                           % Load the pEM results
else 
    pEMTable = varargin{1};
    trackTable = varargin{2};
    pEMFile_fname = varargin{3};
    pEMPath = varargin{4};
       
end

if length(varargin) < 5
    threshMaxPP = 0;
    threshdeltaPP = 0.2;
    fitLength = 3;
    bootstrap_nResamples = 1000;
else
    threshMaxPP = varargin{5};
    threshdeltaPP = varargin{6};
    fitLength = varargin{7};
    bootstrap_nResamples = varargin{8};
end

tstamp = pEMFile_fname(find(pEMFile_fname=='T')-11:end-4);  % Use the timestamp from the pEM_results file for file names names
metaPath = [pEMPath,filesep, 'post_processing'];
% Analyzing global pEM results
% First, we will analyze properties of the entire ensemble of tracks without 
% splitting them by condition. We will plot the following quantities
%% 
% # Swarm chart of *maximum posterior probability per state*
% # Table with *relative proportions* of each state (useful for eliminating 
% low population fraction states)
% # *CDF of diffusivities* per assigned state (based on maximum posterior probability)
% # *Mean squared displacement* for all track, classified by state
% # *Sample tracks* for all the reliable states

mkdir(metaPath);

mkdir(fullfile(metaPath, 'global_analysis'));

global_save_path = fullfile(metaPath,'global_analysis');

%posteriorProb = pEMTable.posteriorProb{1};

%[maxPosteriorProb, optimalState] = max(posteriorProb, [], 2);

%vacf = pEMTable.trackInfo{1}.vacf_exp;          % Autocorrelation function from pEM
%dt = pEMTable.trackInfo{1}.dt;                  % Exposure time
% 
maxPosteriorProb_in = pEMTable.maxPosteriorProb{1};
allPosteriorProb_in = pEMTable.posteriorProb{1};

%calculate the difference between the 2 highest Post. Prob.
MX_pp2 = maxk(allPosteriorProb_in',2);
MX_pp2 = MX_pp2';

deltaPosteriorProb_in = MX_pp2(:,1) - MX_pp2(:,2);
if size(MX_pp2,2) < 2
    MX_pp2 = 0;
end


optimalState_in = pEMTable.optimalState{1};
% (1) Calculate proportions


for i=1:pEMTable.optimalSize
    State(i,:)        = i;
    Proportion(i,:)   = length(find(optimalState_in==i))/length(optimalState_in);
    OptimalD(i,:)     = pEMTable.optimalD{1}(i);
    OptimalS(i,:)     = pEMTable.optimalS{1}(i);
end
proportions = table(State,Proportion,OptimalD,OptimalS);
state_idx = find(proportions.Proportion>0);     % Identify only those states that have a non-zero population fraction
fprintf('Population fraction (global):\n');
proportions

% writetable(proportions, fullfile(pEMPath, ['proportions_' timestamp '.xlsx']), 'WriteMode', 'append' ...
%     ,'Sheet', 'global');

writetable(proportions, fullfile(pEMPath, ['proportions_' tstamp '.xlsx']),'Sheet', 'global');
% (2) Swarm chart of max posterior probability

% Swarm chart of maximum posterior prob

globalfig(1) = figure('Position', [1 1 0.5 1].*get(0, 'Screensize'), 'Visible','on');
swarmchart(optimalState_in, maxPosteriorProb_in, '.');
% scatter(optimalState_in, maxPosteriorProb_in, '.');

set(gca,'linewidth',2,'fontweight','bold','fontsize',24);

grid off;
axis square; 
box off;
xlabel('State');
ylabel('Max posterior probability');
title('Ensemble swarm chart');
ylim([0 1]); 
% 
% (3) CDF of diffusivities

% CDF plot of diffusivities calculated from the tracks
globalfig(2) = figure('Position', [1 1 0.5 1].*get(0, 'Screensize'),'Visible','on');

D = pEMTable.track_D{1};

state_all = {};
MSD_Rc = nan(length(state_idx),2);
for i=1:length(state_idx)%1:pEMTable.optimalSize
    state_all{i}    = sprintf('State %d', state_idx(i));
    DVec        = D(optimalState_in==state_idx(i));
    cdfplot(DVec(DVec>0));

    set(gca,'linewidth',2,'fontweight','bold','fontsize',24);

    grid off;
    axis square;
    box on;
    hold on;
end

xlabel('D(\mum^2/s)');
ylabel('CDF')
legend(state_all);

line_plots = findobj(globalfig(2), 'Type', 'Line');
for i = 1:numel(line_plots)
  line_plots(i).LineWidth = 2.0;
end
% 
% (4) MSD plots
% These MSDs are plotted after assigning the states based on the maximum posterior 
% probability. This threshold can be changed but as seen from the swarm plots, 
% we are throwing out a lot of the data if we impose a high posterior probability 
% threshold.

globalfig(3) =  figure('Position', [1 1 0.5 1].*get(0, 'Screensize'),'Visible','on');

X_in = pEMTable.splitX{1};

dt = pEMTable.trackInfo{1}.dt;

T = 1:pEMTable.trackInfo{1}.splitLength;
T = T*dt;

tracks = cell(length(X_in),1);
for j=1:length(X_in)
    tracks{j} = [T.' X_in{j}];
end
cmap = colormap('lines');
state_glob = {};
MSD_Rc = nan(length(state_idx),2);
MSD_alpha = zeros(length(state_idx),2);
for i=1:length(state_idx)%1:pEMTable.optimalSize
    idx = find(optimalState_in==state_idx(i));
    tracks_tmp = tracks(idx);
    
    ma = msdanalyzer(2, 'µm', 's');     % Initialize the msdanalyzer class  
    ma = ma.addAll(tracks_tmp);
    ma = ma.computeMSD;

    mmsd = ma.getMeanMSD;
    t    = mmsd(:,1);
    x    = mmsd(:,2);
    dx   = mmsd(:,3)./sqrt(mmsd(:,4));
    
    if state_idx(i) < 8
        errorbar(t,x,dx, 'linewidth', 2,'Color',cmap(state_idx(i),:));   % Plot the MSD
    else
        errorbar(t,x,dx, '-.', 'linewidth', 2,'Color',cmap(state_idx(i),:));
    end
    %fit to a power law
    [Pwr_Coef, Pwr_Sigma] = PwrLawGrowth_nlinfit([t(2:end,:),x(2:end,:)],1);
    MSD_alpha(i,1:2) = [Pwr_Coef(1), Pwr_Sigma(1)];
    [~, Rc,~, Rc_CI] = fitMSD_Rc2(t(2:end,:),x(2:end,:),[1,4]);
    D_fit(i,1) = Rc(2);
    D_fit(i,2) = Rc_CI(2);
    if Pwr_Coef(1) < 0.90
        
        MSD_Rc(i,1) = Rc(1);
        MSD_Rc(i,2) = Rc_CI(1);
    else
        MSD_Rc(i,1) = NaN;
        MSD_Rc(i,2) = NaN;
        
    end
    state_glob{i} = sprintf('State %d, D = %1.3f, R_c = %1.3f', state_idx(i), OptimalD(i),round(MSD_Rc(i,1),3));
    set(gca,'linewidth',2,'fontweight','bold','fontsize',24);

    grid off;
    axis square;
    box off;
    hold on;

end
legend(state_glob, 'Location', 'northwest');
xlabel('Lag time (s)');
ylabel('MSD (\mum^2)');
title('MSD vs lag time, all conditions');

% 
% Save global plots

save_global_fig_name = sprintf('global_swarm_msd_cdf_%s.fig', tstamp);
savefig(globalfig, fullfile(global_save_path, save_global_fig_name), 'compact');

close(globalfig);
save(fullfile(global_save_path,'confinement_radii_states_global.mat'),'MSD_Rc','MSD_alpha','D_fit');
clear MSD_Rc MSD_alpha D_fit
% 
% (5) Plot sample tracks
% Plot sample tracks for states with a population fraction higher than 5%
% 
% The sample tracks plotted must have a posterior probability > 0.8 to belong 
% to the state.
% 
% These parameters for population fraction and maximum posterior  probability 
% can be changed  below:

reliableStates = find(proportions.Proportion > 0.05);

pEMTable.reliableState{1} = reliableStates;




for i=1:length(reliableStates)
    trackfig_glob(i) = figure('Position', [1 1 0.5 1].*get(0, 'Screensize'), 'Visible', 'on');
    hold on;
%     idx = find(optimalState_in==reliableStates(i) & maxPosteriorProb_in >= threshMaxPP & deltaPosteriorProb_in >= threshdeltaPP);

    X_temp = X_in(optimalState_in==reliableStates(i) & maxPosteriorProb_in >= threshMaxPP & deltaPosteriorProb_in >= threshdeltaPP);
    
    for j=1:length(X_temp)
        plot(X_temp{j}(:,1), ...
            X_temp{j}(:,2), 'linewidth', 1);
    end
    title(sprintf('Tracks - State %d', reliableStates(i)),'Interpreter','none');
    
    xlim([0 20]);
    ylim([0 20]);

    set(gca,'linewidth',2,'fontweight','bold','fontsize',24);

    grid off;
    axis square;
    box on;
    xticks([0 5 10 15 20]);
    yticks([0 5 10 15 20]);
    xlabel('X (\mum)');
    ylabel('Y (\mum)');
end
% 
% Save track figures

save_global_track_name = sprintf('global_tracks_thresh_%dpc_MaxPP_%dpc_deltaPP_%s.fig', 100*threshMaxPP, tstamp);
savefig(trackfig_glob, fullfile(global_save_path, save_global_track_name));
close(trackfig_glob);

% Condition-wise analysis
%

conditions          = unique(trackTable.condition);  % Identify unique conditions

maxPosteriorProb_in    = pEMTable.maxPosteriorProb{1};
optimalState_in       = pEMTable.optimalState{1};
% (1) Calculate proportions

% proportions = table;
for i=1:pEMTable.optimalSize
    State(i)        = i;
    Proportion(i)   = length(find(optimalState_in==i))/length(optimalState_in);
    OptimalD(i)     = pEMTable.optimalD{1}(i);
    OptimalS(i)     = pEMTable.optimalS{1}(i);
end
proportions = table(State,Proportion,OptimalD,OptimalS);
non_zero_state_idx = find(proportions.Proportion>0);     % Identify only those states that have a non-zero population fraction
% Re-assign pEM results  to cells in |trackTable|
% Here, we re-assign the pEM results to the cells in |trackTable.|
% 
% Note that the |trackTable| stored in the |postProcessing_*.mat| file contains 
% the results of pEM

trackID2 = cell2mat([trackTable.trackID]);     % Original trackIDs from trackTable
cellID2 = [trackTable.cellID];                 % Original cellIDs from trackTable

splitTrackID = pEMTable.splitID{1};           % Array of trackIDs after splitting
cellIDPerTrack  = pEMTable.cellID{1};         % Array of cellIDs after splitting

for i=1:length(cellID2)
    cellNum = cellID2(i);
    
    tmp_trackID = trackID2(cellIDPerTrack==cellNum); % Indices of tracks that belong to cell # cellNum

    idx = [];
    
    for j=1:length(tmp_trackID)
        idx = [idx; find(splitTrackID == tmp_trackID(j))];
    end
    
    trackTable.pEMTable_path{i}     = fullfile(pEMPath, pEMFile_fname);       % Path to pEM results
    trackTable.splitX{i}            = pEMTable.splitX{1}(idx);          % Split tracks per cell
    trackTable.splitID{i}           = pEMTable.splitID{1}(idx);         % Split ID for all tracks
    trackTable.posteriorProb{i}     = pEMTable.posteriorProb{1}(idx,:); % posterior probabilities for cell i
    trackTable.maxPosteriorProb{i}  = pEMTable.maxPosteriorProb{1}(idx);% maximum posterior probability for cell i
    trackTable.optimalState{i}      = pEMTable.optimalState{1}(idx);    % optimal state vector for cell i
    trackTable.track_D{i}           = pEMTable.track_D{1}(idx);         % Track level diffusivities calculated for cell i
    trackTable.optimalSize(i)       = pEMTable.optimalSize(1);          % Optimal number of states
    
    
    prop_Vec = zeros(1, trackTable.optimalSize(i));
    

    for l = 1:trackTable.optimalSize(i)
        prop_Vec(l) = length(find(trackTable.optimalState{i}==l))/...
            length(trackTable.optimalState{i});
    end
    
    trackTable.proportions{i}       = prop_Vec;                         % Proportions per cell
end

% Save the updated |trackTable|

% mkdir(fullfile(pEMPath, 'post_processing'));
save(fullfile(metaPath, ['postProcessing_' tstamp]), 'trackTable','-v7.3');
% 
% Split |trackTable| by condition
% Condition-wise results are saved in the meta_analysis table stored in the 
% |postProcessing*.mat| file

                                 % Initialize the meta_analysis table

for i=1:length(conditions)
    idx = ismember(trackTable.condition, ...
        conditions{i});                                 % Identify cells corresponding to this condition
    
    restrictedTable = trackTable(idx, :);               % Create new table with only relevant rows
     
    X2       = {};
    splitX_tmp  = {};

    for j=1:height(restrictedTable)
        splitX_tmp  = [splitX_tmp restrictedTable.splitX{j}];  % Concatentate all the split tracks
        X2       = [X2 restrictedTable.X{j}];            % Concatentate all the raw tracks
    end

    cell_protein{i,:}       = pEMTable.cell_protein{1};                     % Cell_protein 
    condition{i,:}          = conditions{i};                                % Condition
    splitLength(i,:)        = pEMTable.trackInfo{1}.splitLength;               % Split length
    pEMFile{i,:}            = pEMFile_fname;                                      % pEM file that generated the meta_analysis table
    N_cell(i,:)             = height(restrictedTable);                      % Number of cells
    N_sessions(i,:)         = numel(unique(restrictedTable.session));       % Number of distinct experimental sessions
    cellID{i,:}             = [restrictedTable.cellID];                     % Cell IDs for cells included in this condition
    trackID{i,:}            = cell2mat([restrictedTable.trackID]);          % trackIDs for all the tracks of this condition
    X{i,:}                  = X2;                                            % Raw tracks
    N_tracks(i,:)           = length(X2);                                    % Number of raw tracks
    splitX{i,:}             = splitX_tmp;                                       % Split tracks
    splitID{i,:}            = cell2mat([restrictedTable.splitID]);          % IDs for split tracks
    N_split_tracks(i,:)     = length(splitX_tmp);                               % Number of split tracks
    optimalSize(i,:)        = pEMTable.optimalSize;                         % Optimal size detected by pEM
    optimalVACF{i,:}        = pEMTable.optimalVacf;                         % Optimal covariance matrix
    optimalS{i,:}           = pEMTable.optimalS{1};                         % Localization precision
    optimalD{i,:}           = pEMTable.optimalD{1};                         % Diffusivity calculated for each state
    posteriorProb{i,:}      = cell2mat([restrictedTable.posteriorProb]);    % Matrix of posterior probabilities
    maxPosteriorProb{i,:}   = cell2mat([restrictedTable.maxPosteriorProb]); % Array of maximum posterior probabilities
    optimalState{i,:}       = cell2mat([restrictedTable.optimalState]);     % Optimal state assigned by maximum posterior  probability
    track_D{i,:}            = cell2mat([restrictedTable.track_D]);          % Track-wise diffusivities calculated for the tracks
    maxPP_Thresh{i,:}       = threshMaxPP;                                  % minimum value of the maximum posterior probability
    deltaPP_Thresh{i,:}     = threshdeltaPP;                                % minimum difference between the two best posterior probabilities

    prop_Vec = zeros(1, optimalSize(i));
    
    for l = 1:optimalSize(i)
        prop_Vec(l) = length(find(optimalState{i}==l))/...
            length(optimalState{i});
    end

    Proportions{i,:}        = prop_Vec;                                     % Population-level proportions 
    cell_wise_props{i,:}    = cell2mat([restrictedTable.proportions]);      % Proportions calculated per cell
    
    %calculate the proportions taking the thresholds on deltaPP and maxPP
    %into account
    prop_Vec2 = zeros(optimalSize(i),1);
    allPosteriorProb_in = posteriorProb{i,:};
    mxPP = maxPosteriorProb{i,:};

    %calculate the difference between the 2 highest Post. Prob.
    MX_pp2 = maxk(allPosteriorProb_in',2);
    MX_pp2 = MX_pp2';
    if size(MX_pp2,2) < 2
        MX_pp2 = 0;
    end


    deltaPosteriorProb_in = MX_pp2(:,1) - MX_pp2(:,2);
    optimalState_delPP{i,:} = optimalState{i,:}(deltaPosteriorProb_in >= threshdeltaPP & mxPP >= threshMaxPP);
    
    
    
    for l = 1:optimalSize(i)
        prop_Vec2(l) = length(find(optimalState_delPP{i,:}==l))/...
            length(optimalState_delPP{i,:});
    end
    props_deltaPP{i,:} = prop_Vec2(prop_Vec2>=0.05)/sum(prop_Vec2(prop_Vec2>=0.05));
    idx = find(prop_Vec2 >= 0.05);
    states_deltaPP{i,:} = idx;
    OptimalD_deltaPP = OptimalD(idx);

    %Get the distributions of Ds for tracks with good deltaPP
    for j = 1:length(states_deltaPP{i,:})
        D_track      = track_D{i}(deltaPosteriorProb_in>threshdeltaPP & ...
            optimalState{i,:} == states_deltaPP{i}(j));
    
        [F,x]       = histcounts(D_track, 'Normalization','pdf');
        DP_pdf_F{j}        = F;
        D_pdf_X{j}        = 0.5.*(x(1:end-1)+x(2:end));
    end
    pEM_D_pdf_x{i,:}      = D_pdf_X; % Assign the diffusivity PDF x-coordinates
    pEM_D_pdf_F{i,:}      = DP_pdf_F; % Assign the diffusivity counts
    
   


    %save condition wise proportions
    mkdir([pEMPath,filesep,'post_processing',filesep, condition{i}]);
    for j=1:pEMTable.optimalSize
        State(j,:)        = j;
        Proportion(j,:)   = length(find(optimalState{i}==j))/length(optimalState{i});
        OptimalD(j,:)     = pEMTable.optimalD{1}(j);
        OptimalS(j,:)     = pEMTable.optimalS{1}(j);
    end
    
    prop_cond = table(State,Proportion,OptimalD,OptimalS);

    writetable(prop_cond,fullfile([pEMPath,filesep,'post_processing',filesep,condition{i}],['proportions_',condition{i},'_',tstamp,'.xlsx']));

    % Plot condition-wise figures
    %%
    % * Swarm plot of maximum posterior probability
    % * CDF of diffusivities
    % * MSDs
    % * Sample tracks
    % * Population bar plots of proportions
   
    % In this section, we generate all the figures and save them in single fig files
    % sorted by condition
    figCount = 1;
%     mkdir(fullfile(metaPath, meta_analysis.condition{i}));
    fig_save_dir = fullfile(metaPath, condition{i});

    titlestr = [cell_protein{i} ' ' condition{i}];
    titlestr(titlestr=='_') = ' ';
    
    condfig(figCount)  = figure('Position', [1 1 0.5 1].*get(0, 'Screensize'),'Visible','on');
    swarmchart(optimalState{i}, maxPosteriorProb{i}, '.');
    %if swarmchart is not available uncomment line below and comment line
    %above
%     scatter(optimalState{i}, maxPosteriorProb{i}, '.');

    set(gca,'linewidth',2,'fontweight','bold','fontsize',24);

    grid off;
    axis square;
    box off;
    xlabel('State');
    ylabel('Max posterior probability');
    title(titlestr,'Interpreter','none');
    ylim([0 1]);
    xlim_cur = get(gca,'XLim');
    xlim([0 xlim_cur(2)+1])
    figCount = figCount + 1;
    
    %swarm chart for deltaPP > thresh
    condfig(figCount) = figure('Position', [1 1  0.5 1].*get(0, 'Screensize'));
    col             = {[1 0 0], [0 0 1], [0.47,0.67,0.19], [0.93,0.69,0.13], [1 1 1], [0.49,0.18,0.56]};
    if length(states_deltaPP{i}) > 6
        for j = 1:length(states_deltaPP{i})- 6
            col_tmp{1,j} = [0.8, 0.8 0.8];
        end
        col = [col, col_tmp];
    end
    cmap2       = zeros(length(optimalState{i}),3);
    for j = 1:length(states_deltaPP{i})
        %cmap_vec(summary_table.states_deltaPP{i}(j), :) = col{j};

        cmap2(optimalState{i}==states_deltaPP{i}(j),:)  = ...
            col{j}.*ones(size(cmap2(optimalState{i}==states_deltaPP{i}(j),:)));
    end
    hold on;
    swarmchart(optimalState{i,:}(deltaPosteriorProb_in >= threshdeltaPP & mxPP >= threshMaxPP), mxPP(deltaPosteriorProb_in >= threshdeltaPP & mxPP >= threshMaxPP), 20, ...
        cmap2(deltaPosteriorProb_in >= threshdeltaPP & mxPP >= threshMaxPP,:), 'filled', 'MarkerFaceAlpha',0.5, 'MarkerEdgeAlpha', 0.5);
    set(gca,'linewidth',2,'fontweight','bold','fontsize',24);

    grid off;
    axis square;
    box off;
    xticks(1:optimalSize(i));
    xlim([0 optimalSize(i)+1]);
    ylim([0 1]);
    ylabel('Maximum posterior probability');
    xlabel('pEM State');
    cp_title = cell_protein{i};
    cp_title(cp_title == '_') = ' ';

    title({cp_title, sprintf('swarmchart deltaPP = %.1f', threshdeltaPP)}, 'Interpreter','none');
    figCount = figCount + 1;

    %Kymographs of longest tracks with sub-tracks represented as a pixel
    %color coded by pEM state
    
    % Sort the trackIDs in descending order of trackLength
    [trackLength, trackID_tmp, ~]   = groupcounts(splitID{i});
    [~, idx]            = sort(trackLength, 'descend');
    heatmap_size = min(100,max(idx));
    % Create the track heatmap matrix 
    trackmap_tmp                    = zeros(heatmap_size);
    alphamap                        = zeros(heatmap_size);
    
    for j=1:heatmap_size
        jdx                             = find(splitID{i}==trackID_tmp(idx(j)));
        trackmap_tmp(j, 1:length(jdx))  = optimalState{i}(jdx);
        alphamap(j, 1:length(jdx))      = deltaPosteriorProb_in(jdx);
    end
    
    col = [1 0 0; 0 0 1; ...
        0.47 0.67 0.19; ...
        0.93 0.69 0.13; ...
        0.75 0.75 0.75];
    n_states = pEMTable.optimalSize(1);
    if n_states > 5
        col = [col; zeros(n_states - 5, 3)]; % states 6+ black
    end
    condfig(figCount) = figure('Position', [1 1 0.5 1].*get(0, 'Screensize'));
    cmap = [1 1 1; col(1:n_states, :)]; % row 1 = white blank,
    % rows 2..n+1 = state k
    colormap(cmap);
    imagesc(trackmap_tmp, 'AlphaData', alphamap);
    clim([0, n_states]); % force value k -> row k+1
    
    set(gca,'linewidth',2,'fontweight','bold','fontsize',24);
    box on;
    title({sprintf('Track heatmap, DeltaPP=%.1f', threshdeltaPP),...
        cp_title}, 'fontweight', 'bold', 'fontsize', 24,'Interpreter','none');
    xlabel('Time (subtracks)');
    ylabel('Track #');

    figCount = figCount + 1;
    
    %Proportions vs track length
    % Calculate track lengths from the number of subtracks
    % Sort the trackIDs in descending order of trackLength
    [trackLength, trackID_tmp, ~]   = groupcounts(splitID{i});
    [sortedTrackLength, idx]        = sort(trackLength, 'descend');

    % Assign to the summary_table
    trackLengths{i}   = trackLength;

    % Define edges of the bins to sort tracks into

    % Create logarithmically spaced bin peaks
    binPeak                         = [0 2.^linspace(0,8,9)];

    edges                           = 0.5.*(binPeak(1:end-1)+binPeak(2:end));
    
    % Sort the tracks into bins
    [binIDX, ~]                     = discretize(trackLength, edges);
    binIDX = binIDX(~isnan(binIDX));
    % Define proportions array with rows for each state and columns for all
    % the bins + one additional for the overall proportions
    props                           = nan(length(states_deltaPP{i,:})+1,numel(unique(binIDX))+1);

    for j=1:length(unique(binIDX))

        Lia     = ismember(splitID{i}, trackID{i,:}(binIDX==j));
        idx     = find(Lia & deltaPosteriorProb_in >=threshdeltaPP); % Find all tracks that belong to bin j

        % Calculate proportions

        if ~isempty(idx)
            [stateCount, ~, props_tmp]      = groupcounts(optimalState{i,:}(idx));

            props(1:length(props_tmp), j)   = props_tmp;  
        end
    end
    
    % Normalize proportions to 1
    props   = props./100;

    % Calculate proportions for all subtracks
    props(1:length(states_deltaPP{i}),length(unique(binIDX))+1)    = props_deltaPP{i}';
    condfig(figCount) = figure('Position', get(0, 'Screensize')); 
    
    subplot(1,2,1);
    hold on;

    if length(states_deltaPP{i}) > 2
        col     = [1 0 0; 0 0 1; 0.47,0.67,0.19; 0.93,0.69,0.13; 0.65 0.65 0.65];
    % elseif length(states_deltaPP{i}) == 3
    %     col     = [1 0 0; 0 0 1; 0.47,0.67,0.19; 0.65 0.65 0.65];
    elseif length(states_deltaPP{i}) == 2
        col     = [1 0 0; 0 0 1; 0.65 0.65 0.65];
    end

    b       = bar([1:length(unique(binIDX)) length(unique(binIDX))+2], props', 'stacked', 'linewidth', 2);

    for j = 1:length(states_deltaPP{i}) + 1
        col_ind = min(j,size(col,1));
        
        b(j).FaceColor  = col(col_ind,:);
    end

    
    set(gca,'linewidth',2,'fontweight','bold','fontsize',24);

    axis square;
    box on; grid on;

    xticks(1:size(props,2)+1);
    x_label     = cell(1, size(props,2)+1);

    for j=1:length(x_label)
        if j==1
            x_label{j} = '1';
        elseif j==2
            x_label{j} = '2';
        elseif j==length(x_label)
            x_label{j} = 'ALL';
        elseif j==length(x_label)-1
            x_label{j} = '';
        else
            x_label{j}  = sprintf('%d - %d', edges(j), edges(j+1)-1);
        end
    end

    for j=1:length(unique(binIDX))
        Lia     = ismember(splitID{i}, trackID{i}(binIDX==j));

        ht  = text(j, 0.1, sprintf('N_{T}=%d',...
            numel(find(binIDX==j))), 'color', 'white');
        set(ht, 'Rotation', 90);
        set(ht, 'fontsize', 24, 'fontweight', 'bold');

        hst  = text(j, 0.5, sprintf('N_{ST}=%d',...
            numel(find(Lia==1 & deltaPosteriorProb_in >= threshdeltaPP))), 'color', 'white');
        set(hst, 'Rotation', 90);
        set(hst, 'fontsize', 24, 'fontweight', 'bold');
    end

    ht = text(length(unique(binIDX))+2, 0.1, sprintf('N_{T}=%d', length(binIDX)), 'color', 'white');
    set(ht, 'Rotation', 90);
    set(ht, 'fontsize', 24, 'fontweight', 'bold');

    hst = text(length(unique(binIDX))+2, 0.5, sprintf('N_{ST}=%d', length(splitID{i}(deltaPosteriorProb_in>=threshdeltaPP))), 'color', 'white');
    set(hst, 'Rotation', 90);
    set(hst, 'fontsize', 24, 'fontweight', 'bold');


    xticklabels(x_label);
    xlabel('Track length (subtracks)');
    ylabel('Population fraction');
    title('Binned proportions');
    yticks(0:0.1:1);
    ylim([0 1]);

    subplot(1,2,2);
    histogram(trackLength, edges, 'linewidth', 2);
    set(gca, 'XScale', 'log');
    set(gca, 'YScale', 'log');
    
    set(gca,'linewidth',2,'fontweight','bold','fontsize',24);

    grid off;

    box on; axis square;
    ylabel('Counts');
    xlabel('Track length (subtracks)');
    xticks(binPeak);
    title('Histogram of track lengths');

    sgtitle(sprintf('%s \n deltaPP=%.1f', cp_title, threshdeltaPP), 'fontsize', 36, 'fontweight', 'bold','Interpreter','none');
    figCount = figCount + 1;

    % MSD
    condfig(figCount) = figure('Position', [1 1 0.5 1].*get(0, 'Screensize'),'Visible','on');
    line_col = [1 0 0; 0 0 1; 0.47,0.67,0.19; 0.93,0.69,0.13; 0.49, 0.18, 0.56];
    colormap(line_col);
    X_in   = splitX{i};

    dt  = trackTable.interval(1);
    
    T   = 1:pEMTable.trackInfo{1}.splitLength;
    T   = T*dt;
    
    tracks = cell(length(X_in),1);
    for j=1:length(X_in)
        tracks{j} = [T.' X_in{j}];
    end
    
    state  = cell(1,length(states_deltaPP{i,:}));
    
    
    MSD{i,:} = zeros(splitLength(i),length(props_deltaPP{i}));
    MSD_err{i,:} = zeros(splitLength(i),length(props_deltaPP{i}));
    
    MSD_Rc = nan(length(props_deltaPP{i}),2);
    MSD_alpha = zeros(length(props_deltaPP{i}),2);
    
    cmap = cmap(2:end,:);
    for j=1:length(states_deltaPP{i,:})%1:meta_analysis.optimalSize
        
        idx     = find(optimalState{i}==states_deltaPP{i,:}(j));
        tracks_tmp = tracks(idx);
        
        ma      = msdanalyzer(2, 'µm', 's');     % Initialize the msdanalyzer class  
        ma      = ma.addAll(tracks_tmp);
        ma      = ma.computeMSD;
    
        mmsd    = ma.getMeanMSD;
        t       = mmsd(:,1);
        x       = mmsd(:,2);
        dx      = mmsd(:,3)./sqrt(mmsd(:,4));
        if states_deltaPP{i,:}(j) < 8
            if states_deltaPP{i,:}(j) > size(cmap,1)
                bka = 1;
            end
            errorbar(t,x,dx, 'linewidth', 2,'Color',cmap(states_deltaPP{i,:}(j),:));   % Plot the MSD
        else
            errorbar(t,x,dx, '-.', 'linewidth', 2,'Color',cmap(non_zero_state_idx(j),:));   % Plot the MSD
        end

        set(gca,'linewidth',2,'fontweight','bold','fontsize',24);

        grid off;
        axis square;
        box off;
        hold on;
        
        %store the MSD data
        MSD{i}(:,j) = x;
        MSD_err{i}(:,j) = dx;

        %fit to a power law
        [Pwr_Coef, Pwr_Sigma] = PwrLawGrowth_nlinfit([t(2:end,:),x(2:end,:)],1);
        MSD_alpha(j,1:2) = [Pwr_Coef(1), Pwr_Sigma(1)];
        [~, Rc,~, Rc_CI] = fitMSD_Rc2(t(2:end,:),x(2:end,:),[1,4]);
        D_fit(j,1) = Rc(2);
        D_fit(j,2) = Rc_CI(2);
        if Pwr_Coef(1) < 0.90
            
            MSD_Rc(j,1) = Rc(1);
            MSD_Rc(j,2) = Rc_CI(1);
        else
            MSD_Rc(j,1) = NaN;
            MSD_Rc(j,2) = NaN;
            
        end
        state{j} = sprintf('State %d, D = %1.3f, R_c = %1.3f', states_deltaPP{i,:}(j), OptimalD_deltaPP(j),round(MSD_Rc(j,1),3));
        MSD_Rc_all{i,1} = MSD_Rc;
        MSD_alpha_all{i,1} = MSD_alpha;
    end
    

    legend(state, 'Location', 'northwest');
    xlabel('Lag time (s)');
    ylabel('MSD (\mum^2)');
    title(titlestr,'Interpreter','none');
    figCount = figCount + 1;

    % CDF of diffusivities
    condfig(figCount) = figure('Position', [1 1 0.5 1].*get(0, 'Screensize'),'Visible','on');
    line_col = [1 0 0; 0 0 1; 0.47,0.67,0.19; 0.93,0.69,0.13; 0.49, 0.18, 0.56];
   
    D = track_D{i};

    for j=1:length(states_deltaPP{i,:})
        
        DVec = D(optimalState{i}==states_deltaPP{i,:}(j));
        hCDF = cdfplot(DVec(DVec>0));
        if j <= 5
            hCDF.Color = line_col(j,:);
        else
            lineColorNew = 0.2 + 0.55*(1 - ((j-6)/(length(states_deltaPP{i,:})-5)));
            if lineColorNew < 0 || lineColorNew > 1
                naivna = 1;
            end
            hCDF.Color = repmat(lineColorNew,1,3);
        end
        set(gca,'linewidth',2,'fontweight','bold','fontsize',24);

        grid off;
        axis square;
        box on;
        hold on;
    end
    xlabel('D(\mum^2/s)');
    ylabel('CDF');
    title(titlestr,'Interpreter','none');
    legend(state,'Location','southeast');
    
    line_plots = findobj(condfig(figCount), 'Type', 'Line');
    for k = 1:numel(line_plots)
      line_plots(k).LineWidth = 2.0;
    end
    figCount = figCount +  1;

    %Plot of diffusivities from pEM
    condfig(figCount) = figure('Position', [1 1 0.5 1].*get(0, 'Screensize'));
    
    line_col     = [1 0 0 ; 0 0 1];

    for j=1:2
        plot(pEM_D_pdf_x{i}{j}, pEM_D_pdf_F{i}{j}, ...
            'linewidth', 3, 'color', line_col(j,:));
        hold on;
%         

    end
    xlabel('D(\mum^2/s)');
    ylabel('PDF');
    grid off;
    axis square; 
    set(gca,'linewidth',3,'fontweight','bold','fontsize',24);
    box on;
    title({sprintf('Diffusivity PDF from pEM, deltaPP=%.1f', threshdeltaPP), cp_title},'Interpreter','none');
    legend({'LM 1', 'LM 2'});
    xlim([-0.02 0.05])
    figCount = figCount +  1;

    %Fit the MSD with MSD analyzer
    % Load the split tracks from the summary_table. 
    X_msd       = splitX{i,:};
    T       = 1:splitLength(i);
    T       = dt.*T;
    tracks  = cell(length(X_msd), 1);
    
    for j=1:length(X_msd)
        tracks{j} = [T.' X_msd{j}];
    end
    
    % Initialize msdanalyzer
    MA      = msdanalyzer(2, 'um', 's'); 
    
    % Calculate MSD, fitMSD to extract diffusion coefficient and add this to the summary_table
    MA      = MA.addAll(tracks);
    MA      = MA.computeMSD;
    MA      = MA.fitMSD(fitLength/splitLength(i));
    msd{i,:}   = MA;
    
    % Save the diffusivity calculated by msdanalyzer to the summary_table. Save
    % this as manual_trackD
    msdFit_track_D{i,:}    = MA.lfit.a./4;

    % Calculate the distribution of diffusion coefficients for each state
    % Define cell arrays that will hold the PDF and diffusivities
    N               = cell(length(states_deltaPP{i}),1);
    D               = cell(length(states_deltaPP{i}),1);
    for j=1:length(states_deltaPP{i})
        D_track      = msdFit_track_D{i}(deltaPosteriorProb_in>threshdeltaPP & ...
            optimalState{i} == states_deltaPP{i}(j));
    
        [F,x]       = histcounts(D_track, 'Normalization','pdf');
        N{j}        = F;
        D{j}        = 0.5.*(x(1:end-1)+x(2:end));
    end

    msdFit_D_pdf_x{i,:}      = D; % Assign the diffusivity PDF x-coordinates
    msdFit_D_pdf_F{i,:}      = N; % Assign the diffusivity counts

    % Calculate the distribution of MSDs for each time-lag
    N               = cell(length(states_deltaPP{i}),splitLength(i)-1);
    MSD_deltaPP             = cell(length(states_deltaPP{i}),splitLength(i)-1);
    
    for j=1:splitLength(i) - 1
        for k=1:length(states_deltaPP{i})
            % Transform the msd cell array to a matrix
            msdMat  = cell2mat(MA.msd);
            msdMat = reshape(msdMat,[size(MA.msd{1},1),size(MA.msd{1},2),length(MA.msd)]);
            % Extract the msd values corresponding to the state and time-lag of
            % interest
            msdVec  = squeeze(msdMat(1+j, 2, :));
            msdVec  = msdVec(deltaPosteriorProb_in>threshdeltaPP & ...
                optimalState{i} == states_deltaPP{i}(k));
    
            [F,x]       = histcounts(msdVec, 'Normalization','pdf');
            N{k,j}     = F;
            MSD_deltaPP{k,j}   = 0.5.*(x(1:end-1)+x(2:end));
        end
    end
    msd_dist_x{i,:}   = MSD_deltaPP;
    msd_dist_F{i,:}   = N;


    % Bar chart of cell-wise proportions
    condfig(figCount) = figure('Position', [1 1 1 1].*get(0, 'Screensize'),'Visible','on');
    line_cmap = [1 0 0; 0 0 1; 0.47,0.67,0.19; 0.93,0.69,0.13; 0.49, 0.18, 0.56];
    
    % colormap(condfig(figCount),line_cmap);
    hBar = bar(cellID{i}, cell_wise_props{i}, 'stacked','linewidth', 1);
    for k = 1:length(hBar)
        if k <= 5
            hBar(k).FaceColor = line_cmap(k,:);
        else
            barColor_new =  0.2+ 0.55*(1 - ((k-6)/(length(hBar)-5)));
            hBar(k).FaceColor = repmat(barColor_new,1,3);
        end
    end
    set(gca,'linewidth',2,'fontweight','bold','fontsize',24);
    box on;
    grid off
    ylim([0 1]);
    title(sprintf('Cell-wise proportions: %s ', titlestr),'Interpreter','none');
    legend(state_all);
    figCount =  figCount + 1;
    
   
    save(fullfile(fig_save_dir,['confinement_radii_states_',condition{i},'_',tstamp,'.mat']),'MSD_Rc','MSD_alpha','D_fit');

    savefig(condfig, fullfile(fig_save_dir, ...
        sprintf('%s_swarm_msd_cdf_popFrac_%s.fig', condition{i}, tstamp)), ...
        'compact');
    close(condfig);

    % Proportions
    State = states_deltaPP{i,:};
    Proportion = props_deltaPP{i,:};
%     
%     for j=1:optimalSize(i)
%         State(j) = j;
%         Proportion(j) = length(find(optimalState{i}==j))...
%             /length(optimalState{i});
%     end
% 

    proportions = table(State,Proportion);
    fprintf('Population fraction (%s):\n',titlestr);
    proportions
    

    writetable(proportions, fullfile(pEMPath, ['proportions_' tstamp '.xlsx']),'Sheet', condition{i}(1:min(31, length(condition{i}))));

    % Sample tracks
    reliableStates = find(proportions.Proportion > 0.05);
    
    
    
    for j=1:length(reliableStates)
        trackfig(j) = figure('Position', [1 1 0.5 1].*get(0, 'Screensize'), 'Visible', 'on');
        hold on;
        idx = find(optimalState{i}==reliableStates(j) ...
            & maxPosteriorProb{i} >= threshMaxPP & deltaPosteriorProb_in >= threshdeltaPP);
    
        X_temp = splitX{i}(j);
        
        for k=1:length(X_temp)    
            plot(X_temp{k}(:,1), ...
                X_temp{k}(:,2), 'linewidth', 1);
        end
        title(sprintf('%s Tracks - State %d', titlestr, reliableStates(j)),'Interpreter','none');
        
        xlim([0 20]);
        ylim([0 20]);

        set(gca,'linewidth',2,'fontweight','bold','fontsize',24);

        grid off;
        axis square;
        box on;
        
        xticks([0 5 10 15 20]);
        yticks([0 5 10 15 20]);
        xlabel('X (\mum)');
        ylabel('Y (\mum)');
    end
    savefig(trackfig, fullfile(fig_save_dir, sprintf('%s_tracks_%s', condition{i}, tstamp)), ...
        'compact');
    close(trackfig);
    clear trackfig;
    %Calcualate Confidence intervals on Population fractions
   
    alpha = 0.95;
    if bootstrap_nResamples == 0
        bootstrapCI_resamples(i,1) = bootstrap_nResamples;
        bootstrapCI_alpha(i,1) = 0;
        bootstrapCI_popFracMat{i,1} = [];
        bootstrapCI_ciProps_deltaPP{i,1} = [];
    else

        [popFracMat, ciProps] = QT_confidence_intervals_pEM_fractions(bootstrap_nResamples, alpha, trackID{i}, splitID{i}, ...
           optimalState{i}, posteriorProb{i}, deltaPP_Thresh{i}, ...
           states_deltaPP{i}, props_deltaPP{i});
        bootstrapCI_resamples(i,1) = bootstrap_nResamples;
        bootstrapCI_alpha(i,1) = alpha;
        bootstrapCI_popFracMat{i,1} = popFracMat;
        bootstrapCI_ciProps_deltaPP{i,1} = ciProps;
    end

end
meta_analysis =  table(cell_protein, condition, splitLength, pEMFile, ...
    N_cell, N_sessions, cellID, trackID, X, N_tracks, splitX, splitID, ...
    N_split_tracks, optimalSize, optimalVACF, optimalS, optimalD, ...
    posteriorProb, maxPosteriorProb, optimalState, track_D, ...
    Proportions, cell_wise_props, maxPP_Thresh, deltaPP_Thresh, ...
    props_deltaPP, states_deltaPP, MSD, MSD_err,MSD_alpha_all,MSD_Rc_all,...
    pEM_D_pdf_x,pEM_D_pdf_F,msd, msdFit_track_D, ...
    msdFit_D_pdf_x, msdFit_D_pdf_F, msd_dist_x, msd_dist_F,...
    bootstrapCI_resamples, bootstrapCI_alpha, bootstrapCI_popFracMat, ...
    bootstrapCI_ciProps_deltaPP);
% Save |meta_analysis|

save(fullfile(pEMPath,'post_processing', ['postProcessing_' tstamp]), 'meta_analysis',...
    'non_zero_state_idx', '-append');

