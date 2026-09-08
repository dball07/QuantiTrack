function pEM_Calc_3state_Transitions(varargin)

%Calculates transitions within a track between the states obtained from
%pEM. Only the 2 lowest diffusive states are explicitly used, and other
%states are grouped together.

%parse the inputs and ask for the file to load in if not provided
if isempty(varargin)
    [summary_file, summary_path]    = uigetfile('*.mat','Select Summary table to open');
    if summary_file == 0
        return;
    end

    IN = load(fullfile(path, summary_file));
    if isfield(IN,'meta_analysis')
        summary_table = IN.meta_analysis;
    elseif isfield(IN,'summary_table')
        summary_table = IN.summary_table;
    else
        errordlg('Transitions can currently only be calculated on meta_analysis or summary table variables');
        return;
    end
else
    summary_table = varargin{1};
    summary_path = varargin{2};
    summary_file = varargin{3};
end

%create the save location
save_dir = fullfile(summary_path, 'transition_probabilities_with_p_value');
dir_list = dir(summary_path);

save_dir_exist = 0;
% check if the save directory exists and make it if it does not
for i = 1:length(dir_list)
    if strcmp(save_dir,fullfile(summary_path,dir_list(i).name))
        save_dir_exist = 1;
        break;
    end
end

if save_dir_exist == 0
    mkdir(save_dir);
end

for i=1:height(summary_table)
    optimalState    = summary_table.optimalState{i};
    deltaPP_thresh  = summary_table.deltaPP_Thresh{i};
    deltaPP_states  = summary_table.states_deltaPP{i};
    pp              = summary_table.posteriorProb{i};
    
    trackID         = summary_table.trackID{i};
    splitID         = summary_table.splitID{i};
    optimalState    = optimalState + 100; % dummy change of variable
    
    % Redefine the states that are unambiguous
    for j=1:2
        optimalState(optimalState == deltaPP_states(j) + 100) = j;
    end
    
    optimalState(optimalState > 100)    = 3; % Assign all the other states to 3

    % Calculate transitions
    [Pt, counts]     = pEM_calculate_transition_probability(trackID, splitID, optimalState);

    summary_table.transitionCounts{i}   = counts;
    summary_table.transitionProb{i}     = Pt;

    Pt_random   =   zeros(3,3,1000);

    optimalState_scrambled      = cell(1,1000);

%     tic;

    for m = 1:1000
        optimalState_scrambled{m}   = optimalState(randperm(length(optimalState)));
    end

    parfor m = 1:1000
        Pt_random(:,:,m)            = ...
            pEM_calculate_transition_probability(trackID, splitID, optimalState_scrambled{m});

%         fprintf('\n %d/%d \n randomized trial %d/%d COMPLETE\n', i, height(summary_table), m, 1000)
    end
%     toc;

    p_value_transProb   = nan(length(unique(optimalState)));

    % Calculate "p-value" of the transition probability 
    for m=1:length(unique(optimalState))
        for n=1:length(unique(optimalState))
            p_value_transProb(m,n)  = numel(find(squeeze(Pt_random(m,n,:)) > Pt(m,n)))./1000;
        end
    end
    
    summary_table.Pt_random{i}          = Pt_random;
    summary_table.p_value_transProb{i}  = p_value_transProb;
    cell_protein    = [summary_table.cell_protein{i} ' ' summary_table.condition{i}];
    cell_protein(cell_protein == '_') = ' ';

    % Generate figure 
    P_fig   = figure('Position', [1 1 0.5 1].*get(0, 'Screensize')); hold on;

    b       = bar(Pt, 'linewidth', 2); 
    b(1).FaceColor  = 'r';
    b(2).FaceColor  = 'b';
    b(3).FaceColor  = [0.65 0.65 0.65];

    b(1).BarWidth      = 1;
    
    ylim([0 1]);
    xticks([1 2 3]);
    xticklabels({'Low-mobility 1', 'Low-mobility 2', 'Other'});
    ylabel('Transition probability');
    xlabel('From');
    set(gca,'linewidth',2,'fontweight','bold','fontsize',24);

    grid off;
    axis square;

    box on;
    title({sprintf('Transition probabilities, DeltaPP=%.1f', deltaPP_thresh),...
        cell_protein},...
        'fontweight', 'bold', 'fontsize', 24);
    
    % Add the "p-value" to the bars
    for m=1:3
        xdata   = b(m).XEndPoints;
        ydata   = b(m).YEndPoints;
        labels  = string(p_value_transProb(:,m));
        text(xdata, ydata, labels, 'HorizontalAlignment','center', 'VerticalAlignment','bottom',...
            'FontSize',18);
    end

    savefig(P_fig, fullfile(save_dir, sprintf('transProb_p_value_%s.fig',...
        [summary_table.cell_protein{i} '_' summary_table.condition{i}])));
    if verLessThan('matlab', '9.8')
        print(P_fig, fullfile(save_dir, sprintf('transProb_p_value_%s',...
            [summary_table.cell_protein{i} '_' summary_table.condition{i}])), '-depsc');
    else
        exportgraphics(P_fig, fullfile(save_dir, sprintf('transProb_p_value_%s.eps',...
            [summary_table.cell_protein{i} '_' summary_table.condition{i}])));
    end
    close(P_fig);

