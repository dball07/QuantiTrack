function RL_BatchTrackAnalysis(trackTable,base_dir, lagtime, nbins, jump_thresh, maxBin, filtImmobile_flag, immobileThresh, minTrackLength, Niter, MSDmin, MSDmax, MSDnBins)

%Parse inputs and set undefined parameters to default values
%If no tracktable is specified, open a dialog to select one

if nargin < 2 ||isempty(trackTable) || isempty(base_dir)
    [trackTable_file, base_dir] = uigetfile('*.mat','Select trackTable file to analyze');

    if trackTable_file == 0
        return
    else
        tt_IN = load(fullfile(base_dir,trackTable_file));
        trackTable = tt_IN.trackTable;
    end
end

if nargin < 3 || isempty(lagtime)
    lagtime = 5;
end
if nargin < 4 || isempty(nbins)
    nbins = 200;
end
if nargin < 5 || isempty(jump_thresh)
    jump_thresh = 2e-3; %2 nm
end
if nargin < 6 || isempty(maxBin)
    maxBin = 0.4; %400 nm
end
if nargin < 7 || isempty(filtImmobile_flag)
    filtImmobile_flag = 0;
end
if nargin < 8 || isempty(immobileThresh)
    immobileThresh = 0.0019;
end
if nargin < 9 || isempty(minTrackLength)
    minTrackLength = 7;
end
if nargin < 10 || isempty(Niter)
    Niter = 50000;
end
if nargin < 11 || isempty(MSDmin)
    MSDmin = 1e-4;
end
if nargin < 12 || isempty(MSDmax)
    MSDmax = 0.25;
end
if nargin < 13 || isempty(MSDnBins)
    MSDnBins = 400;
end

%compile all of the tracks into a single cell array
tracks          = [trackTable.X{:}];



for i=1:length(tracks)
    tracks{i}  = tracks{i}(:,1:2); 
    % In case the trackTable was generated to contain the time dimension as well,
    % we want to assign only the coordinates to the X cell array

end
interval = trackTable.interval(1);

RL_values = RL_TrackAnalysis(tracks, interval, lagtime, nbins, jump_thresh, maxBin, filtImmobile_flag, immobileThresh, minTrackLength, Niter, MSDmin, MSDmax, MSDnBins);

%add RL_classification to the trackTable
for i=1:height(trackTable)
    trackTable.RL_classification{i}    = RL_values.classified_tracks(trackTable.trackID{i});
end


title_str   = [trackTable.cell_protein{1} '_' trackTable.condition{1}];


timestamp = datestr(now, 'yyyy-mm-dd_THHMM');

RL_save_dir = fullfile(base_dir,sprintf('RL_results_%s', timestamp));
mkdir(RL_save_dir);

save(fullfile(RL_save_dir, sprintf('RL_results_%s_lagtime_%d_%s.mat', title_str, lagtime, timestamp)), ...
    "RL_values", 'trackTable');
%Make separate trackTables for each state
trackTable_full = trackTable;
for i = 0:max(RL_values.classified_tracks)
    %Reset the trackTable to include everything & reset the track counter
    trackTable = trackTable_full;
    trackID_offset = 0;
    
    ind2remove = [];
    for j = 1:height(trackTable_full)
        
        %Find tracks that belong to the current state in the current movie
        state_ind = trackTable_full.RL_classification{j} == i;
        trackTable.X{j} = trackTable_full.X{j}(state_ind);
        trackTable.xyt{j} = trackTable_full.xyt{j}(state_ind);
        trackTable.trackID{j} = (1:sum(state_ind))' + trackID_offset;
        
        %update the track counter
        if ~isempty(trackTable.trackID{j})
            trackID_offset = max(trackTable.trackID{j});
        else
            ind2remove = [ind2remove; j];
        end

    end
    trackTable(ind2remove,:) = [];
    
    if height(trackTable) > 0 %only save if trackTable is not empty
    
        %Save the new trackTable
        savename = sprintf('trackTable_%s_RL_State%d_%s.mat', trackTable.cell_protein{1}, i, timestamp);
        save(fullfile(RL_save_dir,savename),'trackTable');
    end

