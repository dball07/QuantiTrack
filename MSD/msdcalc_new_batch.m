function [lags,msd,num_lag_tracks] = msdcalc_new_batch(varargin)

%Calculates the average MSD curve from a group of files
[files,path] = uigetfile('*.mat','Select Files to calculate MSD','MultiSelect','on');

if ~iscell(files)
    files_tmp{1} = files;
    files = files_tmp;
end
if isempty(varargin)
    segment_length = 2;
else
    segment_length = varargin{1};
end

if files{1} ~= 0
    tracks_all = cell(length(files),1);
    
    track_msd = {};
    num_lags={};
    k=1;
    %load in the track files and save to memory
    dt = [];
    for i = 1:length(files)
        IN = load(fullfile(path,files{i}));
        if isfield(IN,'tracks')
            
            tracks_all{i} = IN.tracks;
            dt = [dt; diff(IN.tracks(:,3))];
            minTrkLength = 10;
        elseif isfield(IN,'Results')
            if i == 1
                dt_in = inputdlg({'Enter the time-interval in seconds'},'Enter time-lapse',[1,36],{'1'});
                dt_set = str2double(dt_in);
            end
            i
            tracks_all{i} = IN.Results.PreAnalysis.Tracks_um;
            tracks_all{i}(:,3) = (tracks_all{i}(:,3) - 1).*dt_set;
            dt = [dt; diff(tracks_all{i}(:,3))];
            minTrkLength = 7;
        end
            


    end
    idx = find(tracks_all{1}(:,4)==1);
    [interv,ndt] = mode(dt); % find the likely sampling interval
    if(ndt>0.1*length(idx))
        interval = interv; % if dt is roughly quantized
    else
        interval = 0.250e-3; % else force an interval of 250 microseconds
    end
%     segment_length = 60; % data is split into 2 second chunks. Can specify longer but pdist would produce
    %  an n_sample*n_sample matrix that increases quadratically in size for longer segments
    
    for ifile = 1:length(files)
        num_particles = max(tracks_all{ifile}(:,4)); % number of particles tracked in the file
        fprintf('Analyzing file #%d of %d\n', ifile, length(files));
        for ipart = 1:num_particles
            idx = find(tracks_all{ifile}(:,4)==ipart);
            if(length(idx)>minTrkLength) % track should be at least 10 frames long
                vec=tracks_all{ifile}(idx,1:3);
                vec(:,3) = vec(:,3)-vec(1,3);
                maxtime = vec(end,3); % length of track in seconds
                nseg = floor(maxtime/segment_length)+1; % number of segments in the track
                fprintf('computing for track %d, number of segments %d\n',ipart,nseg)
                for iseg = 1:nseg
                    idx = find(vec(:,3)>segment_length*(iseg-1) & vec(:,3) < segment_length*iseg);
                    if(length(idx)>minTrkLength) %make sure that the remaining segment is long enough
                        Dx=pdist(vec(idx,1)); % calculate pairwise jump for each position from a different position
                        Dy=pdist(vec(idx,2)); %
                        D=(Dx.^2+Dy.^2);
                        dt=pdist(vec(idx,3)); % calculate time interval for each displacement
                        nbins=floor(max(dt)/interval)+2;
                        fprintf('max dt %f and number of bins %d in segment %d in particle %d\n',max(dt),nbins,iseg,ipart)
                        [N,edges,bin]=histcounts(dt,linspace(0,(nbins-1)*interval,nbins)); % bin all time increments
                        m=1;
                        for ii=1:length(edges)-1
                            track_msd{k}(m)=sum(D((bin==ii))); % accumulate displacements belonging to each time-lag bin
                            num_lags{k}(m)= N(m);
                            m = m+1;
                        end
                        k=k+1;
                    end
                end
            end
        end
        fprintf('========================\n\n');
    end
    npts = floor((segment_length+interval)/interval);
    e_msd=zeros(npts,1);
    num_lag_tracks=zeros(npts,1);
    % e_var=[];
    for itrack=1:k-1
        for lagtime=1:length(track_msd{itrack})
            e_msd(lagtime)=e_msd(lagtime)+track_msd{itrack}(lagtime); % ensemble average (<ave> = n_seg1*msd_1+...n_segn*msd_n/(nseg_1...+nseg_n))
            %         e_var(lagtime)=e_var(lagtime)+(num_lags{itrack}(lagtime)-1)*track_std{itrack}(lagtime);
            num_lag_tracks(lagtime) = num_lag_tracks(lagtime)+num_lags{itrack}(lagtime);
        end
    end
    edges = linspace(0,segment_length+interval,npts);
    lags = 0.5*(edges(1:end-1)+edges(2:end));
    lags = lags(1:floor(0.9*npts));
    msd = e_msd(1:floor(0.9*npts))./num_lag_tracks(1:floor(0.9*npts));
    num_lag_tracks = num_lag_tracks(1:floor(0.9*npts));
    % e_var = sqrt(e_var)./(num_lags_tracks-k-1);
    % msd_err(:,igroup) = 2.576*e_var; %99% confidence interval

end