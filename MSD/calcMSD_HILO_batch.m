function [lags,msd,msd_sem, msd_n] = calcMSD_HILO_batch(varargin)
%Calculates the average MSD curve from a group of files

%select tracking files
[files,path] = uigetfile('*.mat','Select Files to calculate MSD','MultiSelect','on');

if ~iscell(files)
    files_tmp{1} = files;
    files = files_tmp;
end

if isempty(varargin)
    minTrkLength = 10;
else
    minTrkLength = varargin{1};
end

if files{1} ~= 0
    dt_in = inputdlg({'Enter the time-interval in seconds'},'Enter time-lapse',[1,36],{'1'});
    dt_set = str2double(dt_in{1});
    ind = 1;
    for i = 1:length(files)
        IN = load(fullfile(path,files{i}));
        trkIDs = unique(IN.Results.PreAnalysis.Tracks_um(:,4));
        for j = 1:length(trkIDs)
            curTrk = IN.Results.PreAnalysis.Tracks_um(IN.Results.PreAnalysis.Tracks_um(:,4) == trkIDs(j),:);
            if length(curTrk) >= minTrkLength
%                 tracks_all{ind} = [(curTrk(:,3) - 1).*dt_set, curTrk(:,1), curTrk(:,2)];
                tracks_all{ind} = [curTrk(:,3).*dt_set, curTrk(:,1), curTrk(:,2)];
                
                ind = ind + 1;
            end
        end
    end

    ma      = msdanalyzer(2, 'µm', 's');     % Initialize the msdanalyzer class
    ma      = ma.addAll(tracks_all);
    ma      = ma.computeMSD;

    mmsd    = ma.getMeanMSD;

    %remove Nans and infs
    mmsd = mmsd(~isnan(mmsd(:,3)),:);
    mmsd = mmsd(~isinf(mmsd(:,3)),:);
    lags       = mmsd(:,1);
    msd       = mmsd(:,2);
    msd_sem      = mmsd(:,3)./sqrt(mmsd(:,4));
    msd_n = mmsd(:,5);


end