end
%make some useful figures:

d = waitbar(0,'Generating Figures ','Name','RL analysis');
%van Hove correlation and fit
RL_fig(1) = figure('Position', [1 1 0.5 1].*get(0, 'Screensize'), 'Visible','on');

plot(RL_values.vanHove(:,1),RL_values.vanHove(:,2),'ko','markersize',8);
hold on;
set(gca,'yscale','log');
plot(RL_values.Gs(:,1),RL_values.Gs(:,2),'r','linewidth',2);
set(gca,'linewidth',1,'fontsize',24,'fontweight','bold');
xlabel('r (\mum)');
ylabel('G(r,\tau)');
set(gca,'Xlim',[0, 1]);

title({title_str, sprintf('lagtime = %d frames', lagtime)}, 'Interpreter','none','FontSize',16);

exportgraphics(gcf, fullfile(RL_save_dir, sprintf('vHc_%s_lagtime_%d.eps', title_str, lagtime)));
exportgraphics(gcf, fullfile(RL_save_dir, sprintf('vHc_%s_lagtime_%d.png', title_str, lagtime)));

waitbar(0.33,d);
%P(MSD) plot
RL_fig(2) = figure('Position', [1 1 0.5 1].*get(0, 'Screensize'), 'Visible','on');

semilogx(RL_values.P1norm(:,1),RL_values.P1norm(:,2),'k','linewidth',2);
title(title_str,'FontSize',16);

xlabel('MSD (\mum^2)');
ylabel('P(MSD)');
set(gca,'linewidth',1,'fontsize',24,'fontweight','bold');
box off;
title({title_str, sprintf('lagtime = %d frames', lagtime)}, 'Interpreter','none');

exportgraphics(gcf, fullfile(RL_save_dir, sprintf('PMSD_%s_lagtime_%d.eps', title_str, lagtime)));
exportgraphics(gcf, fullfile(RL_save_dir, sprintf('PMSD_%s_lagtime_%d.png', title_str, lagtime)));

%classified tracks
waitbar(0.66,d);
RL_fig(3) = figure('Position', [1 1 0.5 1].*get(0, 'Screensize'), 'Visible','on');
sgtitle({title_str, sprintf('lagtime = %d frames', lagtime)}, 'Interpreter', 'none');
GroupIDs = unique(RL_values.classified_tracks(RL_values.classified_tracks > 0));

nGroups = length(GroupIDs);
for ii=1:nGroups
    subplot(1,nGroups,ii);
    track_ind_cur = find(RL_values.classified_tracks == GroupIDs(ii));
    total_classified_tracks = length(RL_values.classified_tracks(RL_values.classified_tracks > 0));
    for jj=1:min(500,length(RL_values.classified_tracks(RL_values.classified_tracks == GroupIDs(ii))))

        x=tracks{track_ind_cur(jj)}(:,1);
        y=tracks{track_ind_cur(jj)}(:,2);
        plot(x,y);
        hold on;
    end
    axis image;
    
    title(num2str(length(track_ind_cur)/total_classified_tracks));
end
waitbar(0.99,d);

savefig(RL_fig,fullfile(RL_save_dir,sprintf('RL__%s_vHC_PMSD_classified_tracks_lagtime_%d.fig', title_str, lagtime)));
exportgraphics(gcf, fullfile(RL_save_dir, sprintf('classified_tracks_%s_lagtime_%d.eps', title_str, lagtime)));
exportgraphics(gcf, fullfile(RL_save_dir, sprintf('classified_tracks_%s_lagtime_%d.png', title_str, lagtime)));

close(RL_fig);
delete(d);