%     Pt          = summary_table.transitionProb{i};
% 
%     Pt_random   = summary_table.Pt_random{i};
% 
%     p_value_transProb   = summary_table.p_value_transProb{i};

    P_fig   = figure('Position', [1 1 0.5 1].*get(0, 'Screensize')); hold on;

%     subplot(121);

    b       = bar(Pt, 'linewidth', 2); 
    b(1).FaceColor  = 'r';
    b(2).FaceColor  = 'b';
    b(3).FaceColor  = [0.65 0.65 0.65];

    b(1).BarWidth      = 1;
    
    ylim([0 1]);
    xticks([1 2 3]);
    xticklabels({'Low-mobility 1', 'Low-mobility 2', 'Other'});
    ylabel('Transition probability');
    xlabel('From');
    set(gca,'linewidth',2,'fontweight','bold','fontsize',24);

    grid off;
    axis square;
    box on;
    title({'Transition probabilities',...
        cell_protein},...
        'fontweight', 'bold', 'fontsize', 24);

    x_points    = zeros(3);

    for m=1:3
        x_points(m,:)   = b(m).XEndPoints;
    end

    x_points    = x_points';

    y_data      = zeros(numel(Pt_random), 1);
    x_data      = zeros(size(y_data));

    counter = 1;
    for m=1:3
        for n=1:3
            y_data(counter:counter+1000-1)    = squeeze(Pt_random(m,n,:));
            x_data(counter:counter+1000-1)    = x_points(m,n).*ones(1000,1);
            counter                           = counter + 1000;
        end
    end

    swarmchart(x_data, y_data, 20, [.3 .3 .3], 'filled', 'MarkerEdgeColor', [0 0 0] ,...
        'MarkerFaceColor', [0.06 1 1], 'MarkerFaceAlpha',0.5, 'MarkerEdgeAlpha', 0.5);

    for m=1:3
        xdata   = b(m).XEndPoints;
        ydata   = b(m).YEndPoints;
        labels  = string(p_value_transProb(:,m));
        text(xdata, ydata, labels, 'HorizontalAlignment','center', 'VerticalAlignment','bottom',...
            'FontSize',18, 'FontWeight', 'bold');
    end

    legend({'Transitions to state 1', 'Transitions to state 2', ...
        'Transitions to other state', 'Randomized trial'}, 'Location','northeastoutside');

    savefig(P_fig, fullfile(save_dir, sprintf('transProb_p_value_swarm_%s.fig',...
        [summary_table.cell_protein{i} '_' summary_table.condition{i}])));
    if verLessThan('matlab', '9.8')
        print(P_fig, fullfile(save_dir, sprintf('transProb_p_value_swarm_%s',...
            [summary_table.cell_protein{i} '_' summary_table.condition{i}])), '-depsc');
    else
        exportgraphics(P_fig, fullfile(save_dir, sprintf('transProb_p_value_swarm_%s.eps',...
            [summary_table.cell_protein{i} '_' summary_table.condition{i}])));
    end
    close(P_fig);

    
%     fprintf('\n %d/%d COMPLETE\n', i, height(summary_table));
end


save(fullfile(save_dir, summary_file), 'summary_table', '-v7.3');

